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
    }
}

sub local_css()
{
    print qq{
<style>
</style>
};
}

sub html_monitor_user {
    my $userid = shift;

    my $sid = $SESSION{'sid'};
    my $html = qq{
        <form action="checkuser.pl?sid=$sid" method="post">
            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="target_user" value="$userid" />
            <input type="submit" name="monitor_user" value="Monitor" />
        </form>
    };

    return $html;
}

sub show_all_users()
{
    my $sid = $SESSION{'sid'};
    my $query = "SELECT * FROM ry_users ORDER BY userid";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute() or die $DBH->errstr();

    print qq{
        <div>
        <table>
            <tr>
                <th> User ID  </th>
                <th> User Name </th>
                <th> Created </th>
                <th> Monitor </th>
                <th> Edit </th>
            </tr>
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        my $monitor = html_monitor_user($ROW{'userid'});

        print qq{
            <tr>
                <td> $ROW{'userid'} </td>
                <td> $ROW{'username'} </td>
                <td> $ROW{'ur_created'} </td>
                <td> $monitor </td>
                <td> <a href="user-edit.pl?sid=$sid&target_user=$ROW{'userid'}">Edit</a> </td>
            </tr>
        };
    }

    print qq{
        </table>
        </div>
    };
}


sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";

    link_css();
    local_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    show_all_users();
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
