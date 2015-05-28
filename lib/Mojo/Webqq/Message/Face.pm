my %FACE_MAP = qw(
    0   惊讶
    1   撇嘴
    2   色
    3   发呆
    4   得意
    5   流泪
    6   害羞
    7   闭嘴
    8   睡
    9   大哭
    10  尴尬
    11  发怒
    12  调皮
    13  呲牙
    14  微笑
    33  玫瑰
    34  凋谢
    36  爱心
    46  强  
    50  难过
    51  酷  
    53  抓狂
    54  吐  
    55  惊恐
    56  流汗
    57  憨笑
    58  大兵
    72  便便
    73  偷笑
    74  可爱
    75  白眼
    76  傲慢
    77  饥饿
    78  困
    79  奋斗
    80  咒骂
    81  疑问
    82  嘘
    83  晕
    84  折磨
    85  衰
    87  敲打
    96  冷汗
    118 抱拳
    
);
sub Mojo::Webqq::Message::face_to_txt{
    my $self = shift;
    my $face = shift;
    if(ref $face eq 'ARRAY'){
        return "[未知表情]" if $face->[0] ne "face";
        return "[系统表情]" unless exists $FACE_MAP{$face->[1]};
        return "[" . $FACE_MAP{$face->[1]} . "]"; 
    }
    else{
        return $face;
    }
}
1;
