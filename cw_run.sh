#!/bin/bash

# INVOCATION
#
# Run this as user vagrant in vagrant's directory: /home/vagrant
# Get an X display by using xvfb or by running remotely via
#   ssh -X -p 50022 vagrant@localhost 'sh /vagrant/cw_run.sh'
#
# NOTES
#
# * A handy reference for using "xdotool key":
#   symbolic names for keys: /usr/include/X11/keysymdef.h
#   (in Ubuntu package x11proto-core-dev)
# * The only reason this uses "xdotool sleep" rather than
#   "sleep" is a tiny aethetic reason. It fits in with all
#   the other xdotool invocations. Please do not
#   micro-optimize it, OK?


## Erase a previous test if any,
## to keep the "test the test" cycle relatively short.
#pkill -f Workbench
#[ -e curators-workbench ] && rm -rf curators-workbench
#[ -e curators-workspace ] && rm -rf curators-workspace
#[ -e .cache ] && rm -rf .cache
#tar zxf /vagrant/curators-workbench-linux.gtk.x86_64-jre.tar.gz
#
#set -v

# Curator's Workbench
cd curators-workbench
./Workbench &
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
xdotool key --window $WID Alt_L+h
xdotool sleep 1
xdotool key Down Down Down Down Down Down Return
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
[ "`xdotool getwindowname $WID_NOW`" = 'Preferences ' ] \
    || echo Did not detect Preferences window.

# Workaround: first time, tabbing gets stuck in prefs' left panel
xdotool key Tab Down Down Down Down Down Down
xdotool sleep 3
xdotool key alt+F4
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
WNAME_NOW=`xdotool getwindowname $WID_NOW`
[ "$WNAME_NOW" = "Curator's Workbench " ] \
    || echo Did not detect return to Workbench window rather $WNAME_NOW .

xdotool key --window $WID Alt_L+h
xdotool sleep 1
xdotool key Down Down Down Down Down Down Return
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
[ "`xdotool getwindowname $WID_NOW`" = 'Preferences ' ] \
    || echo Did not detect Preferences window the second time.

xdotool key Tab Tab Tab Tab Return
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
[ "`xdotool getwindowname $WID_NOW`" = 'Repository URL ' ] \
    || echo Did not detect Repository URL window.

# stages.json
#xdotool key h t t p colon slash slash r a c k 5 4 period c s period d r e x e l period e d u \
xdotool key h t t p colon slash slash l o c a l h o s t \
        slash s t a t i c slash s t a g e s period j s o n Return
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
WNAME_NOW=`xdotool getwindowname $WID_NOW`
[ "$WNAME_NOW" = 'Preferences ' ] \
    || echo Did not detect return to Preferences window rather $WNAME_NOW .

xdotool key Tab Tab Tab Tab Tab Return
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
WNAME_NOW=`xdotool getwindowname $WID_NOW`
[ "$WNAME_NOW" = "Curator's Workbench " ] \
    || echo Did not detect return to Workbench window a second time rather $WNAME_NOW .

xdotool key Tab Tab Tab Tab Tab Tab Tab Tab Down Down Down Return
xdotool sleep 1
WID_NOW=`xdotool getactivewindow`
[ "`xdotool getwindowname $WID_NOW`" = 'iRODS Authentication ' ] \
    || echo Did not detect iRODS Authentication window.

# Enter password and submit
xdotool key 4 M P A c w J e Q 2 S g Tab Tab Return

