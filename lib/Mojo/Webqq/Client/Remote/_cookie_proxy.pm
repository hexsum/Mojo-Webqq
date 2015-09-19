sub Mojo::Webqq::Client::_cookie_proxy {
    my $self = shift;
    my $p_skey = $self->search_cookie("p_skey");
    my $p_uin = $self->search_cookie("p_uin");
    $self->ua->cookie_jar->add(
        Mojo::Cookie::Response->new(
            name    => "p_skey",
            value   => $p_skey,
            domain  => "w.qq.com",
            path    => "/",
        ),
        Mojo::Cookie::Response->new(
            name    => "p_uin",
            value   => $p_uin,
            domain  => "w.qq.com",
            path    => "/",
        ),
    ) if defined $p_skey and defined $p_uin;
    $self->save_cookie();
    return 1;
};
1;
