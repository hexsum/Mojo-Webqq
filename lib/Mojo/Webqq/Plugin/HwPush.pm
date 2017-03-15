package Mojo::Webqq::Plugin::HwPush;

our $AUTHOR = 'heipidage';
our $SITE = 'http://www.coolapk.com/apk/com.swjtu.gcmformojo';
our $DESC = '接收消息通过华为推送接口发送到android手机';
our $PRIORITY = 97;
use List::Util qw(first);
sub call {
    my $client = shift;
    my $data  = shift;
    $client->load("UploadQRcode") if !$client->is_load_plugin('UploadQRcode');
    my $api_url = $data->{api_url} // 'https://api.vmall.com/rest.php';
    my $hwfile  = $data->{hwfile} // 'hw_access_token_gcm.txt';
    my $access_token;
	
	my $deviceToken = $data->{registration_ids} // [];
    if(ref $deviceToken ne 'ARRAY' or @{$deviceToken} == 0){
        $client->die("[".__PACKAGE__."]registration_ids无效");
    }
	
	if(!open(my $fh ,$hwfile)) {
 		my $getHwToken = $client->http_get('https://raw.githubusercontent.com/heipidage/HwPushForMojo/master/hw_access_token_gcm.txt');
		if($getHwToken)  {
		open(my $fhw, '>',$hwfile) or die "Could not open file '$hwfile' $!";
                print $fhw $getHwToken;
                close($fhw);
		$access_token = $getHwToken;
		}
	}else{
		my @lines = <$fh> ;
		close($fh);
		$access_token = $lines[0];
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
		
		
		
		my $result=$client->http_post($api_url, {json=>1},
            form=>{
                nsp_fmt => JSON,
                deviceToken => $deviceToken,
                push_type => 1,
				access_token => $access_token,
				priority => 1,
				cacheMode => 0,
				msgType => 1,
				nsp_svc => 'openpush.message.single_send',
				nsp_ts => time(),
                message=>$client->to_json({isAt=>$isAt,type=>$type,title=>$title,message=>$message,msgId=>$msgId,senderType=>$senderType}),
            },
            sub{
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]华为消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]华为消息推送状态：$json->{error}");
                }
            }
		);
		
		
		
        if($result->{error} eq 'invalid session') {	
			my $newtokenres = $client->http_get('https://raw.githubusercontent.com/heipidage/HwPushForMojo/master/hw_access_token_gcm.txt');
            if($newtokenres)  {
                open(my $fhw, '>',$hwfile) or die "Could not open file '$hwfile' $!";
                print $fhw $newtokenres;
                close($fhw);
                $access_token = $newtokenres;		
				$client->http_post($api_url, {json=>1},
					form=>{
					nsp_fmt => JSON,
					deviceToken => $deviceToken,
					push_type => 1,
					access_token => $access_token,
					priority => 1,
					cacheMode => 0,
					msgType => 1,
					nsp_svc => 'openpush.message.single_send',
					nsp_ts => time(),
					message=>$client->to_json({isAt=>$isAt,type=>$type,title=>$title,message=>$message,msgId=>$msgId,senderType=>$senderType}),
					},
						sub{
							my $new_json = shift;
							if(not defined $new_json){
								$client->debug("[".__PACKAGE__."]华为消息推送失败: 返回结果异常");
								return;
							}
							else{
								$client->debug("[".__PACKAGE__."]华为消息推送状态：$new_json->{error}");
							}
						}
				);

            } else {
                print "HwPush HTTP GET Github Token error message.\n";
            }
        }   	
		
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
            {   json=>1,
                blocking=>1,
                ua_connect_timeout=>5,
                ua_request_timeout=>5,
                ua_inactivity_timeout=>5,
                ua_retry_times=>1
            },
			form=>{
					nsp_fmt => JSON,
					deviceToken => $deviceToken,
					push_type => 1,
					access_token => $access_token,
					priority => 1,
					cacheMode => 0,
					msgType => 1,
					nsp_svc => 'openpush.message.single_send',
					nsp_ts => time(),
					message=>$client->to_json({type=>$type,title=>$title,message=>$message,msgId=>$msgId}),
					},
            sub{
                my $json = shift;
                if(not defined $json){
                    $client->debug("[".__PACKAGE__."]华为消息推送失败: 返回结果异常");
                    return;
                }
                else{
                    $client->debug("[".__PACKAGE__."]华为消息推送状态：$json->{error}");
                }
            }
        ); 
		
		
		
		
		
		
    });
}
1;

