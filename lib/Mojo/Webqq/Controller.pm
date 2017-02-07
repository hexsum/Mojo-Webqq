package Mojo::Webqq::Controller;
use strict;
use Config;
use File::Spec;
use Mojo::Webqq::Base 'Mojo::EventEmitter';
use Mojo::Webqq;
use Mojo::Webqq::Server;
use Mojo::Webqq::Log;
use Mojo::UserAgent;
use Mojo::IOLoop;
use IO::Socket::IP;
use Time::HiRes ();
use Storable qw();
use POSIX qw();
use File::Spec ();
use if $^O eq "MSWin32",'Win32::Process';
use if $^O eq "MSWin32",'Win32';
use base qw(Mojo::Webqq::Util Mojo::Webqq::Request);
our $VERSION = $Mojo::Webqq::VERSION;

has backend => sub{+{}};
has ioloop  => sub {Mojo::IOLoop->singleton};
has backend_start_port => 5000;
has post_api => undef;
has poll_api => undef;
has poll_interval => 5;
has auth     => undef;
has server =>  sub { Mojo::Webqq::Server->new };
has listen => sub { [{host=>"0.0.0.0",port=>4000},] };

has http_debug          => sub{$ENV{MOJO_WEBQQ_CONTROLLER_HTTP_DEBUG} || 0 } ;
has ua_debug            => sub{$_[0]->http_debug};
has ua_debug_req_body   => sub{$_[0]->ua_debug};
has ua_debug_res_body   => sub{$_[0]->ua_debug};
has ua_debug_req_body   => sub{$_[0]->ua_debug};
has ua_debug_res_body   => sub{$_[0]->ua_debug};
has ua_retry_times          => 5;
has ua_connect_timeout      => 10;
has ua_request_timeout      => 120;
has ua_inactivity_timeout   => 120;
has ua  => sub {
    Mojo::UserAgent->new(
        connect_timeout=>$_[0]->ua_connect_timeout,
        request_timeout=>$_[0]->ua_request_timeout,
        inactivity_timeout=>$_[0]->ua_inactivity_timeout,
    )
};

has tmpdir              => sub {File::Spec->tmpdir();};
has keep_cookie         => 0;
has cookie_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_controller_cookie','.dat'))};
has pid_path            => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_controller_process','.pid'))};
has backend_path        => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_controller_backend','.dat'))};
has template_path        => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_webqq_controller_template','.pl'))};
has check_interval      => 5;

has log_level           => 'info';     #debug|info|msg|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...
has log_head            => "[wqc][$$]";
has log_console         => 1;
has disable_color       => 0;

has version             => sub{$Mojo::Webqq::Controller::VERSION};

has log     => sub{
    Mojo::Webqq::Log->new(
        encoding    =>  $_[0]->log_encoding,
        path        =>  $_[0]->log_path,
        level       =>  $_[0]->log_level,
        head        =>  $_[0]->log_head,
        disable_color   => $_[0]->disable_color,
        console_output  => $_[0]->log_console,
    )
};
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->info("当前正在使用 Mojo-Webqq-Controller v" . $self->version);
    $self->ioloop->reactor->on(error=>sub{
        my ($reactor, $err) = @_;
        $self->error("reactor error: " . Carp::longmess($err));
    });
    $SIG{__WARN__} = sub{$self->warn(Carp::longmess @_);};
    $self->on(error=>sub{
        my ($self, $err) = @_;
        $self->error(Carp::longmess($err));
    });
    if( $^O!~/^MSWin32/i and $Config{d_pseudofork}){
        $self->fatal("非常抱歉, Mojo-Webqq-Controller不支持您当前使用的系统");
        $self->stop();
    } 
    $self->check_pid();
    $self->load_backend(); 
    $self->check_client();
    $SIG{CHLD} =  'IGNORE';
    $SIG{INT} = $SIG{KILL} = $SIG{TERM} = $SIG{HUP} = sub{
        $self->info("捕获到停止信号[$_[0]]，准备停止...");
        $self->info("正在停止Controller...");
        $self->save_backend();
        $self->clean_pid();
        $self->stop();
    };
    eval{$0 = 'wqcontroller';} if $^O ne 'MSWin32';
    if(defined $self->poll_api){
        $self->on('_mojo_webqq_controller_poll_over' => sub{
            $self->http_get($self->poll_api,sub{
                $self->ioloop->timer($self->poll_interval || 5,sub {$self->emit('_mojo_webqq_controller_poll_over');});
            });
        });
    } 
    $Mojo::Webqq::Controller::_CONTROLLER = $self;
    $self;
}
sub stop{
    my $self = shift;
    $self->info("Controller停止运行");
    CORE::exit();
}

