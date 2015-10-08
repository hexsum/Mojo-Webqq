package Mojo::Webqq::Model::Base;
use Scalar::Util qw(blessed);
use Data::Dumper;
use Encode qw(decode_utf8);
sub to_json_hash{
    my $self = shift;   
    my $hash = {};
    for(keys %$self){
        next if substr($_,0,1) eq "_";
        next if $_ eq "member";
        $hash->{$_} = decode_utf8($self->{$_});
    }
    if(exists $self->{member}){
        $hash->{member} = [];
        if(ref $self->{member} eq "ARRAY"){
            for my $m(@{$self->{member}}){
                my $member_hash = $m->to_json_hash();
                push @{$hash->{member}},$member_hash;
            }
        }
    }

    return $hash;
}
sub dump{
    my $self = shift;
    my $clone = {};
    my $obj_name = blessed($self);
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
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    $self->{_client}->print("Object($obj_name) " . Data::Dumper::Dumper($clone));
    return $self;
}

sub type{
    my $self = shift;
    my %map = (
        "Mojo::Webqq::Friend"           => "friend",
        "Mojo::Webqq::Group"            => "group",
        "Mojo::Webqq::Group::Member"    => "group_member",
        "Mojo::Webqq::Discuss"          => "discuss",
        "Mojo::Webqq::Disucc::Member"   => "discuss_member",
        "Mojo::Webqq::User"             => "user",
        "Mojo::Webqq::Recent::Friend"   => "recent_friend",
        "Mojo::Webqq::Recent::Group"    => "recent_group",
        "Mojo::Webqq::Recent::Discuss"  => "recent_discuss",
    ); 
    return $map{ref($self)};
}

sub is_friend{
    my $self = shift;
    ref $self eq "Mojo::Webqq::Friend"?1:0;
}
sub is_group{
    my $self = shift;
    ref $self eq "Mojo::Webqq::Group"?1:0;
}
sub is_group_member{
    my $self = shift;
    ref $self eq "Mojo::Webqq::Group::Member"?1:0;
}
sub is_discuss{
    my $self = shift;
    ref $self eq "Mojo::Webqq::Discuss"?1:0;
}
sub is_discuss_member{
    my $self = shift;
    ref $self eq "Mojo::Webqq::Discuss::Member"?1:0;
}
sub is_me{
    my $self = shift;
    return 1 if ref $self eq "Mojo::Webqq::User";
    if($self->is_group_member or $self->is_discuss_member){
        return 1 if $self->id eq $self->{_client}->user->id;  
    } 
    return 0;
}

1;
