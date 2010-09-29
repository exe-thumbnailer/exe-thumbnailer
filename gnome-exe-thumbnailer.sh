#!/bin/bash
shopt -s nocasematch

INPUTFILE="$1"

TEMPFILE1=$(mktemp)
TEMPFILE2=$(mktemp)
TEMPTHUMB=$(mktemp)


if [[ ${INPUTFILE##*.} = 'msi' ]]
then
	# Use generic installer icon for a .msi package:
	ICON=/usr/share/pixmaps/gnome-exe-thumbnailer/generic-installer.png
	OFFSET=16

else
	# Extract group_icon resource.
	# If we get the "wrestool: $INPUTFILE could not find `1' in `group_icon' resource." error,
	# there is a 99.9% chance that input file is an installer.

	# Warning: Some redirection magic ahead.

	wrestool --extract --type=group_icon "$INPUTFILE" 2>&1 >$TEMPFILE1 | grep 'could not find'

	if [ $? -eq 0 ]
	then
		# Use generic installer icon:
		ICON=/usr/share/pixmaps/gnome-exe-thumbnailer/generic-installer.png
		OFFSET=16

	else
		# Process extracted data, if we have some:
		if [ -s $TEMPFILE1 ]
		then
			# Look for the best usable icon:
			read OFFSET INDEX < <(
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
					print 16 + (32 - w) / 2, i;
				}'
			)

			# Use a resized 48x48 icon if 32x32 or smaller isn't available.
			# This is very rare, but it happens sometimes:
			if [ "$INDEX" = '' ]
			then
				INDEX=1
				RESIZE=yes
				OFFSET=20
			fi

			# Finally try to extract chosen icon:
			icotool --extract --index=$INDEX $TEMPFILE1 -o $TEMPFILE2

			if [ -s $TEMPFILE2 ]
			then
				ICON=$TEMPFILE2
				[ "$RESIZE" ] && mogrify -resize 24x24 $ICON

			else
				# This case generally happens when the hi-res icons are in new "Vista" icon format (bunch of compressed PNGs).
				# Icotool from icoutils 0.29.1 supports it already, but is unable to extract the one selected icon only.

				# Try to extract all icons:
				icotool --extract $TEMPFILE1 -o /tmp

				# There's always a 32x32x32 icon in "Vista" icons, but just to be sure:
				if [ -s ${TEMPFILE1}_${INDEX}_32x32x32.png ]
				then
					ICON=${TEMPFILE1}_${INDEX}_32x32x32.png
				else
					# Use the generic icon (icoutils < 0.29.1):
					[[ ${INPUTFILE##*.} = 'exe' ]] && EXE='-exe'
					ICON=/usr/share/pixmaps/gnome-exe-thumbnailer/generic$EXE.png
					OFFSET=19
				fi
			fi

		else
			# Just use the generic icon:
			[[ ${INPUTFILE##*.} = 'exe' ]] && EXE='-exe'
			ICON=/usr/share/pixmaps/gnome-exe-thumbnailer/generic$EXE.png
			OFFSET=19
		fi
	fi
fi

# Create the basic thumbnail:
composite -geometry +$OFFSET+$OFFSET $ICON /usr/share/pixmaps/gnome-exe-thumbnailer/template.png $TEMPTHUMB


# Get the version number:
if [[ ${INPUTFILE##*.} = 'msi' ]]
then
	VERSION=$(file "$INPUTFILE" \
		| grep -o ', Subject: .*, Author: ' \
		| egrep -o '[0-9]+\.[0-9]+(\.[0-9][0-9]?)?(beta)?' \
		| head -1
	)

else
	# Extract raw version resource:
	wrestool --extract --raw --type=version "$INPUTFILE" > $TEMPFILE1

	if [ -s $TEMPFILE1 ]
	then
		# Search for a sane version string.
		# This (especially the final regexp) took me really long time to figure out. Am I that lame?
		VERSION=$(< $TEMPFILE1 \
			tr '\0, ' '\t.\0' \
			| sed 's/\t\t/_/g' \
			| tr -c -d '[:print:]' \
			| sed -r -n 's/.*Version[^0-9]*([0-9]+\.[0-9]+(\.[0-9][0-9]?)?).*/\1/p'
		)
	fi
fi


# Put a version label on the thumbnail:
if [ "$VERSION" ]
then
	convert -font -*-clean-medium-r-*-*-6-*-*-*-*-*-*-* \
	-background transparent -fill white label:"$VERSION" \
	-trim -bordercolor '#00001090' -border 2 \
	-fill '#00001048' \
	-draw $'color 0,0 point\ncolor 0,8 point' -flop \
	-draw $'color 0,0 point\ncolor 0,8 point' -flop \
	miff:- | composite -gravity southeast -geometry +1+3 - $TEMPTHUMB $2
else
	cp $TEMPTHUMB $2
fi


rm $TEMPFILE1* $TEMPFILE2 $TEMPTHUMB

