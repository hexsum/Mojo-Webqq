package Mojo::Webqq::Friend;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) }
has [qw(
    flag
    id
    categorie
    nick
    face
    markname    
    is_vip      
    vip_level   
    state       
    client_type 
)];

has displayname => sub{
    my $self = shift;
    return defined $self->markname?$self->markname:$self->nick;
};
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

sub send {
    my $self = shift;
    $self->{_client}->send_message($self,@_);
}

1;
