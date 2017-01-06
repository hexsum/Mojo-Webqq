sub Mojo::Webqq::Client::logout { 
    my $self = shift;
    $self->info("正在注销...\n");
    $self->ua->cookie_jar->add(
        Mojo::Cookie::Response->new(name=>"ptwebqq",value=>undef,path=>"/",domain=>"qq.com",expires=>-1),
        Mojo::Cookie::Response->new(name=>"skey",value=>undef,path=>"/",domain=>"qq.com",expires=>-1),
    );
    $self->ptwebqq(undef);
    $self->skey(undef);
    $self->save_cookie();
    $self->info("注销完毕\n");
    return 1;
}
1;
