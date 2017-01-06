package Mojo::Webqq::Discuss;
use strict;
use List::Util qw(first);
use Mojo::Webqq::Discuss::Member;
use Mojo::Webqq::Base 'Mojo::Webqq::Model::Base';
has [qw(
    id
    name
    owner_id
)];
has member => sub{[]};
sub member_count {0+@{$_[0]->member}}
sub AUTOLOAD {
    my $self = shift;
    if($Mojo::Webqq::Discuss::AUTOLOAD =~ /.*::d(.*)/){
        my $attr = $1;
        $self->$attr(@_);
    }
    else{die("undefined subroutine $Mojo::Webqq::Discuss::AUTOLOAD");}
}
sub displayname {
    my $self = shift;
    return $self->name;
}
sub new {
    my $class = shift;
    my $self ;
    bless $self=@_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
    if(exists $self->{member} and ref $self->{member} eq "ARRAY"){
        for( @{ $self->{member} } ){
            $_->{_discuss_id} = $self->id if not defined $_->{_discuss_id};
            $_ = Mojo::Webqq::Discuss::Member->new($_) if ref $_ ne "Mojo::Webqq::Discuss::Member";
        }
    }
    $self;
}

sub members{
    my $self = shift;
    $self->client->update_discuss($self) if $self->is_empty;
    return @{$self->member};
}
sub each_discuss_member{
    my $self = shift;
    my $callback = shift;
    $self->client->die("参数必须是函数引用") if ref $callback ne "CODE";
    return if ref $self->member ne "ARRAY";
    $self->client->update_discuss($self) if $self->is_empty;
    for(@{$self->member}){
        $callback->($self->client,$_);
    }
}

sub search_discuss_member{
    my $self = shift;
    my %p = @_;
    return if 0 == grep {defined $p{$_}} keys %p;
    $self->client->update_discuss($self) if $self->is_empty;
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
    $self->client->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Discuss::Member";
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
    $self->client->die("不支持的数据类型") if ref $member ne "Mojo::Webqq::Discuss::Member";
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
    $self->client->update_discuss_member($self,@_);
}
sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$hash){
        if($_ eq "member" and exists $hash->{member} and ref $hash->{member} eq "ARRAY"){
            next if not @{$hash->{member}};
            my @member = map {ref $_ eq "Mojo::Webqq::Discuss::Member"?$_:Mojo::Webqq::Discuss::Member->new($_)} @{$hash->{member}};
            if( $self->is_empty() ){
                $self->member(\@member);
            }
            else{
                my($new_members,$lost_members,$sames)=$self->client->array_diff($self->member, \@member,sub{$_[0]->id});
                for(@{$new_members}){
                    $self->add_discuss_member($_);
                    $self->client->emit(new_discuss_member=>$_,$self) if defined $self->client;
                }
                for(@{$lost_members}){
                    $self->remove_discuss_member($_);
                    $self->client->emit(lose_discuss_member=>$_,$self) if defined $self->client;
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
                        $self->client->emit("discuss_property_change"=>$self,$_,$old_property,$new_property);
                    }
                }
                elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->client->emit("discuss_property_change"=>$self,$_,$old_property,$new_property);
                }
            }
        }
    }
    $self;
}
sub send {
    my $self = shift;
    $self->client->send_discuss_message($self,@_);
} 
sub me {
    my $self = shift;
    $self->search_discuss_member(id=>$self->client->user->id);
}
1;
