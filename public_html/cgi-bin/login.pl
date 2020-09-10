#!/usr/bin/perl
#
# Time-stamp: <2020-09-10 06:12:45 annamalai>
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
#

use strict;
use warnings;
use Data::GUID;

require './profile.pl';
require './utility.pl';
require './model.pl';

my %SESSION;
my %FORM;
my $dbh;

# MySQL function sha2(?, 256) is being used to store password.
# My temp password is 'asterix'.
# Mythili password is 'W0rkNts3'

sub display_login {
    print q{
<form action="login.pl" method="post">
<input type="text" name="username" maxlength="10"/>
<input type="password" name="token" maxlength="30"/>
<input type="submit" name="login" value="Sign In" />
</form>
    };
}

sub login_failed {
    my $url = redirect_url();
    print qq{
    <!DOCTYPE html>
	<html>
	<head>
	<title> Login Failed </title>
	</head>
	<body>
	<p>Login failed.  Please try <a href="$ENV{'REQUEST_URI'}">again</a>.</p>
	</body>
	</html>
    };
    
}

sub login_success {
    # Create a new session when login is successful.
    create_new_session();
    
    my $url = redirect_url();
    print qq{
    <!DOCTYPE html>
	<html>
	<head>
	<meta http-equiv="refresh" content="7; url='$url'" />
	</head>
	<body>
	<p>Login successful. Please follow <a href="$url">this link</a>.</p>
	</body>
	</html>
    };
    
}

# Create new session
sub create_new_session {
    my $guid = Data::GUID->new;
    $SESSION{'sid'} = $guid->as_hex;
    $SESSION{'userid'} = $FORM{'userid'};
    $SESSION{'username'} = $FORM{'username'};

    remove_sessions($dbh, $SESSION{'userid'});
    return insert_session($dbh, $SESSION{'sid'}, $SESSION{'userid'});
}

sub redirect_url {
    my $scheme = $ENV{'REQUEST_SCHEME'};
    my $server = $ENV{'HTTP_HOST'};
    my $uri = $ENV{'REQUEST_URI'};
    my $url = $scheme . "://" . $server . $uri;

    $url =~ s/login.pl/menu.pl/;
    $url = $url . qq[?sid=$SESSION{'sid'}];
    return $url;
}

sub ctor {
    $dbh = db_connect();
}

sub dtor {
    $dbh->disconnect();
}

sub COLLECT {
    my $form_href = collect_data();
    %FORM = %{$form_href};
}

sub PROCESS {
    if (my $v = is_token_ok($dbh, $FORM{'username'}, $FORM{'token'})) {
	$FORM{'userid'} = $v;
    } else {
	# Login details not correct.
    }
}

sub DISPLAY {
    content_type();

    if (!defined $FORM{'username'}) {
	html_begin();
	head_begin();
	head_end();
	body_begin();
	display_login();
	body_end();
	html_end();
    } elsif (defined $FORM{'userid'} && $FORM{'userid'} > 0) {
	# Login Successful.
	login_success();
    } else {
	login_failed();
    }
}

sub MAIN {
    ctor();
    COLLECT();
    PROCESS();
    DISPLAY();
    dtor();
    exit;
}

MAIN();
