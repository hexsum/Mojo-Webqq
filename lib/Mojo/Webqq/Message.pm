package Mojo::Webqq::Message;
use strict;
use Mojo::JSON qw(encode_json);
$Mojo::Webqq::Message::LAST_DISPATCH_TIME  = undef;
$Mojo::Webqq::Message::SEND_INTERVAL  = 3;
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
use Mojo::Webqq::Message::XMLescape;
use Mojo::Webqq::Message::Emoji;

sub gen_message_queue{
    my $self = shift;
    Mojo::Webqq::Message::Queue->new(sub{
        my $msg = shift;
        return if $self->is_stop; 
        if($msg->msg_class eq "recv"){
            if($msg->type eq 'message'){
                if(     $self->has_subscribers("receive_pic") 
                    or  $self->has_subscribers("receive_friend_pic") 
                ){
                    for(@{$msg->raw_content}){
                        if($_->{type} eq 'offpic'){
                            $self->_get_offpic($_->{file_path},$msg->sender);
                        }   
                    }
                }
            }
            elsif($msg->type eq 'sess_message'){
                if(     $self->has_subscribers("receive_pic")
                    or  $self->has_subscribers("receive_sess_pic")
                ){
                    for(@{$msg->raw_content}){
                        if($_->{type} eq 'offpic'){
                            $self->_get_offpic($_->{file_path},$msg->sender);
                        }  
                    }
                }
            }
            elsif($msg->type eq 'group_message'){
                if($self->has_subscribers("receive_pic") or $self->has_subscribers("receive_group_pic")){
                    for(@{$msg->raw_content}){
                        if($_->{type} eq 'cface'){
                            return unless exists $_->{server};
                            return unless exists $_->{file_id};
                            return unless exists $_->{name};
                            my ($ip,$port) = split /:/,$_->{server};
                            $port = 80 unless defined $port;
                            $self->_get_group_pic($_->{file_id},$_->{name},$ip,$port,$msg->sender);
                        }
                    }
                }
            }
            elsif($msg->type eq 'discuss_message'){
            }
            elsif($msg->type eq 'state_message'){
                my $friend = $self->search_friend(id=>$msg->id);
                if(defined $friend){
                    $friend->state($msg->state);
                    $friend->client_type($msg->client_type);
                    $self->emit(friend_state_change=>$friend);
                }
                return $self;
            }
            
            #接收队列中接收到消息后，调用相关的消息处理回调，如果未设置回调，消息将丢弃
            $self->emit(receive_message=>$msg);
        }
        elsif($msg->msg_class eq "send"){
            #消息的ttl值减少到0则丢弃消息
            if($msg->ttl <= 0){
                $self->warn("消息[ " . $msg->msg_id.  " ]已被消息队列丢弃，当前TTL: ". $msg->ttl);
                my $status = $self->new_send_status(code=>-5,msg=>"发送失败",info=>"TTL失效");
                if(ref $msg->cb eq 'CODE'){
                    $msg->cb->(
                        $self,
                        $msg,
                        $status,
                    );
                }
                $self->emit(send_message=>
                    $msg,
                    $status,
                );
                return;
            }
            my $ttl = $msg->ttl;
            $msg->ttl(--$ttl);

            my $delay = 0;
            my $now = time;
            if(defined $Mojo::Webqq::Message::LAST_DISPATCH_TIME){
                $delay = $now<$Mojo::Webqq::Message::LAST_DISPATCH_TIME+$Mojo::Webqq::Message::SEND_INTERVAL?
                            $Mojo::Webqq::Message::LAST_DISPATCH_TIME+$Mojo::Webqq::Message::SEND_INTERVAL-$now
                        :   0;
            }
            $self->timer($delay,sub{
                $msg->msg_time(time);
                    $msg->type eq 'message'           ?   $self->_send_message($msg)
                :   $msg->type eq 'group_message'     ?   $self->_send_group_message($msg)
                :   $msg->type eq 'sess_message'      ?   $self->_send_sess_message($msg)
                :   $msg->type eq 'discuss_message'   ?   $self->_send_discuss_message($msg)
                :                                           undef
                ;
            });
            $Mojo::Webqq::Message::LAST_DISPATCH_TIME = $now+$delay;
        }
    });
}
sub gen_message_id {
    my $self             = shift;
    my $last_send_msg_id = $self->send_msg_id;
    $self->send_msg_id(++$last_send_msg_id);
    return $last_send_msg_id;
}

