package Mojo::Webqq::Plugin::ShowMsg;
use POSIX qw(strftime);
sub call{
    my $client = shift;
    $client->on(
        receive_message=>sub{
            my($client,$msg)=@_; 
            if($msg->type eq 'message'){
                my $sender_nick = $msg->sender->markname || $msg->sender->nick;
                my $sender_categorie = $msg->sender->categorie || "好友";
                #my $receiver_nick = $msg->receiver->nick;
                my $receiver_nick = "我";
                $client->info({time=>$msg->msg_time,level=>"好友消息",title=>"$sender_nick|$sender_categorie :"},$msg->content);
                
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->gname;
                my $sender_nick = $msg->sender->card || $msg->sender->nick;
                $client->info({time=>$msg->msg_time,level=>"群消息",title=>"$sender_nick|$gname :"},$msg->content);
            }
            elsif($msg->type eq 'discuss_message'){
                my $dname = $msg->discuss->dname;
                my $sender_nick = $msg->sender->nick;
                $client->info({time=>$msg->msg_time,level=>"讨论组消息",title=>"$sender_nick|$dname :"},$msg->content);
            }
            elsif($msg->type eq 'sess_message'){
                my $sender_nick;
                my $receiver_nick = "我";
                my $gname;
                my $dname;
                if($msg->via eq "group"){
                    $sender_nick = $msg->sender->card||$msg->sender->nick;
                    $gname = $msg->group->gname;
                    $client->info({time=>$msg->msg_time,level=>"群临时消息",title=>"$sender_nick|$gname :"},$msg->content);
                }
                elsif($msg->via eq "discuss"){
                    $sender_nick = $msg->sender->nick;
                    $dname = $msg->discuss->dname;
                    $client->info({time=>$msg->msg_time,level=>"讨论组临时消息",title=>"$sender_nick|$dname :"},$msg->content);
                }
            }
        },
        send_message=>sub{
            my($client,$msg,$status)=@_;
            my $attach = $status->is_success?"":"[发送失败]";
            if($msg->type eq 'message'){
                my $sender_nick = "我";
                my $receiver_nick = $msg->receiver->markname || $msg->receiver->nick;
                $client->info({time=>$msg->msg_time,level=>"好友消息",title=>"$sender_nick->$receiver_nick :"},$msg->content . $attach);
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->gname;
                my $sender_nick = "我";
                $client->info({time=>$msg->msg_time,level=>"群消息",title=>"$sender_nick->$gname :"},$msg->content . $attach);
            }
            elsif($msg->type eq 'discuss_message'){
                my $dname = $msg->discuss->dname;
                my $sender_nick = "我";
                $client->info({time=>$msg->msg_time,level=>"讨论组消息",title=>"$sender_nick->$dname :"},$msg->content . $attach);
            }
            elsif($msg->type eq 'sess_message'){
                my $sender_nick = "我";
                my $receiver_nick;
                my $gname;
                my $dname;
                if($msg->via eq "group"){
                    $receiver_nick = $msg->receiver->card||$msg->receiver->nick;
                    $gname = $msg->group->gname;
                    $client->info({time=>$msg->msg_time,level=>"群临时消息",title=>"$sender_nick->$receiver_nick|$gname :"},$msg->content . $attach);
                }
                elsif($msg->via eq "discuss"){
                    $receiver_nick = $msg->receiver->nick;
                    $dname = $msg->discuss->dname;
                    $client->info({time=>$msg->msg_time,level=>"讨论组临时消息",title=>"$sender_nick->$receiver_nick|$dname :"},$msg->content . $attach);
                }
            }
        }
    );
}

1
