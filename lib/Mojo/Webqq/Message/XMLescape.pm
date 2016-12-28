#my %XML_ESCAPE_MAP = (
#    '&amp;'  => '&',
#    '&lt;'  => '<',
#    '&gt;'  => '>',
#    '&quot;'  => '"',
#    '&#39;' => '\'', 
#    '&apos;' => '\'',
#    '&nbsp;' => ' ',
#    '&#92;'  => "\\",
#);
use Encode ();
use Mojo::Util qw();
sub Mojo::Webqq::xmlescape_parse {
    my $self = shift;
    my $data = shift;
    return $data if not defined $data;
    $data=~s/&nbsp;/ /g;
    $data = Mojo::Util::html_unescape($data);
    return $data;
}
1;
