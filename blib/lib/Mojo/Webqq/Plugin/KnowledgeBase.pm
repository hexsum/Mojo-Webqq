package Mojo::Webqq::Plugin::KnowledgeBase;
our $PRIORITY = 3;
use List::Util qw(first);
sub retrieve_db {
    my ($client,$db,$file) = @_;
    my $new_db = {};
    my $fd;
    if(! open $fd,"<",$file){
        $client->warn("无法加载知识库数据文件 $file : $!");
        return;
    }
    while(<$fd>){
        s/\r?\n$//;
        my($space,$key,$content) = split /\s*(?<!\\)#\s*/,$_,3;
        next if not $space && $key && $content;
        $content =~ s/(\\r)?\\n/\n/g;
        $content =~ s/\\t/\t/g;
        push @{ $new_db->{$space}{$key} }, $content;
    }
    close $fd;
    %$db = %$new_db;
}
sub store_db {
    my($client,$db,$file) = @_;
    my $fd;
    if(!open $fd,">",$file){
        $client->warn("无法加载知识库数据文件 $file : $!");
        return;
    }
    for my $space (keys %$db){
        for my $key (keys %{$db->{$space}}){
            #print $key,$space,join("|",@{$hash->{$space}{$key}});
            for $answer (@{$db->{$space}{$key}}){
                my $key_n= $key;
                my $answer_n = $answer;
                $answer_n =~ s/\r?\n/\\n/g;
                $answer_n =~ s/\t/\\t/g;
                $answer_n =~ s/\|/\\|/g;
                print $fd $space," # ",$key," # ",$answer_n,"\n";
            }
        }
    }
    close $fd;
}
sub call{
    my $client = shift;
    my $data = shift;
    my ($file_size, $file_mtime);
    $data->{mode} = 'fuzzy' if not defined $data->{mode};
    my $file = $data->{file} || './KnowledgeBase.txt';
    my $learn_command = defined $data->{learn_command}?quotemeta($data->{learn_command}):'learn|学习';
    my $delete_command = defined $data->{delete_command}?quotemeta($data->{delete_command}):'delete|del|删除';
    my $base = {};
    if(-e $file){
        ($file_size, $file_mtime) = (stat $file)[7, 9];
        retrieve_db($client,$base,$file);        
    }
    $client->interval($data->{check_time} || 10,sub{
        return if not -e $file;
        return if not defined $file_size; 
        return if not defined $file_mtime; 
        my ($size, $mtime) = (stat $file)[7, 9]; 
        if($size != $file_size or $mtime != $file_mtime){
            $file_size = $size;
            $file_mtime = $mtime;
            retrieve_db($client,$base,$file);        
        }
    });
    my $callback = sub{
        my($client,$msg) = @_;
        return if not $msg->allow_plugin;
        return if $msg->class eq "send" and $msg->from ne "api" and $msg->from ne "irc";
        return if $msg->type !~ /^friend_message|group_message|dicsuss_message|sess_message$/;
        if($msg->type eq 'group_message'){
            return if $data->{is_need_at} and $msg->type eq "group_message" and !$msg->is_at;
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->name eq $_} @{$data->{allow_group}}
        }
        if($msg->content =~ /^(?:$learn_command)(\*?)
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            /xs){
            $msg->allow_plugin(0);
            return if ref $data->{learn_operator} eq "ARRAY" and ! first {$_ eq $msg->sender->uid} @{$data->{learn_operator}};
            my($c,$q,$a) = ($1,$2,$3);
            return unless defined $q;
            return unless defined $a;
            my $space = '';
            if(defined $c and $c eq "*"){
                $space = '__全局__';
            }
            else{
                $space = $msg->type eq "friend_message"?"__我的好友__":$msg->group->displayname;
            }
            $q=~s/^\s+|\s+$//g;
            $a=~s/^\s+|\s+$//g;
            $a=~s/\\n/\n/g;
            push @{ $base->{$space}{$q} }, $a;
            store_db($client,$base,$file);
            ($file_size, $file_mtime)= (stat $file)[7, 9];
            $client->reply_message($msg,"知识库[ $q →  $a ]" . ($space eq '__全局__'?"*":"") . "添加成功",sub{$_[1]->from("bot")}); 

        }   
        elsif($msg->content =~ /^(?:$delete_command)(\*?)
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            /xs){
            $msg->allow_plugin(0);
            return if ref $data->{delete_operator} eq "ARRAY" and ! first {$_ eq $msg->sender->uid} @{$data->{delete_operator}};
            #return if $msg->sender->id ne $client->user->id;
            my($c,$q) = ($1,$2);
            $q=~s/^\s+|\s+$//g;
            return unless defined $q;
            my $space = '';
            if(defined $c and $c eq "*"){
                $space = '__全局__';
            }
            else{
                $space = $msg->type eq "friend_message"?"__我的好友__":$msg->group->displayname;
            }
            delete $base->{$space}{$q}; 
            store_db($client,$base,$file);
            ($file_size, $file_mtime)= (stat $file)[7, 9];
            $client->reply_message($msg,"知识库[ $q ]". ($space eq '__全局__'?"*":"") . "删除成功"),sub{$_[1]->from("bot")};
        }
        else{
            #return if $msg->msg_class eq "send" and $msg->msg_from ne "api" and $msg->msg_from ne "irc";
            my $content = $msg->content;
            $content =~s/^[a-zA-Z0-9_]+: ?// if $msg->msg_from eq "irc";
            my $space = $msg->type eq "friend_message"?"__我的好友__":$msg->group->displayname;
            #return unless exists $base->{$space}{$content};
            if($data->{mode} eq 'regex'){
                my @match_keyword;
                for my $keyword (keys %{$base->{$space}}){
                    next if not $content=~/$keyword/;
                    push @match_keyword,$keyword;
                }
                if(@match_keyword == 0){
                    $space = '__全局__';
                    for my $keyword (keys %{$base->{$space}}){
                        next if not $content=~/$keyword/;
                        push @match_keyword,$keyword;
                    }
                }
                return if @match_keyword == 0;
                $msg->allow_plugin(0);
                my $keyword = $match_keyword[int rand @match_keyword];
                my $len = @{$base->{$space}{$keyword}};
                my $reply = $base->{$space}{$keyword}->[int rand $len];
                $reply .= "\n--匹配模式『$keyword』" . ($space eq '__全局__'?"*":"") if $data->{show_keyword};
                $client->reply_message($msg,$reply,sub{$_[1]->from("bot")});
            }
            elsif($data->{mode} eq 'fuzzy'){
                my @match_keyword;
                for my $keyword (keys %{$base->{$space}}){
                    next if not $content=~/\Q$keyword\E/;
                    push @match_keyword,$keyword;
                }
                if(@match_keyword == 0){
                    $space = '__全局__';
                    for my $keyword (keys %{$base->{$space}}){
                        next if not $content=~/$keyword/;
                        push @match_keyword,$keyword;
                    }
                }
                return if @match_keyword == 0;
                $msg->allow_plugin(0);
                my $keyword = $match_keyword[int rand @match_keyword];
                my $len = @{$base->{$space}{$keyword}};
                my $reply = $base->{$space}{$keyword}->[int rand $len];
                $reply .= "\n--匹配关键字『$keyword』" . ($space eq '__全局__'?"*":"") if $data->{show_keyword};
                $client->reply_message($msg,$reply,sub{$_[1]->from("bot")});
            }
            else{
                $space = '__全局__' if not exists $base->{$space}{$content};
                return if not exists $base->{$space}{$content};
                $msg->allow_plugin(0);
                my $len = @{$base->{$space}{$content}};
                return if $len ==0;
                $client->reply_message($msg,$base->{$space}{$content}->[int rand $len] . ($space eq '__全局__'?"*":""),sub{$_[1]->from("bot")}); 
            }
        }
    };
    $client->on(receive_message=>$callback);
    $client->on(send_message=>$callback);
}
1;
