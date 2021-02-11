#!/bin/zsh
# shellcheck shell=bash

# unScene v0.1
# Finder QuickAction

export LANG=en_US.UTF-8
export SYSTEM_VERSION_COMPAT=0
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin

_beep () {
	osascript -e 'beep' &>/dev/null
}

_notify () {
	osascript -e "display notification \"$2\" with title \"unScene [\" & \"$account\" & \"]\" subtitle \"$1\""
}

_success () {
	afplay "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/burn complete.aif" &>/dev/null
}

account=$(id -u)

if ! command -v unzip &>/dev/null ; then
	_beep &
	_notify "❌ Error" "unzip not found"
	exit 
fi

if ! [[ $* ]] ; then
	_beep &
	_notify "⚠️ Error" "No input"
	exit 
fi

filepath="$1"
if [[ -f "$filepath" ]] ; then
	if echo "$filepath" | grep -q "\.zip$" ; then
		filepath=$(dirname "$filepath")
	else
		_beep &
		_notify "⚠️ Error" "Not a .zip file"
		exit
	fi
else
	if ! [[ -d "$filepath" ]] ; then
		_beep &
		_notify "⚠️ Error" "Incompatible filetype"
		exit
	fi
fi

zipfiles=$(find "$filepath" -type f -mindepth 1 -maxdepth 1 -name '*.zip' 2>/dev/null)
if ! [[ $zipfiles ]] ; then
	_beep &
	_notify "⚠️ Error" "No zip files in folder"
	exit
fi

while read -r zipfile
do
	zipname=$(basename "$zipfile")
	if ! unzip -qq -o "$zipfile" -d "$filepath" &>/dev/null ; then
		_beep &
		_notify "⚠️ Error" "$zipname"
		exit
	fi
done < <(echo "$zipfiles")

rm -rf "$filepath/__MACOSX/" 2>/dev/null

if ! command -v unrar &>/dev/null ; then
	_success &
	exit
fi

rarfile=$(find "$filepath" -type f -mindepth 1 -maxdepth 1 -name '*.rar' 2>/dev/null)
rfn=$(echo "$rarfile" | wc -l)
if [[ $rfn -eq 0 ]] ; then
	rarfile=$(find "$filepath" -type f -mindepth 1 -maxdepth 1 -name '*.part1.rar' 2>/dev/null)
	rfn=$(echo "$rarfile" | wc -l)
	if [[ $rfn -eq 0 ]] ; then
		_success &
		exit
	elif [[ $rfn -gt 1 ]]  ; then
		_beep &
		_notify "⚠️ Error" "Too many .rar files"
		exit
	fi
elif [[ $rfn -gt 1 ]] ; then
	rarfile=$(find "$filepath" -type f -mindepth 1 -maxdepth 1 -name '*.part1.rar' 2>/dev/null)
	rfn=$(echo "$rarfile" | wc -l)
	if [[ $rfn -eq 0 ]] ; then
		_beep &
		_notify "⚠️ Error" "Too many .rar files"
		exit
	elif [[ $rfn -gt 1 ]] ; then
		_beep &
		_notify "⚠️ Error" "Too many .rar files"
		exit
	fi
fi

rarname=$(basename "$rarfile")
if ! unrar x -o+ "$rarfile" "$filepath" -idq &>/dev/null ; then
	_beep &
	_notify "⚠️ Error" "$rarname"
	exit
fi

_success &

exit
