#!/usr/bin/perl
#
# Time-stamp: <2020-09-04 18:50:57 annamalai>
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
    print "<title> Manage References </title>";
    print "</head>";

    print "<body>";

    print "<ul>";
    print qq[<li> <a href="browse.pl?sid=$SESSION{'sid'}">Browse Questions</a> </li>];
    print qq[<li> <a href="addmcq.pl?sid=$SESSION{'sid'}">Add a Type 1 Question</a> </li>];
    print qq[<li> <a href="tinker.pl?sid=$SESSION{'sid'}">Tinker a Question</a> </li>];
    print qq[<li> <a href="biblio.pl?sid=$SESSION{'sid'}">Add a reference or a bibliographic entry</a> </li>];

    print "</ul>";
    print "</body>";

    DTOR();
}

MAIN();
