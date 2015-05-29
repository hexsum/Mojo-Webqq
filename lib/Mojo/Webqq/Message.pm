package Mojo::Webqq::Message;
use strict;
use Encode;
use Mojo::Webqq::Message::Recv::Message;
use Mojo::Webqq::Message::Recv::GroupMessage;
use Mojo::Webqq::Message::Recv::DiscussMessage;
use Mojo::Webqq::Message::Recv::SessMessage;
use Mojo::Webqq::Message::Recv::StateMessage;

use Mojo::Webqq::Message::Send::Status;
use Mojo::Webqq::Message::Send::Message;
use Mojo::Webqq::Message::Send::GroupMessage;
use Mojo::Webqq::Message::Send::DiscussMessage;
use Mojo::Webqq::Message::Send::SessMessage;
#use Mojo::Webqq::Message::Recv::SystemMessage;

use Mojo::Webqq::Message::Remote::_get_sess_sig;
use Mojo::Webqq::Message::Remote::_send_message;
use Mojo::Webqq::Message::Remote::_send_group_message;
use Mojo::Webqq::Message::Remote::_send_discuss_message;
use Mojo::Webqq::Message::Remote::_send_sess_message;

use Mojo::Webqq::Message::Queue;
use Mojo::Webqq::Message::Face;

sub gen_message_queue{
    Mojo::Webqq::Message::Queue->new;
}
sub gen_message_id {
    my $self             = shift;
    my $last_send_msg_id = $self->send_msg_id;
    my $send_msg_id      = $last_send_msg_id++;
    $self->send_msg_id($send_msg_id);
    return $send_msg_id;
}

sub reply_message{
    my $self = shift;
    my ($msg,$content) = @_;
    if($msg->type eq "message"){
        $self->send_message($msg->sender,$content);
    }
    elsif($msg->type eq "group_message"){
        $self->send_group_message($msg->group,$content);
    }
    elsif($msg->type eq "discuss_message"){
        $self->send_discuss_message($msg->discuss,$content);
    }
    elsif($msg->type eq "sess_message"){
        $self->send_sess_message($msg->sender,$content);
    }
}
sub send_message{
    my $self = shift;
    if(@_==1){
        my $msg = shift;
        $self->die("不支持的数据类型") if ref $msg ne "Mojo::Webqq::Message::Send::Message";
        $self->message_queue->put($msg);
        return $self;
    }
    my ($friend,$content) = @_;
    if(ref $friend eq "Mojo::Webqq::Friend" and defined $friend->id){
        my $msg =  Mojo::Webqq::Message::Send::Message->new({
            msg_id      => $self->gen_message_id,
            sender_id   => $self->user->id,
            receiver_id => $friend->id,
            sender      => $self->user,
            receiver    => $friend,
            content     => $content,
        });    
        $self->message_queue->put($msg);
    }
    else{
        $self->die("不支持的数据类型");
    }       
}
sub send_group_message{
    my $self = shift;
    if(@_==1){
        my $msg = shift;
        $self->die("不支持的数据类型") if ref $msg ne "Mojo::Webqq::Message::Send::GroupMessage";
        $self->message_queue->put($msg);
        return $self;
    }
    my ($group,$content) = @_;
    if(ref $group eq "Mojo::Webqq::Group" and defined $group->gid){
        my $msg =  Mojo::Webqq::Message::Send::GroupMessage->new({
            msg_id      => $self->gen_message_id,
            sender_id   => $self->user->id,
            group_id    => $group->gid,
            sender      => $self->user,
            group       => $group,
            content     => $content,
        });
        $self->message_queue->put($msg);
    }
    else{
        $self->die("不支持的数据类型");
    }
}
sub send_discuss_message{
    my $self = shift;
    if(@_==1){
        my $msg = shift;
        $self->die("不支持的数据类型") if ref $msg ne "Mojo::Webqq::Message::Send::DisucssMessage";
        $self->message_queue->put($msg);
        return $self;
    }
    my ($discuss,$content) = @_;
    if(ref $discuss eq "Mojo::Webqq::Discuss" and defined $discuss->did){
        my $msg =  Mojo::Webqq::Message::Send::DisucssMessage->new({
            msg_id      => $self->gen_message_id,
            sender_id   => $self->user->id,
            discuss_id  => $discuss->did,
            sender      => $self->user,
            discuss     => $discuss,
            content     => $content,
        });
        $self->message_queue->put($msg);
    }
    else{
        $self->die("不支持的数据类型");
    }
}
sub send_sess_message{
    my $self = shift;
    if(@_==1){
        my $msg = shift;
        $self->die("不支持的数据类型") if ref $msg ne "Mojo::Webqq::Message::Send::GroupMessage";
        $self->message_queue->put($msg);
        return $self;
    }
    my ($member,$content) = @_;
    if(ref $member eq "Mojo::Webqq::Group::Member" and defined $member->gid and defined $member->id){
        my $msg =  Mojo::Webqq::Message::Send::SessMessage->new({
            msg_id      => $self->gen_message_id,
            sender_id   => $self->user->id,
            receiver_id => $member->id,
            group_id    => $member->gid,
            sender      => $self->user,
            receiver    => $member,
            group       => $self->search_group(gid=>$member->gid),
            content     => $content,
            via         => "group",
            sess_sig    => $self->_get_sess_sig($member->gid,$member->id,0),
        });
        $self->message_queue->put($msg);
    }
    elsif(ref $member eq "Mojo::Webqq::Discuss::Member" and defined $member->did and defined $member->id){
        my $msg =  Mojo::Webqq::Message::Send::SessMessage->new({
            msg_id      => $self->gen_message_id,
            sender_id   => $self->user->id,
            receiver_id => $member->id,
            discuss_id  => $member->did,
            sender      => $self->user,
            receiver    => $member,
            discuss     => $self->search_discuss(did=>$member->did),
            content     => $content,
            via         => "discuss",
            sess_sig    => $self->_get_sess_sig($member->did,$member->id,1),
        });
        $self->message_queue->put($msg);
    }
    else{
        $self->die("不支持的数据类型");
    }
}

