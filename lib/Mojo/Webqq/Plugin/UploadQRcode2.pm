package Mojo::Webqq::Plugin::UploadQRcode2;
our $CALL_ON_LOAD=1;
use strict;
use Mojo::Util ();
use Time::HiRes ();
use Digest::SHA ();
sub call{
    my $client = shift;
    my $data = shift;
    $client->on(input_qrcode=>sub{
        my($client,$qrcode_path,$qrcode_data) = @_;
        #需要产生随机的云存储路径，防止好像干扰
        my $uniq_path = "mojo_webqq_" .  substr(Time::HiRes::gettimeofday(),4) .  sprintf("%.6f",rand(1)) . ".png";
        my $url = upload($client,$data,$uniq_path,$qrcode_data);
        return if not defined $url;
        $client->qrcode_upload_url($url);
        $client->info("二维码已上传云存储[ $url ]");
    });
}

sub upload {
    my($client,$opt,$name,$data) = @_;
    my $mydomain  = $opt->{mydomain} // "qr.perfi.wang";
    my $appid = $opt->{appid} // 10063136;
    my $bucket = $opt->{bucket} // 'qr';
    my $secretid = $opt->{secretid} // 'AKIDGfoZzPrHrWW98rqFbCF5EHP0DenTqO4N';
    my $secretkey = $opt->{secretkey} // 'eT2sPJnvXQ3IGF4yaaBLGkOXDVAsEqlo';
    my $now = time;
    my $expire = $opt->{expire} // 120;
    $expire = $now + $expire;
    my $rand = int rand 1000000;

    my $fileid = Mojo::Util::url_escape("/$appid/$bucket/$name");
    $fileid=~s/%2F/\//g;
    my $orignal = "a=$appid&b=$bucket&k=$secretid&e=$expire&t=$now&r=$rand&f=$fileid";
    my $signtemp = Digest::SHA::hmac_sha1($orignal,$secretkey);
    my $sign = Mojo::Util::b64_encode($signtemp . $orignal,"");

    my $json = $client->http_post("http://web.file.myqcloud.com/files/v1/$appid/$bucket/$name",
        { Authorization=>$sign, json=>1 ,ua_debug_req_body=>0},
        form=>{
            op=>'upload',
            insertOnly=>1,
            filecontent=>{filename=>$name,content=>$data},
        }
    );
    if(not defined $json){
        $client->warn("二维码图片上传云存储失败: 响应数据异常");
        return;
    }
    elsif(defined $json and $json->{code} != 0 ){
        $client->warn("二维码图片上传云存储失败: " . $json->{message});
        return;
    }
    
    my $url = $json->{data}{source_url};
    $url=~s/(^https?:\/\/)([^\/]+)(.*)/$1$mydomain$3/ if (defined $url and defined $mydomain);
    if(not defined $url){
        $client->warn("二维码图片上传云存储失败：未获取到有效地址");
        return;
    }
    return $url;
}
1;
