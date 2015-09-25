package Mojo::Webqq::Plugin::PostQRcode;
our $PRIORITY = 0;
use MIME::Base64;
BEGIN{
    our $has_mime_lite = 0;
    eval{require MIME::Lite;};
    $has_mime_lite = 1 if not $@;
}
sub call{
    my $client = shift;
    my $data   = shift;
    $client->die("插件[". __PACKAGE__ ."]依赖模块 MIME::Lite，请先确认该模块已经正确安装") if not $has_mime_lite;
    my $max = $data->{max} || 10;
    my $count = 0;
    $client->on(login=>sub{$count = 0});
    $client->on(input_qrcode=>sub{
        my($client,$filename) = @_;
        if($count > $max){
            $client->fatal("等待扫描二维码超时");
            $client->stop();
            return 
        }
        my $subject = $data->{subject} || "QQ帐号 " . $client->qq . " 扫描二维码";
        my $mime = MIME::Lite->new(
            Type    => 'multipart/mixed',
            From    => $data->{from},
            To      => $data->{to},
        );
        $mime->add("Subject"=>"=?UTF-8?B?" . MIME::Base64::encode_base64($subject,"") . "?=");
        $mime->attach(
            Type     =>'TEXT',
            Data     =>"请使用手机QQ扫描附件中的二维码",
        );
        $mime->attach(
            Path        => $filename,
            Disposition => 'attachment',
            Type        => 'image/png',
        );
        my($is_success,$err) = $client->mail(
            smtp=>$data->{smtp},
            port=>$data->{port},
            user=>$data->{user},
            pass=>$data->{pass},
            from=>$data->{from},
            to  =>$data->{to}, 
            subject=>$subject,
            data=>$mime->as_string,
        );
        if(not $is_success){
            $client->error("插件[".__PACKAGE__."]邮件发送失败: $err");
        }   
        $count++;
    });        
}
1;
