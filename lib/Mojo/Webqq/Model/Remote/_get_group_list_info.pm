use strict;
sub Mojo::Webqq::Model::_get_group_list_info{
    my $self  = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_group_name_list_mask2';
    my $headers = {Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my %r = (
        hash        =>  $self->hash($self->ptwebqq,$self->qq),
        vfwebqq     =>  $self->vfwebqq,
    );  
    my $json =  $self->http_post(
        $api_url,
        $headers,
        form => {r => $self->encode_json(\%r)},
    );
    return undef unless defined $json;
    return undef unless exists $json->{result}{gnamelist};
    my $group_list_info = $json->{result}{gnamelist};
    my %gmarklist;
    for(@{ $group_list_info }){
        $gmarklist{$_->{uin}} = $_->{markname};
    }
    for(@{$group_list_info}){
        $_->{gmarkname} = $gmarklist{$_->{gid}};
        $_->{gname} = delete $_->{name};
        $_->{gcode} = delete $_->{code};
        delete $_->{flag} ;
        delete $_->{class} ;
        $self->reform_hash($_);
    }
    return $group_list_info;
}
1;
