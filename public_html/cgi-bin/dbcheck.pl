#!/usr/bin/perl

# Time-stamp: <2020-08-27 12:56:51 annamalai>
# Annamalai Gurusami <annamalai.gurusami@gmail.com>

require './utility.pl';

print "Content-type: text/html\n\n";
print <<HTML;
    <html>
    <head>
    <title>A Simple Perl CGI</title>
    </head>
    <body>
    <h1>A Simple Perl CGI</h1>
    <p>Hello World</p>
HTML

print_hash(\%ENV);

print q{
    </body>
    </html>
};

exit; 
