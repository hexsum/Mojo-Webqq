package Mojo::Webqq::Plugin::ReadQR;
our $PRIORITY = 0;
our $CALL_ON_LOAD=1;

sub call
{
my $client = shift;
$client->on(input_qrcode=>sub
               {
                 my($client,$qrcode_path) = @_;
                 my $command;
                 if($^O=~/Win/)
                 {
   	                $command="start $qrcode_path";
   	                print "command is ready to run\n";
   	                eval(system($command));
                 }
                 elsif($^O=~/linux/)
                 {
                 	$command="open $qrcode_path";
   	                print "command is ready to run\n";
   	                eval(system($command));
                 	
                 }
              }
        );
}


1;
