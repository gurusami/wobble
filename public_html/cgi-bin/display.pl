#!/usr/bin/perl

use strict;
use warnings;

require './model.pl';

our $log;

sub log_append {
    my $mesg = shift;
    
    if (defined $log) {
	$log = $log . $mesg;
    } else {
	$log = $mesg;
    }
};

sub display_log {

    if (defined $log) {
	print qq{
	<div>
	    <p> $log </p>
	    </div>
	};
    }
}

sub display_question {
    my $row_href = shift;
    my $sid = shift;
    
    if (! defined $row_href) {
	return "false";
    }
    
    my %ROW = %{$row_href};

    my $checked = "";
    my $qtype;

    if (defined $ROW{'qtype'}) {
	$qtype = $ROW{'qtype'};
    } else {
	$qtype = "";
    }

    if (! defined $ROW{'qparent'}) {
	$ROW{'qparent'} = "";
    }

    print qq{
    <div>
	<h2> Question Details </h2>
	<form action="tinker.pl" method="post">
	<table>

	<tr>
	<td> Question Identifier </td>
	<td> <input type="number" name="qid" value="$ROW{qid}" readonly/> </td>
	</tr>

	<tr>
	<td> Parent Question Identifier </td>
	<td> <input type="number" name="qparent" value="$ROW{qparent}" readonly/> </td>
	</tr>

	<tr>
	<td> <p> Question (in LaTeX format) </p> </td>
	<td> <textarea name="question" cols="80" rows="10">$ROW{'qlatex'}</textarea> </td>
	</tr>
	
	<tr>
	<td> Question Type </td>
	<td> <input type="number" name="qtype" value="$qtype" /> </td>
	</tr>

	</table>
	<input type="hidden" name="sid" value="$sid" />
	<input type="submit" name="UpdateQuestion" value="Update" />
	</form>
	</div>
    };
}

sub display_answer_0 {
    my $row_href = shift;
    my %ROW = %{$row_href};
    my $answer;
    
    if (! defined $ROW{qans}) {
	$answer = "";
    } else {
	$answer = $ROW{qans};
    }

    print qq{
    <div>
	<h2> Answer Details </h2>
	<form action="tinker.pl" method="post">
	<input type="hidden" name="qid" value="$ROW{qid}" />
	<input type="number" name="qans" value="$answer" />
	<input type="submit" name="UpdateAnswer0" value="Update" />
	</form>
	</div>
    };
}

sub display_answer {
    my $dbh = shift;
    my $sid = shift;
    my $qrow_href = shift;
    my %row = %{$qrow_href};
    my $qid = $row{'qid'};
    my $qtype = $row{'qtype'};

    print qq{
    <div>
	<h2> Answer Details </h2>
    };

    if (defined $qtype) {
	if ($qtype == 1) {
	    display_answer_1($dbh, $sid, $qid);
	} elsif ($qtype == 2) {
	    display_child_questions($dbh, $qid);
	}
    }
    
    print qq{
    </div>
    };
};

# Sub-routine to display answer for question of type 1.
sub display_answer_1 {
    my $dbh = shift;
    my $sid = shift;
    my $qid = shift;

    my $rows_aref = select_answer_1($dbh, $qid);

    my @rows = @{$rows_aref};

    print qq{
	<form action="tinker.pl" method="post">
	<table>
    };

    my $iter = 1;
    foreach my $row_href (@rows) {
	my %row = %{$row_href};

	my $choice_name = "choice_" . $iter;
	my $choice_id = $row{'chid'};
	my $correct = $row{'correct'};
	my $checked;

	if ($correct) {
	    $checked = "checked=true";
	} else {
	    $checked = "";
	}
	
	print qq{
	<tr>
	    <td> <input type="radio" name="choice_radio" value="$choice_id" $checked/> </td>
	    <td> <input type="text" name="$choice_name" value="$row{'choice_latex'}" /> </td>
	    </tr>
	};

	$iter++;
    }
    
    print qq{
    </table>
	<input type="hidden" name="sid" value="$sid" />
	<input type="hidden" name="qid" value="$qid" />
	<input type="submit" name="UpdateAnswer1" value="Update" />
	</form>
    };

    # Add an option to add a choice.  New form!
    print qq{
    <form action="tinker.pl" method="post">
	<input type="hidden" name="qid" value="$qid" />
	<input type="hidden" name="chid" value="$iter" />
	<input type="text" name="the_choice" />
	<input type="submit" name="add_choice" value="Add Choice"/>
	</form>
    };
}

sub display_error {
    my $mesg = shift;
    print qq{$mesg};
}

sub display_top {
    print q[<div class="top"> ];
    display_tinker_form();
    display_add_question_form();
    print q[</div> <!-- class="top" -->];
};

sub display_add_question_form {
    print qq{
    <div>
    <form action="tinker.pl" method="POST">
	<input type="submit" name="add_new_question" value=\"Add New Question\" />
	</form>
	</div>
    };
}

sub display_child_questions {
    my $dbh = shift;
    my $parent_qid = shift;

    my $query = "SELECT qid, qparent, LEFT(qlatex, 80), qtype FROM question WHERE qparent = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($parent_qid);

    print qq{
    <h2> Child Questions </h2>
    <table>
	<th>
	<td> Visit </td>
	<td> Question ID </td>
        <td> Parent Question </td>
	<td> Question </td>
	<td> Question Type </td>
	</th>
    };
    
    while (my ($qid, $qparent, $qlatex, $qtype) = $stmt->fetchrow()) {
	print qq{
	<tr>
	    <td>
	    <form action="tinker.pl" method="post">
	    <input type="hidden" name="qid" value="$qid" />
	    <input type="submit" name="visit_child" value=\"Visit\" />
	    </form>
	    </td>
	    <td> $qid </td>
	    <td> $qparent </td>
	    <td> $qlatex </td>
	    <td> $qtype </td>
	    </tr>
	};
    }

    print qq{
    </table>
    };

    $stmt->finish();
    
    print qq{
    <form action="tinker.pl" method="POST">
	<input type="hidden" name="qid" value="$parent_qid" />
	<input type="hidden" name="parent_qid" value="$parent_qid" />
	<input type="submit" name="add_child_question" value=\"Add Child Question\" />
	</form>
    };
};

sub display_parent {
    my $dbh = shift;
    my $qrow_href = shift;
    my %QROW = %{$qrow_href};

    if (! defined $QROW{'qparent'}) {
	return undef;
    }
    
    my $pqid = $QROW{'qparent'};

    print qq{
        <div>
	<h2> Parent Details </h2>
	<form action="tinker.pl" method="post">
	<input type="hidden" name="qid" value="$pqid" />
	<input type="submit" name="visit_parent" value="Visit Parent" />
	</form>
	</div>
    };

};

1;
