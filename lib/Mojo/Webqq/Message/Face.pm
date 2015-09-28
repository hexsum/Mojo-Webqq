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
    21  飞吻
    23  跳跳
    25  发抖
    26  怄火
    27  爱情
    29  足球
    32  西瓜
    33  玫瑰
    34  凋谢
    36  爱心
    37  心碎
    38  蛋糕
    39  礼物
    42  太阳
    45  月亮
    46  强  
    47  弱
    50  难过
    51  酷  
    53  抓狂
    54  吐  
    55  惊恐
    56  流汗
    57  憨笑
    58  大兵
    59  猪头
    62  拥抱
    63  咖啡
    64  饭
    71  握手
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
    86  骷髅
    87  敲打
    88  再见
    91  闪电
    92  炸弹
    93  刀
    95  胜利
    96  冷汗
    97  擦汗
    98  抠鼻
    99  鼓掌
    100 糗大了
    101 坏笑
    102 左哼哼
    103 右哼哼
    104 哈欠
    105 鄙视
    106 委屈
    107 快哭了
    108 阴险
    109 亲亲
    110 吓
    111 可怜
    112 菜刀
    113 啤酒
    114 篮球
    115 乒乓
    116 示爱
    117 瓢虫
    118 抱拳
    119 勾引
    120 拳头
    121 差劲
    122 爱你
    123 NO
    124 OK
    125 转圈
    126 磕头
    127 回头
    128 跳绳
    129 挥手
    130 激动
    131 街舞
    132 献吻
    133 左太极
    134 右太极
);
my %FACEID_MAP = reverse %FACE_MAP;
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
sub Mojo::Webqq::Message::face_parse {
    my $self = shift;
    my $data = shift;
    my @result;
    my $index = 0;
    my $last_face_start = undef;
    my $last_face_end = undef;
    while($data=~/\[[^\[\]]+\]/g){
        my $face = substr($&,1,length($&)-2);
        if(exists $FACEID_MAP{$face}){
            $last_face_start = $-[0];
            $last_face_end = $+[0]-1;
            push @result,{content=>substr($data,$index,$-[0]-$index),type=>"txt"} if $-[0]-$index >0;
            push @result,{content=>$&,id=>$FACEID_MAP{$face},type=>"face"};
            $index = $+[0];
        }
    }
    if(defined $last_face_end){
        push @result,{content=>substr($data,$last_face_end+1),type=>"txt"} if $last_face_end+1 < length($data);
    }
    else{
        push @result,{content=>$data,type=>"txt"};
    }
    return \@result;
}
1;
