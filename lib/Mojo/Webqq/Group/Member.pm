package Mojo::Webqq::Group::Member;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Base Mojo::Webqq::Model);
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
    _client
)];

sub qq{
    my $self = shift;
    if(@_==1){$self->{qq} = $_[0]}
    else{return $self->{qq} if defined $self->{qq};return $self->_client->get_qq_from_id($self->id);}
}

sub update{
    my $self = shift;
    my $hash = shift;
    for(keys %$self){
        $self->{$_} = $hash->{$_} if exists $hash->{$_} ;
    }
    $self;
}
1;
