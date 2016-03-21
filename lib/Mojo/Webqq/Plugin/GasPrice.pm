package Mojo::Webqq::Plugin::GasPrice;
use strict;
use POSIX qw(strftime);
use Encode;
use Mojo::Util qw(url_escape);
use List::Util qw(first);
our $PRIORITY = 91;
my $API = 'http://apis.baidu.com/showapi_open_bus/oil_price/find?prov=';

sub call{
	#获取qqClient
    my $client = shift;
	#获取加载该插件时候传入的参数数组
    my $data   = shift;

	#如果参数有传是否需要@才进行回复，如果么有，则默认需要@才回复
	my $is_need_at = defined $data->{is_need_at} ? $data->{is_need_at}:0;
	my $key_word   = defined $data->{command} ? $data->{command}:'油价';
	my $msg_tail   = defined $data->{msg_tail} ? $data->{msg_tail}:'';

	my $callBack = sub{
		my($client,$msg)=@_;

		#如果消息中设定不允许插件处理，则直接返回
		return if( not $msg->allow_plugin );
		#只处理 好友消息|群消息|临时消息
        return if( $msg->type !~ /^message|group_message|sess_message$/ );
		#如果设置了需要@ 且消息类型是群消息，则判断消息中是否有@，如果没有则直接返回
        return if( $is_need_at and $msg->type eq "group_message" and !$msg->is_at );

		#或者发送者和接受者的昵称
        my $sender_nick = $msg->sender->displayname;
        my $user_nick   = $msg->receiver->displayname;

		#如果是群消息，则判断是否有设置禁止群和允许群（设置是由load插件的时候传入的参数设置）
		if($msg->type eq 'group_message'){
			return if( ref $data->{ban_group} eq "ARRAY" and first { $_ =~ /^\d+$/ ? $msg->group->gnumber eq $_ : $msg->group->gname eq $_} @{$data->{ban_group}} );
            return if( ref $data->{allow_group} eq "ARRAY" and !first { $_ =~ /^\d+$/ ? $msg->group->gnumber eq $_ : $msg->group->gname eq $_} @{$data->{allow_group}} );
		}

		#获取接受消息的内容
		my $input = $msg->content;
		#把前面的@昵称去掉
        $input=~s/\@\Q$user_nick\E ?|\[[^\[\]]+\]\x01|\[[^\[\]]+\]//g;
		#如果去掉昵称后，收到的消息内容为空，则不用处理，直接返回
        return unless $input;
		my @ARGVS = split(/\s+/,$input);

        #这里设置需要获取的关键字，如果得到的不是所需关键字，则不处理，直接返回
        return if($ARGVS[0] ne $key_word);
		#如果匹配了关键字，即属于该插件处理的消息，设置该消息不允许其他插件处理
		$msg->allow_plugin(0);

        my $prov = $ARGVS[1] ? url_escape($ARGVS[1]) : url_escape("广东");

		my $headers = {
        	apikey => '4febc94b54b90f8cc8090af772c25a21',#api key
        	json     => 1,
    	};

		#使用http_get从API获取所需信息
		$client->http_get($API.$prov,$headers,sub{
			my $json = shift;
            return unless defined $json;
			my $resultArray = $json->{showapi_res_body}->{list};
			return if scalar(@$resultArray) <= 0 ;
            my $ct = encode("utf8",$resultArray->[0]->{ct});
            my $p0 = encode("utf8",$resultArray->[0]->{p0});
            my $p90 = encode("utf8",$resultArray->[0]->{p90});
            my $p93 = encode("utf8",$resultArray->[0]->{p93});
            my $p97 = encode("utf8",$resultArray->[0]->{p97});
            my $prov = encode("utf8",$resultArray->[0]->{prov});
            my $reply = "您好！".$prov."的油价情况如下:\n\t发布时间:".$ct."\n\t"
						. "0#:".$p0."\n\t"
						. "90#:".$p90."\n\t"
						. "93#:".$p93."\n\t"
						. "97#:".$p97;
			$reply  = "\@$sender_nick " . $reply  if $msg->type eq 'group_message';
			$client->reply_message($msg,$reply,sub{
				my($client,$msg) = @_;
    			my $content = $msg->content;
    			$content .= $msg_tail;
    			$msg->content($content);
				$msg->msg_from("bot");}) if $reply;
        });
	};
	$client->on(receive_message=>$callBack);
}
1;
