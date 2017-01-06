use File::Temp qw/:seekable/;
use Mojo::Util qw/url_escape/;
sub Mojo::Webqq::Client::_get_group_pic {
    my $self = shift;
    my $fid = shift;
    my $pic_name = shift;
    my $rip = shift;
    my $rport = shift;
    my $sender  = shift;
    my $cb      = pop;
    
    return if $sender->is_discuss_member;
    my $api = 'http://web2.qq.com/cgi-bin/get_group_pic';
    my @query_string ;
    if($sender->is_group_member){
        @query_string= (
            type    => 0,
            fid     => $fid,
            gid     => $sender->gcode,
            pic     => url_escape($pic_name),
            rip     => $rip,
            rport   => $rport,
            uin     => $sender->id,
            vfwebqq => $self->vfwebqq,
            t       => rand(),
        );
    }
    elsif($sender->is_discuss_member){
        @query_string= (
            type    => 0,
            fid     => $fid,
            did     => $sender->did,
            pic     => url_escape($pic_name),
            rip     => $rip,
            rport   => $rport,
            uin     => $sender->id,
            vfwebqq => $self->vfwebqq,
            t       => rand(),
        );
    }
    my $callback = sub{
        my ($data,$ua,$tx) = @_;
        unless(defined $data){
            $self->warn("群图片下载失败: " . $tx->error->{message});
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
            TEMPLATE    => "mojo_webqq_cface_XXXX",
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
            if($sender->is_group_member){
                $self->emit(receive_group_pic => $tmp->filename,$sender);
            }
            else{
                $self->emit(receive_disucss_pic => $tmp->filename,$sender);
            }
            $cb->($self,$tmp->filename,$sender) if ref $cb eq "CODE";
        };
        $self->error("[Mojo::Webqq::Client::_get_group_pic] $@") if $@;
    };
    $self->http_get($self->gen_url($api,@query_string),{Referer=>'http://w.qq.com/'},$callback);
};
1;
