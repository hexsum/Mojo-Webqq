package Mojo::Webqq::Discuss;
use strict;
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    did
    dname
    downer
    member
)];

sub search_discuss_member{
    my $self = shift;
    my %p = @_;
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @{$self->member};
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @{$self->member};
    }
}

sub update{
    my $self = shift;
    my $hash = shift;
    for(keys %$self){
        $self->{$_} = $hash->{$_} if exists $hash->{$_} ;
    }
    $self;
}
1;
