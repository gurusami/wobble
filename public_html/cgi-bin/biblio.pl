#!/usr/bin/perl
#
# Created: Fri 25 Sep 2020 12:02:01 PM IST
# Last-Updated: Fri 25 Sep 2020 12:02:01 PM IST
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
#
# Colors Used: 99b9ff, e6eeff, bcd4e6, ccdcff, 4f86f7

use strict;
use warnings;

require './profile.pl';
require './utility.pl';
require './model.pl';

my %SESSION;
my %FORM;
my $DBH;
my $ref_id = 0;

sub display_references {
    my $query = q{
        SELECT *
        FROM ry_biblio a, ry_ref_types b
        WHERE a.ref_type = b.ref_type_id
        ORDER BY ref_id
    };

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute() or die $DBH->errstr();

    print qq{
        <div id="biblio">
            <h2 align="center"> Bibliography References </h2>
            <table>
            <tr>
            <th> Ref ID </th>
            <th> Ref Type </th>
            <th> Nick Name </th>
            <th> Author </th>
            <th> Title </th>
            <th> ISBN10 </th>
            <th> ISBN13 </th>
            </tr>
    };

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        my $nick = $ROW{'ref_nick'};

        if ($ROW{'ref_type'} == 3) {
            my $full_url = $ENV{'REQUEST_SCHEME'} . "://" . $ENV{'HTTP_HOST'} . $ENV{'CONTEXT_PREFIX'} . $ROW{'ref_url'};
            $nick = qq{<a href="$full_url">$ROW{'ref_nick'}</a>};
        }

        print qq{
            <tr id="rows">
                <td> $ROW{'ref_id'} </td>
                <td> $ROW{'ref_type_name'} </td>
                <td> $nick </td>
                <td> $ROW{'ref_author'} </td>
                <td> $ROW{'ref_title'} </td>
                <td> $ROW{'ref_isbn10'} </td>
                <td> <a href="https://isbnsearch.org/isbn/$ROW{'ref_isbn13'}" target="_blank"> $ROW{'ref_isbn13'} </a></td>
                </tr>
        };
    }

    print qq {
        </table>
            </div>
    };

    $stmt->finish();
}

sub html_ref_types {
    my $query = qq{
        SELECT * FROM ry_ref_types ORDER BY ref_type_id;
    };
    my $html = q{<select name="ref_type">};

    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute() or die $DBH->errstr();

    while (my $row_href = $stmt->fetchrow_hashref()) {
        my %ROW = %{$row_href};
        $html = $html . qq{<option value="$ROW{'ref_type_id'}">$ROW{'ref_type_name'}</option>};
    }

    $html = $html . q{</select>};
    return $html;
}

sub display_add_reference {
    my $html_refs = html_ref_types();

    print qq{
        <div id="addbiblio">
            <h2> Add Reference </h2>
            <form action="biblio.pl?sid=$FORM{'sid'}" method="post">
            <table>

            <tr>
            <td> Nick Name </td>
            <td> <input type="text" name="ref_nick" value="" maxlength="10"/> </td>
            </tr>

            <tr>
            <td> Reference Type </td>
            <td> $html_refs  </td>
            </tr>

            <tr>
            <td> Author(s) </td>
            <td> <input type="text" name="ref_author" value="" size="50" maxlength="128" /></td>
            </tr>

            <tr>
            <td> Name of Series </td>
            <td> <input type="text" name="ref_series" value="" size="50" maxlength="128" /></td>
            </tr>

            <tr>
            <td> Title </td>
            <td> <input type="text" name="ref_title" value="" size="50" maxlength="128" /></td>
            </tr>

            <tr>
            <td> ISBN 10 </td>
            <td> <input type="text" name="ref_isbn10" value="" maxlength="10" /></td>
            </tr>

            <tr>
            <td> ISBN 13 </td>
            <td> <input type="text" name="ref_isbn13" value="" maxlength="13" /></td>
            </tr>

            <tr>
            <td> Year of Publication </td>
            <td> <input type="text" name="ref_year" value="" maxlength="4" /></td>
            </tr>

            <tr>
            <td> Publisher </td>
            <td> <input type="text" name="ref_publisher" value="" size="60" maxlength="128" /></td>
            </tr>

            <tr>
            <td> Keywords </td>
            <td> <input type="text" name="ref_keywords" value="" size="70" maxlength="128" /></td>
            </tr>

            <tr>
            <td> URL </td>
            <td> <input type="text" name="ref_url" value="" /></td>
            </tr>

            <tr>
            <td> Accessed </td>
            <td> <input type="date" name="ref_accessed"/></td>
            </tr>

            </table>

            <input type="hidden" name="sid" value="$SESSION{'sid'}" />
            <input type="submit" name="ref_add" value="Add" />
            </form>
            </div>
    };

}

sub PROCESS {
    if ($FORM{'ref_add'} && ($FORM{'ref_add'} eq "Add")) {
	$ref_id = insert_biblio($DBH, \%FORM);
    }

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

sub local_css()
{
    print qq{
<style>

#addbiblio {
    text-align: left;
    border: 1px solid #99b9ff;
    background-color: #e6eeff;
    width: 90%;
    margin-top: 20px;
    margin-left: auto;
    margin-right: auto;
    margin-bottom: 20px;
    padding-left: 10px;
    padding-right: 10px;
    padding-bottom: 10px;
    padding-top: 10px;
}

#biblio {
    text-align: left;
    border: 1px solid #99b9ff;
    background-color: #e6eeff;
    width: 90%;
    margin-left: auto;
    margin-right: auto;
    margin-bottom: 20px;
    padding-left: 10px;
    padding-right: 10px;
    padding-bottom: 10px;
    padding-top: 10px;
}

#rows:nth-child(even) {
    background-color: #ccdcff;
}

body {
    background-color: #bcd4e6;
    padding-bottom: 10px;
    padding-top: 10px;
}

.top-menu {
    border: 1px solid #4f86f7;
    width: 90%;
    margin-top: 10px;
    margin-left: auto;
    margin-right: auto;
    padding-left: 10px;
    padding-right: 10px;
    padding-bottom: 10px;
    padding-top: 10px;
}

</style>
};
}

sub MAIN {
    CTOR();
    COLLECT();
    PROCESS();
    content_type();

    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};
    
    print "<!doctype html>";
    print "<html>";
    print "<head>";
    print "<title> Wobble: Manage References </title>";
    link_css();
    local_css();
    print "</head>";

    print "<body>";

    top_menu($DBH, $SESSION{'userid'}, $FORM{'sid'});

    # print_hash($form_href);

    display_add_reference();

    display_references();

    print "</body>";

    DTOR();
}

MAIN();
