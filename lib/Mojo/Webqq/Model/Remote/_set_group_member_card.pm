use strict;
sub Mojo::Webqq::Model::_set_group_member_card{
    my $self = shift;
    my($gnumber,$qq,$card) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/set_group_card";
    my $form = defined $card?{gc=>$gnumber,u=>$qq,name=>$card,bkn=>$self->get_csrf_token}:{gc=>$gnumber,u=>$qq,bkn=>$self->get_csrf_token};
    $self->reform_hash($form,1);
    my $json = $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>$form);
    return if not defined $json;
    return if $json->{ec}!=0;
    return 1;
}
1;
