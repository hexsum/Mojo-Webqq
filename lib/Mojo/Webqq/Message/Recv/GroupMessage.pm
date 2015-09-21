package Mojo::Webqq::Message::Recv::GroupMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };
has type         => "group_message";
has msg_class    => "recv";
has msg_from     => "none";
has ttl          => 5;
has allow_plugin => 1;
has [qw(msg_id group_id sender_id receiver_id sender receiver group msg_time content raw_content)];
sub text {
    my $self = shift;
    return $self->content if ref $self->raw_content ne "ARRAY";
    return join "",map{$_->{content}} grep {$_->{type} eq "txt"} @{$self->{raw_content}};
}
1;
