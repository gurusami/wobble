#!/usr/bin/perl
# Created: Fri 18 Sep 2020 04:59:38 PM IST
# Last-Updated: Fri 18 Sep 2020 04:59:38 PM IST
# Time-stamp: <2020-09-11 15:10:58 annamalai>
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
    my $row_href = get_tst_info($DBH, $FORM{'tst_id'});
    my %row = %{$row_href};

    $SESSION{'tst_id'} = $row{'tst_id'};
    $SESSION{'tst_qst_count'} = $row{'tst_qst_count'};
    $SESSION{'tst_title'} = $row{'tst_title'};

    my $userid = $SESSION{'userid'};
    my $tst_id = $FORM{'tst_id'};

    $SESSION{'can_take'} = can_take_test($DBH, $userid, $tst_id);

    if (! defined $FORM{'cur_seq'}) {
        $FORM{'cur_seq'} = 1;
    }

    $SESSION{'qid'} = get_nth_qid_in_tst($DBH, $tst_id, $FORM{'cur_seq'});
    my $qid = $SESSION{'qid'};

    if (defined $FORM{'next'}) {
        $FORM{'cur_seq'}++;
        $SESSION{'qid'} = get_nth_qid_in_tst($DBH, $tst_id, $FORM{'cur_seq'});
        $qid = $SESSION{'qid'};
    } elsif (defined $FORM{'prev'}) {
        $FORM{'cur_seq'}--;
        $SESSION{'qid'} = get_nth_qid_in_tst($DBH, $tst_id, $FORM{'cur_seq'});
        $qid = $SESSION{'qid'};
    } elsif (defined $FORM{'answer'}) {
        if (defined $FORM{'choice'} && $FORM{'choice'} > 0) {
            my $given = $FORM{'choice'};
            give_answer($DBH, $SESSION{'userid'}, $tst_id,
                    $SESSION{'qid'}, $given);
        } elsif (defined $FORM{'give_answer_string'}) {
            my $given = $FORM{'give_answer_string'};
            modify_user_given_string($DBH, $userid, $tst_id, $qid, $given);
        } elsif (defined $FORM{'give_answer_number'}) {
            my $given = $FORM{'give_answer_number'};
            give_answer($DBH, $userid, $tst_id, $qid, $given);
        } else {
            die "No choice defined";
        }
    }

    if (defined $FORM{'locktest'}) {
        # Mark the test as submitted.  No more changes are allowed.
        mark_test_submitted($DBH, $SESSION{'userid'}, $tst_id);
    }

    $FORM{'choice'} = fetch_user_given_answer(
            $DBH, $SESSION{'userid'}, $tst_id, 
            $SESSION{'qid'});

    $SESSION{'test_submitted'} = is_test_submitted(
            $DBH, $SESSION{'userid'}, $tst_id);

}

sub show_links_to_each_question {
    my $sid = $SESSION{'sid'};
    my $N = $SESSION{'tst_qst_count'};
    my $tst_id = $FORM{'tst_id'};
    my $qid = $SESSION{'cur_qid'};
    my $userid = $SESSION{'userid'};

    print qq{
        <div style="text-align: center;" >
            <ul style="list-style: none; display: inline; ">
                <li style="list-style: none; display: inline; "> Direct Question Links: </li>
    };

    my $query = qq{
        SELECT *
        FROM ry_test_attempts a, ry_test_questions b
        WHERE a.att_tst_id = b.tq_tst_id
        AND a.att_userid = ?
        AND a.att_tst_id = ?
        AND b.tq_tst_id = ?
        AND a.att_qid = b.tq_qid
        ORDER BY b.tq_qid_seq
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($userid, $tst_id, $tst_id) or die $DBH->errstr();

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        my $gave = $ROW{'att_gave'};
        my $bg = "";
        my $i = $ROW{'tq_qid_seq'};

        if (! defined $gave || $gave == 0) {
            $bg = "";
        } else {
            $bg = "background-color: Navy; color: white";
        }

        print qq{
                <li style="list-style: none; display: inline; $bg; margin-left: 10px; padding-left: 10px; padding-right: 10px;">
                        <a style="$bg;" href="taketest.pl?sid=$sid&tst_id=$tst_id&cur_seq=$i">$i</a> </li>
        };
    }

    print qq{
            </ul>
        </div>
    };
}

