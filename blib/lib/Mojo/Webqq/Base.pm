package Mojo::Webqq::Base;
use strict;
use warnings;
use feature ();
 
# No imports because we get subclassed, a lot!
use Carp ();
 
# Only Perl 5.14+ requires it on demand
use IO::Handle ();
 
# Supported on Perl 5.22+
my $NAME
  = eval { require Sub::Util; Sub::Util->can('set_subname') } || sub { $_[1] };
 
# Protect subclasses using AUTOLOAD
sub DESTROY { }
 
# Declared here to avoid circular require problems in Mojo::Util
sub _monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = $NAME->("${class}::$_", $patch{$_}) for keys %patch;
}
 
sub attr {
  my ($self, $attrs, $value) = @_;
  return unless (my $class = ref $self || $self) && $attrs;
 
  Carp::croak 'Default has to be a code reference or constant value'
    if ref $value && ref $value ne 'CODE';
 
  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;
 
    # Very performance sensitive code with lots of micro-optimizations
    if (ref $value) {
      _monkey_patch $class, $attr, sub {
        return
          exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value->($_[0]))
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
    }
    elsif (defined $value) {
      _monkey_patch $class, $attr, sub {
        return exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value)
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
    }
    else {
      _monkey_patch $class, $attr,
        sub { return $_[0]{$attr} if @_ == 1; $_[0]{$attr} = $_[1]; $_[0] };
    }
  }
}
 
sub import {
  my $class = shift;
  return unless my $flag = shift;
 
  # Base
  if ($flag eq '-base') { $flag = $class }
 
  # Strict
  elsif ($flag eq '-strict') { $flag = undef }
 
  # Module
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }
 
  # ISA
  if ($flag) {
    my $caller = caller;
    no strict 'refs';
    push @{"${caller}::ISA"}, $flag;
    _monkey_patch $caller, 'has', sub { attr($caller, @_) };
  }
 
  # Mojo modules are strict!
  $_->import for qw(strict warnings);
  feature->import(':5.10');
}
 
sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}
 
sub tap {
  my ($self, $cb) = (shift, shift);
  $_->$cb(@_) for $self;
  return $self;
}
 
1;
