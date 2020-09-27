#!/usr/bin/perl
# Created: Fri 18 Sep 2020 11:31:17 AM IST
# Last-Updated: Fri 18 Sep 2020 11:31:17 AM IST
# Time-stamp: <2020-09-12 10:27:16 annamalai>
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
#
# To edit/modify one question.
#
use strict;
use warnings;
use DBI;
use URI::Encode qw(uri_encode uri_decode);

require "./profile.pl";
require "./display.pl";
require "./model.pl";
require "./utility.pl";

our $dsn;
our $log;
my %FORM;
my %SESSION;
my $DBH;

sub display_top {
    print q[
<div id="main">
<h2 class="title"> Tinker A Question </h2>
<div class="grid-container">
];

    
    display_tinker_form();
    display_add_question_form();
    display_create_given_qid();
    print q[
</div> <!-- class="grid-container" -->
</div>
];
};

sub display_add_question_form {
    print qq{
    <div class="obtain_qid_form">
    <form action="tinker.pl" method="POST">
	<input type="hidden" name="sid" value="$SESSION{'sid'}" />
	<input type="submit" name="add_new_question" value=\"Add New Question\" />
	</form>
	</div>
    };
}

sub display_tinker_form {
    print qq{
        <div class="obtain_qid_form">
            <form action="tinker.pl?sid=$SESSION{'sid'}" method="POST">
            <input type="number" name="qid" value="$FORM{'qid'}" />
            <input type="hidden" name="sid" value="$SESSION{'sid'}" />
            <input type="submit" name="form_tinker" value="Tinker" />
            </form>
            </div>
    };
}

sub display_create_given_qid {
    print qq{
<div class="obtain_qid_form">
    <form action="tinker.pl?sid=$SESSION{'sid'}" method="POST">
        <input type="number" name="qid" />
        <input type="hidden" name="sid" value="$SESSION{'sid'}" />
        <input type="submit" name="create_given_qid" value="Create QID" />
	</form>
</div>
    };
}

sub display_add_reference {
    print qq[
    <form action="tinker.pl" method="post">
    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
    <input type="hidden" name="qid" value="$FORM{'qid'}" />];
    select_refs($DBH, "ref_id");

    print q{
<input type="submit" name="add_ref" value="Add Reference"/>
</form>
};

};

sub show_all_tags {
    my $qid = $FORM{'qid'};
    my $query = "SELECT * FROM ry_tags WHERE tg_tagid NOT IN (SELECT q2t_tagid FROM ry_qst2tag WHERE q2t_qid = ?) ORDER BY tg_tag";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($qid) or die $DBH->errstr();

    print qq{<ul id="menu">};

    while (my ($row_href) = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        print qq{<li>};
        show_add_tag_button_form($ROW{'tg_tagid'},  $ROW{'tg_tag'});
        print qq{ </li> };
    }

    print qq{</ul>};
};

sub show_add_tag_button_form {
    my $tag_id = shift;
    my $tag = shift;

    my $sid = $SESSION{'sid'};
    my $userid = $SESSION{'userid'};
    my $qid = $FORM{'qid'};

    print qq{
        <form action="tinker.pl?sid=$sid" method="post">
            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="userid" value="$userid" />
            <input type="hidden" name="qid" value="$qid" />
            <input type="hidden" name="tag_id" value="$tag_id" />
            <input type="submit" name="add_tag" value="$tag"/>
            </form>
    }
}

sub display_add_tag_form {
    my $html_tags = html_show_tags($DBH, $FORM{'qid'});

    print qq[
<div id="add_tag_form">
    <h2> Tags </h2>
    <p> $html_tags </p>
];

    show_all_tags();

    print qq[
</div> <!-- add_tag_form -->
];
}

sub display_references {
    my $dbh = shift;

    my $query = "SELECT bib.ref_id, bib.ref_author, bib.ref_title FROM ry_biblio bib, ry_qid_ref ref WHERE ref.qid = ? AND ref.ref_id = bib.ref_id ORDER BY bib.ref_id";

    my $stmt = $dbh->prepare($query);
    $stmt->execute($FORM{'qid'});

    print q[<h2> Other References </h2>];

    print q[<ul>];
    while (my $row_href = $stmt->fetchrow_hashref()) {
# print_hash($row_href);
        my %ROW = %{$row_href};
        print qq{<li> $ROW{'ref_author'} <cite> $ROW{'ref_title'} </cite> </li> };
    }
    print q[</ul>];
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};
}

sub CTOR {
    $DBH = db_connect();
}

sub DTOR {
    $DBH->disconnect();
}


