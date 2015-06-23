use strict;
use Mojo::Webqq::Server;
package Mojo::Webqq::Plugin::Openqq;
my $server;
sub call{
    my $client = shift;
    my $data   =  shift;
    package Mojo::Webqq::Plugin::Openqq::App;
    use Encode;
    use Mojolicious::Lite;
    get '/openqq/get_user_info'     => sub {$_[0]->render(json=>$client->user->to_hash());};
    get '/openqq/get_friend_info'   => sub {$_[0]->render(json=>[map {$_->to_hash()} @{$client->friend}]); };
    get '/openqq/get_group_info'    => sub {$_[0]->render(json=>[map {$_->to_hash()} @{$client->group}]); };
    get '/openqq/get_discuss_info'  => sub {$_[0]->render(json=>[map {$_->to_hash()} @{$client->discuss}]); };
    get '/openqq/get_recent_info'   => sub {$_[0]->render(json=>[map {$_->to_hash()} @{$client->recent}]);};
    any [qw(GET POST)] => '/openqq/send_message'         => sub{
        my $c = shift;
        my($id,$qq,$content)=($c->param("id"),$c->param("qq"),$c->param("content"));
        my $friend = $client->search_friend(id=>$id,qq=>$qq);
        if(defined $friend){
            $c->render_later;
            $client->send_message($friend,encode("utf8",$content),sub{
                my($client,$msg,$status)=@_;
                $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});  
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
                my($client,$msg,$status)=@_;
                $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
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
                my($client,$msg,$status)=@_;
                $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
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
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
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
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->msg_id,code=>$status->code,status=>decode("utf8",$status->msg)});
                });
            }
            else{$c->render(json=>{msg_id=>undef,code=>104,status=>"discuss member not found"});}
        }
        else{$c->render(json=>{msg_id=>undef,code=>105,status=>"discuss member or group member  not found"});}
    };
    any '/*whatever'  => sub{whatever=>'',$_[0]->render(text => "request error",status=>403)};
    package Mojo::Webqq::Plugin::Openqq;
    $server = Mojo::Webqq::Server->new();   
    $server->app($server->build_app("Mojo::Webqq::Plugin::Openqq::App"));
    $server->app->secrets("hello world");
    $server->app->log($client->log);
    $server->listen($data) if ref $data eq "ARRAY" ;
    $server->start;
}
1;
