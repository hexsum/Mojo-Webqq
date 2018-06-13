sub Mojo::Webqq::Client::_check_login {
    my $self = shift;
    $self->info("正在检查登录状态...");
    if($self->search_cookie("supertoken") and $self->search_cookie("superuin")){
        my $content = $self->http_get('https://ssl.ptlogin2.qq.com/pt4_auth?daid=164&appid=501004106&auth_token=' . $self->time33($self->search_cookie("supertoken")), {Referer => 'https://xui.ptlogin2.qq.com/cgi-bin/xlogin?daid=164&target=self&style=40&pt_disable_pwd=1&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2F' . $self->domain . '%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'}  );
        return 0 if not defined $content;
        my( $retcode,$api_check_sig) = $content=~/'(.*?)'/g;
        $self->info("登录状态检查结果($retcode)");
        if( $api_check_sig =~ /^https?:\/\/[^\/]+\.qq\.com\/check_sig/){
            $self->api_check_sig($api_check_sig . '&regmaster=&aid=501004106&s_url=http%3A%2F%2F'. $self->domain . '%2Fproxy.html');
            $self->info("检查结果：登录状态有效，尝试直接恢复登录...");
            return 1;
        }
        else{
            $self->info("检查结果：需要重新登录(1)");
            return 0;
        }
    }
    else{
        $self->info("检查结果：需要重新登录(2)");
        return 0;
    }
}
1;
