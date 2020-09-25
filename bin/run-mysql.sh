#!/bin/bash
# Created: Thu 17 Sep 2020 11:51:19 AM IST
# Last-Modified: Fri 25 Sep 2020 09:24:31 AM IST
# Author: Annamalai Gurusami <annamalai.gurusami@gmail.com>

set -vx

BD="/home/annamalai/i/mysql-8.0.21"
cnf="/home/annamalai/wobble.git/conf/my.cnf"

$BD/bin/mysqld --defaults-file="$cnf" --basedir=$BD --user=`whoami` --console --lc-messages-dir=./sql/share
