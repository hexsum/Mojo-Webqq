package Mojo::Webqq::Plugin::Qiandao;
use List::Util qw(first);
sub call {
    my $client = shift;
    my $data = shift;
    my $callback = sub{
        my @groups;
        if(ref $data->{allow_group}  eq "ARRAY"){
            for my $g ($client->groups){
                next if !first {$_=~/^\d+$/?$g->gnumber eq $_:$g->gname eq $_} @{$data->{allow_group}};
                push @groups,$g;
            }
        }
        elsif(ref $data->{ban_group}  eq "ARRAY"){
            for my $g ($client->groups){
                next if first {$_=~/^\d+$/?$g->gnumber eq $_:$g->gname eq $_} @{$data->{ban_group}};
                push @groups,$g;
            } 
        }
        else{
            for($client->groups){push @groups,$_;}
        }
        for(@groups){$_->qiandao()}
    };
    $client->on(login=>$callback) if $data->{is_qiandao_on_login};
    $client->add_job("Qiandao",$data->{qiandao_time} || "09:30",$callback);
}
1;
