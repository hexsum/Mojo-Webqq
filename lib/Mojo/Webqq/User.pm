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
    _client
)];

sub qq{
    my $self = shift;
    if(@_==1){$self->{qq} = $_[0]}
    else{return $self->{qq} if defined $self->{qq};return $self->_client->get_qq_from_id($self->id);}
}

1;
