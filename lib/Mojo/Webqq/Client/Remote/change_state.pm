sub Mojo::Webqq::Client::change_state{
    my $self = shift;
    my $state = shift;
    my $api_url = 'http://d1.web2.qq.com/channel/change_status2';
    my $headers  = {
        Referer => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
        json    => 1,
    };
    my @query_string = (
        newstatus       =>  $state,
        clientid        =>  $self->clientid,
        psessionid      =>  $self->psessionid,
        t               =>  time,
    ); 

    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    return undef if $json->{retcode} !=0;
    $self->state($state);
    $self->info("登录状态已修改为：$state\n");
    return $state;
}
1;
