#!/usr/bin/perl

use strict;
use warnings;

require './profile.pl';
require './utility.pl';
require './model.pl';

my %SESSION;
my %FORM;
my $DBH;
my $ref_id = 0;

sub display_add_reference {
    print qq{
    <div>
	<h2> Add Reference </h2>
	<form action="biblio.pl?sid=$FORM{'sid'}" method="post">
	<table>

	<tr>
	<td> Nick Name </td>
	<td> <input type="text" name="ref_nick" value="" maxlength="10"/> </td>
	</tr>

	<tr>
	<td> Reference Type </td>
	<td> <select name="ref_type"> 
	<option value="1">Book</option>
	<option value="2">Online</option>
	<option value="3">Others</option>
	</select>
	</td>
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
	<td> <input type="url" name="ref_url" value="" /></td>
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
    print "<title> Manage References </title>";
    link_css();
    print "</head>";

    print "<body>";

    top_menu($FORM{'sid'});

    # print_hash($form_href);

    display_add_reference();

    print "</body>";

    DTOR();
}

MAIN();
