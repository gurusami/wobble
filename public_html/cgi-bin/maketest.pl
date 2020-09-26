#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 06:34:02 annamalai>
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
my %ROW;

sub CTOR {
    $DBH = db_connect();
}

sub DTOR {
    $DBH->disconnect();
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};
    if (! defined $FORM{'qid_min'}) {
	$FORM{'qid_min'} = 0;
    }
    $FORM{'qid_count'} = 10;
}

sub show_test_details {
    my $sid = $SESSION{'sid'};
    my $disable = "";
    my $query = q{
        SELECT tst_id, tst_qst_count, tst_type, tst_title, tst_owner, tst_created_on, b.tstate_nick AS tst_state_nick, a.tst_state
            FROM ry_tests a, ry_test_states b
            WHERE a.tst_state = b.tstate_id
            AND tst_id = ?
    };
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($FORM{'tst_id'}) or die $DBH->errstr();
    my ($tst_id, $tst_qst_count, $tst_type, $tst_title, $tst_owner, $tst_created_on, $tst_state_nick, $tst_state) = $stmt->fetchrow();

    if ($tst_state == 2) {
        $disable = "disabled";
    }

    print qq{
        <div>
            <h2 align="center"> Test Information </h2>
            <table align="center">
            <tr>
            <th> Test ID </th> <th> Question Count </th> <th> Type </th> <th> Title </th> <th> Owner </th> <th> Created On </th>
            <th> State </th>
            <th> Make Active </th>
            </tr>
            <tr>
    };

    print qq{
        <td> $tst_id </td> <td> $tst_qst_count </td> <td> $tst_type </td>
            <td> $tst_title </td> <td> $tst_owner </td> <td> $tst_created_on </td>
            <td> $tst_state_nick </td>
            <td>
            <form action="maketest.pl?sid=$sid" method="post">
            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="tst_id" value="$tst_id" />
            <input type="submit" name="make_test_active" value="Make Active" $disable/>
            </form>
            </td>
    };
    print q{</tr>};
    print q{
        </table>
            </div>
    };
}

sub show_questions_in_test {
    my $sid = $SESSION{'sid'};
    my $qlist_aref = get_qid_in_tst($DBH, $FORM{'tst_id'});
    my @qlist = @{$qlist_aref};

    my $N = 1 + $#qlist;

    print qq{
        <div>
            <h2 align="center"> Questions in Test (Total: $N) </h2>
    };

    if (@qlist > 0) {
        my $query = "SELECT qid, qtype, qhtml, b.qst_type_nick, c.ref_nick
            FROM question a, ry_qst_types b, ry_biblio c WHERE a.qsrc_ref = c.ref_id AND a.qtype = b.qst_type_id AND qid IN (" . join(',', @qlist) . ")";
        my $stmt = $DBH->prepare($query);
        $stmt->execute();

        print q{<table align="center">};
        print qq{<tr> <th> QID </th> <th> Question Type </th> <th> Reference </th> <th> Question </th>};

        if ($ROW{'tst_state'} == 1) {
            print qq{ <th> Remove </th> </tr>};
        }

        while (my ($qid, $qtype, $qhtml, $qst_type_nick, $ref_nick) = $stmt->fetchrow()) {
            print q{<tr>} . "\n";
            print qq{<td> $qid </td> <td> $qst_type_nick </td>
                <td> $ref_nick </td>
                    <td> $qhtml </td>};

            # Show the remove button only if the test is in preparation stage.
            if ($ROW{'tst_state'} == 1) {
                print qq{
                    <td>
                        <form action="maketest.pl?sid=$sid" method="post">
                        <input type="hidden" name="sid" value="$sid" />
                        <input type="hidden" name="qid" value="$qid" />
                        <input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />
                        <input type="submit" name="remove_from_test" value="Remove" />
                        <input type="hidden" name="qid_min" value="$FORM{'qid_min'}" />
                        </form>
                        </td>
                };
            }
            print qq{</tr>};
        }
        print q{
            </table> </div>
        };
    }
}

