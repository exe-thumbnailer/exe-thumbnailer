#!/bin/bash

TEMPFILE1=$(mktemp)
TEMPFILE2=$(mktemp)
TEMPTHUMB=$(mktemp)
DEURLEDFILE=$(python -c 'import sys, urlparse, urllib; print urllib.unquote(urlparse.urlparse(sys.argv[1]).path)' $1)

if wrestool --extract --type=group_icon "$DEURLEDFILE" > $TEMPFILE1 && [ -s $TEMPFILE1 ]
then
	read INDEX OFFSET < <(
		icotool --list $TEMPFILE1 | awk '{
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

	icotool --extract --index=$INDEX $TEMPFILE1 -o $TEMPFILE2
	composite -geometry +$OFFSET+$OFFSET $TEMPFILE2 /usr/share/pixmaps/gnome-exe-thumbnailer-template.png $TEMPTHUMB

else
	grep -i "\.exe$" <<< "$DEURLEDFILE" && EXT="-x"
	cp /usr/share/pixmaps/gnome-exe-thumbnailer-generic${EXT}.png $TEMPTHUMB
fi

if wrestool --extract --raw --type=version "$DEURLEDFILE" > $TEMPFILE1 && [ -s $TEMPFILE1 ]
then
	VERSION=$(cat $TEMPFILE1 \
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
		convert -font -*-clean-medium-r-*-*-6-*-*-*-*-*-*-* -interline-spacing 1 \
		-background transparent -fill white -bordercolor '#00001090' \
		-border 1x0 -shave 0x1 label:"$VERSION" miff:- | \
		composite -gravity southeast -geometry +1+3 - $TEMPTHUMB $2
	fi
else
	cp $TEMPTHUMB $2
fi

rm  $TEMPFILE1 $TEMPFILE2 $TEMPTHUMB

