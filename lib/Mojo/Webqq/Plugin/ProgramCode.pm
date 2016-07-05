package Mojo::Webqq::Plugin::ProgramCode;
our $PRIORITY = 94;
use Encode;
=head1 SYNOPSIS
    Support 26 kinds of programming languages
    usage:
        code|cpp>>>...your program code...
    cpp
        code|cpp>>>
        #include <iostream>
        using namespace std;
        int main() {
            cout << "Hello World!";
            return 0;
        }
    c
        code|c>>>
        #include <stdio.h>
        int main() {
            printf("Hello World!\n");
            return 0;
        }
    csharp
        code|csharp>>>
        using System;
        class MainClass {
            static void Main() {
                Console.WriteLine("Hello World!");
            }
        }
    d   
        code|d>>>
        import std.stdio;
        void main()
        {
            writeln("Hello World!");
        }
    erlang
        code|erlang>>>
        main(_) ->
            io:format("Hello World!~n").
    go
        code|go>>>
        package main
        import (
            "fmt"
        )
        func main() {
            fmt.Println("Hello World!")
        }
    idris
        code|idris>>>
        module Main
        main : IO ()
        main = putStrLn "Hello World!"
    java
        code|java>>>
        public class Main {
            public static void main(String[] args) {
                System.out.println("Hello World!");
            }
        }
    scala
        code|scala>>>
        object Main extends App {
            println("Hello World!")
        }
    php
        code|php>>>
        <?php
        echo "Hello World\n";
    rust
        code|rust>>>
        fn main() {
            println!("Hello World!");
        }
    assembly
        code|assembly>>>
        section .data
            msg db "Hello World!", 0ah
        section .text
            global _start
        _start:
            mov rax, 1
            mov rdi, 1
            mov rsi, msg
            mov rdx, 13
            syscall
            mov rax, 60
            mov rdi, 0
            syscall
=cut
my %languages = (
    #code|ruby>>>
    ruby    =>  'main.rb',#code|ruby>>>puts "Hello World!"
    perl    =>  'main.pl',#code|perl>>>print "Hello World!\n";
    clojure =>  'main.clj',#code|clojure>>>(println "Hello World!")
    coffeescript    =>  'main.coffee',#code|coffeescript>>>console.log "Hello World!"
    bash    =>  'main.sh',#code|bash>>>echo Hello World
    cpp =>  'main.cpp',
    c   =>  'main.c',
    assembly    =>  'main.asm',
    java    =>  '.java',
    scala => "main.scala",
    csharp  =>  'main.cs',
    d   =>  'main.d',
    erlang  =>  'main.erl',
    go  =>  'main.go',
    idris   =>  'main.idr',
    rust => "main.rs",
    php =>  'main.php',
    elixir  =>  'main.ex',#code|elixir>>>IO.puts "Hello World!"
    fsharp  =>  'main.fs',#code|fsharp>>>printfn "Hello World!"
    haskell =>  'main.hs',#code|haskell>>>main = putStrLn "Hello World!"
    javascript  =>  'main.js',#code|javascript>>>console.log("Hello World!");
    julia   =>  'main.jl',#code|julia>>>println("Hello world!")
    lua =>  'main.lua',#code|lua>>>print("Hello World!");
    nim =>  'main.nim',#code|nim>>>echo("Hello World!")
    ocaml   =>  'main.ml',#code|ocaml>>>print_endline "Hello World!"
    python => "main.py",#code|python>>>print("Hello World!")
);
sub call{
    my $client = shift;
    my $data = shift;
    my $callback = sub{
        my($client,$msg)=@_;
        if ($msg->content =~ m/^code\s*\|\s*([a-zA-z]+?)\s*>>>(.*)/s) {
            my $language = $1;
            my $code = $2;
            return if not $msg->allow_plugin;
            return if $msg->msg_class eq "send" and $msg->msg_from ne "api" and $msg->msg_from ne "irc";
            return if not exists $languages{$language};
            return if not $code;
            $msg->allow_plugin(0);
            my $url = "https://glot.io/run/$language?version=latest";
            my $filename = $languages{$language};
            if ($language eq 'java') {
                $msg->{content} =~ m/class\s+([\w]+)/g;
                $filename = $1.$languages{$language};
            }
            my %r = (
                files   =>      [{name=>decode("utf8",$filename),content=>decode("utf8",$code)}],
                command =>      "",
                stdin   =>      "",
            );
            $client->http_post($url,{json => 1,Referer => "https://glot.io/run/$language?version=latest"},json=>\%r,sub{
                my $json = shift;
                return unless defined $json;
                if ($json->{stdout}) {
                    $client->reply_message($msg,"执行<$language>结果：---->\n".encode("utf8",$json->{stdout}));
                }else{
                    $client->reply_message($msg,"执行<$language>出错：---->\n".encode("utf8",$json->{stdout})."--->".encode("utf8",$json->{error})."--->".encode("utf8",$json->{stderr}));
                }
            });
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}
