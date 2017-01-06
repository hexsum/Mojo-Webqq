package Mojo::Webqq::Friend;
use strict;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
has [qw(
    flag
    id
    category
    name
    face
    markname    
    is_vip      
    vip_level   
    state       
    client_type 
)];
has uid => sub{
    my $self = shift;
    return $self->{uid} if defined $self->{uid};
    return $self->client->get_qq_from_id($self->id);
};
sub qq {$_[0]->uid}
sub nick {$_[0]->name}
sub displayname {
    my $self = shift;
    return defined $self->markname?$self->markname:$self->name;
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
                    $self->client->emit("friend_property_change"=>$self,$_,$old_property,$new_property);
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->client->emit("friend_property_change"=>$self,$_,$old_property,$new_property);
            }
        }
    }
    $self;
}

sub send {
    my $self = shift;
    $self->client->send_friend_message($self,@_);
}

1;
