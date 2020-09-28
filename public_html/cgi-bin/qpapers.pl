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

sub show_ready_qpapers {
    my $sid = $SESSION{'sid'};

    my $query = qq{
        SELECT * FROM ry_tests a, ry_test_states b, ry_test_types c WHERE a.tst_type = c.tst_type_id AND a.tst_state = b.tstate_id AND a.tst_state = 2
    };

    print qq{
        <div id="main">
        <h2 align="center"> List of Available Question Papers </h2>

        <table>
            <tr> <th> ID </th> <th> Test Type </th> <th> Test Title </th> <th> Total Questions </th> 
                <th> Schedule </th>
                <th> View </th>
            </tr>
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute() or die $DBH->errstr();

    while (my ($row_href) = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        print qq{
            <tr id="rows">
                <td> $ROW{'tst_id'} </td>
                <td> $ROW{'tst_type_nick'} </td>
                <td> $ROW{'tst_title'} </td>
                <td> $ROW{'tst_qst_count'} </td>
                <td>
                    <form action="test-schedule.pl?sid=$sid" method="post">
                        <input type="hidden" name="sid" value="$sid" />
                        <input type="hidden" name="selected_tst_id" value="$ROW{'tst_id'}" />
                        <input type="submit" name="schedule" value="Schedule" />
                    </form>
                </td>
                <td>
                    <form action="looktest.pl?sid=$sid" method="post">
                        <input type="hidden" name="sid" value="$sid" />
                        <input type="hidden" name="tst_id" value="$ROW{'tst_id'}" />
                        <input type="submit" name="looktest" value="View" />
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

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: List of Available Question Papers </title>";

    link_css();
    local_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    show_ready_qpapers();

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
