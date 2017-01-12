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
            if($msg->type eq 'friend_message'){
                my $sender_nick = $msg->sender->displayname;
                my $sender_category = $msg->sender->category || "好友";
                #my $receiver_nick = $msg->receiver->nick;
                my $receiver_nick = "我";
                $client->msg({time=>$msg->time,level_color=>'green',level=>"好友消息",title_color=>'green',title=>"$sender_nick|$sender_category :",content_color=>'green'},$msg->content);
                
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->name;
                my $sender_nick = $msg->sender->displayname;
                return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->uid eq $_:$gname eq $_} @{$data->{ban_group}};
                return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$gname eq $_} @{$data->{allow_group}};
                $client->msg({time=>$msg->time,level_color=>'cyan',level=>"群消息",title_color=>'cyan',title=>"$sender_nick|$gname :",content_color=>'cyan'},$msg->content);
            }
            elsif($msg->type eq 'discuss_message'){
                my $dname = $msg->discuss->name;
                my $sender_nick = $msg->sender->displayname;
                $client->msg({time=>$msg->time,level_color=>'magenta',level=>"讨论组消息",title_color=>'magenta',title=>"$sender_nick|$dname :",content_color=>'magenta'},$msg->content);
            }
            elsif($msg->type eq 'sess_message'){
                my $sender_nick;
                my $receiver_nick = "我";
                my $gname;
                my $dname;
                if($msg->via eq "group"){
                    $sender_nick = $msg->sender->displayname;
                    $gname = $msg->group->name;
                    $client->msg({time=>$msg->time,level_color=>'green',level=>"群临时消息",title_color=>'green',title=>"$sender_nick|$gname :",content_color=>'green'},$msg->content);
                }
                elsif($msg->via eq "discuss"){
                    $sender_nick = $msg->sender->displayname;
                    $dname = $msg->discuss->name;
                    $client->msg({time=>$msg->time,level_color=>'green',level=>"讨论组临时消息",title_color=>'green',title=>"$sender_nick|$dname :",content_color=>'green'},$msg->content);
                }
            }
        },
        send_message=>sub{
            my($client,$msg)=@_;
            my $attach = '';
            if($msg->is_success){
                if($client->log_level eq 'debug' and defined $msg->info and $msg->info ne "发送正常" ){
                    $attach = "[" . $msg->info . "]";
                }
            }
            else{
                $attach = "[发送失败".(defined $msg->info?"(".$msg->info.")":"") . "]";
            }
            if($msg->type eq 'friend_message'){
                my $sender_nick = "我";
                my $receiver_nick = $msg->receiver->displayname;
                $client->msg({time=>$msg->time,level_color=>'green',level=>"好友消息",title_color=>'green',title=>"$sender_nick->$receiver_nick :",content_color=>'green'},$msg->content . $attach);
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->name;
                my $sender_nick = "我";
                $client->msg({time=>$msg->time,level_color=>'cyan',level=>"群消息",title_color=>'cyan',title=>"$sender_nick->$gname :",content_color=>'cyan'},$msg->content . $attach);
            }
            elsif($msg->type eq 'discuss_message'){
                my $dname = $msg->discuss->name;
                my $sender_nick = "我";
                $client->msg({time=>$msg->time,level_color=>'magenta',level=>"讨论组消息",title_color=>'magenta',title=>"$sender_nick->$dname :",content_color=>'magenta'},$msg->content . $attach);
            }
            elsif($msg->type eq 'sess_message'){
                my $sender_nick = "我";
                my $receiver_nick;
                my $gname;
                my $dname;
                if($msg->via eq "group"){
                    $receiver_nick = $msg->receiver->displayname;
                    $gname = $msg->group->name;
                    $client->msg({time=>$msg->time,level_color=>'green',level=>"群临时消息",title_color=>'green',title=>"$sender_nick->$receiver_nick|$gname :",content_color=>'green'},$msg->content . $attach);
                }
                elsif($msg->via eq "discuss"){
                    $receiver_nick = $msg->receiver->displayname;
                    $dname = $msg->discuss->name;
                    $client->msg({time=>$msg->time,level_color=>'green',level=>"讨论组临时消息",title_color=>'green',title=>"$sender_nick->$receiver_nick|$dname :",content_color=>'green'},$msg->content . $attach);
                }
            }
        }
    );
}

1;
