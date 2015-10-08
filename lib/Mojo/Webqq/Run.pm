package Mojo::Webqq::Run;
use List::Util qw(first);
use base qw(Mojo::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) }

use bytes;
use Carp;
use Errno;
use Socket;
use Time::HiRes qw(time gettimeofday);
use Scalar::Util qw(blessed);
use Storable qw(thaw nfreeze);
use POSIX ":sys_wait_h";
use Mojo::Webqq::Log;
use Mojo::IOLoop;
use Mojo::Reactor;
has 'num_forks'  => sub { 0 };
has 'max_forks'  => sub { 0 };
has 'log'        => sub { Mojo::Webqq::Log->new };
has 'ioloop'     => sub { Mojo::IOLoop->singleton };
has [qw/reactor error is_child/];
 
our $VERSION = '0.3';
 
my $_obj  = undef;
 
BEGIN {
        *portable_pipe = sub () { my ($r, $w);
                pipe $r, $w or return;
                 
                ($r, $w);
        };
        *portable_socketpair = sub () {
                socketpair my $fh1, my $fh2, Socket::AF_UNIX(), Socket::SOCK_STREAM(), PF_UNSPEC
                        or return;
                $fh1->autoflush(1);
                $fh2->autoflush(1);
                 
                ($fh1, $fh2)
        };      
}
 
sub new {my $class = shift; __PACKAGE__->singleton(@_) }
 
sub singleton {
        return $_obj if defined $_obj;
        my $class = shift;
        return $_obj = __PACKAGE__->_constructor(@_);
}
 
sub _constructor {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new(@_);
 
        bless $self => $class;
         
        # install SIGCHLD handler
        $SIG{'CHLD'} = sub { _sig_chld($self, @_) };
         
        return $self;
}
 
sub log_level {
        my ($self, $level) = @_;
         
        $self->log->level($level) if defined $level;
         
        return $self->log->level;
}
 
sub spawn {
        my ($self, %opt) = @_;
         
        unless (defined $self && blessed($self) && $self->isa(__PACKAGE__)) {
                my $obj = __PACKAGE__->new;
                return $obj->spawn(%opt);
        }
         
        $self->error('');
         
        if ($self->max_forks > 0 && $self->num_forks >= $self->max_forks) {
                $self->error("Unable to spawn another subprocess: "
                        ."Limit of " . $self->max_forks . " concurrently spawned process(es) is reached."
                );
                return 0;
        }
         
        # normalize and validate run parameters...
        my $proc = $self->_getRunStruct(\%opt);
        return 0 unless $self->_validateRunStruct($proc);
         
        $self->log->debug("Spawning command "
                ."timeout: "
                .($proc->{exec_timeout} > 0 ? sprintf("%-.3f seconds]", $proc->{exec_timeout}) : "none")
                ." : [$proc->{cmd}]"
        );
        my ($stdout_p, $stdout_c) = portable_socketpair;
        my ($stderr_p, $stderr_c) = portable_socketpair;
        my ($stdres_p, $stdres_c) = portable_socketpair;
         
        $proc->{time_started} = time;
        $proc->{running     } = 1;
        $proc->{hdr_stdout  } = $stdout_c;
        $proc->{hdr_stderr  } = $stderr_c;
        $proc->{hdr_stdres  } = $stdres_c;
         
        my $pid = fork;
         
        if ($pid) {
                # parent
                $self->num_forks($self->num_forks + 1);
                 
                $self->log->debug("Subprocess spawned as pid $pid.");
                 
                $proc->{pid} = $pid;
                 
                # exec timeout
                if (defined $proc->{exec_timeout} && $proc->{exec_timeout} > 0) {
                        $self->log->debug(
                                "[process $pid]: Setting execution timeout to " .
                                sprintf("%-.3f seconds.", $proc->{exec_timeout})
                        );
                        my $timer = $self->ioloop->timer(
                                $proc->{exec_timeout},
                                sub { _timeout_cb($self, $pid) }
                        );
         
                        # save timer
                        $proc->{id_timeout} = $timer;
                }
                 
                $self->{_data}->{$pid} = $proc;
                 
                close $stdout_p;
                close $stderr_p;
                close $stdres_p;
                 
                $self->watch('stdout', $pid);
                $self->watch('stderr', $pid);
                $self->watch('stdres', $pid);
        } else {
                # child
                 
                $self->is_child(1);
                 
                close $stdout_c;
                close $stderr_c;
                close $stdres_c;
                 
                # Stdio should not be tied.
                if (tied *STDOUT) {
                        carp "Cannot redirect into tied STDOUT.  Untying it";
                        untie *STDOUT;
                }
                if (tied *STDERR) {
                        carp "Cannot redirect into tied STDERR.  Untying it";
                        untie *STDERR;
                }
                 
                # Redirect STDOUT
                open STDOUT, ">&" . fileno($stdout_p)
                        or croak "can't redirect stdout in child pid $$: $!";
                # Redirect STDERR
                open STDERR, ">&" . fileno($stderr_p)
                        or croak "can't redirect stderr in child pid $$: $!";
 
                select STDERR; $| = 1;
                select STDOUT; $| = 1;
                 
                if (ref $proc->{cmd} eq 'CODE') {
                        my @rv = eval { $proc->{cmd}->($$, $proc->{param}); };
                         
                        if ($@) {
                                carp "exec of coderef failed: $@\n";
                                exit 255;
                        }
                         
                        print $stdres_p nfreeze(\ @rv);
                         
                } else {
                        exec(ref $proc->{cmd} eq 'ARRAY' ? @{ $proc->{cmd} } : $proc->{cmd}) or do {
                                carp "exec failed";
                                exit 255;
                        };
                }
                 
                close $stdout_p;
                close $stderr_p;
                close $stdres_p;
                 
                exit 1;
        }
         
        return $pid;
}
 
