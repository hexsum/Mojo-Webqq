sub Mojo::Webqq::Model::_get_discuss_list_info {
    my $self = shift;
    my $callback = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_discus_list';   
    my @query_string = (
        clientid    =>  $self->clientid,
        psessionid  =>  $self->psessionid,
        vfwebqq     =>  $self->vfwebqq,
        t           =>  time(),
    );
     
    my $headers = {
        Referer  => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
        json     => 1,
    };
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub {
        my $json = shift;
        return unless defined $json;
        return undef if $json->{retcode}!=0;  
        #{"retcode":0,"result":{"dnamelist":[{"name":"test","did":612950676}]}}
        for(@{ $json->{result}{dnamelist} }){
            $_->{id} = delete $_->{did};
        } 
        
        return $json->{result}{dnamelist};
    };
    if($is_blocking){
        return $handle->( $self->http_get($self->gen_url($api_url,@query_string),$headers,) );
    }
    else{
        $self->http_get($self->gen_url($api_url,@query_string),$headers,sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}

1;
