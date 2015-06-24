package Mojo::Webqq::Plugin::PostImgVerifycode;
use Encode;
sub call {
    my $client = shift;
    my $data   = shift;
    my $from      = $data->{from} || "";
    my $to        = $data->{to} || "";
    my $subject   = $data->{subject} || "";
    $client->http_get('http://1111.ip138.com/ic.asp',{Referer=>'http://www.ip138.com/'},sub{
        my ($res,$ua,$tx) = @_;
        unless($tx->success){
            $client->error("插件[ PostImgVerifycode ]获取系统IP失败");  
            return;
        }
        my $data;
        eval{
            my $d = encode("utf8",decode("utf8",$tx->res->dom->at("body > center")->text));
            if($d=~/\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]/){$data = $1}
        }
        
    });
    $client->on(input_img_verifycode=>sub{
        my($client,$filename) = @_;
    });
}
1;