sub save_backend{
    my $self = shift;
    my $backend_path = $self->backend_path;
    eval{Storable::nstore($self->backend,$backend_path);};
    $self->warn("Controller保存backend失败: $@") if $@;

}
sub load_backend {
    my $self = shift;
    my $backend_path = $self->backend_path;
    return if not -f $backend_path;
    eval{$self->backend(Storable::retrieve($backend_path))};
    if($@){
        $self->warn("Controller加载backend失败: $@");
        return;
    }
    else{
        $self->info("Controller加载backend[ $backend_path ]");
    }
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
                $self->warn("检测到有其他运行中的Controller(pid:$pid), 请先将其关闭");
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
    $self->info("清除残留的Controller pid文件");
    unlink $self->pid_path or $self->warn("删除pid文件[ " . $self->pid_path . " ]失败: $!");
}

sub kill_process {
    my $self = shift;
    if(!$_[0] or $_[0]!~/^\d+$/){
        $self->error("pid无效，无法终止进程");
        return;
    }
    #if($^O  eq "MSWin32"){
    #    my $exitcode = 0;
    #    Win32::Process::KillProcess($_[0],$exitcode);
    #    return $exitcode;
    #}
    #else{ 
        kill POSIX::SIGINT,$_[0] ;
    #}
}
sub check_process {
    my $self = shift;
    if(!$_[0] or $_[0]!~/^\d+$/){
        $self->error("pid无效，无法检测进程");
        return;
    }
    #if($^O  eq "MSWin32"){
    #    my $p;
    #    return Win32::Process::Open($p,$_[0],0);
    #}
    kill 0,$_[0];
}
sub start_client {
    my $self = shift;
    my $param = shift;
    if(!$param->{client}){
        return {code => 1, status=>'client not found',};
    }
    elsif(exists $self->backend->{$param->{client}}){
        if( $self->check_process($self->backend->{$param->{client}}{pid}) ){
            my %client = %{ $self->backend->{$param->{client}} };
            for(keys %client){ delete $client{$_} if substr($_,0,1) eq "_"};
            return {code=>0, status=>'client already exists',%client};
        }
    }
    my $backend_port = empty_port({host=>'127.0.0.1',port=>$self->backend_start_port,proto=>'tcp'});
    return {code => 2, status=>'no available port',client=>$param->{client}} if not defined $backend_port;
    my $post_api = $param->{post_api} || $self->post_api;
    my $poll_api = $param->{poll_api};
    if(defined $post_api){
        my $url = Mojo::URL->new($post_api);
        $url->query->merge(client=>$param->{client});
        $post_api =  $url->to_string;
    }
    if(defined $poll_api){
        my $url = Mojo::URL->new($poll_api);
        $url->query->merge(client=>$param->{client});
        $poll_api =  $url->to_string;
    }
    $param->{account} = $param->{client};

    for my $env(keys %ENV){
        delete $ENV{$env} if $env=~/^MOJO_WEBQQ_([A-Z_]+)$/;
    }
    for my $p (keys %$param){
        my $env_key = "MOJO_WEBQQ_" . uc($p);
        $ENV{$env_key} = $param->{$p};
    }
    $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT} = $backend_port;
    $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API} = $post_api;
    $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POLL_API} = $poll_api;

    $ENV{MOJO_WEBQQ_LOG_PATH} = $self->log_path;
    $ENV{MOJO_WEBQQ_LOG_ENCODING} = $self->log_encoding;
    $ENV{MOJO_WEBQQ_LOG_CONSOLE} = $self->log_console;
    $ENV{MOJO_WEBQQ_DISABLE_COLOR} = $self->disable_color;
    $ENV{MOJO_WEBQQ_HTTP_DEBUG} = $self->http_debug;
    $ENV{MOJO_WEBQQ_LOG_LEVEL} = $self->log_level;

    $ENV{MOJO_WEBQQ_TMPDIR} = $self->tmpdir if not defined $ENV{MOJO_WEBQQ_TMPDIR};
    $ENV{MOJO_WEBQQ_STATE_PATH} = File::Spec->catfile($ENV{MOJO_WEBQQ_TMPDIR},join('','mojo_webqq_state_',$ENV{MOJO_WEBQQ_ACCOUNT},'.json')) if not defined $ENV{MOJO_WEBQQ_STATE_PATH};
    $ENV{MOJO_WEBQQ_QRCODE_PATH} = File::Spec->catfile($ENV{MOJO_WEBQQ_TMPDIR},join('','mojo_webqq_qrcode_',$ENV{MOJO_WEBQQ_ACCOUNT},'.jpg')) if not defined $ENV{MOJO_WEBQQ_QRCODE_PATH};
    $ENV{MOJO_WEBQQ_PID_PATH} = File::Spec->catfile($ENV{MOJO_WEBQQ_TMPDIR},join('','mojo_webqq_pid_',$ENV{MOJO_WEBQQ_ACCOUNT},'.pid')) if not defined $ENV{MOJO_WEBQQ_PID_PATH};
    local $ENV{PERL5LIB} = join( ($^O eq "MSWin32"?";":":"),@INC);
    if(!-f $self->template_path or -z $self->template_path){
        my $template =<<'MOJO_WEBQQ_CLIENT_TEMPLATE';
#!/usr/bin/env perl
use Mojo::Webqq;
my $client = Mojo::Webqq->new(log_head=>"[$ENV{MOJO_WEBQQ_ACCOUNT}][$$]");
$0 = "wqclient(" . $client->account . ")" if $^O ne "MSWin32";
$SIG{INT} = 'IGNORE' if ($^O ne 'MSWin32' and !-t);
$client->load(["ShowMsg","UploadQRcode"]);
$client->load("Openqq",data=>{listen=>[{host=>"127.0.0.1",port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT} }], post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API} || undef,post_event=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_EVENT} // 1,post_media_data=> $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_MEDIA_DATA} // 1, poll_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POLL_API} || undef, poll_interval => $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POLL_INTERVAL} },call_on_load=>1);
$client->run();
MOJO_WEBQQ_CLIENT_TEMPLATE
        $self->spurt($template,$self->template_path);
    }
    $self->info("使用模版[" . $self->template_path .  "]创建客户端");
    if( $^O eq 'MSWin32'){#Windows
        my $process;
        no strict;
        my $p = $self->decode("gbk",$Config{perlpath});
        if($p=~/\p{Han}|\s+/){
            $self->warn("perl路径包含空格或中文可能导致客户端创建失败: [" . $self->encode("utf8",$p) . "]");
        }
        if(Win32::Process::Create($process,$Config{perlpath},'perl ' . $self->template_path,0,CREATE_NEW_PROCESS_GROUP,".") ){
            
            my $pid;eval{$pid = $process->GetProcessID()};
            if($pid!~/^\d+$/){
                return {code=>4,status=>'client pid not ok' };
            }
            $self->backend->{$param->{client}} = $param;
            $self->backend->{$param->{client}}{pid} = $pid;
            $self->backend->{$param->{client}}{port} = $backend_port;
            $self->backend->{$param->{client}}{_tmpdir} = $ENV{MOJO_WEBQQ_TMPDIR};
            $self->backend->{$param->{client}}{_state_path} = $ENV{MOJO_WEBQQ_STATE_PATH};
            $self->backend->{$param->{client}}{_pid_path} = $ENV{MOJO_WEBQQ_PID_PATH};
            $self->backend->{$param->{client}}{_qrcode_path} = $ENV{MOJO_WEBQQ_QRCODE_PATH};
            delete $self->backend->{$param->{client}}{log_head};
            my %client = %{ $self->backend->{$param->{client}} };
            for(keys %client){ delete $client{$_} if substr($_,0,1) eq "_"}
            return {code=>0,status=>'success',%client };    
        }
        else{
            $self->error(
                "创建客户端失败: " . 
                $self->encode("utf8",
                    $self->decode("gbk",Win32::FormatMessage( Win32::GetLastError() ) || 'create client fail' ) 
                ) 
            );
            #$self->error(Win32::FormatMessage( Win32::GetLastError() ) );
            return {code=>3,status=>'failure',};
        }
    }
    else{#Unix 
        my $pid = fork();
        if($pid == 0) {#new process
            $self->server->stop;
            $self->ioloop->stop;
            delete $self->server->{servers};
            my $template_path = $self->template_path;
            undef $self;
            exec $Config{perlpath} || 'perl',$template_path;
        }
        else{
            select undef,undef,undef,0.05;
            if($pid!~/^\d+$/){
                return {code=>4,status=>'client pid not ok' };
            }
            $self->backend->{$param->{client}} = $param;
            $self->backend->{$param->{client}}{pid} = $pid;
            $self->backend->{$param->{client}}{port} = $backend_port;
            $self->backend->{$param->{client}}{_tmpdir} = $ENV{MOJO_WEBQQ_TMPDIR};
            $self->backend->{$param->{client}}{_state_path} = $ENV{MOJO_WEBQQ_STATE_PATH};
            $self->backend->{$param->{client}}{_pid_path} = $ENV{MOJO_WEBQQ_PID_PATH};
            $self->backend->{$param->{client}}{_qrcode_path} = $ENV{MOJO_WEBQQ_QRCODE_PATH};
            delete $self->backend->{$param->{client}}{log_head};
            my %client = %{ $self->backend->{$param->{client}} };
            for(keys %client){ delete $client{$_} if substr($_,0,1) eq "_"}
            return {code=>0,status=>'success',%client };
        }
    }
}

