package Mojo::Webqq::User;
use strict;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
has [qw(
    face
    birthday
    phone
    occupation
    allow
    college 
    id
    uid
    sex
    blood
    constel
    homepage
    state
    country
    city
    personal
    name
    shengxiao
    email
    token
    client_type
    province
    mobile
    signature
)];
sub qq {$_[0]->uid}
sub nick {$_[0]->name}
sub displayname {
    my $self = shift;
    return $self->name;
}

1;
