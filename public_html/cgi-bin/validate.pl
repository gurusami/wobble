#!/usr/bin/perl
#
# Created: Mon 21 Sep 2020 09:16:43 PM IST
# Last-Updated: Mon 21 Sep 2020 09:16:43 PM IST
# 
# Time-stamp: <2020-09-09 13:41:07 annamalai>
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
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
    }
}

sub list_tests_to_validate {
    my $query = q{
SELECT c.username AS giver, b.username AS taker, a.sch_tst_id AS tid, d.exam_state_name AS state
FROM ry_test_schedule a, ry_users b, ry_users c, ry_exam_states d
WHERE a.sch_userid = b.userid
AND c.userid = a.sch_tst_giver 
AND a.sch_exam_state = d.exam_state_id
AND a.sch_exam_state = ?
AND a.sch_tst_giver = ?
};

    # my $query = "SELECT * FROM ry_test_schedule WHERE sch_exam_state = ? AND sch_tst_giver = ?";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute(2, $SESSION{'userid'}) or die $DBH->errstr();

    print q{
<table>
    <tr>
        <th> Test Giver </th>
        <th> Test Taker </th>
        <th> Test ID </th>
        <th> Test State </th>
        <th> Validate </th>
    </tr>
};

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        print qq{
<tr>
    <td> $ROW{'giver'} </td>
    <td> $ROW{'taker'} </td>
    <td> $ROW{'tid'} </td>
    <td> $ROW{'state'} </td>
    <td>
        <form action="ticktest.pl?sid=$SESSION{'sid'}" method="post">
        <input type="hidden" name="sid" value="$SESSION{'sid'} " />
        <input type="hidden" name="tst_id" value="$ROW{'tid'} " />
        <input type="submit" name="ticktest" value="Validate" />
        </form>
    </td>
</tr>
};
    }

    print q{</table>};

    $stmt->finish();
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: List Tests To Be Validated </title>";

    link_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});

    print q{
<h2> List of Tests To Be Validated </h2>
};

    list_tests_to_validate();

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
