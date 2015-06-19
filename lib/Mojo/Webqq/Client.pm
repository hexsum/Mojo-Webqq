package Mojo::Webqq::Client;
use strict;
use Mojo::IOLoop;
$Mojo::Webqq::Client::CLIENT_COUNT  = 0;
$Mojo::Webqq::Client::LAST_DISPATCH_TIME  = undef;
$Mojo::Webqq::Client::SEND_INTERVAL  = 3;

use Mojo::Webqq::Client::Remote::_prepare_for_login;
use Mojo::Webqq::Client::Remote::_check_verify_code;
use Mojo::Webqq::Client::Remote::_get_img_verify_code;
use Mojo::Webqq::Client::Remote::_login1;
use Mojo::Webqq::Client::Remote::_check_sig;
use Mojo::Webqq::Client::Remote::_login2;
use Mojo::Webqq::Client::Remote::_get_vfwebqq;
use Mojo::Webqq::Client::Remote::_cookie_proxy;
use Mojo::Webqq::Client::Remote::change_state;
use Mojo::Webqq::Client::Remote::_get_offpic;
use Mojo::Webqq::Client::Remote::_recv_message;
use Mojo::Webqq::Client::Remote::_relink;
use Mojo::Webqq::Client::Remote::logout;

use Mojo::Webqq::Message::Send::Status;

use base qw(Mojo::Webqq::Request Mojo::Webqq::Client::Cron Mojo::EventEmitter Mojo::Webqq::Base);

sub run{
    my $self = shift;
    $self->ready();

    my $plugins = $self->plugins;
    for(
        sort {$plugins->{$b}{priority} <=> $plugins->{$a}{priority} } 
        grep {$plugins->{$_}{auto_call} == 1} keys %{$plugins}
    ){
        $self->call($_);
    }

    $self->emit("run");
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}
sub stop{
    my $self = shift;
    my $mode = shift || "auto";
    $self->is_stop(1);
    if($mode eq "auto"){
        $Mojo::Webqq::Client::CLIENT_COUNT > 1?$Mojo::Webqq::Client::CLIENT_COUNT--:exit;
    }
    else{
        $Mojo::Webqq::Client::CLIENT_COUNT--;
    }
}
sub exit{
    my $s = shift;  
    my $code = shift;
    exit(defined $code?$code+0:0);
}
sub ready{
    my $self = shift;
    $self->set_message_queue();
    $self->on("model_update_fail"=>sub{
        my $self = shift;
        my $last_model_update_failure_count = $self->model_update_failure_count;
        $self->model_update_failure_count(++$last_model_update_failure_count);  
        if($self->model_update_failure_count >= $self->model_update_failure_count_max ){
            $self->model_update_failure_count(0);
            $self->_relink();
        }
    });
    $self->interval(600,sub{
        return if $self->is_stop;
        $self->update_group;
    });

    $self->timer(60,sub{
        $self->interval(600,sub{
            return if $self->is_stop;
            $self->update_discuss;    
        });
    });

    $self->timer(60+60,sub{
        $self->interval(600,sub{
            return if $self->is_stop;
            $self->update_friend;
        });
    });

    $self->info("开始接收消息...\n");
    $self->_recv_message(); 
    $self->emit("ready");
    $Mojo::Webqq::Client::CLIENT_COUNT++;
}

sub timer {
    my $self = shift;
    Mojo::IOLoop->timer(@_);
    return $self;
}
sub interval{
    my $self = shift;
    Mojo::IOLoop->recurring(@_);
    return $self;
}
sub relogin{
    my $self = shift;
    $self->info("正在重新登录...\n");
    $self->logout();
    $self->login_state("relogin");
    $self->sess_sig_cache(Mojo::Webqq::Cache->new);
    $self->id_to_qq_cache(Mojo::Webqq::Cache->new);
    $self->ua->cookie_jar->empty;

    $self->user(+{});
    $self->friend([]);
    $self->group([]);
    $self->discuss([]);
    $self->recent([]);

    $self->login(qq=>$self->qq,pwd=>$self->pwd);
    $self->emit("relogin");
}
sub login {
    my $self = shift;
    my %p = @_;
    $self->qq($p{qq})->pwd($p{pwd});
    if(
           $self->_prepare_for_login()    
        && $self->_check_verify_code()     
        && $self->_get_img_verify_code()

    ){
        while(1){
            my $ret = $self->_login1();
            if($ret == -1){
                $self->_get_img_verify_code();
                next;
            }
            elsif($ret == -2){
                $self->error("登录失败，尝试更换加密算法计算方式，重新登录...");
                $self->encrypt_method("js");
                $self->relogin();
                return;
            }
            elsif($ret == 1){
                   $self->_check_sig() 
                && $self->_get_vfwebqq()
                && $self->_login2();
                last;
            }
            else{
                last;
            }
        }
    }

    #登录不成功，客户端退出运行
    if($self->login_state ne 'success'){
        $self->fatal("登录失败，客户端退出（可能网络不稳定，请多尝试几次）\n");
        $self->stop();
    }
    else{
        $self->info("登录成功\n");
        $self->update_user;
        $self->update_friend;
        $self->update_group;
        $self->update_discuss;
        $self->update_recent;

        $self->emit("login");
    }
}

