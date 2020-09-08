#!/usr/bin/perl
# Time-stamp: <2020-09-08 13:26:10 annamalai>
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

our $log;

my $t_users = 'ry_users';
my $t_sessions = 'ry_sessions';

my %TABLE = (
    answer_1 => 'answer_1',
    question => 'question',
    qid_ref  => 'ry_qid_ref',
    tests    => 'ry_tests',
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
# -------------------------------------------------------------------------

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

# -------------------------------------------------------------------------
# BEGIN - TABLE: ry_tests
# -------------------------------------------------------------------------

sub insert_new_test {
    my $dbh = shift;
    my $tst_type = shift;
    my $tst_title = shift;
    my $tst_owner = shift;

    my $query = "INSERT INTO $TABLE{'tests'} (tst_type, tst_title, tst_owner) VALUES (?, ?, ?)";
    my $stmt = $dbh->prepare($query) or return undef;
    $stmt->execute($tst_type, $tst_title, $tst_owner) or return undef;
    $stmt->finish();

    return last_insert_id($dbh);
}

sub increment_tst_version {
    my $dbh = shift;
    my $tst_id = shift;
    
    my $query = "UPDATE ry_tests SET tst_version = tst_version + 1 WHERE tst_id = ?";
    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    $stmt->execute($tst_id) or die $dbh->errstr();
    $stmt->finish();
}

sub get_tst_version {
    my $dbh = shift;
    my $tst_id = shift;
    
    my $query = "SELECT tst_version FROM ry_tests WHERE tst_id = ?";
    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    $stmt->execute($tst_id) or die $dbh->errstr();
    my ($tst_version) = $stmt->fetchrow();
    $stmt->finish();

    return $tst_version;
}

# -------------------------------------------------------------------------
# END - TABLE: ry_tests
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# BEGIN - TABLE: ry_test_questions
# -------------------------------------------------------------------------

sub insert_one_test_question {
    my $dbh = shift;
    my $tst_id = shift;
    my $tst_version = shift;
    my $qid = shift;

    my $query = "INSERT INTO ry_test_questions (tq_tst_id, tq_tst_version, tq_qid) VALUES (?, ?, ?)";
    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    $stmt->execute($tst_id, $tst_version, $qid) or die $dbh->errstr();
    $stmt->finish();
}

sub remove_one_test_question {
    my $dbh = shift;
    my $tst_id = shift;
    my $tst_version = shift;
    my $qid = shift;

    my $query = "INSERT INTO ry_test_questions (tq_tst_id, tq_tst_version, tq_qid, tq_added) VALUES (?, ?, ?, false)";
    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    $stmt->execute($tst_id, $tst_version, $qid) or die $dbh->errstr();
    $stmt->finish();
}


sub add_question_to_test {
    my $dbh = shift;
    my $tst_id = shift;
    my $qid = shift;

    $dbh->begin_work();
    increment_tst_version($dbh, $tst_id);
    my $tst_version = get_tst_version($dbh, $tst_id);
    insert_one_test_question($dbh, $tst_id, $tst_version, $qid);
    $dbh->commit();    
}

sub remove_question_from_test {
    my $dbh = shift;
    my $tst_id = shift;
    my $qid = shift;

    $dbh->begin_work();
    increment_tst_version($dbh, $tst_id);
    my $tst_version = get_tst_version($dbh, $tst_id);
    remove_one_test_question($dbh, $tst_id, $tst_version, $qid);
    $dbh->commit();    
}


sub get_questions {
    my $dbh = shift;
    my $tst_id = shift;
    my $tst_version = shift;
    
    my %QID_LIST;
    my $query = "SELECT tq_qid, tq_added FROM ry_test_questions WHERE tq_tst_id = ? AND tq_tst_version <= ? ORDER BY tq_tst_version";

    my $stmt = $dbh->prepare($query) or die $dbh->errstr();
    $stmt->execute($tst_id, $tst_version) or die $dbh->errstr();

    while (my ($qid, $added) = $stmt->fetchrow()) {
	if ($added) {
	    if (defined $QID_LIST{$qid}) {
		$QID_LIST{$qid}++;
	    } else {
		$QID_LIST{$qid} = 1;
	    }
	} else {
	    $QID_LIST{$qid} = 0;
	}
    }

    $stmt->finish();

    return \%QID_LIST;
}

sub get_qid_in_tst {
    my $dbh = shift;
    my $tst_id = shift;
    my $tst_version = shift;

    my $qlist_href = get_questions($dbh, $tst_id, $tst_version);
    my %QID_LIST = %{$qlist_href};

    my @qid_in_tst;
    foreach my $qid (keys %QID_LIST) {
	if ($QID_LIST{$qid} == 0) {
	    next;
	} elsif ($QID_LIST{$qid} == 1) {
	    push @qid_in_tst, $qid;
	} else {
	    die "Question $qid occurs more than once in test $tst_id";
	}
    }

    return \@qid_in_tst;
}

# -------------------------------------------------------------------------
# BEGIN - TABLE: ry_test_questions
# -------------------------------------------------------------------------


1;
