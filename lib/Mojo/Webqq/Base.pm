package Mojo::Webqq::Base;
use Scalar::Util qw(blessed);
use Carp qw();
use Mojo::JSON;
use Encode qw(encode_utf8 encode decode);
use Data::Dumper;
sub to_hash{
    my $self = shift;   
    my $hash = {};
    for(keys %$self){
        next if substr($_,0,1) eq "_";
        next if $_ eq "member";
        $hash->{$_} = $self->{$_};
    }
    $self->reform_hash($hash,1);
    if(exists $self->{member}){
        $hash->{member} = [];
        if(ref $self->{member} eq "ARRAY"){
            for my $m(@{$self->{member}}){
                my $member_hash = $m->to_hash();
                $self->reform_hash($member_hash,1);
                push @{$hash->{member}},$member_hash;
            }
        }
    }

    return $hash;
}
sub decode_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::decode_json(@_);
    };
    if($@){
        print $@,"\n";
        return undef;
    }
    else{
        return $r;
    }
}
sub encode_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::encode_json(@_);
    };
    if($@){
        print $@,"\n";
        return undef;
    }
    else{
        return $r;
    }
}
sub hash {
    my $self = shift;
    my $ptwebqq = shift;
    my $uin = shift;

    $uin .= "";
    my @N;
    for(my $T =0;$T<length($ptwebqq);$T++){
        $N[$T % 4] ^= ord(substr($ptwebqq,$T,1));
    }
    my @U = ("EC", "OK");
    my @V;
    $V[0] =  $uin >> 24 & 255 ^ ord(substr($U[0],0,1));
    $V[1] =  $uin >> 16 & 255 ^ ord(substr($U[0],1,1));
    $V[2] =  $uin >> 8  & 255 ^ ord(substr($U[1],0,1));
    $V[3] =  $uin       & 255 ^ ord(substr($U[1],1,1));
    @U = ();
    for(my $T=0;$T<8;$T++){
        $U[$T] = $T%2==0?$N[$T>>1]:$V[$T>>1]; 
    }
    @N = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F");
    my $V = "";
    for($T=0;$T<@U;$T++){
        $V .= $N[$U[$T] >> 4 & 15];
        $V .= $N[$U[$T] & 15];
    }

    return $V;
            
}

sub truncate {
    my $self = shift;
    my $out_and_err = shift;
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

sub dump{
    my $self = shift;
    my $clone = {};
    my $obj_name = blessed($self);
    bless $clone,$obj_name if $obj_name; 
    for(keys %$self){
        next if $_ eq "_client";
        if(my $n=blessed($self->{$_})){
             $clone->{$_} = "Object($n)";
        }
        elsif($_ eq "member" and ref($self->{$_}) eq "ARRAY"){
            my $member_count = @{$self->{$_}};
            $clone->{$_} = [ "$member_count of Object(${obj_name}::Member)" ];
        }
        else{
            $clone->{$_} = $self->{$_};
        }
    }
    $self->print(Dumper $clone);
    return $self;
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
    $self->log->info(join $,,@_);
    $self;
}

1;
