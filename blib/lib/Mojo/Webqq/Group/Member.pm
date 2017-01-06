package Mojo::Webqq::Group::Member;
use strict;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
has [qw(
    name
    province
    sex
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
    _group_id
)];

has uid => sub{
    my $self = shift;
    return $self->{qq} if defined $self->{qq};
    return $self->client->get_qq_from_id($self->id);
};
sub qq {$_[0]->uid}
sub AUTOLOAD {
    my $self = shift;
    if($Mojo::Webqq::Group::Member::AUTOLOAD =~ /.*::g(.*)/){
        my $attr = $1;
        $self->group->$attr(@_);
    }
    else{die("undefined subroutine $Mojo::Webqq::Group::Member::AUTOLOAD");}
}
sub nick {$_[0]->name};
sub displayname {
    my $self = shift;
    return defined $self->card?$self->card:$self->name;
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
                    $self->client->emit("group_member_property_change"=>$self,$_,$old_property,$new_property);
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->client->emit("group_member_property_change"=>$self,$_,$old_property,$new_property);
            }
        }
    }
    $self;
}

sub send {
    my $self = shift;
    $self->client->send_sess_message($self,@_);
} 
sub set_card {
    my $self = shift;
    my $card = shift;
    $self->group->set_group_member_card($self,$card);
}
sub group {
    my $self = shift;
    return scalar $self->client->search_group(id=>$self->_group_id);
}
sub shutup{
    my $self = shift;
    my $time = shift;
    $self->group->shutup_group_member($time,$self);
}
1;

