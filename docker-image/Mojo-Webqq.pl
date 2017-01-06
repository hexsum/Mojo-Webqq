#!/usr/bin/env perl
use Mojo::Webqq;
my ($host,$port,$post_api);
$host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
$port = $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT} || 5000;      #发送消息接口监听端口，修改为自己希望监听的端口
$post_api = $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API};  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

#从环境变量读取new的参数，例如MOJO_WEBQQ_ACCOUNT/MOJO_WEBQQ_LOG_PATH
#参加文档 https://metacpan.org/pod/distribution/Mojo-Webqq/lib/Mojo/Webqq.pm#new
my $client = Mojo::Webqq->new();
$client->load("ShowMsg");
$client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->load("UploadQRcode");
$client->run();
