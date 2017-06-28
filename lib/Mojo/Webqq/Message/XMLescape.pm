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
    eval { if($data =~ /[><]/) {
        $data = Encode::decode('utf8', $data); #才不会发生乱码。暂时还没有发现别的字符。
        Encode::_utf8_off($data);
        }       
    };
    return $data;
}
1;
