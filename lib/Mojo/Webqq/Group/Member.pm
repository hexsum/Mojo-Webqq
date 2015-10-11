package Mojo::Webqq::Group::Member;
use strict;
use base qw(Mojo::Base Mojo::Webqq::Model::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    nick
    province
    gender
    id
    country
    city
    card
    state
    client_type
    qage
    join_time
    last_speak_time
    level
    role
    bad_record
    gid
    gcode
    gtype 
    gnumber
    gname
    gmemo
    gcreatetime
    glevel
    gowner
    gmarkname
)];

has displayname => sub{
    my $self = shift;
    return defined $self->card?$self->card:$self->nick;
};
has qq  => sub{
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
    $self->{_client}->send_sess_message($self,@_);
} 
sub set_card {
    my $self = shift;
    my $card = shift;
    $self->group->set_group_member_card($self,$card);
}
sub group {
    my $self = shift;
    return scalar $self->{_client}->search_group(gid=>$self->gid);
}
1;

