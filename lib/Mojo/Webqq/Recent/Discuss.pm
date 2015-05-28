package Mojo::Webqq::Recent::Discuss;
use strict;
use Mojo::Base;
@Mojo::Webqq::Recent::Discuss::ISA= qw(Mojo::Base Mojo::Webqq::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    did
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
