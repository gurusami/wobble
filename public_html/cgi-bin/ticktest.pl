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

    # taker is the one who took the test.
    $SESSION{'taker'} = $FORM{'taker'};
    my $taker = $SESSION{'taker'};

    $SESSION{'tst_id'} = $row{'tst_id'};
    $SESSION{'tst_qst_count'} = $row{'tst_qst_count'};
    $SESSION{'tst_title'} = $row{'tst_title'};

    my $userid = $SESSION{'userid'};
    my $tst_id = $FORM{'tst_id'};

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
    } elsif (defined $FORM{'correct'}) {
        mark_correct($DBH, $taker, $tst_id, $qid);
    } elsif (defined $FORM{'wrong'}) {
        mark_wrong($DBH, $taker, $tst_id, $qid);
    } elsif (defined $FORM{'skipped'}) {
        mark_skipped($DBH, $taker, $tst_id, $qid);
    } elsif (defined $FORM{'prepare_report'}) {
        my $total = $SESSION{'tst_qst_count'};
        my $correct = get_correct_count($DBH, $taker, $tst_id);
        my $skipped = get_skipped_count($DBH, $taker, $tst_id);
        my $wrong = get_wrong_count($DBH, $taker, $tst_id);

        my $report_exists = check_for_report($DBH, $taker, $tst_id);

        if ($report_exists == 0) {
            insert_test_report($DBH, $taker, $tst_id, $total, $correct, $wrong, $skipped);
        } else {
            update_test_report($DBH, $taker, $tst_id, $total, $correct, $wrong, $skipped);
        }

        mark_test_validated($DBH, $taker, $tst_id);
    }
}

sub validate_answers {
    my $dbh = shift;
    my $userid = shift;
    my $tst_id = shift;

    $dbh->begin_work();

    my $query = "SELECT * FROM ry_test_attempts WHERE att_userid = ? AND att_tst_id = ? FOR UPDATE";
    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    my $update_query = "UPDATE ry_test_attempts SET att_result = ? WHERE att_userid = ? AND att_tst_id = ?";
    my $upd_stmt = $dbh->prepare($update_query) or die $dbh->errstr();

    $stmt->execute($userid, $tst_id) or die $dbh->errstr();

    while (my ($row_href) = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        my $qid = $ROW{'att_qid'};
        my $qst_row_href = select_question($dbh, $qid);
        my %QROW = %{$qst_row_href};
        my $qtype = $QROW{'qtype'};

        if ($qtype == 0) {
            my $C = validate_answer_1($dbh, $qid, $ROW{'att_given'});
            $upd_stmt->execute($C, $userid, $tst_id) or die $dbh->errstr();

        } elsif ($qtype == 1) {
            my $C = validate_answer_2($dbh, $qid, $ROW{'att_given'});
            $upd_stmt->execute($C, $userid, $tst_id) or die $dbh->errstr();

        } else {
            die "Unknown Question Type";
        }
    }

    $upd_stmt->finish();
    $stmt->finish();

    $dbh->commit();
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
    my $tst_id = $SESSION{'tst_id'};
    my $taker = $SESSION{'taker'};

    print qq{
    <ul id="menu">
	<li> [Test ID: $tst_id] </li>
	<li> Test Title: $SESSION{'tst_title'} </li>
	<li> Total Questions: $SESSION{'tst_qst_count'} </li>
	<li> Current Question: $FORM{'cur_seq'} </li>
    </ul>
};

    my $val;
    my $report_exists = check_for_report($DBH, $taker, $tst_id);

    if ($report_exists == 0) {
        $val = "Prepare Report";
    } else {
        $val = "Update Report";
    }

	print qq{
	<div>
	    <form action="ticktest.pl?sid=$SESSION{'sid'}" " method="post">
	    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
	    <input type="hidden" name="tst_id" value="$tst_id" />
	    <input type="hidden" name="taker" value="$FORM{'taker'}" />
	    <input type="submit" name="prepare_report" value="$val" />
	    </form>
	    </div>
	};
}

sub show_numberbox_for_answer {
    my $sid = $SESSION{'sid'};
    my $taker = $SESSION{'taker'};
    my $tst_id = $SESSION{'tst_id'};
    my $qid = $SESSION{'qid'};
    my $readonly = "";

    my $given = fetch_user_given_answer($DBH, $taker, $tst_id, $qid);
    my $correct = obtain_answer_1($DBH, $qid);

    if (! defined $given) {
        $given = "";
    }

    print qq{
    <input type="number" size="80" name="give_answer_number" value="$given" readonly/>

    <h2> Correct Answer </h2>

    <textarea rows="5" cols=80" readonly>$correct</textarea>
};
}

