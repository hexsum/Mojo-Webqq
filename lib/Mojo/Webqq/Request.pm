package Mojo::Webqq::Request;
use List::Util qw(first);
sub gen_url{
    my $self = shift;
    my ($url,@query_string) = @_;
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
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
sub _http_request{
    my $self = shift;
    my $method = shift;
    my %opt = ();
    if(ref $_[1] eq "HASH"){#with header or option
        $opt{json} = delete $_[1]->{json} || 0;
        $opt{retry_times} = delete $_[1]->{retry_times} || $self->ua_retry_times;
    }
    if(ref $_[-1] eq "CODE"){
        my $cb = pop;
        $self->ua->$method(@_,sub{
            my($ua,$tx) = @_;
            if(defined $tx and $tx->success){
                my $r = eval{$opt{json}?$tx->res->json:$tx->res->body;};
                if($@){
                    $self->warn($@);
                    $cb->(undef,$ua,$tx);
                }
                else{$cb->($r,$ua,$tx);}
            }
            else{$cb->(undef,$ua,$tx);}
        });
    }
    else{
        for(my $i=0;$i<=$opt{retry_times};$i++){
            my $tx = $self->ua->$method(@_);
            if(defined $tx and $tx->success){
                my $r = eval{$opt{json}?$tx->res->json:$tx->res->body;};
                if($@){
                    $self->warn($@);
                    next;
                }
                else{
                    return wantarray?($r,$self->ua,$tx):$r;
                }
            }
        }
        return wantarray?(undef,$self->ua,$tx):undef;
    }
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
1;