sub stop_client {
    my $self = shift;
    my $param = shift;
    if(!$param->{client}){
        return {code => 1, status=>'client not found',};
    }
    elsif(!exists $self->backend->{$param->{client}}){
        return {code => 1, status=>'client not exists',};
    }
    my $ret = $self->kill_process( $self->backend->{$param->{client}}{pid} );
    if ($ret){
        my $client = $self->backend->{$param->{client}};
        delete $self->backend->{$param->{client}};
        for(keys %$client){ delete $client->{$_} if substr($_,0,1) eq "_"}
        return {code=>0,status=>'success',%$client };
    }
    return {code=>1,status=>'failure'};
}

sub check_client {
    my $self = shift;
    for my $client ( keys %{ $self->backend }  ){
        my $pid = $self->backend->{$client}->{pid};
        return if !$pid;
        return if $pid !~ /^\d+$/;
        my $ret = $self->check_process($pid);
        if(not $ret){
            $self->warn("检测到客户端 $client\[$pid\] 不存在，删除客户端信息");
            delete $self->backend->{$client};
        }
    }
}
sub run {
    my $self = shift;
    my $server =  $self->server;
    $server->app($server->build_app("Mojo::Webqq::Controller::App"));
    $server->app->defaults(wqc=>$self);
    $server->app->secrets("hello world");
    $server->app->log($self->log);
    $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:2000)} @{ $self->listen } ]) ;
    $server->start;
    $self->ioloop->recurring($self->check_interval || 5,sub{
        $self->check_client();
        $self->save_backend();
    });
    $self->emit('_mojo_webqq_controller_poll_over');
    $self->ioloop->start if not $self->ioloop->is_running;
}