sub show_textbox_for_answer()
{
    my $sid = $SESSION{'sid'};
    my $taker = $SESSION{'taker'};
    my $tst_id = $SESSION{'tst_id'};
    my $qid = $SESSION{'qid'};
    my $readonly = "";

    my $given = select_user_given_string($DBH, $taker, $tst_id, $qid);
    my $correct = select_answer_string($DBH, $qid);

    if (! defined $given) {
        $given = "";
    }

    print qq{
    <input type="text" size="80" name="give_answer_string" value="$given" readonly/>

    <h3> Correct Answer </h3>

    <textarea rows="5" cols="80" readonly>$correct</textarea>
};
}

sub show_choices_mcq_unique {
    my $qid = $SESSION{'qid'};
    my $userid = $SESSION{'userid'};
    my $taker = $SESSION{'taker'};
    my $tst_id = $SESSION{'tst_id'};

    my $correct = get_correct_answer_2($DBH, $qid);
    my $given = fetch_user_given_answer($DBH, $taker, $tst_id, $qid);

    my $query = "SELECT chid, choice_html, correct FROM answer_2 WHERE qid = ? ORDER BY chid";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($qid) or die $DBH->errstr();

    print qq{<table>};
    while (my ($chid, $choice_html, $correct) = $stmt->fetchrow())
    {
        my $cell_val;
        my $color = "";
        my $border;

        if ($chid == $given) {
            $color = "yellow";
        }

        if ($correct == 1) {
            $border = "1px solid";
        } else {
            $border = "none";
        }

        $cell_val = qq{<p style="background-color: $color;">$chid</p>};

        print qq{
            <tr> 
                <td style="border: $border;">  $cell_val </td>
                <td> $choice_html </td>
                </tr> };
    }
    print qq{</table>};

    print qq{
<p> Note: User given answer has yellow background </p>
};

    $stmt->finish();
}

sub show_choices {
    my $qtype = shift;
    my $sid = $SESSION{'sid'};

    my $locked = $SESSION{'test_submitted'};
    my $qid = $SESSION{'qid'};
    if ($qtype == 1) {
        # The answer is to be given as a single integer
        show_numberbox_for_answer();
    } elsif ($qtype == 4) {
        # The answer is to be given as a string.
        show_textbox_for_answer();
    } elsif ($qtype == 2) {
        show_choices_mcq_unique();
    } else {
        die "Unknown question type";
    }
}

sub show_mcq {
    my $qid_seq = $FORM{'cur_seq'};
    my $tst_id = $SESSION{'tst_id'};
    my $qid = $SESSION{'qid'};
    my $row_href = select_question($DBH, $qid);
    my %row = %{$row_href};
    
    print qq{<h3> Question (QID: $qid) </h3>
		 <p> $row{'qhtml'} </p>};

    show_choices($row{'qtype'});
}

sub local_css {
    print qq{
<style>

.tick-container {
    border: 1px solid tan;
    background-color: wheat;
    display: grid;
    grid-template-columns: auto auto auto auto auto;
    position: fixed;
    bottom: 5%;
    width: 90%;
    align: center;
    margin-left: 5%;
    margin-right: 5%;
    text-align: center;
    padding-top: 10px;
    padding-bottom: 10px;
}

#next-q div {
    background-color: red;
}
</style>
};

}

sub doc_begin {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Validate Test Answers </title>";
    link_css();
    local_css();
    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});
}

sub doc_end {
    print q{</body></html>};
}

sub report_validation_status {
    my $validated = is_answer_validated($DBH, $SESSION{'taker'}, $SESSION{'tst_id'}, $SESSION{'qid'});

    if (! defined $validated) {
        print qq{<p> This question is NOT yet validated or SKIPPED. </p>};
    } elsif ($validated == 1) {
        print qq{<p> This question has been validated as CORRECT. </p>};
    } elsif ($validated == 0) {
        print qq{<p> This question has been validated as WRONG. </p>};
    }
}

sub DISPLAY {
    doc_begin();
    show_test_details();

    print qq{
        <form action="ticktest.pl?sid=$SESSION{'sid'}" method="POST">
    };

    show_mcq();

    report_validation_status();

    print qq{
        <input type="hidden" name="sid" value="$SESSION{'sid'}" />
        <input type="hidden" name="taker" value="$FORM{'taker'}" />
            <input type="hidden" name="cur_seq" value="$FORM{'cur_seq'}" />
            <input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />
    };

    my $next_disable = "";

    if ($FORM{'cur_seq'} >= $SESSION{'tst_qst_count'}) {
        $next_disable = "disabled";
    }

    my $prev_disable = "";

    if ($FORM{'cur_seq'} <= 1) {
        $prev_disable = "disabled";
    }

    print qq{
<div class="tick-container">
    <div>
        <input type="submit" name="prev" value="Previous Question" $prev_disable />
    </div>
    <div>
        <input type="submit" name="correct" value="Correct" />
    </div>
    <div>
        <input type="submit" name="wrong" value="Wrong" />
    </div>
    <div>
        <input type="submit" name="skipped" value="Skipped" />
    </div>
    <div id="next-q">
        <input type="submit" name="next" value="Next Question" $next_disable />
    </div>
</div>
};

    print q{
        </form>};

# print_hash(\%SESSION);
# print_hash(\%FORM);
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
