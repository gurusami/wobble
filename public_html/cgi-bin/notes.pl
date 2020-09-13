#!/usr/bin/perl
#
# Time-stamp: <2020-09-12 11:06:11 annamalai>
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
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
	if (defined $FORM{'add_note'}) {
	    my $note = $FORM{'add_note'};
	    insert_note($DBH, $SESSION{'userid'}, $FORM{'qid'}, $FORM{'note_html'});
	}
    }
}

sub add_note {
	print qq{
		<h2> Add a Note </h2>
			<form action="notes.pl" method="post">
			<textarea name="note_html" cols="80" rows="20"></textarea>
			<input type="hidden" name="sid" value="$SESSION{'sid'}" />
			<input type="hidden" name="qid" value="$FORM{'qid'}" />
			<input type="submit" name="add_note" value="Add Note" />
			</form>
	};
}

sub display_notes {
    my $query =  q{SELECT note_id, no_note
		       FROM ry_qst_notes WHERE no_qid = ? ORDER BY no_created DESC};

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($FORM{'qid'}) or die $DBH->errstr();

    print q{<h2> Available Notes </h2>};

    while (my ($note_id, $note) = $stmt->fetchrow()) {
        my $qs = qq[note-edit.pl?sid=$SESSION{'sid'}&note_id=$note_id];
	print qq{<div> $note (<a href="$qs">Edit</a>)</div>};
    }
}


sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Add Notes for a Question </title>";
    link_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});

    add_note();
    display_notes();
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
