#!/usr/bin/perl

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

sub menu {
    my $sid = shift;
    print qq[<a href="menu.pl?sid=$sid">Main Menu</a>];
    print qq[<a href="addmcq.pl?sid=$sid">Add Another Question</a>];
    print q[<hr>];
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title>Add Multiple Choice Question</title>";
    print "</head>";
    print "<body>";

    menu($SESSION{'sid'});

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
    print "<input type=\"submit\" value=\"Add Question\" />\n";
    print "</form>\n";

    my $nc = $FORM{'n_choices'} + 1;
    my $qs = qq@sid=$SESSION{'sid'}&n_choices=$nc@;
    print qq{<a href="addmcq.pl?$qs">One more choice</a>};
    
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
