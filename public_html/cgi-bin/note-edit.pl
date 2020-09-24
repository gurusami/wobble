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
       if (defined $FORM{'fetch_note_id'}) {
            $FORM{'note'} = select_note($DBH, $FORM{'note_id'});
       }
       if (defined $FORM{'update_note_id'}) {
            update_note($DBH, $FORM{'note_id'}, $FORM{'note'});
       }
    }
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    if (! defined $FORM{'note_id'}) {
    print qq{
<form action="note-edit.pl" method="post">
  <input type="hidden" name="sid" value="$SESSION{'sid'}" />
  <input type="number" name="note_id" />
  <input type="submit" name="fetch_note_id" value="Fetch Note"/>
</form>
};
    } else {
    print qq{
<form action="note-edit.pl" method="post">
  <input type="hidden" name="sid" value="$SESSION{'sid'}" />
  <input type="hidden" name="note_id" value="$FORM{'note_id'}"/>
  <textarea rows="20" cols="80" name="note">$FORM{'note'}</textarea>
  <input type="submit" name="update_note_id" value="Update Note"/>
</form>
};
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

    CHECK_AUTH($DBH, $SESSION{'sid'}, $ENV{'SCRIPT_NAME'}, $SESSION{'userid'});
    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
