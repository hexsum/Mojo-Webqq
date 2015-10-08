package Mojo::Webqq::Plugin::Perldoc;
our $PRIORITY = 96;
use Pod::Perldoc;
use Term::ANSIColor;
use Mojo::Webqq::Cache;
my $metacpan_module_api = 'http://api.metacpan.org/v0/module/';
my $metacpan_pod_api = 'http://api.metacpan.org/v0/pod/';
my $metacpan_cache  = Mojo::Webqq::Cache->new;
sub call{
    my $client = shift;
    my $data = shift;
    my $callback = sub{
        my($client,$msg)=@_;
        return if not $msg->allow_plugin;
        if($msg->content =~ /perldoc\s+-(v|f)\s+([^ ]+)/){
            $msg->allow_plugin(0);
            return if $msg->msg_class eq "send" and $msg->msg_from ne "api" and $msg->msg_from ne "irc";
            my($p,$v) = ("-$1",$2);
            $client->spawn(
                cmd  =>sub{
                    local @ARGV=($p,$v);
                    require 5;
                    exit(Pod::Perldoc->run());
                },
                exec_timeout => 5,
                exit_cb => sub {
                    my($pid,$res)=@_;
                    my $reply;
                    if($res->{exit_status}==0){
                        $reply = $client->truncate($res->{stdout},max_lines=>10,max_bytes=>2000); 
                        $reply .= "\n查看更多内容: http://perldoc.perl.org/functions/$v.html" if $p eq "-f";
                        $reply .= "\n查看更多内容: http://perldoc.perl.org/perlvar.html" if $p eq "-v";
                    }
                    elsif($res->{stderr}=~/exec of coderef failed: (.+?)\s*at /){
                        $reply = $1;
                        $reply .= "\n查看更多内容: http://perldoc.perl.org/index-functions.html" if $p eq "-f";
                        $reply .= "\n查看更多内容: http://perldoc.perl.org/perlvar.html" if $p eq "-v";
                    }
                    eval{$reply = Term::ANSIColor::colorstrip($reply);};
                    $client->reply_message($msg,$reply) if $reply;
                },
            );
        }
        elsif($msg->content =~ /perldoc\s+((\w+::)*\w+)/){
            $msg->allow_plugin(0);
            return if $msg->msg_class eq "send" and $msg->msg_from ne "api" and $msg->msg_from ne "irc";
            my $module = $1;
            my $cache  = $metacpan_cache->retrieve($module);
            if(defined $cache){
                $client->reply_message($msg,$cache->{doc});
                return;
            }
            $client->http_get($metacpan_module_api . $module,{json=>1},sub{
                my $json = shift;
                return unless defined $json;
                my $doc;
                my $code;
                if(defined $json->{code} and $json->{code} == 404){
                    $doc = "模块名称: $module ($json->{message})" ;
                    $code = 404; 
                    $metacpan_cache->store($module,{code=>$code,doc=>$doc},604800);
                    $client->reply_message($msg,$doc);
                } 
                else{
                    $code = 200;
                    my $author  =   $json->{author};
                    my $version =   $json->{version};
                    my $abstract=   $json->{abstract};
                    my $podlink     = 'https://metacpan.org/pod/' . $module; 
                    $doc = 
                        "模块: $module\n" .
                        "版本: $version\n" .
                        "作者: $author\n" .
                        "简述: $abstract\n" .
                        "链接: $podlink\n"
                    ;
                    $client->http_get($metacpan_pod_api . $module,{Accept=>"text/plain"},sub{
                        my $data = shift;
                        return unless defined $data;
                        my ($SYNOPSIS) = $data=~/^SYNOPSIS$(.*?)^[A-Za-z]+$/ms;
                        if($SYNOPSIS){
                            $doc .= "用法概要: $SYNOPSIS\n" ;
                            $doc=~s/\n+$//;
                            $doc  = $client->truncate($doc,max_bytes=>1000,max_lines=>30);
                        }
                        $metacpan_cache->store($module,{code=>$code,doc=>$doc},604800);
                        $client->reply_message($msg,$doc); 
                    });
                }
            }); 
        }
    };
    $client->on(receive_message=>$callback);
    $client->on(send_message=>$callback);
}
1;
