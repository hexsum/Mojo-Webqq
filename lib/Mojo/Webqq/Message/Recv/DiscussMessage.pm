package Mojo::Webqq::Message::Recv::DiscussMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has type         => "discuss_message";
has msg_class    => "recv";
has msg_from     => "none";
has ttl          => 5;
has allow_plugin => 1;
has msg_time     => sub{time};
has [qw(msg_id discuss_id sender_id receiver_id sender receiver discuss content raw_content)];

1;
