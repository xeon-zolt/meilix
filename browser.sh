#!/bin/bash

set -eu		
# firefox
preferences_file="`echo /etc/skel/.mozilla/firefox/a.default/user.js`"
if [ -f "$preferences_file" ]
then
    echo "user_pref(\"browser.startup.homepage\", \"${event_url}\");" >> $preferences_file
fi
#chromium

