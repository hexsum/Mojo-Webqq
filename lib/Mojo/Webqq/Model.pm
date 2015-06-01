package Mojo::Webqq::Model;
use strict;
use List::Util qw(first);
use Storable qw(dclone);
use Mojo::Webqq::User;
use Mojo::Webqq::Friend;
use Mojo::Webqq::Group;
use Mojo::Webqq::Discuss;
use Mojo::Webqq::Discuss::Member;
use Mojo::Webqq::Group::Member;
use Mojo::Webqq::Recent::Friend;
use Mojo::Webqq::Recent::Group;
use Mojo::Webqq::Recent::Discuss;
use Mojo::Webqq::Model::Remote::_get_user_info;
use Mojo::Webqq::Model::Remote::get_single_long_nick;
use Mojo::Webqq::Model::Remote::get_qq_from_id;
use Mojo::Webqq::Model::Remote::_get_user_friends;
use Mojo::Webqq::Model::Remote::_get_friends_state;
use Mojo::Webqq::Model::Remote::_get_group_list_info;
use Mojo::Webqq::Model::Remote::_get_group_info;
use Mojo::Webqq::Model::Remote::_get_discuss_info;
use Mojo::Webqq::Model::Remote::_get_discuss_list_info;
use Mojo::Webqq::Model::Remote::_get_recent_info;

use base qw(Mojo::Webqq::Request Mojo::Webqq::Base);

sub update_user {
    my $self = shift;
    $self->info("更新个人信息...\n");
    my $user_info = $self->_get_user_info();
    unless ( defined $user_info ) {
        $self->warn("更新个人信息失败\n");
        return;
    }       
    $self->user($self->new_user($user_info));
}

sub add_friend {
    my $self = shift;
    my $friend = shift;
    my $nocheck = shift;
    $self->die("不支持的数据类型\n") if ref $friend ne "Mojo::Webqq::Friend";
    if(@{$self->friend}  == 0){
        push @{$self->friend},$friend;
        return $self;
    }
    if($nocheck){
        push @{$self->friend},$friend;
        return $self;
    }
    my $f = $self->search_friend(id => $friend->id);
    if(defined $f){
        $f = $friend;
    }
    else{
        push @{$self->friend},$friend;
    }
    return $self;
}

sub update_friend {
    my $self = shift;
    my $friend = shift;
    if(defined $friend){
        $self->die("不支持的数据类型") if ref $friend ne "Mojo::Webqq::Friend";
        $self->debug("更新好友 [ " . $friend->nick .  " ] 信息...\n");
        my $friend_info = $self->_get_friend_info($friend->id);  
        if(defined $friend_info){$friend->update($friend_info);}
        else{$self->warn("更新好友 [ " . $friend->nick .  " ] 信息失败...\n");}
        return $self;
    }
    my @friends;
    $self->debug("更新好友信息...\n"); 
    my $friends_info = $self->_get_user_friends();
    if(defined $friends_info){
        push @friends,$self->new_friend($_) for @{$friends_info};
        if(ref $self->friend eq "ARRAY" and @{$self->friend}  == 0){
            #@{$self->friend} = @{$friends_info}; 
            $self->friend(\@friends);
        }
        else{
            my($new_friends,$lost_friends) = $self->array_diff($self->friend,\@friends,sub{$_[0]->id});
            $self->emit(new_friend=>$_) for @{$new_friends};
            $self->emit(lose_friend=>$_) for @{$lost_friends};
            $self->friend(\@friends);
        }
    }
    else{$self->warn("更新好友信息失败\n");}
}

sub search_friend {
    my $self = shift;
    my %p = @_;
    if(wantarray){
        return grep {my $f = $_;(first {$p{$_} ne $f->$_} keys %p) ? 0 : 1;} @{$self->friend};
    }
    else{
        return first {my $f = $_;(first {$p{$_} ne $f->$_} keys %p) ? 0 : 1;} @{$self->friend};
    }
}

sub add_group{
    my $self = shift;
    my $group = shift;
    my $nocheck = shift;
    $self->die("不支持的数据类型") if ref $group ne "Mojo::Webqq::Group";
    if(@{$self->group}  == 0){
        push @{$self->group},$group;
        return $self;
    }
    if($nocheck){
        push @{$self->group},$group;
        return $self;
    }
    my $g = $self->search_group(gid => $group->gid);
    if(defined $g){
        $g = $group;
    }
    else{#new group
        push @{$self->group},$group;
    }
    return $self;
}

