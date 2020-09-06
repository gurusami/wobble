#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI;

require "./profile.pl";

our $dsn;
my $cgi = CGI->new;

print $cgi->header('text/html');

print "<html>";
print "<head>";
print "<title>Add a Question</title>";
print "</head>";

print "<body>";
print "<h1>Add one question</h1>";

print "<form action=\"qadd.pl\" method=\"POST\">\n";
print "<textarea name=\"question\" cols=\"80\" rows=\"25\" />";
print $cgi->param('question');
print "</textarea>\n";
print "<input type=\"submit\" value=\"Add Question\" />\n";
print "</form>\n";

if ( my $quest = $cgi->param('question') ) {
    my $dbh = DBI->connect($dsn,'','');
    die "failed to connect to MySQL database:DBI->errstr()" unless($dbh);
    
    my $stmt = $dbh->prepare("insert into question (qlatex, qtype) values (?, 0)") or die "prepare statement failed: $dbh->errstr()";

    my @data = (trim($quest));

    $stmt->execute(@data) or die "execution failed: $dbh->errstr()";
    $stmt->finish();
    $dbh->disconnect();

    print "<p> Successfully added question </p>";
}

print "</body>";
print "</html>";
