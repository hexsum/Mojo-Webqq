package Mojo::Webqq::Message;
use Mojo::Webqq::Base 'Mojo::Webqq::Message::Base';
has time     => sub{time};
has from     => "none";
has ttl      => 5;
has cb       => undef;
has allow_plugin => 1;
has format   => 'text';
has [qw(id via type class discuss_id sender_id receiver_id group_id content raw_content)];
has [qw(sender receiver group discuss)];
has [qw(state client_type)];
has code    => -2;
has msg     =>'未初始化';
has info    =>'未初始化';

#兼容老版本属性msg_class/msg_id/msg_time
sub AUTOLOAD {
    my $self = shift;
    if($Mojo::Webqq::Message::AUTOLOAD =~ /.*::msg_(.*)/){
        my $attr = $1;
        $self->$attr(@_);
    } 
    else{die("undefined subroutine $Mojo::Webqq::Message::AUTOLOAD");}
}

1;
