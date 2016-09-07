package Mojo::Webqq::Request;
use List::Util qw(first);
use Mojo::Util ();
use File::Spec ();
sub gen_url{
    my $self = shift;
    my ($url,@query_string) = @_;
    my @query_string_pairs;
    while(@query_string){
        my $key = shift(@query_string);
        my $val = shift(@query_string);
        $key = "" if not defined $key;
        $val = "" if not defined $val;
        push @query_string_pairs , $key . "=" . $val;
    }
    return $url . '?' . join("&",@query_string_pairs);    
}
sub http_get{
    my $self = shift;
    return $self->_http_request("get",@_);
}
sub http_post{
    my $self = shift;
    return $self->_http_request("post",@_);
}

sub _ua_debug {
    my ($self,$ua,$tx,$opt,$is_blocking) = @_;
    return if not $opt->{ua_debug};
    $self->print("-- " . ($is_blocking?"Blocking":"Non-blocking"). " request (@{[$tx->req->url->to_abs]})\n");

    $opt->{ua_debug_req_body}?$self->print("-- Client >>> Server (@{[$tx->req->url->to_abs]})\n@{[$tx->req->to_string]}\n"):$self->print("-- Client >>> Server (@{[$tx->req->url->to_abs]})\n@{[$tx->req->build_start_line . $tx->req->build_headers]}\n[body data skipped]\n");

    my $res_content_type = eval {$tx->res->headers->content_type};
    if(defined $res_content_type and $res_content_type =~m#^(image|video|auido)/|^application/octet-stream#){
        $self->print("-- Server >>> Client (@{[$tx->req->url->to_abs]})\n@{[$tx->res->build_start_line . $tx->res->build_headers]}\n[binary data not shown]");
    }
    else{
        $opt->{ua_debug_res_body}?$self->print("-- Server >>> Client (@{[$tx->req->url->to_abs]})\n@{[$tx->res->to_string]}\n"):$self->print("-- Server >>> Client (@{[$tx->req->url->to_abs]})\n@{[$tx->res->build_start_line . $tx->res->build_headers]}\n[body data skipped]\n");
    }
}
sub _http_request{
    my $self = shift;
    my $method = shift;    #$method eq [get|post]
    my %opt = (
        json                =>  0,
        retry_times         =>  $self->ua_retry_times,
        ua_debug            =>  $self->ua_debug,
        ua_debug_res_body   =>  $self->ua_debug_res_body,
        ua_debug_req_body   =>  $self->ua_debug_req_body
    );
    if(ref $_[1] eq "HASH"){#with header or option
        $opt{json} = delete $_[1]->{json} if defined $_[1]->{json};
        $opt{retry_times} = delete $_[1]->{retry_times} if defined $_[1]->{retry_times};
        $opt{ua_debug}          = delete $_[1]->{ua_debug} if defined $_[1]->{ua_debug};
        $opt{ua_debug_res_body} = delete $_[1]->{ua_debug_res_body} if defined $_[1]->{ua_debug_res_body};
        $opt{ua_debug_req_body} = delete $_[1]->{ua_debug_req_body} if defined $_[1]->{ua_debug_req_body};
    }
    if(ref $_[-1] eq "CODE"){
        my $cb = pop;
        return $self->ua->$method(@_,sub{
            my($ua,$tx) = @_;
            _ua_debug($self,$ua,$tx,\%opt,0) if $opt{ua_debug};
            $self->save_cookie();
            if(defined $tx and $tx->success){
                my $r = $opt{json}?$self->decode_json($tx->res->body):$tx->res->body;
                $cb->($r,$ua,$tx);
            }
            elsif(defined $tx){
                $self->warn($tx->req->url->to_abs . " 请求失败: " . ($tx->error->{code}||"-") . " " . Mojo::Util::encode("utf8",$tx->error->{message}));
                $cb->(undef,$ua,$tx);
            }
        });
    }
    else{
        my $tx;
        for(my $i=0;$i<=$opt{retry_times};$i++){
            $tx = $self->ua->$method(@_);   #$method eq [get|post]
            _ua_debug($self,$ua,$tx,\%opt,1) if $opt{ua_debug};
            $self->save_cookie();
            if(defined $tx and $tx->success){
                my $r = $opt{json}?$self->decode_json($tx->res->body):$tx->res->body;
                return wantarray?($r,$self->ua,$tx):$r;
            }
            elsif(defined $tx){
                $self->warn($tx->req->url->to_abs . " 请求失败: " . ($tx->error->{code} || "-") . " " . Mojo::Util::encode("utf8",$tx->error->{message}));
                next;
            }
        }
        $self->warn($tx->req->url->to_abs . " 请求失败: " . ($tx->error->{code}||"-") . " " . Mojo::Util::encode("utf8",$tx->error->{message})) if defined $tx;
        return wantarray?(undef,$self->ua,$tx):undef;
    }
}

sub load_cookie{
    my $self = shift;
    return if not $self->keep_cookie;
    #if(not defined $self->qq){
    #    $self->warn("未设置登录帐号, 无法加载登录cookie"); 
    #    return;  
    #}
    my $cookie_jar;
    my $cookie_path = File::Spec->catfile($self->cookie_dir , 'mojo_webqq_cookie_' . ($self->is_set_qq && $self->qq?$self->qq:'default') . '.dat');
    return if not -f $cookie_path;
    eval{require Storable;$cookie_jar = Storable::retrieve($cookie_path)};
    if($@){
        $self->warn("客户端加载cookie[ $cookie_path ]失败: $@");
        return;
    }
    else{
        $self->info("客户端加载cookie[ $cookie_path ]");
    }
    $self->ua->cookie_jar($cookie_jar);

}
sub save_cookie{
    my $self = shift;
    return if not $self->keep_cookie;
    #return if not defined $self->qq;
    my $cookie_path = File::Spec->catfile($self->cookie_dir ,'mojo_webqq_cookie_' .($self->is_set_qq && $self->qq?$self->qq:'default') . '.dat');
    eval{Storable::nstore($self->ua->cookie_jar,$cookie_path);};
    $self->warn("客户端保存cookie[ $cookie_path ]失败: $@") if $@;
}

sub search_cookie{
    my $self   = shift;
    my $cookie = shift;
    my @cookies;
    my @tmp = $self->ua->cookie_jar->all;
    if(@tmp == 1 and ref $tmp[0] eq "ARRAY"){ 
        @cookies = @{$tmp[0]};
    }
    else{
        @cookies = @tmp;
    }
    my $c = first  { defined $_ and $_->name eq $cookie} @cookies;
    return defined $c?$c->value:undef;
}
1;
