package Mojo::Webqq::Message::Recv::StateMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has type         => "state_message";
has msg_class    => "recv";
has allow_plugin => 1;
has [qw(id state client_type)];

1;
