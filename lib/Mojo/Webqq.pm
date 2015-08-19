package Mojo::Webqq;
use strict;
$Mojo::Webqq::VERSION = "1.4.1";
use Mojo::Base;
use Mojo::Webqq::Log;
use Mojo::Webqq::Cache;
use base qw(Mojo::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
use Time::HiRes qw(gettimeofday);
use POSIX;
use Encode::Locale;
use base qw(Mojo::Webqq::Model Mojo::Webqq::Client Mojo::Webqq::Message Mojo::Webqq::Plugin);

has security                => 0;
has state                   => 'online';   #online|away|busy|silent|hidden|offline,
has type                    => 'smartqq';  #smartqq
has ua_debug                => 0;
has log_level               => 'info';     #debug|info|warn|error|fatal
has log_path                => undef;
has email                   => undef;
has encrypt_method          => "perl";     #perl|js

has version                 => $Mojo::Webqq::VERSION;

has user    => sub {+{}};
has friend  => sub {[]};
has recent  => sub {[]};
has group   => sub {[]};
has discuss => sub {[]};

has data    => sub {+{}};
has plugins => sub{+{}};
has log    => sub{Mojo::Webqq::Log->new(path=>$_[0]->log_path,level=>$_[0]->log_level,format=>sub{
    my ($time, $level, @lines) = @_;
    my $title;
    if(ref $lines[0] eq "HASH"){
        my $opt = shift @lines; 
        $time = $opt->{"time"} if defined $opt->{"time"};
        $title = $opt->{title} . " " if defined $opt->{"title"};
        $level  = $opt->{level} if defined $opt->{"level"};
    }
    #$level .= " " if ($level eq "info" or $level eq "warn");
    @lines = split /\n/,join "",@lines;
    my $return;
    my $time = POSIX::strftime('[%y/%m/%d %H:%M:%S]',localtime($time));
    for(@lines){
        $return .=
            $time
        .   " " 
        .   "[$level]" 
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
has ua_retry_times          => 5;
has is_first_login          => -1;
has login_state             => "init";
has poll_failure_count      => 0;
has poll_failure_count_max  => 3;
has model_update_failure_count      => 0;
has model_update_failure_count_max  => 3;
has message_queue           => sub { $_[0]->gen_message_queue };
has ua                      => sub {
    local $ENV{MOJO_USERAGENT_DEBUG} = $_[0]->ua_debug;
    require Mojo::UserAgent;
    Mojo::UserAgent->new(
        request_timeout    => 30,
        inactivity_timeout => 30,
        transactor => Mojo::UserAgent::Transactor->new( 
            name =>  'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062'
        ),
    );
};

has qq                     => undef;
has pwd                    => undef;
has is_need_img_verifycode => 0;
has img_verifycode_source  => 'TTY';             #NONE|TTY|CALLBACK
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
has passwd_sig             => '';
has verifycode             => undef;
has pt_verifysession       => undef,
has ptvfsession            => undef;
has md5_salt               => undef;
has cap_cd                 => undef;
has isRandSalt             => 0;
has api_check_sig          => undef;
has g_login_sig            => undef;
has g_style                => 5;
has g_mibao_css            => 'm_webqq';
has g_daid                 => 164;
has g_appid                => 1003903;
has g_pt_version           => 10092;
has rc                     => 1;

sub on {
    my $self = shift;
    while(@_){
        my($event,$callback) = (shift,shift);
        $self->SUPER::on($event,$callback);
    }
    return $self;
}

1;
