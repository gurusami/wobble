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

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";

    link_css();
    local_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});
    show_test_details();
    show_qsts();
    print "</body>";
    print "</html>";

}

sub show_qsts {
    my $sid = $SESSION{'sid'};
    my $tst_id = $FORM{'tst_id'};
    my $query = q{SELECT * FROM ry_tests a, ry_test_questions b, question c WHERE a.tst_id = b.tq_tst_id AND b.tq_qid = c.qid AND a.tst_id = ? ORDER BY tq_qid_seq};
    my $stmt = $DBH->prepare($query);
    $stmt->execute($tst_id);

    print qq{
<div>
<table>
    <tr>
        <th> S. No </th>
        <th> QID </th>
        <th> Question </th>
    </tr>
};

    while (my ($row_href) = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        print qq{
            <tr>
                <td> $ROW{'tq_qid_seq'} </td>
                <td> <a href="tinker.pl?sid=$sid&qid=$ROW{'qid'}">$ROW{'qid'}</a> </td>
                <td style="border: 1px dotted blue;" > $ROW{'qhtml'} </td>
            </tr>
        };
    }

    print qq{
</table>
</div>
};
}

sub show_test_details {
    my $sid = $SESSION{'sid'};
    my $tst_id = $FORM{'tst_id'};

    my $query = q{
        SELECT *
            FROM ry_tests a, ry_test_states b, ry_test_types c, ry_users d
            WHERE a.tst_state = b.tstate_id
            AND a.tst_type = c.tst_type_id
            AND a.tst_owner = d.userid
            AND tst_id = ?
    };

    my $stmt = $DBH->prepare($query);
    $stmt->execute($tst_id);

    my $row_href = $stmt->fetchrow_hashref();
    my %ROW = %{$row_href};

    my $all_tags = get_tags_for_test($DBH, $tst_id);

    print qq{
        <div>
            <h2 align="center"> Test Information </h2>
            <table align="center">
            <tr>
                <th> Test ID </th> <th> Question Count </th> <th> Type </th> <th> Title </th> <th> Owner </th> <th> Created On </th>
                <th> State </th>
                <th> Tags </th>
            </tr>

            <tr>
                <td> $ROW{'tst_id'} </td>
                <td> $ROW{'tst_qst_count'} </td>
                <td> $ROW{'tst_type_nick'} </td>
                <td> $ROW{'tst_title'} </td>
                <td> $ROW{'username'} </td>
                <td> $ROW{'tst_created_on'} </td>
                <td> $ROW{'tstate_nick'} </td>
                <td> $all_tags </td>
    };
    print q{</tr>};
    print q{
        </table>
            </div>
    };

    $stmt->finish();
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
