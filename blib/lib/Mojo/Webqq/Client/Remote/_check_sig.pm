sub Mojo::Webqq::Client::_check_sig {
    my $self = shift;
    $self->info("检查安全代码...\n");
    my $api_url = $self->api_check_sig;  
    my $content = $self->http_get($api_url,{ua_debug_body=>0});
    return 0 unless defined $content;
    return 1;
}
1;
