package Mojo::Webqq::Plugin::UploadQRcode;
our $CALL_ON_LOAD=1;
use strict;
sub call{
    my $client = shift;
    my $data = shift;
    $client->on(input_qrcode=>sub{
        my($client,$qrcode_path,$qrcode_data) = @_;
        #需要产生随机的云存储路径，防止好像干扰
        my $json = $client->http_post('https://sm.ms/api/upload',{json=>1},form=>{
            format=>'json',
            smfile=>{filename=>$qrcode_path,content=>$qrcode_data},
        });
        if(not defined $json){
            $client->warn("二维码图片上传云存储失败: 响应数据异常");
            return;
        }
        elsif(defined $json and $json->{code} ne 'success' ){
            $client->warn("二维码图片上传云存储失败: " . $json->{msg});
            return;
        }
        $client->qrcode_upload_url($json->{data}{url});
        $client->info("二维码已上传云存储[ ". $json->{data}{url} . " ]");
    });
}
1;