sub reply_message{
    my $self = shift;
    my ($msg,$content,$cb) = @_;
    if($msg->type eq "message"){
        $self->send_message($msg->sender,$content,$cb) if $msg->msg_class eq "recv";
        $self->send_message($msg->receiver,$content,$cb) if $msg->msg_class eq "send";
    }
    elsif($msg->type eq "group_message"){
        $self->send_group_message($msg->group,$content,$cb);
    }
    elsif($msg->type eq "discuss_message"){
        $self->send_discuss_message($msg->discuss,$content,$cb);
    }
    elsif($msg->type eq "sess_message"){
        $self->send_sess_message($msg->sender,$content,$cb) if $msg->msg_class eq "recv";
        $self->send_sess_message($msg->receiver,$content,$cb) if $msg->msg_class eq "send";
    }
}
sub send_message{
    my $self = shift;
    if(@_==1){
        my $msg = shift;
        $self->die("不支持的数据类型") if ref $msg ne "Mojo::Webqq::Message::Send::Message";
        my $content = $msg->content;
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
        $self->message_queue->put($msg);
        return $self;
    }
    my ($friend,$content,$cb) = @_;
    if(!defined $content or $content eq ""){
        $self->warn("发送好友消息，内容不能为空");
        return;
    }
    if(ref $friend eq "Mojo::Webqq::Friend" and defined $friend->id){
        #my $msg =  Mojo::Webqq::Message::Send::Message->new({
        my $msg =  $self->new_send_message({
            msg_id      => $self->gen_message_id,
            sender_id   => $self->user->id,
            receiver_id => $friend->id,
            sender      => $self->user,
            receiver    => $friend,
            content     => $content,
            raw_content => $self->face_parse($content),
            msg_from    => 'code',
            ttl         => $self->msg_ttl,
        });    
        $cb->($self,$msg) if ref $cb eq "CODE";
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
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
        my $content = $msg->content;
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
        $self->message_queue->put($msg);
        return $self;
    }
    my ($group,$content,$cb) = @_;
    if(!defined $content or $content eq ""){
        $self->warn("发送群消息，内容不能为空");
        return;
    }
    if(ref $group eq "Mojo::Webqq::Group" and defined $group->gid){
        my $sender = $group->me || $self->user;
        #my $msg =  Mojo::Webqq::Message::Send::GroupMessage->new({
        my $msg =  $self->new_send_group_message({
            msg_id      => $self->gen_message_id,
            sender_id   => $sender->id,
            group_id    => $group->gid,
            sender      => $sender,
            group       => $group,
            content     => $content,
            raw_content => $self->face_parse($content),
            msg_from    => 'code',
            ttl         => $self->msg_ttl,
        });
        $cb->($self,$msg) if ref $cb eq "CODE";
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
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
        $self->die("不支持的数据类型") if ref $msg ne "Mojo::Webqq::Message::Send::DiscussMessage";
        my $content = $msg->content;
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
        $self->message_queue->put($msg);
        return $self;
    }
    my ($discuss,$content,$cb) = @_;
    if(!defined $content or $content eq ""){
        $self->warn("发送讨论组消息，内容不能为空");
        return;
    }
    if(ref $discuss eq "Mojo::Webqq::Discuss" and defined $discuss->did){
        my $sender = $discuss->search_discuss_member(id=>$self->user->id) || $self->user;
        #my $msg =  Mojo::Webqq::Message::Send::DiscussMessage->new({
        my $msg =  $self->new_send_discuss_message({
            msg_id      => $self->gen_message_id,
            sender_id   => $sender->id,
            discuss_id  => $discuss->did,
            sender      => $sender,
            discuss     => $discuss,
            content     => $content,
            raw_content => $self->face_parse($content), 
            msg_from    => 'code',
            ttl         => $self->msg_ttl,
        });
        $cb->($self,$msg) if ref $cb eq "CODE";
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
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
        my $content = $msg->content;
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
        $self->message_queue->put($msg);
        return $self;
    }
    my ($member,$content,$cb) = @_;
    if(!defined $content or $content eq ""){
        $self->warn("发送临时消息，内容不能为空");
        return;
    }
    if(ref $member eq "Mojo::Webqq::Group::Member" and defined $member->gid and defined $member->id){
        my $group = $self->search_group(gid=>$member->gid);
        return unless defined $group;
        my $sender = $group->search_group_member(id=>$self->user->id) || $self->user;
        #my $msg =  Mojo::Webqq::Message::Send::SessMessage->new({
        my $msg =  $self->new_send_sess_message({
            msg_id      => $self->gen_message_id,
            sender_id   => $sender->id,
            receiver_id => $member->id,
            group_id    => $member->gid,
            sender      => $sender,
            receiver    => $member,
            group       => $self->search_group(gid=>$member->gid),
            content     => $content,
            raw_content => $self->face_parse($content),
            via         => "group",
            sess_sig    => $self->_get_sess_sig($member->gid,$member->id,0),
            msg_from    => 'code',
            ttl         => $self->msg_ttl,
        });
        $cb->($self,$msg) if ref $cb eq "CODE";
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
        $self->message_queue->put($msg);
    }
    elsif(ref $member eq "Mojo::Webqq::Discuss::Member" and defined $member->did and defined $member->id){
        my $discuss = $self->search_discuss(did=>$member->did);
        return unless defined $discuss;
        my $sender = $discuss->search_discuss_member(id=>$self->user->id) || $self->user;
        my $msg =  Mojo::Webqq::Message::Send::SessMessage->new({
            msg_id      => $self->gen_message_id,
            sender_id   => $sender->id,
            receiver_id => $member->id,
            discuss_id  => $member->did,
            sender      => $sender,
            receiver    => $member,
            discuss     => $self->search_discuss(did=>$member->did),
            content     => $content,
            raw_content => $self->face_parse($content),
            via         => "discuss",
            sess_sig    => $self->_get_sess_sig($member->did,$member->id,1),
            msg_from    => 'code',
        });
        $cb->($self,$msg) if ref $cb eq "CODE";
        $self->emit(before_send_message=>$msg);
        $msg->raw_content($self->face_parse($msg->content)) if $msg->content ne $content;
        $self->message_queue->put($msg);
    }
    else{
        $self->die("不支持的数据类型");
    }
}

