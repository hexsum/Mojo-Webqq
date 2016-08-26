sub Mojo::Webqq::Client::_check_verify_code{
    my $self = shift;
    return 1 if $self->login_type eq "qrlogin";
    $self->info("检查验证码...\n") if $self->login_type eq "login";
    my $api_url = 'https://ssl.ptlogin2.qq.com/check';
    my $headers = {Referer=>'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'};

    my $query_string_ul = 'http%3A%2F%2Fw.qq.com%2Fproxy.html';
    my @query_string = (
        pt_tea      =>  ($self->login_type eq "qrlogin"?2:1),
        uin         =>  $self->qq,
        appid       =>  $self->g_appid,
        js_ver      =>  $self->g_pt_version,
        js_type     =>  0,
        login_sig   =>  $self->g_login_sig,
        u1          =>  $query_string_ul,
        r           =>  rand(),
    ); 
    
    $self->ua->cookie_jar->add(
        Mojo::Cookie::Response->new(
            name   => "chkuin",
            value  => $self->qq,
            domain => "ptlogin2.qq.com", 
            path   => "/",
        )
    );
    my $content = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return 0 unless defined $content;
    my %d = ();
    @d{qw( retcode cap_cd md5_salt ptvfsession isRandSalt)} = $content=~/'(.*?)'/g ;
    $self->md5_salt($d{md5_salt})
         ->cap_cd($d{cap_cd})
         ->isRandSalt($d{isRandSalt})
         ->pt_verifysession($d{ptvfsession});
    if($d{retcode} ==0){
        $self->info("检查结果: 很幸运，本次登录不需要验证码\n") if $self->login_type eq "login";
        $self->verifycode($d{cap_cd});
    }
    elsif($d{retcode} == 1){
        $self->info("检查结果: 需要输入图片验证码\n")->is_need_img_verifycode(1) if $self->login_type eq "login";
    }
    return 1;
}
1;
