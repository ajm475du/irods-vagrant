#!/bin/sh

# Run this as user irods in directory /var/lib/irods
# Get an X display by using xvfb or by running remotely via
#   ssh -X -p 50080 vagrant@localhost
#
# A handy reference for using "xdotool key":
# symbolic names for keys: /usr/include/X11/keysymdef.h

# Curator's Workbench
/var/lib/irods/curators-workbench/Workbench &
WID=`xdotool search --onlyvisible --name "Curator's"`
while [ "$WID" = "" ]
do
	sleep 1
	WID=`xdotool search --onlyvisible --name "Curator's"`
done

WID_SURVEY=`xdotool search --onlyvisible --name "User Survey"`
if [ "$WID_SURVEY" != "" ]
then
	xdotool windowactivate $WID_SURVEY
	xdotool key --window $WID_SURVEY Escape
fi

# Preferences
xdotool windowactivate $WID
xdotool key --window $WID Alt_L+h Down Down Down Down Down Down Return
xdotool sleep 1
WID_PREFS=`xdotool getactivewindow`

# Repository, Add
xdotool key r
xdotool sleep 1
xdotool key e
xdotool sleep 1
xdotool key p
xdotool sleep 3
xdotool key Return
xdotool sleep 3
# Somehow tabbing around wasn't working here,
# so I switched to mousing around.
xdotool mousemove --window $WID_PREFS 223 411
xdotool click 1
xdotool sleep 1
WID_X=`xdotool getactivewindow` # > /dev/null
xdotool getwindowname $WID_X

# stages.json
xdotool key h t t p colon slash slash l o c a l h o s t \
        slash s t a t i c slash s t a g e s period j s o n Return
xdotool getactivewindow > /dev/null

# Staging Areas, irods, Connect
xdotool key Tab Tab Tab Tab Tab Return
xdotool getactivewindow > /dev/null
xdotool sleep 1
xdotool key shift+alt+q
xdotool sleep 1
xdotool key q
xdotool getactivewindow > /dev/null
xdotool sleep 1
xdotool key s
xdotool sleep 1
xdotool key t
xdotool sleep 1
xdotool key a
xdotool sleep 1
xdotool key Return
xdotool sleep 1
xdotool key Down Return Down Down Down Down Return
xdotool getactivewindow > /dev/null

# Enter password and submit
xdotool key 4 M P A c w J e Q 2 S g Tab Tab Return

