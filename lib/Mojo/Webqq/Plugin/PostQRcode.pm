package Mojo::Webqq::Plugin::PostQRcode;
our $PRIORITY = 0;
our $CALL_ON_LOAD = 1;
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
    $data->{max} =  10 if not defined $data->{max};
    #$data->{charset} =  "UTF-8" if not defined $data->{charset};
    my $count = 0;
    $client->on(login=>sub{$count = 0});
    $client->on(input_qrcode=>sub{
        my($client,$filename) = @_;
        if($count > $data->{max}){
            $client->fatal("等待扫描二维码超时");
            $client->stop();
            return 
        }
        $data->{subject} = "QQ帐号" . (defined $client->uid?$client->uid:$client->account) . "扫描二维码" if not defined $data->{subject};
        my $mime = MIME::Lite->new(
            Type    => 'multipart/mixed',
            From    => $data->{from},
            To      => $data->{to},
        );
        $mime->add("Subject"=>"=?UTF-8?B?" . MIME::Base64::encode_base64($data->{subject},"") . "?=");
        $mime->attach(
            Type     =>"text/plain; charset=UTF-8",
            Data     =>"请使用手机QQ扫描附件中的二维码",
        );
        $mime->attach(
            Path        => $filename,
            Disposition => 'attachment',
            Type        => 'image/png',
        );
        $data->{data} = $mime->as_string;
        my($is_success,$err) = $client->mail(%$data);
        if(not $is_success){
            if($data->{smtp} eq 'smtp.qq.com'){
                $client->error("插件[".__PACKAGE__."]邮件发送失败: " . $client->encode("utf8",$client->decode("gbk",$err)));
            }
            else{
                $client->error("插件[".__PACKAGE__."]邮件发送失败: $err");
            }
        }   
        else{
            $client->info("登录二维码已经发送到邮箱: $data->{to}");
        }
        $count++;
    });        
}
1;