sub update_group {
    my $self = shift;
    my $group = shift;
    if(defined $group){
        $self->die("不支持的数据类型") if ref $group ne "Mojo::Webqq::Group"; 
        $self->debug("更新群 [ " . $group->gname .  " ] 信息...");
        my $group_info = $self->_get_group_info($group->gcode);
        if(defined $group_info){
            $self->debug("更新群 [ " . $group->gname .  " ] 信息成功(未获取到群成员信息)") 
                if ref $group_info->{member} ne "ARRAY";
            $group->update($group_info);
        }
        else{
            $self->warn("更新群 [ " . $group->gname .  " ] 信息失败...");
        }
        return $self;
    }
    my @groups;
    $self->info("更新群列表信息...\n");
    my $group_list = $self->_get_group_list_info(); 
    unless(defined $group_list){
        $self->warn("更新群列表信息失败\n");
        return $self;
    }
    for my $g (@{$group_list}){
        my $group_info;
        $self->info("更新[ " . $g->{gname} . " ]信息\n");
        $group_info = $self->_get_group_info($g->{gcode});
        unless(defined $group_info){
            $self->warn("更新[ " . $g->{gname} . " ]信息失败\n");
            $group_info = $g;
        }
        if(ref $group_info->{member} ne 'ARRAY'){
            $self->debug("更新群 [ " . $group_info->{gname} .  " ] 信息成功,但暂时没有获取到群成员信息");
        }
        push @groups, $self->new_group($group_info);
    } 
    if(ref $self->group eq "ARRAY" and @{$self->group} == 0){
        $self->group(\@groups);
    }
    else{
        my($new_groups,$lost_groups,$sames) = $self->array_diff($self->group,\@groups,sub{$_[0]->gid});  
        $self->emit(new_group=>$_) for @{$new_groups};
        $self->emit(lose_group=>$_) for @{$lost_groups};
        for (
            grep { ref($_->[0]->member) eq "ARRAY"
                and ref($_->[1]->member) eq "ARRAY"
                and @{$_->[0]->member}!=0 
                and @{$_->[1]->member}!=0
            } @{$sames}
        ){
            my($old_group,$new_group) = ($_->[0],$_->[1]);
            my($new_members,$lose_members) = $self->array_diff($old_group->member,$new_group->member,sub{$_[0]->id});
            $self->emit(new_group_member=>$_) for @{$new_members};
            $self->emit(lose_group_member=>$_) for @{$lose_members};
        }
        $self->group(\@groups);
    }
     
}

sub search_group {
    my $self = shift;
    my %p = @_;
    delete $p{member};
    if(wantarray){
        return grep {my $g = $_;(first {$p{$_} ne $g->$_} keys %p) ? 0 : 1;} @{$self->group};
    }
    else{
        return first {my $g = $_;(first {$p{$_} ne $g->$_} keys %p) ? 0 : 1;} @{$self->group};
    }
}

sub search_group_member {
    my $self = shift;
    my %p = @_;
    my @member = map {@{$_->member}} @{$self->group};
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @member;
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @member;
    }
}

sub add_discuss {

}

sub add_discuss_member {

}