sub start { shift->ioloop->start }
 
sub watch {
        my $self = shift;
        my $io   = lc(shift || '');
        my $pid  = shift;
         
        my $proc = $self->get_proc($pid);
         
        $self->log->error('Cant start IO watcher off NULL process'           ) and return unless $proc;
        $self->log->error("[process $proc->{pid}]: IO ($io) is unsupported"  ) and return unless first {$io eq $_} qw/stdout stderr stdres/;
        $self->log->error("[process $proc->{pid}]: IO handler ($io) is EMPTY") and return unless $proc->{"hdr_$io"};
         
        my $id = fileno $proc->{"hdr_$io"};
         
        $self->ioloop->reactor->io($proc->{"hdr_$io"}, sub {
                my $chunk = undef;
                my $len   = sysread $proc->{"hdr_$io"}, $chunk, 65536;
                 
                return unless defined $len or $! != Errno::EINTR;
                 
                if (!$len) {
                        $self->drop_handle($pid, $io);
                        return;
                }
                 
                if (defined $proc->{"$io\_cb"}) {
                        $self->log->debug("[process $proc->{pid}]: (handle: $id) Invoking ".uc($io)." callback.");
                         
                        eval { $proc->{"$io\_cb"}->($proc->{pid}, $chunk) };
                         
                        if ($@) {
                                $self->log->error("[process $proc->{pid}]: (handle: $id) Exception in $io\_cb: $@");
                        }
                }   
                #else {
                {
                        # append to buffer
                        $self->log->debug("[process $proc->{pid}]: (handle: $id) Appending $len bytes to ".uc($io)." buffer.");
                        $proc->{"buf_$io"} .= $chunk;
                }
        })->watch($proc->{"hdr_$io"}, 1, 0);
}
 
sub drop_handle {
        my $self = shift;
        my $pid  = shift;
        my $io   = lc(shift || '');
         
        my $proc = $self->get_proc($pid);
        return unless $proc;
         
        $self->log->debug("[process $pid]: Got HUP for unmanaged handle ".$proc->{"hdr_$io"}."; ignoring.") and return
                unless $proc->{"hdr_$io"};
         
         
        $self->ioloop->remove( $proc->{"hdr_$io"} );
        undef $proc->{"hdr_$io"};
         
        $self->log->debug("[process $pid]: ".uc($io)." closed.");
         
        $self->complete($pid);
}
 
