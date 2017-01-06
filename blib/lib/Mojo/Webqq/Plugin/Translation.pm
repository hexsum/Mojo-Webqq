package Mojo::Webqq::Plugin::Translation;
use strict;
use Mojo::Util qw(url_escape encode md5_sum decode);
our $PRIORITY = 93;
sub call {
    my ($client,$data) = @_;
    my $api = 'http://api.fanyi.baidu.com/api/trans/vip/translate';
    my $appid = $data->{appid} || '20160516000021158';
    my $appsecret = $data->{appsecret} || '2QoSmvMuun8btJmsl446';
    my $callback = sub{
        my($client,$msg) = @_;
        return if not $msg->allow_plugin;
        return if $msg->class eq "send" and $msg->from ne "api" and $msg->from ne "irc";
        if($msg->content =~ /^翻译\s+(.*)/s){
            my $query = $1;
            return if not $query;
            $msg->allow_plugin(0);
            my $salt = time;
            $client->http_get($api,{json=>1},form=>{
                q     => $query,
                from  => 'auto',
                to    => 'auto',
                appid => $appid,
                salt  => $salt,
                sign  => md5_sum($appid . $query . $salt . $appsecret),
            },sub{
                my $json = shift;
                if( not defined $json ){$msg->reply("翻译失败: api接口不可用")}
                elsif(defined $json and exists $json->{error_code}){
                    $msg->reply("翻译失败: api接口不可用(" . $json->{error_code} . " " . $json->{error_msg} . ")"); 
                }
                elsif(defined $json){
                    $msg->reply( join " ",map {$_->{dst}} @{ $json->{trans_result} } );
                }
            });
        } 
    };
    $client->on(receive_message=>$callback,send_message=>$callback);  
}
1;
