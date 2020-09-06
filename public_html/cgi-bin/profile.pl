#!/usr/bin/perl
#
# Time-stamp: <2020-09-04 18:46:00 annamalai>
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
#
# Question Types:
#
# Type 0: Answer consists of a single integer/number.
# Type 1: Multiple choice question with 1 correct answer.
#

use strict;
use warnings;
use DBI;

my $dbhost = "localhost";
my $dbport = "8888";
my $dbname = "rydb";
my $dbuser = "root";
my $dbpasswd = "W3lcome=";
my $dbsock   = "/home/annamalai/i/my_data/mysql.sock";

# Data Source Name (DSN)
our $dsn = "DBI:mysql:database=" . $dbname . ";host=" . $dbhost . ";mysql_socket=" . $dbsock . ";port=" . $dbport;

sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub tag_p {
    my $arg = shift;

    print "<p>";
    print $arg;
    print "</p>";
}


sub is_true {
    my $v = shift;

    if ($v == 0) {
	return "false";
    }
    
    return "true";
}

# Get a database connection.
sub db_connect {
    my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die $DBI::errstr;
    return $dbh;
}

