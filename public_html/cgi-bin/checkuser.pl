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

sub local_css()
{
    print qq{
<style>
</style>
};
}

sub list_all_reports {

    my $query = q{
        SELECT *
        FROM ry_test_reports a, ry_tests b, ry_users c, ry_test_types d
        WHERE a.rpt_tst_id = b.tst_id
        AND a.rpt_userid = c.userid
        AND b.tst_type = d.tst_type_id
        AND a.rpt_userid = ?
        ORDER BY a.rpt_tst_id;
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($FORM{'target_user'});

    print qq{
        <div>
        <h3> Test Reports </h3>
        <table>
            <tr>
                <th> User Name </th>
                <th> Test ID </th>
                <th> Test Type </th>
                <th> Test Title </th>
                <th> Total </th>
                <th> Correct </th>
                <th> Wrong </th>
                <th> Skip </th>
                <th> Created </th>
                <th> Percentage </th>
            </tr>
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        my $pc = ($ROW{'rpt_q_correct'} / $ROW{'rpt_q_total'}) * 100;

        print qq{
            <tr>
                <td> $ROW{'username'} </td>
                <td> $ROW{'tst_id'} </td>
                <td> $ROW{'tst_type_nick'} </td>
                <td> $ROW{'tst_title'} </td>
                <td> $ROW{'rpt_q_total'} </td>
                <td> $ROW{'rpt_q_correct'} </td>
                <td> $ROW{'rpt_q_wrong'} </td>
                <td> $ROW{'rpt_q_skip'} </td>
                <td> $ROW{'rpt_created'} </td>
                <td> $pc </td>
            </tr>
        };
    }

    print qq{
        </table>
        </div>
    };
}

sub list_tests_not_yet_taken {
    my $sid = $SESSION{'sid'};

    my $query = q{
        SELECT *
        FROM ry_tests a, ry_users b, ry_test_types c, ry_test_states d
        WHERE a.tst_type = c.tst_type_id
        AND a.tst_owner = b.userid
        AND a.tst_owner = ?
        AND a.tst_state = d.tstate_id
        AND a.tst_state = 2
        AND a.tst_id NOT IN (SELECT sch_tst_id FROM ry_test_schedule WHERE sch_userid = ?)
        AND a.tst_id IN (SELECT t2t_tid FROM ry_user2tag a, ry_test2tag b WHERE a.u2t_tagid = b.t2t_tagid AND a.u2t_userid = ?)
        ORDER BY a.tst_id;
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($SESSION{'userid'}, $FORM{'target_user'}, $FORM{'target_user'}) or die $DBH->errstr();

    print qq{
        <div>
        <h3> Tests Not Yet Taken </h3>
        <table>
            <tr>
                <th> User Name </th>
                <th> Test ID </th>
                <th> Test Type </th>
                <th> Test Title </th>
                <th> State </th>
                <th> Schedule </th>
            </tr>
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        print qq{
            <tr>
                <td> $ROW{'username'} </td>
                <td> $ROW{'tst_id'} </td>
                <td> $ROW{'tst_type_nick'} </td>
                <td> $ROW{'tst_title'} </td>
                <td> $ROW{'tstate_nick'} </td>
                <td> 
                    <form action="test-schedule.pl?sid=$sid" method="post">
                        <input type="hidden" name="sid" value="$sid" />
                        <input type="hidden" name="selected_tst_id" value="$ROW{'tst_id'}" />
                        <input type="hidden" name="selected_username" value="$FORM{'target_user'}" />
                        <input type="submit" name="schedule" value="Schedule" />
                    </form>
                </td>
            </tr>
        };
    }

    print qq{
        </table>
        </div>
    };
}

sub list_all_tests {

    my $query = q{
        SELECT *
        FROM ry_test_schedule a, ry_tests b, ry_users c, ry_test_types d, ry_exam_states e
        WHERE a.sch_tst_id = b.tst_id
        AND a.sch_userid = c.userid
        AND b.tst_type = d.tst_type_id
        AND a.sch_exam_state = e.exam_state_id
        AND a.sch_tst_giver = ?
        AND a.sch_userid = ?
        ORDER BY a.sch_exam_state;
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($SESSION{'userid'}, $FORM{'target_user'});

    print qq{
        <div>
        <h3> Tests Taken </h3>
        <table>
            <tr>
                <th> User Name </th>
                <th> Test ID </th>
                <th> Test Type </th>
                <th> Test Title </th>
                <th> State </th>
                <th> Schedule From </th>
                <th> Schedule To </th>
            </tr>
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        print qq{
            <tr>
                <td> $ROW{'username'} </td>
                <td> $ROW{'tst_id'} </td>
                <td> $ROW{'tst_type_nick'} </td>
                <td> $ROW{'tst_title'} </td>
                <td> $ROW{'exam_state_name'} </td>
                <td> $ROW{'sch_from'} </td>
                <td> $ROW{'sch_to'} </td>
            </tr>
        };
    }

    print qq{
        </table>
        </div>
    };
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";

    link_css();
    local_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    list_all_tests();
    list_all_reports();
    list_tests_not_yet_taken();

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
