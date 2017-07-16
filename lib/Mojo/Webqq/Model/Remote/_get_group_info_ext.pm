use strict;
sub Mojo::Webqq::Model::_get_group_info_ext {
    my $self = shift;
    my $uid = shift;
    my $callback = shift;
    #my $api = "http://qinfo.clt.qq.com/cgi-bin/qun_info/get_group_members_new";
    my $api = "http://qinfo.clt.qq.com/cgi-bin/qun_info/get_group_members";
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub {
        my $json = shift;
        return if not defined $json;
        return if $json->{ec}!=0;
        if(ref $json->{mems} ne 'ARRAY'){
            $self->warn("更新群[$uid]扩展信息失败: 返回数据异常");
            return;
        }
        my %levelname; 
        for(keys %{$json->{levelname}}){
            $levelname{$_} = $json->{levelname}{$_};
        }
        my %last_speak_time;
        for (keys %{$json->{times}}){
            $last_speak_time{$_} = $json->{times}{$_};
        }
        my %join_time;
        for (keys %{$json->{join}}){
            $join_time{$_} = $json->{join}{$_};
        }
        my %adm; 
        $adm{$_} = 1 for @{$json->{adm}};

        my %card;
        for(keys %{$json->{cards}}){
            $card{$_} = $json->{cards}{$_};
        }

        my $group = {member=>[]};

        $group->{max_admin} = undef;
        $group->{admin_count} = undef;
        $group->{member_count} = undef;
        $group->{max_member} = undef;

        $group->{uid} = $uid;
        $group->{owner_uid} = $json->{owner};
        for(@{$json->{mems}}){
            my $member = {};
            $member->{uid}  = $_->{u};

            if($member->{uid} eq $group->{owner_uid}){
                $member->{role} = 'owner';
            }
            elsif($adm{ $member->{uid} } == 1){
                $member->{role} = 'admin';
            }
            else{
                $member->{role} = 'member';
            }
            $member->{card} = (defined $card{$member->{uid}} and $card{$member->{uid}} ne "")?$self->xmlescape_parse($card{$member->{uid}}): undef;
            if ($self->group_member_use_fullcard) {
                $member->{fullcard} = $member->{card};
            }
            if(not $self->group_member_card_ext_only){
                $member->{card} = $self->safe_truncate($member->{card},$self->group_member_card_cut_length) if defined $member->{card};
            }
            $member->{name} = $self->xmlescape_parse($_->{n});
            $member->{last_speak_time} = $last_speak_time{$member->{uid}};
            $member->{join_time} = $join_time{$member->{uid}};
            push @{$group->{member}},$member;
        }   
        return $group;
    };
    if($is_blocking){
        return $handle->( $self->http_post($api,{Referer=>"http://qinfo.clt.qq.com/member.html",json=>1},form=>{gc=>$uid,u=>$self->user->uid,bkn=>$self->get_csrf_token},) );
    }
    else{
        $self->http_post($api,{Referer=>"http://qinfo.clt.qq.com/member.html",json=>1},form=>{gc=>$uid,u=>$self->user->uid,bkn=>$self->get_csrf_token},sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}
1;
