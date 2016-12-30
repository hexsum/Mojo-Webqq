package Mojo::Webqq::Plugin::PostQRcodeToTelegram;
our $PRIORITY = 0;
our $CALL_ON_LOAD = 1;

sub call{
    my $client = shift;
    my $data = shift;
    $client->on(input_qrcode=>sub{
        my($client,$qrcode_path) = @_;
        # Generate Telegram Bot API URL
        my $telegram_api = 'https://api.telegram.org/bot' . $data->{api_key} .'/sendPhoto';
        my $response = $client->http_post($telegram_api,{json=>1},form=>{
            chat_id => $data->{chat_id},
            caption => 'QQ帐号' .(defined $client->uid?$client->uid:$client->account) .'登录二维码',
            photo=>{file=>$qrcode_path}
        });

        if(not defined $response){
            $client->warn("插件[".__PACKAGE__ . "]发送登录二维码失败，响应数据异常"); 
            return
        }

        if (not $response->{"ok"}) {
            $client->warn("插件[".__PACKAGE__ . "]发送登录二维码失败"); 
            return
        }
        my $chat = $response->{"result"}->{"chat"};
        my $chat_type = $chat->{"type"};
        # Check response types: private, group, supergroup or channel
        if ($chat_type eq "private") {
            $client->info("插件[".__PACKAGE__ . "]二维码已发送给Telegram用户[ ". $chat->{"username"} . " ]");
        } 
        elsif ($chat_type eq "group" or $chat_type eq "supergroup") {
            $client->info("插件[".__PACKAGE__ . "]二维码已发送至Telegram群组[ ". $chat->{"title"} . " ]");
        }
        elsif ($chat_type eq "channel") {
            $client->info("插件[".__PACKAGE__ . "]二维码已发送至Telegram频道[ ". $chat->{"title"} . " ]");
        } else {
            $client->info("插件[".__PACKAGE__ . "]二维码已发送，目标未知");
        }
    });
}
1;
