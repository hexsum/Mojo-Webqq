package Mojo::Webqq::Message::Base;
use Data::Dumper;
use Storable qw(dclone);
use List::Util qw(first);
use Scalar::Util qw(blessed);
sub dump{
    my $self = shift;
    my $clone = dclone($self);  
    for(keys %$clone){
        if($_ eq "_client"){delete $clone->{$_};next}
        my $bless_name =  blessed($clone->{$_});
        $clone->{$_} =  "Object($bless_name)" if defined $bless_name;
    }
    print Dumper $clone;
    return $self;
}
1;
