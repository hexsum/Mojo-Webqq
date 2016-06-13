package Mojo::Webqq::Plugin::KnowledgeBase;
our $PRIORITY = 2;
use List::Util qw(first);
use Storable qw(retrieve nstore);
sub call{
    my $client = shift;
    my $data = shift;
    $data->{fuzzy} = 1 if not defined $data->{fuzzy};
    my $file = $data->{file} || './KnowledgeBase.dat';
    my $learn_command = defined $data->{learn_command}?quotemeta($data->{learn_command}):'learn|学习';
    my $delete_command = defined $data->{delete_command}?quotemeta($data->{delete_command}):'delete|del|删除';
    my $base = {};
    $base = retrieve($file) if -e $file;
    #$client->timer(120,sub{nstore $base,$file});
    my $callback = sub{
        my($client,$msg) = @_;
        return if $msg->type !~ /^message|group_message|dicsuss_message|sess_message$/;
        if($msg->type eq 'group_message'){
            return if $data->{is_need_at} and $msg->type eq "group_message" and !$msg->is_at;
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->gnumber eq $_:$msg->group->gname eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->gnumber eq $_:$msg->group->gname eq $_} @{$data->{allow_group}}
        }
        if($msg->content =~ /^(?:$learn_command)
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            /xs){
            $msg->allow_plugin(0);
            return if ref $data->{learn_operator} eq "ARRAY" and ! first {$_ eq $msg->sender->qq} @{$data->{learn_operator}};
            my($q,$a) = ($1,$2);
            return unless defined $q;
            return unless defined $a;
            my $space = $msg->type eq "message"?"__我的好友__":$msg->group->displayname;
            $q=~s/^\s+|\s+$//g;
            $a=~s/^\s+|\s+$//g;
            push @{ $base->{$space}{$q} }, $a;
            nstore($base,$file);
            $client->reply_message($msg,"知识库[ $q →  $a ]添加成功",sub{$_[1]->msg_from("bot")}); 

        }   
        elsif($msg->content =~ /^(?:$delete_command)
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            /xs){
            $msg->allow_plugin(0);
            return if ref $data->{delete_operator} eq "ARRAY" and ! first {$_ eq $msg->sender->qq} @{$data->{delete_operator}};
            #return if $msg->sender->id ne $client->user->id;
            my($q) = ($1);
            $q=~s/^\s+|\s+$//g;
            return unless defined $q;
            my $space = $msg->type eq "message"?"__我的好友__":$msg->group->displayname;
            delete $base->{$space}{$q}; 
            nstore($base,$file);
            $client->reply_message($msg,"知识库[ $q ]删除成功"),sub{$_[1]->msg_from("bot")};
        }
        else{
            return if $msg->msg_class eq "send" and $msg->msg_from ne "api" and $msg->msg_from ne "irc";
            my $content = $msg->content;
            $content =~s/^[a-zA-Z0-9_]+: ?// if $msg->msg_from eq "irc";
            my $space = $msg->type eq "message"?"__我的好友__":$msg->group->displayname;
            #return unless exists $base->{$space}{$content};
            if($data->{fuzzy}){
                for my $keyword (keys %{$base->{$space}}){
                    next if not $content=~/\Q$keyword\E/;
                    $msg->allow_plugin(0);
                    my $len = @{$base->{$space}{$keyword}};
                    $client->reply_message($msg,$base->{$space}{$keyword}->[int rand $len],sub{$_[1]->msg_from("bot")});
                }
            }
            else{
                return unless exists $base->{$space}{$content};
                $msg->allow_plugin(0);
                my $len = @{$base->{$space}{$content}};
                $client->reply_message($msg,$base->{$space}{$content}->[int rand $len],sub{$_[1]->msg_from("bot")}); 
            }
        }
    };
    $client->on(receive_message=>$callback);
    $client->on(send_message=>$callback);
}
1;
