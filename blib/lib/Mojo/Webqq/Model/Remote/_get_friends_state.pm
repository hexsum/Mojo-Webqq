sub Mojo::Webqq::Model::_get_friends_state {
    my $self = shift;
    my $callback = shift;
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
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub {
        my $json = shift;
        return undef unless defined $json;
        return undef if $json->{retcode} !=0;
        for(@{$json->{result}}){
            $_->{client_type} = $self->code2client($_->{client_type});
            $_->{state} = $_->{status};
            delete $_->{status};
        }
        return $json->{result};
    };
    if($is_blocking){
        return $handle->(  $self->http_get($self->gen_url($api_url,@query_string),$headers,) );
    }
    else{
        $self->http_get($self->gen_url($api_url,@query_string),$headers,sub{
            my $json = shift;
            $callback->( $handle->($json));
        });
    }
}
1;
