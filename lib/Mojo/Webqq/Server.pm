package Mojo::Webqq::Server;
use Mojo::Base 'Mojo::Server';
 
use Carp 'croak';
use Mojo::IOLoop;
use Mojo::URL;
use Mojo::Util 'term_escape';
use Scalar::Util 'weaken';
 
use constant DEBUG => $ENV{MOJO_DAEMON_DEBUG} || 0;
 
has acceptors => sub { [] };
has [qw(backlog max_clients silent)];
has inactivity_timeout => sub { $ENV{MOJO_INACTIVITY_TIMEOUT} // 15 };
has ioloop => sub { Mojo::IOLoop->singleton };
has listen => sub { [{host=>"127.0.0.1",port=>3000,proto=>"http"}]};
has max_requests => 25;
 
sub DESTROY {
  return if Mojo::Util::_global_destruction();
  my $self = shift;
  $self->_remove($_) for keys %{$self->{connections} || {}};
  my $loop = $self->ioloop;
  $loop->remove($_) for @{$self->acceptors};
}
 
sub run {
  my $self = shift;
 
  # Make sure the event loop can be stopped in regular intervals
  my $loop = $self->ioloop;
  my $int = $loop->recurring(1 => sub { });
  local $SIG{INT} = local $SIG{TERM} = sub { $loop->stop };
  $self->start->ioloop->start;
  $loop->remove($int);
}
 
sub start {
  my $self = shift;
 
  # Resume accepting connections
  my $loop = $self->ioloop;
  if (my $max = $self->max_clients) { $loop->max_connections($max) }
  if (my $servers = $self->{servers}) {
    push @{$self->acceptors}, $loop->acceptor(delete $servers->{$_})
      for keys %$servers;
  }
 
  # Start listening
  else { $self->_listen($_) for @{$self->listen} }
 
  return $self;
}
 
sub stop {
  my $self = shift;
 
  # Suspend accepting connections but keep listen sockets open
  my $loop = $self->ioloop;
  while (my $id = shift @{$self->acceptors}) {
    my $server = $self->{servers}{$id} = $loop->acceptor($id);
    $loop->remove($id);
    $server->stop;
  }
 
  return $self;
}
 
sub _build_tx {
  my ($self, $id, $c) = @_;
 
  my $tx = $self->build_tx->connection($id);
  $tx->res->headers->server('Mojolicious (Perl)');
  my $handle = $self->ioloop->stream($id)->handle;
  $tx->local_address($handle->sockhost)->local_port($handle->sockport);
  $tx->remote_address($handle->peerhost)->remote_port($handle->peerport);
  $tx->req->url->base->scheme('https') if $c->{tls};
 
  # Handle upgrades and requests
  weaken $self;
  $tx->on(
    upgrade => sub {
      my ($tx, $ws) = @_;
      $ws->server_handshake;
      $self->{connections}{$id}{ws} = $ws;
    }
  );
  $tx->on(
    request => sub {
      my $tx = shift;
      $self->emit(request => $self->{connections}{$id}{ws} || $tx);
      $tx->on(resume => sub { $self->_write($id) });
    }
  );
 
  # Kept alive if we have more than one request on the connection
  return ++$c->{requests} > 1 ? $tx->kept_alive(1) : $tx;
}
 
sub _close {
  my ($self, $id) = @_;
 
  # Finish gracefully
  if (my $tx = $self->{connections}{$id}{tx}) { $tx->server_close }
 
  delete $self->{connections}{$id};
}
 
sub _finish {
  my ($self, $id) = @_;
 
  # Always remove connection for WebSockets
  my $c = $self->{connections}{$id};
  return unless my $tx = $c->{tx};
  return $self->_remove($id) if $tx->is_websocket;
 
  # Finish transaction
  $tx->server_close;
 
  # Upgrade connection to WebSocket
  if (my $ws = $c->{tx} = delete $c->{ws}) {
 
    # Successful upgrade
    if ($ws->res->code == 101) {
      weaken $self;
      $ws->on(resume => sub { $self->_write($id) });
      $ws->server_open;
    }
 
    # Failed upgrade
    else {
      delete $c->{tx};
      $ws->server_close;
    }
  }
 
  # Close connection if necessary
  my $req = $tx->req;
  return $self->_remove($id) if $req->error || !$tx->keep_alive;
 
  # Build new transaction for leftovers
  return unless length(my $leftovers = $req->content->leftovers);
  $tx = $c->{tx} = $self->_build_tx($id, $c);
  $tx->server_read($leftovers);
}
 
sub _listen {
  my ($self, $listen) = @_;
  $listen->{proto} = "http" unless defined $listen->{proto};
  $listen->{host} = "0.0.0.0" unless defined $listen->{host};
  croak qq{Invalid listen proto: $listen->{proto}} unless $listen->{proto} =~ /^https?$/;;
  $listen->{tls} = 1 if $listen->{proto} eq "https";
  $listen->{tls_verify} = hex $listen->{tls_verify} if defined $listen->{tls_verify};
  
  my $options = {
    address     => $listen->{host} || "0.0.0.0",
    backlog     => $listen->{backlog} || $self->backlog,
    port        => $listen->{port} || 3000,
    tls         => $listen->{tls},
    tls_ca      => $listen->{tls_ca},
    tls_cert    => $listen->{tls_cert},
    tls_ciphers => $listen->{tls_ciphers},
    tls_key     => $listen->{tls_key},
    tls_verify  => $listen->{tls_verify},
  };
 
  weaken $self;
  push @{$self->acceptors}, $self->ioloop->server(
    $options => sub {
      my ($loop, $stream, $id) = @_;
 
      my $c = $self->{connections}{$id} = {tls => $listen->{tls}};
      warn "-- Accept $id (@{[$stream->handle->peerhost]})\n" if DEBUG;
      $stream->timeout($self->inactivity_timeout);
 
      $stream->on(close => sub { $self && $self->_close($id) });
      $stream->on(error =>
          sub { $self && $self->app->log->error(pop) && $self->_close($id) });
      $stream->on(read => sub { $self->_read($id => pop) });
      $stream->on(timeout =>
          sub { $self->app->log->debug('client connection Iinactivity timeout') if $c->{tx} });
    }
  );
 
  return if $self->silent;
  #$self->app->log->info("Listening at $listen->{host}:$listen->{port}");
  $self->app->log->info("$listen->{proto} server available at $listen->{host}:$listen->{port}");
}
 
sub _read {
  my ($self, $id, $chunk) = @_;
 
  # Make sure we have a transaction and parse chunk
  return unless my $c = $self->{connections}{$id};
  my $tx = $c->{tx} ||= $self->_build_tx($id, $c);
  warn term_escape "-- Server <<< Client (@{[_url($tx)]})\n$chunk\n" if DEBUG;
  $tx->server_read($chunk);
 
  # Last keep-alive request or corrupted connection
  $tx->res->headers->connection('close')
    if (($c->{requests} || 0) >= $self->max_requests) || $tx->req->error;
 
  # Finish or start writing
  if    ($tx->is_finished) { $self->_finish($id) }
  elsif ($tx->is_writing)  { $self->_write($id) }
}
 
sub _remove {
  my ($self, $id) = @_;
  $self->ioloop->remove($id);
  $self->_close($id);
}
 
sub _url { shift->req->url->to_abs }
 
sub _write {
  my ($self, $id) = @_;
 
  # Get chunk and write
  return unless my $c  = $self->{connections}{$id};
  return unless my $tx = $c->{tx};
  return if !$tx->is_writing || $c->{writing}++;
  my $chunk = $tx->server_write;
  delete $c->{writing};
  warn term_escape "-- Server >>> Client (@{[_url($tx)]})\n$chunk\n" if DEBUG;
  my $stream = $self->ioloop->stream($id)->write($chunk);
 
  # Finish or continue writing
  weaken $self;
  my $cb = sub { $self->_write($id) };
  if ($tx->is_finished) {
    if ($tx->has_subscribers('finish')) {
      $cb = sub { $self->_finish($id) }
    }
    else {
      $self->_finish($id);
      return unless $c->{tx};
    }
  }
  $stream->write('' => $cb);
}
 
1;
