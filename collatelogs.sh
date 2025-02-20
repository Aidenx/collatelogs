#!/bin/zsh

# Getting logged in username
loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")

# Variables to get username as per Jamf
preference_path='/Library/Managed Preferences/com.username.script'
preference_key='jamf_mac_username'
jamfUsername=$(/usr/bin/defaults read "${preference_path}" "${preference_key}")

# Get date
time=$(date "+%Y-%m-%d")

# Setting desktop variable
desktop=/Users/"${loggedInUser}"/Desktop

# Settings logs folder variable
logs_folder=/tmp/cpe_logs_tmp

# Variable for jamfHelper path
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# List of logs
logs=(
    "/private/var/log/adminbyrequest.log"
    "/private/var/log/install.log"
    "/private/var/log/Installometer.log"
    "/private/var/log/jamf.log"
    "/private/var/log/Nudge.log"
    "/private/var/log/system.log"
    "/private/var/tmp/depnotify.log"
)

# Deletes logs folder if it already exists, then (re)creates it.
if [[ -d "${logs_folder}" ]]; then
    rm -rf "${logs_folder}"
    echo "Deleting ${logs_folder}"
fi
echo "Creating logs_folder"
mkdir -p "${logs_folder}"

# Copy logs, if they exist, to logs folder
for log in "${logs[@]}"; do
    echo "Copying ${log}"
    if [[ -f "${log}" ]]; then
        cp -r "${log}" "${logs_folder}"
        echo "Copied ${log}"
    else
        echo "${log} not found"
    fi
done

# Zips logs folder
echo "Creating zip folder..."
if [[ -n "$jamfUsername" ]]; then
    echo "Creating zip file with Jamf username"
    tar -C /tmp -cvf "${desktop}/CPE_Logs_${jamfUsername}_${time}.zip" cpe_logs_tmp
else
    echo "Creating zip file with local username"
    tar -C /tmp -cvf "${desktop}/CPE_Logs_${loggedInUser}_${time}.zip" cpe_logs_tmp
fi

# Open Desktop window
open "${desktop}"
echo "Alerting user..."

# Display jamfHelper message
output=$("$jamfHelper" \
-windowType utility \
-title "Jamf" \
-heading "Logs Collated" \
-description "We have opened the Desktop folder for you where you will find your CPE Logs.

Please upload this file to your IT Ticket." \
-icon "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" \
-button1 "OK"
-button2 "OK Again")

# Open Desktop again
if [[ "$output" == "0" ]]; then
    echo "Opening Desktop again"
    open "${desktop}"
else
    echo "Nothing"
fi
