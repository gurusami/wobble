#!/usr/bin/perl
# Created: Mon 14 Sep 2020 01:20:01 PM IST
# Last Modified: Thu 24 Sep 2020 10:09:51 PM IST
# Time-stamp: <2020-09-09 13:41:07 annamalai>
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
        $FORM{'img_id'} = insert_image($DBH, $FORM{'img_type'}, $FORM{'filedata'});
    }
}

sub DISPLAY {
    print "<html>";
    print "<head>";
    print "<title> Wobble: Upload an image </title>";
    link_css();
    print "</head>" . "\n";
    print "<body>";
    top_menu($DBH, $SESSION{'userid'}, $SESSION{'sid'});

    my $qs = qq[image-upload.pl?sid=$SESSION{'sid'}];

print qq{
<form action="$qs" method="post" enctype="multipart/form-data">
  <input type="hidden" name="sid" value="$SESSION{'sid'}" />
  <input type="hidden" name="MAX_FILE_SIZE" value="1048576" />
  <input type="file" name="filedata" />
  <select name="img_type">
    <option value="png">png</option>
    <option value="jpg">jpg</option>
  </select>
  <input type="submit" name="image_upload" value="Upload Image" />
</form>
};

    if (defined $FORM{'img_id'}) {
        print qq{
<p> Successfully inserted image: $FORM{'img_id'} </p>
};

        embed_image($DBH, $FORM{'img_id'});
    }

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
