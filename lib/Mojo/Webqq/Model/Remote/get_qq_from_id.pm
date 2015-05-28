sub Mojo::Webqq::Model::get_qq_from_id{
    my $self = shift;
    my $uin = shift;
    my $cache_data =  $self->id_to_qq_cache->retrieve($uin);
    return $cache_data if defined $cache_data;
    my $api_url = 'http://s.web2.qq.com/api/get_friend_uin2';
    my $headers =  {Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my @query_string = (
        tuin            =>  $uin,
        type            =>  1,
        vfwebqq         =>  $self->vfwebqq,
        t               =>  time,
    );     
    
    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    return undef if $json->{retcode} !=0;
    $self->id_to_qq_cache->store($uin,$json->{result}{account});
    return $json->{result}{account};
}
1;
