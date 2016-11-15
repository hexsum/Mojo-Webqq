package Mojo::Webqq::Plugin::IPwhere;
our $PRIORITY = 1;
use IP::IPwhere;
#use IP::QQWry; #使用纯真库注释掉本行
use Encode;

=pod
本插件需要，安装模块IP::IPwhere，如果你需要纯真的信息
还要安装IP::QQWry，以及下载纯真的数据库QQWry.Dat
下载地址:

https://github.com/bollwarm/ipwhere/blob/master/QQWry.Dat
安装库可以简单通过cpanm IP::IPwhere IP::QQWry

并把下面部分注释掉。

my $qqwry = IP::QQWry->new('QQWry.Dat');

sub gquery {

my ($ip)=shift;
my ($base,$info) = $qqwry->query($ip);
my $result;
$result="qqwry $ip:";
$result.=decode('gbk',$base);
$result.=decode('gbk',$info)."\n";
return $result;

}
=cut

my $re=qr([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]);
my $ipre=qr/($re\.){3}$re$/;

sub call {
    my $client = shift;
    $client->on(receive_message=>sub{
        my($client,$msg)=@_;
        return if not $msg->allow_plugin;
        return if $msg->content !~ /IPwhere\s*($ipre)/;
        my $arg= $1 if $msg->content=~ /IPwhere\s*($ipre)/;
        $reply= Encode::encode("utf8",squery($arg));
#         $reply.=Encode::encode("utf8",gquery($arg)); # 如果需要解析纯真数据库，吧本行注释去掉
        $client->reply_message($msg,$reply,sub{$_[1]->msg_from("bot")}) if $reply;
    });
}
1;
