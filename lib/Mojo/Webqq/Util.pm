package Mojo::Webqq::Util;
use Mojo::Webqq::Counter;
sub new_counter {
    my $self = shift;
    return Mojo::Webqq::Counter->new(client=>$self,@_);
}
1;
