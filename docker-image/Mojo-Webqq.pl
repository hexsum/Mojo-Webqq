#!/usr/bin/env perl
use Mojo::Webqq;
my ($qq,$host,$port,$post_api);
$qq   = $ENV{QQ};
$host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
$port = $ENV{PORT} || 5000;      #发送消息接口监听端口，修改为自己希望监听的端口
$post_api = $ENV{POST_API};  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

my $client = Mojo::Webqq->new(
    qq          =>  $qq,
    log_encoding=>  $ENV{LOG_ENCODING} || "utf8",
    log_level   =>  $ENV{LOG_LEVEL} || "info",
    ua_debug    =>  $ENV{UA_DEBUG} || 0,
    (defined $ENV{LOG_PATH}?(log_path =>  $ENV{LOG_PATH}):()),
    (defined $ENV{QRCODE_PATH}?(qrcode_path =>  $ENV{QRCODE_PATH}):()),
);
$client->load("ShowMsg");
$client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->load("UploadQRcode");
$client->run();