sub show_test_result() {

    my $query = "SELECT rpt_q_total, rpt_q_correct, rpt_q_wrong, rpt_q_skip FROM ry_test_reports WHERE rpt_userid = ? AND rpt_tst_id = ?";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($SESSION{'userid'}, $FORM{'tst_id'}) or die $DBH->errstr();

    my ($total, $correct, $wrong, $skipped) = $stmt->fetchrow();
    $stmt->finish;
    
    print qq{
    <h2> Test Results </h2>
	<table>
	<tr> <td> Total Questions </td> <td> $total </td> </tr>
	<tr> <td> Correct Answers </td> <td> $correct </td> </tr>
	<tr> <td> Skipped Questions </td> <td> $skipped </td> </tr>
	<tr> <td> Wrong Answers </td> <td> $wrong </td> </tr>
	</table>
    }
}
    
sub show_test_details {
    print qq{
        <div class="test-details-container">
            <div class="title"> Test ID: $SESSION{'tst_id'} </div>
            <div class="title"> Test Title: $SESSION{'tst_title'} </div>
            <div class="title"> Total Questions: $SESSION{'tst_qst_count'} </div>
            <div class="title"> Current Question: $FORM{'cur_seq'} </div>
            <div class="title">
    };

    if ($SESSION{'test_submitted'} == 0) {
        print qq{
                <form action="taketest.pl" method="post">
                <input type="hidden" name="sid" value="$SESSION{'sid'}" />
                <input type="hidden" name="tst_id" value="$SESSION{'tst_id'}" />
                <input type="submit" name="locktest" value="Submit Test" />
                </form>
        };
    }	
    print q{
        </div>
        </div> <!-- test-details-container -->
    };
}

sub show_numberbox_for_answer {
    my $sid = $SESSION{'sid'};
    my $userid = $SESSION{'userid'};
    my $tst_id = $SESSION{'tst_id'};
    my $qid = $SESSION{'cur_qid'};
    my $locked = $SESSION{'test_submitted'};
    my $readonly = "";

    my $given = fetch_user_given_answer($DBH, $userid, $tst_id, $qid);

    if (! defined $given) {
        $given = "";
    }

    if (defined $locked && $locked == 1) {
        $readonly = "readonly";
    }

    print qq{
    <input type="number" size="80" name="give_answer_number" value="$given" $readonly/>
};
}

sub show_textbox_for_answer() {
    my $sid = $SESSION{'sid'};
    my $userid = $SESSION{'userid'};
    my $tst_id = $SESSION{'tst_id'};
    my $qid = $SESSION{'cur_qid'};
    my $locked = $SESSION{'test_submitted'};
    my $readonly = "";

    my $given = select_user_given_string($DBH, $userid, $tst_id, $qid);

    if (! defined $given) {
        $given = "";
    }

    if (defined $locked && $locked == 1) {
        $readonly = "readonly";
    }

    print qq{
        <textarea rows="10" cols="80" name="give_answer_string" $readonly>$given</textarea>
    };
}

sub show_choices {
    my $qtype = shift;
    my $sid = $SESSION{'sid'};

    my $locked = $SESSION{'test_submitted'};
    my $qid = $SESSION{'cur_qid'};
    my $query = "SELECT chid, choice_html FROM answer_2 WHERE qid = ? ORDER BY chid";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($qid) or die $DBH->errstr();

    if ($qtype == 1) {
        # The answer is to be given as a single integer
        show_numberbox_for_answer();
    } else {

        my $user_choice = $FORM{'choice'};

        print qq{<ul class="no-bullets">};
        while (my ($chid, $choice_html) = $stmt->fetchrow())
        {
            my $cell_val;
            if ($locked == 0) {
# Not locked.  User can give answer.
                my $checked = "";

                if (defined $FORM{'choice'} && $FORM{'choice'} == $chid) {
                    $checked = "checked";
                }

                if (! defined $choice_html) {
                    $choice_html = "";
                }
                $cell_val = qq{<input type="radio" name="choice" value="$chid" $checked/>};
            } else {
# Locked.  User cannot change answer.
                my $color;

                if ($user_choice == $chid) {
                    $color = "yellow";
                }

                $cell_val = qq{<p style="background-color: $color;">$chid</p>};
            }

            print qq{
                <li> 
                    $cell_val $choice_html
                    </li> };
        }
        print qq{</ul>};

    }

    $stmt->finish();
}

