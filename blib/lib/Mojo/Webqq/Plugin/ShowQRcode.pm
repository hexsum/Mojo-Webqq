package Mojo::Webqq::Plugin::ShowQRcode;
our $PRIORITY = 0;
our $CALL_ON_LOAD=1;

sub call
{
my $client = shift;
$client->on(input_qrcode=>sub
               {
                 my($client,$qrcode_path) = @_;
                 my $command;
                 if($^O=~/^MSWin32/i) # Windows
                 {
   	                $command="start $qrcode_path";
   	                eval(system($command));
                    $client->error($@) if $@;
                 }
                 elsif($^O=~/^linux/i) # Linux
                 {
                 }
                 elsif($^O=~/^darwin/i) # Mac OS X
                 {
                    $command="open $qrcode_path";
                    eval(system($command));
                    $client->error($@) if $@;
                 }
              }
        );
}


1;
