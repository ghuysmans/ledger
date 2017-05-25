#!/bin/sh
if [ ! -f "$1" -o -z "$2" -o -z "$3" ]; then
	echo "usage: $0 book.dat Assets:Bank input.csv [prefilter.sh]" >&2
	exit 1
fi

if [ -z "$4" ]; then
	PREFILTER=cat
else
	PREFILTER="$4"
fi
CLEAN="$3.clean"

if [ ! -f "$CLEAN" -o "$CLEAN" -ot "$3" ]; then
	sed "s/\r/\n/g" <"$3" | #Mac to UNIX line endings
	$PREFILTER |
	(echo ";;;;code;date;desc;;amount;"; tail -n +2) | #header
	sed s/,/./g | #decimal separator
	sed "s/; \\+/,/g" | #remove prefix whitespaces
	sed "s/;/,/g" | #avoid crashing Ledger
	sed "s/ PAR LES SERVICES INTERNET//" | #garbage
	sed "s/,PAIEMENT ACHAT.* HEURES. \\?/,/" | #type + date
	sed "s/ AVEC CARTE BANCAIRE[^,]*//" | #I only have one card
	sed "s/,VIREMENT EUROPEEN .*: [A-Z]\\+ /,/" | #ignore the account number
	sed "s/,DOMICILIATION EUROPEENNE [^:]*: /,/" | #too specific
	#FIXME too aggressive?
	sed "s/ REF. CREANCIER [^,]*//" | #just keep the company, not the detail
	tee "$CLEAN" >/dev/null
fi

DATE="--date-format %Y/%m/%d" #avoid .ledgerrc's influence
ledger convert -f "$1" --account "$2" --invert --rich-data \
	--input-date-format "%d/%m/%Y" $DATE "$CLEAN" |
ledger print $DATE -f - -S date
