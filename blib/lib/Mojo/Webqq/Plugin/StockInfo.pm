package Mojo::Webqq::Plugin::StockInfo;
$Mojo::Webqq::Plugin::StockInfo::PRIORITY = 95;
use strict;
use 5.010;
use Encode;

sub call{
    my $client = shift ;
    my $data  = shift;
    $client->on(receive_message => sub {
        my($client,$msg)=@_;
        return unless $msg->allow_plugin;
        return unless $msg->content =~ /^gp\s+(.*)$/ or $msg->content =~ /^股票\s+(.*)$/;
        $msg->allow_plugin(0);

        my $stockid = stockid_convert($1); 
        return unless defined $stockid;
        
        my $url="http://qt.gtimg.cn/q=$stockid";
        $client->http_get($url,sub{
            my $res = shift;
            $res = encode("utf8",decode("gbk",$res));
            my $reply_msg = stockinfo_convert($res);
            $client->reply_message($msg,$reply_msg);       
	})
 
    });
}

sub stockid_convert{
    my $info = shift;
### $info
    my $stockid;
    if(  $info =~ /^(\d\d\d)(\d\d\d)/ ){   
        my $stockid_head_num = "$1";
        my $stockid_tail_num = "$2";
        my @sz=qw/000 001 002 031 038 131 150 159 160 161 162 163 164 165 166 167 169 184 200 300/;
        my @sh=qw/201 202 203 204 500 502 505 510 511 512 513 518 580 600 601 603 900/;
        my $stockid_site;
        if( grep {$_ =~ /^$stockid_head_num$/ }@sz)
        {
            $stockid_site="sz";
        }elsif ( grep {$_ =~ /^$stockid_head_num$/ }@sh ) {
            $stockid_site="sh";
        }else{
           print "不属于股票id(${stockid_head_num}${stockid_tail_num})\n";
           return undef;
        }
        $stockid = "$stockid_site"."$stockid_head_num"."$stockid_tail_num";
    }else{
        return undef;
    }
    return $stockid;
}
sub stockinfo_convert{

    my $res = shift;
### $res 
    (
    undef,
    my $name,             #名称
    my $code,             #代码
    #3-5
    my $current_price,    #当前价格
    my $yesterday_price,  #昨日收盘
    my $today_open_price, #今日开盘
    #6-8 
    my $totalNumber, #成交量
    my $outNumber,   #外盘
    my $innerNumber, #内盘
    
    #9~18
    my $buy1,
    my $buyPrice1,
    my $buy2,
    my $buyPrice2,
    my $buy3,
    my $buyPrice3,
    my $buy4,
    my $buyPrice4,
    my $buy5,
    my $buyPrice5,
    
    #19~28
    my $sell1,
    my $sellPrice1,
    my $sell2,
    my $sellPrice2,
    my $sell3,
    my $sellPrice3,
    my $sell4,
    my $sellPrice4,
    my $sell5,
    my $sellPrice5,
    undef,
    my $CurrentTime,
    my $UpdownPrice,
    my $UpdownPercent,
    my $HighPrice,
    my $LowPrice,
    undef,
    undef,
    my $totalMony,
    my $changePercent,
    my $shiYing,
    undef,
    undef,
    undef,
    my $zhenFu,
    ) = split /~/,$res;
    my $reply;
    $reply .= "股票名称:   $name($code)\n";
    $reply .= "------------------------\n";
    $reply .= "当前价格:$current_price\t开盘价格:$today_open_price\t昨日收盘:$yesterday_price\n";
    $reply .= sprintf  "幅度    :%-15s换手率  :%-17s\n",$UpdownPercent."%",$changePercent."%";
    $reply .= "成交量  :$totalNumber\n";
    $reply .= "------------------------\n";
    $reply .= sprintf "买一    :%-8s  %-5s卖一    :%-8s  %-5s\n",$buy1,$buyPrice1,$sell1,$sellPrice1;
    $reply .= sprintf "买二    :%-8s  %-5s卖二    :%-8s  %-5s\n",$buy2,$buyPrice2,$sell2,$sellPrice2;
    $reply .= sprintf "买三    :%-8s  %-5s卖三    :%-8s  %-5s\n",$buy3,$buyPrice3,$sell3,$sellPrice3;
    $reply .= sprintf "买四    :%-8s  %-5s卖四    :%-8s  %-5s\n",$buy4,$buyPrice4,$sell4,$sellPrice4;
    $reply .= sprintf "买五    :%-8s  %-5s卖五    :%-8s  %-5s\n",$buy5,$buyPrice5,$sell5,$sellPrice5;
    return $reply;
}
1;
