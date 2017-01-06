sub Mojo::Webqq::Model::get_single_long_nick{
    my $self = shift;
    my $uin = shift;
    
    my $api_url = 'http://s.web2.qq.com/api/get_single_long_nick2';
    my $headers  = {Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',json=>1};
    my @query_string = (
        tuin            =>  $uin,
        vfwebqq         =>  $self->vfwebqq,
        t               =>  time,
    ); 
    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    return undef if $json->{retcode} !=0;
    #{"retcode":0,"result":[{"uin":308165330,"lnick":""}]}
    my $single_long_nick = $json->{result}[0]{lnick};
    return $single_long_nick;
}
1;
