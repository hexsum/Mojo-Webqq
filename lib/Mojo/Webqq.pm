package Mojo::Webqq;
use strict;
use Carp ();
$Mojo::Webqq::VERSION = "1.8.7";
use base qw(Mojo::Base);
use Mojo::Webqq::Log;
use Mojo::Webqq::Cache;
use Mojo::Webqq::Counter;
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
use Time::HiRes qw(gettimeofday);
use POSIX;
use File::Spec ();
use base qw(Mojo::EventEmitter Mojo::Webqq::Base Mojo::Webqq::Model Mojo::Webqq::Client Mojo::Webqq::Message Mojo::Webqq::Plugin Mojo::Webqq::Util);

has qq                  => undef;
has pwd                 => undef;
has security            => 0;
has state               => 'online';   #online|away|busy|silent|hidden|offline|callme,
has type                => 'smartqq';  #smartqq
has login_type          => 'qrlogin';    #qrlogin|login
has ua_debug            => 0;
has ua_debug_req_body   => sub{$_[0]->ua_debug};
has ua_debug_res_body   => sub{$_[0]->ua_debug};
has log_level           => 'info';     #debug|info|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...
has email               => undef;
has ignore_1202         => 1;           #对发送消息返回状态码1202是否认为发送失败

has is_init_friend         => 1;                            #是否在首次登录时初始化好友信息
has is_init_group          => 1;                            #是否在首次登录时初始化群组信息
has is_init_discuss        => 1;                            #是否在首次登录时初始化讨论组信息
has is_init_recent         => 0;                            #是否在首次登录时初始化最近联系人信息

has is_update_user          => 0;                            #是否定期更新个人信息
has is_update_group         => 1;                            #是否定期更新群组信息
has is_update_friend        => 1;                            #是否定期更新好友信息
has is_update_discuss       => 1;                            #是否定期更新讨论组信息
has update_interval         => 600;                          #定期更新的时间间隔

has encrypt_method      => "perl";     #perl|js
has tmpdir              => sub {File::Spec->tmpdir();};
has pic_dir             => sub {$_[0]->tmpdir};
has cookie_dir          => sub{return $_[0]->tmpdir;};
has verifycode_path     => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_verifycode_',$_[0]->qq || 'default','.jpg'))};
has qrcode_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_qrcode_',$_[0]->qq || 'default','.png'))};
has pid_path            => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_pid_',$_[0]->qq || 'default','.pid'))};
has ioloop              => sub {Mojo::IOLoop->singleton};
has keep_cookie         => 1;
has max_recent          => 20;
has msg_ttl             => 5;

has version => $Mojo::Webqq::VERSION;
has user    => sub {+{}};
has friend  => sub {[]};
has recent  => sub {[]};
has group   => sub {[]};
has discuss => sub {[]};

has data    => sub {+{}};
has plugins => sub{+{}};
has log    => sub{Mojo::Webqq::Log->new(encoding=>$_[0]->log_encoding,path=>$_[0]->log_path,level=>$_[0]->log_level,format=>sub{
    my ($time, $level, @lines) = @_;
    my $title = "";
    if(ref $lines[0] eq "HASH"){
        my $opt = shift @lines; 
        $time = $opt->{"time"} if defined $opt->{"time"};
        $title = $opt->{title} . " " if defined $opt->{"title"};
        $level  = $opt->{level} if defined $opt->{"level"};
    }
    @lines = split /\n/,join "",@lines;
    my $return = "";
    $time = $time?POSIX::strftime('[%y/%m/%d %H:%M:%S]',localtime($time)):"";
    $level = $level?"[$level]":"";
    for(@lines){
        $return .=
          $time
        . " " 
        . $level 
        . " " 
        . $title 
        . $_ 
        . "\n";
    }
    return $return;
})};

has sess_sig_cache => sub {Mojo::Webqq::Cache->new};
has id_to_qq_cache => sub {Mojo::Webqq::Cache->new};

