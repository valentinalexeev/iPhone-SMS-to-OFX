#!/usr/bin/awk
#
# A sample transformation script to turn iPhone's SMS message database
# into an OFX file. This one is specific to Russian's Sberbank.
#
# Author: Valentin Alexeev <valentin.alekseev(at)gmail.com>
# Distrubuted under Apache License v.2

# Following is the list of bank-specific message parsing.

# Bank charge (SMS banking fee)
# Sample line (followed by awk indexes used):
# 695;900;1262033183;VISAQQQQQ; Oplata uslug mobilnogo banka za period s DD/MM/YYYY po DD/MM/YYYY; Uspeshno; Summa:XX.XXCUR; DD.MM.YY HH:MMTZ; Dostupno:YYYYY.YYCUR;;2;0;;4;0;0;0;0;;ru;;;1
#  1   2   3          4          5                                                                  6         7               8               9
$5 ~ / Oplata uslug mobilnogo/ {
    transaction("SRVCHRG", $8, "-", $7, "Sberbank", $5 ", " $6, $3);
    storeBalance($8, $9);
}

# 1126;900;1285860309;VISA71830; Oplata uslug; Uspeshno; Summa:1000.00RUR; MEGAFON (NWGSM); 30.09.10 19:24; Dostupno:20484.39RUR;;2;0;;4;0;0;4;0;;ru;;;1
# 1    2   3          4         5             6         7                 8                9               10
$5 ~ / Oplata uslug/ && $5 !~ /mobilnogo/ {
    transaction("POS", $9, "-", $7, $8, $3);
    storeBalance($9, $10);
}

# Purchase
# Sample line (followed by awk indexes used):
# 712;900;1263051677;VISAQQQQQ; Pokupka; Uspeshno; Summa:XXXX.XXCUR; AAAAAAAAAAAAAAA; DD.MM.YY HH:MM; Dostupno:YYYYY.YYCUR;;2;0;;4;0;0;0;0;;ru;;;1
#  1   2   3          4          5        6         7                 8                9              10
$5 ~ / Pokupka/ {
    transaction("POS", $9, "-", $7, $8, "", $3);
    storeBalance($9, $10);
}

# ATM
# Sample line (followed by awk indexes used):
# 680;900;1260781386;VISAQQQQQ; Vydacha nalichnyh; Uspeshno; Summa:XXXX.XXCUR; AAAAAAAAAAA; DD.MM.YY HH:MM; Dostupno:YYYYY.YYCUR;;2;0;;4;0;0;0;0;;ru;;;1
#  1   2   3          4          5                  6         7                 8            9              10
$5 ~ / Vydacha/ && $6 ~ /Uspeshno/ {
    transaction("ATM", $9, "-", $7, $8, "", $3);
    storeBalance($9, $10);
}

# Account credit
# Sample line (followed by awk indexes used):
# 673;900;1259952265;VISAQQQQQ; Popolnenie scheta; Uspeshno; Summa:XXXXX.XXCUR; DD.MM.YY HH:MM; Dostupno:YYYYY.YYCUR;;2;0;;4;0;0;0;0;;ru;;;1
#  1   2   3          4          5                  6         7                  8              9
$5 ~ / Popolnenie/ {
    transaction("Deposit", $8, "", $7, "Salary", "", $3);
    storeBalance($8, $9);
}

# Output XML and OFX headers.
BEGIN {
    FS=";";
    balance["date"] = 0;
    balance["amt"] = 0;
    print "<?xml version='1.0'?>";
    print "<OFX><BANKMSGSRSV1><STMTRS><BANKTRANLIST>";
}

# Output OFX finishing tags.
END {
    print "</BANKTRANLIST>";
    # print balance result
    print "<AVAILBAL><BALAMT>" balance["amt"] "</BALAMT><DTASOF>" balance["date"] "</DTASOF></AVAILBAL>";
    print "</STMTRS></BANKMSGSRSV1></OFX>";
}

# Print out transaction tag for a line in a database.
# @param type a type to use in transaction (any text)
# @param date transaction date (format: "DD.MM.YY")
# @param sig transaction amount sign ("-" for debet, "" for credit)
# @param amt amount on transaction
# @param memo a textual memo
# @param trid transaction ID
function transaction(type, date, sig, amt, name, memo, trid) {
    print "<STMTTRN>";
    print "<TRNTYPE>" type "</TRNTYPE>";
    split(date, dtposted, "[. :]");
    print "<DTPOSTED>20" dtposted[4] "" dtposted[3] "" dtposted[2] "</DTPOSTED>";
    
    split(amt, amtA, ":");
    print "<TRNAMT>" sig "" substr(amtA[2], 0, length(amtA[2]) - 3) "</TRNAMT>";
    print "<CURRENCY>" substr(amtA[2], length(amtA[2]) - 2, 3) "</CURRENCY>";
    
    sub("^ *", "", name);
    sub("^ *", "", memo);
    print "<NAME>" name "</NAME>";
    print "<MEMO>" memo "</MEMO>";
    print "<FITID>" trid "</FITID>";
    print "</STMTTRN>";
}

# Store account balance for later
# @param date date for the balance to store
# @param amt balance string
function storeBalance (date, amt) {
    if (balance["date"] == 0) {
        split(date, dtposted, "[. :]");
        balance["date"] = "20" dtposted[4] "" dtposted[3] "" dtposted[2];
    
        split(amt, amtA, ":");
        balance["amt"] = substr(amtA[2], 0, length(amtA[2]) - 3);
    }
}
