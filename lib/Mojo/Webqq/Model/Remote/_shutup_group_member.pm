use strict;
use Mojo::JSON qw(encode_json);
sub Mojo::Webqq::Model::_shutup_group_member{
    my $self = shift;
    my($gnumber,$t,@qq) = @_;
    my $api = "http://qinfo.clt.qq.com/cgi-bin/qun_info/set_group_shutup";
    my $json = $self->http_post($api,{Referer=>"http://qinfo.clt.qq.com/qinfo_v3/member.html",json=>1},form=>{gc=>$gnumber,shutup_list=>encode_json([map {{uin=>$_,t=>$t}} @qq]),bkn=>$self->get_csrf_token});
    return if not defined $json;
    return if $json->{ec}!=0;
    return 1;
}
1;
