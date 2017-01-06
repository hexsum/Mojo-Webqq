use Encode ();
use Encode::Locale;
sub Mojo::Webqq::Client::_get_qrlogin_pic {
    my $self = shift;
    return 1 if $self->login_type ne "qrlogin";
    $self->info("正在获取登录二维码...");
    my $api = 'https://ssl.ptlogin2.qq.com/ptqrshow';
    my @query_string = (
        appid => $self->g_appid,
        e     => 0,
        l     => 'M',
        s     => 5,
        d     => 72,
        v     => 4,
        t     => rand(),
    );  
    my $url = $self->gen_url($api,@query_string);
    my $data = $self->http_get($url,{Referer=>'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'});
    if( not defined $data){
        $self->error("登录二维码下载失败");
        return 0;
    }
    $self->clean_qrcode();
    eval{
        die "未设置二维码保存路径\n" if not defined $self->qrcode_path;
        open(my $fh,">",$self->qrcode_path) or die "$!\n";
        binmode $fh;
        print $fh $data;
        close $fh;
    };
    
    if($@){
        $self->error("二维码写入文件失败: $@");
        return 0;
    }

    my $filename_for_log = Encode::encode("utf8",Encode::decode(locale_fs,$self->qrcode_path));
    #$self->info("二维码已下载到本地[ $filename_for_log ]\n二维码原始下载地址[ $url ]");
    $self->info("二维码已下载到本地[ $filename_for_log ]");
    $self->emit(input_qrcode=>$self->qrcode_path,$data);
    return 1;
}
1;
