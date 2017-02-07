package Mojo::Webqq::Client;
use strict;
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;
$Mojo::Webqq::Client::CLIENT_COUNT  = 0;
use Mojo::Webqq::Message::Handle;
use Mojo::Webqq::Client::Remote::_prepare_for_login;
use Mojo::Webqq::Client::Remote::_check_verify_code;
use Mojo::Webqq::Client::Remote::_get_img_verify_code;
use Mojo::Webqq::Client::Remote::_get_qrlogin_pic;
use Mojo::Webqq::Client::Remote::_login1;
use Mojo::Webqq::Client::Remote::_check_sig;
use Mojo::Webqq::Client::Remote::_login2;
use Mojo::Webqq::Client::Remote::_get_vfwebqq;
use Mojo::Webqq::Client::Remote::_cookie_proxy;
use Mojo::Webqq::Client::Remote::change_state;
use Mojo::Webqq::Client::Remote::_get_offpic;
use Mojo::Webqq::Client::Remote::_get_group_pic;
use Mojo::Webqq::Client::Remote::_recv_message;
use Mojo::Webqq::Client::Remote::_relink;
use Mojo::Webqq::Client::Remote::logout;

sub run{
    my $self = shift;
    $self->ready() if not $self->is_ready;
    $self->emit("run");
    $self->ioloop->start unless $self->ioloop->is_running;
}

sub steps {
    my $self = shift;
    Mojo::IOLoop::Delay->new(ioloop=>$self->ioloop)->steps(@_)->catch(sub {
        my ($delay, $err) = @_;
        $self->error("steps error: $err");
    })->wait;
    $self;
}
sub stop{
    my $self = shift;
    return if $self->is_stop;
    $self->is_stop(1);
    $self->state('stop');
    $self->emit("stop");
    $self->info("客户端停止运行");
    CORE::exit;
}
sub ready{
    my $self = shift;
    $self->state('loading');
    #加载插件
    my $plugins = $self->plugins;
    for(
        sort {$plugins->{$b}{priority} <=> $plugins->{$a}{priority} } 
        grep {defined $plugins->{$_}{auto_call} and $plugins->{$_}{auto_call} == 1} keys %{$plugins}
    ){
        $self->call($_);
    }
    $self->emit("after_load_plugin");
    $self->login() if $self->login_state ne 'success';
    $self->relogin() if $self->get_model_status() == 0;

    $self->interval($self->update_interval || 600,sub{
        return if $self->is_stop;
        return if not $self->is_update_group;
        $self->update_group(is_blocking=>0,is_update_group_ext=>0,is_update_group_member=>1,is_update_group_member_ext=>0);
    });

    $self->timer(60,sub{
        $self->interval($self->update_interval || 600,sub{
            return if $self->is_stop;
            return if not $self->is_update_discuss;
            $self->update_discuss(is_blocking=>0,is_update_discuss_member=>1);    
        });
    });

    $self->timer(60+60,sub{
        $self->interval($self->update_interval || 600,sub{
            return if $self->is_stop;
            return if not $self->is_update_friend;
            $self->update_friend(is_blocking=>0,is_update_friend_ext=>0);
        });
    });

    $self->timer(60+60+60,sub{
        $self->interval($self->update_interval || 600,sub{
            return if $self->is_stop;
            return if not $self->is_update_user;
            $self->update_user(is_blocking=>0);
        });
    });

    #接收消息
    $self->on(poll_over=>sub{ $self->state('running');my $self = $_[0];$self->timer(1,sub{$self->_recv_message()}) } );
    $self->on(run=>sub{
        my $self = $_[0]; 
        $self->info("开始接收消息..."); 
        $self->state('running');
        $self->_recv_message();
    });
    $self->is_ready(1);
    $self->emit("ready");
    return $self;
}

