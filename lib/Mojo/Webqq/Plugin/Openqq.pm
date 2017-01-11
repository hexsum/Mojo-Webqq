package Mojo::Webqq::Plugin::Openqq;
our $PRIORITY = 98;
use strict;
use POSIX qw();
use Mojo::Util qw();
use List::Util qw(first);
use Mojo::Webqq::Server;
use Mojo::Webqq::List;
my  $server;
my  $check_event_list;
sub call{
    my $client = shift;
    my $data   =  shift;
    $check_event_list = Mojo::Webqq::List->new(max_size=>$data->{check_event_list_max_size} || 20);
    $data->{post_media_data} = 1 if not defined $data->{post_media_data};
    $data->{post_event} = 1 if not defined $data->{post_event};
    $data->{post_event_list} = [qw(login stop state_change input_qrcode new_group new_friend new_group_member lose_group lose_friend lose_group_member)]
        if ref $data->{post_event_list} ne 'ARRAY';

    if(defined $data->{poll_api}){
        $client->on('_mojo_webqq_plugin_openqq_poll_over' => sub{
            $client->http_get($data->{poll_api},sub{
                $client->timer($data->{poll_interval} || 5,sub {$client->emit('_mojo_webqq_plugin_openqq_poll_over');});
            });
        });
        $client->emit('_mojo_webqq_plugin_openqq_poll_over');
    }

    $client->on(all_event => sub{
        my($client,$event,@args) =@_;
        return if not first {$event eq $_} @{ $data->{post_event_list} };
        if(defined $data->{post_api} and ($event eq  'login' or $event eq 'stop' or $event eq 'state_change') ){
            my $post_json = {};
            $post_json->{post_type} = "event";
            $post_json->{event} = $event;
            $post_json->{params} = [@args];
            my($data,$ua,$tx) = $client->http_post($data->{post_api},{ua_connect_timeout=>5,ua_request_timeout=>5,ua_inactivity_timeout=>5,ua_retry_times=>1},json=>$post_json);
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]事件[".$event . "](@args)上报成功");
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]事件[".$event."](@args)上报失败:" . $client->encode("utf8",$tx->error->{message}));
            } 
        }
        elsif(defined $data->{post_api} and $event eq 'input_qrcode'){
            my ($qrcode_path,$qrcode_data) = @args;
            eval{ $qrcode_data = Mojo::Util::b64_encode($qrcode_data);};
            if($@){
                $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: $@");
                return;
            }
            my $post_json = {};
            $post_json->{post_type} = "event";
            $post_json->{event} = $event;
            $post_json->{params} = [$qrcode_path,$qrcode_data];
            push @{$post_json->{params} },$client->qrcode_upload_url if defined $client->qrcode_upload_url;
            my($data,$ua,$tx) = $client->http_post($data->{post_api},json=>$post_json);
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]事件[".$event . "]上报成功");
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败:" . $client->encode("utf8",$tx->error->{message}));
            }
        }
        elsif($event =~ /^new_group|lose_group|new_friend|lose_friend|new_discuss|lose_discuss|new_group_member|lose_group_member|new_discuss_member|lose_discuss_member$/){
            my $post_json = {};
            $post_json->{post_type} = "event";
            $post_json->{event} = $event;
            if($event =~ /^new_group_member|lose_group_member$/){
                $post_json->{params} = [$args[0]->to_json_hash(0),$args[1]->to_json_hash(0)];
            }
            else{
                $post_json->{params} = [$args[0]->to_json_hash(0)];
            }
            $check_event_list->append($post_json);
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",$tx->error->{message}));
                }
            }) if defined $data->{post_api};
        }
        elsif($event =~ /^group_property_change|group_member_property_change|friend_property_change|user_property_change$/){
            my ($object,$property,$old,$new) = @args;
            my $post_json = {
                post_type => "event",
                event     => $event,
                params    => [$object->to_json_hash(0),$property,$old,$new],
            };
            $check_event_list->append($post_json);
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",$tx->error->{message}));
                }
            }) if defined $data->{post_api};

        }
        elsif($event =~ /^update_user|update_friend|update_group$/){
            my ($ref) = @args;
            my $post_json = {
                post_type => "event",
                event     => $event,
                params    => [$event eq 'update_user'?$ref->to_json_hash():map {$_->to_json_hash()} @{$ref}], 
            };
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",tx->error->{message}));
                }
            }) if defined $data->{post_api};
        }
    }) if $data->{post_event};

    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        return if $msg->type !~ /^friend_message|group_message|discuss_message|sess_message$/;
        my $post_json = $msg->to_json_hash;
        #delete $post_json->{media_data} if ($post_json->{format} eq "media" and ! $data->{post_media_data});
        $post_json->{post_type} = "receive_message";
        $check_event_list->append($post_json);
        $client->http_post($data->{post_api},json=>$post_json,sub{
            my($data,$ua,$tx) = @_;
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]接收消息[".$msg->id."]上报成功");
                if($tx->res->headers->content_type =~m#text/json|application/json#){
                    #文本类的返回结果必须是json字符串
                    my $json;
                    eval{$json = $client->from_json($tx->res->body)};
                    if($@){$client->warn($@);return}
                    if(defined $json){
                        #暂时先不启用format的属性
                        #{code=>0,reply=>"回复的消息",format=>"text"}
                        #if((!defined $json->{format}) or (defined $json->{format} and $json->{format} eq "text")){
                        #    $msg->reply(Encode::encode("utf8",$json->{reply})) if defined $json->{reply};
                        #}

                        $msg->reply($json->{reply}) if defined $json->{reply};
                        if($msg->type eq "group_message" and defined $json->{shutup} and $json->{shutup} == 1){
                            $msg->sender->shutup($json->{shutup_time} || 60);
                        }
                        #$msg->reply_media($json->{media}) if defined $json->{media} and $json->{media} =~ /^https?:\/\//;

                    }
                }
                #elsif($tx->res->headers->content_type =~ m#image/#){
                #   #发送图片，暂未实现
                #}
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]接收消息[".$msg->id."]上报失败: ". $client->encode("utf8",$tx->error->{message})); 
            }
        }) if defined $data->{post_api};
    });

    $client->on(send_message=>sub{
        my($client,$msg) = @_;
        return if $msg->type !~ /^friend_message|group_message|discuss_message|sess_message$/;
        my $post_json = $msg->to_json_hash;
        #delete $post_json->{media_data} if ($post_json->{format} eq "media" and ! $data->{post_media_data});
        $post_json->{post_type} = "send_message";
        $check_event_list->append($post_json);
        $client->http_post($data->{post_api},json=>$post_json,sub{
            my($data,$ua,$tx) = @_;
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]发送消息[".$msg->id."]上报成功");
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
                    }
                }
                #elsif($tx->res->headers->content_type =~ m#image/#){
                #   #发送图片，暂未实现
                #}
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]发送消息[".$msg->id."]上报失败: ".$client->encode("utf8",$tx->error->{message})); 
            }
        }) if defined $data->{post_api};
    });
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
    no utf8;
    app->controller_class('Mojo::Webqq::Plugin::Openqq::App::Controller');
    under sub {
        my $c = shift;
        if(ref $data eq "HASH" and ref $data->{auth} eq "CODE"){
            my $hash  = $c->params;
            my $ret = 0;
            eval{
                $ret = $data->{auth}->($hash,$c);
            };
            $client->warn("插件[Mojo::Webqq::Plugin::Openqq]认证回调执行错误: $@") if $@;
            $c->safe_render(json=>{code=>-6,status=>"auth failure"}) if not $ret;
            return $ret;
        }
        else{return 1} 
    };
    get '/openqq/get_user_info'     => sub {$_[0]->safe_render(json=>$client->user->to_json_hash());};
    get '/openqq/get_friend_info'   => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->friend}]); };
    get '/openqq/get_group_info'    => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->group}]); };
    get '/openqq/get_group_basic_info'    => sub {$_[0]->safe_render(json=>[map {delete $_->{member};$_} map {$_->to_json_hash()} @{$client->group}]); };
    get '/openqq/get_discuss_info'  => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->discuss}]); };
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
    any [qw(GET POST)] => '/openwx/check_event'          => sub{
        my $c = shift;
        $c->render_later;
        if($check_event_list->size > 0){
            $c->safe_render(json=>scalar($check_event_list->pick_all));
            return;
        }
        else{
            $c->inactivity_timeout(120);
            my($timer,$cb);
            $timer = Mojo::IOLoop->timer( 30 ,sub { $check_event_list->unsubscribe(append=>$cb);$c->safe_render(json=>[]) });
            $cb = $check_event_list->once(append=>sub{
                my($list,$element) = @_;
                Mojo::IOLoop->remove($timer);
                $c->safe_render(json=>[ $list->pick ]);
            });
        }
    };
    any [qw(GET POST)] => '/openqq/get_client_info' => sub{
        my $c = shift;
        $c->safe_render(json=>{
            code=>0,
            pid=>$$,
            account=>$client->account,
            os=>$^O,
            version=>$client->version,
            starttime=>$client->start_time,
            runtime=>int(time - $client->start_time),
            http_debug=>$client->http_debug,
            log_encoding=>$client->log_encoding,
            log_path=>$client->log_path||"",
            log_level=>$client->log_level,
            status=>"success",
        });
    };
    any [qw(GET POST)] => '/openqq/stop_client' => sub{
        my $c = shift;
        $c->safe_render(json=>{
            code=>0,
            account=>$client->account,
            pid=>$$,
            starttime=>$client->start_time,
            runtime=>int(time - $client->start_time),
            status=>"success, client($$) will stop in 3 seconds",
        });
        $client->timer(3=>sub{$client->stop()});#3秒后再执行，让客户端可以收到该api的响应
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
