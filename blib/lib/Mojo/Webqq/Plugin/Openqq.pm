use strict;
use Mojo::Webqq::Server;
package Mojo::Webqq::Plugin::Openqq;
$Mojo::Webqq::Plugin::Openqq::PRIORITY = 98;
my $server;
sub call{
    my $client = shift;
    my $data   =  shift;
    my $post_api = $data->{post_api} if ref $data eq "HASH";

    if(defined $post_api){
        $client->on(receive_message=>sub{
            my($client,$msg) = @_;
            return if $msg->type !~ /^friend_message|group_message|discuss_message|sess_message$/;
            $client->http_post($post_api,json=>$msg->to_json_hash,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]接收消息[".$msg->id."]上报成功");
                    if($tx->res->headers->content_type =~m#text/json|application/json#){
                        #文本类的返回结果必须是json字符串
                        my $json;
                        eval{$json = $client->from_json($tx->res->body)};
                        if($@){$client->warn($@);return}
                        if(defined $json){
                            #{code=>0,reply=>"回复的消息",format=>"text"}
                            if((!defined $json->{format}) or (defined $json->{format} and $json->{format} eq "text")){
                                $msg->reply($json->{reply}) if defined $json->{reply}; 
                            } 
                            if($msg->type eq "group_message" and defined $json->{shutup} and $json->{shutup} == 1){
                                $msg->sender->shutup($json->{shutup_time} || 60);
                            }
                        }
                    }
                    #elsif($tx->res->headers->content_type =~ m#image/#){
                    #    #发送图片，暂未实现 
                    #}
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]接收消息[".$msg->id."]上报失败: ". $client->encode_utf8($tx->error->{message})); 
                }
            });
        });
    }

    package Mojo::Webqq::Plugin::Openqq::App::Controller;
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
        $client->reform($hash);
        return $hash;
    }
    package Mojo::Webqq::Plugin::Openqq::App;
    use Encode ();
    use Mojolicious::Lite;
    app->controller_class('Mojo::Webqq::Plugin::Openqq::App::Controller');
    under sub {
        my $c = shift;
        if(ref $data eq "HASH" and ref $data->{auth} eq "CODE"){
            my $hash  = $c->req->params->to_hash;
            $client->reform($hash);
            my $ret = 0;
            eval{
                $ret = $data->{auth}->($hash,$c);
            };
            $client->warn("插件[Mojo::Webqq::Plugin::Openqq]认证回调执行错误: $@") if $@;
            $c->safe_render(text=>"auth failure",status=>403) if not $ret;
            return $ret;
        }
        else{return 1} 
    };
    get '/openqq/get_user_info'     => sub {$_[0]->safe_render(json=>$client->user->to_json_hash());};
    get '/openqq/get_friend_info'   => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->friend}]); };
    get '/openqq/get_group_info'    => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->group}]); };
    get '/openqq/get_group_basic_info'    => sub {$_[0]->safe_render(json=>[map {delete $_->{member};$_} map {$_->to_json_hash()} @{$client->group}]); };
    get '/openqq/get_discuss_info'  => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->discuss}]); };
    get '/openqq/get_recent_info'   => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->recent}]);};
    any [qw(GET POST)] => '/openqq/send_friend_message'         => sub{
        my $c = shift;
        my $p = $c->params;
        my $friend = $client->search_friend(id=>$p->{id},uid=>$p->{uid});
        if(defined $friend){
            $c->render_later;
            $client->send_friend_message($friend,$p->{content},sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg)=@_;
                    $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->msg});  
                });
                $msg->from("api");
            });
        }
        else{$c->safe_render(json=>{id=>undef,code=>100,status=>"friend not found"});}
    };
    any [qw(GET POST)] => 'openqq/send_group_message'    => sub{
        my $c = shift;
        my $p = $c->params;
        my $group = $client->search_group(id=>$p->{id},uid=>$p->{uid},);
        if(defined $group){
            $c->render_later;
            $client->send_group_message($group,$p->{content},sub{
                my $msg = $_[1];
                $msg->cb(sub{
                    my($client,$msg)=@_;
                    $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->msg});
                });
                $msg->from("api");
            });
        }
        else{$c->safe_render(json=>{id=>undef,code=>101,status=>"group not found"});}
    };
    any [qw(GET POST)] => 'openqq/send_discuss_message'  => sub{
        my $c = shift;
        my $p = $c->params;
        my $discuss = $client->search_discuss(id=>$p->{id});
        if(defined $discuss){
            $c->render_later;
            $client->send_discuss_message($discuss,$p->{content},sub{
                my $msg = $_[1];
                $msg->cb(sub{
                    my($client,$msg)=@_;
                    $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->msg});
                });
                $msg->from("api");
            });
        }
        else{$c->safe_render(json=>{id=>undef,code=>102,status=>"discuss not found"});}
    };
    any [qw(GET POST)] => '/openqq/send_sess_message'    => sub{
        my $c = shift;
        my $p = $c->params;
        if(defined $p->{group_id} or defined $p->{group_uid}){
            my $group = $client->search_group(id=>$p->{group_id},uid=>$p->{group_uid});
            my $member = defined $group?$group->search_group_member(uid=>$p->{uid},id=>$p->{id}):undef;
            if(defined $member){
                $c->render_later;
                $client->send_sess_message($member,$p->{content},sub{
                    my $msg = $_[1];
                    $msg->cb(sub{
                        my($client,$msg)=@_;
                        $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->msg});
                    });
                    $msg->from("api");
                });
            }
            else{$c->safe_render(json=>{id=>undef,code=>103,status=>"group member not found"});}
        }
        elsif(defined $p->{discuss_id}){
            my $discuss = $client->search_discuss(id=>$p->{discuss_id});
            my $member = defined $discuss?$discuss->search_discuss_member(uid=>$p->{uid},id=>$p->{id}):undef;
            if(defined $member){
                $c->render_later;
                $client->send_sess_message($member,$p->{content},sub{
                    my $msg = $_[1];
                    $msg->cb(sub{
                        my($client,$msg)=@_;
                        $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->msg});
                    });
                    $msg->from("api");
                });
            }
            else{$c->safe_render(json=>{id=>undef,code=>104,status=>"discuss member not found"});}
        }
        else{$c->safe_render(json=>{id=>undef,code=>105,status=>"discuss member or group member  not found"});}
    };
    any [qw(GET POST)] => '/openqq/search_friend' => sub{
        my $c = shift;
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_friend(@params);
        if(@objects){
            $c->safe_render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->safe_render(json=>{code=>100,status=>"object not found"});
        }
        
    };
    any [qw(GET POST)] => '/openqq/search_group' => sub{
        my $c = shift;
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_group(@params);
        for(@objects){$client->update_group_member($_,is_blocking=>1,is_update_group_member_ext=>1) if $_->is_empty};
        if(@objects){
            $c->safe_render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->safe_render(json=>{code=>100,status=>"object not found"});
        }
    };
    any [qw(GET POST)] => '/openqq/kick_group_member' => sub{
        my $c = shift;
        my $p = $c->params;
        my $group = $client->search_group(id=>$p->{group_id},uid=>$p->{group_uid});
        if(not defined $group){ 
            $c->safe_render(json=>{code=>100,status=>"object not found"});
            return;
        }

        my @id = split /,/,($p->{member_id} // $p->{member_uid}); 
        if(@id){
            my @members;
            for(@id){
                my $member = $group->search_group_member(defined($p->{member_id})?(id=>$_):(uid=>$_));
                if(not defined $member){
                    $c->safe_render(json=>{code=>100,status=>"member $_ not found"});
                    return;
                }
                push @members,$member;
            }
            if($group->kick_group_member(@members)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }   
        }
        else{$c->safe_render(json=>{code=>200,status=>"member id empty"});}
    };
    any [qw(GET POST)] => '/openqq/shutup_group_member' => sub{
        my $c = shift;
        my $p = $c->params;
        my $group = $client->search_group(id=>$p->{group_id},uid=>$p->{group_uid});
        if(not defined $group){ 
            $c->safe_render(json=>{code=>100,status=>"object not found"});
            return;
        }
        if(not defined $p->{time} or $p->{time}!~/^\d+$/){ 
            $c->safe_render(json=>{code=>400,status=>"shutup time missing or error"});
            return;
        }
        my @id = split /,/,($p->{member_id} // $p->{member_uid}); 
        if(@id){
            my @members;
            for(@id){
                my $member = $group->search_group_member(defined($p->{member_id})?(id=>$_):(uid=>$_));
                if(not defined $member){
                    $c->safe_render(json=>{code=>100,status=>"member $_ not found"});
                    return;
                }
                push @members,$member;
            }
            if($group->shutup_group_member($p->{time},@members)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }   
        }
        else{$c->safe_render(json=>{code=>200,status=>"member id empty"});}
    };
    any '/*whatever'  => sub{whatever=>'',$_[0]->safe_render(text=>"request error",status=>403)};
    package Mojo::Webqq::Plugin::Openqq;
    $server = Mojo::Webqq::Server->new();   
    $server->app($server->build_app("Mojo::Webqq::Plugin::Openqq::App"));
    $server->app->secrets("hello world");
    $server->app->log($client->log);
    if(ref $data eq "ARRAY"){#旧版本兼容性
        $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:5000)} @$data]);
    }
    elsif(ref $data eq "HASH" and ref $data->{listen} eq "ARRAY"){
        $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:5000)} @{ $data->{listen}} ]) ;
    }
    $server->start;
}
1;
