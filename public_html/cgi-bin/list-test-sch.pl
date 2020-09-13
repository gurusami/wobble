#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 06:32:48 annamalai>
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
#
# List ALL the scheduled tests.
#
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

sub list_scheduled_tests {
    my $query =  q{SELECT sch_userid, b.username, sch_tst_id, sch_from, sch_to,
                          sch_submitted, sch_created_on
                   FROM ry_test_schedule a, ry_users b
                   WHERE a.sch_userid = b.userid ORDER BY sch_userid};

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute() or die $DBH->errstr();

    print q{
<table>
  <tr>
    <th> User ID </th>
    <th> User Name </th>
    <th> Test ID </th>
    <th> From Date </th>
    <th> To Date </th>
    <th> Submitted On </th>
    <th> Schedule Created On </th>
  </tr>
};

    while (my ($sch_userid, $username, $sch_tst_id, $sch_from, $sch_to, 
	       $sch_submitted, $sch_created_on) = $stmt->fetchrow()) {

	my $qs=qq{taketest.pl?sid=$SESSION{'sid'}&tst_id=$sch_tst_id};
	
	print qq{
<tr>
  <td> $sch_userid </td>
  <td> $username </td>
  <td> <a href="$qs">$sch_tst_id</a> </td>
  <td> $sch_from </td>
  <td> $sch_to </td>
  <td> $sch_submitted </td>
  <td> $sch_created_on </td>
</tr>
};
    }

    print q{</table>};
    
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    link_css();
    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});

    list_scheduled_tests();
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
