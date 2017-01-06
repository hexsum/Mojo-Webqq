package Mojo::Webqq::Request;
use Mojo::Util ();
use List::Util qw(first);
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

sub gen_url2{
    my $self = shift;
    my ($url,@query_string) = @_;
    my @query_string_pairs;
    while(@query_string){
        my $key = shift(@query_string);
        my $val = shift(@query_string);
        $key = "" if not defined $key;
        $val = "" if not defined $val;
        push @query_string_pairs , $key . "=" . Mojo::Util::url_escape($val);
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
    my $method = shift;
    my %opt = (
        json                =>  0,  
        blocking            =>  0,
        ua_retry_times      =>  $self->ua_retry_times,
        #ua_connect_timeout  =>  $self->ua_connect_timeout,
        #ua_request_timeout  =>  $self->ua_request_timeout,
        #ua_inactivity_timeout => $self->ua_inactivity_timeout,
        ua_debug            =>  $self->ua_debug,
        ua_debug_res_body   =>  $self->ua_debug_res_body,
        ua_debug_req_body   =>  $self->ua_debug_req_body
    );
    if(ref $_[1] eq "HASH"){#with header or option
        $opt{json} = delete $_[1]->{json} if defined $_[1]->{json};
        $opt{blocking} = delete $_[1]->{blocking} if defined $_[1]->{blocking};
        $opt{ua_retry_times} = delete $_[1]->{ua_retry_times} if defined $_[1]->{ua_retry_times};
        $opt{ua_debug}          = delete $_[1]->{ua_debug} if defined $_[1]->{ua_debug};
        $opt{ua_debug_res_body} = delete $_[1]->{ua_debug_res_body} if defined $_[1]->{ua_debug_res_body};
        $opt{ua_debug_req_body} = delete $_[1]->{ua_debug_req_body} if defined $_[1]->{ua_debug_req_body};
        $opt{ua_connect_timeout} = delete $_[1]->{ua_connect_timeout} if defined $_[1]->{ua_connect_timeout};
        $opt{ua_request_timeout} = delete $_[1]->{ua_request_timeout} if defined $_[1]->{ua_request_timeout};
        $opt{ua_inactivity_timeout} = delete $_[1]->{ua_inactivity_timeout} if defined $_[1]->{ua_inactivity_timeout};
    }
    if(ref $_[-1] eq "CODE" and !$opt{blocking}){
        my $cb = pop;
        return $self->ua->$method(@_,sub{
            my($ua,$tx) = @_;
            _ua_debug($self,$ua,$tx,\%opt,0) if $opt{ua_debug};
            $self->save_cookie();
            if(defined $tx and $tx->success){
                my $r = $opt{json}?$self->from_json($tx->res->body):$tx->res->body;
                $cb->($r,$ua,$tx);
            }
            elsif(defined $tx){
                $self->warn($tx->req->url->to_abs . " 请求失败: " . ($tx->error->{code}||"-") . " " . $self->encode_utf8($tx->error->{message}));
                $cb->(undef,$ua,$tx);
            }
        });
    }
    else{
        my $tx;
        my $cb = pop if ref $_[-1] eq "CODE";
        for(my $i=0;$i<=$opt{ua_retry_times};$i++){
            if($opt{ua_connect_timeout} or  $opt{ua_request_timeout} or $opt{ua_inactivity_timeout}){
                my $connect_timeout = $self->ua->connect_timeout;
                my $request_timeout = $self->ua->request_timeout;
                my $inactivity_timeout = $self->ua->inactivity_timeout;
                $self->ua->connect_timeout($opt{ua_connect_timeout}) if $opt{ua_connect_timeout};
                $self->ua->request_timeout($opt{ua_request_timeout}) if $opt{ua_request_timeout};
                $self->ua->inactivity_timeout($opt{ua_inactivity_timeout}) if $opt{ua_inactivity_timeout};
                $tx = $self->ua->$method(@_);
                $self->ua->connect_timeout($connect_timeout)
                        ->request_timeout($request_timeout)
                        ->inactivity_timeout($inactivity_timeout);
            }
            else{
                $tx = $self->ua->$method(@_);
            }
            _ua_debug($self,$ua,$tx,\%opt,1) if $opt{ua_debug};
            $self->save_cookie();
            if(defined $tx and $tx->success){
                my $r = $opt{json}?$self->from_json($tx->res->body):$tx->res->body;
                $cb->($r,$ua,$tx) if defined $cb;
                return wantarray?($r,$self->ua,$tx):$r;
            }
            elsif(defined $tx){
                $self->warn($tx->req->url->to_abs . " 请求失败: " . ($tx->error->{code} || "-") . " " . $self->encode_utf8($tx->error->{message}));
                next;
            }
        }
        $self->warn($tx->req->url->to_abs . " 请求失败: " . ($tx->error->{code}||"-") . " " . $self->encode_utf8($tx->error->{message})) if defined $tx;
        $cb->($r,$ua,$tx) if defined $cb;
        return wantarray?(undef,$self->ua,$tx):undef;
    }
}

sub load_cookie{
    my $self = shift;
    return if not $self->keep_cookie;
    my $cookie_jar;
    my $cookie_path = $self->cookie_path;
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
    my $cookie_path = $self->cookie_path;
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
    my $c = first  { $_->name eq $cookie} @cookies;
    return defined $c?$c->value:undef;
}
sub clear_cookie{
    my $self = shift;
    $self->ua->cookie_jar->empty;
    $self->save_cookie();
}
1;
