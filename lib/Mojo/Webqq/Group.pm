package Mojo::Webqq::Group;
use strict;
use List::Util qw(first);
use base qw(Mojo::Base Mojo::Webqq::Model::Base);
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
)];
has member => sub{[]};
sub id {
    my $self = shift;
    return @_?$self->gid(@_):$self->gid;
}
sub name{
    my $self = shift;
    return @_?$self->gname(@_):$self->gname;
}
sub markname{
    my $self = shift;
    return @_?$self->gmarkname(@_):$self->gmarkname;
}
sub displayname {
    my $self = shift;
    return defined $self->gmarkname?$self->gmarkname:$self->gname;
}
sub new {
    my $class = shift;
    my $self ;
    bless $self=@_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
    if(exists $self->{member} and ref $self->{member} eq "ARRAY"){
        for( @{ $self->{member} } ){
            $_ = $self->{_client}->new_group_member($_) if ref $_ ne "Mojo::Webqq::Group::Member";
        } 
    }
    $self;
}

sub each_group_member{
    my $self = shift;
    my $callback = shift;
    $self->{_client}->die("参数必须是函数引用") if ref $callback ne "CODE";
    return if ref $self->member ne "ARRAY";
    $self->{_client}->update_group($self) if $self->is_empty;
    for(@{$self->member}){
        $callback->($self->{_client},$_); 
    }
}
sub members {
    my $self = shift;
    $self->{_client}->update_group($self) if $self->is_empty;
    return @{$self->member};
}
sub search_group_member{
    my $self = shift;
    my %p = @_;
    return if 0 == grep {defined $p{$_}} keys %p;
    $self->{_client}->update_group($self) if $self->is_empty;
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->$_} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$self->member};
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->$_} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$self->member};
    } 
}

sub add_group_member{
    my $self = shift;   
    my $member = shift;
    my $nocheck = shift;
    $self->{_client}->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Group::Member";
    if($nocheck){
        push @{$self->member},$member;
        return $self;
    }
    my $m = $self->search_group_member(id=>$member->id);
    if(defined $m){
        %$m = %$member;
    }   
    else{
        push @{$self->member},$member;
    }
    return $self;
}   

sub remove_group_member{
    my $self = shift;
    my $member = shift;
    $self->{_client}->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Group::Member";
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

sub update_group_member_ext {
    my $self = shift;
    $self->{_client}->update_group_member_ext($self,@_);
}
sub update_group_member {
    my $self = shift;
    $self->{_client}->update_group_member($self,@_);
}
sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$hash){
        if($_ eq "member" and ref $hash->{member} eq "ARRAY"){
            next if not @{$hash->{member}};
            my @member = map {ref $_ eq "Mojo::Webqq::Group::Member"?$_:$self->{_client}->new_group_member($_)} @{$hash->{member}};
            if( $self->is_empty() ){
                $self->member(\@member);
            }
            else{
                my($new_members,$lost_members,$sames)=$self->{_client}->array_diff($self->member, \@member,sub{$_[0]->id});
                for(@{$new_members}){
                    $self->add_group_member($_);
                    $self->{_client}->emit(new_group_member=>$_) if defined $self->{_client};
                }
                for(@{$lost_members}){
                    $self->remove_group_member($_);
                    $self->{_client}->emit(lose_group_member=>$_) if defined $self->{_client};
                }
                for(@{$sames}){
                    my($old_member,$new_member) = ($_->[0],$_->[1]);
                    $old_member->update($new_member); 
                }
                #$self->member(\@member);
            }
        }
        else{
            if(exists $hash->{$_}){
                if(defined $hash->{$_} and defined $self->{$_}){
                    if($hash->{$_} ne $self->{$_}){
                        my $old_property = $self->{$_};
                        my $new_property = $hash->{$_};
                        $self->{$_} = $hash->{$_};
                        $self->{_client}->emit("group_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                    }
                }
                elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->{_client}->emit("group_property_change"=>$self,$_,$old_property,$new_property) if defined $self->{_client};
                }
            }
        }
    }
    $self;
}

sub send {
    my $self = shift;
    $self->{_client}->send_group_message($self,@_);
} 
sub me {
    my $self = shift;
    $self->search_group_member(id=>$self->{_client}->user->id);
}
sub invite_friend{
    my $self = shift;
    my @friends = @_;
    return $self->{_client}->invite_friend($self,@friends);
}
sub shutup_group_member{
    my $self = shift;
    my $time = shift;
    my @members = @_;
    return $self->{_client}->shutup_group_member($self,$time,@members);
}
sub speakup_group_member{
    my $self = shift;
    my @members = @_;
    return $self->{_client}->speakup_group_member($self,@members);
}
sub kick_group_member{
    my $self = shift;
    my @members = @_;
    return $self->{_client}->kick_group_member($self,@members);
}
sub set_group_admin{
    my $self = shift;
    my @members = @_;
    return $self->{_client}->set_group_admin($self,@members);
}
sub remove_group_admin{
    my $self = shift;
    my @members = @_;
    return $self->{_client}->remove_group_admin($self,@members);
}
sub set_group_member_card{
    my $self = shift;
    my $member = shift;
    my $card = shift;
    return $self->{_client}->set_group_member_card($self,$member,$card);
}
sub qiandao {
    my $self = shift;
    return $self->{_client}->qiandao($self);
}
1;
