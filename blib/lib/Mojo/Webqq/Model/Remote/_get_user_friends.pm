sub Mojo::Webqq::Model::_get_user_friends{
    my $self = shift;
    my $callback = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_user_friends2';
    my $headers = {Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my %r = (
        hash        => $self->hash($self->ptwebqq,$self->uid),  
        vfwebqq     => $self->vfwebqq,
    );
    
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub{
        my $json = shift;
        my $friends_state = shift;
        return undef unless defined $json;
        return undef if $json->{retcode}!=0 ;
        my %categories ;
        my %info;
        my %marknames;
        my %vipinfo;
        my %state;
        if(defined $friends_state and ref $friends_state eq "ARRAY"){
            for(@{$friends_state}){
                $state{$_->{uin}}{state} = $_->{state};
                $state{$_->{uin}}{client_type} = $_->{client_type};
            }
        }
        for(@{ $json->{result}{categories}}){
            $categories{ $_->{'index'} } = {'sort'=>$_->{'sort'},name=>$_->{name} };
        }
        $categories{0} = {sort=>0,name=>'我的好友'} if not defined $categories{0};
        for(@{ $json->{result}{info}}){
            $info{$_->{uin}} = {face=>$_->{face},flag=>$_->{flag},nick=>$_->{nick}};
        }
        for(@{ $json->{result}{marknames} }){
            $marknames{$_->{uin}} = {markname=>$_->{markname},type=>$_->{type}};
        }
        for(@{ $json->{result}{vipinfo} }){
            $vipinfo{$_->{u}} = {vip_level=>$_->{vip_level},is_vip=>$_->{is_vip}};
        }        
        for(@{$json->{result}{friends}}){
            my $uin  = $_->{uin};
            if(exists $state{$_->{uin}}){
                $_->{state} = $state{$uin}{state};
                $_->{client_type} = $state{$uin}{client_type};
            }
            else{
                $_->{state} = 'offline';
                $_->{client_type} = 'unknown';
            }
            $_->{category} = $self->xmlescape_parse($categories{$_->{categories}}{name});
            $_->{name}  = $self->xmlescape_parse($info{$uin}{nick});
            $_->{face} = $info{$uin}{face};
            $_->{markname} = $self->xmlescape_parse($marknames{$uin}{markname});
            $_->{is_vip} = $vipinfo{$uin}{is_vip};
            $_->{vip_level} = $vipinfo{$uin}{vip_level};
            delete $_->{categories};
            $_->{id} = delete $_->{uin};
        }
        return $json->{result}{friends};
    };
    if($is_blocking){
        my $json = $self->http_post($api_url,$headers,form=>{r=>$self->to_json(\%r)},);
        my $friends_state = $self->_get_friends_state();
        return $handle->($json,$friends_state);
    }
    else{
        $self->steps(
            sub{
                my $delay = shift;
                $self->http_post($api_url,$headers,form=>{r=>$self->to_json(\%r)},$delay->begin(0,1));
                $self->_get_friends_state($delay->begin(0,1));
            },
            sub{
                my($delay,$json,$friends_state) = @_;
                $callback->( $handle->($json,$friends_state) )  if ref $callback eq "CODE";
            },
        );
    }
}
1;
