#!/usr/bin/perl
# Created: Wed 16 Sep 2020 11:26:33 AM IST
# Last-Modified: Wed 16 Sep 2020 12:33:06 PM IST
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
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

        if (defined $FORM{'addimage'}) {
            my $max_seq = qst_max_img_seq($DBH, $FORM{'qid'});
            $FORM{'seq'} = 1 + $max_seq;
            add_img_to_qst($DBH, $FORM{'qid'}, $FORM{'img_id'}, $FORM{'seq'});
        }
    }

    if (! defined $FORM{'low_img_id'} ) {
        $FORM{'low_img_id'} = 0;
    }
}

sub browse_images {
    my $low_img_id = $FORM{'low_img_id'};

    my $query = "SELECT img_id, to_base64(img_image), img_type FROM ry_images WHERE img_id > ? LIMIT 20";
    my $stmt = $DBH->prepare($query) or die $DBH->errstr();
    $stmt->execute($low_img_id) or die $DBH->errstr();

    while (my ($img_id, $image, $image_type) = $stmt->fetchrow()) {
print qq^
<div class="show_image">
<img src="data:image/$image_type;base64,
$image
"/>
<form action="image-addq.pl?sid=$SESSION{'sid'}" method="post">
    <input type="hidden" name="qid" value="$FORM{'qid'}" />
    <input type="hidden" name="img_id" value="$img_id" />
    <input type="hidden" name="low_img_id" value="$low_img_id" />
    <input type="submit" name="addimage" value="Add This Image" />
</form>
</div>
^;
    }
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Add Images to Question </title>";

    link_css();

    print "</head>" . "\n";
    print "<body>";
    top_menu($SESSION{'sid'});

    defined $FORM{'qid'} || die "<p> No QID given </p>";
    defined $FORM{'sid'} || die "<p> No Session ID given </p>";
    
    browse_images();

    print "</body>";
    print "</html>";

}

sub MAIN {
    CTOR();
    COLLECT();
    content_type();
    
    my $s_ref = CHECK_SESSION($DBH, $FORM{'sid'});
    %SESSION = %{$s_ref};

    CHECK_AUTH($DBH, $SESSION{'sid'}, $ENV{'SCRIPT_NAME'}, $SESSION{'userid'});
    PROCESS();
    DISPLAY();
    
    DTOR();
    exit(0);
}

MAIN();
