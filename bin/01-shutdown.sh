#!/bin/bash
# Created: Mon 21 Sep 2020 01:07:20 PM IST
# Last-Updated: Mon 21 Sep 2020 01:07:20 PM IST
set -vx

BD="/home/annamalai/i/mysql-8.0.21"
DD=/home/annamalai/i/my_data
LF=$DD/mysql.log
SF="/home/annamalai/i/my_data/mysql.sock";

/home/annamalai/i/mysql-8.0.21/bin/mysqladmin --socket=$SF --user=root --password='W3lcome=' shutdown
