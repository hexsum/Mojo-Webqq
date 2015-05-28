package Mojo::Webqq::Message::Send::GroupMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has type         => "group_message";
has msg_class    => "send";
has ttl          => 5;
has allow_plugin => 1;
has msg_time     => sub{time};
has [qw(msg_id group_id sender_id receiver_id sender receiver group content raw_content cb)];

1;
