package Mojo::Webqq::Plugin::Pu;
$Mojo::Webqq::Plugin::Pu::PRIORITY = 1;


use ZHOUYI::ZhanPu;
use Encode;
sub call {
    my $client = shift;
    $client->on(receive_message=>sub{
        my($client,$msg)=@_;
        return if not $msg->allow_plugin;
        return if $msg->type eq "group_message" and $msg->group->gname eq "Mojolicious";
        return if $msg->content !~ /(周\s*易|占\s*卜|八\s*卦|算\s*命)/;
        my $reply = Encode::encode("utf8",pu);
        $client->reply_message($msg,$reply,sub{$_[1]->msg_from("bot")}) if $reply;
    });
}
1;