sub get_proc {
        my ($self, $pid) = @_;
         
        no warnings;
        my $err = "[process $pid]: Unable to get process data structure: ";
         
        unless (defined $pid) {
                $self->error($err . "Undefined pid.");
                return undef;
        }
         
        unless (
                exists $self->{_data}->{$pid}
                && defined $self->{_data}->{$pid}
        ) {
                $self->error($err . "Non-managed process pid: $pid");
                return undef;
        }
 
        return $self->{_data}->{$pid};
}
 
sub cleanup {
        my ($self, $pid, $exit_val, $signum, $core) = @_;
         
        my $proc = $self->get_proc($pid);
        unless (defined $proc) {
                no warnings;
                $self->log->warn("Untracked process pid $pid exited with exit status $exit_val by signal $signum, core: $core.");
                return 0;
        }
        return 0 if $proc->{cleanup};
         
        $proc->{cleanup} = 1;
 
        $self->log->debug("[process $pid]: Got SIGCHLD, "
                . "exited with exit status: $exit_val by signal $signum"
                . (($core) ? "with core dump." : ".")
        );
 
        if (defined $proc->{id_timeout}) {
                $self->ioloop->remove($proc->{id_timeout});
                $proc->{id_timeout} = undef;
        }
        if ($proc->{hard_kill}) {
                for (qw/stderr stdout stdres/) {
                        $self->drop_handle($pid, $_) if $proc->{"hdr_$_"};
                }
        }
        $proc->{exit_status} = $exit_val;
        $proc->{exit_core  } = $core;
        $proc->{exit_signal} = $signum;
 
        # command timings...
        my $te = time;
        $proc->{time_stopped      } = $te;
        $proc->{time_duration_exec} = $te - $proc->{time_started};
 
        # this process is no longer running
        $proc->{running} = 0;
 
        $self->complete($pid);
}
 
sub complete {
        my ($self, $pid, $force) = @_;
         
        my $proc = $self->get_proc($pid);
         
        return 0 if !$force
                && (
                        $proc->{running}
                        || defined $proc->{hdr_stdout}
                        || defined $proc->{hdr_stdres}
                        || defined $proc->{hdr_stderr}
                );
         
 
        if ($proc && %$proc) {
                $self->log->debug("[process $pid]: All streams closed, process execution complete.");
                 
                $proc->{time_duration_total} = time - $proc->{time_started};
 
                # fire exit callback!
                if (defined $proc->{exit_cb} && ref $proc->{exit_cb} eq 'CODE') {
                        my $result = eval { $proc->{buf_stdres} ? thaw($proc->{buf_stdres}) : undef};
                         
                        if ($@) {
                                croak "Error de-serializing subprocess data: $@";
                        }
                         
                        # prepare callback structure
                        my $cb_d = {
                                cmd => ref $proc->{cmd} eq 'CODE'  ? 'CODE'                     :
                                           ref $proc->{cmd} eq 'ARRAY' ? join(' ', @{$proc->{cmd}}) :
                                           $proc->{cmd}
                                ,
                                param               => $proc->{param},
                                is_timeout          => $proc->{is_timeout},
                                exit_status         => $proc->{exit_status},
                                exit_signal         => $proc->{exit_signal},
                                exit_core           => $proc->{exit_core},
                                stdout              => $proc->{buf_stdout},
                                stderr              => ($proc->{buf_stderr} ? $proc->{buf_stderr} : '').($proc->{stderr} ? $proc->{stderr} : ''),
                                result              => $result,
                                time_started        => $proc->{time_started},
                                time_stopped        => $proc->{time_stopped},
                                time_duration_exec  => $proc->{time_duration_exec},
                                time_duration_total => $proc->{time_duration_total},
                        };
 
                        # safely invoke callback
                        $self->log->debug("[process $pid]: invoking exit_cb callback.");
                        eval { $proc->{exit_cb}->($pid, $cb_d); };
                         
                        $self->log->error("[process $pid]: Error running exit_cb: $@") if $@;
                } else {
                        $self->log->error("[process $pid]: No exit_cb callback!");
                }
        }
 
        delete $self->{_data}->{$pid};
        $self->num_forks($self->num_forks - 1);
}
 
sub _sig_chld {
        my ($self) = @_;
 
        no strict 'subs';
         
        my $i = 0;
        while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
                $i++;
                my $exit_val = $? >> 8;
                my $signum   = $? & 127;
                my $core     = $? & 128;
 
                # do process cleanup
                $self->cleanup($pid, $exit_val, $signum, $core);
        }
         
        $self->log->debug("SIGCHLD handler cleaned up after $i process(es).")
          if $i > 0;
}
 