sub timer {
    my $self = shift;
    return $self->ioloop->timer(@_);
}
sub interval{
    my $self = shift;
    return $self->ioloop->recurring(@_);
}
sub relogin{
    my $self = shift;
    $self->info("正在重新登录...\n");
    if(defined $self->poll_connection_id){
        eval{
            $self->ioloop->remove($self->poll_connection_id);
            $self->is_polling(0);
            $self->info("停止接收消息...");
        };
        $self->info("停止接收消息失败: $@") if $@;
    }
    $self->logout();
    $self->login_state("relogin");
    $self->sess_sig_cache(Mojo::Webqq::Cache->new);
    $self->id_to_qq_cache(Mojo::Webqq::Cache->new);
    #$self->clear_cookie();
    $self->poll_failure_count(0);
    $self->send_failure_count(0);
    $self->qrcode_count(0);
    $self->csrf_token(undef);
    $self->model_ext(0);

    $self->user(+{});
    $self->friend([]);
    $self->group([]);
    $self->discuss([]);
    $self->model_status(+{});

    $self->login(delay=>0);
    $self->info("重新开始接收消息...");
    $self->_recv_message();
    $self->emit("relogin");
}
sub relink {
    my $self = shift;
    $self->info("尝试进行重新连接(1)...");
    if($self->_get_vfwebqq() && $self->_login2()){
        $self->info("重新连接(1)成功");
    }
    else{
        $self->info("重新连接(1)失败");
        $self->relogin();
    }
}
sub login {
    my $self = shift;
    return if $self->login_state eq 'success';
    my %p = @_;
    my $is_scan  = 0;
    my $delay = defined $p{delay}?$p{delay}:0;
    if($self->is_first_login == -1){
        $self->is_first_login(1);
    }
    elsif($self->is_first_login == 1){
        $self->is_first_login(0);
    }
    if($self->is_first_login){
        #$self->load_cookie(); #转移到new的时候就调用，这里不再需要
        my $ptwebqq = $self->search_cookie("ptwebqq");
        my $skey = $self->search_cookie("skey");
        $self->ptwebqq($ptwebqq) if defined $ptwebqq;
        $self->skey($skey) if defined $skey;
    }
    if(defined $self->ptwebqq and defined $self->skey){
        $self->info("检测到最近登录活动，尝试直接恢复登录...");
        if(not $self->_get_vfwebqq() && $self->_login2()){
            $self->relogin();
            return;
        }
        $is_scan = 0;
    } 
    elsif(
        $self->_prepare_for_login()    
        && $self->_check_verify_code()     
        && $self->_get_img_verify_code()
        && $self->_get_qrlogin_pic()

    ){
        while(1){
            my $ret = $self->_login1();
            if($ret == -1){#验证码输入错误
                $self->_get_img_verify_code();
                next;
            }
            elsif($ret == -2){#帐号或密码错误
                $self->error("登录失败，尝试更换加密算法计算方式，重新登录...");
                $self->encrypt_method("js");
                $self->relogin();
                return;
            }
            elsif($ret == -4 ){#等待二维码扫描
                sleep 3;
                next;
            }
            elsif($ret == -5 ){#二维码已经扫描 等待手机端进行授权登录
                sleep 3;
                next;
            }
            elsif($ret == -6){#二维码已经过期，重新下载二维码
                $self->emit("qrcode_expire");
                $self->_get_qrlogin_pic();
                next;
            }
            elsif($ret == 1){#登录成功
                $is_scan = 1;
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
        $self->fatal("登录失败，客户端退出（可能网络不稳定，请多尝试几次）");
        $self->stop();
    }
    else{
        $self->qrcode_count(0);
        $self->info("帐号(" .( $self->uid // $self->account) . ")登录成功");
        $self->login_type eq "qrlogin"?$self->clean_qrcode():$self->clean_verifycode();
        $self->state('updating');
        $self->update_user;
        $self->update_friend(is_blocking=>1,is_update_friend_ext=>1) if $self->is_init_friend;
        $self->update_group(is_blocking=>1,is_update_group_ext=>1,is_update_group_member_ext=>0,is_update_group_member=>0)  if $self->is_init_group;
        $self->update_discuss(is_blocking=>1,is_update_discuss_member=>0) if $self->is_init_discuss;
        $self->emit("login",$is_scan);
    }
    return $self;
}

sub mail{
    my $self  = shift;
    my $callback ;
    my $is_blocking = 1;
    if(ref $_[-1] eq "CODE"){
        $callback = pop;
        $is_blocking = 0;
    }
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
    eval{ require Mojo::SMTP::Client; } ;
    if($@){
        $self->error("发送邮件，请先安装模块 Mojo::SMTP::Client");
        return;
    }
    my %new = (
        address => $opt{smtp},
        port    => $opt{port} || 25,
        autodie => $is_blocking,
    ); 
    for(qw(tls tls_ca tls_cert tls_key)){
        $new{$_} = $opt{$_} if defined $opt{$_}; 
    }
    $new{tls} = 1 if($new{port} == 465 and !defined $new{tls});
    my $smtp = Mojo::SMTP::Client->new(%new);
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
        require MIME::Base64;
        my $charset = defined $opt{charset}?$opt{charset}:"UTF-8";
        push @data,"Subject: =?$charset?B?" . MIME::Base64::encode_base64($opt{subject},"") . "?=";
        if(defined $opt{text}){
            push @data,("Content-Type: text/plain; charset=$charset",'',$opt{text});
        }
        elsif(defined $opt{html}){
            push @data,("Content-Type: text/html; charset=$charset",'',$opt{html});
        }
        $data = join "\r\n",@data;
    }
    if(defined $callback){#non-blocking send
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
                    $callback->(0,$resp->error) if ref $callback eq "CODE"; 
                    return;
                }
                else{
                    $self->debug("邮件[ To: $opt{to}|Subject: $opt{subject} ]发送成功");
                    $callback->(1) if ref $callback eq "CODE";
                }
            },
        );
    }
    else{#blocking send
        eval{
            $smtp->send(
                auth    => {login=>$opt{user},password=>$opt{pass}},
                from    => $opt{from},
                to      => $opt{to},
                data    => $data,
                quit    => 1,
            );
        };
        return $@?(0,$@):(1,);
    }
    
}

