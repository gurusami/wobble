#!/usr/bin/perl

use strict;
use warnings;
use DBI;

our $log;

my $t_users = 'ry_users';
my $t_sessions = 'ry_sessions';

my %TABLE = (
    answer_1 => 'answer_1',
    question => 'question',
    qid_ref  => 'ry_qid_ref',
    );

sub last_insert_id {
    my $dbh = shift;
    
    my $sel_stmt = $dbh->prepare("SELECT last_insert_id()");
    $sel_stmt->execute();
    my ($ins_id) = $sel_stmt->fetchrow();
    $sel_stmt->finish();

    return $ins_id;
}

# -------------------------------------------------------------------------
# BEGIN TABLE 'question'

sub insert_question {
    my $dbh = shift;

    my $query = "INSERT INTO question (qlatex) VALUES ('')";
    my $stmt = $dbh->prepare($query);
    $stmt->execute();
    $stmt->finish();

    return last_insert_id($dbh);
};


sub insert_question_type1 {
    my $dbh = shift;
    my $userid = shift;
    my $question = shift;
    my $qst_html = shift;

    my $query = "INSERT INTO $TABLE{'question'} (userid, qlatex, qhtml, qtype) VALUES (?, ?, ?, 1)";
    my $stmt = $dbh->prepare($query) or die "prepare statement failed: $dbh->errstr()";
    $stmt->execute($userid, $question, $qst_html) or die "execution failed: $dbh->errstr()";
    $stmt->finish();

    return last_insert_id($dbh);
}


sub insert_child_question {
    my $dbh = shift;
    my $pqid = shift;

    my $query = "INSERT INTO question (qparent) VALUES (?)";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($pqid);
    $stmt->finish();

    my $sel_stmt = $dbh->prepare("SELECT last_insert_id()");
    $sel_stmt->execute();
    my ($qid) = $sel_stmt->fetchrow();
    $stmt->finish();

    return $qid;
};

sub select_question {
    my $dbh = shift;
    my $qid = shift;

    my $query = "SELECT qid, qparent, qlatex, qimage, qhtml, qtype FROM question WHERE qid = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($qid);
    my $row = $stmt->fetchrow_hashref();
    $stmt->finish();
    return $row;
}

sub select_max_qid {
    my $dbh = shift;
    
    my $sel_stmt = $dbh->prepare("SELECT MAX(qid) FROM question");
    $sel_stmt->execute();
    my ($max_qid) = $sel_stmt->fetchrow();
    $sel_stmt->finish();

    return $max_qid;
}

sub update_question {
    my $dbh = shift;
    my $form_href = shift;

    my %FORM = %{$form_href};

    my $qid = $FORM{'qid'};

    my $query = "UPDATE question SET qlatex = ?, qtype = ? WHERE qid = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($FORM{'question'}, $FORM{'qtype'}, $qid) or return undef;
    log_append("Update question (qid=$qid) successfully");
    $stmt->finish();
}

# END TABLE: question
# -------------------------------------------------------------------------

sub select_answer_0 {
    my $dbh = shift;
    my $qid = shift;

    my $query = "SELECT qid, qans FROM answer_0 WHERE qid = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($qid);
    my $row = $stmt->fetchrow_hashref();
    $stmt->finish();
    return $row;
}

sub insert_answer_0 {
    my $dbh = shift;
    my $qid = shift;

    my $query = "INSERT INTO answer_0 (qid) VALUES (?)";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($qid);
    $stmt->finish();
}

sub update_answer_0 {
    my $dbh = shift;
    my $qid = shift;
    my $ans = shift;

    my $query = "UPDATE answer_0 SET qans = ? WHERE qid = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($ans, $qid);
    $stmt->finish();
}

# -------------------------------------------------------------------------
# BEGIN: TABLE answer_1
# This returns an array of rows. 
sub select_answer_1 {
    my $dbh = shift;
    my $qid = shift;

    my $query = "SELECT qid, chid, choice_latex, correct FROM answer_1 WHERE qid = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($qid) or return undef;
    my @rows_aref;
    while (my $row_href = $stmt->fetchrow_hashref())
    {
	push @rows_aref, $row_href;
    }
    
    $stmt->finish();
    log_append("Successfully fetched the choices.");
    return \@rows_aref;
}

sub insert_answer_1 {
    my $dbh = shift;
    my $form_href = shift;
    my %FORM = %{$form_href};

    my $qid = $FORM{'qid'};
    my $chid = $FORM{'chid'};
    my $choice = $FORM{'the_choice'};
    
    my $query = "INSERT INTO answer_1 (qid, chid, choice_latex, correct) VALUES (?, ?, ?, ?)";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($qid, $chid, $choice, 0);
    $stmt->finish();
}

sub update_answer_1 {
    my $dbh = shift;
    my $form_href = shift;
    my %FORM = %{$form_href};

    my $qid = $FORM{'qid'};
    my $query = "UPDATE answer_1 SET choice_latex = ?, correct = ? WHERE qid = ? AND chid = ?";
    my $stmt = $dbh->prepare($query);
    my $correct_choice = $FORM{'choice_radio'};
    
    my $i = 1;
    while (1) {
	my $choice_name = "choice_" . $i;
	if (! defined $FORM{$choice_name}) {
	    last;
	}

	my $is_correct;

	if ($i == $correct_choice) {
	    $is_correct = 1;
	} else {
	    $is_correct = 0;
	}

	my $qlatex = $FORM{$choice_name};

	$stmt->execute($qlatex, $is_correct, $qid, $i);
		       
	$i++;
    }
    $stmt->finish();
}

