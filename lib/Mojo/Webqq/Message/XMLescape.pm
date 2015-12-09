my %XML_ESCAPE_MAP = (
    '&amp;'  => '&',
    '&lt;'  => '<',
    '&gt;'  => '>',
    '&quot;'  => '"',
    '&#39;' => '\'' 
);
sub Mojo::Webqq::Message::xmlescape_parse {
    my $self = shift;
    my $data = shift;
    $data=~s/(&lt;|&gt;|&amp;|&quot;|&#39;)/$XML_ESCAPE_MAP{$1}/g; 
    return $data;
}
