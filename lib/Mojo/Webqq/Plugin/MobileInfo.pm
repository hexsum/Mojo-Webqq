package Mojo::Webqq::Plugin::MobileInfo;
our $PRIORITY = 93;
use Mojo::DOM;
use Encode;

sub call{
    my $client = shift;
    my $data = shift;
    my $callback = sub{
        my($client,$msg)=@_;
        return if $msg->class eq "send" and $msg->from ne "api" and $msg->from ne "irc";
        if ($msg->content =~ m/^手机\s+([0-9]{7,11})/g) {
            my $phone = $1;
            return unless $phone;
            $msg->allow_plugin(0);
            my $reply;
            my $sender_nick = $msg->sender->displayname;
            $client->http_get("http://www.ip138.com:8080/search.asp?mobile=$phone&action=mobile",sub{
                my $data = shift;
                return unless defined $data;
                $data =~ s/&nbsp;//g;
                my $dom = Mojo::DOM->new($data);
                my @commands = $dom->find('td.tdc2')->each;#获取所有的子命令
                #$client->debug(encode('utf8',decode('gbk',join("  ",@commands))));
                if (scalar(@commands) == 5) {
                    $reply .= "\@$sender_nick 您查询的手机号码信息如下:\n";
                    $reply .= "手机号: ".(shift @commands)->text."\n";
                    $reply .= "归属地: ".encode("utf8",decode("gbk",(shift @commands)->text))."\n";
                    $reply .= "卡类型: ".encode("utf8",decode("gbk",(shift @commands)->text))."\n";
                    $reply .= "区  号: ".(shift @commands)->text."\n";
                    $reply .= "邮  编: ".(shift @commands)->text;
                }
                unless ($reply) {
                    return;
                }
                $client->reply_message($msg,$reply);
            });
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}
1;
