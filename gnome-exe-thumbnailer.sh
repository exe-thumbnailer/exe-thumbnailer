#!/bin/bash

TEMPFILE1=$(mktemp)
TEMPFILE2=$(mktemp)
TEMPTHUMB=$(mktemp)
INPUTFILE="$1"

if wrestool --extract --type=group_icon "$INPUTFILE" > $TEMPFILE1 && [ -s $TEMPFILE1 ]
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
	grep -i "\.exe$" <<< "$INPUTFILE" && EXT="-x"
	cp /usr/share/pixmaps/gnome-exe-thumbnailer-generic${EXT}.png $TEMPTHUMB
fi

if wrestool --extract --raw --type=version "$INPUTFILE" > $TEMPFILE1 && [ -s $TEMPFILE1 ]
then
	VERSION=$(< $TEMPFILE1 \
		tr '\0, ' '\t.\0' \
		| sed 's/\t\t/_/g' \
		| tr -c -d '[:print:]' \
		| sed -r 's/.*Version[^0-9]*([0-9\.]*).*/\1/; s/([0-9]*\.[0-9]*\.[0-9][0-9]?).*/\1/; s/\.$//'
	)

	if [ "$VERSION" ]
	then
		convert -font -*-clean-medium-r-*-*-6-*-*-*-*-*-*-* \
		-background transparent -fill white label:"$VERSION" \
		-trim -bordercolor '#00001090' -border 2 \
		-fill '#00001048' \
		-draw $'color 0,0 point\ncolor 0,8 point' -flop \
		-draw $'color 0,0 point\ncolor 0,8 point' -flop \
		miff:- | composite -gravity southeast -geometry +1+3 - $TEMPTHUMB $2
	fi
else
	cp $TEMPTHUMB $2
fi

rm $TEMPFILE1 $TEMPFILE2 $TEMPTHUMB

