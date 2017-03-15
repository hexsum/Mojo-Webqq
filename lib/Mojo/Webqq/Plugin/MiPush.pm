package Mojo::Webqq::Plugin::MiPush;

our $AUTHOR = 'heipidage';
our $SITE = 'http://www.coolapk.com/apk/com.swjtu.gcmformojo';
our $DESC = '接收消息通过小米推送接口发送到android手机';
our $PRIORITY = 97;
use List::Util qw(first);
sub call {
    my $client = shift;
    my $data  = shift;
    $client->load("UploadQRcode") if !$client->is_load_plugin('UploadQRcode');
    my $api_url = $data->{api_url} // 'https://api.xmpush.xiaomi.com/v2/message/regid';
   	my $api_key = 'hdtYlfMarG6GEObzPg+JNg==';
	my $pkgname = 'com.swjtu.gcmformojo';
	my $registration_id = $data->{registration_ids} // [];
    if(ref $registration_id ne 'ARRAY' or @{$registration_id} == 0){
        $client->die("[".__PACKAGE__."]registration_ids无效");
    }
	
	
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        my $type  = 'Mojo-Webqq';
        my $title;
        my $message;
        my $msgId;
        my $senderType;
        my $isAt = 0;
		
        if($msg->is_at) {
        $isAt=1;
        }
        if($msg->type eq 'friend_message'){
            $msgId = $msg->sender->id;
            $title = $msg->sender->displayname;
            $message = $msg->content;
            $senderType = '1';
        }
        elsif($msg->type eq 'group_message'){
         if(!$isAt)  {
            return if ref $data->{ban_group}  eq "ARRAY" and @{$data->{ban_group}} and first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->displayname eq $_} @{$data->{ban_group}};
            return if ref $data->{allow_group}  eq "ARRAY" and  @{$data->{allow_group}} and !first {$_=~/^\d+$/?$msg->group->uid eq $_:$msg->group->displayname eq $_} @{$data->{allow_group}};
            }
            $msgId = $msg->group->id;
            $title = $msg->group->displayname;
            $message = $msg->sender->displayname . ": " . $msg->content;
            $senderType = '2';
        }
        elsif($msg->type eq 'discuss_message'){
            return if ref $data->{ban_discuss}  eq "ARRAY" and @{$data->{ban_discuss}} and first {$_=~/^\d+$/?$msg->discuss->uid eq $_:$msg->discuss->displayname eq $_} @{$data->{ban_discuss}};
            return if ref $data->{allow_discuss}  eq "ARRAY" and @{$data->{allow_discuss}} and !first {$_=~/^\d+$/?$msg->discuss->uid eq $_:$msg->discuss->displayname eq $_} @{$data->{allow_discuss}};
            $msgId= $msg->discuss->id;
            $title = $msg->discuss->displayname;
            $message = $msg->sender->displayname . ": " . $msg->content;
            $senderType = '3';
        }
        elsif($msg->type eq 'sess_message'){
            
        }
        return if !$title or !$message;
		
		$client->http_post($api_url, 
			{'Authorization'=>"key=$api_key",
			  json=>1
			},
            form=>{
                pass_through => 1,
                registration_id => $registration_id,
                restricted_package_namee => $pkgname,
                payload=>$client->to_json({isAt=>$isAt,type=>$type,title=>$title,message=>$message,msgId=>$msgId,senderType=>$senderType}),
            },
            sub{
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]小米消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]小米消息推送状态：$json->{error}");
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

        $client->http_post($api_url,
            {   'Authorization'=>"key=$api_key",
                blocking=>1,
		json=>1,
                ua_connect_timeout=>5,
                ua_request_timeout=>5,
                ua_inactivity_timeout=>5,
                ua_retry_times=>1
            },
            form=>{
				pass_through => 1,
                registration_id => $registration_id,
                restricted_package_namee => $pkgname,
                payload=>$client->to_json({type=>$type,title=>$title,message=>$message,msgId=>$msgId}),
            },
            sub{
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]小米消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]小米消息推送状态：$json->{error}");
                }
            }
        ); 
    });
}
1;
