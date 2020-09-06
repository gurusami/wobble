#!/usr/bin/perl

use strict;
use warnings;

require './utility.pl';

sub MAIN {
    content_type();

    print q{<html>};
    print q{<head>};
    print q{</head>};

    print q{<body>};
    print q{<h1> ____ </h2>};
    print q{</body>};
    
    print q{</html>};
}

MAIN();
