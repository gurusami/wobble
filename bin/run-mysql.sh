#!/bin/bash
# Created: Thu 17 Sep 2020 11:51:19 AM IST
# Last-Modified: Mon 21 Sep 2020 01:10:27 PM IST
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>
#

BD="/home/annamalai/i/mysql-8.0.21"
DD=/home/annamalai/i/my_data
LF=$DD/mysql.log
cnf="/home/annamalai/wobble.git/conf/my.cnf"

$BD/bin/mysqld --defaults-file="$cnf" --basedir=$BD --log-error=$LF --user=`whoami` --console --max_allowed_packet=500M --lc-messages-dir=./sql/share
