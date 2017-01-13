package Mojo::Webqq::Util;
use Carp qw();
use Encode qw();
use IO::Handle;
use Mojo::JSON qw();
use Mojo::Util qw();
use Mojo::Webqq::Counter;
sub new_counter {
    my $self = shift;
    return Mojo::Webqq::Counter->new(client=>$self,@_);
}
sub url_escape {
    my $self = shift;
    return Mojo::Util::url_escape(@_);
}

sub slurp {
    my $self = shift;
    my $path = shift;

    open my $file, '<', $path or Carp::croak qq{Can't open file "$path": $!};
    my $ret = my $content = '';
    while ($ret = $file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
    Carp::croak qq{Can't read from file "$path": $!} unless defined $ret;

    return $content;
}
sub spurt {
    my $self = shift;
    my ($content, $path) = @_;
    open my $file, '>', $path or Carp::croak qq{Can't open file "$path": $!};
    defined $file->syswrite($content)
        or Carp::croak qq{Can't write to file "$path": $!};
    return $content;
}
sub encode{
    my $self = shift;
    return Mojo::Util::encode(@_);
}
sub decode{
    my $self = shift;
    return Mojo::Util::decode(@_);
}

sub encode_utf8{
    my $self = shift;
    return Mojo::Util::encode("utf8",@_);
}

sub from_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::from_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "::from_json return undef value");
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "::from_json return undef value") if not defined $r;
        return $r;
    }
}
sub to_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::to_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "::to_json return undef value");
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "::to_json return undef value") if not defined $r;
        return $r;
    }
}
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
    my $max_lines = $p{max_lines} || 8;
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

sub reform{
    my $self = shift;
    my $ref = shift;
    my %opt = @_;
    my $unicode = $opt{unicode} // 0;
    my $recursive = $opt{recursive} // 1;
    my $cb = $opt{filter};
    my $deep = $opt{deep} // 0;
    if(ref $ref eq 'HASH'){
        my @reform_hash_keys;
        for (keys %$ref){
            next if ref $cb eq "CODE" and !$cb->("HASH",$deep,$_,$ref->{$_});
            if($_ !~ /^[[:ascii:]]+$/){
                if($unicode and not Encode::is_utf8($_)){
                    push @reform_hash_keys,[ $_,Encode::decode_utf8($_) ];
                }
                elsif(!$unicode and Encode::is_utf8($_)){ 
                    push @reform_hash_keys,[ $_,Encode::encode_utf8($_) ];
                }
            }
        
            if(ref $ref->{$_} eq ""){
                if($unicode and not Encode::is_utf8($ref->{$_}) ){
                    Encode::_utf8_on($ref->{$_});
                }
                elsif( !$unicode and Encode::is_utf8($ref->{$_}) ){
                    Encode::_utf8_off($ref->{$_});
                }
            }
            elsif( $recursive and ref $ref->{$_} eq "ARRAY" or ref $ref->{$_} eq "HASH"){
                $self->reform($ref->{$_},@_,deep=>$deep+1);
            }
            #else{
            #    $self->die("不支持的hash结构\n");
            #}
        }

        for(@reform_hash_keys){ $ref->{$_->[1]} = delete $ref->{$_->[0]} }
    }
    elsif(ref $ref eq 'ARRAY'){
        for(@$ref){
            next if ref $cb eq "CODE" and !$cb->("ARRAY",$deep,$_);
            if(ref $_ eq ""){
                if($unicode and not Encode::is_utf8($_) ){
                    Encode::_utf8_on($_);
                }
                elsif( !$unicode and Encode::is_utf8($_) ){
                    Encode::_utf8_off($_);
                }
            }
            elsif($recursive and ref $_ eq "ARRAY" or ref $_ eq "HASH"){
                $self->reform($_,@_,deep=>$deep+1);
            }
            #else{
            #    $self->die("不支持的hash结构\n");
            #}
        }
    }
    else{
        $self->die("不支持的数据结构");
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
sub msg{
    my $self = shift;
    $self->log->msg(@_);
    $self;
}
sub warn{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'yellow' and $_[0]->{content_color} //= 'yellow')
    :   unshift @_,{level_color=>'yellow',content_color=>'yellow'};
    $self->log->warn(@_);
    $self;
}
sub error{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'red' and $_[0]->{content_color} //= 'red')
    :   unshift @_,{level_color=>'red',content_color=>'red'};
    $self->log->error(@_);
    $self;
}
sub fatal{
    my $self = shift;
        ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'red' and $_[0]->{content_color} //= 'red')
    :   unshift @_,{level_color=>'red',content_color=>'red'};
    $self->log->fatal(@_);
    $self;
}
sub debug{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'blue' and $_[0]->{content_color} //= 'blue')
    :   unshift @_,{level_color=>'blue',content_color=>'blue'};
    $self->log->debug(@_);
    $self;
}
sub print {
    my $self = shift;
    $self->log->info({time=>'',level=>'',}, join defined $,?$,:'',@_);
    $self;
}

1;
