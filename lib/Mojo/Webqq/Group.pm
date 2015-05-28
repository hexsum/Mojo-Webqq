package Mojo::Webqq::Group;
use strict;
use List::Util qw(first);
use Mojo::Base;
use base qw(Mojo::Base Mojo::Webqq::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    gid
    gcode
    gtype 
    gnumber
    gname
    gmemo
    gcreatetime
    glevel
    gowner
    gmarkname    
    member
)];

sub search_group_member{
    my $self = shift;
    my %p = @_;
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @{$self->member};
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @{$self->member};
    } 
}

sub add_group_member{
    my $self = shift;   
    my $member = shift;
    my $nocheck = shift;
    $self->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Group::Member";
    if($nocheck){
        push @{$self->member},$member;
        return $self;
    }
    my $m = $self->search_group_member(id=>$member->id);
    if(defined $m){
        $m = $member;
    }   
    else{
        push @{$self->member},$member;
    }
    return $self;
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
