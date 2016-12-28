=encoding utf8
=head1 SYNOPSIS
使用帮助

-h          打印帮助内容
-id         对象(好友、群成员、讨论组成员)的id
-uid        对象(好友、群成员、讨论组成员)的qq号码
-gid        群的id
-guid       群号码
-did        讨论组的id

发送消息示例：

好友消息         ./script -id 123456 你好
                 ./script -uid 123456 你好

群消息           ./script -gid 123456 你好
                 ./script -guid 123456 你好

群临时消息       ./script -gid 123456 -id 123456 你好
                 ./script -guid 123456 -uid 123456 你好

讨论组临时消息   ./script -did 123456 -id 123456 你好
=cut
use strict;
use Getopt::Long;
use Mojo::UserAgent;
use Mojo::Util qw(url_escape encode decode);
my %API = (
    send_friend_message   =>  'http://127.0.0.1:5000/openqq/send_friend_message',
    send_group_message   =>  'http://127.0.0.1:5000/openqq/send_group_message',
    send_discuss_message =>  'http://127.0.0.1:5000/openqq/send_discuss_message',
    send_sess_message    =>  'http://127.0.0.1:5000/openqq/send_sess_message',
);
my $ua = Mojo::UserAgent->new;
if($ARGV[0] eq "-l" or $ARGV[0] eq "-list"){
    my $friend = $ua->get("http://127.0.0.1:5000/openqq/get_friend_info")->res->json;
    print "好友:\n";
    for(@{$friend}){
        print $_->{id},"\t",encode("utf8",$_->{name}),"\n";
    }
    print "群组:\n";
    my $group = $ua->get("http://127.0.0.1:5000/openqq/get_group_info")->res->json;
    for(@{$group}){
        print $_->{id},"\t",encode("utf8",$_->{name}),"\n";
    }
    exit;
}
elsif(@ARGV == 0 or $ARGV[0] eq "-h" or $ARGV[0] eq "--help"){
    print <<USAGE;

使用帮助

-h          打印帮助内容
-id         对象(好友、群成员、讨论组成员)的id
-uid        对象(好友、群成员、讨论组成员)的qq号码
-gid        群的id
-guid       群号码
-did        讨论组的id

发送消息示例：

好友消息         ./script -id 123456 你好
                 ./script -uid 123456 你好

群消息           ./script -gid 123456 你好
                 ./script -guid 123456 你好

群临时消息       ./script -gid 123456 -id 123456 你好
                 ./script -guid 123456 -uid 123456 你好

讨论组临时消息   ./script -did 123456 -id 123456 你好
使用帮助

USAGE
exit;
}
my ($id,$uid,$guid,$gid,$did,@content,$content);
GetOptions (
    "gid=i" => \$gid,
    "id=i" => \$id,
    "did=i" => \$did,
    "uid=i" => \$uid,
    "guid=i" => \$guid,
    "<>"    =>  sub{push @content ,$_[0]},
)or die $!;
$content = join " ",@content;
$content=~s/\\n/\n/g;
$content = url_escape( $content);
die "需要输入发送内容\n" unless defined $content;

my $tx;
if(defined $gid and defined $id){
    $tx = $ua->get($API{"send_sess_message"} . "?group_id=$gid&id=$id&content=$content");
}
elsif(defined $did and defined $id) {
    $tx = $ua->get($API{"send_sess_message"} . "?discuss_id=$did&id=$id&content=$content");
}
elsif(defined $gid){
    $tx = $ua->get($API{"send_group_message"} . "?id=$gid&content=$content");
}
elsif(defined $did){
    $tx = $ua->get($API{"send_discuss_message"} . "?id=$did&content=$content");
}
elsif(defined $id){
    $tx = $ua->get($API{"send_friend_message"} . "?id=$id&content=$content");
}
elsif(defined $guid and defined $uid){
    $tx = $ua->get($API{"send_sess_message"} . "?group_uid=$guid&uid=$uid&content=$content");
}
elsif(defined $guid){
    $tx = $ua->get($API{"send_group_message"} . "?uid=$guid&content=$content");
}
elsif(defined $uid){
    $tx = $ua->get($API{"send_friend_message"} . "?uid=$uid&content=$content");
}
else{
    die "参数错误\n";
}
warn $tx->req->to_string;
warn $tx->res->to_string;
