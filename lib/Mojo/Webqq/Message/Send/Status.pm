package Mojo::Webqq::Message::Send::Status;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has [qw(code msg)];
sub is_success{
    my $self = shift;
    return $self->code == 0?1:0; 
}
1;
