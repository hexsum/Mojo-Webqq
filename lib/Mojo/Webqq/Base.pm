package Mojo::Webqq::Base;
use Carp qw();
use Mojo::JSON qw();
use Encode qw(encode_utf8 encode decode);
sub decode_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::decode_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "::decode_json return undef value");
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "::decode_json return undef value") if not defined $r;
        return $r;
    }
}
sub encode_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::encode_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "encode_json return undef value") if not defined $r;
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "encode_json return undef value") if not defined $r;
        return $r;
    }
}
sub truncate {
    my $self = shift;
    my $out_and_err = shift || '';
    my %p = @_;
    my $max_bytes = $p{max_bytes} || 200;
    my $max_lines = $p{max_lines} || 10;
    my $is_truncated = 0;
    if(length($out_and_err)>$max_bytes){
        $out_and_err = substr($out_and_err,0,$max_bytes);
        $is_truncated = 1;
    }
    my @l =split /\n/,$out_and_err,$max_lines+1;
    if(@l>$max_lines){
        $out_and_err = join "\n",@l[0..$max_lines-1];
        $is_truncated = 1;
    }
    return $out_and_err. ($is_truncated?"\n(已截断)":"");
}
sub code2state {
    my $self = shift;
    my %c = qw(
        10  online
        20  offline
        30  away
        40  hidden
        50  busy
        60  callme
        70  silent
    );
    return $c{$_[0]} || "online";
}
sub code2client {
    my $self = shift;
    my %c = qw(
        1   pc
        21  mobile
        24  iphone
        41  web
    );
    return $c{$_[0]} || 'unknown';
}
sub reform_hash{
    my $self = shift;
    my $hash = shift;
    my $flag = shift || 0;
    for(keys %$hash){
        $self->die("不支持的hash结构\n") if ref $hash->{$_} ne "";
        if($flag){
            Encode::_utf8_on($hash->{$_}) if not Encode::is_utf8($hash->{$_}); 
        }
        else{Encode::_utf8_off($hash->{$_}) if Encode::is_utf8($hash->{$_});}
    }
    $self;
}

sub array_diff{
    my $self = shift;
    my $old = shift;
    my $new = shift;
    my $compare = shift;
    my $old_hash = {};
    my $new_hash = {};
    my $added = [];
    my $deleted = [];
    my $same = {};

    my %e = map {$compare->($_) => undef} @{$new};
    for(@{$old}){
        unless(exists $e{$compare->($_)}){
            push @{$deleted},$_;    
        }
        else{
            $same->{$compare->($_)}[0] = $_;
        }
    }

    %e = map {$compare->($_) => undef} @{$old};
    for(@{$new}){
        unless(exists $e{$compare->($_)}){
            push @{$added},$_;
        }
        else{
            $same->{$compare->($_)}[1] = $_;
        }
    }
    return $added,$deleted,[values %$same]; 
}

sub array_unique {
    my $self = shift;
    my $array = shift;
    my $diff = shift;
    my $info = shift;
    my @result;
    my %info;
    my %tmp;
    for(@$array){
        my $id = $diff->($_);
        $tmp{$id}++;
    }
    my $i = 0;
    for(@$array){
        my $id = $diff->($_);
        next if not exists $tmp{$id} ;
        if($tmp{$id}>1){
            $self->debug("$info array_unique id duplicate: $id($tmp{$id})") if defined $info;
            $i++;
            next;
        }
        push @result,$_;
        $info{$id} = $_ if wantarray;
    }
    $self->debug("$info array_unique id duplicate count: $i") if defined $info and $i >0;
    return wantarray?(\@result,\%info):\@result;
}
sub die{
    my $self = shift; 
    local $SIG{__DIE__} = sub{$self->log->fatal(@_);exit -1};
    Carp::confess(@_);
}
sub info{
    my $self = shift;
    $self->log->info(@_);
    $self;
}
sub warn{
    my $self = shift;
    $self->log->warn(@_);
    $self;
}
sub error{
    my $self = shift;
    $self->log->error(@_);
    $self;
}
sub fatal{
    my $self = shift;
    $self->log->fatal(@_);
    $self;
}
sub debug{
    my $self = shift;
    $self->log->debug(@_);
    $self;
}
sub print {
    my $self = shift;
    $self->log->info({time=>'',level=>'',}, join defined $,?$,:'',@_);
    $self;
}

1;