has is_stop                 => 0;
has is_ready                => 0;
has is_polling              => 0;
has ua_retry_times          => 5;
has is_first_login          => -1;
has is_set_qq               => 0; #是否在初始化时设置qq参数
has login_state             => "init";#init|relogin|success|scaning|confirming
has qrcode_count            => 0;
has qrcode_count_max        => 10;
has send_failure_count      => 0;
has send_failure_count_max  => 5;
has poll_failure_count      => 0;
has poll_failure_count_max  => 3;
has poll_connection_id      => undef;
has message_queue           => sub { $_[0]->gen_message_queue };
has ua                      => sub {
    require Mojo::UserAgent;
    require Mojo::UserAgent::Proxy;
    #local $ENV{MOJO_USERAGENT_DEBUG} = $_[0]->ua_debug; 
    require Storable if $_[0]->keep_cookie;
    Mojo::UserAgent->new(
        proxy              => sub{ my $proxy = Mojo::UserAgent::Proxy->new;$proxy->detect;$proxy}->(),
        max_redirects      => 7,
        request_timeout    => 120,
        inactivity_timeout => 120,
        transactor => Mojo::UserAgent::Transactor->new( 
            name =>  'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062'
        ),
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
has g_pt_version           => 10137;
has rc                     => 1;
has csrf_token             => undef;
has model_ext              => 0;
#{user=>0,friend=>0,friend_ext=>0,group=>0,group_ext=>0,discuss=>0,recent=>0}
has model_status           => sub {+{}}; 

sub on {
    my $self = shift;
    my @return;
    while(@_){
        my($event,$callback) = (shift,shift);
        push @return,$self->SUPER::on($event,$callback);
    }
    return wantarray?@return:$return[0];
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
    #$ENV{MOJO_USERAGENT_DEBUG} = $self->{ua_debug};
    $self->info("当前正在使用 Mojo-Webqq v" . $self->version);
    if(not defined $self->{qq}){
        $self->warn("客户端初始化缺少qq参数，尝试自动检测");
        $self->is_set_qq(0);
    #    $self->fatal("客户端初始化缺少qq参数");
    #    $self->exit();
    }
    else{ $self->is_set_qq(1); }
    $self->ioloop->reactor->on(error=>sub{
        my ($reactor, $err) = @_;
        $self->error("reactor error: " . Carp::longmess($err));
    });
    $SIG{__WARN__} = sub{$self->warn(Carp::longmess @_);};
    $self->on(error=>sub{
        my ($self, $err) = @_;
        $self->error(Carp::longmess($err));
    });
    $self->check_pid();
    $SIG{INT} = $SIG{KILL} = $SIG{TERM} = sub{
        $self->clean_qrcode();
        $self->clean_pid();
        $self->stop();
    };
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
        my($self,$msg,$status)=@_;
        if($status->is_success){$self->send_failure_count(0);}
        elsif($status->code == -3){my $count = $self->send_failure_count;$self->send_failure_count(++$count);}
        if($self->send_failure_count >= $self->send_failure_count_max){
            $self->relogin();
        }
    });
    $self->on(send_message=>sub{
        my($self,$msg)=@_;
        return unless $msg->type =~/^message|sess_message$/;
        $self->add_recent($msg->receiver);
    });
    $self->on(receive_message=>sub{
        my($self,$msg)=@_;
        return unless $msg->type =~/^message|sess_message$/;
        my $sender_id = $msg->sender->id;
        $self->add_recent($msg->sender);
        unless(exists $self->data->{first_talk}{$sender_id}) {
            $self->data->{first_talk}{$sender_id}++;
            $self->emit(first_talk=>$msg->sender,$msg);
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
    $Mojo::Webqq::Client::CLIENT_COUNT++;
    $self;
}

sub friends{
    my $self = shift;
    $self->update_friend() if @{$self->friend} == 0;
    return @{$self->friend};
}
sub groups{
    my $self = shift;
    $self->update_group() if @{$self->group} == 0;
    return @{$self->group};
}
sub discusss{
    my $self = shift;
    $self->update_discuss() if @{$self->discuss} == 0;
    return @{$self->discuss};
}
sub recents{
    my $self = shift;
    return @{$self->recent};
}

1;