sub PROCESS {
    my $form_href = \%FORM;
    # Process the submitted data.
    if ($ENV{'REQUEST_METHOD'} eq "POST") {

        if (defined $FORM{'create_given_qid'}) {
            # We need to create the given qid.
            insert_question_withqid($DBH, $FORM{'qid'}, $SESSION{'userid'});

        } elsif ($FORM{'UpdateAnswer1'} && ($FORM{'UpdateAnswer1'} eq "Update")) {
            update_answer_1($DBH, $FORM{qid}, $FORM{qans});
        } elsif ($FORM{'UpdateQuestion'} && ($FORM{'UpdateQuestion'} eq "Update")) {
            update_question($DBH, $form_href);
        } elsif ($FORM{'UpdateAnswer2'} && ($FORM{'UpdateAnswer2'} eq "Update")) {
            update_answer_2($DBH, $form_href);
        } elsif ($FORM{'add_new_question'} && ($FORM{'add_new_question'} eq "Add New Question")) {
            $FORM{'qid'} = insert_question($DBH, $SESSION{'userid'});
        } elsif ($FORM{'add_choice'} && ($FORM{'add_choice'} eq "Add Choice")) {
            insert_answer_2($DBH, $form_href);
        } elsif ($FORM{'add_child_question'} && ($FORM{'add_child_question'} eq "Add Child Question")) {
            insert_child_question($DBH, $FORM{'parent_qid'});
        } elsif ($FORM{'visit_parent'} && ($FORM{'visit_parent'} eq "Visit Parent")) {
        # The qid has been updated.  Nothing else to do.
        } elsif ($FORM{'add_ref'} && ($FORM{'add_ref'} eq "Add Reference")) {
            insert_qid_ref($DBH, $form_href);
        } elsif (defined $FORM{'add_tag'}) {
            add_tag($DBH, $SESSION{'userid'}, $FORM{'qid'}, $FORM{'tag_id'});
        } elsif (defined $FORM{'UpdateAnswerString'}) {
            modify_answer_string($DBH, $FORM{'qid'}, $FORM{'qans'});
        }
    }
}

sub display_add_note {
    print qq{<a href="notes.pl?sid=$SESSION{'sid'}&qid=$FORM{'qid'}">Add Note</a>};
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Tinker A Question </title>";
    link_css();
    print "</head>";

    print "<body>";

    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    # At this point we have a valid qid, either old or new.  Lets tinker it!

    # Represents one row in the table answer_1.
    my $answer1_row_href;
    my $qrow_href;
    my %QROW;
    my $qid = $FORM{'qid'};

    # Collect Data that is to be used for display.
    # TODO: Data is to be collected based on what is to be displayed.
    # I think it is better if each data is collected by its display unit.

    # print_hash(\%FORM);

    if (defined $qid && $qid > 0) {
        $qrow_href = select_question($DBH, $qid);

        if (defined $qrow_href) {
            %QROW = %{$qrow_href};
            if (defined $QROW{qtype} && $QROW{qtype} == 1) {
                $answer1_row_href = select_answer_1($DBH, $qid);
                if (! defined $answer1_row_href) {
                    insert_answer_1($DBH, $qid);
                    $answer1_row_href = select_answer_1($DBH, $qid);
                }
            }
        } 
    }

    display_top();

    if (defined $FORM{'qid'} && $FORM{'qid'} > 0) {
        display_question($DBH, $qrow_href, $SESSION{'sid'});

        if ($QROW{'qhtml_img'} == 1) {
            # Display the images section only if the question has images.
            display_question_images($DBH, $FORM{'qid'}, $SESSION{'sid'});
        }

        if (defined $qrow_href) {
            if (defined $QROW{'qtype'} && $QROW{'qtype'} == 2) {
                display_choices($DBH, $FORM{'qid'});
            }
            if (defined $QROW{'qtype'} && $QROW{'qtype'} == 1) {
                display_answer_1($SESSION{'sid'}, $answer1_row_href);
            } 

            if (defined $QROW{'qtype'}) {
                display_answer($DBH, $SESSION{'sid'}, $qrow_href);
            }
        }

        display_parent($DBH, $qrow_href);
        display_add_tag_form();
        # display_references($DBH);
        # display_add_reference();
        # display_add_note();
    }

    print "</body>";
    print "</html>";
 
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();

    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    CHECK_AUTH($DBH, $SESSION{'sid'}, $ENV{'SCRIPT_NAME'}, $SESSION{'userid'});
    PROCESS();
    DISPLAY();
    DTOR();
    exit(0);
}

MAIN();
