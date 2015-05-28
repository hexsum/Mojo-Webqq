package Mojo::Webqq::Message::Recv::DiscussMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has type         => "discuss_message";
has msg_class    => "recv";
has ttl          => 5;
has allow_plugin => 1;
has [qw(msg_id discuss_id sender_id msg_time sender discuss content raw_content)];
1;
