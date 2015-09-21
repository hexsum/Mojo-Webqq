package Mojo::Webqq::Message::Send::SessMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Message::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) }

has type         => "sess_message";
has msg_class    => "send";
has msg_from     => "none";
has ttl          => 5;
has allow_plugin => 1;
has msg_time     => sub {time};
has [qw(
    msg_id 
    sess_sig 
    group_id 
    discuss_id 
    sender_id 
    receiver_id 
    sender 
    receiver 
    group 
    discuss 
    content 
    raw_content 
    via 
    cb
)];

sub text {
    my $self = shift;
    return $self->content if ref $self->raw_content ne "ARRAY";
    return join "",map{$_->{content}} grep {$_->{type} eq "txt"} @{$self->{raw_content}};
}
1;
