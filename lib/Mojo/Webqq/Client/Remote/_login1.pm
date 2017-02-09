#use Webqq::Encryption qw(pwd_encrypt pwd_encrypt_js);
sub Mojo::Webqq::Client::_login1{ 
    my $self = shift;
    my $login_type = $self->login_type;
    $self->info("尝试进行登录(1)...\n") if $login_type eq "login";
    my $api_url = 'https://ssl.ptlogin2.qq.com/' . ($login_type eq "qrlogin"?"ptqrlogin":"login");
    my $headers = {Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'};

    my @query_string;
    my $query_string_ul = 'http%3A%2F%2Fw.qq.com%2Fproxy.html%3Flogin2qq%3D1%26webqq_type%3D10';
    my $query_string_action = '0-23-19230';
    if($login_type eq "login"){
        if(not defined $self->account){
            $self->fatal("未设置登录帐号, 无法登录");
            $self->stop();
            return 0;
        }
        if(not defined $self->pwd){
            $self->fatal("未设置登录密码, 无法登录");
            $self->stop();
            return 0;
        }
        eval{require Webqq::Encryption;};
        if($@){
            $self->fatal("帐号密码登录模式需要模块 Webqq::Encryption ,请先确保该模块正确安装");
            $self->stop();
            return 0;
        }
        my $passwd;
        #if($self->type eq 'webqq'){
        #    require Mojo::Util;
        #    my $md5_salt = $self->md5_salt;
        #    $md5_salt = eval qq{"$md5_salt"};
        #    $passwd = pack "H*",$self->pwd;
        #    $passwd = uc Mojo::Util::md5_sum( uc(Mojo::Util::md5_sum( $passwd . $md5_salt)) . uc( $self->verifycode));
        #}
        eval{
            if($self->encrypt_method eq "perl"){
                $passwd = Webqq::Encryption::pwd_encrypt($self->pwd,$self->md5_salt,$self->verifycode,1) ;
            }
            else{
                $passwd = Webqq::Encryption::pwd_encrypt_js($self->pwd,$self->md5_salt,$self->verifycode,1) ;
            }
        };
        if($@){
            $self->error("客户端加密算法执行错误：$@\n");
            return $self->encrypt_method eq "perl"?-2:-3; 
        }
        @query_string = (
            u               =>  $self->account,
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
            pt_verifysession_v1 =>   $self->pt_verifysession || $self->search_cookie("verifysession"),
            
        );
    }
    elsif($login_type eq "qrlogin"){
        @query_string = (
            ptqrtoken       => $self->hash33($self->search_cookie("qrsig")),
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
            t               =>  'undefined',
            g               =>  1,
            js_type         =>  0,
            js_ver          =>  $self->g_pt_version,
            login_sig       =>  undef,
            pt_randsalt     =>  $self->isRandSalt, 
        );
    }

    my $content = $self->http_get($self->gen_url($api_url,@query_string),$headers );
    return 0 unless defined $content;
    #ptuiCB('4','0','','0','您输入的验证码不正确，请重新输入。', '12345678');
    #ptuiCB('3','0','','0','您输入的帐号或密码不正确，请重新输入。', '2735534596');
    if($login_type eq "login"){
        my %d = ();
        @d{qw( retcode unknown_1 api_check_sig unknown_2 status uin )} = $content=~/'(.*?)'/g;
        if($d{retcode} == 4){
            $self->error("您输入的验证码不正确，需要重新输入...\n");
            return -1;
        }
        elsif($d{retcode} == 3){
            if($self->encrypt_method eq "perl"){
                return -2;
            }
            else{
                $self->fatal("您输入的帐号或密码不正确，客户端终止运行...\n");
                $self->stop();
                return 0;
            }
        }   
        elsif($d{retcode} != 0){
            $self->fatal("$d{status}，客户端终止运行...\n");
            $self->stop();
            return 0;
        }
        $self->api_check_sig($d{api_check_sig})->ptwebqq($self->search_cookie('ptwebqq'));
    }
    elsif($login_type eq "qrlogin"){
        my %d = ();
        @d{qw( retcode unknown_1 api_check_sig unknown_2 status nick )} = $content=~/'(.*?)'/g;
        if($d{retcode} == 65){
            $self->info("登录二维码已失效，重新获取二维码");
            return -6;
        }     
        elsif($d{retcode} == 66){
            $self->info("等待手机QQ扫描二维码...\n") if $self->login_state ne 'scaning';
            $self->login_state('scaning');
            $self->state('scaning');
            return -4;
        }
        elsif($d{retcode} == 67){
            $self->info("手机QQ扫码成功，请在手机上点击[允许登录smartQQ]按钮...") if $self->login_state ne 'confirming';
            $self->login_state('confirming');
            $self->state('confirming');
            return -5;
        }
        #elsif($d{retcode} == 10005){
        #
        #}
        #elsif($d{retcode} == 10006){
        #
        #}
        elsif($d{retcode} == 0){
            my $qrlogin_id = $self->search_cookie("uin");
            my $id = substr($qrlogin_id,1,) + 0;
            if(!defined $id or $id !~/^\d+$/){
                $self->fatal("无法获取到登录帐号");
                $self->stop();
                return 0;
            }
            elsif($self->check_account and $self->account=~/^\d+$/ and $self->account ne $id){
                $self->fatal("实际登录帐号和程序预设帐号不一致");
                $self->stop();
                return 0;
            }
            $self->uid($id);
            $self->api_check_sig($d{api_check_sig})->ptwebqq($self->search_cookie('ptwebqq'));;
            return 1;
        }
        elsif($d{retcode} != 0){
            $self->fatal("$d{status}，客户端终止运行...\n");
            $self->stop();
            return 0;
        }
    }
    return 1;
}
1;

