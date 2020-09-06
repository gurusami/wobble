#!/usr/bin/perl

use strict;
use warnings;

require './model.pl';

sub handle_all_forms {
    my $dbh = shift;
    my $form_href = shift;

    my %FORM = %{$form_href};

    if ($FORM{'UpdateAnswer0'} && ($FORM{'UpdateAnswer0'} eq "Update")) {
	update_answer_0($dbh, $FORM{qid}, $FORM{qans});
    } elsif ($FORM{'UpdateQuestion'} && ($FORM{'UpdateQuestion'} eq "Update")) {
	update_question($dbh, $form_href);
    } elsif ($FORM{'UpdateAnswer1'} && ($FORM{'UpdateAnswer1'} eq "Update")) {
	update_answer_1($dbh, $form_href);
    } elsif ($FORM{'add_new_question'} && ($FORM{'add_new_question'} eq "Add New Question")) {
	my $qid = insert_question($dbh);
	$FORM{'qid'} = $qid;
    } elsif ($FORM{'add_choice'} && ($FORM{'add_choice'} eq "Add Choice")) {
	insert_answer_1($dbh, $form_href);
    } elsif ($FORM{'add_child_question'} && ($FORM{'add_child_question'} eq "Add Child Question")) {
	insert_child_question($dbh, $FORM{'parent_qid'});
    } elsif ($FORM{'visit_parent'} && ($FORM{'visit_parent'} eq "Visit Parent")) {
	# The qid has been updated.  Nothing else to do.
    } elsif ($FORM{'add_ref'} && ($FORM{'add_ref'} eq "Add Reference")) {
	insert_qid_ref($dbh, $form_href);
    }

    return \%FORM;
};

1;
