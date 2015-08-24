package Mojo::Webqq::Plugin::MsgSync;
$Mojo::Webqq::Plugin::MsgSync::PRIORITY = 99;
use strict;
use Encode;
use List::Util qw(first);
$Mojo::Webqq::Plugin::MsgSync::is_hold_mojo_irc;
BEGIN{
    local $SIG{__WARN__}=sub{};
    eval{require Mojo::IRC;};
    $Mojo::Webqq::Plugin::MsgSync::is_hold_mojo_irc = 1 unless $@;
}
my @pairs;
my %group_status;
my %irc_channel_status;
my $irc = undef;
sub call{
    my $client = shift;
    my $data = shift;
    $client->die(__PACKAGE__ . "依赖Mojo::IRC模块，请先安装该模块") if !$Mojo::Webqq::Plugin::MsgSync::is_hold_mojo_irc;
    return if ref $data ne "HASH";
    return if ref $data->{pairs} ne "ARRAY";
    if(exists $data->{irc}){
        $irc = {};
        $irc->{nick} = $data->{irc}->{nick};
        $irc->{user} = $data->{irc}->{user};
        $irc->{pass} = $data->{irc}->{pass};
        $irc->{server} = $data->{irc}->{server} || "irc.perfi.wang";
        $irc->{port}   = $data->{irc}->{port} || 6667;
    }
    for my $pair (@{ $data->{pairs} }){
        my @p;
        for(@{$pair}){
            if(ref $_ eq "Mojo::Webqq::Group"){
                push @p,{type=>"group",name=>$_->gname} ;
                $group_status{$_->gname}=1;
            }
            else {push @p,{type=>"channel",name=>$_}; $irc_channel_status{$_}=0; }
        }
        push @pairs,\@p;
    }
    
    if(defined $irc){
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
            for(keys %irc_channel_status){
                if(lc($_) eq lc($channel)){
                    $irc_channel_status{$_} = 1;
                    last;
                }
            }

            $client->debug("$nick 已加入频道 $channel|$irc->{server}:$irc->{port}") if $command eq "JOIN";
        });
        $irc->{client}->on(irc_privmsg=>sub{
            my(undef, $m) = @_; 
            my ($command,$nick,$channel,$content) =
                ($m->{command},substr($m->{prefix},0,index($m->{prefix},"!")),$m->{params}[0],$m->{params}[1]);
            if($content !~ /^(>>>6?|###|~~~|@@@|\/\/\/)/){
                $content =~ s/^(\w+): ?/\@$1 /;
            }
            for my $pair (@pairs){
                next unless first {$_->{type} eq "channel" and lc($_->{name}) eq lc($channel) } @$pair;
                for(grep { $_->{type} eq "group"} @$pair){ 
                    my $g = $client->search_group(gname=>$_->{name});
                    next unless defined $g;
                    $client->send_group_message($g,"$nick: " . encode("utf8",$content),sub{        
                    #$client->send_group_message($g,encode("utf8",$content) . " (来自 $nick)",sub{        
                        my $msg = $_[1];
                        $msg->cb(sub{
                            my($client,$msg,$status)=@_;
                            return if $status->is_success;
                            $irc->{client}->write(PRIVMSG => $channel,":$nick: " . $content . decode("utf8","[QQ群同步失败]"));
                        });
                        $msg->msg_from("irc");
                    });
                }
            }
        });
        my $connect_callback;$connect_callback = sub{
            if($_[1]){
                $irc->{is_connect} = 0;
                $client->error("irc[ $irc->{nick}|$irc->{server}:$irc->{port} ]连接失败: $_[1]");
                $client->timer(3,sub{$irc->{client}->connect($connect_callback)});
            }
            $irc->{is_connect} = 1;
            $client->debug("$irc->{nick} 已连接 $irc->{server}:$irc->{port}"); 
            for my $channel( keys %irc_channel_status){
                $_[0]->write(JOIN => $channel,sub{
                    $client->debug("$irc->{nick} 尝试加入频道 $channel|$irc->{server}:$irc->{port}");
                    $client->error("$irc->{nick} 加入频道 $channel|$irc->{server}:$irc->{port} 失败: $_[1]") if $_[1];
                });
            }
        };
        $irc->{client}->on(close=>sub{
            $irc->{is_connect} = 0;
            for(keys %irc_channel_status){$irc_channel_status{$_}=0}
            $client->debug("irc[ $irc->{nick}|$irc->{server}:$irc->{port} ]已断开连接，尝试重新连接");
            $irc->{client}->connect($connect_callback);
        });
        $irc->{client}->connect($connect_callback);
    }

    my $callback = sub{
        my ($client,$msg)=@_;
        return if $msg->msg_class eq "send" and $msg->msg_from eq "irc"; 
        return if $msg->type ne 'group_message';
        my $sender_nick;
        if($msg->msg_class eq "recv"){
            $sender_nick = $msg->sender->card || $msg->sender->nick;
        }
        elsif($msg->msg_class eq "send"){
            if($msg->msg_from eq "bot"){
                $sender_nick = "小灰助理";
            }
            else{$sender_nick = $msg->sender->nick;}
        }
        my $gname = $msg->group->gname;
        return unless first {$gname eq $_} keys %group_status;
        for my $pair (@pairs){ 
            next unless first {$_->{type} eq "group" and $_->{name} eq $gname} @$pair;
            for(grep {$_->{type} eq "group" and $_->{name} ne $gname} @$pair){
                my $g = $client->search_group(gname=>$_->{name});
                next unless defined $g;
                $client->send_group_message($g,"${sender_nick}|$gname: " . $msg->content);
            }
            my $content = $msg->content;
            $content=~s/ \(来自 小灰助理\)$// if $msg->msg_class eq "send" and $msg->msg_from eq "bot";
            for my $channel(grep {$_->{type} eq "channel" and $irc_channel_status{$_->{name}}==1} @$pair){
                for(split /\n/,$client->truncate($content,max_bytes=>2000,max_lines=>10)){
                    $irc->{client}->write(PRIVMSG => $channel->{name},decode("utf8",":[$sender_nick] ". $_));
                }
            }
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}
1;
