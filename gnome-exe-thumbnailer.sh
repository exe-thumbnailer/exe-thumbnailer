#!/bin/bash

f=`mktemp`
deurledfile=`python -c 'import sys, urlparse, urllib; print urllib.unquote(urlparse.urlparse(sys.argv[1]).path)' $1`

if wrestool "$deurledfile" -x -t14 > $f && [ -s $f ]; then
	id=$(icotool -l $f | awk '{
		ci=int(substr($2,index($2,"=")+1));
		cw=int(substr($3,index($3,"=")+1));
		cb=int(substr($5,index($5,"=")+1));

		if (cw > w || (cw == w && cb > b)) {
			b = cb;
			w = cw;
			i = ci;
		}
		}
		END {
			print i;
		}')

	icotool -x --index=$id $f -o $f

	if [ $(file -b $f | cut -f3 -d' ') -gt 48 ]; then
		convert -resize 48x48 $f $f
	fi
	
	if [[ $3 == "--clean" ]]; then
		cp $f $2
	else
		composite -gravity center $f /usr/share/pixmaps/gnome-exe-thumbnailer-template-wine.png $2
	fi
else
	cp /usr/share/pixmaps/gnome-exe-thumbnailer-template-wine.png "$2"
fi

rm $f
