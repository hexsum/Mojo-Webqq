package Mojo::Webqq::Recent::Group;
use strict;
use Mojo::Base;
@Mojo::Webqq::Recent::Group::ISA= qw(Mojo::Base Mojo::Webqq::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    gid
    type
)];

sub update{
    my $self = shift;
    my $hash = shift;
    for(keys %$self){
        $self->{$_} = $hash->{$_} if exists $hash->{$_} ;
    }
    $self;
}
1;
