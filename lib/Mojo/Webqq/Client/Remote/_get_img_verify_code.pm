use File::Temp qw/tempfile/;
sub Mojo::Webqq::Client::_get_img_verify_code{
    my $self = shift;
    if ($self->is_need_img_verifycode == 0){
        $self->img_verifycode_source('NONE');
        return 1 ;
    }
    my $api_url = 'https://ssl.captcha.qq.com/getimage';
    my $headers ={Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'};
    my @query_string = (
        aid        => $self->g_appid,
        r          => rand(),
        uin        => $self->qq, 
        cap_cd     => $self->cap_cd,
    );    

    my $content = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return 0 unless defined $content;
    my ($fh, $filename) = tempfile("webqq_img_verfiy_XXXX",SUFFIX =>".jpg",TMPDIR => 1);
    binmode $fh;
    print $fh $content;
    close $fh; 
    if(-t STDIN){
        my $info = $self->log->format->(time,"info","请输入图片验证码 [ $filename ]: ");
        chomp $info;
        $self->log->append($info);
        my $verifycode = <STDIN>;
        chomp($verifycode);
        $self->verifycode($verifycode)
             ->img_verifycode_source('TTY');
        return 1;
    }
    elsif($self->has_subscribers("input_img_verifycode")){
        $self->emit(input_img_verifycode => $filename);
        if(defined $self->verifycode){
            $self->img_verifycode_source('CALLBACK');
            return 1;
        }
        else{$self->fatal("无法从回调函数中获取有效的验证码，客户端终止\n");$self->stop();}
    }
    else{
        $self->fatal("STDIN未连接到tty，无法输入验证码，客户端终止...\n");
        $self->stop();
    }
    return 0;
}
1;
