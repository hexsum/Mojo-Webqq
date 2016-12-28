package Mojo::Webqq::Plugin::PostQRcodeToTelegram;
our $PRIORITY = 0;
our $CALL_ON_LOAD = 1;
BEGIN{
    our $has_telegram = 0;
    eval{require WWW::Telegram::BotAPI;};
    $has_telegram = 1 if not $@;
}
    
sub call{
    my $client = shift;
    my $data = shift;
    $client->die("插件[". __PACKAGE__ ."]依赖模块 WWW::Telegram::BotAPI，请先确认该模块已经正确安装") if not $has_telegram;
    $client->on(input_qrcode=>sub{
        my($client,$qrcode_path) = @_;
        # Login Telegram
        my $api = WWW::Telegram::BotAPI->new (
            token => $data->{API_KEY}
        );
        # Send photo
        my $response = $api->sendPhoto ({
            chat_id => $data->{CHAT_ID},
            photo   => {
                file => $qrcode_path
            },
            caption => "QQ帐号" . (defined $client->uid?$client->uid:$client->account) . "扫描二维码"
        });
        # Check response
        if (!$response->{"ok"}) {
            $client->info("二维码发送至Telegram失败！");
            return
        }
        my $chat = $response->{"result"}->{"chat"};
        my $chat_type = $chat->{"type"};
        # Check response types: private, group, supergroup or channel
        if ($chat_type eq "private") {
            $client->info("二维码已发给Telegram用户[ ". $chat->{"username"} . " ]");
        } 
        elsif ($chat_type eq "group" or $chat_type eq "supergroup") {
            $client->info("二维码已发至Telegram群组[ ". $chat->{"title"} . " ]");
        }
        elsif ($chat_type eq "channel") {
            $client->info("二维码已发至Telegram频道[ ". $chat->{"title"} . " ]");
        } else {
            $client->info("二维码已发送，目标未知");
        }
    });
}
1;
