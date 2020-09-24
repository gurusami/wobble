#!/usr/bin/perl
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
require './model.pl';

my $DBH;
my $qid_from = 1;
my $qid_count = 10;
my %FORM;
my $qid_previous;
my $qid_next;
my %SESSION;

sub local_style {
  print q{
<style>
</style>
};
}

sub DISPLAY {
    if (defined $FORM{'qid'}) {
	$qid_from = $FORM{'qid'};
    }

    print "<!doctype html>";
    print "<html>";
    print "<head>";
    print "<title> Browse Questions </title>";
    link_css();
    print "</head>";

    print "<body>";

    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

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

    my $max_qid = $SESSION{'max_qid'};

    if ($qid_from + $qid_count > $max_qid) {
	$qid_next = $qid_from;
    } else {
	$qid_next = $qid_from + $qid_count;
    }

    print q[</table>];

    my $last_qid = $max_qid - $qid_count + 1;
    print qq{
<div>
  <ul id="menu">
    <li> [ <a href="browse.pl?sid=$SESSION{'sid'}&qid=$qid_previous">Previous</a> ] </li>
    <li> [ <a href="browse.pl?sid=$SESSION{'sid'}&qid=$qid_next">Next</a> ] </li>
    <li> [ <a href="browse.pl?sid=$SESSION{'sid'}&qid=$last_qid">Last</a> ] </li>
  <ul>
</div>
};

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

sub PROCESS {
    $SESSION{'max_qid'} = select_max_qid($DBH);
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