package Mojo::Webqq::Controller::App::Controller;
use Mojo::JSON ();
use Mojo::Util ();
use base qw(Mojolicious::Controller);
sub render{
    my $self = shift;
    if($_[0] eq 'json'){
        $self->res->headers->content_type('application/json');
        $self->SUPER::render(data=>Mojo::JSON::to_json($_[1]),@_[2..$#_]);
    }
    else{$self->SUPER::render(@_)}
}
sub safe_render{
    my $self = shift;
    $self->render(@_) if (defined $self->tx and !$self->tx->is_finished);
}
sub param{
    my $self = shift;
    my $data = $self->SUPER::param(@_);
    defined $data?Mojo::Util::encode("utf8",$data):undef;
}
sub params {
    my $self = shift;
    my $hash = $self->req->params->to_hash ;
    $self->stash('wqc')->reform($hash);
    return $hash;
}
package Mojo::Webqq::Controller::App;
use Mojolicious::Lite;
use Mojo::Transaction::HTTP;
no utf8;
app->controller_class('Mojo::Webqq::Controller::App::Controller');
under sub {
    my $c = shift;
    if(ref $c->stash('wqc')->auth eq "CODE"){
        my $hash  = $c->params;
        my $ret = 0;
        eval{
            $ret = $c->stash('wqc')->auth->($hash,$c);
        };
        $c->stash('wqc')->warn("插件[Mojo::Webqq::Controller]认证回调执行错误: $@") if $@;
        $c->safe_render(text=>"auth failure",status=>403) if not $ret;
        return $ret;
    }
    else{return 1}
};
get '/openqq/start_client' => sub{
    my $c = shift;
    my $hash   = $c->params;
    my $result =  $c->stash('wqc')->start_client($hash);
    $c->safe_render(json=>$result);
};
get '/openqq/stop_client' => sub{
    my $c = shift;
    my $hash   = $c->params;
    my $result = $c->stash('wqc')->stop_client($hash);
    $c->safe_render(json=>$result);
};
get '/openqq/get_qrcode' => sub{
    my $c = shift;
    my $client = $c->param("client");
    if(!$client){
        $c->safe_render(json=>{code => 1, status=>'client not found',});
        return;
    }
    elsif(!exists $c->stash('wqc')->backend->{$client}){
        $c->safe_render(json => {code => 1, status=>'client not exists',});
        return;
    }
    eval{
        my $qrcode_path = $c->stash('wqc')->backend->{$client}{_qrcode_path};
        my $data = $c->stash('wqc')->slurp($qrcode_path);
        $c->res->headers->cache_control('no-cache');
        $c->res->headers->content_type('image/png');
        $c->safe_render(data=>$data,);
    };
    if($@){
        $c->stash('wqc')->warn("读取客户端二维码失败: $@");
        $c->safe_render(text=>"",status=>404);
    }
};
get '/openqq/check_client' => sub{
    my $c = shift;
    my $client = $c->param("client");
    if(defined $client){
        if(!exists $c->stash('wqc')->backend->{$client}){
            $c->safe_render(json => {code => 1, status=>'client not exists',});
            return;
        }
        else{
            eval{
                my $state_path = $c->stash('wqc')->backend->{$client}{_state_path};
                my $json = $c->stash('wqc')->decode_json($c->stash('wqc')->slurp($state_path));
                $json->{port} = $c->stash('wqc')->backend->{$client}{port};
                $c->safe_render(json=>{code=>0,client=>[$json]});
            };
            if($@){
                $c->stash('wqc')->warn("读取客户端state文件失败: $@");
                #$c->safe_render(json=>{code=>0,client=>[ $c->stash('wqc')->backend->{$client}, ] });
                $c->safe_render(json=>{code => 1,status=>"client state file read error"});
            }
        }
    }
    else{
        eval{
            my @client;
            for my $client ( values %{ $c->stash('wqc')->backend }){
                my $state_path = $client->{_state_path};
                my $json = $c->stash('wqc')->from_json($c->stash('wqc')->slurp($state_path));
                $json->{port} = $client->{port};
                push @client,$json;
            }
            $c->safe_render(json=>{code=>0,client=>\@client});
        };
        if($@){
            $c->stash('wqc')->warn("读取客户端state文件失败: $@");
            #$c->safe_render(json=>{code=>0,client=>[ values %{ $c->stash('wqc')->backend } ]});    
            $c->safe_render(json=>{code => 1,status=>"client state file read error"});
        }
    }
};
any '/openqq/*whatever'  => sub{
    my $c = shift;
    my $client = $c->param("client");
    if(!$client){
        $c->safe_render(json=>{code => 1, status=>'client not found',});
        return;
    }
    elsif(!exists $c->stash('wqc')->backend->{$client}){
        $c->safe_render(json => {code => 1, status=>'client not exists',});
        return;
    }
    $c->inactivity_timeout(120);
    $c->render_later;
    my $tx = Mojo::Transaction::HTTP->new(req=>$c->req->clone);
    $tx->req->url->host("127.0.0.1");
    $tx->req->url->port($c->stash('wqc')->backend->{$client}->{port});
    $tx->req->url->scheme('http');
    $tx->req->headers->header('Host',$tx->req->url->host_port);
    return if $c->stash('mojo.finished');
    $c->stash('wqc')->ua->start($tx,sub{
        my ($ua,$tx) = @_;
        $c->tx->res($tx->res);
        $c->rendered;
    });
};
any '/*whatever'  => sub{whatever=>'',$_[0]->safe_render(json=>{code=>-1,status=>"api not found"},status=>403)};
package Mojo::Webqq::Controller;

sub can_bind {
    my ($host, $port, $proto) = @_;
    # The following must be split across two statements, due to
    # https://rt.perl.org/Public/Bug/Display.html?id=124248
    my $s = _listen_socket($host, $port, $proto);
    return defined $s;
}
 
sub _listen_socket {
    my ($host, $port, $proto) = @_;
    $port  ||= 0;
    $proto ||= 'tcp';
    IO::Socket::IP->new(
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => $host,
        LocalPort => $port,
        Proto     => $proto,
        V6Only    => 1,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    );
}
 
sub listen_socket {
    my ($host, $proto) = @{$_[0]}{qw(host proto)};
    $host = '127.0.0.1' unless defined $host;
    return _listen_socket($host, undef, $proto);
}
 
# get a empty port on 49152 .. 65535
# http://www.iana.org/assignments/port-numbers
sub empty_port {
    my ($host, $port, $proto) = @_ && ref $_[0] eq 'HASH' ? ($_[0]->{host}, $_[0]->{port}, $_[0]->{proto}) : (undef, @_);
    $host = '127.0.0.1'
        unless defined $host;
    if (defined $port) {
        $port = 49152 unless $port =~ /^[0-9]+$/ && $port < 49152;
    } else {
        $port = 50000 + (int(rand()*1500) + abs($$)) % 1500;
    }
    $proto = $proto ? lc($proto) : 'tcp';
 
    $port--;
    while ( $port++ < 65000 ) {
        # Remote checks don't work on UDP, and Local checks would be redundant here...
        next if ($proto eq 'tcp' && check_port({ host => $host, port => $port }));
        return $port if can_bind($host, $port, $proto);
    }
    return;
}
 
sub check_port {
    my ($host, $port, $proto) = @_ && ref $_[0] eq 'HASH' ? ($_[0]->{host}, $_[0]->{port}, $_[0]->{proto}) : (undef, @_);
    $host = '127.0.0.1'
        unless defined $host;
    $proto = $proto ? lc($proto) : 'tcp';
 
    # for TCP, we do a remote port check
    # for UDP, we do a local port check, like empty_port does
    my $sock = ($proto eq 'tcp') ?
        IO::Socket::IP->new(
            Proto    => 'tcp',
            PeerAddr => $host,
            PeerPort => $port,
            V6Only   => 1,
        ) :
        IO::Socket::IP->new(
            Proto     => $proto,
            LocalAddr => $host,
            LocalPort => $port,
            V6Only   => 1,
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        )
    ;
 
    if ($sock) {
        close $sock;
        return 1; # The port is used.
    }
    else {
        return 0; # The port is not used.
    }
 
}
1;