sub set_message_queue{
    my $self = shift;
    #设置从接收消息队列中接收到消息后对应的处理函数
    $self->message_queue->get(sub{
        my $msg = shift;
        return if $self->is_stop; 
        if($msg->msg_class eq "recv"){
            if($msg->type eq 'message'){
                if($self->has_subscribers("receive_offpic")){
                    for(@{$msg->raw_content}){
                        if($_->{type} eq 'offpic'){
                            $self->_get_offpic($_->{file_path},$msg->sender_id);
                        }   
                    }
                }
                #$self->_detect_new_friend($msg);
            }
            elsif($msg->type eq 'group_message'){
                #$self->_detect_new_group($msg);
                #$self->_detect_new_group_member($msg);
            }
            elsif($msg->type eq 'discuss_message'){
                #$self->_detect_new_discuss($msg);
                #$self->_detect_new_discuss_member($msg);
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
                $self->debug("消息[ " . $msg->msg_id.  " ]已被消息队列丢弃，当前TTL: ". $msg->ttl);
                my $status = Mojo::Webqq::Message::Send::Status->new(code=>-1,msg=>"发送失败");
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
            if(defined $Mojo::Webqq::Client::LAST_DISPATCH_TIME){
                $delay = $now<$Mojo::Webqq::Client::LAST_DISPATCH_TIME+$Mojo::Webqq::Client::SEND_INTERVAL?
                            $Mojo::Webqq::Client::LAST_DISPATCH_TIME+$Mojo::Webqq::Client::SEND_INTERVAL-$now
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
            $Mojo::Webqq::Client::LAST_DISPATCH_TIME = $now+$delay;
        }
    });
}

sub mail{
    my $self  = shift;
    my %opt = @_;
    #smtp
    #port
    #tls
    #tls_ca
    #tls_cert
    #tls_key
    #user
    #pass
    #from
    #to
    #cc
    #subject
    #charset
    #html
    #text
    #data MIME::Lite产生的发送数据
    eval{ require Mojo::SMTP::Client;} ;
    if($@){
        $self->error("发送邮件，请先安装模块 Mojo::SMTP::Client");
        return;
    }
    my $smtp = Mojo::SMTP::Client->new(
        address => $opt{smtp},
        port    => $opt{port} || 25,
        tls     => $opt{tls}||"",
        tls_ca  => $opt{tls_ca}||"",
        tls_cert=> $opt{tls_cert}||"",
        tls_key => $opt{tls_key}||"",
    ); 
    unless(defined $smtp){
        $self->error("Mojo::SMTP::Client客户端初始化失败");
        return;
    }
    my $data;
    if(defined $opt{data}){$data = $opt{data}}
    else{
        my @data;
        push @data,("From: $opt{from}","To: $opt{to}");
        push @data,"Cc: $opt{cc}" if defined $opt{cc};
        push @data,"Subject: $opt{subject}";
        my $charset = defined $opt{charset}?$opt{charset}:"UTF-8";
        if(defined $opt{text}){
            push @data,("Content-Type: text/plain; charset=$charset",'',$opt{text});
        }
        elsif(defined $opt{html}){
            push @data,("Content-Type: text/html; charset=$charset",'',$opt{html});
        }
        $data = join "\r\n",@data;
    }
    $smtp->send(
        auth    => {login=>$opt{user},password=>$opt{pass}},
        from    => $opt{from},
        to      => $opt{to},
        data    => $data,
        quit    => 1,
        sub{
            my ($smtp, $resp) = @_;
            if($resp->error){
                $self->error("邮件[ To: $opt{to}|Subject: $opt{subject} ]发送失败: " . $resp->error );
                return;
            }
            else{
                $self->debug("邮件[ To: $opt{to}|Subject: $opt{subject} ]发送成功");
            }
        },
    );
    
}

1;