sub insert_choices {
    my ($dbh, $qid, $choices_aref, $answers_aref) = @_;

    my @choices = @{$choices_aref};
    my @answers = @{$answers_aref};
    
    my $query = "INSERT INTO $TABLE{'answer_1'} (qid, chid, choice_latex, correct) VALUES ($qid, ?, ?, ?)";
    my $rv;

    my $stmt = $dbh->prepare($query) or die $dbh->errstr();

    my $n_choices = scalar(@choices);

    my $chid = 1;
    for (my $i = 0; $i < $n_choices; $i++) {
	$rv = $stmt->execute($chid, $choices[$i], $answers[$i]) or die "execution failed: $dbh->errstr()";

	$chid++;
    }

    return $rv;
}

# END: TABLE answer_1
# -------------------------------------------------------------------------

# TABLE: ry_biblio

sub insert_biblio {
    my $dbh = shift;
    my $form_href = shift;
    my %FORM = %{$form_href};

    my $ins_query = "INSERT INTO ry_biblio (ref_nick, ref_type, ref_author, " .
	"ref_series, ref_title, ref_isbn10, ref_isbn13, ref_year, ref_publisher, " .
	"ref_keywords, ref_url, ref_accessed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    my $ref_nick;

    my $accessed;

    if (defined $FORM{'ref_accessed'} && length($FORM{'ref_accessed'}) > 0) {
	$accessed = $FORM{'ref_accessed'};
    }
    my $stmt = $dbh->prepare($ins_query);
    $stmt->execute($FORM{'ref_nick'}, $FORM{'ref_type'}, $FORM{'ref_author'}, 
		   $FORM{'ref_series'}, $FORM{'ref_title'}, $FORM{'ref_isbn10'},
		   $FORM{'ref_isbn13'}, $FORM{'ref_year'}, $FORM{'ref_publisher'}, 
		   $FORM{'ref_keywords'}, $FORM{'ref_url'}, $accessed)
	or return undef;
    $stmt->finish();

    return last_insert_id($dbh);
}

# -------------------------------------------------------------------------
# BEGIN TABLE: ry_qid_ref
sub insert_qid_ref {
    my $dbh = shift;
    my $form_href = shift;
    my %FORM = %{$form_href};

    my $ins_query = "INSERT INTO $TABLE{'qid_ref'} (qid, ref_id) " . " VALUES (?, ?)";

    my $stmt = $dbh->prepare($ins_query);
    $stmt->execute($FORM{'qid'}, $FORM{'ref_id'}) or return undef;
    $stmt->finish();

    return $FORM{'qid'};
};

sub insert_qid_ref_2 {
    my $dbh = shift;
    my $qid = shift;
    my $ref_id = shift;

    my $ins_query = "INSERT INTO $TABLE{'qid_ref'} (qid, ref_id) " . " VALUES (?, ?)";

    my $stmt = $dbh->prepare($ins_query);
    $stmt->execute($qid, $ref_id) or return undef;
    $stmt->finish();

    return $ref_id;
};

# END TABLE: ry_qid_ref
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# BEGIN - TABLE: ry_users
#
# The variable t_users, represents this table.

sub is_token_ok {
    my $dbh  = shift;
    my $u_name = shift;
    my $token = shift;

    my $query = "SELECT userid, sha2(?, 256) = token FROM $t_users WHERE username = ?";
    my $stmt = $dbh->prepare($query);
    $stmt->execute($token, $u_name) or return undef;
    if (my ($userid, $valid) = $stmt->fetchrow()) {
	if (defined $valid && $valid == 1) {
	    return $userid;
	}
    }
    $stmt->finish();
    return 0;
};

# END - TABLE: ry_users
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# BEGIN - TABLE: ry_sessions
#
# The variable t_sessions, represents this table.

sub insert_session {
    my $dbh = shift;
    my $sid = shift;
    my $userid = shift;

    my $query = "INSERT INTO $t_sessions (sid, userid, start, stop) VALUES (?, ?, now(), addtime(now(), '02:00:00'))";
    my $stmt = $dbh->prepare($query) or return undef;
    $stmt->execute($sid, $userid) or return undef;
    $stmt->finish();

    return 1;
}

sub remove_sessions {
    my $dbh = shift;
    my $userid = shift;

    my $query = "DELETE FROM $t_sessions WHERE userid = ?";
    my $stmt = $dbh->prepare($query) or return undef;
    $stmt->execute($userid) or return undef;
    $stmt->finish();

    return 1;
}

sub select_session {
    my $dbh = shift;
    my $sid = shift;

    my $query = "SELECT sid, userid, start, stop FROM $t_sessions WHERE sid = ?";
    my $stmt = $dbh->prepare($query) or return undef;
    $stmt->execute($sid) or return undef;
    my $row_href = $stmt->fetchrow_hashref();
    $stmt->finish();

    return $row_href;
}

sub is_session_valid {
    my $dbh = shift;
    my $sid = shift;

    my $query = "SELECT sid, userid, start, stop, (now() < stop) AS valid FROM $t_sessions WHERE sid = ?";
    my $stmt = $dbh->prepare($query) or return undef;
    $stmt->execute($sid) or return undef;

    my %row;
    my $row_href;
    
    if ($row_href = $stmt->fetchrow_hashref()) {
	%row = %{$row_href};
    }
    $stmt->finish();

    if (! defined $row_href) {
	return undef;
    }
    
    if ($row{'valid'} == 0) {
	return undef;
    }

    return $row_href;
}

# END - TABLE: ry_sessions

1;
