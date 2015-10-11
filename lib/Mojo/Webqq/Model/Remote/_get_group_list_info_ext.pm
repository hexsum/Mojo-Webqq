use strict;
sub Mojo::Webqq::Model::_get_group_list_info_ext {
    my $self = shift;
    my $api = 'http://qun.qq.com/cgi-bin/qun_mgr/get_group_list';
    my $json = $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{bkn=>$self->get_csrf_token});
    return if not defined $json;
    return if $json->{ec}!=0;
    #{"ec":0,"join":[{"gc":1299322,"gn":"perl技术","owner":4866832},{"gc":144539789,"gn":"PERL学习交流","owner":419902730},{"gc":213925424,"gn":"PERL","owner":913166583}],"manage":[{"gc":390179723,"gn":"IT狂人","owner":308165330}]}  
    my @result;
    for my $t (qw(join manage create)){
        for(@{$json->{$t}}){
            my $group = {};
            $group->{gname} = $_->{gn};
            $group->{gnumber} = $_->{gc};
            $group->{gowner} = $_->{owner};
            $group->{gtype} = $t eq "join"?"attend":$t;
            $self->reform_hash($group); 
            push @result,$group;
        }
    }
    return \@result;
};
1;
