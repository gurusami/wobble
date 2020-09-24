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
        } elsif (defined $FORM{'update_test'}) {
            my $tst_id = $FORM{'tst_id'};
            my $tst_title = $FORM{'tst_title'};
            my $tst_type = $FORM{'tst_type'};

            update_test($DBH, $tst_id, $tst_type, $tst_title);
        }
    }
}

sub html_select_tst_type {
    my $option = shift;
    my $html = q{<select name="tst_type">};

    my $query = "SELECT tst_type_id, tst_type_name FROM ry_test_types";
    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    while (my ($tst_type_id, $tst_type_name) = $stmt->fetchrow()) {
        my $sel = "";

        if ($option == $tst_type_id) {
            $sel = "selected";
        }

        $html = $html . qq{<option value="$tst_type_id" $sel> $tst_type_name </option>};
    }
    $html = $html . q{</select>};

    $stmt->finish();

    return $html;
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
    my $query = q{
        SELECT tst_id, a.tst_type, b.tst_type_nick AS tst_nick, u.userid as tst_owner_id, u.username AS tst_owner_name, tst_created_on, tst_qst_count, tst_title
            FROM ry_tests a, ry_test_types b, ry_users u
            WHERE a.tst_type = b.tst_type_id
            AND   u.userid = tst_owner
            ORDER BY tst_id DESC
    };

    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    print q{<hr>
        <h2 align="center"> List of Available Tests </h2>
        <div class="regular">
            <table align="center">
            <tr>
            <th> Test ID </th>
            <th> Test Type </th>
            <th> Title </th>
            <th> Number of Questions </th>
            <th> Owner </th>
            <th> Created On </th>
            <th> Prepare </th>
            <th> Modify </th>
            </tr>
    };

    while (my ($tst_id, $tst_type_id, $tst_type_nick, $tst_owner, $tst_owner_name, $tst_created_on, $tst_qst_count, $tst_title) = $stmt->fetchrow()) {

        print qq{<tr>};

        print qq{<td align="center"> $tst_id </td> <td> $tst_type_nick </td> <td> $tst_title </td> <td align="center"> $tst_qst_count </td>
                <td> $tst_owner_name </td> <td> $tst_created_on </td> <td>
        };

        if ($tst_owner eq $SESSION{'userid'}) {
            print qq{
                <form action="maketest.pl?sid=$SESSION{'sid'}" method="post">
                    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
                    <input type="hidden" name="tst_id" value="$tst_id" />
                    <input type="submit" name="make_test" value="Prepare" />
                    </form>
            };
        }

        print q{</td> <td>};

        if ($tst_owner eq $SESSION{'userid'}) {
            print qq{
                <form action="create-test.pl?sid=$SESSION{'sid'}" method="post">
                    <input type="hidden" name="sid" value="$SESSION{'sid'}" />
                    <input type="hidden" name="tst_id" value="$tst_id" />
                    <input type="hidden" name="tst_type" value="$tst_type_id" />
                    <input type="hidden" name="tst_title" value="$tst_title" />
                    <input type="submit" name="modify_test" value="Modify" />
                    </form>
            };
        }

        print q{
            </td> </tr>
        };

    }

    print q{
        </table>
            </div>
    };

    $stmt->finish();

} # sub show_existing_tests

sub local_css {
    print q{
<style>
tr:nth-child(even) {
    background-color: lightblue;
}

.regular {
    text-align: center;
    margin-left: auto;
    margin-right: auto;
}

.grid-container-2 {
    display: grid;
    grid-template-columns: auto auto;
}
</style>

};
}

sub show_create_test_form {
    my $sid = $SESSION{'sid'};

    print qq{
        <div>
        <h3> Create a Test </h3>
    };
    print qq{<form action="create-test.pl?sid=$sid" method="post">};

    print qq{
        <table>
            <tr> <td> Test Title </td> <td> <input type="text" name="tst_title" value="" /> </td> </tr>
            <tr> <td> Test Type </td> <td>};

    select_tst_type();

    print qq{</td> </tr>
            </table>
            <input type="hidden" name="sid" value="$FORM{'sid'}" />
            <input type="submit" name="create_test" value="Create Test" />
            </form>
        </div>
    };
}

sub show_update_test_form {
    my $sid = $SESSION{'sid'};
    my $tst_id = $FORM{'tst_id'};
    my $tst_type = $FORM{'tst_type'};
    my $html_tst_type = html_select_tst_type($tst_type);

    print qq{
        <div>
        <h3> Update a Test </h3>
    };
    print qq{<form action="create-test.pl?sid=$sid" method="post">};

    print qq{
        <table>
            <tr> <td> Test ID </td> <td> $tst_id </td> </tr>
            <tr> <td> Test Type </td> <td> $html_tst_type </td> </tr>
            <tr> <td> Test Title </td>
            <td> <input type="text" name="tst_title" size="80" value="$FORM{'tst_title'}" /> </td> </tr>
            </table>

            <input type="hidden" name="sid" value="$sid" />
            <input type="hidden" name="tst_id" value="$tst_id" />
            <input type="submit" name="update_test" value="Update Test" />
            </form>
        </div>
    };
}

sub create_or_update_test {
    print qq{<div class="grid-container-2">};

    show_create_test_form();

    if (defined $FORM{'tst_id'}) {
        show_update_test_form();
    }

    print qq{</div> <!-- grid-container-2 -->};
    nl();
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Create a New Test </title>";
    link_css();
    local_css();
    print "</head>" . "\n";

    print "<body>";

    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    create_or_update_test();

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
