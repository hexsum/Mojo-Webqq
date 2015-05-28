sub Mojo::Webqq::Model::_get_user_friends{
    my $self = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_user_friends2';
    my $headers = {Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my %r = (
        hash        => $self->hash($self->ptwebqq,$self->qq),  
        vfwebqq     => $self->vfwebqq,
    );
    my $json = $self->http_post($api_url,$headers,form=>{r=>$self->encode_json(\%r)});  
    return undef unless defined $json;
    return undef if $json->{retcode}!=0 ;
    my $friends_state = $self->_get_friends_state();
    my %categories ;
    my %info;
    my %marknames;
    my %vipinfo;
    my %state;
    if(defined $friends_state){
        for(@{$friends_state}){
            $state{$_->{uin}}{state} = $_->{state};
            $state{$_->{uin}}{client_type} = $_->{client_type};
        }
    }
    for(@{ $json->{result}{categories}}){
        $categories{ $_->{'index'} } = {'sort'=>$_->{'sort'},name=>encode("utf8",$_->{name}) };
    }
    $categories{0} = {sort=>0,name=>'我的好友'};
    for(@{ $json->{result}{info}}){
        $info{$_->{uin}} = {face=>$_->{face},flag=>$_->{flag},nick=>encode("utf8",$_->{nick}),};
    }
    for(@{ $json->{result}{marknames} }){
        $marknames{$_->{uin}} = {markname=>encode("utf8",$_->{markname}),type=>$_->{type}};
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
        $_->{categorie} = $categories{$_->{categories}}{name};
        $_->{nick}  = $info{$uin}{nick};
        $_->{face} = $info{$uin}{face};
        $_->{markname} = $marknames{$uin}{markname};
        $_->{is_vip} = $vipinfo{$uin}{is_vip};
        $_->{vip_level} = $vipinfo{$uin}{vip_level};
        delete $_->{categories};
        $_->{id} = delete $_->{uin};
        $self->reform_hash($_);
    }
    return $json->{result}{friends};
}
1;
