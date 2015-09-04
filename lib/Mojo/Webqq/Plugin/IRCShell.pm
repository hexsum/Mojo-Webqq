package Mojo::Webqq::Plugin::IRCShell;
$Mojo::Webqq::Plugin::IRCShell::PRIORITY = 99;
use strict;
use List::Util qw(first);
BEGIN{
    $Mojo::Webqq::Plugin::IRCShell::has_mojo_irc_server = 0;
    eval{
        require Mojo::IRC::Server;
    };
    $Mojo::Webqq::Plugin::IRCShell::has_mojo_irc_server = 1 if not $@;
}

my $ircd;
sub call{
    my $client = shift;
    my $data = shift;
    $client->die("请先安装模块 Mojo::IRC::Server") if not $Mojo::Webqq::Plugin::IRCShell::has_mojo_irc_server;
    my $master_irc_user = $data->{master_irc_user} || $client->user->qq;
    my @groups = ref($data->{group}) eq "ARRAY"?@{$data->{group}}:();
    $ircd = Mojo::IRC::Server->new(host=>$data->{host}||"0.0.0.0",port=>$data->{port}||6667,log=>$client->log);
    $ircd->on(privmsg=>sub{
        my($ircd,$user,$msg) = @_;
        if(substr($msg->{params}[0],0,1) eq "#" ){
            my $channel_name = $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $channel = $ircd->search_channel(name=>$channel_name);
            return if not defined $channel;
            my $group = $client->search_group(gid=>$channel->id);
            return if not defined $group;
            if($content=~/^([^\s]+?): /){
                my $at_nick = $1;
                $content =~s/^([^\s]+?): /\@$at_nick / if  $ircd->search_user(nick=>$at_nick);
            }
            if($user->user ne $master_irc_user and !$user->is_localhost){
                #$content = "$irc_client->{nick}: " . $content; 
                $content .= " (来自 ".$user->nick.")"; 
            }
            $group->send($content,sub{$_[1]->msg_from("irc")});
        }
        elsif($user->user eq $master_irc_user or $user->is_localhost){
            my $nick =  $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $u = $ircd->search_user(nick=>$nick,virtual=>1);
            return if not defined $u;
            my $friend = $client->search_friend(id=>$u->id);
            if(defined $friend){
                $friend->send($content,sub{$_[1]->msg_from("irc")});
            }
            else{
                my $member = $client->search_group_member(id=>$u->id);
                if(defined $member){
                    $member->send($content,sub{$_[1]->msg_from("irc")});
                }
            }
        } 
    });

    my $callback = sub{
        my %delete_channel  = map {$_->id => $_} grep {$_->name ne "#我的好友"}  $ircd->channels;
        $ircd->remove_user($_) for grep {$_->is_virtual} $ircd->users;
        my $friend_channel = $ircd->new_channel(name=>'#我的好友',mode=>"Pis");
        $client->each_friend(sub{
            my($client,$friend) = @_;
            my $virtual_user = $ircd->new_user(
                id      => $friend->id,
                name    =>(defined($friend->markname)?$friend->markname:$friend->nick) . ":虚拟用户",
                nick    =>(defined($friend->markname)?$friend->markname:$friend->nick),
                user    => $friend->id,
                virtual => 1,
            );
            $virtual_user->join_channel($friend_channel);
        });
        $client->each_group(sub{
            my($client,$group) = @_;
            my $mode = "Pi";$mode = "Pis" if(@groups and not first {$group->gname eq $_} @groups);
            my $channel_name = '#'.$group->gname;$channel_name=~s/\s|,|&//g;
            my $channel = $ircd->search_channel(name=>$channel_name);
            if(defined $channel){
                delete $delete_channel{$channel->id};
                $channel->id($group->gid);
                $channel->remove_user($_) for grep {$_->is_virtual} $channel->users;
            }
            else{ $ircd->new_channel(id=>$group->gid,name=>'#'.$group->gname,mode=>$mode);}
        });
        $ircd->remove_channel($_) for values %delete_channel;
    };
    $client->on(ready=>$callback,login=>$callback);
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        if($msg->type eq "message"){
            my $friend = $msg->sender;
            my $user = $ircd->search_user(id=>$friend->id,virtual=>1) || $ircd->search_user(nick=>$friend->nick,virtual=>0);
            if(not defined $user){
                $user = $ircd->new_user(
                    id      =>$friend->id,
                    name    =>(defined($friend->markname)?$friend->markname:$friend->nick) . ":虚拟用户",,
                    user    =>$friend->id,
                    nick    =>defined($friend->markname)?$friend->markname:$friend->nick,
                    virtual => 1,
                );
                my $channel = $ircd->search_channel(name=>'#我的好友') || $ircd->new_channel(name=>'#我的好友',mode=>"Pis");
                $user->join_channel($channel) if defined $channel;
            }
            for (grep { $_->user eq $master_irc_user or $_->is_localhost} grep {!$_->is_virtual} $ircd->users){
                for my $line (split /\r?\n/,$msg->content){
                    $_->send($user->ident,"PRIVMSG",$_->nick,$line);
                    $user->send($user->ident,"PRIVMSG",$_->nick,$line);
                }
            }
        }

        if($msg->type eq "sess_message"){
            my $member  = $msg->sender;
            return if @groups and not first {$member->gname eq $_} @groups;
            return if $msg->via ne "group";
            my $user = $ircd->search_user(id=>$member->id,virtual=>1) || $ircd->search_user(nick=>$member->nick,virtual=>0);
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$member->id,
                    name    =>(defined($member->card)?$member->card:$member->nick) . "虚拟用户",
                    user    =>$member->id,
                    nick    =>defined($member->card)?$member->card:$member->nick,
                    virtual => 1,
                );
                my $channel = $ircd->search_channel(id=>$member->gid) ||
                    $ircd->new_channel(id=>$member->id,name=>'#'.$member->gname,);
                $user->join_channel($channel);
            } 

            for(
                grep {$_->user eq $master_irc_user or $_->is_localhost}
                grep {!$_->is_virtual} $ircd->users
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $_->send($user->ident,"PRIVMSG",$_->nick,$line);
                    $user->send($user->ident,"PRIVMSG",$_->nick,$line);
                }
            }
        }

        elsif($msg->type eq "group_message"){
            my $member = $msg->sender;
            return if @groups and not first {$member->gname eq $_} @groups;
            my $user = $ircd->search_user(id=>$member->id,virtual=>1) || $ircd->search_user(nick=>$member->nick,virtual=>0);
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$member->id,
                    name    =>(defined($member->card)?$member->card:$member->nick) . "虚拟用户",
                    user    =>$member->id,
                    nick    =>defined($member->card)?$member->card:$member->nick,
                    virtual => 1,
                );
                
                my $channel = $ircd->search_channel(id=>$member->gid) ||
                    $ircd->new_channel(id=>$member->gid,name=>'#'.$member->gname,);
                $user->join_channel($channel);
            }
            my $channel = $ircd->search_channel(id=>$member->gid);
            return if not defined $channel;
            for(grep {!$_->is_virtual} $channel->users){
                my @content = split /\r?\n/,$msg->content;
                if($content[0]=~/^\@([^\s]+?) /){
                    my $at_nick = $1;
                    if($ircd->search_user(nick=>$at_nick)){
                        $content[0] =~s/^\@([^\s]+?) //;
                        $_ = "$at_nick: " . $_ for @content;
                    }
                }
                for my $line (@content){
                    $_->send($user->ident,"PRIVMSG",$channel->name,$line);
                }
            }
        }
    
    });
    $client->on(send_message=>sub{
        my($client,$msg) = @_;
        return if $msg->msg_from eq "irc";
        if($msg->type eq "message"){
            my $friend = $msg->receiver;
            my $user = $ircd->search_user(id=>$friend->id,virtual=>1) || $ircd->search_user(nick=>$friend->nick,virtual=>0);
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$friend->id,
                    name    =>(defined($friend->markname)?$friend->markname:$friend->nick) . "虚拟用户",
                    user    =>$friend->id,
                    nick    =>defined($friend->markname)?$friend->markname:$friend->nick,
                    virtual => 1,
                );
                my $channel = $ircd->search_channel(name=>'#我的好友') || $ircd->new_channel(name=>'#我的好友',mode=>"Pis");

                $user->join($channel);
            }
            for(
                grep {$_->user eq $master_irc_user or $_->is_localhost} 
                grep {!$_->is_virtual} $ircd->users
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $_->send($_->ident,"PRIVMSG",$user->nick,$line);
                    $user->send($_->ident,"PRIVMSG",$user->nick,$line);
                }
            }
        }

        if($msg->type eq "sess_message"){
            my $member  = $msg->receiver;
            return if @groups and not first {$member->gname eq $_} @groups;
            return if $msg->via ne "group";
            my $user = $ircd->search_user(id=>$member->id,virtual=>1)||$ircd->search_user(nick=>$member->nick,virtual=>0);
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$member->id,
                    name    =>(defined($member->card)?$member->card:$member->nick) . "虚拟用户",
                    user    =>$member->id,
                    nick    =>defined($member->card)?$member->card:$member->nick,
                    virtual => 1,
                );
                my $channel = $ircd->search_channel(id=>$member->gid) ||
                    $ircd->new_channel(id=>$member->id,name=>'#'.$member->gname,);
                $user->join_channel($channel);
            } 

            for(
                grep {$_->user eq $master_irc_user or $_->is_localhost}
                grep {!$_->is_virtual } $ircd->users
            )
            {
                for my $line (split /\r?\n/,$msg->content){
                    $_->send($_->ident,"PRIVMSG",$user->nick,$line);
                    $user->send($_->ident,"PRIVMSG",$user->nick,$line);
                }
            }
        }

        elsif($msg->type eq "group_message"){
            return if @groups and not first {$msg->group->gname eq $_} @groups;
            my $channel = $ircd->search_channel(id=>$msg->group->gid);
            return unless defined $channel;
            for my $master_irc_client (
                grep {$_->user eq $master_irc_user or $_->is_localhost}
                grep {!$_->is_virtual} $ircd->users
            ){
                for(grep {!$_->{virtual}} $channel->users){
                    my @content = split /\r?\n/,$msg->content;
                    if($content[0]=~/^\@([^\s]+?) /){
                        my $at_nick = $1;
                        if($ircd->search_user(nick=>$at_nick)){
                            $content[0] =~s/^\@([^\s]+?) //;
                            map {$_ = "$at_nick: " . $_} @content;
                        }
                    }
                    for my $line (@content){
                        $_->send($master_irc_client->ident,"PRIVMSG",$channel->name,$line);
                    }
                }
            }
        }
    });
    $ircd->ready();
}
1;
