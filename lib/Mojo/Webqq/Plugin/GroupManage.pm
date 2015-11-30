package Mojo::Webqq::Plugin::GroupManage;
use strict;
our $PRIORITY = 100;
use POSIX ();
sub do_speak_limit{
    my($client,$data,$db,$msg) = @_;
    my $gid = $msg->group->gid;
    my $sender_id = $msg->sender->id;
    my $period = $data->{speak_limit}{period} || 600;

    my $warn_limit = $data->{speak_limit}{warn_limit};
    my $warn_message = $data->{speak_limit}{warn_message} || '@%s 警告, 您发言过于频繁，可能会被禁言或踢出本群';

    my $shutup_limit = $data->{speak_limit}{shutup_limit};
    my $shutup_time = $data->{speak_limit}{shutup_time} || 600;

    my $kick_limit = $data->{speak_limit}{kick_limit};

    my $start = POSIX::mktime(0,0,0,(localtime)[3,4,5]);
    return if $msg->msg_time-$start <0;
    my $slot = int(($msg->msg_time-$start)/$period);
    my $count = ++$db->{speak_limit}{$gid}{$sender_id}{$slot};

    if(defined $kick_limit and $count >= $kick_limit){
        $msg->group->kick_group_member($msg->sender);
    }
    elsif(defined $shutup_limit and $count >= $shutup_limit){
        $msg->group->shutup_group_member($shutup_time,$msg->sender);
    }
    elsif(defined $warn_limit and $count >= $warn_limit){
        $msg->reply(sprintf $warn_message,$msg->sender->displayname); 
    }
}
sub do_pic_limit{
    my($client,$data,$db,$msg) = @_;
    my $gid = $msg->group->gid;
    my $sender_id = $msg->sender->id;
    my $period = $data->{pic_limit}{period} || 600;

    my $warn_limit = $data->{pic_limit}{warn_limit};
    my $warn_message = $data->{pic_limit}{warn_message} || '@%s 警告, 您发图过多，可能会被禁言或踢出本群';

    my $shutup_limit = $data->{pic_limit}{shutup_limit};
    my $shutup_time = $data->{pic_limit}{shutup_time} || 600;

    my $kick_limit = $data->{pic_limit}{kick_limit};

    my $start = POSIX::mktime(0,0,0,(localtime)[3,4,5]);
    return if $msg->msg_time-$start <0;
    my $slot = int(($msg->msg_time-$start)/$period);
    for(@{$msg->raw_content}){
        if($_->{type} eq 'cface'){
            $db->{pic_limit}{$gid}{$sender_id}{$slot}++;  
        }
    }
    my $count = $db->{pic_limit}{$gid}{$sender_id}{$slot} || 0;
    if(defined $kick_limit and $count >= $kick_limit){
        $msg->sender->group->kick_group_member($msg->sender);
    }
    elsif(defined $shutup_limit and $count >= $shutup_limit){
        $msg->sender->group->shutup_group_member($shutup_time,$msg->sender);
    }
    elsif(defined $warn_limit and $count >= $warn_limit){
        $msg->reply(sprintf $warn_message,$msg->sender->displayname); 
    }
}
#sub do_badwork_check {}
sub call {
    my $client = shift;
    my $data   = shift;
    my $db = {};
    $client->add_job(__PACKAGE__ . "清空数据库","00:00:00",sub{$db = {}});
    $client->on(login=>sub{$db={}});
    $client->on(
        receive_message     => sub {
            my($client,$msg) = @_;
            return if $msg->type ne "group_message";
            #说话频率限制
            do_speak_limit($client,$data,$db,$msg);        
            #发图数量限制
            do_pic_limit($client,$data,$db,$msg);
            #关键字限制
            #do_badwork_check($client,$data,$db,$msg);
        },
        new_group           => sub {$_[1]->send($data->{new_group} || "大家好，初来咋到，请多关照");},
        #lose_group         => sub { },
        new_group_member    => sub {
            my $displayname = $_[1]->displayname;
            return if $displayname eq "昵称未知";
            $_[1]->group->send(
                sprintf($data->{new_group_member} || '欢迎新成员 @%s 入群[鼓掌][鼓掌][鼓掌]',$displayname)
            ); 
        },
        lose_group_member   => sub {
            my $displayname = $_[1]->displayname;
            return if $displayname eq "昵称未知";
            $_[1]->group->send(
                sprintf($data->{lose_group_member} || '很遗憾 @%s 离开了本群[流泪][流泪][流泪]',$displayname)
            );
        },
        #new_discuss_member  => sub { },
        #lose_discuss_member => sub { },
        #new_friend          => sub { },
        #lose_friend         => sub { },
    );
}
1;
