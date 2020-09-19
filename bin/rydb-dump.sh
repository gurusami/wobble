#!/bin/bash
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

# Initialize the necessary path variables.  
PROJ_DIR="/home/annamalai/wobble.git"
BD="/home/annamalai/i/mysql-8.0.21"
DD="/home/annamalai/i/my_data"
SF=$DD/mysql.sock

outfile="rydb-schema.sql"
outdir="${PROJ_DIR}/schema/"
of="$outdir/$outfile"

$BD/bin/mysqldump --no-data --socket=$SF --user=root --password='W3lcome=' --databases rydb > $of
$BD/bin/mysqldump --socket=$SF --user=root --password='W3lcome=' --databases rydb > ${PROJ_DIR}/rydb/rydb-dump.sql
