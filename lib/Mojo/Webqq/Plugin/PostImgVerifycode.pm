package Mojo::Webqq::PostImgVerifycode;
sub call {
    my $client = shift;
    my $data   = shift;
    my $from      = $data->{from} || "";
    my $from_name = $data->{from_name} | "";
    my $to        = $data->{to} || "";
    my $subject   = $data->{subject} || "";
    $client->on(input_img_verifycode=>sub{
        my($client,$filename) = @_;
    });
}
1;
