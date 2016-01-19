package Mojo::Webqq::Plugin::PostImgVerifycode;
our $PRIORITY = 0;
our $CALL_ON_LOAD = 1;
use MIME::Base64;
BEGIN{
    our $has_mime_lite = 0;
    eval{require MIME::Lite;};
    $has_mime_lite = 1 if not $@;
}
sub call {
    my $client = shift;
    my $data   = shift;
    $client->die("插件[". __PACKAGE__ ."]依赖模块 MIME::Lite，请先确认该模块已经正确安装") if not $has_mime_lite;
    $client->on(input_img_verifycode=>sub{
        my($client,$filename) = @_;
        $client->die("插件[".__PACKAGE__."]必须设置提交验证码本机地址") unless defined $data->{post_host};
        $data->{post_port} = "3000" unless defined $data->{post_port};
        my $subject = $data->{subject} || "QQ帐号 " . $client->qq . " 登录验证码";
        my $mime = MIME::Lite->new(
            Type    => 'multipart/mixed',
            From    => $data->{from},
            To      => $data->{to},
        );
        $mime->add("Subject"=>"=?UTF-8?B?" . MIME::Base64::encode_base64($subject,"") . "?=");
        $mime->attach(
            Type     =>'TEXT',
            Data     =>"请点击以下链接输入验证码: http://$data->{post_host}:$data->{post_port}/check_code"
        );
        $mime->attach(
            Path        => $filename,
            Disposition => 'attachment',
            Type        => 'image/jpeg',
        ); 
        my ($is_success,$err) = $client->mail(
            smtp=>$data->{smtp},
            port=>$data->{port},
            user=>$data->{user},
            pass=>$data->{pass},
            from=>$data->{from},
            to  =>$data->{to}, 
            subject=>$subject,
            data=>$mime->as_string,
        );
        if(not $is_success){
            $client->error("插件[".__PACKAGE__."]邮件发送失败: $err");
            return;
        }
        package Mojo::Webqq::Plugin::PostImgVerifycode::App;
        use Encode;
        use Mojolicious::Lite;
        use File::Basename qw(basename);
        my $img_path = basename($filename);
        my $img_data = '';
        open my $img_handle,$filename or die $!;
        while((read $img_handle,my $buf,4096)!=0){
            $img_data .= $buf;
        }
        close $img_handle;
        get '/check_code' => sub{
        my $template = <<"TEMPLATE";
            <html>
            <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
            </head>
            <body>
                <form action="/post_code" method="get">
                    <div><img src="/$img_path"></img></div>
                    <nobr>验证码：</nobr>
                    <input type="text" maxlength="4" size="4" name="code"></input>
                    <input type="submit"></input>
                </form>
            </body>
            </html>
TEMPLATE
            $_[0]->render(text => $template);
        };
        get "/$img_path" => sub{$_[0]->render(data=>$img_data,format=>'image/jpg')};
        get '/post_code' => sub{
            my $code=$_[0]->param("code") || ""; $client->verifycode($code) if defined $code;
            $_[0]->render(text => "您的验证码已经提交: $code");
            $client->debug(encode("utf8","插件[Mojo::Webqq::Plugin::PostImgVerifycode]获取到登录验证码为: $code"));
        };
        package Mojo::Webqq::Plugin::PostImgVerifycode;
        use Mojo::IOLoop;
        use Mojo::Webqq::Server;
        my $server = Mojo::Webqq::Server->new(ioloop=>Mojo::IOLoop->new);
        $server->app($server->build_app("Mojo::Webqq::Plugin::PostImgVerifycode::App"));
        $server->app->secrets("hello world");
        $server->app->log($client->log);
        $server->app->hook(after_render => sub {
            my ($c, $output, $format) = @_;
            if($c->req->url->path eq '/post_code'){
                $server->stop;
                $server->ioloop->stop;
                undef $server;
            }
        });
        #$server->listen([{host=>$data->{post_host},port=>$data->{post_port}}]);
        $server->listen(["http://$data->{post_host}:$data->{post_port}"  ,]);
        $server->run;
    });
}
1;
