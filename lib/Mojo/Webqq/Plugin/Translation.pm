package Mojo::Webqq::Plugin::Translation;
use strict;
use Mojo::Util qw(url_escape encode);
our $PRIORITY = 93;
sub call {
    my ($client,$data) = @_;
    my $api = 'http://apis.baidu.com/apistore/tranlateservice/translate';
    my $apikey = '20d7db97e337ffa35ae0838439c9db5d';
    my $callback = sub{
        my($client,$msg) = @_;
        return if not $msg->allow_plugin;
        return if $msg->msg_class eq "send" and $msg->msg_from ne "api" and $msg->msg_from ne "irc";
        if($msg->content =~ /^翻译\s+(.*)/s){
            my $query = $1;
            return if not $query;
            $msg->allow_plugin(0);
            my @query_string = (
                query => url_escape($query),
                from  => 'auto',
                to    => 'auto',
            );
            $client->http_get($client->gen_url($api,@query_string),{apikey=>$apikey,json=>1},sub{
                my $json = shift;
                if( not defined $json ){$msg->reply("翻译失败: api接口不可用")}
                elsif(defined $json and $json->{errNum} == 0){
                    $msg->reply( encode('utf8',join('',map {$_->{dst}} @{$json->{retData}{trans_result}}) ) ); 
                }
                elsif(defined $json){
                    $msg->reply("翻译失败: " . encode('utf8',$json->{errMsg} . "(" . $json->{errNum} . ")"));
                }
            });
        } 
    };
    $client->on(receive_message=>$callback,send_message=>$callback);  
}
1;
