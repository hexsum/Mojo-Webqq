use File::Temp qw/:seekable/;
use Mojo::Util qw/url_escape/;
sub Mojo::Webqq::Client::_get_offpic {
    my $self = shift;
    my $file_path = shift;
    my $sender  = shift;
    my $cb      = pop;
    
    #my $api = 'http://w.qq.com/d/channel/get_offpic2';
    my $api = 'http://d.web2.qq.com/channel/get_offpic2';
    my @query_string = (
        file_path   =>  url_escape($file_path),
        f_uin       =>  $sender->id,
        clientid    =>  $self->clientid,  
        psessionid  =>  $self->psessionid,
    );
    my $callback = sub{
        my ($data,$ua,$tx) = @_;
        unless(defined $data){
            $self->warn("图片下载失败: " . $tx->error->{message});
            return;
        }
        return unless $tx->res->headers->content_type =~/^image\/(.*)/;
        my $type =      $1=~/jpe?g/i        ?   ".jpg"
                    :   $1=~/png/i          ?   ".png"
                    :   $1=~/bmp/i          ?   ".bmp"
                    :   $1=~/gif/i          ?   ".gif"
                    :                           undef
        ;
        return unless defined $type; 
        if(defined $self->pic_dir and not -d $self->pic_dir){
            $self->error("无效的 pic_dir: " . $self->pic_dir);
            return;
        }
        my @opt = (
            TEMPLATE    => "mojo_webqq_offpic_XXXX",
            SUFFIX      => $type,
            UNLINK      => 0,
        );
        defined $self->pic_dir?(push @opt,(DIR=>$self->pic_dir)):(push @opt,(TMPDIR=>1));
        eval{
            my $tmp = File::Temp->new(@opt);
            binmode $tmp;
            print $tmp $tx->res->body();    
            close $tmp;
            $self->emit(receive_pic => $tmp->filename,$sender);
            $self->emit(receive_friend_pic => $tmp->filename,$sender) if $sender->type eq "friend";
            $self->emit(receive_sess_pic => $tmp->filename,$sender) if $sender->type ne "friend";
            $cb->($self,$tmp->filename,$sender) if ref $cb eq "CODE";
        };
        $self->error("[Mojo::Webqq::Client::_get_offpic] $@") if $@;
    };
    $self->http_get($self->gen_url($api,@query_string),{Referer=>'http://w.qq.com/'},$callback);
};
1;
