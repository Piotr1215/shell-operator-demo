#!/usr/bin/env bash

title="Shell Operator"

if command -v figlet &>/dev/null && command -v boxes &>/dev/null; then
	echo "$title" | figlet -f big | lolcat | boxes -d peek
else
	echo "$title"
fi
