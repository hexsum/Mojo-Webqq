package Mojo::Webqq::Plugin::Riddle;
our $PRIORITY = 92;
use Encode;
sub call{
    my $client = shift;
    my $data   = shift;
    my $flag   = 0;
    my $command = $data->{command} || "猜谜";
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        if($msg->type eq "group_message"){
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->gnumber eq $_:$msg->group->gname eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->gnumber eq $_:$msg->group->gname eq $_} @{$data->{allow_group}}
        }
        return if ref $data->{ban_user} eq "ARRAY" and first {$_=~/^\d+$/?$msg->sender->qq eq $_:$sender_nick eq $_} @{$data->{ban_user}};
        
        if($flag == 0  and $msg->content eq $command){
            $client->http_get('http://apis.baidu.com/myml/c1c/c1c',{json=>1,apikey=>$data->{apikey}||'f23168e0956fe11f6fc44ee61dbfa002'},form=>{id=>-1},sub{
                my $json = shift;
                return if not defined $json;
                my $answer = encode("utf8",$json->{Answer});
                $flag = 1; 
                $msg->reply("文曲星君题戏三界($json->{id}):\n" . encode("utf8",$json->{Title}),sub{$_[1]->msg_from("bot")}); 

                $client->wait(
                    30,#等待答案超时时间
                    sub{#超时公布答案
                        $flag = 0;
                        $msg->reply("本题答案：$answer\n偌大的三界之中,难道就没有能懂本星君心意之人么.\n吾独徘徊于天地之间,对酒影成双,知己难求,呜呼哉!");
                    },
                    receive_message=>sub{#查看是否有人给出正确答案
                        my($client,$msg,$timer_id) = @_;
                        return if $msg->content !~ /\Q$answer\E/;
                        $flag = 0;
                        $msg->reply("于千万人之中,文曲星君终于找到了有缘人:\n恭喜 \@" . $msg->sender->displayname . " 回答正确");                      return 1;
                    }
                );
            }); 
        }
    }); 
}
1;
