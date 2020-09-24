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

sub display_question_images {
    my $dbh = shift;
    my $qid = shift;
    my $sid = shift;

    print qq{
<div class="question_images">
    <h2> Images in Question </h2>
    <form action="image-addq.pl?sid=$sid" method="post">
        <input type="hidden" name="sid" value="$sid" />
        <input type="hidden" name="qid" value="$qid" />
        <input type="submit" name="add_image_to_q" value="Add Images" />
    </form>
</div>
};

}

sub html_show_tags {
    my $dbh = shift;
    my $qid = shift;
    my $html = "";

    my $tags_aref = tags_for_qst($dbh, $qid);
    my @tags = @{$tags_aref};

    if (@tags > 0) {
        my $tag = shift @tags;
        $html = qq{<p> Tags: $tag};
        foreach $tag (@tags) {
            $html = $html . qq{, $tag};
        }
        $html = $html . q{</p>};
    }

    return $html;
}

sub html_select_qtype {
    my $dbh = shift;
    my $given_qtype = shift;

    my $html = q{<select name="qtype">};

    my $query = "SELECT qst_type_id, qst_type_name FROM ry_qst_types ORDER BY qst_type_id";
    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    $stmt->execute() or die $dbh->errstr;

    while (my ($qst_type_id, $qst_type_name) = $stmt->fetchrow()) {
        my $sel = "";

        if (defined $given_qtype && $given_qtype == $qst_type_id) {
            $sel = "selected";
        }
        $html = $html . qq{<option value="$qst_type_id" $sel> $qst_type_name </option>};
    }
    $html = $html . q{</select>};
    $stmt->finish();
    return $html;
}

