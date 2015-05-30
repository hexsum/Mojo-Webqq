package Mojo::Webqq::Message::Base;
use Data::Dumper;
use Scalar::Util qw(blessed);
sub dump{
    my $self = shift;
    my $clone = {};
    my $obj_name = blessed($self);
    bless $clone,$obj_name if $obj_name;
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
    print Dumper $clone;
    return $self;
}
1;
