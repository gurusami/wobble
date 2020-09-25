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

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    print "<!doctype html>";
    print "<html>";
    print "<head>";
    print "<title> Wobble: Main Menu </title>";
    link_css();
    print "</head>";

    print "<body>";

    my $userid = $SESSION{'userid'};
    my $sid = $SESSION{'sid'};

    top_menu($DBH, $userid, $sid);
    
    print qq{
<div id="main">
<h2> Welcome </h2>
<ul>
};
    IF_AUTH_LINK($DBH, $userid, $sid, "browse.pl", "Browse Questions");
    # IF_AUTH_LINK("addmcq.pl", "Add Type 1 Question (MCQ)");
    IF_AUTH_LINK($DBH, $userid, $sid, "tinker.pl", "Tinker a Question");
    IF_AUTH_LINK($DBH, $userid, $sid, "biblio.pl", "Register a Reference/Bibliography");
    IF_AUTH_LINK($DBH, $userid, $sid, "create-test.pl", "Create/Modify/List Tests");
    IF_AUTH_LINK($DBH, $userid, $sid, "test-schedule.pl", "Schedule a Test");
    IF_AUTH_LINK($DBH, $userid, $sid, "list-test-sch.pl", "List ALL Scheduled Tests");
    IF_AUTH_LINK($DBH, $userid, $sid, "list-mytests.pl", "List My Tests");
    IF_AUTH_LINK($DBH, $userid, $sid, "test-reports.pl", "My Test Reports");
    IF_AUTH_LINK($DBH, $userid, $sid, "test-reports-all.pl", "ALL Test Reports");
    IF_AUTH_LINK($DBH, $userid, $sid, "note-edit.pl", "Edit a Note");
    IF_AUTH_LINK($DBH, $userid, $sid, "image-upload.pl", "Upload an image");
    IF_AUTH_LINK($DBH, $userid, $sid, "image-view.pl", "View an image");
    IF_AUTH_LINK($DBH, $userid, $sid, "validate.pl", "List Tests That I Need To Validate");
    IF_AUTH_LINK($DBH, $userid, $sid, "qpapers.pl", "List of Available Question Papers");
    print qq{
</ul>
</div>
</body>
};

    DTOR();
}

MAIN();
