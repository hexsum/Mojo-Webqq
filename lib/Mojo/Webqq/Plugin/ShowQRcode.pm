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
                 if($^O=~/win/i)
                 {
   	                $command="start $qrcode_path";
   	                eval(system($command));
                    $self->error($@) if $@;
                 }
                 elsif($^O=~/linux/i)
                 {
                 }
              }
        );
}


1;
