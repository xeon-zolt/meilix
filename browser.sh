#!/bin/bash

set -eu		
# firefox
preferences_file="`echo /home/hotelos/.mozilla/firefox/a.default/user.js`"
if [ -f "$preferences_file" ]
then
    echo "user_pref(\"browser.startup.homepage\", \"${event_url}\");" >> $preferences_file
fi

#chromium
change-homepage(){ sed -ri 's|( "${event_url}": ").*(",)|\1'"$@"'\2|' /home/hotelos/.config/chromium/Default/Preferences; }
