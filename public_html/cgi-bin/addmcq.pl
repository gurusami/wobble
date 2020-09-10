#!/usr/bin/perl
# Time-stamp: <2020-09-10 06:30:38 annamalai>
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
use DBI;
use URI::Encode qw(uri_encode uri_decode);

require "./profile.pl";
require "./utility.pl";
require "./model.pl";

our $dsn;
my %FORM;
my $DBH;
my %SESSION;

sub print_checkbox {
    my ($name, $value, $checked) = @_;

    print "<input type=\"checkbox\" name=\"$name\" value=\"$value\"";

    if ($checked) {
	if ($checked eq "true") {
	    print "checked";
	}
    }
    print "/>";
}

sub get_answers {
    my @answer;

    for (my $i = 1; $i <= $FORM{'n_choices'}; $i++) {
	my $name = "check_choice" . $i;

	if ($FORM{$name}) {
	    if ($FORM{$name} eq "true") {
		push @answer, 1;
	    } else {
		push @answer, 0;
	    }
	} else {
	    push @answer, 0;
	}
    }

    return @answer;
};

sub PROCESS {
    $SESSION{'ref_id'} = "";
    
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
	if (defined $FORM{'add_mcq'}) {
	    my $buffer;
	    my @pairs;

	    my $quest = $FORM{'question'};
	    my $qst_html = $FORM{'qst_html'};

	    my @choices;

	    for (my $i = 1; $i <= $FORM{'n_choices'}; $i++) {
		my $choice_name = "choice" . $i;
		push @choices, trim($FORM{$choice_name});
	    }
	    my @answers = get_answers();

	    # foreach my $ans (@answers) {
	    #  print "<p> ans: $ans </p>";
	    # }
	    # All data has been collected. Now save it in database.

	    $DBH->begin_work() or die $DBH->errstr;
	    $SESSION{'qid'} = insert_question_type1($DBH, $SESSION{'userid'}, $quest, $qst_html);
	    insert_choices($DBH, $SESSION{'qid'}, \@choices, \@answers);
	    $SESSION{'ref_id'} = insert_qid_ref_2($DBH, $SESSION{'qid'}, $FORM{'ref_id'});
	    $DBH->commit() or die $DBH->errstr();
	}

	if  (defined $FORM{'add_choice'}) {
	    $FORM{'n_choices'}++;
	}
    }
}

sub CTOR {
    $DBH = db_connect();
}

sub DTOR {
    $DBH->disconnect();
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};

    if (! defined $FORM{'n_choices'}) {
	$FORM{'n_choices'} = 4;
    }
}

sub display_choice {
    my $choice_id = shift;
    my $choice_name = "choice" . $choice_id;
    my $choice_check = "check_choice" . $choice_id;
    
    # ROW
    print q{<tr>};
    print qq{<td> <p> Choice: $choice_id </p> </td>};
    print qq{<td> <textarea name="$choice_name" cols="80" rows="5" />};

    if ($FORM{$choice_name}) {
	print "$FORM{$choice_name}";
    }

    print q{</textarea> </td>} . "\n";

    print qq{<td> <input type="checkbox" name="$choice_check" value="true" };

    if ($FORM{$choice_check}) {
	if ($FORM{$choice_check} eq "true") {
	    print "checked";
	}
    }

    print "/> </td> </tr> \n";

}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title>Add Multiple Choice Question</title>";
    link_css();
    print "</head>";
    print "<body>";

    top_menu($SESSION{'sid'});

    print "<h1>Add an MCQ (Question of Type 1)</h1>";
    
    print "<form action=\"addmcq.pl\" method=\"POST\">\n";

    print q{<table>};

    # ROW
    if (defined $SESSION{'qid'}) {
	print q{<tr>};
	print q{<td>Question ID</td>};
	print q{<td>} . $SESSION{'qid'} . q{</td>};
	print q{<td></td>};
	print q{</tr>};
    }

    # ROW
    print q{<tr>};
    print q{<td> <p> Question (LaTeX) </p> </td>};
    print q{<td> <textarea name="question" cols="80" rows="10">};

    if ($FORM{question}) {
	print "$FORM{question}";
    }

    print q{</textarea> </td>} . "\n";
    print q{<td></td>};
    print q{</tr>};

    # ROW (HTML Question)
    print q{<tr>};
    print q{<td> <p> Question (HTML) </p> </td>};
    print q{<td> <textarea name="qst_html" cols="80" rows="10">};

    if ($FORM{question}) {
	print "$FORM{qst_html}";
    }

    print q{</textarea> </td>} . "\n";
    print q{<td></td>};
    print q{</tr>};

    
    # CHOICE ROW
    for (my $choice_id = 1; $choice_id <= $FORM{'n_choices'}; $choice_id++) {
	display_choice($choice_id);
    }

    # ROW
    if (! defined $FORM{'ref_id'}) {
	$FORM{'ref_id'} = "";
    }
    
    print q{<tr>};
    print q{<td> Reference </td>};
    print qq{<td> <input type="number" name="ref_id" value="$SESSION{'ref_id'}" /> </td>};
    print q{</tr>};
    print q{</table>};

    print qq[<input type="hidden" name="n_choices" value="$FORM{'n_choices'}" />];
    print qq[<input type="hidden" name="userid" value="$SESSION{'userid'}" />];
    print qq[<input type="hidden" name="sid" value="$SESSION{'sid'}" />];
    print q[<input type="submit" name="add_mcq" value="Add Question" />] . "\n";
    print q[<input type="submit" name="add_choice" value="Add Choice" />] . "\n";
    print "</form>\n";

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
