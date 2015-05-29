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
    $user_info->{_client} = $self;
    $self->user(Mojo::Webqq::User->new($user_info));
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
        $self->info("更新好友 [ " . $friend->nick .  " ] 信息...\n");
        my $friend_info = $self->_get_friend_info($friend->id);  
        if(defined $friend_info){$friend->update($friend_info);}
        else{$self->warn("更新好友 [ " . $friend->nick .  " ] 信息失败...\n");}
        return $self;
    }
    $self->info("更新好友信息...\n"); 
    my $friends_info = $self->_get_user_friends();
    if(defined $friends_info){
        for(@{$friends_info}){
            $_->{_client}=$self;
            $_ = Mojo::Webqq::Friend->new($_);
        }
        if(ref $self->friend eq "ARRAY" and @{$self->friend}  == 0){
            #@{$self->friend} = @{$friends_info}; 
            $self->friend($friends_info);
        }
        else{
            my($new_friends,$lost_friends) = $self->array_diff($self->friend,$friends_info,sub{$_[0]->id});
            $self->emit(new_friend=>$_) for @{$new_friends};
            $self->emit(lose_friend=>$_) for @{$lost_friends};
            $self->friend($friends_info);
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
        $self->info("更新群 [ " . $group->gname .  " ] 信息...");
        my $group_info = $self->_get_group_info($group->gcode);
        if(defined $group_info){
            $self->debug("更新群 [ " . $group->gname .  " ] 信息成功,但暂时没有获取到群成员信息")
                if ref $group_info->{member} ne 'ARRAY';
            my $old_group = dclone($group);
            for (@{$group_info->{member}}){
                $_->{_client} = $self ;
                $_ = Mojo::Webqq::Group::Member->new($_) ;
            }
            $group->update($group_info);
            my($new_members,$lost_members)  = $self->array_diff($old_group->member,$group->member,sub{$_[0]->id});
            $self->emit(new_group_member=>$_) for @{$new_members};
            $self->emit(lose_group_member=>$_) for @{$lost_members};
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
        $self->warn("更新群信息失败\n");
        return $self;
    }
    for my $g (@{$group_list}){
        $self->info("更新[ " . $g->{gname} . " ]信息\n");
        my $group_info = $self->_get_group_info($g->{gcode});
        unless(defined $group_info){
            $self->warn("更新[ " . $g->{gname} . " ]信息失败\n");
            push @groups,Mojo::Webqq::Group->new($g);
            next;
        }
        if(ref $group_info->{member} ne 'ARRAY'){
            $self->debug("更新群 [ " . $group_info->{gname} .  " ] 信息成功,但暂时没有获取到群成员信息");
        }
        else{
            for(@{$group_info->{member}}){
                $_->{_client} = $self ;
                $_ = Mojo::Webqq::Group::Member->new($_) ;
            }
        }
        push @groups,Mojo::Webqq::Group->new($group_info);
    } 
    if(ref $self->group eq "ARRAY" and @{$self->group} == 0){
        $self->group(\@groups);
    }
    else{
        my($new_groups,$lost_groups,$sames) = $self->array_diff($self->group,\@groups,sub{$_[0]->gid});  
        $self->emit(new_group=>$_) for @{$new_groups};
        $self->emit(lose_group=>$_) for @{$lost_groups};
        for(@{$sames}){
            my($og,$ng) = ($_->[0],$_->[1]);
            if(ref $og->member eq "ARRAY" and ref $ng->member eq "ARRAY" and @{$og->member}!=0 and @{$ng->member}!=0){
                my($new_members,$lost_members) = $self->array_diff($og->member,$ng->member,sub{$_[0]->id});
                $self->emit(new_group_member=>$_) for @{$new_members};
                $self->emit(lose_group_member=>$_) for @{$lost_members}; 
            }
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
    my $discuss =shift;
    if(defined $discuss){
        $self->die("不支持的数据类型") if ref $discuss ne "Mojo::Webqq::Discuss";
        $self->info("更新群 [ " . $discuss->dname .  " ] 信息...\n"); 
        my $discuss_info = $self->_get_discuss_info($discuss->did);
        if(defined $discuss_info){
            my $old_discuss = dclone($discuss);
            for(@{$discuss_info->{member}}){
                $_->{_client} = $self;
                $_ = Mojo::Webqq::Discuss::Member->new($_);
            } 
            $discuss->update($discuss_info);
            my($new_members,$lost_members) = $self->array_diff($old_discuss->member,$discuss->member,sub{$_[0]->id});
            $self->emit(new_discuss_member=>$_) for @{$new_members};
            $self->emit(lose_discuss_member=>$_) for @{$lost_members};
        }
        else{
            $self->warn("更新群 [ " . $discuss->dname .  " ] 信息失败...\n");
        }
        return $self;
    }

    my @discusss;
    $self->info("更新讨论组列表信息...\n");  
    my $discuss_list = $self->_get_discuss_list_info(); 
    unless(defined $discuss_list){
        $self->warn("更新群信息失败\n");
        return $self;
    }
    for my $d (@{$discuss_list}){
        $self->info("更新[ " . $d->{dname} . " ]信息\n");
        my $discuss_info = $self->_get_disucss_info($d->{did});
        unless(defined $discuss_info){
            $self->warn("更新[ " . $d->{dname} . " ]信息失败\n");
            push @discusss,Mojo::Webqq::Discuss->new($d);
            next;
        }
        if(ref $discuss_info->{member} eq "ARRAY"){
            for(@{$discuss_info->{member}}){
                $_->{_client} = $self;
                $_ = Mojo::Webqq::Discuss::Member->new($_) ;
            }
        }
        push @discusss,Mojo::Webqq::Discuss->new($discuss_info);
    } 
    if(ref $self->discuss eq "ARRAY" and @{$self->discuss} == 0){
        $self->discuss(\@discusss);
    }
    else{
        my($new_discusss,$lost_discusss,$sames) = $self->array_diff($self->discuss,\@discusss,sub{$_[0]->did});  
        $self->emit(new_discuss=>$_) for @{$new_discusss};
        $self->emit(lose_discuss=>$_) for @{$lost_discusss};
        for(@{$sames}){
            my($od,$nd) = ($_->[0],$_->[1]);
            if(ref $od->member eq "ARRAY" and ref $nd->member eq "ARRAY" and @{$od->member}!=0 and @{$nd->member}!=0){
                my($new_members,$lost_members) = $self->array_diff($od->member,$nd->member,sub{$_[0]->id});
                $self->emit(new_discuss_member=>$_) for @{$new_members};
                $self->emit(lose_discuss_member=>$_) for @{$lost_members}; 
            }
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

1;
