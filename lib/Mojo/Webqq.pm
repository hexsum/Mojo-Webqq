package Mojo::Webqq;
use strict;
use Carp ();
$Mojo::Webqq::VERSION = "2.0.6";
use Mojo::Webqq::Base 'Mojo::EventEmitter';
use Mojo::Webqq::Log;
use Mojo::Webqq::Cache;
use Time::HiRes qw(gettimeofday);
use File::Spec ();
use base qw(Mojo::Webqq::Model Mojo::Webqq::Client Mojo::Webqq::Plugin Mojo::Webqq::Request Mojo::Webqq::Util);

has account             => sub{ $ENV{MOJO_WEBQQ_ACCUNT} || 'default'};
has start_time          => time;
has pwd                 => undef;
has security            => 0;
has mode                => 'online';   #online|away|busy|silent|hidden|offline|callme,
has type                => 'smartqq';  #smartqq
has login_type          => 'qrlogin';    #qrlogin|login
has http_debug          => sub{$ENV{MOJO_WEBQQ_HTTP_DEBUG} || 0 };
has ua_debug            => sub{$_[0]->http_debug};
has ua_debug_req_body   => sub{$_[0]->ua_debug};
has ua_debug_res_body   => sub{$_[0]->ua_debug};
has log_level           => 'info';     #debug|info|msg|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...
has log_head            => undef;
has log_unicode         => 0;
has log_console         => 1;
has check_account       => 0;           #是否检查预设账号与实际登录账号是否匹配
has disable_color       => 0;           #是否禁用终端打印颜色
has ignore_retcode      => sub{[0,1202,100100]}; #对发送消息返回这些状态码不认为发送失败，不重试

has is_init_friend         => 1;                            #是否在首次登录时初始化好友信息
has is_init_group          => 1;                            #是否在首次登录时初始化群组信息
has is_init_discuss        => 1;                            #是否在首次登录时初始化讨论组信息

has is_update_user          => 0;                            #是否定期更新个人信息
has is_update_group         => 1;                            #是否定期更新群组信息
has is_update_friend        => 1;                            #是否定期更新好友信息
has is_update_discuss       => 1;                            #是否定期更新讨论组信息
has update_interval         => 600;                          #定期更新的时间间隔

has encrypt_method      => "perl";     #perl|js
has tmpdir              => sub {$ENV{MOJO_WEIXIN_TMPDIR} || File::Spec->tmpdir();};
has pic_dir             => sub {$_[0]->tmpdir};
has cookie_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_cookie_',$_[0]->account || 'default','.dat'))};
has verifycode_path     => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_verifycode_',$_[0]->account || 'default','.jpg'))};
has qrcode_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_qrcode_',$_[0]->account || 'default','.png'))};
has pid_path            => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_pid_',$_[0]->account || 'default','.pid'))};
has state_path          => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_state_',$_[0]->account || 'default','.json'))};
has ioloop              => sub {Mojo::IOLoop->singleton};
has keep_cookie         => 1;
has msg_ttl             => 3;

has version => $Mojo::Webqq::VERSION;
has user    => sub {+{}};
has friend  => sub {[]};
has group   => sub {[]};
has discuss => sub {[]};

has plugins => sub{+{}};
has log    => sub{
    Mojo::Webqq::Log->new(
        encoding    =>  $_[0]->log_encoding,
        unicode_support => $_[0]->log_unicode,
        path        =>  $_[0]->log_path,
        level       =>  $_[0]->log_level,
        head        =>  $_[0]->log_head,
        disable_color   => $_[0]->disable_color,
        console_output  => $_[0]->log_console,
    )
};

has sess_sig_cache => sub {Mojo::Webqq::Cache->new};
has id_to_qq_cache => sub {Mojo::Webqq::Cache->new};

