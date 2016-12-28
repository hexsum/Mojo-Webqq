package Mojo::Webqq::Plugin::Pu;
$Mojo::Webqq::Plugin::Pu::PRIORITY = 1;
BEGIN{
    eval{require ZHOUYI::ZhanPu};
    our $is_hold_module = 1 unless $@;
}
use Mojo::Util qw();
sub call {
    my $client = shift;
    $client->die(__PACKAGE__ . '依赖ZHOUYI::ZhanPu模块，请先通过命令"cpanm ZHOUYI::ZhanPu"安装') if !$is_hold_module;
    $client->on(receive_message=>sub{
        my($client,$msg)=@_;
        return if not $msg->allow_plugin;
        return if $msg->content !~ /(周\s*易|占\s*卜|八\s*卦|算\s*命)/;
        $msg->allow_plugin(0);
        my $reply;
        eval{$reply = Mojo::Util::encode("utf8",ZHOUYI::ZhanPu::pu()); };
        $client->error( __PACKAGE__ . $@);
        $msg->reply($reply,sub{$_[1]->from("bot")}) if $reply;
    });
}
1;
