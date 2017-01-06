sub Mojo::Webqq::Message::_get_sess_sig {
    my $self = shift;
    my($id,$to_uin,$service_type,) = @_;
    my $cache_data = $self->sess_sig_cache->retrieve("$id|$to_uin|$service_type");
    return $cache_data if defined $cache_data;
    my $api_url = 'http://d1.web2.qq.com/channel/get_c2cmsg_sig2';
    my @query_string  = (
        id              =>  $id,
        to_uin          =>  $to_uin,
        service_type    =>  $service_type,
        clientid        =>  $self->clientid,
        psessionid      =>  $self->psessionid,
        t               =>  time,
    ); 
    my $headers = {Referer=>'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',json=>1};
    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    return undef if $json->{retcode}!=0;
    return undef if $json->{result}{value} eq "";
    $self->sess_sig_cache->store("$id|$to_uin|$service_type",$json->{result}{value},300);
    return $json->{result}{value} ;
}
1;
