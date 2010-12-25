#!/bin/sh
#
# One-liner to find SMS database, extract relevant messages and pipe it to AWK script.
#
# Author: Valentin Alexeev <valentin.alekseev(at)gmail.com>
# Distrubuted under Apache License v.2

# Dissecting the one-liner:
# find ~/Library/Application\ Support/MobileSync/Backup -name \*mddata -exec file \{\} \; 
#          -- Find all mddata files and pipe through "file" to get its' types
# | grep -i sqlite
#          -- Select only SQLite files
# | sed -e 's/:.*/"/' -e 's/^/"/'
#          -- Extract filenames and quote them
# | xargs grep -l msg_group
#          -- Look through these files for a magic string "msg_group" (the table name in SMS database)
# | sed -e 's/^/"/' -e 's/$/"/'
#          -- Get the matching file name from grep's output
# | xargs -I% sqlite3 % 'SELECT * FROM message WHERE address="$BANKPHONE" ORDER BY rowid DESC LIMIT 20;'
#          -- Execute an SQL query to fetch the messages from specific phone number on matched file
# | sed -e 's/|/;/g'
#          -- Convert SQLite column separators ('|') to semicolons
# | awk -f sberbank.awk
#          -- Pipe to awk to generate OFX

# Phone number the bank sends notifications from
BANKPHONE=900

find ~/Library/Application\ Support/MobileSync/Backup -exec file \{\} \; | grep -i sqlite | sed -e 's/:.*/"/' -e 's/^/"/' | xargs grep -l msg_group | sed -e 's/^/"/' -e 's/$/"/' | xargs -I% sqlite3 % "SELECT * FROM message WHERE address=\"$BANKPHONE\" ORDER BY rowid DESC LIMIT 20;" | sed -e 's/|/;/g' | awk -f sberbank.awk
