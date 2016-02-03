package Mojo::Webqq;
use strict;
$Mojo::Webqq::VERSION = "1.7.0";
use base qw(Mojo::Base);
use Mojo::Webqq::Log;
use Mojo::Webqq::Cache;
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
use Time::HiRes qw(gettimeofday);
use POSIX;
use File::Spec ();
use base qw(Mojo::EventEmitter Mojo::Webqq::Base Mojo::Webqq::Model Mojo::Webqq::Client Mojo::Webqq::Message Mojo::Webqq::Plugin);

has qq                  => undef;
has pwd                 => undef;
has security            => 0;
has state               => 'online';   #online|away|busy|silent|hidden|offline,
has type                => 'smartqq';  #smartqq
has login_type          => 'qrlogin';    #qrlogin|login
has ua_debug            => 0;
has log_level           => 'info';     #debug|info|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...
has email               => undef;
has encrypt_method      => "perl";     #perl|js

has tmpdir              => sub {File::Spec->tmpdir();};
has pic_dir             => sub {$_[0]->tmpdir};
has cookie_dir          => sub{return $_[0]->tmpdir;};
has verifycode_path     => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_verifycode_',$_[0]->qq,'.jpg'))};
has qrcode_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_qrcode_',$_[0]->qq,'.png'))};
has ioloop              => sub {Mojo::IOLoop->singleton};
has keep_cookie         => 1;
has max_recent          => 20;

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
has ua_retry_times          => 5;
has is_first_login          => -1;
has login_state             => "init";#init|relogin|success|scaning|confirming
has qrcode_count            => 0;
has qrcode_count_max        => 10;
has send_failure_count      => 0;
has send_failure_count_max  => 5;
has poll_failure_count      => 0;
has poll_failure_count_max  => 3;
has message_queue           => sub { $_[0]->gen_message_queue };
has ua                      => sub {
    require Mojo::UserAgent;
    #local $ENV{MOJO_USERAGENT_DEBUG} = $_[0]->ua_debug; 
    require Storable if $_[0]->keep_cookie;
    Mojo::UserAgent->new(
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
    while(@_){
        my($event,$callback) = (shift,shift);
        $self->SUPER::on($event,$callback);
    }
    return $self;
}

sub new {
    my $class = shift;
    my $self  = $class->Mojo::Base::new(@_);
    #$ENV{MOJO_USERAGENT_DEBUG} = $self->{ua_debug};
    if(not defined $self->{qq}){
        $self->fatal("客户端初始化缺少qq参数");
        $self->exit();
    }
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
    $self->on(send_message=>sub{
        my($self,$msg,$status)=@_;
        if($status->is_success){$self->send_failure_count(0);}
        elsif($status->code == -3){my $count = $self->send_failure_count;$self->send_failure_count(++$count);}
        if($self->send_failure_count >= $self->send_failure_count_max){
            $self->relogin();
        }
    });
    $self;
}

sub friends{
    my $self = shift;
    return @{$self->friend};
}
sub groups{
    my $self = shift;
    return @{$self->group};
}
sub discusss{
    my $self = shift;
    return @{$self->discuss};
}
sub recents{
    my $self = shift;
    return @{$self->recent};
}

1;
