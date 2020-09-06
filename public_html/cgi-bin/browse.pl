#!/usr/bin/perl

use strict;
use warnings;

require './profile.pl';
require './utility.pl';
require './model.pl';

my $DBH;
my $qid_from = 1;
my $qid_count = 10;
my %FORM;
my $qid_previous;
my $qid_next;
my %SESSION;

sub DISPLAY {
    if (defined $FORM{'qid'}) {
	$qid_from = $FORM{'qid'};
    }

    print "<!doctype html>";
    print "<html>";
    print "<head>";
    print "<title> Browse Questions </title>";
    print "</head>";

    print "<body>";

    top_menu($SESSION{'sid'});

    print q[<table>];
    print q[<tr> <th> Qid </th> <th> Parent </th> <th> Q-Type </th> <th> Question </th> </tr>];

    my $query = "SELECT qid, qparent, qtype, qlatex FROM question WHERE qid >= ? ORDER BY qid LIMIT ?";
    my $stmt = $DBH->prepare($query);
    $stmt->execute($qid_from, $qid_count);

    while (my ($qid, $qparent, $qtype, $qlatex) = $stmt->fetchrow()) {
	if (! defined $qparent) { $qparent = ""; }
	if (! defined $qtype)   { $qtype = ""; }
	if (! defined $qlatex)  { $qlatex = ""; }
	
	print qq[<tr> <td> <a href="tinker.pl?sid=$SESSION{'sid'}&qid=$qid"> $qid </a> </td> <td> $qparent </td> <td> $qtype </td> <td> $qlatex </td> </tr>];
    }

    if ($qid_from > $qid_count) {
	$qid_previous = $qid_from - $qid_count;
    } else {
	$qid_previous = $qid_from;
    }

    my $max_qid = select_max_qid($DBH);

    if ($qid_from + $qid_count > $max_qid) {
	$qid_next = $qid_from;
    } else {
	$qid_next = $qid_from + $qid_count;
    }

    print qq[<tr> <td> <a href="browse.pl?sid=$SESSION{'sid'}&qid=$qid_previous">Previous</a> </td>];
    print qq[<td> </td> <td> </td> <td> <a href="browse.pl?sid=$SESSION{'sid'}&qid=$qid_next">Next</a> </td> </tr>];
    print q[</table>];

    $stmt->finish();
    print "</body>";

}

sub DTOR {
    $DBH->disconnect();
}

sub CTOR {
    $DBH = db_connect();
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};
    DISPLAY();
    DTOR();
    exit(0);
}

MAIN();
