use Webqq::Encryption qw(pwd_encrypt);
sub Mojo::Webqq::Client::_login1{ 
    my $self = shift;
    $self->info("尝试进行登录(阶段1)...\n");
    my $api_url = 'https://ssl.ptlogin2.qq.com/login';
    my $headers = {Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'};

    my $passwd;

    #if($self->{type} eq 'webqq'){
    #    $md5_salt = eval qq{"$self->{qq_param}{md5_salt}"};
    #    $passwd = pack "H*",$self->{qq_param}{pwd};
    #    $passwd = uc md5_hex( uc(md5_hex( $passwd . $md5_salt)) . uc( $self->{qq_param}{verifycode}  ) );
    #
    #}
    
    eval{
        $passwd = pwd_encrypt($self->pwd,$self->md5_salt,$self->verifycode,1) ;
    };
    if($@){
        $self->error("客户端加密算法执行错误：$@\n");
        return 0; 
    }
    
    my $query_string_ul = 'http%3A%2F%2Fw.qq.com%2Fproxy.html%3Flogin2qq%3D1%26webqq_type%3D10';
    my $query_string_action = '0-23-19230';
    
    my @query_string = (
        u               =>  $self->qq,
        p               =>  $passwd,
        verifycode      =>  $self->verifycode,
        webqq_type      =>  10,
        remember_uin    =>  1,
        login2qq        =>  1,
        aid             =>  $self->g_appid,
        u1              =>  $query_string_ul,
        h               =>  1,
        ptredirect      =>  0,
        ptlang          =>  2052,
        daid            =>  $self->g_daid,
        from_ui         =>  1,
        pttype          =>  1,  
        dumy            =>  undef,
        fp              =>  'loginerroralert',
        action          =>  $query_string_action,
        mibao_css       =>  $self->g_mibao_css,
        t               =>  1,
        g               =>  1,
        js_type         =>  0,
        js_ver          =>  $self->g_pt_version,
        login_sig       =>  $self->g_login_sig,
        pt_randsalt     =>  $self->isRandSalt, 
        pt_vcode_v1     =>  0,
        pt_verifysession_v1 =>   $self->verifysession || $self->search_cookie("verifysession"),
        
    );

    my $content = $self->http_get($self->gen_url($api_url,@query_string),$headers );
    return 0 unless defined $content;
    my %d = ();
    @d{qw( retcode unknown_1 api_check_sig unknown_2 status uin )} = $content=~/'(.*?)'/g;
    #ptuiCB('4','0','','0','您输入的验证码不正确，请重新输入。', '12345678');
    #ptuiCB('3','0','','0','您输入的帐号或密码不正确，请重新输入。', '2735534596');
        
    if($d{retcode} == 4){
        $self->error("您输入的验证码不正确，需要重新输入...\n");
        return -1;
    }
    elsif($d{retcode} == 3){
        $self->fatal("您输入的帐号或密码不正确，客户端终止运行...\n");
        $self->stop();
    }   
    elsif($d{retcode} != 0){
        $self->fatal("$d{status}，客户端终止运行...\n");
        $self->stop();
    }
    $self->api_check_sig($d{api_check_sig})
         ->ptwebqq($self->search_cookie('ptwebqq'));
    return 1;
}
1;

