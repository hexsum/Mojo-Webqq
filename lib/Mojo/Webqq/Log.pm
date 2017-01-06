package Mojo::Webqq::Log;
use Mojo::Base;
use base qw(Mojo::Base Mojo::EventEmitter);
use Carp 'croak';
use Fcntl ':flock';
use Encode;
use POSIX qw();
use Encode::Locale;
BEGIN{
    eval{require Term::ANSIColor};
    $Mojo::Webqq::Log::is_support_color = 1 unless $@;
}
sub has { Mojo::Base::attr(__PACKAGE__, @_) }; 
 
has format => sub { \&_format };
has handle => sub {
  # STDERR
  return \*STDOUT unless my $path = shift->path;
  # File
  croak qq{Can't open log file "$path": $!} unless open my $file, '>>', $path;
  return $file;
};
has history => sub { [] };
has level => 'debug';
has head => '';
has encoding => undef;
has unicode_support => 1;
has disable_color   => 0;
has console_output  => 0;
has max_history_size => 10;
has 'path';
 
# Supported log levels
my $LEVEL = {debug => 1, info => 2, msg=>3, warn => 4, error => 5, fatal => 6};
sub _format {
    my ($time, $level, @lines) = @_;
    my %opt = ref $lines[0] eq "HASH"?%{shift @lines}:();
    $time = $opt{time} if defined $opt{time};
    $time = $time?POSIX::strftime('[%y/%m/%d %H:%M:%S]',localtime($time)):"";
    my $log = {
        head        =>  $opt{head} // "",
        head_color  =>  $opt{head_color},
        'time'      =>  $time,
        time_color  =>  $opt{time_color},
        level       =>  $opt{level} // $level,
        level_color =>  $opt{level_color},
        title       =>  defined $opt{title}?"$opt{title} ":"",
        title_color =>  $opt{title_color},
        content     =>  [split /\n/,join "",@lines],
        content_color=> $opt{content_color},
    };
    return $log;
}
sub colored {
    #black  red  green  yellow  blue  magenta  cyan  white
    my $self = shift;
    return $_[0] if (!$_[0] or !$_[1] or $self->disable_color or !$Mojo::Webqq::Log::is_support_color);
    return Term::ANSIColor::colored(@_) if $Mojo::Webqq::Log::is_support_color;
}
sub reform_encoding{
    my $self = shift;
    my $log = shift;
    no strict;
    my $msg ; 
    if($self->unicode_support and Encode::is_utf8($log)){
        $msg = encode($self->encoding || console_out,$log);
    }
    else{
        if($self->encoding =~/^utf-?8$/i ){
            $msg = $log;
        }
        else{
            $msg = encode($self->encoding || console_out,decode("utf8",$log));
        }
    }
    return $msg;
}
sub append {
    my ($self,$log) = @_;
    return unless my $handle = $self->handle;
    flock $handle, LOCK_EX;
    $log->{$_} = $self->reform_encoding($log->{$_}) for(qw(head level title ));
    $_ = $self->reform_encoding($_) for @{$log->{content}};
    if( -t $handle){
        my $color_msg;
        for(@{$log->{content}}){
            $color_msg .=    $self->colored($log->{head},$log->{head_color}) 
                        .  $self->colored($log->{time},$log->{time_color}) 
                        .  " " 
                        .  ( $log->{level}?"[".$self->colored($log->{level},$log->{level_color})."]":"" )
                        .  " " 
                        .  $self->colored($log->{title},$log->{title_color}) 
                        .  $self->colored($_,$log->{content_color}) 
                        . "\n";
        }
        $handle->print($color_msg) or croak "Can't write to log: $!";
    }
    else{
        my $msg;
        for(@{$log->{content}}){
            $msg .= $log->{head}
                . $log->{time}
                . " "
                . ($log->{level}?"[$log->{level}]":"")
                . " "
                . $log->{title}
                . $_
                . "\n";
        }
        $handle->print($msg) or croak "Can't write to log: $!";
        if($self->console_output and -t STDOUT){
            my $color_msg;
            for(@{$log->{content}}){
                $color_msg .=    $self->colored($log->{head},$log->{head_color})
                            .  $self->colored($log->{time},$log->{time_color})
                            .  " "
                            .  ( $log->{level}?"[".$self->colored($log->{level},$log->{level_color})."]":"" )
                            .  " "
                            .  $self->colored($log->{title},$log->{title_color})
                            .  $self->colored($_,$log->{content_color})
                            . "\n";
            }              
            print STDOUT $color_msg;#or croak "Can't write to log: $!"
        }
    }
    flock $handle, LOCK_UN;
}
 
sub debug { shift->_log(debug => @_) }
sub error { shift->_log(error => @_) }
sub fatal { shift->_log(fatal => @_) }
sub info  { shift->_log(info  => @_) }
sub warn  { shift->_log(warn  => @_) }
sub msg   { shift->_log(msg   => @_) }
 
sub is_debug { shift->_now('debug') }
sub is_error { shift->_now('error') }
sub is_info  { shift->_now('info') }
sub is_warn  { shift->_now('warn') }
sub is_msg   { shift->_now('msg') }
sub is_fatal   { shift->_now('fatal') }
 
sub new {
  my $self = shift->SUPER::new(@_);
  $self->on(message => \&_message);
  return $self;
}
 
sub _log { shift->emit('message', shift, @_) }
 
sub _message {
  my ($self, $level) = (shift, shift);
 
  return unless $self->_now($level);
 
  my $max     = $self->max_history_size;
  my $history = $self->history;
  if(ref $_[0] eq 'HASH'){
      $_[0]{head} = $self->head if not defined $_[0]{head};
  }
  else{
      unshift @_,{head=>$self->head};
  }
  push @$history, my $msg = [time, $level, @_];
  shift @$history while @$history > $max;

  $self->append($self->format->(@$msg));
}
 
sub _now { $LEVEL->{pop()} >= $LEVEL->{$ENV{MOJO_LOG_LEVEL} || shift->level} }
 
1;
