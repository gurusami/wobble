#!/usr/bin/perl

# Put code here that is usable across all the pages of this
# application.

use strict;
use warnings;
use DBI;
use URI::Encode qw(uri_encode uri_decode);

sub content_type {
    print qq[Content-type:text/html\n\n];
}

sub html_begin {
    print q[<!doctype html>] . "\n";
    print q[<html>] . "\n";
}

sub html_end {
    print q[</html>] . "\n";
}

sub head_begin {
    print q[<head>] . "\n";
}

sub head_end {
    print q[</head>] . "\n";
}

sub body_begin {
    print q[<body>] . "\n";
}

sub body_end {
    print q[</body>] . "\n";
}

sub collect_data {
    my %form;

    my $m = $ENV{'REQUEST_METHOD'};
    
    if ($m eq "POST") {
	%form = read_post_data();
    } elsif ($m eq "GET") {
	%form = read_get_data();
    }

    return \%form;
}

sub print_hash {
    my $form_href = shift;
    my %FORM = %{$form_href};

    print "<table>";
    foreach my $key (keys %FORM) {
	print "<tr>";
	print "<td>" . $key . "</td>";
	print "<td>" . $FORM{$key} . "</td>";
	print "</tr>";
    }
    print "</table>";
}

sub read_post_data {
    my $buffer;
    my @pairs;
    my %form;
    
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

    @pairs = split(/&/, $buffer); 
    foreach my $pair (@pairs)  
    { 
	my ($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /; 
	$value = uri_decode($value);
	$form{$name} = $value;
    }
    return %form;
}

sub read_get_data {
    my $buffer;
    my @pairs;
    my %form;
    
    $buffer = $ENV{'QUERY_STRING'};

    @pairs = split(/&/, $buffer); 
    foreach my $pair (@pairs)  
    { 
	my ($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value = uri_decode($value);
	$form{$name} = $value;
    }
    return %form;
}

sub top_menu {
    my $sid = shift;
    print qq[<a href="menu.pl?sid=$sid">Main Menu</a>];
    print q[<hr>];
}

sub login_url {
    my $scheme = $ENV{'REQUEST_SCHEME'};
    my $server = $ENV{'HTTP_HOST'};
    my $script = $ENV{'SCRIPT_NAME'};
    my $url = $scheme . "://" . $server . $script;

    $url =~ s/\w+\.pl/login.pl/;
    return $url;
}

sub goto_login {
    my $url = login_url();

    print qq{
    <!DOCTYPE html>
	<html>
	<head>
	<title> Invalid Session </title>
	</head>
	<body>
	<p>Invalid Session (Maybe it is expired).  Login <a href="$url">again</a>.</p>
    };

    # print_hash(\%ENV);

    print q[</body> </html>];

    exit(0);
}

sub CHECK_SESSION {
    my $dbh = shift;
    my $sid = shift;
    
    my $row_href = is_session_valid($dbh, $sid);
    my %session;
    
    if (! defined $row_href) {
	goto_login();
    }
    
    my %row = %{$row_href};
    $session{'sid'} = $sid;
    $session{'userid'} = $row{'userid'};

    return \%session;
}

1;