has is_stop                 => 0;
has is_ready                => 0;
has is_polling              => 0;
has ua_retry_times          => 5;
has is_first_login          => -1;
has login_state             => "init";#init|relogin|success|scaning|confirming
has qrcode_upload_url       => undef;
has qrcode_count            => 0;
has qrcode_count_max        => 10;
has send_failure_count      => 0;
has send_failure_count_max  => 5;
has poll_failure_count      => 0;
has poll_failure_count_max  => 3;
has poll_connection_id      => undef;
has message_queue           => sub { $_[0]->gen_message_queue };
has ua                      => sub {
    my $self = shift;
    require Mojo::UserAgent;
    require Mojo::UserAgent::Proxy;
    #local $ENV{MOJO_USERAGENT_DEBUG} = $_[0]->ua_debug; 
    require Storable if $self->keep_cookie;
    my $transactor = Mojo::UserAgent::Transactor->new(
        name =>  'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062'
    );
    my $default_form_generator = $transactor->generators->{form};
    $transactor->add_generator(form => sub{
        #my ($self, $tx, $form, %options) = @_;
        $self->reform($_[2],unicode=>1,recursive=>1,filter=>sub{
            my($type,$deep,$key) = @_;
            return 1 if $type ne 'HASH';
            return 1 if $deep == 0;
            return 0 if $deep == 1 and $key =~ /^filename|file|content$/;
            return 1;
        });
        $default_form_generator->(@_);
    });
    $transactor->add_generator(json=>sub{
        $_[1]->req->body($self->to_json($_[2]))->headers->content_type('application/json');
        return $_[1];
    });
    Mojo::UserAgent->new(
        proxy              => sub{ my $proxy = Mojo::UserAgent::Proxy->new;$proxy->detect;$proxy}->(),
        max_redirects      => 7,
        request_timeout    => 120,
        inactivity_timeout => 120,
        transactor => $transactor,
    );
};

has is_need_img_verifycode => 0;
has send_msg_id            => sub {
    my ( $second, $microsecond ) = gettimeofday;
    my $send_msg_id = $second * 1000 + $microsecond;
    $send_msg_id = ( $send_msg_id - $send_msg_id % 1000 ) / 1000;
    $send_msg_id = ( $send_msg_id % 10000 ) * 10000;
    $send_msg_id;
};
has uid                    => undef;
has clientid               => 53999199;
has psessionid             => undef;
has vfwebqq                => undef;
has ptwebqq                => undef;
has skey                   => undef;
has passwd_sig             => '';
has verifycode             => undef;
has pt_verifysession       => undef,
has ptvfsession            => undef;
has md5_salt               => undef;
has cap_cd                 => undef;
has isRandSalt             => 0;
has api_check_sig          => undef;
has g_login_sig            => undef;
has g_style                => 16;
has g_mibao_css            => 'm_webqq';
has g_daid                 => 164;
has g_appid                => 501004106;
has g_pt_version           => 10179;
has rc                     => 1;
has csrf_token             => undef;
has model_ext              => 0;
#{user=>0,friend=>0,friend_ext=>0,group=>0,group_ext=>0,discuss=>0}
has model_status           => sub {+{}}; 

sub state {
    my $self = shift;
    $self->{state} = 'init' if not defined $self->{state};
    if(@_ == 0){#get
        return $self->{state};
    }
    elsif($_[0] and $_[0] ne $self->{state}){#set
        my($old,$new) = ($self->{state},$_[0]);
        $self->{state} = $new;
        $self->emit(state_change=>$old,$new);
    }
    $self;
}
sub on {
    my $self = shift;
    my @return;
    while(@_){
        my($event,$callback) = (shift,shift);
        push @return,$self->SUPER::on($event,$callback);
    }
    return wantarray?@return:$return[0];
}
sub emit {
    my $self = shift;
    $self->SUPER::emit(@_);
    $self->SUPER::emit(all_event=>@_);
}
sub wait_once {
    my $self = shift;
    my($timeout,$timeout_callback,$event,$event_callback)=@_;
    my ($timer_id, $subscribe_id);
    $timer_id = $self->timer($timeout,sub{
        $self->unsubscribe($event,$subscribe_id);
        $timeout_callback->(@_) if ref $timeout_callback eq "CODE";
    });
    $subscribe_id = $self->once($event=>sub{
        $self->ioloop->remove($timer_id);
        $event_callback->(@_) if ref $event_callback eq "CODE";
    });
    $self;
}

