package Mojo::Webqq::Message::Recv::StateMessage;
use strict;
use Mojo::Base;
use base qw(Mojo::Base);
sub has { Mojo::Base::attr( __PACKAGE__, @_ ) };

has type         => "state_message";
has msg_class    => "recv";
has msg_from     => "none";
has allow_plugin => 1;
has [qw(id state client_type)];

sub dump{
    my $self = shift;
    my $clone = {};
    my $obj_name = blessed($self);
    for(keys %$self){
        next if $_ eq "_client";
        if(my $n=blessed($self->{$_})){
             $clone->{$_} = "Object($n)";
        }
        elsif($_ eq "member" and ref($self->{$_}) eq "ARRAY"){
            my $member_count = @{$self->{$_}};
            $clone->{$_} = [ "$member_count of Object(${obj_name}::Member)" ];
        }
        else{
            $clone->{$_} = $self->{$_};
        }
    }
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    $self->{_client}->print("Object($obj_name) " . Data::Dumper::Dumper($clone));
    return $self;
}

1;
