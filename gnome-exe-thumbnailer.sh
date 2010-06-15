#!/bin/bash

TEMPFILE=$(mktemp)
TEMPTHUMB=$(mktemp)
DEURLEDFILE=$(python -c 'import sys, urlparse, urllib; print urllib.unquote(urlparse.urlparse(sys.argv[1]).path)' $1)

if wrestool --extract --type=group_icon "$DEURLEDFILE" > $TEMPFILE && [ -s $TEMPFILE ]
then
	read INDEX OFFSET < <(
		icotool --list $TEMPFILE | awk '{
			ci=int(substr($2,index($2,"=") + 1));
			cw=int(substr($3,index($3,"=") + 1));
			cb=int(substr($5,index($5,"=") + 1));

			if ((cw > w && cw <= 32) || (cw == w && cb > b)) {
				b = cb;
				w = cw;
				i = ci;
			}
		}
		END {
			print i, 16 + (32 - w) / 2;
		}'
	)

	icotool --extract --index=$INDEX $TEMPFILE -o $TEMPFILE
	composite -geometry +$OFFSET+$OFFSET $TEMPFILE /usr/share/pixmaps/gnome-exe-thumbnailer-template.png $TEMPTHUMB

else
	grep -i "\.exe$" <<< "$DEURLEDFILE" && EXT="-x"
	cp /usr/share/pixmaps/gnome-exe-thumbnailer-generic${EXT}.png $TEMPTHUMB
fi

if wrestool --extract --raw --type=version "$DEURLEDFILE" > $TEMPFILE && [ -s $TEMPFILE ]
then
	VERSION=$(cat $TEMPFILE \
		| tr '\0' '\t' \
		| sed 's/\t\t/#/g' \
		| tr -c -d '[:print:]' \
		| sed -r 's/.*Version#*([^#]*).*/\1/; s/, /./g;' \
		| xargs echo \
		| sed -r 's/^([0-9]*\.[0-9]*\.[0-9]).*/\1/' \
		| sed 's/.* //'
	)

	if [ "$VERSION" ]
	then
		convert -font Helvetica-Bold -pointsize 7 -background '#00001090' -fill white label:" $VERSION " miff:- | \
		composite -gravity southeast -geometry +1+3 - $TEMPTHUMB $2
	fi
else
	cp $TEMPTHUMB $2
fi

rm $TEMPFILE $TEMPTHUMB
