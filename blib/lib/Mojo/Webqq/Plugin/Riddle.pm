package Mojo::Webqq::Plugin::Riddle;
our $PRIORITY = 92;
use Encode;
use List::Util qw(first);
sub call{
    my $client = shift;
    my $data   = shift;
    my $flag   = 0;
    my $command = $data->{command} || "猜谜";
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        if($msg->type eq "group_message"){
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->name eq $_} @{$data->{allow_group}}
        }
        return if ref $data->{ban_user} eq "ARRAY" and first {$_=~/^\d+$/?$msg->sender->uid eq $_:$sender_nick eq $_} @{$data->{ban_user}};
        
        if($flag == 0  and $msg->content eq $command){
            $msg->allow_plugin(0);
            $client->steps(
                sub{
                    my $delay =shift;
                    $client->http_get('http://apis.baidu.com/gushi/grid/p1',{json=>1,apikey=>$data->{apikey}||'20d7db97e337ffa35ae0838439c9db5d'},form=>{count=>1,fmt=>0},$delay->begin(0,1));
                },
                sub{
                    my $delay = shift;
                    my $json = shift;
                    return if not defined $json;
                    return if $json->{status} != 0;
                    my $id = $json->{data}[0]{id} if ref $json->{data} eq "ARRAY";
                    return if not $id;
                    $client->http_get('http://apis.baidu.com/gushi/grid/p2',{json=>1,apikey=>$data->{apikey}||'20d7db97e337ffa35ae0838439c9db5d'},form=>{id=>$id,fmt=>0},sub{
                        my $json = shift;
                        return if not defined $json;
                        return if $json->{status} != 0;
                        return if ref $json->{data} ne "ARRAY";
                        my $answer = $json->{data}[0]{body};
                        $flag = 1; 
                        $msg->reply("文曲星君题戏三界($json->{data}[0]{id}):\n" . $json->{data}[0]{title},sub{$_[1]->from("bot")}); 

                        $client->wait(
                            $data->{timeout} || 30,#等待答案超时时间
                            sub{#超时公布答案
                                $flag = 0;
                                $msg->reply("本题答案：$answer\n偌大的三界之中,难道就没有能懂本星君心意之人么.\n吾独徘徊于天地之间,对酒影成双,知己难求,呜呼哉!");
                            },
                            receive_message=>sub{#查看是否有人给出正确答案
                                my($client,$msg,$timer_id) = @_;
                                return if $msg->content !~ /\Q$answer\E/;
                                $flag = 0;
                                $msg->reply("于千万人之中,文曲星君终于找到了有缘人:\n恭喜 \@" . $msg->sender->displayname . " 回答正确");                return 1;
                            }
                        );
                    });
                },
            );
        }
    }); 
}
1;
