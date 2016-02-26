use strict;
sub Mojo::Webqq::Model::_get_group_info_ext {
    my $self = shift;
    my $gnumber = shift;
    my $callback = shift;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/search_group_members";
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub {
        my $json = shift;
        return if not defined $json;
        return if $json->{ec}!=0;
        #{"adm_max":10,"adm_num":1,"count":4,"ec":0,"levelname":{"1":"潜水","2":"冒泡","3":"吐槽","4":"活跃","5":"话唠","6":"传说"},"max_count":500,"mems":[{"card":"","flag":0,"g":0,"join_time":1410241477,"last_speak_time":1427191050,"lv":{"level":2,"point":404},"nick":"灰灰","qage":10,"role":0,"tags":"-1","uin":308165330},{"card":"","flag":0,"g":0,"join_time":1423016758,"last_speak_time":1427210847,"lv":{"level":2,"point":275},"nick":"小灰","qage":0,"role":1,"tags":"-1","uin":3072574066},{"card":"","flag":0,"g":0,"join_time":1427210502,"last_speak_time":1427210858,"lv":{"level":2,"point":1},"nick":"王鹏飞","qage":8,"role":2,"tags":"-1","uin":470869063},{"card":"小灰2号","flag":0,"g":0,"join_time":1422946743,"last_speak_time":1424144472,"lv":{"level":1,"point":0},"nick":"小灰2号","qage":0,"role":2,"tags":"-1","uin":1876225186}],"search_count":4,"svr_time":1427291710,"vecsize":1}
        my %role = (
            0   =>  "owner",
            1   =>  "admin",
            2   =>  "member",
        );
        my %levelname; 
        for(keys %{$json->{levelname}}){
            $levelname{$_} = $json->{levelname}{$_};
        }
        my $group = {member=>[]};
        $group->{adm_max} = $json->{adm_max};
        $group->{adm_num} = $json->{adm_num};
        $group->{member_count} = $json->{count};
        $group->{max_member_count} = $json->{max_count};
        $group->{gnumber} = $gnumber;

        for(@{$json->{mems}}){
            my $member = {};
            $member->{level} = $levelname{$_->{lv}{level}};
            $member->{bad_record} = $_->{flag};
            $member->{gender} = $_->{g}?"female":"male";
            $member->{qq}  = $_->{uin};
            $member->{role} = $role{$_->{role}};
            $member->{card} = (defined $_->{card} and $_->{card} ne "")?$self->xmlescape_parse($_->{card}): undef;
            $member->{nick} = $self->xmlescape_parse($_->{nick});
            $member->{qage} = $_->{qage};
            $member->{join_time} = $_->{join_time};
            $member->{last_speak_time} = $_->{last_speak_time};
            $self->reform_hash($member);
            push @{$group->{member}},$member;
        }   
        return $group;
    };
    if($is_blocking){
        return $handle->( $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{gc=>$gnumber,st=>0,end=>2000,sort=>0,bkn=>$self->get_csrf_token},) );
    }
    else{
        $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{gc=>$gnumber,st=>0,end=>2000,sort=>0,bkn=>$self->get_csrf_token},sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}
1;
