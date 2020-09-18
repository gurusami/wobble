#!/usr/bin/perl
# Time-stamp: <2020-09-08 13:56:53 annamalai>
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
#

use strict;
use warnings;
use DBI;
use Getopt::Long;

require '../public_html/cgi-bin/model.pl';

my $dbname = "rydb";
my $dbuser = "root";
my $dbpasswd = "W3lcome=";

# Output filename prefix
my $prefix   = "practice";
my $ofh;
my $bib_file = "ntse.bib";
my $DBH;

# The Test Identifier
my $tst_id = 0;
my $tst_version;
my $tst_title;
my $title_in_doc;

# List of questions in the given test.
my @qids;
my $with_answer = '';
my @answer_seq;

# Data Source Name (DSN)
my $dsn = "DBI:mysql:database=" . $dbname . ";host=localhost;mysql_socket=/home/annamalai/i/my_data/mysql.sock;port=8888";

sub newline {
    print $ofh "\n";
}

sub create_biblio_file {
    my $bib_fh;
    
    open($bib_fh, ">", $bib_file) or die "Could not open file: $bib_file";
    $bib_fh->autoflush(1);

    my $query = "SELECT * from ry_biblio ORDER BY ref_id";
    my $stmt = $DBH->prepare($query);
    $stmt->execute();

    while (my $row_href = $stmt->fetchrow_hashref()) {
	my %ROW = %{$row_href};

	if ($ROW{'ref_type'} == 1) {
	    # It is a book.
	    biblio_one_book_entry($bib_fh, $row_href);
	    print $bib_fh "\n";
	}
    }
    
    close($bib_fh);
}

sub cite_for_qid {
    my $qid = shift;

    my $query = "SELECT bib.ref_nick FROM ry_biblio bib, ry_qid_ref ref WHERE ref.qid = ? AND ref.ref_id = bib.ref_id ORDER BY bib.ref_id";

    my $stmt = $DBH->prepare($query);
    $stmt->execute($qid);

    while (my $row_href = $stmt->fetchrow_hashref()) {
	my %ROW = %{$row_href};
	print $ofh qq[\\cite{$ROW{'ref_nick'}}];

	newline();
    }
}

sub biblio_one_book_entry {
    my $bib_fh = shift;
    my $row_href = shift;
    my %ROW = %{$row_href};

    print $bib_fh q[@book{];
    print $bib_fh qq[$ROW{'ref_nick'}, title = { $ROW{'ref_title'} }, author = {$ROW{'ref_author'}}, isbn = {$ROW{'ref_isbn13'}}, series = {$ROW{'ref_series'}}, year = {$ROW{'ref_year'}}, publisher = {$ROW{ref_publisher}}, keywords = {$ROW{'ref_keywords'}}}];
}

sub print_question {
    my $qrow_href = shift;
    my %QROW = %{$qrow_href};

    my $qid = $QROW{'qid'};
    my $qparent = $QROW{'qparent'};
    my $qtype = $QROW{'qtype'};

    if ($qtype == 0) {
	print_question_0($qrow_href);
    } elsif ($qtype == 1) {
	print_question_1($qrow_href);
    } elsif ($qtype == 2) {
	print_question_2($qrow_href);
    } else {
	die "Unknown Question Type";
    }

    cite_for_qid($qid);
};

