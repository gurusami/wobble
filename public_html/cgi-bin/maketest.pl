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
    my $query = q{SELECT tst_id, tst_qst_count, tst_type, tst_title, tst_owner, tst_created_on FROM ry_tests WHERE tst_id = ?};
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($FORM{'tst_id'}) or die $DBH->errstr();
    my ($tst_id, $tst_qst_count, $tst_type, $tst_title, $tst_owner, $tst_created_on) = $stmt->fetchrow();

    print q{<h2> Test Information </h2>};
    print q{<table>} . "\n";
    print q{<tr> <th> Test ID </th> <th> Question Count </th> <th> Type </th> <th> Title </th> <th> Owner </th> <th> Created On </th> </tr>} . "\n";
    print q{<tr>};
    print qq{<td> $tst_id </td> <td> $tst_qst_count </td> <td> $tst_type </td>}
    . qq{<td> $tst_title </td> <td> $tst_owner </td> <td> $tst_created_on </td>} . "\n";
    print q{</tr>};
    print q{</table>} . "\n";
}

sub show_questions_in_test {
    my $qlist_aref = get_qid_in_tst($DBH, $FORM{'tst_id'});
    my @qlist = @{$qlist_aref};

    my $N = 1 + $#qlist;
    print qq{<h2> Questions in Test (Total: $N) </h2>};
    
    if (@qlist > 0) {
	my $query = "SELECT qid, qtype, LEFT(qlatex, 64) FROM question WHERE qid IN (" . join(',', @qlist) . ")";
	my $stmt = $DBH->prepare($query);
	$stmt->execute();

	print q{<form action="maketest.pl" method="post">};
	print q{<table>};
	print qq{<tr> <th> Select </th> <th> QID </th> <th> Question Type </th> <th> Question </th> </tr>};

	while (my ($qid, $qtype, $qlatex) = $stmt->fetchrow()) {
	    	print q{<tr>} . "\n";
		print qq{<td> <input type="radio" name="qid" value="$qid" /> </td> };
		print qq{<td> $qid </td> <td> $qtype </td> <td> $qlatex </td> </tr>};
	}
	print q{</table>};
	print q{<input type="submit" name="remove_from_test" value="Remove Question from Test" />};
	print qq{<input type="hidden" name="sid" value="$SESSION{'sid'}" />};
	print qq{<input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />} . "\n";
	print q{</form>};
    }
}

sub show_questions {

    
    my $query = "SELECT qid, qtype, LEFT(qlatex, 64) FROM question WHERE qid > ? ORDER BY qid LIMIT ?";
    my $stmt = $DBH->prepare($query);
    $stmt->execute($FORM{'qid_min'}, $FORM{'qid_count'});

    print q{<h2> Available Questions </h2>};
    print q{<form action="maketest.pl" method="post">};
    print q{<table>};
    print qq{<tr> <th> Select </th> <th> QID </th> <th> Question Type </th> <th> Question </th> </tr>};

    my $qid_to = $FORM{'qid_min'};
    while (my ($qid, $qtype, $qlatex) = $stmt->fetchrow()) {
	print q{<tr>} . "\n";
	print qq{<td> <input type="radio" name="qid" value="$qid" /> </td> };
	print qq{<td> $qid </td> <td> $qtype </td> <td> $qlatex </td> </tr>};
	$qid_to = $qid;
    }

    my $prev_qid = $FORM{'qid_min'};

    if ($FORM{'qid_min'} > $FORM{'qid_count'}) {
	$prev_qid = $FORM{'qid_min'} - $FORM{'qid_count'};
    } else {
	$prev_qid = 0;
    }

    my $max_qid = select_max_qid($DBH);
    my $last_qid = $max_qid - $FORM{'qid_count'};
    my $next_qs = qq@maketest.pl?sid=$SESSION{'sid'}&tst_id=$FORM{'tst_id'}&qid_min=$qid_to@;
    my $prev_qs = qq@maketest.pl?sid=$SESSION{'sid'}&tst_id=$FORM{'tst_id'}&qid_min=$prev_qid@;
    my $first_qs = qq@maketest.pl?sid=$SESSION{'sid'}&tst_id=$FORM{'tst_id'}&qid_min=0@;
    my $last_qs = qq@maketest.pl?sid=$SESSION{'sid'}&tst_id=$FORM{'tst_id'}&qid_min=$last_qid@;
    

    print qq{<td colspan="4"> <a href="$first_qs">First</a> <a href="$prev_qs"> Prev </a> <a href="$next_qs"> Next </a> <a href="$last_qs">Last</a></td> </tr>};
    print q{</table>};
    print q{<input type="submit" name="add_to_test" value="Add Question to Test" />};
    print qq{<input type="hidden" name="sid" value="$SESSION{'sid'}" />};
    print qq{<input type="hidden" name="tst_id" value="$FORM{'tst_id'}" />} . "\n";
    print q{</form>};

    $stmt->finish();
}

sub PROCESS {
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
	if (defined $FORM{'add_to_test'}) {
	    add_question_to_test($DBH, $FORM{'tst_id'}, $FORM{'qid'});
	} elsif (defined $FORM{'remove_from_test'}) {
	    remove_question_from_test($DBH, $FORM{'tst_id'}, $FORM{'qid'});
	}

    }
}

sub CHECK_TST_ID {
    if (! defined $FORM{'tst_id'}) {
	print q{<p> No Test Identifier Specified. </p>};
	exit(0);
    }
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Preparing Test With Test ID: $FORM{'tst_id'} </title>";
    link_css();
    print "</head>" . "\n";

    print "<body>";

    top_menu($SESSION{'sid'});

    CHECK_TST_ID();

    show_test_details();

    print q{<hr>};
    
    show_questions_in_test();

    print q{<hr>};
    
    show_questions();
    
    print "</body>";
    print "</html>";
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
