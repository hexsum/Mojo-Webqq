package Mojo::Webqq::Plugin::FuckDaShen;
$Mojo::Webqq::Plugin::FuckDaShen::PRIORITY = 1;

my @reply = (
    "动不动就叫%...",
    "%能不能换点别的称呼...",
    "%，%，%，%..喜欢你就叫个够...",
    "请问%是指哪位?",
    "能不能别随随便便就叫%?"
);
sub call {
    my $client = shift;
    $client->on(receive_message=>sub{
        my($client,$msg)=@_;
        return if not $msg->allow_plugin;
        return if $msg->content !~ /(大\s*神|大\s*婶|大\s*侠)/;
        my $key_word = $1;$key_word=~s/\s+//;
        my $reply = $reply[int rand($#reply+1)];
        $reply=~s/%/$key_word/g;
        $client->reply_message($msg,$reply,sub{$_[1]->from("bot")}) if $reply;
    });
}
1;
