package Mojo::Webqq::Message::Base;
use Data::Dumper;
use Encode qw(decode_utf8);
use Scalar::Util qw(blessed);
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

sub is_at{
    my $self = shift;
    my $object;
    my $displayname;
    if($self->msg_class eq "recv"){
        $object = shift || $self->receiver;
        $displayname = $object->displayname;
    }
    elsif($self->msg_class eq "send"){
        if($self->type eq "group"){
            $object = shift || $self->group->me;
            $displayname = $object->displayname;
        } 
        elsif($self->type eq "discuss"){
            $object = shift || $self->discuss->me;
            $displayname = $object->displayname;
        }
        elsif($self->type=~/^message|sess_message$/){
            $object = shift || $self->receiver;
            $displayname = $object->displayname;
        }
    }
    return $self->content =~/\@\Q$displayname\E ?/; 
}

sub to_json{
    my $self = shift;
    my $json = {};
    for my $key (keys %$self){
        if($key eq "sender"){
            $json->{sender} = decode_utf8($self->sender->displayname);
        }
        elsif($key eq "receiver"){
            $json->{receiver} = decode_utf8($self->receiver->displayname);
        }
        elsif($key eq "group"){
            $json->{group} = decode_utf8($self->group->gname);
        }
        elsif($key eq "discuss"){
            $json->{discuss} = decode_utf8($self->discuss->dname);
        }
        elsif(ref $self->{$key} eq ""){
            $json->{$key} = decode_utf8($self->{$key});
        }
    }    
    return $json;
}

1;
