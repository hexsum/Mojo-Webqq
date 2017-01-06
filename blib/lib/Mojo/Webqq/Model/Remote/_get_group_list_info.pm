use strict;
sub Mojo::Webqq::Model::_get_group_list_info{
    my $self  = shift;
    my $callback = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_group_name_list_mask2';
    my $headers = {Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my %r = (
        hash        =>  $self->hash($self->ptwebqq,$self->uid),
        vfwebqq     =>  $self->vfwebqq,
    );  
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub{
        my $json = shift;
        return undef unless defined $json;
        return undef unless exists $json->{result}{gnamelist};
        my $group_list_info = $json->{result}{gnamelist};
        my %gmarklist;
        for(@{ $group_list_info }){
            $gmarklist{$_->{gid}} = $_->{markname};
        }
        for(@{$group_list_info}){
            $_->{markname} = $self->xmlescape_parse($gmarklist{$_->{gid}});
            $_->{name} = $self->xmlescape_parse($_->{name});
            $_->{id} = delete $_->{gid};
            delete $_->{flag} ;
        }
        return $group_list_info;
    };
    if($is_blocking){
        return $handle->($self->http_get($api_url,$headers,form=>{r=>$self->to_json(\%r)},) );
    }
    else{
        $self->http_get($api_url,$headers,form=>{r=>$self->to_json(\%r)},sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}
1;
