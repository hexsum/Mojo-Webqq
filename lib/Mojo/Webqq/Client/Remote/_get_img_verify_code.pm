use Encode;
use Encode::Locale;
sub Mojo::Webqq::Client::_get_img_verify_code{
    my $self = shift;
    return 1 if $self->login_type ne "login";
    #return 1 if not $self->is_need_img_verifycode ;
    $self->verifycode(undef);
    my $api_url = 'https://ssl.captcha.qq.com/getimage';
    my $headers ={Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'};
    my @query_string = (
        aid        => $self->g_appid,
        r          => rand(),
        uin        => $self->qq, 
        cap_cd     => $self->cap_cd,
    );    

    my $content = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    unless(defined $content){
        $self->error("验证码下载失败");
        return 0;
    }
    $self->clean_verifycode();
    eval{
        die "未定义验证码保存路径\n" if not defined $self->verifycode_path;
        open(my $fh,">",$self->verifycode_path) or die "$!\n";
        binmode $fh;
        print $fh $content;
        close $fh; 
    };
    if($@){
        $self->error("验证码写入文件失败: $@"); 
        return 0;
    }
    if($self->has_subscribers("input_img_verifycode")){
        $self->emit(input_img_verifycode => $self->verifycode_path);
        if(defined $self->verifycode){return 1;}
        else{$self->fatal("无法从回调函数中获取有效的验证码");$self->stop();return 0;}
    }
    elsif(-t STDIN){
        my $filename_for_console = encode("utf8",decode(locale_fs,$self->verifycode_path));
        my $info = $self->log->format->(time,"info","请输入图片验证码 [ $filename_for_console ]: ");
        chomp($info);
        $self->log->append($info);
        my $verifycode = <STDIN>;
        chomp($verifycode);
        $self->verifycode($verifycode);
        return 1;
    }
    else{
        $self->fatal("未连接到终端，无法获取验证码\n");
        $self->stop();
        return 0;
    }
    return 0;
}
1;
