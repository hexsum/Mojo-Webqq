package Mojo::Webqq::Plugin::IRCSimulation;
use strict;
$Mojo::Webqq::Plugin::IRCSimulation::PRIORITY = 99;
use List::Util qw(first);
$Mojo::Webqq::Plugin::IRCSimulation::has_mojo_irc_server = 0;
BEGIN{
    eval{
        require Mojo::IRC::Server;
    };
    $Mojo::Webqq::Plugin::IRCSimulation::has_mojo_irc_server = 1 if not $@;
}
my $ircd;
sub call{
    my $client = shift;
    my $data = shift;
    $client->die("请先安装模块 Mojo::IRC::Server") if  not $Mojo::Webqq::Plugin::IRCSimulation::has_mojo_irc_server;
    my $master_irc_user = $data->{master_irc_user} || $client->user->qq;
    my @groups = ref($data->{group}) eq "ARRAY"?@{$data->{group}}:();
    $ircd = Mojo::IRC::Server->new(host=>$data->{host}||"0.0.0.0",port=>$data->{port}||6667,log=>$client->log);
    $client->each_friend(sub{
        my($client,$friend) = @_;
        my $virtual_client = $ircd->add_virtual_client(
            id      => $friend->id,
            name    => $friend->id,
            nick    =>(defined($friend->markname)?$friend->markname:$friend->nick),
            user    => $friend->id,
        );
        $ircd->join_channel($virtual_client,'#我的好友',mode=>"is");
    });

    #$client->each_group_member(sub{
    #    my($client,$member) = @_;
    #    return if @groups and not first {$member->gname eq $_} @groups;    
    #    return if $member->id eq $client->user->id;
    #    my $virtual_client = $ircd->add_virtual_client(
    #        id      => $member->id,
    #        name    => $member->id,
    #        nick    =>(defined($member->card)?$member->card:$member->nick), 
    #        user    => $member->id,
    #    );
    #    $ircd->join_channel($virtual_client,'#'.$member->gname);
    #});

    $ircd->on(privmsg=>sub{
        my($ircd,$irc_client,$msg) = @_;
        my $content = $msg->{params}[1];
        if($irc_client->{user} ne $master_irc_user and $irc_client->{host} ne "127.0.0.1"){
            #$content = "$irc_client->{nick}: " . $content; 
            $content .= " (来自 $irc_client->{nick})"; 
        }
        if(substr($msg->{params}[0],0,1) eq "#" ){
            my $channel_id = $msg->{params}[0];
            my $group = $client->search_group(gname=>substr($irc_client->{channel}{$channel_id}{id},1));
            $group->send($content,sub{$_[1]->msg_from("irc")}) if defined $group;
        }
        elsif($irc_client->{user} eq $master_irc_user or $irc_client->{host} eq "127.0.0.1"){
            my $nick = $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $c = $ircd->search_client(nick=>$nick);
            return if not defined $c;
            my $friend = $client->search_friend(id=>$c->{id});
            if(defined $friend){
                $friend->send($content,sub{$_[1]->msg_from("irc")});
            }
            else{
                my $member = $client->search_group_member(id=>$c->{id});
                if(defined $member){
                    $member->send($content,sub{$_[1]->msg_from("irc")});
                }
            }
        } 
    });

    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        if($msg->type eq "message"){
            my $friend = $msg->sender;
            my $virtual_client = $ircd->search_client(user=>$friend->id);
            if(not defined $virtual_client){
                $virtual_client = $ircd->add_virtual_client(
                    id      =>$friend->id,
                    name    =>$friend->id,
                    user    =>$friend->id,
                    nick    =>defined($friend->markname)?$friend->markname:$friend->nick,
                );
                $ircd->join_channel($virtual_client,'#我的好友',mode=>"is");
            }
            for(
                grep {$_->{user} eq $master_irc_user or $_->{host} eq "127.0.0.1"} 
                grep {!$_->{virtual}} @{$ircd->client}
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $ircd->send($_,$ircd->fullname($virtual_client),"PRIVMSG",$virtual_client->{nick},$line);
                }
            }
        }

        if($msg->type eq "sess_message"){
            my $member  = $msg->sender;
            return if @groups and not first {$member->gname eq $_} @groups;
            my $virtual_client = $ircd->search_client(user=>$member->id);
            if(not defined $virtual_client){
                $virtual_client=$ircd->add_virtual_client(
                    id      =>$member->id,
                    name    =>$member->id,
                    user    =>$member->id,
                    nick    =>defined($member->card)?$member->card:$member->nick,
                );
                $ircd->join_channel($virtual_client,'#'.$member->gname) if $msg->via eq "group";
            } 

            for(
                grep {$_->{user} eq $master_irc_user or $_->{host} eq "127.0.0.1"}
                grep {!$_->{virtual}} @{$ircd->client}
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $ircd->send($_,$ircd->fullname($virtual_client),"PRIVMSG",$virtual_client->{nick},$line);
                }
            }
        }

        elsif($msg->type eq "group_message"){
            my $member = $msg->sender;
            return if @groups and not first {$member->gname eq $_} @groups;
            my $virtual_client = $ircd->search_client(user=>$member->id);
            if(not defined $virtual_client){
                $virtual_client=$ircd->add_virtual_client(
                    id      =>$member->id,
                    name    =>$member->id,
                    user    =>$member->id,
                    nick    =>defined($member->card)?$member->card:$member->nick,
                );
                $ircd->join_channel($virtual_client,'#'.$member->gname);
            }
            my $channel = $ircd->search_channel(name=>'#'.$member->gname);
            return if not defined $channel;
            for(
                grep {exists $_->{channel}{$channel->{name}}} 
                grep {!$_->{virtual}} @{$ircd->client}
            ){
                for my $line (split /\r?\n/,$msg->content){
                    $ircd->send($_,$ircd->fullname($virtual_client),"PRIVMSG",$channel->{name},$line);
                }
            }
        }
    
    });
    $client->on(send_message=>sub{
        my($client,$msg) = @_;
        return if $msg->msg_from eq "irc";
        if($msg->type eq "message"){
            my $friend = $msg->receiver;
            my $virtual_client = $ircd->search_client(user=>$friend->id);
            if(not defined $virtual_client){
                $virtual_client=$ircd->add_virtual_client(
                    id      =>$friend->id,
                    name    =>$friend->id,
                    user    =>$friend->id,
                    nick    =>defined($friend->markname)?$friend->markname:$friend->nick,
                );
                $ircd->join_channel($virtual_client,'#我的好友',mode=>"is");
            }
            for(
                grep {$_->{user} eq $master_irc_user or $_->{host} eq "127.0.0.1"} 
                grep {!$_->{virtual}} @{$ircd->client}
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $ircd->send($_,$ircd->fullname($_),"PRIVMSG",$virtual_client->{nick},$line);
                }
            }
        }

        if($msg->type eq "sess_message"){
            my $member  = $msg->receiver;
            return if @groups and not first {$member->gname eq $_} @groups;
            my $virtual_client = $ircd->search_client(user=>$member->id);
            if(not defined $virtual_client){
                $virtual_client=$ircd->add_virtual_client(
                    id      =>$member->id,
                    name    =>$member->id,
                    user    =>$member->id,
                    nick    =>defined($member->card)?$member->card:$member->nick,
                );
                $ircd->join_channel($virtual_client,'#'.$member->gname) if $msg->via eq "group";
            } 

            for(
                grep {$_->{user} eq $master_irc_user or $_->{host} eq "127.0.0.1"}
                grep {!$_->{virtual}} @{$ircd->client}
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $ircd->send($_,$ircd->fullname($_),"PRIVMSG",$virtual_client->{nick},$line);
                }
            }
        }

        elsif($msg->type eq "group_message"){
            return if @groups and not first {$msg->group->gname eq $_} @groups;
            my $channel = $ircd->search_channel(name=>'#'.$msg->group->gname);
            return unless defined $channel;
            for my $master_irc_client (
                grep {$_->{user} eq $master_irc_user or $_->{host} eq "127.0.0.1"}
                grep {!$_->{virtual}} @{$ircd->client}
            ){
                for(
                    grep {exists $_->{channel}{$channel->{name}}} 
                    grep {!$_->{virtual}} @{$ircd->client}
                ){
                    for my $line (split /\r?\n/,$msg->content){
                        $ircd->send($_,$ircd->fullname($master_irc_client),"PRIVMSG",$channel->{id},$line);
                    }
                }
            }
        }
    });
    $ircd->ready();
}
1;
