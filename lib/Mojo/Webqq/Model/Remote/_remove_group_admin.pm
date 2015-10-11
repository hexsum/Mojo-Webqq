use strict;
sub Mojo::Webqq::Model::_remove_group_admin{
    my $self = shift;
    my($gnumber,@qq) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/set_group_admin";
    my $json = $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{gc=>$gnumber,ul=>join("|",@qq),op=>0,bkn=>$self->get_csrf_token});
    return if not defined $json;
    return if $json->{ec}!=0;
    return 1;
}
1;
