package Mojo::Webqq::Plugin::MsgSync;
use strict;
use Encode;
use List::Util qw(first);
$Mojo::Webqq::Plugin::MsgSync::is_hold_mojo_irc;
BEGIN{
    local $SIG{__WARN__}=sub{};
    eval{require Mojo::IRC;};
    $Mojo::Webqq::Plugin::MsgSync::is_hold_mojo_irc = 1 unless $@;
}
my @ircs;
my @groups;
sub call{
    my $client = shift;
    my $data = shift;
    $client->die(__PACKAGE__ . "依赖Mojo::IRC模块，请先安装该模块") if !$Mojo::Webqq::Plugin::MsgSync::is_hold_mojo_irc;
    return if ref $data ne "ARRAY";
    for(@$data){
        if(ref $_ eq "Mojo::Webqq::Group"){
            push @groups,$_; 
        }
        elsif(ref $_ eq "HASH"){
            $_->{server} = "irc.freenode.net" unless defined $_->{server};
            $_->{port}   = 6667 unless defined $_->{port};
            $_->{channel} = "#ChinaPerl" unless defined $_->{channel};
            push @ircs,$_;
        } 
    }    
    for my $irc (@ircs){
        $irc->{client} = Mojo::IRC->new(
            nick=>$irc->{nick},
            user=>$irc->{user},
            pass=>$irc->{pass},
            server=>"$irc->{server}:$irc->{port}",
        ); 

        $irc->{client}->on(irc_join =>sub{
            my(undef, $m) = @_;
            my ($command,$nick,$channel,$content) = 
                ($m->{command},substr($m->{prefix},0,index($m->{prefix},"!~")),$m->{params}[0],$m->{params}[1]);
            $client->debug("$nick 已加入频道 $channel|$irc->{server}:$irc->{port}") if $command eq "JOIN";
        });
        $irc->{client}->on(irc_privmsg=>sub{
            my(undef, $m) = @_; 
            my ($command,$nick,$channel,$content) =
                ($m->{command},substr($m->{prefix},0,index($m->{prefix},"!~")),$m->{params}[0],$m->{params}[1]);
            for(@groups){
                $client->send_group_message($_,"[$nick#irc] " . encode("utf8",$content));
            }
        });
        $irc->{client}->on(close=>sub{
            $irc->{is_join} = 0;
            $client->debug("irc[ $irc->{nick}|$irc->{server}:$irc->{port} ]已断开连接，尝试重新连接");
            $irc->{client}->connect(sub{
                if($_[1]){
                    $client->error("irc[ $irc->{nick}|$irc->{server}:$irc->{port} ]连接失败: $_[1]");
                    return;
                }
                $irc->{is_join} = 1;
                $client->debug("$irc->{nick} 已连接 $irc->{channel}|$irc->{server}:$irc->{port}");
                $_[0]->write(join => $irc->{channel},sub{
                    $client->debug("$irc->{nick} 尝试加入频道 $irc->{channel}|$irc->{server}:$irc->{port}");
                    $client->error("$irc->{nick} 加入频道 $irc->{channel}|$irc->{server}:$irc->{port} 失败: $_[1]") if $_[1];
                });
            });
        });
        $irc->{client}->connect(sub{
            if($_[1]){
                $client->error("irc[ $irc->{nick}|$irc->{server}:$irc->{port} ]连接失败: $_[1]");
                return;
            }
            $irc->{is_join} = 1;
            $client->debug("$irc->{nick} 已连接 $irc->{channel}|$irc->{server}:$irc->{port}"); 
            $_[0]->write(JOIN => $irc->{channel},sub{
                $client->debug("$irc->{nick} 尝试加入频道 $irc->{channel}|$irc->{server}:$irc->{port}");
                $client->error("$irc->{nick} 加入频道 $irc->{channel}|$irc->{server}:$irc->{port} 失败: $_[1]") if $_[1];
            });
            
        });
    }

    my $callback = sub{
        my ($client,$msg)=@_;
        return if ($msg->msg_class eq "send" and $msg->content=~/^\[.*?#.+?\]/); 
        return if $msg->type ne 'group_message';
        my $sender_nick;
        if($msg->msg_class eq "recv"){
            $sender_nick = $msg->sender->card || $msg->sender->nick;
        }
        elsif($msg->msg_class eq "send"){
            $sender_nick = $msg->sender->nick;
        }
        my $gname = $msg->group->gname;
        return unless first {$gname eq $_->gname} @groups;
        for(grep {$gname  ne $_->gname} @groups){ 
            $client->send_group_message($_,"[${sender_nick}#$gname] " . $msg->content);
        }
        for(@ircs){
            $_->{client}->write(PRIVMSG => $_->{channel},decode("utf8",":[$sender_nick] ". $msg->content));
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}
1;
