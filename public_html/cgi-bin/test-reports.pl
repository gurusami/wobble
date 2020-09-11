#!/usr/bin/perl
#
# Time-stamp: <2020-09-11 13:42:12 annamalai>
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
}

sub list_my_reports {

    my $query =  q{SELECT rpt_tst_id, rpt_q_total, rpt_q_correct, rpt_q_wrong, rpt_q_skip, rpt_created
		       FROM ry_test_reports WHERE rpt_userid = ? ORDER BY rpt_created DESC};

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($SESSION{'userid'}) or die $DBH->errstr();

    print q{
    <h2> My Test Reports </h2>
	<table>
	<tr> 
	<th> Test ID </th>
	<th> Total Questions </th>
	<th> Correct </th>
	<th> Wrong </th>
	<th> Skipped </th>
	<th> Date </th>
	</tr>
    };


    while (my ($tst_id, $total, $correct, $wrong, $skip, $created) = $stmt->fetchrow()) {

	my $qs=qq{taketest.pl?sid=$SESSION{'sid'}&tst_id=$tst_id};
	
	print qq{
	<tr> 
	    <td> <a href="$qs">$tst_id</a> </td>
	    <td> $total </td>
	    <td> $correct </td>
	    <td> $wrong </td>
	    <td> $skip </td>
	    <td> $created </td>
	    </tr>
	};
    }

    print q{</table>};
    
}


sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});

    list_my_reports();
    print "</body>";
    print "</html>";

}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    CHECK_AUTH($DBH, $SESSION{'sid'}, $ENV{'SCRIPT_NAME'}, $SESSION{'userid'});
    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
