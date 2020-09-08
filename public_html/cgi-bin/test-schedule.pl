#!/usr/bin/perl
#
# Time-stamp: <2020-09-08 22:01:44 annamalai>
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
use File::Basename;

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
}

sub show_existing_tests {
    my $query = "SELECT tst_id, tst_type, tst_owner, tst_created_on, tst_version, tst_title FROM ry_tests ORDER BY tst_id DESC";

    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    print q{<table>};
    print q{<tr> <th> Test ID </th> <th> Test Type </th> <th> Title </th> <th> Version </th> <th> Owner </th> <th> Created On </th> </tr>};
    while (my ($tst_id, $tst_type, $tst_owner, $tst_created_on, $tst_version, $tst_title) = $stmt->fetchrow()) {
	print qq{<tr>} . "\n";
	print qq{<td> $tst_id </td>} . "\n";
	print qq{<td> $tst_type </td> <td> $tst_title </td> <td> $tst_version </td> <td> $tst_owner </td> <td> $tst_created_on </td> </tr>};
    }
    print q{</table>};

    $stmt->finish();

}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});
    show_existing_tests();
    print "</body>";
    print "</html>";
}

sub AUTH_FAILED {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});
    print qq{<p> You are not authorized. </p>};
    print "</body>";
    print "</html>";

    exit(0);
}


sub CHECK_AUTH {
    my $script =  basename($ENV{'SCRIPT_NAME'});
    my $is_allowed = check_acl($DBH, $SESSION{'userid'}, $script);

    if ($is_allowed == 0) {
	AUTH_FAILED();
    }
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};
    CHECK_AUTH();
    
    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