sub _getRunStruct {
        my ($self, $opt) = @_;
         
        my $s = {
                pid          => 0,
                cmd          => undef,
                param        => undef,
                error        => undef,
                stdout_cb    => undef,
                stderr_cb    => undef,
                exit_cb      => undef,
                is_timeout   => undef,
                exec_timeout => 0,
                buf_stdout   => '',
                buf_stderr   => '',
                buf_stdres   => '',
                hdr_stdout   => undef,
                hdr_stderr   => undef,
                hdr_stdres   => undef,
        };
 
        # apply user defined vars...
        $s->{$_} = $opt->{$_}
                for grep { exists $s->{$_} } keys %$opt;
 
        return $s;
}
 
sub _validateRunStruct {
        my ($self, $s) = @_;
 
        # command?
        $self->error('Undefined command.') and return
                unless defined $s->{cmd};
         
        # check command...
        my $cmd_ref = ref $s->{cmd};
        $self->error('Zero-length command.') and return
                if $cmd_ref eq '' && length $s->{cmd} == 0;
         
        $self->error('Command can be pure scalar, arrayref or coderef.') and return
                if $cmd_ref ne '' && not defined first {$cmd_ref eq $_} ('CODE', 'ARRAY');
 
        # callbacks...
        $self->error("STDOUT callback defined, but is not code reference.") and return
                if defined $s->{stdout_cb} && ref $s->{stdout_cb} ne 'CODE';
         
        $self->error("STDERR callback defined, but is not code reference.") and return
                if defined $s->{stderr_cb} && ref $s->{stderr_cb} ne 'CODE';
         
        $self->error("Process exit_cb callback defined, but is not code reference.") and return
                if defined $s->{exit_cb} && ref($s->{exit_cb}) ne 'CODE';
 
        # exec timeout
        { no warnings; $s->{exec_timeout} += 0; }
 
        return 1;
}
 
sub _timeout_cb {
        my ($self, $pid) = @_;
         
        my $proc = $self->get_proc($pid);
        return 0 unless $proc;
         
        # drop timer (can't hurt...)
        if (defined $proc->{id_timeout}) {
                $self->ioloop->remove($proc->{id_timeout});
                $proc->{id_timeout} = undef;
        }
 
        # is process still alive?
        return 0 unless kill 0, $pid;
 
        $self->log->debug("[process $pid]: Execution timeout ("
                .sprintf("%-.3f seconds).", $proc->{exec_timeout})
                ." Killing process.");
 
        $proc->{stderr} .= ";Execution timeout.";
        $proc->{is_timeout} = 1;
         
        # kill the motherfucker!
 
        unless (CORE::kill(9, $pid)) {
                $self->log->warn("[process $pid]: Unable to kill process: $!");
        }
        $proc->{hard_kill} = 1;
        $self->cleanup($pid, 0, 9, 0);
 
        return 1;
}
 
sub kill {
        my ($self, $pid, $signal) = @_;
        $signal = 15 unless defined $signal;
         
        my $proc = $self->get_proc($pid);
        return 0 unless $proc;
 
        # kill the process...
        unless (kill($signal, $pid)) {
                $self->error("Unable to send signal $signal to process $pid: $!");
                return 0;
        }
         
        return 1;
}
 
sub DESTROY {
        my ($self) = @_;
         
        # perform cleanup...
        unless ($self->is_child) {
                foreach my $pid (keys %{$self->{_data}}) {
                        my $proc = $self->{_data}->{$pid};
                         
                        $self->log->debug("Killing subprocess $pid with SIGKILL") if $self->log;
                        # kill process (HARD!)
                        $self->kill($pid, 9);
         
                        next unless defined $self->ioloop;
         
                        # drop fds
                        $self->drop_handle($pid, $_) for grep {$proc->{"hdr_$_"}} qw/stdout stderr stdres/;
         
                        # fire exit callbacks (if any)
                        $self->complete($pid, 1);
                }
        }
 
        # disable sigchld hander
        $SIG{'CHLD'} = 'IGNORE';
}
 
1;
