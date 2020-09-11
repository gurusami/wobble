#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 14:36:57 annamalai>
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
#
# To edit/modify one question.
#
use strict;
use warnings;
use DBI;
use URI::Encode qw(uri_encode uri_decode);

require "./profile.pl";
require "./display.pl";
require "./model.pl";
require "./utility.pl";

our $dsn;
our $log;
my %FORM;
my %SESSION;
my $DBH;

# The question identifier (qid).
my $qid = 0;

sub display_tinker_form {
    print qq{
    <div style="text-width: 50%">
    <form action="tinker.pl" method="POST">
	<input type="number" name="qid" />
	<input type="hidden" name="sid" value="$SESSION{'sid'}" />
	<input type="submit" name="form_tinker" value=\"Tinker\" />
	</form>
	</div>
    };
}

sub display_add_reference {
    print qq[
    <form action="tinker.pl" method="post">
    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
    <input type="hidden" name="qid" value="$qid" />
    <input type="number" name="ref_id" />
    <input type="submit" name="add_ref" value="Add Reference"/>
    </form>
	];
};

sub display_references {
    my $dbh = shift;

    my $query = "SELECT bib.ref_id, bib.ref_author, bib.ref_title FROM ry_biblio bib, ry_qid_ref ref WHERE ref.qid = ? AND ref.ref_id = bib.ref_id ORDER BY bib.ref_id";

    my $stmt = $dbh->prepare($query);
    $stmt->execute($qid);

    print q[<h2> References </h2>];
    print q[<ul>];
    while (my $row_href = $stmt->fetchrow_hashref()) {
	# print_hash($row_href);
	my %ROW = %{$row_href};
	print qq{<li> $ROW{'ref_author'} <cite> $ROW{'ref_title'} </cite> </li> };
    }
    print q[</ul>];
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};
    $qid = $FORM{'qid'};
}

# sub get_answers {
#     my @answer;

#     for (my $i = 1; $i < 5; $i++) {
# 	my $name = "check_choice" . $i;

# 	if ($FORM{$name}) {
# 	    if ($FORM{$name} eq "true") {
# 		push @answer, 1;
# 	    } else {
# 		push @answer, 0;
# 	    }
# 	} else {
# 	    push @answer, 0;
# 	}
#     }

#     return @answer;
# };

sub CTOR {
    $DBH = db_connect();
}

sub DTOR {
    $DBH->disconnect();
}


sub handle_all_forms {
    my $dbh = shift;
    my $form_href = shift;

    my %FORM = %{$form_href};

    if ($FORM{'UpdateAnswer0'} && ($FORM{'UpdateAnswer0'} eq "Update")) {
	update_answer_0($dbh, $FORM{qid}, $FORM{qans});
    } elsif ($FORM{'UpdateQuestion'} && ($FORM{'UpdateQuestion'} eq "Update")) {
	update_question($dbh, $form_href);
    } elsif ($FORM{'UpdateAnswer1'} && ($FORM{'UpdateAnswer1'} eq "Update")) {
	update_answer_1($dbh, $form_href);
    } elsif ($FORM{'add_new_question'} && ($FORM{'add_new_question'} eq "Add New Question")) {
	my $qid = insert_question($dbh);
	$FORM{'qid'} = $qid;
    } elsif ($FORM{'add_choice'} && ($FORM{'add_choice'} eq "Add Choice")) {
	insert_answer_1($dbh, $form_href);
    } elsif ($FORM{'add_child_question'} && ($FORM{'add_child_question'} eq "Add Child Question")) {
	insert_child_question($dbh, $FORM{'parent_qid'});
    } elsif ($FORM{'visit_parent'} && ($FORM{'visit_parent'} eq "Visit Parent")) {
	# The qid has been updated.  Nothing else to do.
    } elsif ($FORM{'add_ref'} && ($FORM{'add_ref'} eq "Add Reference")) {
	insert_qid_ref($dbh, $form_href);
    }

    return \%FORM;
};

sub PROCESS {
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
	# Process the submitted data.
	my $form_href = handle_all_forms($DBH, \%FORM);
	%FORM = %{$form_href};
    }
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Tinker A Question </title>";
    link_css();
    print "</head>";

    print "<body>";

    top_menu($SESSION{'sid'});

    # At this point we have a valid qid, either old or new.  Lets tinker it!

    # Represents one row in the table answer_0.
    my $answer0_row_href;
    my $qrow_href;
    my %QROW;

    $qid = $FORM{'qid'};

    # Collect Data that is to be used for display.
    # TODO: Data is to be collected based on what is to be displayed.
    # I think it is better if each data is collected by its display unit.

    if (defined $qid && $qid > 0) {
	$qrow_href = select_question($DBH, $qid);

	if (defined $qrow_href) {
	    %QROW = %{$qrow_href};
	    if (defined $QROW{qtype} && $QROW{qtype} == 0) {
		$answer0_row_href = select_answer_0($DBH, $qid);
		if (! defined $answer0_row_href) {
		    insert_answer_0($DBH, $qid);
		    $answer0_row_href = select_answer_0($DBH, $qid);
		}
	    }
	} 
    }

    display_top();

    print "<hr>";

    display_log();

    if (defined $qid && $qid > 0) {
	display_question($qrow_href, $SESSION{'sid'});

	if (defined $qrow_href) {
	    if (defined $QROW{'qtype'} && $QROW{'qtype'} == 0) {
		display_answer_0($answer0_row_href);
	    } else {
		display_answer($DBH, $SESSION{'sid'}, $qrow_href);
	    }
	}

	display_parent($DBH, $qrow_href);
	display_references($DBH);
	display_add_reference();
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

    PROCESS();
    DISPLAY();
    DTOR();
    exit(0);
}

MAIN();
