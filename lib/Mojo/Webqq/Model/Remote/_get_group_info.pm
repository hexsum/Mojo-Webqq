use strict;
sub Mojo::Webqq::Model::_get_group_info {
    my $self = shift;
    my $gcode = shift;
    my $callback = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_group_info_ext2';
    my @query_string  = (
        gcode   =>  $gcode,
        vfwebqq =>  $self->vfwebqq,
        t       =>  time(),
    ); 

    my $headers = {Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub {
        my $json = shift;
        return unless defined $json;
        my $ginfo_status = exists $json->{result}{ginfo}?"[ginfo-ok]":"[ginfo-not-ok]";
        my $minfo_status = ref $json->{result}{minfo} eq "ARRAY"?"[minfo-ok]":"[minfo-not-ok]";
        
        return undef unless exists $json->{result}{ginfo};
        $json->{result}{ginfo}{id} = delete $json->{result}{ginfo}{gid};
        $json->{result}{ginfo}{code} = delete $json->{result}{ginfo}{code};
        $json->{result}{ginfo}{name} = $self->xmlescape_parse($json->{result}{ginfo}{name});
        $json->{result}{ginfo}{memo} = delete $json->{result}{ginfo}{memo};
        $json->{result}{ginfo}{createtime} = delete $json->{result}{ginfo}{createtime};
        $json->{result}{ginfo}{level} = delete $json->{result}{ginfo}{level};
        $json->{result}{ginfo}{owner_id} = delete $json->{result}{ginfo}{owner};
        $json->{result}{ginfo}{markname} = $self->xmlescape_parse($json->{result}{ginfo}{markname});
        
        delete $json->{result}{ginfo}{fingermemo};
        delete $json->{result}{ginfo}{face};
        delete $json->{result}{ginfo}{option};
        delete $json->{result}{ginfo}{class};
        delete $json->{result}{ginfo}{flag};
        delete $json->{result}{ginfo}{members}; 

        #retcode等于0说明包含完整的ginfo和minfo
        if(exists $json->{result}{minfo} and ref $json->{result}{minfo} eq "ARRAY"){
            my %cards;
            if(ref $json->{result}{cards} eq "ARRAY" and @{ $json->{result}{cards} }!=0){
                for  (@{ $json->{result}{cards} }){
                    $cards{$_->{muin}} = $_->{card};
                }
            }
            my %state;
            for(@{ $json->{result}{stats} }){
                $state{$_->{uin}}{client_type} = $self->code2client($_->{client_type});
                $state{$_->{uin}}{state} = $self->code2state($_->{'stat'});
            }
            for my $m(@{ $json->{result}{minfo} }){
                $m->{card} = $self->xmlescape_parse($cards{$m->{uin}}) if exists $cards{$m->{uin}};
                $m->{name} = $self->xmlescape_parse(delete $m->{nick});
                if(exists $state{$m->{uin}}){
                    $m->{state} = $state{$m->{uin}}{state};
                    $m->{client_type} = $state{$m->{uin}}{client_type};
                }
                else{
                    $m->{state} = 'offline';
                    $m->{client_type} = 'unknown';
                }
                $m->{_group_id} = $json->{result}{ginfo}{id};
                $m->{id}    = delete $m->{uin};
                $m->{sex}    = delete $m->{gender};
            }
            $json->{result}{ginfo}{member} = delete $json->{result}{minfo};
        }
        return $json->{result}{ginfo};
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
