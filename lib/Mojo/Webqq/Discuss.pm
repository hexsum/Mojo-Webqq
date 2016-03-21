package Mojo::Webqq::Discuss;
use strict;
use List::Util qw(first);
use base qw(Mojo::Base Mojo::Webqq::Model::Base);
sub has { Mojo::Base::attr(__PACKAGE__, @_) };
has [qw(
    did
    dname
    downer
)];
has member => sub{[]};
sub owner{
    my $self = shift;
    return @_?$self->downer(@_):$self->downer;
}
sub id {
    my $self = shift;
    return @_?$self->did(@_):$self->did; 
}
sub name{
    my $self = shift;
    return @_?$self->dname(@_):$self->dname;
}
sub displayname {
    my $self = shift;
    return $self->dname;
}
sub new {
    my $class = shift;
    my $self ;
    bless $self=@_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
    if(exists $self->{member} and ref $self->{member} eq "ARRAY"){
        for( @{ $self->{member} } ){
            $_ = $self->{_client}->new_discuss_member($_) if ref $_ ne "Mojo::Webqq::Discuss::Member";
        }
    }
    $self;
}

sub members{
    my $self = shift;
    $self->{_client}->update_discuss($self) if $self->is_empty;
    return @{$self->member};
}
sub each_discuss_member{
    my $self = shift;
    my $callback = shift;
    $self->{_client}->die("参数必须是函数引用") if ref $callback ne "CODE";
    return if ref $self->member ne "ARRAY";
    $self->{_client}->update_discuss($self) if $self->is_empty;
    for(@{$self->member}){
        $callback->($self->{_client},$_);
    }
}

sub search_discuss_member{
    my $self = shift;
    my %p = @_;
    return if 0 == grep {defined $p{$_}} keys %p;
    $self->{_client}->update_discuss($self) if $self->is_empty;
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->$_} grep {defined $p{$_}}  keys %p) ? 0 : 1;} @{$self->member};
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->$_} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$self->member};
    }
}

sub add_discuss_member{
    my $self = shift;   
    my $member = shift;
    my $nocheck = shift;
    $self->{_client}->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Discuss::Member";
    if($nocheck){
        push @{$self->member},$member;
        return $self;
    }
    my $m = $self->search_discuss_member(id=>$member->id);
    if(defined $m){
        %$m = %$member;
    }   
    else{
        push @{$self->member},$member;
    }
    return $self;
}
sub remove_discuss_member{
    my $self = shift;
    my $member = shift;
    $self->{_client}->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Discuss::Member";
    for(my $i=0;$i<@{$self->member};$i++){
        if($self->member->[$i]->id eq $member->id){
            splice @{$self->member},$i,1;
            return 1;
        }
    }
    return;
}

sub is_empty{
    my $self = shift;
    return !(ref($self->member) eq "ARRAY"?0+@{$self->member}:0);
}
sub update_discuss_member {
    my $self = shift;
    $self->{_client}->update_discuss_member($self,@_);
}
sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$hash){
        if($_ eq "member" and exists $hash->{member} and ref $hash->{member} eq "ARRAY"){
            next if not @{$hash->{member}};
            my @member = map {ref $_ eq "Mojo::Webqq::Discuss::Member"?$_:$self->{_client}->new_discuss_member($_)} @{$hash->{member}};
            if( $self->is_empty() ){
                $self->member(\@member);
            }
            else{
                my($new_members,$lost_members,$sames)=$self->{_client}->array_diff($self->member, \@member,sub{$_[0]->id});
                for(@{$new_members}){
                    $self->add_discuss_member($_);
                    $self->{_client}->emit(new_discuss_member=>$_) if defined $self->{_client};
                }
                for(@{$lost_members}){
                    $self->remove_discuss_member($_);
                    $self->{_client}->emit(lose_discuss_member=>$_) if defined $self->{_client};
                }
                for(@{$sames}){
                    my($old,$new) = ($_->[0],$_->[1]);
                    $old->update($new);
                }
            }
        }
        else{
            if(exists $hash->{$_}){
                if(defined $hash->{$_} and defined $self->{$_}){
                    if($hash->{$_} ne $self->{$_}){
                        my $old_property = $self->{$_};
                        my $new_property = $hash->{$_};
                        $self->{$_} = $hash->{$_};
                        $self->{_client}->emit("discuss_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                    }
                }
                elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->{_client}->emit("discuss_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                }
            }
        }
    }
    $self;
}
sub send {
    my $self = shift;
    $self->{_client}->send_discuss_message($self,@_);
} 
sub me {
    my $self = shift;
    $self->search_discuss_member(id=>$self->{_client}->user->id);
}
1;
