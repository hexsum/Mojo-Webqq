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
    my $unicode_data = Mojo::Util::html_unescape(Encode::decode("utf8",$data));
    #my $newdata = Mojo::Util::html_unescape($data);
    #eval {
    #    if ($data =~ /\&/ or $newdata =~ /[><&]/) {
    #        $newdata = Encode::decode('utf8', $newdata);
    #        Encode::_utf8_off($newdata);
    #    }       
    #};
    #return $newdata;
    #return $data;
    return Encode::encode("utf8",$unicode_data);
}
1;
