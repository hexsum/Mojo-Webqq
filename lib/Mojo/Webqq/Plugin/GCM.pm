package Mojo::Webqq::Plugin::GCM;
our $AUTHOR = 'sjdy521@163.com';
our $SITE = '';
our $DESC = '接收消息通过谷歌提供的GCM接口发送到android手机';
our $PRIORITY = 97;
use List::Util qw(first);
sub call {
    my $client = shift;
    my $data  = shift;
    my $api_url = $data->{api_url} // 'https://gcm-http.googleapis.com/gcm/send';
    my $api_key = $data->{api_key} or $client->die("[".__PACKAGE__."]必须指定api_key");
    my $collapse_key = $data->{collapse_key};
    my $registration_ids = $data->{registration_ids} // [];
    if(ref $registration_ids ne 'ARRAY' or @{$registration_ids} == 0){
        $client->die("[".__PACKAGE__."]registration_ids无效");
    }
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        my $title;
        my $message;
        if($msg->type eq 'friend_message'){
            $title = $msg->sender->displayname;
            $message = $msg->content;
        }
        elsif($msg->type eq 'group_message'){
            return if ref $data->{ban_group}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->displayname eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->displayname eq $_} @{$data->{allow_group}};
            $title = $msg->group->displayname;
            $message = $msg->sender->displayname . ": " . $msg->content;
        }
        elsif($msg->type eq 'discuss_message'){
            return if ref $data->{ban_discuss}  eq "ARRAY" and first {$_=~/^\d+$/?$msg->discuss->uid eq $_:$msg->discuss->displayname eq $_} @{$data->{ban_discuss}};
            return if ref $data->{allow_discuss}  eq "ARRAY" and !first {$_=~/^\d+$/?$msg->discuss->uid eq $_:$msg->discuss->displayname eq $_} @{$data->{allow_discuss}};
            $title = $msg->discuss->displayname;
            $message = $msg->sender->displayname . ": " . $msg->content;
        }
        elsif($msg->type eq 'sess_message'){
            
        }
        return if !$title or !$message;
        $client->http_post($api_url, 
            {'Authorization'=>"key=$api_key",},
            json=>{
                registration_ids=> $registration_ids,
                $collapse_key?(collapse_key=> $collapse_key):(),
                data=>{type=>$data->{type} // 'Mojo-Webqq',title=>$title,message=>$message},
            },
            sub{
                #"{"multicast_id":9016211065189210367,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1484103730761325%9b9e6c13f9fd7ecd"}]}"
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]GCM消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]GCM消息推送完成：$json->{multicast_id}/$json->{success}/$json->{failure}");
                }
            }
        );
    });
}
1;
