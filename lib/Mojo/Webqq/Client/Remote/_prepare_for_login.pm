use Mojo::Util qw(url_escape);
sub Mojo::Webqq::Client::_prepare_for_login {
    my $self = shift;
    $self->info( "初始化 " . $self->type . " 客户端参数...\n" );
    $self->http_get("http://w.qq.com/",{ua_debug_res_body=>0});
    my $api_url =
'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001';
    my $headers ={ Referer => 'http://w.qq.com/',ua_debug_res_body=>0 };
    my @global_param = qw(
      g_pt_version
      g_login_sig
      g_style
      g_mibao_css
      g_daid
      g_appid
    );

    my $regex_pattern =
        'var\s*('
      . join( "|", @global_param )
      . ')\s*=\s*encodeURIComponent\("(.*?)"\)';
    my $content = $self->http_get( $api_url, $headers);
    return 0 unless defined $content;
    my %kv = map { url_escape($_) } $content =~ /$regex_pattern/g;
    $self->$_($kv{$_}) for keys %kv;
    $self->g_login_sig($self->search_cookie("pt_login_sig")) if not $self->g_login_sig;
    return 1;
}
1;
