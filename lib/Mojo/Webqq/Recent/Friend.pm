package Mojo::Webqq::Recent::Friend;
use strict;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
has [qw(
    id
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
