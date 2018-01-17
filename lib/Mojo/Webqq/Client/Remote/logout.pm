sub Mojo::Webqq::Client::logout { 
    my $self = shift;
    $self->info("正在注销...\n");
    $self->http_get($self->gen_url('https://ptlogin2.qq.com/logout',(
        pt4_token   => $self->search_cookie('pt4_token'),
        pt4_hkey    => $self->time33($self->skey),
        pt4_ptcz    => $self->hash33($self->search_cookie("ptcz")),
        deep_logout => 1
    )),{Referer => 'http://w.qq.com/'});
    #my $expire = 0 - time;
    #$self->ua->cookie_jar->add(
    #    Mojo::Cookie::Response->new(name=>"superuin",value=>undef,path=>"/",domain=>"qq.com",expires=>$expire),
    #    Mojo::Cookie::Response->new(name=>"superkey",value=>undef,path=>"/",domain=>"qq.com",expires=>$expire),
    #    Mojo::Cookie::Response->new(name=>"uin",value=>undef,path=>"/",domain=>"qq.com",expires=>$expire),
    #    Mojo::Cookie::Response->new(name=>"key",value=>undef,path=>"/",domain=>"qq.com",expires=>$expire),
    #);
    $self->ptwebqq(undef);
    $self->skey(undef);
    $self->save_cookie();
    $self->info("注销完毕\n");
    return 1;
}
1;
