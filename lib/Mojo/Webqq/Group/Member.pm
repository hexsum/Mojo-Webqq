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

has qq  => sub{
    my $self = shift;
    return $self->{qq} if defined $self->{qq};
    return $self->{_client}?$self->{_client}->get_qq_from_id($self->id):undef;
};
sub displayname {
    my $self = shift;
    return defined $self->card?$self->card:$self->nick;
}

sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$hash){
        if(exists $hash->{$_}){
            if(defined $hash->{$_} and defined $self->{$_}){
                if($hash->{$_} ne $self->{$_}){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->{_client}->emit("group_member_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->{_client}->emit("group_member_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
            }
        }
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
sub shutup{
    my $self = shift;
    my $time = shift;
    $self->group->shutup_group_member($time,$self);
}
1;

