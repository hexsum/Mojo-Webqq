package Mojo::Webqq::Discuss::Member;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    nick
    id
    ruin
    state
    client_type
    dname
    did
    downer
    _client
)];

has qq => sub{
    my $self = shift;
    return $self->{_client}?$self->{_client}->get_qq_from_id($self->id):undef;
};

sub update{
    my $self = shift;
    my $hash = shift;
    for(keys %$self){
        $self->{$_} = $hash->{$_} if exists $hash->{$_} ;
    }
    $self;
}
1;