sub parse_send_status_msg{
    my $self = shift;
    my $json = shift;
    if(defined $json and $json->{retcode}==0){
        return Mojo::Webqq::Message::Send::Status->new(code=>$json->{retcode},msg=>"发送成功"); 
    }
    else{
        return Mojo::Webqq::Message::Send::Status->new(code=>$json->{retcode},msg=>"发送失败"); 
    }
}

sub parse_receive_msg {
    my $self = shift;
    my $json = shift;
    return if $self->is_stop;
    return unless defined $json;
    if ( $json->{retcode} == 0 ) {
        $self->poll_failure_count(0);
        for my $m ( @{ $json->{result} } ) {
            #收到群临时消息
            if ( $m->{poll_type} eq 'sess_message' ) {
                my $msg = {
                    type        => "sess_message",
                    msg_id      => $m->{value}{msg_id},
                    sender_id   => $m->{value}{from_uin},
                    reveiver_id => $m->{value}{to_uin},
                    msg_time    => $m->{value}{'time'},
                    content     => $m->{value}{content},
                    #service_type=>  $m->{value}{service_type},
                    #ruin        =>  $m->{value}{ruin},
                };

                #service_type =0 表示群临时消息，1 表示讨论组临时消息
                if ( $m->{value}{service_type} == 0 ) {
                    $msg->{group_id} = $m->{value}{id};
                    $msg->{via} = 'group';
                }
                elsif ( $m->{value}{service_type} == 1 ) {
                    $msg->{discuss_id} = $m->{value}{id};
                    $msg->{via} = 'discuss';
                }
                else { return }
                $self->msg_put($msg);
            }

            #收到的消息是普通消息
            elsif ( $m->{poll_type} eq 'message' ) {
                my $msg = {
                    type        => "message",
                    msg_id      => $m->{value}{msg_id},
                    sender_id   => $m->{value}{from_uin},
                    receiver_id => $m->{value}{to_uin},
                    msg_time    => $m->{value}{'time'},
                    content     => $m->{value}{content},
                };
                $self->msg_put($msg);
            }

            #收到的消息是群消息
            elsif ( $m->{poll_type} eq 'group_message' ) {
                my $msg = {
                    type        => "group_message",
                    msg_id      => $m->{value}{msg_id},
                    group_id    => $m->{value}{from_uin},
                    #receiver_id      =>  $m->{value}{to_uin},
                    msg_time    => $m->{value}{'time'},
                    content     => $m->{value}{content},
                    sender_id   => $m->{value}{send_uin},
                };
                $self->msg_put($msg);
            }

            #收到讨论组消息
            elsif ( $m->{poll_type} eq 'discu_message' ) {
                my $msg = {
                    type        => "discuss_message",
                    discuss_id       => $m->{value}{did},
                    msg_id    => $m->{value}{msg_id},
                    sender_id => $m->{value}{send_uin},
                    msg_time  => $m->{value}{'time'},
                    #receiver_id      =>  $m->{value}{'to_uin'},
                    content => $m->{value}{content},
                };
                $self->msg_put($msg);
            }
            elsif ( $m->{poll_type} eq 'buddies_status_change' ) {
                my $msg = {
                    type  => 'state_message',
                    id    => $m->{value}{uin},
                    state => $m->{value}{status},
                    client_type => $self->code2client( $m->{value}{client_type} ),
                };
                $self->msg_put($msg);
            }

            #收到系统消息
            #elsif ( $m->{poll_type} eq 'sys_g_msg' ) {
            #    my $msg = {
            #        type        =>  'system_message',
            #        msg_id      =>  $m->{value}{msg_id},
            #        sender_id    =>  $m->{value}{from_uin},
            #        receiver_id      =>  $m->{value}{to_uin},
            #    
            #    };
            #    $self->msg_put($msg);
            #}

            #收到强制下线消息
            elsif ( $m->{poll_type} eq 'kick_message' ) {
                if ( $m->{value}{show_reason} == 1 ) {
                    my $reason = encode( "utf8", $m->{value}{reason} );
                    $self->fatal("$reason\n");
                    $self->stop();
                }
                else {
                    $self->fatal("您已被迫下线\n");
                    $self->stop();
                }
            }

            #还未识别和处理的消息
            else {

            }
        }
    }

    #可以忽略的消息，暂时不做任何处理
    elsif ($json->{retcode} == 102
        or $json->{retcode} == 109
        or $json->{retcode} == 110 )
    {
        $self->poll_failure_count(0);
    }

    #更新客户端ptwebqq值
    elsif ( $json->{retcode} == 116 ) { 
        $self->debug("更新ptwebqq的值[ $json->{p} ]");
        $self->ptwebqq($json->{p}); 
        $self->ua->cookie_jar->add(
            Mojo::Cookie::Response->new(name=>"ptwebqq",value=>$json->{p},path=>"/",domain=>"qq.com",),
        );
    }

    #未重新登录
    elsif ( $json->{retcode} == 100 ) {
        $self->warn("因网络或其他原因与服务器失去联系，客户端需要重新登录...\n");
        $self->relogin();
    }

    #重新连接失败
    elsif ( $json->{retcode} == 120 or $json->{retcode} == 121 ) {
        $self->warn("因网络或其他原因与服务器失去联系，客户端需要重新连接...\n");
        $self->_relink();
    }

    #其他未知消息
    else {
        my $poll_failure_count = $self->poll_failure_count;
        $self->poll_failure_count( $poll_failure_count++ );
        $self->warn( "获取消息失败，当前失败次数: ". $self->poll_failure_count. "\n" );
        if ( $self->poll_failure_count > $self->poll_failure_count_max ) {
            $self->warn("接收消息失败次数超过最大值，尝试进行重新连接...\n");
            $self->poll_failure_count(0);
            $self->_relink();
        }
    }

}

