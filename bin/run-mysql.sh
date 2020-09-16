#!/bin/bash
# Date Generated: Thu Aug 27 12:31:48 IST 2020

# This file is generated by the shell func grun(). Use the command
# "type grun" to view the src.  Use the command "mysqld --help
# --verbose" for the full list of options supported by MySQL server.
# Feel free to edit this file for your convenience.

set -vx
BD="/home/annamalai/i/mysql-8.0.21"
DD=/home/annamalai/i/my_data
LF=$DD/mysql.log
SF=$DD/mysql.sock
cnf="/home/annamalai/wobble.git/conf/my.cnf"

$BD/bin/mysqld --defaults-file="$cnf" --basedir=$BD --datadir=$DD --log-error=$LF --socket=$SF --user=`whoami` --console --max_allowed_packet=500M --lc-messages-dir=./sql/share
