#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 06:27:50 annamalai>
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

# Put code here that is usable across all the pages of this
# application.

use strict;
use warnings;
use DBI;
use URI::Encode qw(uri_encode uri_decode);
use File::Basename;

require './model.pl';

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
  print qq{
  <div class="top-menu">
    <ul id="menu">
      <li> [<a href="menu.pl?sid=$sid">Main Menu</a>] </li>
      <li> [<a href="logout.pl?sid=$sid">Logout</a>] </li>
    </ul>
  </div>
  <hr>
};
}

sub login_url {
    my $scheme = $ENV{'REQUEST_SCHEME'};
    my $server = $ENV{'HTTP_HOST'};
    my $script = $ENV{'SCRIPT_NAME'};
    my $url = $scheme . "://" . $server . dirname($script) . "/login.pl";

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

sub AUTH_FAILED {
    my $sid = shift;
    
    print "<html>";
    print "<head>";
    print "<title> Create a New Test </title>";
    print "</head>" . "\n";
    print "<body>";
    top_menu($sid);
    print qq{<p> You are not authorized. </p>};
    print "</body>";
    print "</html>";

    exit(0);
}

sub CHECK_AUTH {
    my $dbh = shift;
    my $sid = shift;
    my $script = shift;
    my $userid = shift;
    
    $script =  basename($script);
    my $is_allowed = check_acl($dbh, $userid, $script);

    if ($is_allowed == 0) {
	AUTH_FAILED($sid);
    }
}

sub link_css {
    my $css_file = $ENV{'CONTEXT_PREFIX'} . "/wobble.css";
    print qq{<link rel="stylesheet" href="$css_file">};
}

1;
