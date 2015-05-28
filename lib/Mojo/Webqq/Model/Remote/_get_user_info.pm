use strict;
sub Mojo::Webqq::Model::_get_user_info{
    my $self = shift;
    my $api_url ='http://s.web2.qq.com/api/get_self_info2';
    my $headers = {
        Referer     =>  'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
        json        =>  1,
    };
    my @query_string = (
        t               =>  time,
    ); 
    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    return undef if $json->{retcode} !=0;
    my $user = $json->{result};
    $user->{state} = $self->state;
    $user->{client_type} = 'web';
    $user->{birthday} = join( "-", @{ $user->{birthday} }{qw(year month day)} );
    $user->{signature} = delete $user->{lnick};
    #my $single_long_nick = $self->get_single_long_nick( $self->qq );
    #$json->{result}{signature} = $single_long_nick if defined $single_long_nick;
    $self->reform_hash($user);
    $user->{qq}        = $self->qq;
    $user->{id}        = delete $user->{uin};
    return $user;
}
1;
