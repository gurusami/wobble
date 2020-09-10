#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 06:25:44 annamalai>
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
# Created on 07-Sept-2020
#
###########################################################################
#
# Copyright (C) 2020 Annamalai Gurusami.  All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <https://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;

require './profile.pl';
require './utility.pl';

my $DBH;
my %FORM;
my %SESSION;

sub CTOR {
    $DBH = db_connect();
}

sub DTOR {
    $DBH->disconnect();
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};
}

sub PROCESS {
    remove_sessions($DBH, $SESSION{'userid'});
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";

    my $url = login_url();
    
    print qq{
    <body> <p> You have been successfully logged out.
	Go back to <a href="$url">login</a> page </p>};
    
    print "</body>";
    print "</html>";

}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();

    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};
    
    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
