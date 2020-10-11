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
# $FORM{'ref_id'} is needed for this page.
#
# PURPOSE: Show the list of questions in the given ref_id.

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

sub show_mcq_unique_choices {
    my $qid = shift;
    my $result = "<ol>";

    my $query = q{SELECT chid, choice_latex, choice_html, correct FROM answer_2 WHERE qid = ? ORDER BY chid};
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($qid);

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};

        $result = $result .  qq{<li> $ROW{'choice_html'} </li>};
    }
    $result = $result . q{</ol>};

    return $result;
}

sub add_question_form {
    my $sid = $SESSION{'sid'};
    my $ref_id = $FORM{'ref_id'};

    print qq{
        <div style="text-align: center;">
            <form action="tinker.pl?sid=$sid" method="post">
                <input type="hidden" name="ref_id" value="$ref_id" />
                <input type="hidden" name="sid" value="$sid" />
                <input type="hidden" name="qsrc_ref" value="$ref_id" />
                <input type="submit" name="add_question_from_src" value="Add Question From This Source" />
            </form>
        </div>
    };
}

sub show_src_ref {
    my $ref_id = shift;
    my $query = q{SELECT * FROM ry_biblio WHERE ref_id = ? };
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();;
    $stmt->execute($ref_id) or die $DBH->errstr();
    my $row_href = $stmt->fetchrow_hashref();
    my %ROW = %{$row_href};

    print qq{
        <div>
            <h3 align="center"> Source Reference </h3>
            <table>
                <tr> <th> Ref ID </th> <td> $ROW{'ref_id'} </td> </tr>
                <tr> <th> Ref Nick </th> <td> $ROW{'ref_nick'} </td> </tr>
                <tr> <th> Ref Type </th> <td> $ROW{'ref_type'} </td> </tr>
                <tr> <th> Author </th> <td> $ROW{'ref_author'} </td> </tr>
                <tr> <th> Series </th> <td> $ROW{'ref_series'} </td> </tr>
                <tr> <th> Title </th> <td> $ROW{'ref_title'} </td> </tr>
                <tr> <th> ISBN10 </th> <td> $ROW{'ref_isbn10'} </td> </tr>
                <tr>
                    <th> ISBN13 </th>
                    <td> <a href="https://isbnsearch.org/isbn/$ROW{'ref_isbn13'}" target="_blank"> $ROW{'ref_isbn13'} </a> </td>
                </tr>
                <tr> <th> URL </th> <td> $ROW{'ref_url'} </td> </tr>
            </table>
        </div>
    };
}

sub show_questions {
    my $ref_id = shift;
    my $sid = $SESSION{'sid'};

    my $query = q{SELECT * FROM question a, ry_qst_types b
        WHERE a.qtype = b.qst_type_id
        AND qsrc_ref = ?
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();;
    $stmt->execute($ref_id) or die $DBH->errstr();

    print qq{
        <div>
            <table>
                <tr> <th> QID </th> <th> Question </th> <th> Type </th>
                    <th> Tinker </th>
                </tr> 
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        my $choices = "";

        if ($ROW{'qtype'} == 2) {
            $choices = show_mcq_unique_choices($ROW{'qid'});
        }

        print qq{
            <tr>
                <td> $ROW{'qid'} </td>
                <td> $ROW{'qhtml'}
                    $choices
                </td>
                <td> $ROW{'qst_type_nick'} </td>
                <td>
                    <form action="tinker.pl?sid=$sid" method="post">
                        <input type="hidden" name="qid" value="$ROW{'qid'}" />
                        <input type="hidden" name="sid" value="$sid" />
                        <input type="submit" name="tinker" value="Tinker" />
                    </form>
                </td>
            </tr>
        };
    }

    print qq{</table></div>};

    $stmt->finish();
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

    show_src_ref($FORM{'ref_id'});
    add_question_form();
    show_questions($FORM{'ref_id'});
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
