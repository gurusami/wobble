#!/usr/bin/perl
#
# Time-stamp: <2020-09-06 16:07:35 annamalai>
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
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
require "./control.pl";
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
