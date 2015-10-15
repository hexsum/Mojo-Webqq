package Mojo::Webqq::User;
use strict;
use base qw(Mojo::Base Mojo::Webqq::Model::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    face
    birthday
    phone
    occupation
    allow
    college 
    qq
    id
    blood
    constel
    homepage
    state
    country
    city
    personal
    nick
    shengxiao
    email
    token
    client_type
    province
    gender
    mobile
    signature
)];

sub displayname {
    my $self = shift;
    return $self->nick;
}

1;
