package Mojo::Webqq::Friend;
use strict;
use base qw(Mojo::Base Mojo::Webqq::Model::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) }
has [qw(
    flag
    id
    qq
    category
    nick
    face
    markname    
    is_vip      
    vip_level   
    state       
    client_type 
)];
has qq => sub{
    my $self = shift;
    return $self->{qq} if defined $self->{qq};
    return $self->{_client}?$self->{_client}->get_qq_from_id($self->id):undef;
};
sub displayname {
    my $self = shift;
    return defined $self->markname?$self->markname:$self->nick;
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
                    $self->{_client}->emit("friend_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->{_client}->emit("friend_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
            }
        }
    }
    $self;
}

sub send {
    my $self = shift;
    $self->{_client}->send_message($self,@_);
}

1;
