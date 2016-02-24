use strict;
sub Mojo::Webqq::Model::_get_user_info{
    my $self = shift;
    my $callback = shift;
    my $api_url ='http://s.web2.qq.com/api/get_self_info2';
    my $headers = {
        Referer     =>  'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
        json        =>  1,
    };
    my @query_string = (
        t               =>  time,
    ); 
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub{
        my $json = shift;
        return undef unless defined $json;
        return undef if $json->{retcode} !=0;
        my $user = $json->{result};
        $user->{state} = $self->state;
        $user->{client_type} = 'web';
        $user->{birthday} = join( "-", @{ $user->{birthday} }{qw(year month day)} );
        $user->{signature} = delete $user->{lnick};
        #my $single_long_nick = $self->get_single_long_nick( $self->qq );
        #$json->{result}{signature} = $single_long_nick if defined $single_long_nick;
        $self->reform_hash($user);
        $user->{qq}        = $self->qq;
        $user->{id}        = delete $user->{uin};
        return $user;
    };
    if($is_blocking){
        return $handle->(  $self->http_get($self->gen_url($api_url,@query_string),$headers,) );
    }
    else{
        $self->http_get($self->gen_url($api_url,@query_string),$headers,sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}
1;
