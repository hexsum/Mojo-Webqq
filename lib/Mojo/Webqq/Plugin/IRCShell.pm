package Mojo::Webqq::Plugin::IRCShell;
$Mojo::Webqq::Plugin::IRCShell::PRIORITY = 99;
use strict;
use List::Util qw(first);
BEGIN{
    $Mojo::Webqq::Plugin::IRCShell::has_mojo_irc_server = 0;
    eval{
        require Mojo::IRC::Server::Chinese;
    };
    $Mojo::Webqq::Plugin::IRCShell::has_mojo_irc_server = 1 if not $@;
}

my $ircd;
sub call{
    my $client = shift;
    my $data = shift;
    $client->die("请先安装模块 Mojo::IRC::Server::Chinese") if not $Mojo::Webqq::Plugin::IRCShell::has_mojo_irc_server;
    my $master_irc_nick = $data->{master_irc_nick};
    my $upload_api = $data->{upload_api} // 'https://sm.ms/api/upload';
    my $is_load_friend = defined $data->{load_friend}?$data->{load_friend}:1;
    my @groups = ref($data->{allow_group}) eq "ARRAY"?@{$data->{allow_group}}:();
    my %mode = ref($data->{mode}) eq "HASH"?%{$data->{mode}}:();
    $ircd = Mojo::IRC::Server::Chinese->new(listen=>$data->{listen},log=>$client->log);
    $ircd->on(privmsg=>sub{
        my($ircd,$user,$msg) = @_;
        if(substr($msg->{params}[0],0,1) eq "#" ){
            my $channel_name = $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $raw_content = $content;
            my $channel = $ircd->search_channel(name=>$channel_name);
            return if not defined $channel;
            my $group = $client->search_group(id=>$channel->id);
            return if not defined $group;
            if($content=~/^([^\s]+?): /){
                my $at_nick = $1;
                $content =~s/^([^\s]+?): /\@$at_nick / if  $ircd->search_user(nick=>$at_nick);
                $raw_content = $content;
            }
            if($user->nick ne $master_irc_nick and !$user->is_localhost){
                #$content = $user->nick . ": $content"; 
                $content .= "\n(来自irc用户 - ".$user->nick.")"; 
            }
            $group->send($content,sub{
                $_[1]->from("irc");
                $_[1]->cb(sub{
                    my($client,$msg)=@_;
                    if($msg->is_success){
                        if($msg->content ne $raw_content){
                            $msg->content($raw_content);
                            $msg->raw_content($client->face_parse($msg->content));
                        }
                    }
                    else{
                        $user->send($user->ident,"PRIVMSG",$channel_name,$content . "[发送失败]");
                    }
                });
            });
        }
        elsif($user->nick eq $master_irc_nick or $user->is_localhost){
            my $nick =  $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $u = $ircd->search_user(nick=>$nick);
            #return if not defined $u;
            if(not defined $u){
                my $friend = $client->search_friend(displayname=>$nick);
                return if not defined $friend;
                my $channel = $ircd->search_channel(name=>'#我的好友') || $ircd->new_channel(name=>'#我的好友',mode=>"Pis");
                return if not defined $channel;
                $u = $ircd->new_user(
                    id      =>$friend->id,
                    name    =>$friend->displayname . ":虚拟用户",,
                    user    =>$friend->id,
                    nick    =>$friend->displayname,
                    virtual => 1,
                );
                $u->join_channel($channel);
                $user->send($user->ident,"PRIVMSG",$nick,"[系统提示]已从QQ好友中搜索到对应昵称好友并生成irc用户，现在可以
继续和好友聊天了");

            }
            my $friend = $client->search_friend(id=>$u->id);
            if(defined $friend){
                $friend->send($content,sub{
                    $_[1]->from("irc");
                    $_[1]->cb(sub{
                        my($client,$msg)=@_;
                        return if $msg->is_success;
                        $user->send($user->ident,"PRIVMSG",$nick,$content . "[发送失败]");
                    });
                });
            }
            else{
                my $member = $client->search_group_member(id=>$u->id);
                if(defined $member){
                    $member->send($content,sub{
                        $_[1]->msg_from("irc");
                        $_[1]->cb(sub{
                            my($client,$msg)=@_;
                            return if $msg->is_success;
                            $user->send($user->ident,"PRIVMSG",$nick,$content . "[发送失败]");
                        });
                    });
                }
            } 
        }
    });

    my $callback = sub{
        my %delete_channel  = map {$_->id => $_} grep {$_->name ne "#我的好友"}  $ircd->channels;
        $ircd->remove_user($_) for grep {$_->is_virtual} $ircd->users;
        my $friend_channel = $ircd->new_channel(name=>'#我的好友',mode=>"Pis");
        if($is_load_friend){
            $client->each_friend(sub{
                my($client,$friend) = @_;
                my $user = $ircd->search_user(nick=>$friend->displayname,virtual=>0);
                if(defined $user){
                    $user->once(close=>sub{
                        my $virtual_user = $ircd->new_user(
                            id      => $friend->id,
                            name    => $friend->displayname . ":虚拟用户",
                            nick    => $friend->displayname,
                            user    => $friend->id,
                            virtual => 1,
                        );
                        $virtual_user->join_channel($friend_channel);
                    });
                }
                else{
                    my $virtual_user = $ircd->new_user(
                        id      => $friend->id,
                        name    => $friend->displayname . ":虚拟用户",
                        nick    => $friend->displayname,
                        user    => $friend->id,
                        virtual => 1,
                    );
                    $virtual_user->join_channel($friend_channel);
                }
            });
        }
        $client->each_group(sub{
            my($client,$group) = @_;
            return if(@groups and not first {$group->name eq $_} @groups);
            my $mode = defined $mode{$group->name}?$mode{$group->name}:"Pi";
            my $channel_name = '#'.$group->name;$channel_name=~s/\s|,|&//g;
            my $channel = $ircd->search_channel(name=>$channel_name);
            if(defined $channel){
                delete $delete_channel{$channel->id};
                $channel->id($group->id);
                $channel->remove_user($_) for grep {$_->is_virtual} $channel->users;
            }
            else{ $ircd->new_channel(id=>$group->id,name=>'#'.$group->name,mode=>$mode);}
        });
        $ircd->remove_channel($_) for values %delete_channel;
    };
    $client->on(new_group=>sub{
        my($client,$group) = @_;
        return if(@groups and not first {$group->displayname eq $_} @groups);
        my $mode = defined $mode{$group->displayname}?$mode{$group->displayname}:"Pi";
        my $channel_name = '#'.$group->displayname;$channel_name=~s/\s|,|&//g;
        my $channel = $ircd->search_channel(name=>$channel_name);
        if(defined $channel){
            $channel->id($group->id);
            $channel->remove_user($_) for grep {$_->is_virtual} $channel->users;
        }
        else{ $ircd->new_channel(id=>$group->id,name=>'#'.$group->displayname,mode=>$mode);}
    });
    $client->on(lose_group=>sub{
        my($client,$group) = @_;
        return if(@groups and not first {$group->displayname eq $_} @groups);
        my $mode = defined $mode{$group->displayname}?$mode{$group->displayname}:"Pi";
        my $channel_name = '#'.$group->displayname;$channel_name=~s/\s|,|&//g;
        my $channel = $ircd->search_channel(name=>$channel_name);
        $ircd->remove_channel($channel) if defined $channel;
    });
    $client->on(ready=>sub{
        $master_irc_nick //= $client->user->displayname ;
        $callback->();
        $client->on(login=>$callback);
    });
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        if($msg->type eq "friend_message"){
            my $friend = $msg->sender;
            my $user = $ircd->search_user(id=>$friend->id,virtual=>1) || $ircd->search_user(nick=>$friend->displayname,virtual=>0);
            my $channel = $ircd->search_channel(name=>'#我的好友') || $ircd->new_channel(name=>'#我的好友',mode=>"Pis");
            return if not defined $channel;
            if(not defined $user){
                $user = $ircd->new_user(
                    id      =>$friend->id,
                    name    =>$friend->displayname . ":虚拟用户",,
                    user    =>$friend->id,
                    nick    =>$friend->displayname,
                    virtual => 1,
                );
                $user->join_channel($channel);
            }
            else{
                $user->join_channel($channel) if $user->is_virtual and !$user->is_join_channel($channel);
            }
            for (grep { $_->nick eq $master_irc_nick or $_->is_localhost} grep {!$_->is_virtual} $ircd->users){
                for my $line (split /\r?\n/,$msg->content){
                    $_->send($user->ident,"PRIVMSG",$_->nick,$line);
                    $user->send($user->ident,"PRIVMSG",$_->nick,$line);
                }
            }
        }

        if($msg->type eq "sess_message"){
            my $member  = $msg->sender;
            return if @groups and not first {$member->group->name eq $_} @groups;
            return if $msg->via ne "group";
            my $user = $ircd->search_user(id=>$member->id,virtual=>1) || $ircd->search_user(nick=>$member->displayname,virtual=>0);
            my $channel = $ircd->search_channel(id=>$member->group->id) ||
                    $ircd->new_channel(id=>$member->id,name=>'#'.$member->group->name,);
            return if not defined $channel;
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$member->id,
                    name    =>$member->displayname . ":虚拟用户",
                    user    =>$member->id,
                    nick    =>$member->displayname,
                    virtual => 1,
                );
                $user->join_channel($channel);
            } 
            else{
                $user->join_channel($channel) if $user->is_virtual and !$user->is_join_channel($channel);
            }

            for(
                grep {$_->nick eq $master_irc_nick or $_->is_localhost}
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
            return if @groups and not first {$member->group->name eq $_} @groups;
            my $user = $ircd->search_user(id=>$member->id,virtual=>1) || $ircd->search_user(nick=>$member->displayname,virtual=>0);
            my $channel = $ircd->search_channel(id=>$member->group->id) ||
                    $ircd->new_channel(id=>$member->group->id,name=>'#'.$member->group->name,);
            return if not defined $channel;
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$member->id,
                    name    =>$member->displayname . ":虚拟用户",
                    user    =>$member->id,
                    nick    =>$member->displayname,
                    virtual => 1,
                );
                
                $user->join_channel($channel);
            }
            elsif($user->is_virtual){
                $user->join_channel($channel)  if not $user->is_join_channel($channel);
            }
            else{
                $user->join_channel($channel) if not $user->is_join_channel($channel);
            }
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
        if($msg->type eq "friend_message"){
            my $friend = $msg->receiver;
            my $user = $ircd->search_user(id=>$friend->id,virtual=>1) || $ircd->search_user(nick=>$friend->displayname,virtual=>0);
            my $channel = $ircd->search_channel(name=>'#我的好友') || $ircd->new_channel(name=>'#我的好友',mode=>"Pis");
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$friend->id,
                    name    =>$friend->displayname . ":虚拟用户",
                    user    =>$friend->id,
                    nick    =>$friend->displayname,
                    virtual => 1,
                );
                $user->join_channel($channel);
            }
            elsif($user->is_virtual){
                $user->join_channel($channel)  if not $user->is_join_channel($channel);
            }
            for(
                grep {$_->nick eq $master_irc_nick or $_->is_localhost} 
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
            return if @groups and not first {$member->group->name eq $_} @groups;
            return if $msg->via ne "group";
            my $user = $ircd->search_user(id=>$member->id,virtual=>1)||$ircd->search_user(nick=>$member->displayname,virtual=>0);
            my $channel = $ircd->search_channel(id=>$member->group->id) ||
                    $ircd->new_channel(id=>$member->id,name=>'#'.$member->group->name,);
            if(not defined $user){
                $user=$ircd->new_user(
                    id      =>$member->id,
                    name    =>$member->displayname . ":虚拟用户",
                    user    =>$member->id,
                    nick    =>$member->displayname,
                    virtual => 1,
                );
                $user->join_channel($channel);
            } 
            else{
                $user->join_channel($channel) if $user->is_virtual and !$user->is_join_channel($channel);
            }
            for(
                grep {$_->nick eq $master_irc_nick or $_->is_localhost}
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
            return if @groups and not first {$msg->group->name eq $_} @groups;
            my $channel = $ircd->search_channel(id=>$msg->group->id);
            return unless defined $channel;
            for my $master_irc_client (
                grep {$_->nick eq $master_irc_nick or $_->is_localhost}
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
    if(defined $upload_api){
        $client->on(receive_group_pic=>sub{
            my($client,$file_path,$sender) = @_;
            my $channel = $ircd->search_channel(id=>$sender->id);
            my $user = $ircd->search_user(id=>$sender->id,virtual=>1)||$ircd->search_user(nick=>$sender->displayname,virtual=>0);
            return unless defined $user;
            return unless defined $channel;
            return unless $user->is_join_channel($channel);
            $client->http_post($upload_api,{json=>1},form=>{format=>'json',smfile=>{file=>$file_path}},sub{
                my($json,$ua,$tx)=@_;
                if(not defined $json){
                    $client->warn("二维码图片上传云存储失败: 响应数据异常");
                    return;
                }
                elsif(defined $json and $json->{code} ne 'success' ){
                    $client->warn("二维码图片上传云存储失败: " . $json->{msg});
                    return;
                }
                $channel->broadcast($user->ident,"PRIVMSG",$channel->name,"图片链接: $json->{data}{url}");
            });  
        });
        
        $client->on(receive_friend_pic=>sub{
            my($client,$file_path,$sender) = @_;
            my $user = $ircd->search_user(id=>$sender->id,virtual=>1)||$ircd->search_user(nick=>$sender->displayname,virtual=>0);
            return unless defined $user;
            $client->http_post($upload_api,{json=>1},form=>{format=>'json',smfile=>{file=>$file_path}},sub{
                my($json,$ua,$tx)=@_;
                if(not defined $json){
                    $client->warn("二维码图片上传云存储失败: 响应数据异常");
                    return;
                }
                elsif(defined $json and $json->{code} ne 'success' ){
                    $client->warn("二维码图片上传云存储失败: " . $json->{msg});
                    return;
                }
                for(
                    grep {$_->nick eq $master_irc_nick or $_->is_localhost}
                    grep {!$_->is_virtual } $ircd->users
                ){
                    $_->send($user->ident,"PRIVMSG",$_->nick,"图片链接: $json->{data}{url}");
                    $user->send($user->ident,"PRIVMSG",$_->nick,"图片链接: $json->{data}{url}");
                }
            });
        });

        $client->on(receive_sess_pic=>sub{
            my($client,$file_path,$sender) = @_;
            return if not $sender->is_group_member;
            my $user = $ircd->search_user(id=>$sender->id,virtual=>1)||$ircd->search_user(nick=>$sender->displayname,virtual=>0);
            return unless defined $user;
            $client->http_post($upload_api,{json=>1},form=>{format=>'json',smfile=>{file=>$file_path}},sub{
                my($json,$ua,$tx)=@_;
                if(not defined $json){
                    $client->warn("二维码图片上传云存储失败: 响应数据异常");
                    return;
                }
                elsif(defined $json and $json->{code} ne 'success' ){
                    $client->warn("二维码图片上传云存储失败: " . $json->{msg});
                    return;
                }
                for(
                    grep {$_->nick eq $master_irc_nick or $_->is_localhost}
                    grep {!$_->is_virtual } $ircd->users
                ){
                    $_->send($user->ident,"PRIVMSG",$_->nick,"图片链接: $json->{data}{url}");
                    $user->send($user->ident,"PRIVMSG",$_->nick,"图片链接: $json->{data}{url}");
                }
            });
        });

    }

    my $property_change_callback = sub{
        my($client,$object,$property,$old,$new)=@_;
        if($object->is_friend){
            return if $property ne "nick" and $property ne "markname";
            my $user = $ircd->search_user(id=>$object->id,virtual=>1);
            return unless defined $user;
            $user->set_nick($object->displayname) if $object->displayname ne $user->nick;
        }
        elsif($object->is_group_member){
            return if $property ne "nick" and $property ne "card"; 
            my $user = $ircd->search_user(id=>$object->id,virtual=>1);
            return unless defined $user;
            $user->set_nick($object->displayname) if $object->displayname ne $user->nick;
        }
        elsif($object->is_group){
            return if $property ne "name";
            my $channel = $ircd->search_channel(id=>$object->id);
            return unless defined $channel;
            my $channel_name = '#'.$object->displayname;$channel_name=~s/\s|,|&//g;
            $channel->name($channel_name);
        }
    };
    $client->on("friend_property_change"=>$property_change_callback,
                "group_member_property_change"=>$property_change_callback,
                "group_property_change"=>$property_change_callback
    );

    $ircd->ready();
}
1;