sub show_mcq {
    my $qid_seq = $FORM{'cur_seq'};
    my $tst_id = $SESSION{'tst_id'};
    my $qid = get_nth_qid_in_tst($DBH, $tst_id, $qid_seq);
    $SESSION{'cur_qid'} = $qid;
    my $row_href = select_question($DBH, $qid);
    my %row = %{$row_href};

    print qq{<h3> Question (QID: $qid) </h3>
        <p> $row{'qhtml'} </p>};

    if ($row{'qtype'} == 4) {
# The answer is to be given as a string.
        show_textbox_for_answer();
    } else {
        show_choices($row{'qtype'});
    }
}

sub local_css {
    print qq{
<style>

ul.no-bullets {
    list-style-type: none;
}

.test-details-container {
    display: grid;
    grid-column-gap: 1px;
    background-color: var(--light-bg-color);
    grid-template-columns: auto auto auto auto auto;
}

.submit-container {
    display: grid;
    background-color: var(--dark-bg-color);
    grid-template-columns: auto auto auto;
    width: 90%;
    margin-left: auto;
    margin-right: auto;
    text-align: center;
    padding-left: 2px;
    padding-top: 2px;
    padding-bottom: 2px;
    margin-bottom: 1px;
    height: auto;
}

#choice_table {
    align: left;
    border: none;
    text-align: left;
    width: 100%;
}

div.title {
    display: table-cell;
    vertical-align: middle;
    margin-top: 0px;
    margin-bottom: 0px;
    padding-top: 0px;
    padding-bottom: 0px;
    height: auto;
}

</style>
};

}

sub doc_begin {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Take a Test </title>";
    link_css();
    local_css();
    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});
}

sub doc_end {
    print q{</body></html>};
}

sub display_status {
    if (defined $FORM{'answer'}) {
        print qq{
            <div class="report-status">
                <h3> Answer submitted successfully. </h3>
                </div>
        };
    }
}

sub DISPLAY {
    my $userid = $SESSION{'userid'};
    my $tst_id = $SESSION{'tst_id'};

    doc_begin();
    show_test_details();
    display_status();

    if ($SESSION{'can_take'} == 0 ) {
        my $row_href = get_schedule($DBH, $userid, $tst_id);
        my %ROW = %{$row_href};
        print qq{
            <h2> The test can only be taken between $ROW{'sch_from'} and $ROW{'sch_to'}. </h2>
        };
    } else {

        show_links_to_each_question();

        print qq{
            <form action="taketest.pl?sid=$SESSION{'sid'}" method="POST">
                <div>
        };

        show_mcq();

        print qq{
            </div>
                <input type="hidden" name="sid" value="$SESSION{'sid'}" />
                <input type="hidden" name="cur_seq" value="$FORM{'cur_seq'}" />
                <input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />
        };

        my $answer_disable = "";

        if ($SESSION{'test_submitted'} == 1) {
            $answer_disable = "disabled";
        }

        my $next_disable = "";

        if ($FORM{'cur_seq'} >= $SESSION{'tst_qst_count'}) {
            $next_disable = "disabled";
        }

        my $prev_disable = "";

        if ($FORM{'cur_seq'} <= 1) {
            $prev_disable = "disabled";
        }

        print qq{
            <div class="submit-container">
                <div>
                <input type="submit" name="prev" value="Previous Question" $prev_disable />
                </div>
                <div>
                <input type="submit" name="answer" value="Submit Answer" $answer_disable />
                </div>
                <div>
                <input type="submit" name="next" value="Next Question" $next_disable />
                </div>
                </div>
        };

        print q{
            </form>};

    }
    doc_end();
}

# Before going to display, ensure that needed information is available.
sub CHECK_ERRORS {
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    CHECK_AUTH($DBH, $SESSION{'sid'}, $ENV{'SCRIPT_NAME'}, $SESSION{'userid'});
    PROCESS();

    CHECK_ERRORS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