sub wait {
    my $self = shift;
    my($timeout,$timeout_callback,$event,$event_callback)=@_;
    my ($timer_id, $subscribe_id);
    $timer_id = $self->timer($timeout,sub{
        $self->unsubscribe($event,$subscribe_id);
        $timeout_callback->(@_) if ref $timeout_callback eq "CODE";;
    });
    $subscribe_id = $self->on($event=>sub{
        my $ret = ref $event_callback eq "CODE"?$event_callback->(@_):0;
        if($ret){ $self->ioloop->remove($timer_id);$self->unsubscribe($event,$subscribe_id); }
    });
    $self;
}


sub new {
    my $class = shift;
    my $self  = $class->Mojo::Base::new(@_);
    for my $env(keys %ENV){
        if($env=~/^MOJO_WEBQQ_([A-Z_]+)$/){
            my $attr = lc $1;
            next if $attr =~ /^plugin_/;
            $self->$attr($ENV{$env}) if $self->can($attr);
        }
    }
    $self->info("当前正在使用 Mojo-Webqq v" . $self->version);
    $self->warn("当前版本与1.x.x版本不兼容，改动详情参见更新日志");
    $self->ioloop->reactor->on(error=>sub{
        my ($reactor, $err) = @_;
        $self->error("reactor error: " . Carp::longmess($err));
    });
    local $SIG{__WARN__} = sub{$self->warn(Carp::longmess @_);};
    $self->on(error=>sub{
        my ($self, $err) = @_;
        $self->error(Carp::longmess($err));
    });
    $self->check_pid();
    $self->load_cookie();
    $self->save_state();
    $SIG{CHLD} = 'IGNORE';
    $SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub{
        return if $^O ne 'MSWin32' and $_[0] eq 'INT' and !-t;
        $self->info("捕获到停止信号[$_[0]]，准备停止...");
        $self->stop();
    };
    $self->on(stop=>sub{
        my $self = shift;
        $self->clean_qrcode();
        $self->clean_pid();
    });
    $self->on(state_change=>sub{
        my $self = shift;
        $self->save_state();
    });
    $self->on(qrcode_expire=>sub{
        my($self) = @_;
        my $count = $self->qrcode_count;
        $self->qrcode_count(++$count);
        if($self->qrcode_count >= $self->qrcode_count_max){
            $self->stop();
        }
    });
    $self->on(model_update=>sub{
        my($self,$type,$status)=@_;
        $self->model_status->{$type} = $status;
        $self->emit("model_update_fail") if $self->get_model_status == 0;
    });
    $self->on(before_send_message=>sub{
        my($self,$msg) = @_;
        my $content = $msg->content;
        $content =~s/>/＞/g;
        $content =~s/</＜/g;
        $msg->content($content);
    });
    $self->on(send_message=>sub{
        my($self,$msg)=@_;
        if($msg->is_success){$self->send_failure_count(0);}
        elsif($msg->code == -3){my $count = $self->send_failure_count;$self->send_failure_count(++$count);}
        if($self->send_failure_count >= $self->send_failure_count_max){
            $self->relogin();
        }
    });
    $self->on(new_group=>sub{
        my($self,$group)=@_;
        $self->update_group($group,is_blocking=>1,is_update_group_ext=>1,is_update_group_member_ext=>1);
    });

    $self->on(new_group_member=>sub{
        my($self,$member)=@_;
        $member->group->update_group_member_ext(is_blocking=>1);
    });
    $self->on(new_friend=>sub{
        my($self,$friend)=@_;
        $self->update_friend_ext(is_blocking=>1);
    });
    $Mojo::Webqq::_CLIENT = $self;
    $self;
}

1;
