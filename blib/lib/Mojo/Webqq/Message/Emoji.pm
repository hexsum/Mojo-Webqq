my %EMOJI_MAP = qw(
    :100:           100分
    :1234:          1234
    :grinning:      笑嘻嘻
    :joy:           高兴
    :smiley:        微笑
    :emoji:         失望
    :smirk:         假笑
    :pensive:       沉思
    :grin:          露齿而笑
    :wink:          眨眼
    :scream:        尖叫
    :confounded:    糊涂
    :kissing_closed_eyes: 闭上眼睛亲吻
    :stuck_out_tongue_closed_eyes: 闭眼吐舌头
    :relieved:      放心
    :fearful:       担心
    :mask:          戴口罩
    :flushed:       脸红
    :unamused:      无趣
    :cold_sweat:    冒冷汗
    :astonished:    吃惊
    :sob:           流泪
    :stuck_out_tongue_winking_eye: 眨眼吐舌头
    :kissing_heart: 飞吻
    :rage:          愤怒
    :muscle:        秀肌肉
    :punch:         拳头猛击
    :thumbsup:      竖起大拇指
    :point_up:      竖起中指
    :clap:          鼓掌
    :v:             胜利
    :thumbsdown:    大拇指向下
    :pray:          祈祷
    :ok_hand:       OK
    :point_left:    向左指
    :point_right:   向右指
    :point_up_2:    向上指
    :point_down:    向下指
    :eyes:          大眼珠
    :nose:          鼻子
    :lips:          嘴唇
    :ear:           耳朵
    :rice:          米饭
    :spaghetti:     意大利面
    :ramen:         拉面
    :rice_ball:     饭团
    :shaved_ice:    冰沙
    :sushi:         熟食
    :birthday:      生日蛋糕
    :bread:         面包
    :hamburger:     汉堡包
    :egg:           煎鸡蛋
    :fries:         薯条
    :beer:          一杯啤酒
    :beers:         啤酒
    :cocktail:      鸡尾酒
    :coffee:        咖啡
    :apple:         苹果
    :tangerine:     蜜橘
    :strawberry:    草莓
    :watermelon:    西瓜
    :pill:          胶囊
    :smoking:       抽烟
    :christmas_tree: 圣诞树
    :rose:          玫瑰
    :tada:          回头见
    :palm_tree:     椰子树
    :gift_heart:    心形礼物
    :ribbon:        丝带
    :balloon:       气球
    :shell:         贝壳
    :ring:          钻戒
    :bomb:          炸弹
    :crown:         皇冠
    :bell:          铃铛
    :star:          星星
    :sparkles:      闪耀
    :dash:          冲刺
    :sweat_drops:   汗滴
    :fire:          火焰
    :trophy:        奖杯
    :moneybag:      金钱袋
    :zzz:           睡觉
    :zap:           闪电
    :feet:          脚印
    :shit:          大便
    :syringe:       注射器
    :hotsprings:    温泉
    :mailbox:       邮箱
    :key:           钥匙
    :lock:          锁
    :airplane:      飞机
    :bullettrain_side:  子弹头列车
    :red_car:       红色小汽车
    :speedboat:     快艇
    :bike:          自行车
    :racehorse:     赛马
    :rocket:        火箭
    :bus:           公交车
    :boat:          帆船
    :woman:         女人
    :man:           男人
    :girl:          女孩
    :boy:           男孩
    :monkey_face:   猴子脸
    :octopus:       章鱼
    :pig:           猪
    :baby_chick:    小鸡
    :koala:         考拉
    :cow:           奶牛
    :chicken:       鸡
    :frog:          青蛙
    :ghost:         鬼魂
    :skull:         骷髅
    :bug:           毛毛虫
    :tropical_fish: 热带鱼
    :dog:           狗狗
    :tiger:         老虎
    :angel:         天生
    :penguin:       海豚
    :whale:         鲸鱼
    :mouse:         老鼠
    :womans_hat:    女士帽子
    :dress:         礼服
    :lipstick:      唇膏
    :high_heel:     高跟鞋
    :boot:          长筒靴
    :closed_umbrella:   雨伞
    :handbag:       手提袋
    :bikini:        比基尼 
    :shirt:         衬衫 
    :shoe:          鞋子
    :cloud:         多云
    :sunny:         晴天
    :umbrella:      下雨
    :moon:          弯月
    :snowman:       雪人
    :o:             圈
    :x:             叉
    :grey_question: 灰色问号
    :grey_exclamation:  灰色感叹号
    :telephone:     电话
    :camera:        相机
    :iphone:        手机  
    :fax:           传真机
    :computer:      电脑
    :movie_camera:  摄像机
    :microphone:    麦克风
    :gun:           手枪
    :cd:            光盘
    :heartbeat:     心动
    :clubs:         梅花
    :mahjong:       麻将牌
    :part_alternation_mark: 衣架
    :slot_machine:  投币机
    :traffic_light: 红绿灯
    :construction:  施工
    :guitar:        吉他
    :barber:        理发店
    :bath:          浴缸
    :toilet:        坐便器
    :house:         房子
    :church:        教堂
    :bank:          银行
    :hospital:      医院
    :hotel:         旅店
    :atm:           ATM
    :convenience_store: 便利店
    :mens:          男洗手间
    :womens:        女洗手间
);

sub Mojo::Webqq::emoji_parse{
    my $self = shift;
    my $data = shift;
    my @result;
    my $index = 0;
    my $last_emoji_start = undef;
    my $last_emoji_end = undef;
    while($data=~/:[a-z0-9_]+:/g){
        if(exists $EMOJI_MAP{$&}){
            $last_emoji_start = $-[0];
            $last_emoji_end = $+[0]-1;
            push @result,{content=>substr($data,$index,$-[0]-$index),type=>"txt"} if $-[0]-$index >0;
            push @result,{content=>"[$EMOJI_MAP{$&}]",id=>$&,type=>"emoji"};
            $index = $+[0];
        }
    }
    if(defined $last_emoji_end){
        push @result,{content=>substr($data,$last_emoji_end+1),type=>"txt"} if $last_emoji_end+1 < length($data);
    }
    else{
        push @result,{content=>$data,type=>"txt"};
    }
    return \@result;
}
