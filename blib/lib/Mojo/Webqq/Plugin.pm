package Mojo::Webqq::Plugin;
sub load {
    my $self = shift;
    my @module_name;
    my %opt;
    if(ref $_[0] eq "ARRAY"){
        @module_name = @{shift @_};
    }
    else{
        push @module_name,shift;
    }
    %opt= @_;
    
    for my $module_name (@module_name){
        my $module_function = undef;
        my $module;
        if(substr($module_name,0,1) eq '+'){
            substr($module_name,0,1) = "";
            $module = $module_name;
        }
        else{
            $module = "Mojo::Webqq::Plugin::" . $module_name;
        }
        eval "require $module";
        $self->die("加载插件[ $module ]失败: $@\n") if $@;
        $module_function = *{"${module}::call"}{CODE};
        $self->die("加载插件[ $module ]失败: 未获取到call函数引用\n") if ref $module_function ne 'CODE';
        $self->debug("加载插件[ $module ]");
        $self->plugins->{$module}{code} = $module_function;
        $self->plugins->{$module}{name} = $module;
        $self->plugins->{$module}{data} = $opt{data};
        $self->plugins->{$module}{priority} = $opt{priority} || eval "\$${module}::PRIORITY" ||  0;
        $self->plugins->{$module}{call_on_load} = $opt{call_on_load} || eval "\$${module}::CALL_ON_LOAD" ||  0;
        if($self->plugins->{$module}{call_on_load}){
            $self->emit("plugin_load",$module);
            $self->call($module);
        }
        else{
            $self->plugins->{$module}{auto_call} = $opt{auto_call} || eval "\$${module}::AUTO_CALL" || 1 ;
            $self->emit("plugin_load",$module);
        }
    }
    return $self;
}

sub call{
    my $self = shift;
    my @plugins;
    if(ref $_[0] eq 'ARRAY'){
        @plugins = @{$_[0]};
        shift;
    }
    else{
        push @plugins,$_[0];
        shift;
    }
    for(sort {$self->plugins->{$b}{priority} <=> $self->plugins->{$a}{priority}} @plugins){
        if(exists $self->plugins->{$_}){
            $self->info("执行插件[ $_ ]");
            eval {
                &{$self->plugins->{$_}{code}}($self,$self->plugins->{$_}{data},@_);   
            };
            if($@){
                $self->error("插件[ $_ ]执行错误: $@");            
                next;
            }
            $self->emit("plugin_call",$_);
        }
        else{
            $self->error("运行插件[ $_ ]失败：找不到该插件"); 
        }
    }
    return $self;
}

1;
