package Mojo::Webqq::Friend;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Base Mojo::Webqq::Model);
sub has { Mojo::Base::attr(__PACKAGE__, @_) }
has [qw(
    flag
    id
    categorie
    nick
    face
    markname    
    is_vip      
    vip_level   
    state       
    client_type 
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