sub msg_put{   
    my $self = shift;
    my $msg = shift;
    $msg->{raw_content} = [];
    my $msg_content;
    shift @{ $msg->{content} };
    for my $c (@{ $msg->{content} }){
        if(ref $c eq 'ARRAY'){
            if($c->[0] eq 'cface'){
                push @{$msg->{raw_content}},{
                    type    =>  'cface',
                    content =>  '[图片]',
                    name    =>  $c->[1]{name},
                    file_id =>  $c->[1]{file_id},
                    key     =>  $c->[1]{key},
                    server  =>  $c->[1]{server},
                };
                $c="[图片]";
            }
            elsif($c->[0] eq 'offpic'){
                push @{$msg->{raw_content}},{
                    type        =>  'offpic',
                    content     =>  '[图片]',
                    file_path   =>  $c->[1]{file_path},
                };
                $c="[图片]";
            }
            elsif($c->[0] eq 'face'){
                push @{$msg->{raw_content}},{
                    type    =>  'face',
                    content =>  $self->face_to_txt($c),
                    id      =>  $c->[1],
                }; 
                $c=$self->face_to_txt($c);
            }
            else{
                push @{$msg->{raw_content}},{
                    type    =>  'unknown',
                    content =>  '[未识别内容]',
                };
                $c = "[未识别内容]";
            }
        }
        elsif($c eq " "){
            next;
        }
        else{
            $c=encode("utf8",$c);
            $c=~s/ $//;   
            $c=~s/\r|\n/\n/g;
            #{"retcode":0,"result":[{"poll_type":"group_message","value":{"msg_id":538,"from_uin":2859929324,"to_uin":3072574066,"msg_id2":545490,"msg_type":43,"reply_ip":182424361,"group_code":2904892801,"send_uin":1951767953,"seq":3024,"time":1418955773,"info_seq":390179723,"content":[["font",{"size":12,"color":"000000","style":[0,0,0],"name":"\u5FAE\u8F6F\u96C5\u9ED1"}],"[\u50BB\u7B11]\u0001 "]}}]}
            #if($c=~/\[[^\[\]]+?\]\x{01}/)
            push @{$msg->{raw_content}},{
                type    =>  'txt',
                content =>  $c,
            };
        }
        $msg_content .= $c;
    }
    $msg->{content} = $msg_content;
    #将整个hash从unicode转为UTF8编码
    #$msg->{$_} = encode("utf8",$msg->{$_} ) for grep {$_ ne 'raw_content'}  keys %$msg;
    #$msg->{content}=~s/\r|\n/\n/g;
    if($msg->{content}=~/\(\d+\) 被管理员禁言\d+(分钟|小时|天)$/ or $msg->{content}=~/\(\d+\) 被管理员解除禁言$/){
        $msg->{type} = "system_message";
    }


    if($msg->{type} eq "message"){
        my $sender = $self->search_friend(id=>$msg->{sender_id});
        my $receiver = $self->user;
        unless(defined $sender){#new friend
            $self->update_friend();     
            $sender = $self->search_friend(id=>$msg->{sender_id});
            unless(defined $sender){
                $sender = Mojo::Webqq::Friend->new( 
                    id          =>  $msg->{sender_id},
                    nick        =>  "昵称未知",
                    categorie   =>  "陌生人",
                );
                $self->add_friend($sender,1);
            }
            
        }
        $msg->{sender} = $sender;
        $msg->{receiver} = $receiver;
        $msg = Mojo::Webqq::Message::Recv::Message->new($msg);
    }
    elsif($msg->{type} eq "group_message"){ 
        my $sender;
        my $group; 
        $group = $self->search_group(gid=>$msg->{group_id});
        if(defined $group){
            $sender = $group->search_group_member(id=>$msg->{sender_id});
            unless(defined $sender){
                $self->update_group($group);
                $sender = $group->search_group_member(id=>$msg->{sender_id});
                unless(defined $sender){
                    $sender = Mojo::Webqq::Group::Member->new(
                        id=>$msg->{sender_id},
                        nick=>"昵称未知",   
                        gid=>$group->gid,
                        gcode=>$group->gcode,
                        gname=>$group->gname,
                        gmarkname=>$group->gmarkname,
                        _client=>$self,
                    );
                    $group->add_group_member($sender,1); 
                }
            }
        }                         
        else{
            $self->update_group();
            $group = $self->search_group(gid=>$msg->{group_id});
            return unless defined $group;
            $sender = $group->search_group_member(id=>$msg->{sender_id});
            unless(defined $sender){
                $sender = Mojo::Webqq::Group::Member->new(
                    id  =>  $msg->{sender_id},  
                    nick=>"昵称未知",
                    gid =>  $group->gid,
                    gcode=>$group->gcode,   
                    gname=>$group->gname,
                    gmarkname=>$group->gmarkname,
                    _client=>$self,
                );
                $group->add_group_member($sender,1);
            }
        }
        $msg->{sender} = $sender;
        $msg->{group} = $group;
        $msg = Mojo::Webqq::Message::Recv::GroupMessage->new($msg);
    }
    elsif($msg->{type} eq "sess_message"){
        if($msg->{via} eq "group"){
            my $sender;
            my $receiver = $self->user;
            my $group;
            $group = $self->search_group(gid=>$msg->{group_id});
            if(defined $group){
                $sender = $group->search_group_member(id=>$msg->{sender_id});
                unless(defined $sender){
                    $self->update_group($group);
                    $sender = $group->search_group_member(id=>$msg->{sender_id});
                    unless(defined $sender){
                        $sender = Mojo::Webqq::Group::Member->new(
                            gid=>$msg->{group_id},
                            gcode=>$group->gcode,
                            gname=>$group->gname,
                            gmarkname=>$group->gmarkname,
                            id=>$msg->{sender_id},
                            nick=>"昵称未知",
                            _client=>$self,
                        ); 
                        $group->add_group_member($sender,1);
                    }
                }    
            }
            else{
                $self->update_group();
                $group = $self->search_group(gid=>$msg->{group_id});
                return unless defined $group;
                $sender = $group->search_group_member(id=>$msg->{sender_id});
                unless(defined $sender){
                    $sender = Mojo::Webqq::Group::Member->new(
                        gid=>$msg->{group_id},
                        id=>$msg->{sender_id},
                        nick=>"昵称未知",
                        gcode=>$group->gcode,
                        gname=>$group->gname,
                        gmarkname=>$group->gmarkname,
                        _client=>$self,
                    ); 
                    $group->add_group_member($sender,1);
                }
            }
            $msg->{sender} = $sender;
            $msg->{receiver} = $receiver;
            $msg->{group} = $group;
        }
        elsif($msg->{via} eq "discuss"){
            my $sender;
            my $receiver = $self->user;
            my $discuss;
            $discuss = $self->search_discuss(did=>$msg->{discuss_id});
            if(defined $discuss){
                $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                unless(defined $sender){
                    $self->update_discuss($discuss);
                    $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                    $sender = Mojo::Webqq::Discuss::Member->new(
                        did=>$msg->{discuss_id},
                        id=>$msg->{sender_id},
                        nick=>"昵称未知",
                        _client=>$self,
                    ) unless defined $sender;
                }
            }                
            else{            
                $self->update_discuss();
                $discuss = $self->search_discuss(did=>$msg->{discuss_id});
                $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                $sender = Mojo::Webqq::Discuss::Member->new(did=>$msg->{discuss_id},id=>$msg->{sender_id},nick=>"昵称未知")                     unless defined $sender; 
            }                
            $msg->{sender} = $sender;
            $msg->{receiver} = $receiver;
            $msg->{discuss} = $discuss;
        } 
        $msg = Mojo::Webqq::Message::Recv::SessMessage->new($msg);
    }
    elsif($msg->{type} eq "discuss_message"){
        my $sender;
        my $discuss;
        $discuss = $self->search_discuss(did=>$msg->{discuss_id});
        if(defined $discuss){
            $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
            unless(defined $sender){
                $self->update_discuss($discuss);
                $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                $sender = Mojo::Webqq::Discuss::Member->new(_client=>$self,did=>$msg->{discuss_id},id=>$msg->{sender_id},nick=>"昵称未知") 
                    unless defined $sender;
            }
        }
        else{
            $self->update_discuss();
            $discuss = $self->search_discuss(did=>$msg->{discuss_id});
            return unless defined $discuss;
            $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
            $sender = Mojo::Webqq::Discuss::Member->new(_client=>$self,did=>$msg->{discuss_id},id=>$msg->{sender_id},nick=>"昵称未知") 
                unless defined $sender;
        }
        $msg->{sender} = $sender;
        $msg->{discuss} = $discuss;
        $msg = Mojo::Webqq::Message::Recv::DiscussMessage->new($msg);
    }
    elsif($msg->{type} eq "state_message"){ 
        $msg = Mojo::Webqq::Message::Recv::StateMessage->new($msg);
    }
    elsif($msg->{type} eq "system_message"){
        return;
        #$msg = Mojo::Webqq::Message::Recv::SystemMessage->new($msg);
    }
    else{
        return;
    }

    $self->message_queue->put($msg);
}

sub format_msg{
    my $self = shift;
    my $msg_header  = shift;
    my $msg_content = shift;
    my @msg_content = split /\n/,$msg_content;
    $msg_header = decode("utf8",$msg_header);
    my $chinese_count=()=$msg_header=~/\p{Han}/g    ;
    my $total_count = length($msg_header);
    $msg_header=encode("utf8",$msg_header);

    my @msg_header = ($msg_header,(' ' x ($total_count-$chinese_count+$chinese_count*2)) x $#msg_content  );
    while(@msg_content){
        my $lh = shift @msg_header;
        my $lc = shift @msg_content;
        #你的终端可能不是UTF8编码，为了防止乱码，做下编码自适应转换
        $self->info($lh, $lc,"\n");
    }
}
1;
