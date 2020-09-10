#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 02:42:31 annamalai>
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

    my $tst_id = $FORM{'tst_id'};

    if (! defined $FORM{'cur_seq'}) {
	$FORM{'cur_seq'} = 1;
    }
    
    $SESSION{'qid'} = get_nth_qid_in_tst($DBH, $tst_id, $FORM{'cur_seq'});
    
    if (defined $FORM{'next'}) {
	$FORM{'cur_seq'}++;
	$SESSION{'qid'} = get_nth_qid_in_tst($DBH, $tst_id, $FORM{'cur_seq'});
	# $FORM{'choice'} = fetch_user_given_answer(
	#     $DBH, $SESSION{'userid'}, $tst_id, $FORM{'att_id'},
	#     $SESSION{'qid'});
    } elsif (defined $FORM{'prev'}) {
	$FORM{'cur_seq'}--;
	$SESSION{'qid'} = get_nth_qid_in_tst($DBH, $tst_id, $FORM{'cur_seq'});
	# $FORM{'choice'} = fetch_user_given_answer(
	#     $DBH, $SESSION{'userid'}, $tst_id, $FORM{'att_id'}, 
	#     $SESSION{'qid'});
    } elsif (defined $FORM{'answer'}) {
	if (defined $FORM{'choice'} && $FORM{'choice'} > 0) {
	    give_answer($DBH, $FORM{'choice'},
			$SESSION{'userid'}, $tst_id,
			$FORM{'att_id'}, $SESSION{'qid'});
	} else {
	    die "No choice defined";
	}
    } elsif (defined $FORM{'locktest'}) {
	# Mark the test as submitted.  No more changes are allowed.
	mark_test_submitted($DBH, $SESSION{'userid'}, $tst_id, $FORM{'att_id'});
    }

    $FORM{'choice'} = fetch_user_given_answer(
	$DBH, $SESSION{'userid'}, $tst_id, $FORM{'att_id'}, 
	$SESSION{'qid'});

    $SESSION{'test_submitted'} = is_test_submitted(
	$DBH, $SESSION{'userid'}, $tst_id, $FORM{'att_id'});
}

sub show_test_details {
    print qq{
    <ul id="menu">
	<li> [Test ID: $SESSION{'tst_id'}] </li>
	<li> Attempt Number: $FORM{'att_id'} </li>
	<li> Test Title: $SESSION{'tst_title'} </li>
	<li> Total Questions: $SESSION{'tst_qst_count'} </li>
	<li> Current Question: $FORM{'cur_seq'} </li>
    };

    if ($SESSION{'test_submitted'} == 0) {
	print qq{
	<li>
	    <form action="taketest.pl" method="post">
	    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
	    <input type="hidden" name="tst_id" value="$SESSION{'tst_id'}" />
	    <input type="hidden" name="att_id" value="$FORM{'att_id'}" />
	    <input type="submit" name="locktest" value="Submit Test" />
	    </form>
	    </li>
	};
    }

    print q{</ul>};
}

sub show_choices {
    my $locked = $SESSION{'test_submitted'};
    my $qid = $SESSION{'cur_qid'};
    my $query = "SELECT chid, choice_html FROM answer_1 WHERE qid = ? ORDER BY chid";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($qid) or die $DBH->errstr();
    print qq{<table>};
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
	    if (defined $FORM{'choice'} && $FORM{'choice'} == $chid) {
		$cell_val = qq{<p style="background-color: yellow;">$chid</p>};
	    } else {
		$cell_val = qq{$chid};
	    }

	}
	
	print qq{
	<tr> 
	    <td> $cell_val </td>
	    <td> $choice_html </td>
	    </tr> };
    }
    print qq{</table>};
    
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

    show_choices();
}

sub doc_begin {
    print "<html>";
    print "<head>";
    print "<title> Take a Test </title>";
    link_css();
    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});
}

sub doc_end {
    print q{</body></html>};
}

sub DISPLAY {
    doc_begin();
    show_test_details();

    print qq{
    <form action="taketest.pl?sid=$SESSION{'sid'}" method="POST">
    };
    
    show_mcq();
    
    print qq{
    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
	<input type="hidden" name="cur_seq" value="$FORM{'cur_seq'}" />
	<input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />
	<input type="hidden" name="att_id" value="$FORM{'att_id'}" />
    };

    if ($SESSION{'test_submitted'} == 0) {
	print qq{<input type="submit" name="answer" value="Submit Answer" />};
    }

    if ($FORM{'cur_seq'} < $SESSION{'tst_qst_count'}) {
	print qq{
	<input type="submit" name="next" value="Next Question" />
	};
    }

    if ($FORM{'cur_seq'} > 1) {
	print qq{
	<input type="submit" name="prev" value="Previous Question" />
	};
    }

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
