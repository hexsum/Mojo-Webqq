package Mojo::Webqq::Recent::Discuss;
use strict;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
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
