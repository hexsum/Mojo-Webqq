sub Mojo::Webqq::Model::_get_discuss_info {
    my $self = shift;       
    my $did = shift;
    my $callback = shift;
    my $api_url  = 'http://d1.web2.qq.com/channel/get_discu_info';
    my @query_string = (
        did         =>  $did,
        vfwebqq     =>  $self->vfwebqq,
        clientid    =>  $self->clientid,
        psessionid  =>  $self->psessionid,
        t           =>  time(),
    );
    my $headers = {
        Referer  => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
        json     => 1,
    };
    
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub{
        my $json = shift;
        return unless defined $json;
        return undef if $json->{retcode}!=0;
        return undef unless exists $json->{result}{info};
        
        my %mem_list;
        my %mem_status;
        my %mem_info;
        my $minfo = [];

        for(@{ $json->{result}{info}{mem_list} }){
            $mem_list{$_->{mem_uin}}{ruin} = $_->{ruin};            
        }

        for(@{ $json->{result}{mem_status} }){
            $mem_status{$_->{uin}}{status} = $_->{status};
            $mem_status{$_->{uin}}{client_type} = $_->{client_type};
        }

        for(@{ $json->{result}{mem_info} }){
            $mem_info{$_->{uin}}{nick} = $_->{nick};
        }

        my $discuss_info = {
            id         =>  $json->{result}{info}{did},
            owner_id   =>  $json->{result}{info}{discu_owner},
            name       =>  $json->{result}{info}{discu_name},
        };

        for(keys %mem_list){
            my $m = {
                id          => $_,  
                name        => $mem_info{$_}{nick},
                uid          => $mem_list{$_}{ruin},
                _discuss_id => $discuss_info->{did},
            };
            if(exists $mem_status{$_}){
                $m->{state} = $mem_status{$_}{status};
                $m->{client_type} = $self->code2client($mem_status{$_}{client_type});
            }
            else{
                $m->{state} = 'offline';
                $m->{client_type} = 'unknown';
            }
            push @{$minfo},$m;
        }

        $discuss_info->{ member } = $minfo if @$minfo>0;
        return $discuss_info;
    };
    if($is_blocking){
        return $handle->( $self->http_get($self->gen_url($api_url,@query_string),$headers,) );
    }
    else{
        $self->http_get($self->gen_url($api_url,@query_string),$headers,sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });    
    }
}
1;