# Display a question in the Tinker interface.
sub display_question {
    my $dbh = shift;
    my $row_href = shift;
    my $sid = shift;

    if (! defined $row_href) {
        print qq{<p> Question with given QID not found. </p>};
        die "Row from question table NOT available";
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


    my $html_qsrc = html_select_refs($dbh, "qsrc_ref", $ROW{'qsrc_ref'});
    my $html_tags = html_show_tags($dbh, $ROW{'qid'});
    my $html_qtype = html_select_qtype($dbh, $ROW{'qtype'});

    print qq{
<div class="question">
    <h2> Question </h2>
    <p> $ROW{'qhtml'} </p>
    $html_tags
</div> <!-- question -->

        <div class="question">
            <h2> Modify Question </h2>
            <form action="tinker.pl?sid=$sid" method="post">
            <table align="center">

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
            <td> <p> Question (in HTML format) </p> </td>
            <td> <textarea name="qhtml" cols="80" rows="10">$ROW{'qhtml'}</textarea> </td>
            </tr>

<tr>
    <td> Question Type </td>
    <td> $html_qtype </td>
</tr>

    <tr>
        <td> Question Has Images (HTML) </td>
        <td>
            <select name="has_images" selected="$ROW{'qhtml_img'}">
                <option value="0">No</option>
                <option value="1">Yes</option>
            </select>
        </td>
    </tr>

    <tr>
        <td> Source Reference </td>
        <td> $html_qsrc </td>
    </tr>

            </table>

<p>
    <input type="hidden" name="sid" value="$sid" />
    <input type="submit" name="UpdateQuestion" value="Update" />
</p>
            </form>
            </div>
    };
}

sub display_answer_1 {
    my $sid = shift;
    my $row_href = shift;
    my %ROW = %{$row_href};
    my $answer;

    if (! defined $ROW{'qans'}) {
        $answer = "";
    } else {
        $answer = $ROW{'qans'};
    }

    print qq{
        <div>
            <h2> Answer Details </h2>
            <form action="tinker.pl?sid=$ROW{'qid'}" method="post">
            <input type="hidden" name="qid" value="$ROW{'qid'}" />
            <input type="hidden" name="sid" value="$sid" />
            <input type="number" name="qans" value="$answer" />
            <input type="submit" name="UpdateAnswer1" value="Update" />
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
        if ($qtype == 2) {
            display_answer_2($dbh, $sid, $qid);
        } elsif ($qtype == 3) {
            display_child_questions($dbh, $qid);
        } elsif ($qtype == 4) {
            display_answer_string($dbh, $sid, $qid);
        }
    }

    print qq{
        </div>
    };
};

sub display_answer_string {
    my $dbh = shift;
    my $sid = shift;
    my $qid = shift;

    my $answer = select_answer_string($dbh, $qid);

    if (! defined $answer) {
        $answer = "";
    }

    print qq{
<div>
    <h2> Answer (String) </h2>
        <form action="tinker.pl?sid=$sid" method="post">
            <input type="hidden" name="qid" value="$qid" />
            <input type="hidden" name="sid" value="$sid" />
            <textarea rows="5" cols="80" name="qans">$answer</textarea>
            <input type="submit" name="UpdateAnswerString" value="Update Answer" />
        </form>
</div>
};

}

# Sub-routine to display answer for question of type 1.
sub display_answer_2 {
    my $dbh = shift;
    my $sid = shift;
    my $qid = shift;

    my $rows_aref = select_answer_2($dbh, $qid);

    my @rows = @{$rows_aref};

    print qq{
        <form action="tinker.pl" method="post">
            <table>
            <tr> <th> Select </th> <th> Choice (LaTeX) </th> <th> Choice (HTML) </th> </tr>
    };

    my $iter = 1;
    foreach my $row_href (@rows) {
        my %row = %{$row_href};

        my $choice_name = "choice_" . $iter;
        my $choice_name_html = "choice_html_" . $iter;
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
                <td> <input type="text" size="80" name="$choice_name" value="$row{'choice_latex'}" /> </td>
                <td> <input type="text" size="80" name="$choice_name_html" value="$row{'choice_html'}" /> </td>
                </tr>
        };

        $iter++;
    }

    print qq{
        </table>
            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="qid" value="$qid" />
            <input type="submit" name="UpdateAnswer2" value="Update" />
            </form>
    };

# Add an option to add a choice.  New form!
    print qq{
<!-- Begin: Form to Add a Choice. -->
<form action="tinker.pl?sid=$sid" method="post">
    <table>
        <tr>
            <td> Choice (LaTeX) </td>
            <td> <input type="text" size="80" name="choice_latex" /> </td>
        </tr>
        <tr>
            <td> Choice (HTML) </td>
            <td> <input type="text" size="80" name="choice_html" /> </td>
        </tr>
        <tr>
            <td colspan="2">
            <input type="submit" name="add_choice" value="Add Choice"/>
            </td>
        </tr>
    </table>

    <input type="hidden" name="sid" value="$sid" />
    <input type="hidden" name="qid" value="$qid" />
    <input type="hidden" name="chid" value="$iter" />
</form>
<!-- End: Form to Add a Choice. -->
};

}

# This function is valid only for question type of 2. (MCQUNIQ).
sub display_choices {
    my $dbh = shift;
    my $qid = shift;

    my $rows_aref = select_answer_2($dbh, $qid);

    my @rows = @{$rows_aref};

    print qq{
<div>
    <h2> Available Choices </h2>

    <table>
        <tr> <th> C No </th> <th> Choice (LaTeX) </th> <th> Choice (HTML) </th> </tr>
    };

    my $iter = 1;
    foreach my $row_href (@rows) {
        my %row = %{$row_href};

        my $choice_name = "choice_" . $iter;
        my $choice_name_html = "choice_html_" . $iter;
        my $choice_id = $row{'chid'};
        my $correct = $row{'correct'};
        my $border = "none";

        if ($correct) {
            $border = "1px solid";
        } 

        print qq{
        <tr> 
            <td style="border: $border;"> $iter </td>
            <td> $row{'choice_latex'} </td>
            <td> $row{'choice_html'} </td>
        </tr>
        };

        $iter++;
    }

    print qq{
    </table>
</div>
};
}

sub display_error {
    my $mesg = shift;
    print qq{$mesg};
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
