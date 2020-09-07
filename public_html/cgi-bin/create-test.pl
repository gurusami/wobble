#!/usr/bin/perl

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
	if (defined $FORM{'create_test'}) {
	    my $tst_title = $FORM{'tst_title'};
	    my $tst_type = $FORM{'tst_type'};

	    $SESSION{'tst_id'} = insert_new_test($DBH, $tst_type, $tst_title, $SESSION{'userid'});
	}
    }
}

sub select_tst_type {
    print q{<select name="tst_type">};

    my $query = "SELECT tst_type_id, tst_type_name FROM ry_test_types";
    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    while (my ($tst_type_id, $tst_type_name) = $stmt->fetchrow()) {
	print qq{<option value="$tst_type_id"> $tst_type_name </option>};
    }
    print q{</select>};

    $stmt->finish();
}

sub show_existing_tests {
    my $query = "SELECT tst_id, tst_type, tst_owner, tst_created_on, tst_version, tst_title FROM ry_tests ORDER BY tst_id DESC";

    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    print q{<hr>};
    
    print q{<table>};
    print q{<tr> <th> Test ID </th> <th> Test Type </th> <th> Title </th> <th> Version </th> <th> Owner </th> <th> Created On </th> </tr>};
    while (my ($tst_id, $tst_type, $tst_owner, $tst_created_on, $tst_version, $tst_title) = $stmt->fetchrow()) {
	print qq{<tr>} . "\n";
	print qq{<td> <a href="maketest.pl?sid=$SESSION{'sid'}&tst_id=$tst_id"> $tst_id</a> </td>} . "\n";
	print qq{<td> $tst_type </td> <td> $tst_title </td> <td> $tst_version </td> <td> $tst_owner </td> <td> $tst_created_on </td> </tr>};
    }
    print q{</table>};

    $stmt->finish();

}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";

    print "<body>";

    top_menu($SESSION{'sid'});

    print q{<form action="create-test.pl" method="post">} . "\n" .
	q{<input type="text" name="tst_title" value="} . $FORM{'tst_title'} . q{" />};

    select_tst_type();

    print qq{<input type="hidden" name="sid" value="$FORM{'sid'}" />};
    print qq{<input type="submit" name="create_test" value="Create Test" />};
    print q{</form>};

    show_existing_tests();
    
    print "</body>";
    print "</html>";
}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
