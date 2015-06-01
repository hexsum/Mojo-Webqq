package Mojo::Webqq::User;
use strict;
use Mojo::Base;
@Mojo::Webqq::User::ISA = qw(Mojo::Base Mojo::Webqq::Base Mojo::Webqq::Model);
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

1;
