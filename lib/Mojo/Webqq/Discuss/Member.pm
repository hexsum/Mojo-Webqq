package Mojo::Webqq::Discuss::Member;
use strict;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
has [qw(
    name
    id
    state
    client_type
    _discuss_id
)];

has uid => sub{
    my $self = shift;
    return $self->{uid} if defined $self->{uid};
    return $self->client->get_qq_from_id($self->id);
};
sub qq {$_[0]->uid}
sub nick {$_[0]->name}
sub AUTOLOAD {
    my $self = shift;
    if($Mojo::Webqq::Discuss::Member::AUTOLOAD =~ /.*::d(.*)/){
        my $attr = $1;
        $self->group->$attr(@_);
    }
    else{die("undefined subroutine $Mojo::Webqq::Discuss::Member::AUTOLOAD");}
}
sub displayname {
    my $self = shift;
    return $self->name;
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
                    $self->client->emit("discuss_member_property_change"=>$self,$_,$old_property,$new_property);
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->client->emit("discuss_member_property_change"=>$self,$_,$old_property,$new_property);
            }
        }
    }
    $self;
}

sub send {
    my $self = shift;
    $self->client->send_sess_message($self,@_);
} 

sub discuss {
    my $self = shift;
    return scalar $self->client->search_discuss(id=>$self->_discuss_id);
}

1;
