use strict;
use Encode;
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
            return if $msg->type !~ /^message|group_message|discuss_message|sess_message$/;
            $client->http_post($post_api,json=>$msg->to_json_hash,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]接收消息[".$msg->msg_id."]上报成功");
                    if($tx->res->headers->content_type =~m#text/json|application/json#){
                        #文本类的返回结果必须是json字符串
                        my $json;
                        eval{$json = $tx->res->json};
                        if($@){$client->warn($@);return}
                        if(defined $json){
                            #{code=>0,reply=>"回复的消息",format=>"text"}
                            if((!defined $json->{format}) or (defined $json->{format} and $json->{format} eq "text")){
                                $msg->reply(Encode::encode("utf8",$json->{reply})) if defined $json->{reply}; 
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
                    $client->warn("插件[".__PACKAGE__ . "]接收消息[".$msg->msg_id."]上报失败: ".$tx->error->{message}); 
                }
            });
        });
    }

    package Mojo::Webqq::Plugin::Openqq::App;
    use Encode;
    use Mojolicious::Lite;
    under sub {
        my $c = shift;
        if(ref $data eq "HASH" and ref $data->{auth} eq "CODE"){
            my $hash  = $c->req->params->to_hash;
            $client->reform_hash($hash);
            my $ret = 0;
            eval{
                $ret = $data->{auth}->($hash,$c);
            };
            $client->warn("插件[Mojo::Webqq::Plugin::Openqq]认证回调执行错误: $@") if $@;
            $c->render(text=>"auth failure",status=>403) if not $ret;
            return $ret;
        }
        else{return 1} 
    };
    get '/openqq/get_user_info'     => sub {$_[0]->render(json=>$client->user->to_json_hash());};
    get '/openqq/get_friend_info'   => sub {$_[0]->render(json=>[map {$_->to_json_hash()} @{$client->friend}]); };
    get '/openqq/get_group_info'    => sub {$_[0]->render(json=>[map {$_->to_json_hash()} @{$client->group}]); };
    get '/openqq/get_group_basic_info'    => sub {$_[0]->render(json=>[map {delete $_->{member};$_} map {$_->to_json_hash()} @{$client->group}]); };
    get '/openqq/get_discuss_info'  => sub {$_[0]->render(json=>[map {$_->to_json_hash()} @{$client->discuss}]); };
    get '/openqq/get_recent_info'   => sub {$_[0]->render(json=>[map {$_->to_json_hash()} @{$client->recent}]);};
    any [qw(GET POST)] => '/openqq/send_message'         => sub{
        my $c = shift;
        my($id,$qq,$content)=($c->param("id"),$c->param("qq"),$c->param("content"));
        my $friend = $client->search_friend(id=>$id,qq=>$qq);
        if(defined $friend){
            $c->render_later;
            $client->send_message($friend,encode("utf8",$content),sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});  
                });
                $msg->msg_from("api");
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"friend not found"});}
    };
    any [qw(GET POST)] => 'openqq/send_group_message'    => sub{
        my $c = shift;
        my($gid,$gnumber,$content)=($c->param("gid"),$c->param("gnumber"),$c->param("content"));
        my $group = $client->search_group(gid=>$gid,gnumber=>$gnumber,);
        if(defined $group){
            $c->render_later;
            $client->send_group_message($group,encode("utf8",$content),sub{
                my $msg = $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
                });
                $msg->msg_from("api");
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>101,status=>"group not found"});}
    };
    any [qw(GET POST)] => 'openqq/send_discuss_message'  => sub{
        my $c = shift;
        my($did,$content)=($c->param("did"),$c->param("content"));
        my $discuss = $client->search_discuss(did=>$did);
        if(defined $discuss){
            $c->render_later;
            $client->send_discuss_message($discuss,encode("utf8",$content),sub{
                my $msg = $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
                });
                $msg->msg_from("api");
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>102,status=>"discuss not found"});}
    };
    any [qw(GET POST)] => '/openqq/send_sess_message'    => sub{
        my $c = shift;
        my($gid,$gnumber,$did,$qq,$id,$content)=
        ($c->param("gid"),$c->param("gnumber"),$c->param("did"),$c->param("qq"),$c->param("id"),$c->param("content"));
        if(defined $gid or defined $gnumber){
            my $group = $client->search_group(gid=>$gid,gnumber=>$gnumber);
            my $member = defined $group?$group->search_group_member(qq=>$qq,id=>$id):undef;
            if(defined $member){
                $c->render_later;
                $client->send_sess_message($member,encode("utf8",$content),sub{
                    my $msg = $_[1];
                    $msg->cb(sub{
                        my($client,$msg,$status)=@_;
                        $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
                    });
                    $msg->msg_from("api");
                });
            }
            else{$c->render(json=>{msg_id=>undef,code=>103,status=>"group member not found"});}
        }
        elsif(defined $did){
            my $discuss = $client->search_discuss(did=>$did);
            my $member = defined $discuss?$discuss->search_discuss_member(qq=>$qq,id=>$id):undef;
            if(defined $member){
                $c->render_later;
                $client->send_sess_message($member,encode("utf8",$content),sub{
                    my $msg = $_[1];
                    $msg->cb(sub{
                        my($client,$msg,$status)=@_;
                        $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
                    });
                    $msg->msg_from("api");
                });
            }
            else{$c->render(json=>{msg_id=>undef,code=>104,status=>"discuss member not found"});}
        }
        else{$c->render(json=>{msg_id=>undef,code=>105,status=>"discuss member or group member  not found"});}
    };
    any [qw(GET POST)] => '/openqq/search_friend' => sub{
        my $c = shift;
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_friend(@params);
        if(@objects){
            $c->render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->render(json=>{code=>100,status=>"object not found"});
        }
        
    };
    any [qw(GET POST)] => '/openqq/search_group' => sub{
        my $c = shift;
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_group(@params);
        for(@objects){$client->update_group_member($_,is_blocking=>1,is_update_group_member_ext=>1) if $_->is_empty};
        if(@objects){
            $c->render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->render(json=>{code=>100,status=>"object not found"});
        }
    };
    any [qw(GET POST)] => '/openqq/kick_group_member' => sub{
        my $c = shift;
        my($gid,$gnumber,$members_id,$members_qq)=($c->param("gid"),$c->param("gnumber"),$c->param("member_id"),$c->param("member_qq"));
        my $group = $client->search_group(gid=>$gid,gnumber=>$gnumber,);
        if(not defined $group){ 
            $c->render(json=>{code=>100,status=>"object not found"});
            return;
        }

        my @id = split /,/,(defined($members_id)?$members_id:$members_qq); 
        if(@id){
            my @members;
            for(@id){
                my $member = $group->search_group_member(defined($members_id)?(id=>$_):(qq=>$_));
                if(not defined $member){
                    $c->render(json=>{code=>100,status=>"member $_ not found"});
                    return;
                }
                push @members,$member;
            }
            if($group->kick_group_member(@members)){
                $c->render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->render(json=>{code=>201,status=>"failure"});
            }   
        }
        else{$c->render(json=>{code=>200,status=>"member id empty"});}
    };
    any [qw(GET POST)] => '/openqq/shutup_group_member' => sub{
        my $c = shift;
        my($gid,$gnumber,$time,$members_id,$members_qq)=($c->param("gid"),$c->param("gnumber"),$c->param("time"),$c->param("member_id"),$c->param("member_qq"));
        my $group = $client->search_group(gid=>$gid,gnumber=>$gnumber,);
        if(not defined $group){ 
            $c->render(json=>{code=>100,status=>"object not found"});
            return;
        }
        if(not defined $time or $time!~/^\d+$/){ 
            $c->render(json=>{code=>400,status=>"shutup time missing or error"});
            return;
        }
        my @id = split /,/,(defined($members_id)?$members_id:$members_qq); 
        if(@id){
            my @members;
            for(@id){
                my $member = $group->search_group_member(defined($members_id)?(id=>$_):(qq=>$_));
                if(not defined $member){
                    $c->render(json=>{code=>100,status=>"member $_ not found"});
                    return;
                }
                push @members,$member;
            }
            if($group->shutup_group_member($time,@members)){
                $c->render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->render(json=>{code=>201,status=>"failure"});
            }   
        }
        else{$c->render(json=>{code=>200,status=>"member id empty"});}
    };
    any '/*whatever'  => sub{whatever=>'',$_[0]->render(text=>"request error",status=>403)};
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
