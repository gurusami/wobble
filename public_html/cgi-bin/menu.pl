#!/usr/bin/perl
#
# Time-stamp: <2020-09-11 13:41:26 annamalai>
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
#

use strict;
use warnings;

my %FORM;
my %SESSION;
my $DBH;

require './profile.pl';
require './utility.pl';
require './model.pl';

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

sub IF_AUTH_LINK {
    my $script = shift;
    my $text = shift;

    if (check_acl($DBH, $SESSION{'userid'}, $script)) {
	print qq[<li> <a href="$script?sid=$SESSION{'sid'}"> $text </a> </li>];
    }
    
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    print "<!doctype html>";
    print "<html>";
    print "<head>";
    print "<title> Main Menu </title>";
    link_css();
    print "</head>";

    print "<body>";

    top_menu($FORM{'sid'});
    
    print "<ul>";
    IF_AUTH_LINK("browse.pl", "Browse Questions");
    IF_AUTH_LINK("addmcq.pl", "Add Type 1 Question (MCQ)");
    IF_AUTH_LINK("tinker.pl", "Tinker a Question");
    IF_AUTH_LINK("biblio.pl", "Register a Reference/Bibliography");
    IF_AUTH_LINK("create-test.pl", "Create a New Test");
    IF_AUTH_LINK("maketest.pl", "Prepare a Test (Add/Remove Questions)");
    IF_AUTH_LINK("test-schedule.pl", "Schedule a Test");
    IF_AUTH_LINK("list-test-sch.pl", "List ALL Scheduled Tests");
    IF_AUTH_LINK("list-mytests.pl", "List My Tests");
    IF_AUTH_LINK("test-reports.pl", "My Test Reports");
    print "</ul>";
    print "</body>";

    DTOR();
}

MAIN();
