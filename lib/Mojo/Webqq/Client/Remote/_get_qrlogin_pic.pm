use Encode;
use Encode::Locale;
use File::Temp qw/tempfile/;
sub Mojo::Webqq::Client::_get_qrlogin_pic {
    my $self = shift;
    return 1 if $self->login_type ne "qrlogin";
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
    my $data = $self->http_get($self->gen_url($api,@query_string),{Referer=>'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001'});
    if( not defined $data){
        $self->error("登录二维码下载失败");
        return 0;
    }
    my ($fh, $filename);
    eval{
        if(defined $self->qrcode_path){
            $filename = $self->qrcode_path;
            unlink $filename;
            open $fh,">",$filename or die "Can't open $filename: $!";
        }
        else{ 
            ($fh, $filename) = tempfile("webqq_qrcode_XXXX",SUFFIX =>".png",DIR => $self->tmpdir);
        }
        binmode $fh;
        print $fh $data;
        close $fh;
    };
    
    if($@){
        $self->error("验证码写入文件失败");
        return 0;
    }

    my $filename_for_log = encode("utf8",decode(locale_fs,$filename));
    my $info = $self->log->format->(time,"info","二维码已下载到本地[ $filename_for_log ]");
    $self->log->append($info);
    return $filename;
}
1;
