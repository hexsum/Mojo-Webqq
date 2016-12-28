use strict;
sub Mojo::Webqq::Model::_invite_friend{
    my $self = shift;
    my($uid,@qq) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/add_group_member";
    my $json = $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{gc=>$uid,ul=>join("|",@qq),bkn=>$self->get_csrf_token});
    return if not defined $json;
    return if $json->{ec}!=0;
    return 1;
}
1;
