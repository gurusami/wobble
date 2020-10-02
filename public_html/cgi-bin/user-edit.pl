#!/usr/bin/perl
#
# Created: Mon 21 Sep 2020 09:16:43 PM IST
# Last-Updated: Mon 21 Sep 2020 09:16:43 PM IST
# 
# Time-stamp: <2020-09-09 13:41:07 annamalai>
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

# For this page the following information is required.
# 
# $FORM{'target_user'}

use strict;
use warnings;

require './profile.pl';
require './utility.pl';

my $DBH;
my %FORM;
my %SESSION;

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

sub PROCESS {
    if ($ENV{'REQUEST_METHOD'} eq "POST") {

        if (defined $FORM{'remove_tag_from_user'}) {
            remove_user2tag($DBH, $FORM{'target_user'}, $FORM{'tag_id'}, $FORM{'by_user'});
        } elsif (defined $FORM{'add_tag_to_user'}) {
            insert_user2tag($DBH, $FORM{'target_user'}, $FORM{'tag_id'}, $FORM{'by_user'});
        }
    }
}

sub local_css()
{
    print qq{
<style>
</style>
};
}

sub show_user_info  {
    my $query = qq{SELECT * FROM ry_users WHERE userid = ?};
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($FORM{'target_user'});
    my $row_href = $stmt->fetchrow_hashref();
    my %ROW = %{$row_href};

    print qq{
        <div>
            <h3> User Details </h3>
            <table>
                <tr> <td> User ID </td> <td> $ROW{'userid'} </td> </tr>
                <tr> <td> User Name </td> <td> $ROW{'username'} </td> </tr>
                <tr> <td> Created On </td> <td> $ROW{'ur_created'} </td> </tr>
            </table>
        </div>
    };

    $stmt->finish();
}

sub show_all_tags {
    my $query = "SELECT * FROM ry_tags ORDER BY tg_tag";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute() or die $DBH->errstr();

    print qq{
        <div>
            <h3> All Available Tags </h3>
            <ul id="menu">
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        print qq{<li>};
        show_add_tag_button_form($ROW{'tg_tagid'},  $ROW{'tg_tag'});
        print qq{ </li> };
    }

    print qq{</ul> </div>};
}

sub show_add_tag_button_form {
    my $tag_id = shift;
    my $tag = shift;

    my $sid = $SESSION{'sid'};
    my $userid = $SESSION{'userid'};
    my $qid = $FORM{'qid'};

    print qq{
        <form action="user-edit.pl?sid=$sid" method="post">
            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="target_user" value="$FORM{'target_user'}" />
            <input type="hidden" name="by_user" value="$userid" />
            <input type="hidden" name="tag_id" value="$tag_id" />
            <input type="submit" name="add_tag_to_user" value="$tag"/>
            </form>
    }
}

sub show_remove_tag_button_form {
    my $tag_id = shift;
    my $tag = shift;

    my $sid = $SESSION{'sid'};
    my $userid = $SESSION{'userid'};
    my $qid = $FORM{'qid'};

    print qq{
        <form action="user-edit.pl?sid=$sid" method="post">
            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="target_user" value="$FORM{'target_user'}" />
            <input type="hidden" name="by_user" value="$SESSION{'userid'}" />
            <input type="hidden" name="tag_id" value="$tag_id" />
            <input type="submit" name="remove_tag_from_user" value="$tag"/>
            </form>
    }
}

sub show_user_interested_tags {
    my $query = "SELECT * FROM ry_user2tag a, ry_tags b WHERE a.u2t_tagid = b.tg_tagid AND a.u2t_userid = ? ORDER BY tg_tag";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($FORM{'target_user'}) or die $DBH->errstr();

    print qq{
        <div>
            <h3> User Relevant Tags </h3>
            <ul id="menu">
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        print qq{<li>};
        show_remove_tag_button_form($ROW{'tg_tagid'},  $ROW{'tg_tag'});
        print qq{ </li> };
    }

    print qq{</ul> </div>};
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Edit Details of Single User </title>";

    link_css();
    local_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    show_user_info();
    show_user_interested_tags();
    show_all_tags();

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
