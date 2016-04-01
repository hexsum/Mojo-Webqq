package Mojo::Webqq::Plugin::ShowMsg;
our $PRIORITY = 100;
use POSIX qw(strftime);
use List::Util qw(first);
sub call{
    my $client = shift;
    my $data = shift;
    $client->on(
        receive_message=>sub{
            my($client,$msg)=@_; 
            if($msg->type eq 'message'){
                my $sender_nick = $msg->sender->displayname;
                my $sender_category = $msg->sender->category || "好友";
                #my $receiver_nick = $msg->receiver->nick;
                my $receiver_nick = "我";
                $client->info({time=>$msg->msg_time,level=>"好友消息",title=>"$sender_nick|$sender_category :"},$msg->content);
                
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->gname;
                my $sender_nick = $msg->sender->displayname;
                return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->gnumber eq $_:$gname eq $_} @{$data->{ban_group}};
                return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->gnumber eq $_:$gname eq $_} @{$data->{allow_group}};
                $client->info({time=>$msg->msg_time,level=>"群消息",title=>"$sender_nick|$gname :"},$msg->content);
            }
            elsif($msg->type eq 'discuss_message'){
                my $dname = $msg->discuss->dname;
                my $sender_nick = $msg->sender->displayname;
                $client->info({time=>$msg->msg_time,level=>"讨论组消息",title=>"$sender_nick|$dname :"},$msg->content);
            }
            elsif($msg->type eq 'sess_message'){
                my $sender_nick;
                my $receiver_nick = "我";
                my $gname;
                my $dname;
                if($msg->via eq "group"){
                    $sender_nick = $msg->sender->displayname;
                    $gname = $msg->group->gname;
                    $client->info({time=>$msg->msg_time,level=>"群临时消息",title=>"$sender_nick|$gname :"},$msg->content);
                }
                elsif($msg->via eq "discuss"){
                    $sender_nick = $msg->sender->displayname;
                    $dname = $msg->discuss->dname;
                    $client->info({time=>$msg->msg_time,level=>"讨论组临时消息",title=>"$sender_nick|$dname :"},$msg->content);
                }
            }
        },
        send_message=>sub{
            my($client,$msg,$status)=@_;
            my $attach = '';
            if($status->is_success){
                if(defined $status->info and $status->info ne "发送正常" ){
                    $attach = "[" . $status->info . "]";
                }
            }
            else{
                $attach = "[发送失败".(defined $status->info?"(".$status->info.")":"") . "]";
            }
            if($msg->type eq 'message'){
                my $sender_nick = "我";
                my $receiver_nick = $msg->receiver->displayname;
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
                    $receiver_nick = $msg->receiver->displayname;
                    $gname = $msg->group->gname;
                    $client->info({time=>$msg->msg_time,level=>"群临时消息",title=>"$sender_nick->$receiver_nick|$gname :"},$msg->content . $attach);
                }
                elsif($msg->via eq "discuss"){
                    $receiver_nick = $msg->receiver->displayname;
                    $dname = $msg->discuss->dname;
                    $client->info({time=>$msg->msg_time,level=>"讨论组临时消息",title=>"$sender_nick->$receiver_nick|$dname :"},$msg->content . $attach);
                }
            }
        }
    );
}

1
