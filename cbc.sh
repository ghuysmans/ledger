#!/bin/sh
if [ ! -f "$1" -o -z "$2" -o -z "$3" ]; then
	echo usage: $0 book.dat Assets:Bank input.csv >&2
	exit 1
fi

CLEAN="$3.clean"

if [ ! -f "$CLEAN" ]; then
	./anon.sh <"$3" |
	#replace the header
	(echo ";;;;code;;desc;date;amount;"; tail -n +2) |
	#separators
	sed s/,/./g | #decimal separator
	sed "s/; \\+/,/g" | #remove prefix whitespaces
	sed "s/;/,/g" | #avoid crashing Ledger
	#cleanup
	sed "s/ PAR LES SERVICES INTERNET//" | #garbage
	sed "s/,PAIEMENT ACHAT.* HEURES. \\?/,/" | #type + date
	sed "s/ AVEC CARTE BANCAIRE[^,]*//" | #I only have one card
	sed "s/,VIREMENT EUROPEEN .*: [A-Z]\\+ /,/" | #ignore the account number
	sed "s/,DOMICILIATION EUROPEENNE [^:]*: /,/" | #too specific
	#FIXME too aggressive?
	sed "s/ REF. CREANCIER [^,]*//" | #just keep the company, not the detail
	tee "$CLEAN" >/dev/null
fi

ledger convert -f "$1" --account "$2" \
	--input-date-format "%d/%m/%Y" --rich-data "$CLEAN"
