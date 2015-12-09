sub Mojo::Webqq::Model::_get_friends_state {
    my $self = shift;
    my $api_url = 'http://d1.web2.qq.com/channel/get_online_buddies2';
    my $headers  = {
        Referer => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
        json    => 1,
    };
    my @query_string = (
        vfwebqq         =>  $self->vfwebqq,
        clientid        =>  $self->clientid,
        psessionid      =>  $self->psessionid,
        t               =>  time,
    ); 
    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    return undef if $json->{retcode} !=0;
    for(@{$json->{result}}){
        $_->{client_type} = $self->code2client($_->{client_type});
        $_->{state} = $_->{status};
        delete $_->{status};
    }
    return $json->{result};
}
1;
