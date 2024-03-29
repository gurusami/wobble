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
    my $sid=$SESSION{'sid'};
    my $taker=$SESSION{'userid'};

    my $query =  qq{
        SELECT *
        FROM ry_test_reports a, ry_tests b, ry_test_types c
        WHERE a.rpt_tst_id = b.tst_id
        AND b.tst_type = c.tst_type_id
        AND rpt_userid = ?
        ORDER BY rpt_created DESC;
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($SESSION{'userid'}) or die $DBH->errstr();

    print q{
    <h2> My Test Reports </h2>
	<table>
	<tr> 
	<th> Test ID </th>
	<th> Test Type </th>
	<th> Test Title </th>
	<th> Total Questions </th>
	<th> Correct </th>
	<th> Wrong </th>
	<th> Skipped </th>
	<th> Report Created On </th>
	<th> Review </th>
	</tr>
    };


    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        my $tst_id = $ROW{'tst_id'};

        my $qs=qq[taketest.pl?sid=$sid&tst_id=$tst_id];

        print qq{
            <tr> 
                <td> <a href="$qs">$tst_id</a> </td>
                <td> $ROW{'tst_type_nick'} </td>
                <td> $ROW{'tst_title'} </td>
                <td> $ROW{'rpt_q_total'} </td>
                <td> $ROW{'rpt_q_correct'} </td>
                <td> $ROW{'rpt_q_wrong'} </td>
                <td> $ROW{'rpt_q_skip'} </td>
                <td> $ROW{'rpt_created'} </td>
                <td>

                <form action="test-review.pl?sid=$sid" method="post">
                <input type="hidden" name="sid" value="$sid" />
                <input type="hidden" name="taker" value="$taker" />
                <input type="hidden" name="tst_id" value="$tst_id" />
                <input type="submit" name="test_review" value="Test Review" />
                </form>

                </td>
                </tr>
        };
    }

    print q{</table>};
    
}


sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: List My Test Reports </title>";

    link_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

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
