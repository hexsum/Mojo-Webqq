use strict;
sub Mojo::Webqq::Model::_remove_group_admin{
    my $self = shift;
    my($uid,@qq) = @_;
    my $api = "http://qinfo.clt.qq.com/cgi-bin/qun_info/set_group_admin";
    my $json = $self->http_post($api,{Referer=>"http://qinfo.clt.qq.com/member.html",json=>1},
            form=>{src=>"qinfo_v2",gc=>$uid,u=>join("|",$qq[0]),op=>0,bkn=>$self->get_csrf_token});
    return if not defined $json;
    return if $json->{ec}!=0;
    return 1;
}
1;