sub parse_send_status_msg{
    my $self = shift;
    my $json = shift;
    if(defined $json){
        if(exists $json->{errCode}){
            if($json->{errCode}==0 and exists $json->{msg} and $json->{msg} eq 'send ok'){
                return $self->new_send_status(code=>0,msg=>"发送成功",info=>'发送正常');
            }
            elsif(exists $json->{errMsg} and $json->{errMsg} eq "ERROR"){
                return $self->new_send_status(code=>-3,msg=>"发送失败",info=>'发送异常');
            }
            else{
                return $self->new_send_status(code=>-4,msg=>"发送失败",info=>'响应未知: ' . encode_json($json));
            }
        }
        elsif(exists $json->{retcode}){
            if($json->{retcode}==0){
                return $self->new_send_status(code=>0,msg=>"发送成功",info=>'发送正常');
            }
            elsif($json->{retcode}==1202){
                if($self->ignore_1202){
                    return $self->new_send_status(code=>0,msg=>"发送成功",info=>'无法判断是否发送成功');
                }
                else{
                    return $self->new_send_status(code=>-5,msg=>"发送失败",info=>'发送异常1202');
                }
            }
            else{
                return $self->new_send_status(code=>-4,msg=>"发送失败",info=>'响应未知: ' . encode_json($json));
            }
        }
        else{
            return $self->new_send_status(code=>-2,msg=>"发送失败",info=>'响应未知: ' . encode_json($json));
        }
    }
    else{
        return $self->new_send_status(code=>-1,msg=>"发送失败",info=>'数据格式错误'); 
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
                    receiver_id => $m->{value}{to_uin},
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
                next if " \x{0000}\n\x{0000}\x{0000}\x{0000}\x{0000}\x{0002}\x{5B8B}\x{4F53}\r" eq $m->{value}{content}[1];
                my $msg = {
                    type        => "group_message",
                    msg_id      => $m->{value}{msg_id},
                    group_id    => $m->{value}{from_uin},
                    receiver_id => $m->{value}{to_uin},
                    msg_time    => $m->{value}{'time'},
                    content     => $m->{value}{content},
                    sender_id   => $m->{value}{send_uin},
                };
                #if(     $msg->{content}=~/\(\d+\) 被管理员禁言\d+(分钟|小时|天)$/ 
                #    or  $msg->{content}=~/\(\d+\) 被管理员解除禁言$/
                #){
                #    $msg->{type} = "system_message";
                #}
                $self->msg_put($msg);
            }

            #收到讨论组消息
            elsif ( $m->{poll_type} eq 'discu_message' ) {
                my $msg = {
                    type        => "discuss_message",
                    discuss_id  => $m->{value}{did},
                    msg_id    => $m->{value}{msg_id},
                    sender_id => $m->{value}{send_uin},
                    msg_time  => $m->{value}{'time'},
                    receiver_id  =>  $m->{value}{'to_uin'},
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

            elsif( $m->{poll_type} eq 'group_web_message' ){
                if(exists $m->{value}{xml}){
                    my %info;
                    eval{
                        require Mojo::DOM;
                        Mojo::DOM->new($m->{value}{xml})->find('d > n')->each(sub{
                            my ($e, $num) = @_;
                            if($e->attr("t") eq "h" ){
                                $info{qq} = $e->attr("u");
                            }
                            elsif($e->attr("t") eq "t" ){
                                if($e->attr("s") eq decode("utf8","共享文件")){
                                    $info{type} = 'share-file';
                                }
                                else{
                                    $info{file} = encode("utf8",$e->attr("s"));
                                }
                            }
                        });
                    };
                    if(defined $info{type} and $info{type} eq 'share-file'){
                        my $msg = {
                            type        => "group_message",
                            msg_id      => $m->{value}{msg_id},
                            group_id    => $m->{value}{from_uin},
                            msg_time    => time,
                            content     => [[],decode("utf8","共享文件 [$info{file}]")],
                            sender_id   => $m->{value}{send_uin},
                            
                        };
                        $self->msg_put($msg);
                    }
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
    elsif ( $json->{retcode} == 100 or $json->{retcode} == 103) {
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
        $self->poll_failure_count( ++$poll_failure_count);
        $self->warn( "获取消息失败，当前失败次数: ". $self->poll_failure_count. "\n" );
        if ( $self->poll_failure_count > $self->poll_failure_count_max ) {
            $self->poll_failure_count(0);
            #$self->warn("接收消息失败次数超过最大值，尝试进行重新连接...\n");
            #$self->_relink();
            $self->warn("接收消息失败次数超过最大值，尝试进行重新登录...\n");
            $self->relogin();
        }
    }

}

sub msg_put{   
    my $self = shift;
    my $msg = shift;
    if(     $msg->{type} eq "message" 
        or  $msg->{type} eq "group_message" 
        or  $msg->{type} eq "sess_message" 
        or  $msg->{type} eq "discuss_message"
    ){
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
            #elsif($c eq " "){
            #    next;
            #}
            else{
                $c=encode("utf8",$c);
                $c=$self->xmlescape_parse($c);
                #$c=~s/ $//;   
                $c=~s/\r\n/\n/g;
                my $res = $self->emoji_parse($c);
                push @{$msg->{raw_content}},@$res;
                $c = join "",map{$_->{content}} @$res;
                #push @{$msg->{raw_content}},{
                #    type    =>  'txt',
                #    content =>  $c,
                #};
            }
            $msg_content .= $c;
        }
        $msg->{content} = $msg_content;
        #$msg->{$_} = encode("utf8",$msg->{$_} ) for grep {$_ ne 'raw_content'}  keys %$msg;
        #$msg->{content}=~s/\r|\n/\n/g;
    }
    if($msg->{type} eq "message"){
        my $sender = $self->search_friend(id=>$msg->{sender_id});
        my $receiver = $self->user;
        unless(defined $sender){#new friend
            $self->update_friend();     
            $sender = $self->search_friend(id=>$msg->{sender_id});
            unless(defined $sender){
                $sender = $self->new_friend(
                    id          =>  $msg->{sender_id},
                    nick        =>  "昵称未知",
                    category    =>  "陌生人",
                );
                $self->add_friend($sender,1);
            }
        }
        $msg->{sender} = $sender;
        $msg->{receiver} = $receiver;
        #$msg = Mojo::Webqq::Message::Recv::Message->new($msg);
        $msg = $self->new_recv_message($msg);
    }
    elsif($msg->{type} eq "group_message"){ 
        my $sender;
        my $receiver;
        my $group;  
        $group = $self->search_group(gid=>$msg->{group_id});
        if(defined $group){
            $sender = $group->search_group_member(id=>$msg->{sender_id});
            $receiver = $group->search_group_member(id=>$msg->{receiver_id}) || $self->user;
            unless(defined $sender){
                $self->update_group($group);
                $sender = $group->search_group_member(id=>$msg->{sender_id});
                unless(defined $sender){
                    $sender = $self->new_group_member(
                        id=>$msg->{sender_id},
                        nick=>"昵称未知",   
                        gid=>$group->gid,
                        gcode=>$group->gcode,
                        gname=>$group->gname,
                        gmarkname=>$group->gmarkname,
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
            $receiver = $group->search_group_member(id=>$msg->{receiver_id}) || $self->user;
            unless(defined $sender){
                $sender = $self->new_group_member(
                    id  =>  $msg->{sender_id},  
                    nick=>"昵称未知",
                    gid =>  $group->gid,
                    gcode=>$group->gcode,   
                    gname=>$group->gname,
                    gmarkname=>$group->gmarkname,
                );
                $group->add_group_member($sender,1);
            }
        }
        $msg->{sender} = $sender;
        $msg->{receiver} = $receiver;
        $msg->{group} = $group;
        #$msg = Mojo::Webqq::Message::Recv::GroupMessage->new($msg);
        $msg = $self->new_recv_group_message($msg);
    }
    elsif($msg->{type} eq "sess_message"){
        if($msg->{via} eq "group"){
            my $sender;
            my $receiver;
            my $group;
            $group = $self->search_group(gid=>$msg->{group_id});
            if(defined $group){
                $sender = $group->search_group_member(id=>$msg->{sender_id});
                $receiver = $group->search_group_member(id=>$msg->{receiver_id}) || $self->user;
                unless(defined $sender){
                    $self->update_group($group);
                    $sender = $group->search_group_member(id=>$msg->{sender_id});
                    unless(defined $sender){
                        $sender = $self->new_group_member(
                            gid=>$msg->{group_id},
                            gcode=>$group->gcode,
                            gname=>$group->gname,
                            gmarkname=>$group->gmarkname,
                            id=>$msg->{sender_id},
                            nick=>"昵称未知",
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
                $receiver = $group->search_group_member(id=>$msg->{receiver_id}) || $self->user;
                unless(defined $sender){
                    $sender = $self->new_group_member(
                        gid=>$msg->{group_id},
                        id=>$msg->{sender_id},
                        nick=>"昵称未知",
                        gcode=>$group->gcode,
                        gname=>$group->gname,
                        gmarkname=>$group->gmarkname,
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
            my $receiver;
            my $discuss;
            $discuss = $self->search_discuss(did=>$msg->{discuss_id});
            if(defined $discuss){
                $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                $receiver = $discuss->search_discuss_member(id=>$msg->{receiver_id}) || $self->user;
                unless(defined $sender){
                    $self->update_discuss($discuss);
                    $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                    unless(defined $sender){
                        $sender = $self->new_discuss_member(
                            did=>$msg->{discuss_id},
                            id=>$msg->{sender_id},
                            nick=>"昵称未知",
                        );
                        $discuss->add_group_member($sender,1);
                    }
                }
            }                
            else{            
                $self->update_discuss();
                $discuss = $self->search_discuss(did=>$msg->{discuss_id});
                return unless defined $discuss;
                $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                $receiver = $discuss->search_discuss_member(id=>$msg->{receiver_id}) || $self->user;
                unless(defined $sender){
                    $sender = $self->new_discuss_member(
                        did=>$msg->{discuss_id},
                        id=>$msg->{sender_id},
                        nick=>"昵称未知"
                    );
                    $discuss->add_discuss_member($sender,1);
                }
            }                
            $msg->{sender} = $sender;
            $msg->{receiver} = $receiver;
            $msg->{discuss} = $discuss;
        } 
        #$msg = Mojo::Webqq::Message::Recv::SessMessage->new($msg);
        $msg = $self->new_recv_sess_message($msg);
    }
    elsif($msg->{type} eq "discuss_message"){
        my $sender;
        my $receiver;
        my $discuss;
        $discuss = $self->search_discuss(did=>$msg->{discuss_id});
        if(defined $discuss){
            $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
            $receiver = $discuss->search_discuss_member(id=>$msg->{receiver_id}) || $self->user;
            unless(defined $sender){
                $self->update_discuss($discuss);
                $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
                unless(defined $sender){
                    $sender = $self->new_discuss_member(did=>$msg->{discuss_id},id=>$msg->{sender_id},nick=>"昵称未知");
                    $discuss->add_discuss_member($sender,1);
                }
            }
        }
        else{
            $self->update_discuss();
            $discuss = $self->search_discuss(did=>$msg->{discuss_id});
            return unless defined $discuss;
            $sender = $discuss->search_discuss_member(id=>$msg->{sender_id});
            $receiver = $discuss->search_discuss_member(id=>$msg->{receiver_id}) || $self->user;
            unless(defined $sender){
                $sender = $self->new_discuss_member(did=>$msg->{discuss_id},id=>$msg->{sender_id},nick=>"昵称未知");
                $discuss->add_discuss_member($sender,1);
            }
        }
        $msg->{sender} = $sender;
        $msg->{discuss} = $discuss;
        $msg->{receiver} = $receiver;
        #$msg = Mojo::Webqq::Message::Recv::DiscussMessage->new($msg);
        $msg = $self->new_recv_discuss_message($msg);
    }
    elsif($msg->{type} eq "state_message"){ 
        $msg = $self->new_recv_state($msg);
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

sub _new_message_hash{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    return $hash;
}
sub new_recv_group_message{
    my $self = shift;
    Mojo::Webqq::Message::Recv::GroupMessage->new($self->_new_message_hash(@_));
}
sub new_send_group_message{
    my $self = shift;
    Mojo::Webqq::Message::Send::GroupMessage->new($self->_new_message_hash(@_));
}
sub new_recv_discuss_message{
    my $self = shift;
    Mojo::Webqq::Message::Recv::DiscussMessage->new($self->_new_message_hash(@_));
}
sub new_send_discuss_message{
    my $self = shift;
    Mojo::Webqq::Message::Send::DiscussMessage->new($self->_new_message_hash(@_));
}
sub new_recv_sess_message{
    my $self = shift;
    Mojo::Webqq::Message::Recv::SessMessage->new($self->_new_message_hash(@_));
}
sub new_send_sess_message{
    my $self = shift;
    Mojo::Webqq::Message::Send::SessMessage->new($self->_new_message_hash(@_));
}
sub new_recv_message{
    my $self = shift;
    Mojo::Webqq::Message::Recv::Message->new($self->_new_message_hash(@_));
}
sub new_send_message{
    my $self = shift;
    Mojo::Webqq::Message::Send::Message->new($self->_new_message_hash(@_));
}
sub new_send_status {
    my $self = shift;
    Mojo::Webqq::Message::Send::Status->new($self->_new_message_hash(@_));
}

sub new_recv_state{
    my $self = shift;
    Mojo::Webqq::Message::Recv::StateMessage->new($self->_new_message_hash(@_));
}
1;