sub update_discuss {
    my $self = shift;
    my $discuss = shift;
    if(defined $discuss){
        $self->die("不支持的数据类型") if ref $discuss ne "Mojo::Webqq::Discuss"; 
        $self->debug("更新讨论组 [ " . $discuss->dname .  " ] 信息...");
        my $discuss_info = $self->_get_discuss_info($discuss->did);
        if(defined $discuss_info){
            $self->debug("更新讨论组 [ " . $discuss->dname .  " ] 信息成功(未获取到成员信息)") 
                if ref $discuss_info->{member} ne "ARRAY";
            $discuss->update($discuss_info);
        }
        else{
            $self->warn("更新讨论组 [ " . $discuss->dname .  " ] 信息失败...");
        }
        return $self;
    }
    my @discusss;
    $self->info("更新讨论组列表信息...\n");
    my $discuss_list = $self->_get_discuss_list_info(); 
    unless(defined $discuss_list){
        $self->warn("更新讨论组列表信息失败\n");
        return $self;
    }
    for my $d (@{$discuss_list}){
        my $discuss_info;
        $self->info("更新[ " . $d->{dname} . " ]信息\n");
        $discuss_info = $self->_get_discuss_info($d->{did});
        unless(defined $discuss_info){
            $self->warn("更新[ " . $d->{dname} . " ]信息失败\n");
            $discuss_info = $d;
        }
        if(ref $discuss_info->{member} ne 'ARRAY'){
            $self->debug("更新讨论组 [ " . $discuss_info->{dname} .  " ] 信息成功(未获取到成员信息)");
        }
        push @discusss, $self->new_discuss($discuss_info);
    } 
    if(ref $self->discuss eq "ARRAY" and @{$self->discuss} == 0){
        $self->discuss(\@discusss);
    }
    else{
        my($new_discusss,$lost_discusss,$sames) = $self->array_diff($self->discuss,\@discusss,sub{$_[0]->did});  
        $self->emit(new_discuss=>$_) for @{$new_discusss};
        $self->emit(lose_discuss=>$_) for @{$lost_discusss};
        for (
            grep { ref($_->[0]->member) eq "ARRAY"
                and ref($_->[1]->member) eq "ARRAY"
                and @{$_->[0]->member}!=0 
                and @{$_->[1]->member}!=0
            } @{$sames}
        ){
            my($old_discuss,$new_discuss) = ($_->[0],$_->[1]);
            my($new_members,$lose_members) = $self->array_diff($old_discuss->member,$new_discuss->member,sub{$_[0]->id});
            $self->emit(new_discuss_member=>$_) for @{$new_members};
            $self->emit(lose_discuss_member=>$_) for @{$lose_members};
        }
        $self->discuss(\@discusss);
    }
}

sub search_discuss {
    my $self = shift;
    my %p = @_;
    delete $p{member};
    if(wantarray){
        return grep {my $g = $_;(first {$p{$_} ne $g->$_} keys %p) ? 0 : 1;} @{$self->discuss};
    }
    else{
        return first {my $g = $_;(first {$p{$_} ne $g->$_} keys %p) ? 0 : 1;} @{$self->discuss};
    }
}

sub search_discuss_member {
    my $self = shift;
    my %p = @_;
    my @member = map {@{$_->member}} @{$self->discuss};
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @member;
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->$_} keys %p) ? 0 : 1;} @member;
    }
}

sub add_recent {

}

sub update_recent {
    my $self = shift;
    $self->info("更新最近联系人信息...\n");
    my $recent_info = $self->_get_recent_info();
    if(defined $recent_info){
        my @recent;
        for(@{$recent_info}){
            if($_->{type} eq "friend"){$_=Mojo::Webqq::Recent::Friend->new($_);}
            elsif($_->{type} eq "group"){$_=Mojo::Webqq::Recent::Group->new($_);}
            elsif($_->{type} eq "discuss"){$_=Mojo::Webqq::Recent::Discuss->new($_);}
            push @recent,$_;    
        }
        $self->recent(\@recent);
    }
    else{
        $self->warn("更新最近联系人信息失败\n");
    }
}

sub search_recent {
    my $self = shift;
    my %p = @_;
    if(wantarray){
        return grep {my $f = $_;(first {$p{$_} ne $f->$_} keys %p) ? 0 : 1;} @{$self->recent};
    }
    else{
        return first {my $f = $_;(first {$p{$_} ne $f->$_} keys %p) ? 0 : 1;} @{$self->recent};
    }
}


sub new_user{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    Mojo::Webqq::User->new($hash);
}
sub new_friend{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    Mojo::Webqq::Friend->new($hash);
}
sub new_group{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    Mojo::Webqq::Group->new($hash);
}
sub new_group_member{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    Mojo::Webqq::Group::Member->new($hash);
}
sub new_discuss{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    Mojo::Webqq::Discuss->new($hash);
}
sub new_discuss_member{
    my $self = shift;
    my $hash = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $hash->{_client} = $self;
    Mojo::Webqq::Discuss::Member->new($hash);
}

1;
