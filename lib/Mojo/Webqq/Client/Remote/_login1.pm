sub Mojo::Webqq::Client::_login1{ 
    my $self = shift;
    my $login_type = $self->login_type;
    $self->info("正在进行登录(1)...") if $login_type eq "login";
    if($login_type eq "qrlogin"){
        my $headers = {Referer => 'https://xui.ptlogin2.qq.com/cgi-bin/xlogin?daid=164&target=self&style=40&pt_disable_pwd=1&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'};
        my @query_string = (
            u1              => 'http%3A%2F%2Fw.qq.com%2Fproxy.html',
            ptqrtoken       => $self->hash33($self->search_cookie("qrsig")),
            ptredirect      => 0,
            h               => 1,
            t               => 1,
            g               => 1,
            from_ui         => 1,
            ptlang          => 2052,
            action          => '0-0-1516082717616',
            js_ver          => 10233,
            js_type         => 1,
            login_sig       => $self->pt_login_sig,
            pt_uistyle      => 40,
            aid             => 501004106,
            daid            => 164,
            mibao_css       => 'm_webqq',
        );
        my $content = $self->http_get($self->gen_url('https://ssl.ptlogin2.qq.com/ptqrlogin',@query_string) . '&' ,$headers );
        return 0 unless defined $content;
        #ptuiCB('4','0','','0','您输入的验证码不正确，请重新输入。', '12345678');
        #ptuiCB('3','0','','0','您输入的帐号或密码不正确，请重新输入。', '2735534596');
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
            $self->api_check_sig($d{api_check_sig})->ptwebqq($self->search_cookie('ptwebqq'));
            return 1;
        }
        elsif($d{retcode} != 0){
            $self->fatal("$d{status}，客户端终止运行...\n");
            $self->stop();
            return 0;
        }
    }
    elsif($login_type eq "login"){
        my $ret = $self->model_ext_authorize();
        if($ret == 1){
            $self->info("账号密码方式登录成功");
            $self->uid($self->account);
            $self->ptwebqq($self->search_cookie('ptwebqq'));
            return 1;
        }
        else{
            $self->warn("账号密码登录方式失败，尝试使用二维码登录");
            $self->login_type('qrlogin');
            return -3;
        }
    }
    return 1;
}
1;

