#!/usr/bin/perl
#
# Time-stamp: <2020-09-11 10:08:02 annamalai>
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
use File::Basename;

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
    if (defined $FORM{'confirm'}) {
        my $userid = $FORM{'selected_username'};
        my $tst_id = $FORM{'selected_tst_id'};
        my $tst_giver = $SESSION{'userid'};

        $DBH->begin_work();
        insert_test_schedule($DBH, $userid, $tst_id,
                $FORM{'from_date'}, $FORM{'to_date'}, $tst_giver);
        prepare_test_attempt($DBH, $userid, $tst_id);
        $DBH->commit();
    }
}

sub show_existing_tests {
    my $query = "SELECT tst_id, tst_type, tst_owner, tst_created_on, tst_qst_count, tst_title FROM ry_tests ORDER BY tst_id DESC";

    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    print q{<table>};
    print q{<tr> <th> Select </th> <th> Test ID </th> <th> Test Type </th>} .
	q{<th> Title </th> <th> Question Count </th> <th> Owner </th>} .
	q{<th> Created On </th> </tr>};
    
    while (my ($tst_id, $tst_type, $tst_owner, $tst_created_on, $tst_qst_count,
	       $tst_title) = $stmt->fetchrow()) {
	print qq{<tr>} . "\n";
	print qq{<td> <input type="radio" name="selected_tst_id" value="$tst_id" /> </td>} . "\n";
	print qq{<td> $tst_id </td>} . "\n";
	print qq{<td> $tst_type </td> <td> $tst_title </td> <td> $tst_qst_count </td> <td> $tst_owner </td> <td> $tst_created_on </td> </tr>};
    }
    print q{</table>};

    print q{<input type="submit" name="sel_tst" value="Select Test" />};
    $stmt->finish();

}

sub show_users {
    my $query = "SELECT userid, username FROM ry_users ORDER BY username";

    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    print q{<table>};
    print q{<tr> <th> Select </th> <th> User Name </th> </tr>};
    
    while (my ($userid, $uname) = $stmt->fetchrow()) {
	print qq{<tr>} . "\n";
	print qq{<td> <input type="radio" name="selected_username" value="$userid" /> </td>} . "\n";
	print qq{<td> $uname </td>} . "\n";
    }
    print q{</table>};

    print q{<input type="submit" name="sel_user" value="Select User" />};
    $stmt->finish();

}

sub show_dates {
    print q{<table>};
    print q{<tr> <th> From Date </th> <th> To Date </th> </tr>};
    print q{<tr>} . 
	qq{<td> <input type="date" name="from_date" value="$FORM{'from_date'}" /> </td>} .
	qq{<td> <input type="date" name="to_date" value="$FORM{'to_date'}" /> </td>} .
	q{</tr>} . "\n"
	. q{</table>} . "\n"
	. q{<input type="submit" name="sel_dates" value="Select Dates" />};
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    link_css();
    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});

    print qq{<form action="test-schedule.pl?sid=$SESSION{'sid'}" method="post">};
    print qq{<input type="hidden" name="sid" value="$SESSION{'sid'}" />};

    if (! defined $FORM{'selected_tst_id'} ) {
        show_existing_tests();
    } elsif (! defined $FORM{'selected_username'} ) {
# Test ID has been selected already.  Now select user. 
        print qq{<input type="hidden" name="selected_tst_id" value="$FORM{'selected_tst_id'}" />};
        show_users();
    } elsif (! (defined $FORM{'from_date'} && defined $FORM{'to_date'}) ) {
        print qq{<input type="hidden" name="selected_tst_id" value="$FORM{'selected_tst_id'}" />};
        print qq{<input type="hidden" name="selected_username" value="$FORM{'selected_username'}" />};

        show_dates();
    } elsif (! defined $FORM{'confirm'}) {
        print qq{<input type="hidden" name="selected_tst_id" value="$FORM{'selected_tst_id'}" />};
        print qq{<input type="hidden" name="selected_username" value="$FORM{'selected_username'}" />};
        print qq{<input type="hidden" name="userid" value="$SESSION{'userid'}" />};
        print qq{<input type="hidden" name="from_date" value="$FORM{'from_date'}" />};
        print qq{<input type="hidden" name="to_date" value="$FORM{'to_date'}" />} .
            q{<input type="submit" name="confirm" value="Confirm" />};
    } else {
        print q{<h2> Test Schedule Completed </h2>} . "\n"
            . q{<table>} . "\n"
            . q{<tr> <th> Test Property </th> <th> Value </th> </tr>} . "\n"
            . qq{<tr> <td> Test ID </td> <td> $FORM{'selected_tst_id'} </td> </tr>} . "\n"
            . qq{<tr> <td> User </td> <td> $FORM{'selected_username'} </td> </tr> } . "\n"
            . qq{<tr> <td> From Date </td> <td> $FORM{'from_date'} </td> </tr> } . "\n"
            . qq{<tr> <td> To Date </td> <td> $FORM{'to_date'} </td> </tr> } . "\n"
            . q{</table>};
    }
    print q{</form>};
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
