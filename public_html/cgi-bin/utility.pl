#!/usr/bin/perl
# Created: Mon 14 Sep 2020 10:39:48 PM IST
# Last Modified: Mon 14 Sep 2020 11:58:48 PM IST
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

    print q{<table border="1">};
    foreach my $key (keys %FORM) {
	print "<tr>";
	print "<td>[" . $key . "]</td>";
	print "<td>[" . $FORM{$key} . "]</td>";
	print "</tr>";
    }
    print "</table>";
}

sub read_post_multipart {
    my $buffer = shift;
    my %form;
    my $boundary;

    # This can be used for debugging.
    $form{'data'} = $buffer;
    
    $ENV{'CONTENT_TYPE'} =~ /boundary=(.*$)/ or die "No boundary found";
    $boundary = $1;

    # For the boundary parameter specification refer to
    # https://tools.ietf.org/html/rfc7578
    my @data_array = split(/\r\n--$boundary/, $buffer);

    foreach my $data (@data_array) {
        my ($header_part, $body_part) = split(/\r\n\r\n/, $data);
        my @headers = split(/\r\n/, $header_part);
        foreach my $header (@headers) {
            my ($header_name, $header_value) = split(/: /, $header);
            if ($header_name eq "Content-Disposition") {
                my @sub_header_parts = split(/; /, $header_value);

                # Remove the form-data from the array.
                shift @sub_header_parts; 

                foreach my $sub_header (@sub_header_parts) {
                    my ($key, $value) = split(/=/, $sub_header);
                    $value =~ /"(.*)"/;
                    if ($key eq "name") {
                        $form{$1} = $body_part;
                    } else {
                        $form{$key} = $1;
                    }
                }
            }
        }
    }

    return %form;
}

sub read_post_data {
    my $buffer;
    my @pairs;
    my %form;

    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

    if ($ENV{'CONTENT_TYPE'} =~ "multipart/form-data") {
        return read_post_multipart($buffer);
    }

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
    my $sid = shift;
    my $url = login_url();

    print qq{
    <!DOCTYPE html>
	<html>
	<head>
	<title> Invalid Session </title>
	</head>
	<body>
	<p>Invalid Session (sid=$sid) (Maybe it is expired).  Login <a href="$url">again</a>.</p>
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
         goto_login($sid);
    }

    my %row = %{$row_href};
    $session{'sid'} = $sid;
    $session{'userid'} = $row{'userid'};
    # $session{'userid'} = 1;

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