sub print_question_0 {
    my $qrow_href = shift;
    my %QROW = %{$qrow_href};
    my $qid = $QROW{'qid'};

    print $ofh qq{\\item $QROW{'qlatex'}};
    print $ofh qq{[QID:$qid]};

    if ($with_answer) {
	my $query = "SELECT qid, qans FROM answer_1 WHERE qid = ?";
	my $stmt = $DBH->prepare($query) or die $DBH->errstr();
	$stmt->execute($qid);
	my ($qid, $qans) = $stmt->fetchrow();
	print $ofh q[\colorbox{yellow}{];
        print $ofh q[\emph{Answer:}] . $qans . "}\n";

	push @answer_seq, $qans;
    }
}

sub print_answer_seq {
    print $ofh qq[{\\begin{itemize}];
    newline();
    print $ofh "\\item Total Questions: " . scalar(@answer_seq);
    newline();
    print $ofh "\\item Answer sequence: ";
    foreach my $chid (@answer_seq) {
	print $ofh "$chid" . ", ";
    }
    newline();
    print $ofh q[\end{itemize}];
    newline();
}

sub print_question_1 {
    my $qrow_href = shift;
    my %QROW = %{$qrow_href};
    my $qid = $QROW{'qid'};
    
    print $ofh qq{\\item $QROW{'qlatex'} };
    print $ofh qq{[QID:$qid]};

    newline();
    
    my $query = "SELECT qid, chid, choice_latex, correct FROM answer_2 WHERE qid = ?";

    my $stmt = $DBH->prepare($query);
    $stmt->execute($qid);

    print $ofh qq{\\begin{enumerate}};

    newline();
    
    while (my ($qid, $chid, $choice_latex, $correct) = $stmt->fetchrow()) {
	print $ofh qq{\\item };
	if ($with_answer && $correct == 1) {
	    push @answer_seq, $chid;
	    print $ofh qq[\\colorbox{yellow}{];
	}
	print $ofh qq{$choice_latex};
	if ($with_answer && $correct == 1) {
	    print $ofh qq[}];
	}

	newline();
    }

    print $ofh qq{\\end{enumerate}};

    newline();
};

sub print_question_2 {
    my $row_href = shift;
    my %QROW = %{$row_href};
    my $qid = $QROW{'qid'};

    print $ofh qq{\\item $QROW{'qlatex'}};
    print $ofh qq{[QID:$qid]};

    newline();

    my $query = "SELECT qid, qparent, qlatex, qtype FROM question WHERE qparent = ?";
    my $stmt = $DBH->prepare($query);
    $stmt->execute($qid);

    print $ofh q{\begin{enumerate}};

    newline();
    
    while (my $qrow_href = $stmt->fetchrow_hashref()) {
	print_question($qrow_href);
    }
    print $ofh qq{\\end{enumerate}};

    newline();
}


sub print_preamble{
    my $preamble = q{\documentclass[10pt,twocolumn,a4paper]{article}
\usepackage{cite}
\usepackage{multicol}
\usepackage{tikz}
\usepackage{url}
\usepackage{xcolor}
};

    print $ofh $preamble;
    print $ofh q[\title {] . $title_in_doc . q[}] . "\n"
	. q[\begin{document}] . "\n"
	. q[\maketitle] . "\n";
}

sub get_test_info() {
    my $query = "SELECT tst_version, tst_title FROM ry_tests WHERE tst_id = ?";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($tst_id) or die $DBH->errstr();

    if (($tst_version, $tst_title) = $stmt->fetchrow()) {
    } else {
	die "Given (Test-ID: $tst_id) not found."
    }

    $title_in_doc = qq{$tst_title [Test-ID: $tst_id.$tst_version]};
}

sub print_all_questions {
    my $query = "SELECT qid, qparent, qlatex, qtype FROM question WHERE qid = ?";
    my $stmt = $DBH->prepare($query) or die "prepare statement failed: $DBH->errstr()";

    print $ofh q{\begin{enumerate}};

    newline();
    
    # prepare SQL statement
    foreach my $qid (@qids)
    {
	$stmt->execute($qid) or die "execution failed: $DBH->errstr()"; 
	my $qrow_href = $stmt->fetchrow_hashref();
	print_question($qrow_href);
    }

    $stmt->finish();
}

# Get output file name
sub get_output_fname {
    my $file_name = $prefix . "-$tst_id" . "-$tst_version";

    if ($with_answer) {
	$file_name = $file_name . "-solved";
    }

    $file_name = $file_name . ".tex";
    return $file_name
}

# MAIN
sub the_main() {
    my $result = GetOptions('with-answer' => \$with_answer,
			    'prefix=s' => \$prefix,
			    'test-id=i' => \$tst_id);

    if ($tst_id == 0) {
	die "No test identifier specified";
	exit(0);
    }
    
    $DBH = DBI->connect($dsn,$dbuser,$dbpasswd);
    die "failed to connect to MySQL database:DBI->errstr()" unless($DBH);

    print "Successfully connected to $dsn\n";

    # The output filename contains the test id and the test version
    # number.  So obtain this information before opening the output
    # file.
    get_test_info();
    
    # Generate the
    my $output_filename = get_output_fname();
    
    open($ofh, ">", $output_filename) or die "Could not open file: $output_filename";

    $ofh->autoflush(1);


    my $qid_aref = get_qid_in_tst($DBH, $tst_id, $tst_version);
    @qids = @{$qid_aref};

    print_preamble();

    print_all_questions();
    newline();

    print $ofh q[\end{enumerate}];

    if ($with_answer) {
	print_answer_seq();
    }

    newline();

    print $ofh q[\bibliography{ntse}{}];
    print $ofh q[\bibliographystyle{apalike}];

    print $ofh q[\end{document}];

    close($ofh);

    create_biblio_file();
    $DBH->disconnect();
}

the_main();

1;