sub show_questions {
    my $sid = $SESSION{'sid'};
    my $tst_id = $FORM{'tst_id'};
    my $query = q{
SELECT qid, qtype, qst_type_nick, qhtml, c.ref_nick AS ref_nick
FROM question a, ry_qst_types b, ry_biblio c
WHERE a.qtype = b.qst_type_id
AND a.qsrc_ref = c.ref_id
AND qid > ?
AND qid NOT IN (SELECT tq_qid FROM ry_test_questions WHERE tq_tst_id = ?)
ORDER BY qid LIMIT ?
};
    my $stmt = $DBH->prepare($query);
    $stmt->execute($FORM{'qid_min'}, $tst_id, $FORM{'qid_count'});

    print q{<h2 align="center"> Available Questions </h2>};

    print q{<div id="available"> <table align="center">};
    print qq{
        <tr> <th> QID </th> <th> Question Type </th>
            <th> Reference </th>
        <th> Question </th> <th> Add </th> </tr>
    };

    while (my ($qid, $qtype, $qtype_nick, $qhtml, $ref_nick) = $stmt->fetchrow()) {
        print q{<tr>} . "\n";
        print qq{<td> $qid </td> <td> $qtype_nick </td>
            <td> $ref_nick </td>
            <td> $qhtml </td>};
        print qq{<td>
            <form action="maketest.pl?sid=$sid" method="post">
                <input type="hidden" name="sid" value="$sid" />
                <input type="hidden" name="qid" value="$qid" />
                <input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />
                <input type="submit" name="add_to_test" value="Add" />
                <input type="hidden" name="qid_min" value="$FORM{'qid_min'}" />
                </form>
                </td>
                </tr>
        };
    }

    print q{</table> </div>};

    show_qst_navigation();

    $stmt->finish();
}

sub show_nav_form {
    my $sid = $SESSION{'sid'};
    my $name = shift;
    my $qid_min = shift;

    print qq{
<div>
    <form action="maketest.pl?sid=$sid" method="post">
        <input type="hidden" name="sid" value="$sid" />
        <input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />
        <input type="hidden" name="qid_min" value="$qid_min" />
        <input type="hidden" name="qid_count" value="$FORM{'qid_count'}" />
        <input type="submit" name="$name" value="$name" />
    </form>
</div>
}
}

sub show_qst_navigation {
    my $sid = $SESSION{'sid'};
    my $qid_min = $FORM{'qid_min'};
    my $prev_qid = $FORM{'qid_min'};
    my $next_qid = $qid_min + $FORM{'qid_count'};

    if ($FORM{'qid_min'} > $FORM{'qid_count'}) {
        $prev_qid = $FORM{'qid_min'} - $FORM{'qid_count'};
    } else {
        $prev_qid = 0;
    }

    my $max_qid = select_max_qid($DBH);
    my $last_qid = $max_qid - $FORM{'qid_count'};

    print qq{
<div style="width: 80%; margin-left: auto; display: grid; grid-template-columns: auto auto auto auto;">
};

    show_nav_form("First", 0);
    show_nav_form("Prev", $prev_qid);
    show_nav_form("Next", $next_qid);
    show_nav_form("Last", $last_qid);

    print qq{
</div> <!-- grid container -->
};

}

sub PROCESS {
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
        if (defined $FORM{'make_test_active'}) {
            make_test_active($DBH, $FORM{'tst_id'});
        } elsif (defined $FORM{'add_to_test'}) {
            add_question_to_test($DBH, $FORM{'tst_id'}, $FORM{'qid'});
        } elsif (defined $FORM{'remove_from_test'}) {
            remove_question_from_test($DBH, $FORM{'tst_id'}, $FORM{'qid'});
        }
    }

    defined $FORM{'tst_id'} || die "No test identifier";
    my $row_href = get_tst_info($DBH, $FORM{'tst_id'});
    %ROW = %{$row_href};
}

sub CHECK_TST_ID {
    if (! defined $FORM{'tst_id'}) {
	print q{<p> No Test Identifier Specified. </p>};
	exit(0);
    }
}

sub local_css {
    print qq{
<style>
#available {
    width: 80%;
    margin-left: auto;
    margin-right: auto;
}

tr:nth-child(even) {
    background-color: lightblue;
}
</style>
};
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Preparing Test With Test ID: $FORM{'tst_id'} </title>";
    link_css();
    local_css();
    print "</head>" . "\n";

    print "<body>";

    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    CHECK_TST_ID();

    show_test_details();

    print q{<hr>};
    
    show_questions_in_test();

    print q{<hr>};

    if ($ROW{'tst_state'} == 1) {
        show_questions();
    }
    
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
