#!/bin/bash
# Created: Mon 21 Sep 2020 01:07:20 PM IST
# Last-Updated: Mon 21 Sep 2020 01:07:20 PM IST
set -vx

# Initialize the necessary path variables.  
BD="/home/annamalai/i/mysql-8.0.21"
DD="/home/annamalai/i/my_data"
LF=$DD/mysql.log
cnf="/home/annamalai/wobble.git/conf/my.cnf"

$BD/bin/mysql --defaults-file="$cnf" --verbose --user=root --password='W3lcome=' rydb

