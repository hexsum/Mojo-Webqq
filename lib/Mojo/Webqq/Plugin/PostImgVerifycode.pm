package Mojo::Webqq::PostImgVerifycode;
sub call {
    my $client = shift;
    my $data   = shift;
    my $api = $data->{api} || "http://sendcloud.sohu.com/webapi/mail.send.json";
    my $api_user  = $data->{api_user} || "mojo_webqq";
    my $api_key   = $data->{api_key} || "RRXGiR4sN17jDStf";
    my $from      = $data->{from} || "";
    my $from_name = $data->{from_name} | "";
    my $to        = $data->{to} || "";
    my $subject   = $data->{subject} || "";
    $client->on(input_img_verifycode=>sub{
        my($client,$filename) = @_;
         
    });
}
1;
