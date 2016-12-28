package Mojo::Webqq::Plugin::GroupManage;
use strict;
use List::Util qw(first);
our $PRIORITY = 100;
use POSIX ();
sub do_speak_limit{
    my($client,$data,$speak_counter,$msg) = @_;
    my $gid = $msg->group->id;
    my $sender_id = $msg->sender->id;

    my $warn_limit = $data->{speak_limit}{warn_limit};
    my $warn_message = $data->{speak_limit}{warn_message} || '@%s 警告, 您发言过于频繁，可能会被禁言或踢出本群';

    my $shutup_limit = $data->{speak_limit}{shutup_limit};
    my $shutup_time = $data->{speak_limit}{shutup_time} || 600;

    my $kick_limit = $data->{speak_limit}{kick_limit};

    my $count = $speak_counter->check($gid . "|" . $sender_id,$msg->time);
    if(defined $kick_limit and $count >= $kick_limit){
        $msg->group->kick_group_member($msg->sender);
        $speak_counter->clear($gid . "|" . $sender_id);
    }
    elsif(defined $shutup_limit and $count >= $shutup_limit){
        $msg->group->shutup_group_member($shutup_time,$msg->sender);
        $speak_counter->clear($gid . "|" . $sender_id);
    }
    elsif(defined $warn_limit and $count >= $warn_limit){
        $msg->reply(sprintf $warn_message,$msg->sender->displayname); 
    }
}
sub do_pic_limit{
    my($client,$data,$pic_counter,$msg) = @_;
    my $gid = $msg->group->id;
    my $sender_id = $msg->sender->id;
    return if not first {$_->{type} eq 'cface'} @{$msg->raw_content};    

    my $warn_limit = $data->{pic_limit}{warn_limit};
    my $warn_message = $data->{pic_limit}{warn_message} || '@%s 警告, 您发图过多，可能会被禁言或踢出本群';

    my $shutup_limit = $data->{pic_limit}{shutup_limit};
    my $shutup_time = $data->{pic_limit}{shutup_time} || 600;

    my $kick_limit = $data->{pic_limit}{kick_limit};

    for(@{$msg->raw_content}){
        if($_->{type} eq 'cface'){
            $pic_counter->count($gid . "|" . $sender_id,$msg->time);
        }
    }
    my $count = $pic_counter->look($gid . "|" . $sender_id);
    if(defined $kick_limit and $count >= $kick_limit){
        $msg->sender->group->kick_group_member($msg->sender);
        $pic_counter->clear($gid . "|" . $sender_id);
    }
    elsif(defined $shutup_limit and $count >= $shutup_limit){
        $msg->sender->group->shutup_group_member($shutup_time,$msg->sender);
        $pic_counter->clear($gid . "|" . $sender_id);
    }
    elsif(defined $warn_limit and $count >= $warn_limit){
        $msg->reply(sprintf $warn_message,$msg->sender->displayname); 
    }
}
sub do_keyword_limit {
    my($client,$data,$keyword_counter,$msg) = @_;
    my $gid = $msg->group->id;
    my $sender_id = $msg->sender->id;
    my @keywords = ref $data->{keyword_limit}{keyword} eq "ARRAY"?@{$data->{keyword_limit}{keyword}}:();
    return if @keywords == 0;
    return if not first {$msg->content =~/\Q$_\E/} @keywords;
    my $warn_limit = $data->{keyword_limit}{warn_limit};
    my $warn_message = $data->{keyword_limit}{warn_message} || '@%s 警告, 您发言包含限制内容，可能会被禁言或踢出本群';

    my $shutup_limit = $data->{keyword_limit}{shutup_limit};
    my $shutup_time = $data->{keyword_limit}{shutup_time} || 600;

    my $kick_limit = $data->{keyword_limit}{kick_limit};

    my $count = $keyword_counter->check($gid  . "|" . $sender_id,$msg->time);

    if(defined $kick_limit and $count >= $kick_limit){
        $msg->sender->group->kick_group_member($msg->sender);
        $keyword_counter->clear($gid . "|" . $sender_id);
    }
    elsif(defined $shutup_limit and $count >= $shutup_limit){
        $msg->sender->group->shutup_group_member($shutup_time,$msg->sender);
        $keyword_counter->clear($gid . "|" . $sender_id);
    }
    elsif(defined $warn_limit and $count >= $warn_limit){
        $msg->reply(sprintf $warn_message,$msg->sender->displayname); 
    }
}
sub call {
    my $client = shift;
    my $data   = shift;
    my $speak_counter = $client->new_counter(id=>'GroupManage_speek',period=>$data->{speak_limit}{period} || 600);
    my $pic_counter = $client->new_counter(id=>'GroupManage_pic',period=>$data->{pic_limit}{period} || 600);
    my $keyword_counter = $client->new_counter(id=>'GroupManage_keyword',period=>$data->{keyword_limit}{period} || 600);
    $client->on(login=>sub{$speak_counter->reset();$pic_counter->reset();$keyword_counter->reset()});
    $client->on(
        receive_message     => sub {
            my($client,$msg) = @_;
            return if $msg->type ne "group_message";
            return if $data->{is_need_at} and $msg->type eq "group_message" and !$msg->is_at;
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->name eq $_} @{$data->{allow_group}};
            #说话频率限制
            do_speak_limit($client,$data,$speak_counter,$msg);
            #发图数量限制
            do_pic_limit($client,$data,$pic_counter,$msg);
            #关键字限制
            do_keyword_limit($client,$data,$keyword_counter,$msg)
        },
        new_group           => sub {
            my $group = $_[1];
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{allow_group}};
            $group->send($data->{new_group} || "大家好，初来咋到，请多关照");
            
        },
        #lose_group         => sub { },
        new_group_member    => sub {
            my $member = $_[1];
            my $group = $member->group;
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{allow_group}};
            my $displayname = $member->displayname;
            return if $displayname eq "昵称未知";
            $group->send(
                sprintf($data->{new_group_member} || '欢迎新成员 @%s 入群[鼓掌][鼓掌][鼓掌]',$displayname)
            ); 
        },
        lose_group_member   => sub {
            my $member = $_[1];
            my $group = $member->group;
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{allow_group}};
            my $displayname = $member->displayname;
            return if $displayname eq "昵称未知";
            $group->send(
                sprintf($data->{lose_group_member} || '很遗憾 @%s 离开了本群[流泪][流泪][流泪]',$displayname)
            );
        },
        #new_discuss_member  => sub { },
        #lose_discuss_member => sub { },
        #new_friend          => sub { },
        #lose_friend         => sub { },
        group_member_property_change => sub {
            my($client,$member,$property,$old,$new)=@_;
            my $group = $member->group;
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$group->uid eq $_:$group->name eq $_} @{$data->{allow_group}};
            return if $property ne "card";
            return if not defined($new);
            return if not defined($old);
            $group->send('@' . (defined($old)?$old:$member->name) . " 修改群名片为: $new");
        }
    );
}
1;
