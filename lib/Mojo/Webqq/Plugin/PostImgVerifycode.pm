package Mojo::Webqq::Plugin::PostImgVerifycode;
use Encode;
sub call {
    my $client = shift;
    my $data   = shift;
    $client->on(input_img_verifycode=>sub{
        my($client,$filename) = @_;
    });
}
1;
