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
    my $tst_id = $SESSION{'tst_id'};

    my $correct = get_correct_answer_2($DBH, $qid);
    my $given = fetch_user_given_answer($DBH, $userid, $tst_id, $qid);

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

#next-q div {
    background-color: red;
}
</style>
};

}

sub doc_begin {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Test Review </title>";
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

    my $not_validated =  qq{<p> This question is NOT YET VALIDATED. </p>};

    if (! defined $validated) {
        print $not_validated;
    } elsif ($validated == 3) {
        print qq{<p> This question has been validated as SKIPPED. </p>};
    } elsif ($validated == 2) {
        print qq{<p> This question has been validated as WRONG. </p>};
    } elsif ($validated == 1) {
        print qq{<p> This question has been validated as CORRECT. </p>};
    } elsif ($validated == 0) {
        print $not_validated;
    }
}

sub DISPLAY {
    doc_begin();
    show_test_details();

    print qq{
        <form action="test-review.pl?sid=$SESSION{'sid'}" method="POST">
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
      <div style="display: grid; grid-template-columns: auto auto; text-align: center;">
       <div>
        <input type="submit" name="prev" value="Previous Question" $prev_disable />
       </div>
       <div>
        <input type="submit" name="next" value="Next Question" $next_disable />
       </div>
      </div>
     </form>
    };
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