sub spawn {
    my $self = shift;
    my %opt = @_;
    require Mojo::Webqq::Run;
    my $is_blocking = delete $opt{is_blocking};
    my $run = Mojo::Webqq::Run->new(ioloop=>($is_blocking?Mojo::IOLoop->new:$self->ioloop),log=>$self->log); 
    $run->max_forks(delete $opt{max_forks}) if defined $opt{max_forks};
    $run->spawn(%opt);
    $run->start if $is_blocking;
    $run;
}
sub clean_qrcode{
    my $self = shift;
    return if not defined $self->qrcode_path;
    return if not -f $self->qrcode_path;
    $self->info("清除残留的历史二维码图片");
    unlink $self->qrcode_path or $self->warn("删除二维码图片[ " . $self->qrcode_path . " ]失败: $!");
}
sub clean_verifycode{
    my $self = shift;
    return if not defined $self->verifycode_path;
    return if not -f $self->verifycode_path;
    $self->info("清除残留的历史验证码图片");
    unlink $self->verifycode_path or $self->warn("删除验证码图片[ ". $self->verifycode_path . " ]失败: $!");
}

sub add_job {
    my $self = shift;
    require Mojo::Webqq::Client::Cron;
    $self->Mojo::Webqq::Client::Cron::add_job(@_);
}

sub check_pid {
    my $self = shift;
    return if not $self->pid_path;
    eval{
        if(not -f $self->pid_path){
            $self->spurt($$,$self->pid_path);
        }
        else{
            my $pid = $self->slurp($self->pid_path);
            if( $pid=~/^\d+$/ and kill(0, $pid) ){
                $self->warn("检测到该账号有其他运行中的客户端(pid:$pid), 请先将其关闭");
                $self->stop();
            }
            else{
                $self->spurt($$,$self->pid_path);
            }
        }
    };
    $self->warn("进程检测遇到异常: $@") if $@;
    
}


sub clean_pid {
    my $self = shift;
    return if not defined $self->pid_path;
    return if not -f $self->pid_path;
    $self->info("清除残留的pid文件");
    unlink $self->pid_path or $self->warn("删除pid文件[ " . $self->pid_path . " ]失败: $!");
}

sub save_state{
    my $self = shift;
    my @attr = qw( 
        account 
        version 
        start_time
        mode
        http_debug 
        log_encoding 
        log_path 
        log_level 
        log_console
        disable_color
        tmpdir
        cookie_path
        qrcode_path
        pid_path
        state_path
        keep_cookie
        ua_retry_times
        qrcode_count_max
        state 
    );
    # pid
    # os
    eval{
        my $json = {plugin => []};
        for my $attr (@attr){
            $json->{$attr} = $self->$attr;
        }
        $json->{pid} = $$;
        $json->{os}  = $^O;
        for my $p (keys %{ $self->plugins }){
            push @{ $json->{plugin} } , { name=>$self->plugins->{$p}{name},priority=>$self->plugins->{$p}{priority},auto_call=>$self->plugins->{$p}{auto_call},call_on_load=>$self->plugins->{$p}{call_on_load} } ;
        }
        $self->spurt($self->to_json($json),$self->state_path);
    };
    $self->warn("客户端状态信息保存失败：$@") if $@;
}

sub is_load_plugin {
    my $self = shift;
    my $plugin = shift;
    return exists $self->plugins->{ substr($plugin,0,1) eq '+'?$plugin:"Mojo::Webqq::Plugin::$plugin" };
}
1;
