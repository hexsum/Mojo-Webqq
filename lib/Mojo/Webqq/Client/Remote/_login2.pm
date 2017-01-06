sub Mojo::Webqq::Client::_login2{
    my $self = shift;
    $self->info("尝试进行登录(2)...\n");
    my $api_url = 'http://d1.web2.qq.com/channel/login2';
    my $headers = {
        Referer     => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
        json        => 1,
    };
    my %r = (
        status      =>  $self->mode,
        ptwebqq     =>  $self->ptwebqq,
        clientid    =>  $self->clientid,
        psessionid  =>  $self->psessionid,  
    );    
    
    #if($self->{type} eq 'webqq'){
    #    $r{passwd_sig} = $self->passwd_sig;
    #}
    
    my $data = $self->http_post($api_url,$headers,form=>{r=>$self->to_json(\%r)});
    return 0 unless defined $data;
    if($data->{retcode} ==0){
        if(defined $self->uid and $self->uid ne $data->{result}{uin}){
            $self->fatal("实际登录帐号和程序预设帐号不一致");
            $self->stop();
            return 0;
        }
        $self->uid($data->{result}{uin})
             ->psessionid($data->{result}{psessionid})
             #->vfwebqq($data->{result}{vfwebqq})
             ->login_state('success')
             ->_cookie_proxy();
        return 1;
    }
    return 0;
}
1;
