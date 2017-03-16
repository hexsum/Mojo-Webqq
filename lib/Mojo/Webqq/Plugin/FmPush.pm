package Mojo::Webqq::Plugin::FmPush;
use Mojo::Util qw(md5_sum);


our $AUTHOR = 'heipidage';
our $SITE = 'http://www.coolapk.com/apk/com.swjtu.gcmformojo';
our $DESC = '接收消息通过魅族提供的推送接口发送到android手机';
our $PRIORITY = 97;
use List::Util qw(first);
sub call {
    my $client = shift;
    my $data  = shift;
    $client->load("UploadQRcode") if !$client->is_load_plugin('UploadQRcode');
    my $api_url = $data->{api_url} // 'https://api-push.meizu.com/garcia/api/server/push/unvarnished/pushByPushId';
	my $api_key = 'eb034b0b4f42414baedaa04ddc7e6981';
	my $app_id = '110370';
	my $registration_ids = $data->{registration_ids} // [];
    if(ref $registration_ids ne 'ARRAY' or @{$registration_ids} == 0){
        $client->die("[".__PACKAGE__."]registration_ids无效");
    }
    	my $registration_id = $registration_ids->[0];

    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        my $type = 'Mojo-Webqq';
        my $title;
        my $message;
        my $msgId;
        my $senderType;
        my $isAt = 0;
		
        if($msg->is_at) {
        $isAt=1;
        }
        if($msg->type eq 'friend_message'){
            return if $data->{is_ban_official} and $msg->sender->category eq '公众号';
            $msgId = $msg->sender->id;
            $title = $msg->sender->displayname;
            $message = $msg->content;
            $senderType = '1';
        }
        elsif($msg->type eq 'group_message'){
        if(!$isAt)  {
            return if ref $data->{ban_group}  eq "ARRAY" and @{$data->{ban_group}} and first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->displayname eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and @{$data->{allow_group}} and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->displayname eq $_} @{$data->{allow_group}};
            }
            $msgId = $msg->group->id;
            $title = $msg->group->displayname;
            $message = $msg->sender->displayname . ": " . $msg->content;
            $senderType = '2';
        }
        return if !$title or !$message;
		
		my $messageJson = '{"content":"{\"isAt\":\"'.$isAt.'\",\"type\":\"'.$type.'\",\"title\":\"'.$title.'\",\"message\":\"'.$message.'\",\"msgId\":\"'.$msgId.'\",\"senderType\":\"'.$senderType.'\"}"}';
		print "appId=".$app_id."messageJson=".$messageJson."pushIds=".$registration_id.$api_key;
		my $sign = md5_sum("appId=".$app_id."messageJson=".$messageJson."pushIds=".$registration_id.$api_key);
		
		$client->http_post($api_url, 
			{ua_debug=>1,ua_debug_req_body=>1,ua_debug_res_body=>1,json=>1},
            form=>{
                appId => $app_id,
                pushIds => $registration_id,
                messageJson=>$messageJson,
				sign  => $sign,
            },
            sub{
                #"{"multicast_id":9016211065189210367,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1484103730761325%9b9e6c13f9fd7ecd"}]}"
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]魅族消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]魅族消息推送完成：$json->{multicast_id}/$json->{success}/$json->{failure}");
                }
            }
        );
    });

    $client->on(all_event => sub{
        my($client,$event,@args) =@_;
        my $type = 'Mojo-Sys';
        my $message;
        my $msgId = 1;
        my $title;
        if($event eq 'login'){
            $message = "登录成功";
            $title = "登录事件";
        }
        elsif($event eq 'input_qrcode'){
            $message = $client->qrcode_upload_url // '获取二维码url失败';
            $title = "扫描二维码事件";
        }
        elsif($event eq 'stop'){
            $message = "Mojo-Webqq已停止";
            $title = "停止事件";
        }
        else{return}
		
		my $messageJson = '{"content":"{\"type\":\"'.$type.'\",\"title\":\"'.$title.'\",\"message\":\"'.$message.'\",\"msgId\":\"'.$msgId.'\"}"}';
		
        $client->http_post($api_url,
            {  
                blocking=>1,
		json=>1,
                ua_connect_timeout=>5,
                ua_request_timeout=>5,
                ua_inactivity_timeout=>5,
                ua_retry_times=>1
            },
            form=>{
			
			    appId => $app_id,
                pushIds => $registration_id,
                messageJson=>$messageJson,
				sign  => md5_sum("appId=".$app_id."messageJson=".$messageJson."pushIds=".$registration_id.$api_key),
            
			},
            sub{
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]魅族消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]魅族消息推送完成：$json->{multicast_id}/$json->{success}/$json->{failure}");
                }
            }
        ); 
    });
}
1;
