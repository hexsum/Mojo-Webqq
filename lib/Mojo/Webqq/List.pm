package Mojo::Webqq::List;
use Mojo::Webqq::Base 'Mojo::EventEmitter';
sub new{
    my $class = shift;
    my %opt = @_;
    my $self = {
        max_size => $opt{max_size},
        _data => [],
    };
    return bless $self,$class;
}

sub empty {
    my $self = shift;
    @{$self->{_data}} = ();
    return $self;
}
sub size {
    my $self = shift;
    return 0+@{$self->{_data}};
}
sub append {
    my $self = shift;
    my $element = shift;
    if(defined $self->{max_size} and @{$self->{_data}} >= $self->{max_size}){
        shift @{$self->{_data}};
    }
    push @{$self->{_data}},$element;
    $self->emit(append => $element);
    return $self;
}
sub list {
    my $self = shift;
    return wantarray?@{$self->{_data}}:$self->{_data};
}
sub pick{
    my $self = shift;
    CORE::shift( @{$self->{_data}} );
}
sub pick_all {
    my $self = shift;
    my @data = @{$self->{_data}};
    $self->empty;
    return wantarray?@data:\@data;
}
1;
