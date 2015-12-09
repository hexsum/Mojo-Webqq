sub Mojo::Webqq::Model::_get_recent_info {
    my $self  = shift;
    my $api_url = 'http://d1.web2.qq.com/channel/get_recent_list2';
    my $headers = {
        Referer => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
        json    => 1,
    };     

    my %r = (
        vfwebqq         =>  $self->vfwebqq,
        clientid        =>  $self->clientid,
        psessionid      =>  $self->psessionid,
    ); 
    my $json = $self->http_post($api_url,$headers,form=>{r=>$self->encode_json(\%r)},);    
    return undef unless defined $json;
    return undef if $json->{retcode}!=0 ;
    my %type = (0 => 'friend',1 => 'group', 2 => 'discuss');
    my @recent;
    for(@{$json->{result}}){
        next unless exists $type{$_->{type}};
        $_->{type} = $type{$_->{type}};
        if($_->{type} eq "friend"){$_->{id} = delete $_->{uin};}
        elsif($_->{type} eq "group"){$_->{gid} = delete $_->{uin};}
        elsif($_->{type} eq "discuss"){$_->{did} = delete $_->{uin};}
        push @recent,$_;
    }
    return @recent>0?\@recent:undef;
}
1;
