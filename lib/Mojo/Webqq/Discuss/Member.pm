package Mojo::Webqq::Discuss::Member;
use strict;
use base qw(Mojo::Base Mojo::Webqq::Model::Base);
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

sub displayname {
    my $self = shift;
    return $self->nick;
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
                    $self->{_client}->emit("discuss_member_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->{_client}->emit("discuss_member_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
            }
        }
    }
    $self;
}

sub send {
    my $self = shift;
    $self->{_client}->send_sess_message($self,@_);
} 

sub discuss {
    my $self = shift;
    return scalar $self->{_client}->search_discuss(did=>$self->did);
}

1;
