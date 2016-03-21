package Mojo::Webqq::Message::Recv::SessMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has type         => "sess_message";
has msg_class    => "recv";
has msg_from     => "none";
has ttl          => 5;
has allow_plugin => 1;
has msg_time     => sub{time};
has [qw(msg_id group_id discuss_id sender_id receiver_id sender group discuss receiver content raw_content via)];
1;
