#!/bin/bash
#
#    Copyright (C) 2024 Kevin Tyrrell
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

print_usage() {
	script_name=$(basename "$0")
    echo "usage: $script_name <main|minor|patch>"
    echo "example: $script_name minor"
    exit 1
}

# Check for no-args or --help / -h in arg list
if [[ "$#" -eq 0 ]] || [[ "$@" =~ "-h" ]] || [[ "$@" =~ "--help" ]]; then
    print_usage
fi

# Current date in yyyy-mm-dd
cur_date=$(date "+%Y-%m-%d")

# Version major.minor.patch
major=0; minor=0; patch=0
increment_version() { # Adjust the patch number according to the user's input
	if [[ "$1" != "patch" ]]; then
		patch=0
		if [[ "$1" == "major" ]]; then
			minor=0; ((major++))
		elif [[ "$1" == "minor" ]]; then
			((minor++))
		else
			echo "fatal: patch parameter was unrecognized, see usage."
			print_usage
		fi
	else
		((patch++))
	fi
}

# Replaces a line in a specific file, under the given token/marker
# @param $1 [file] Path to file to mutate
# @param $2 [string] Token to search for in file
# @param $3 [string] Replacement string to overwrite the following line
replace_line_in_file() {
	# Update version number inside code file
	if [ ! -f "$1" ]; then
		echo "fatal: file path not found: $1"; exit 1
	elif grep -q "$2" "$1"; then
		full_line="$(grep -n "$2" "$1")"  # Should be guaranteed not to fail
		line_num=$(echo "$full_line" | grep -oE '[0-9]+'); ((line_num++))
		sed -i "${line_num}s/.*/$3/" "$1"
	else
		echo "fatal: version marker is absent from file: $1"; exit 1
	fi
}

#### Constants
VER_NOTE_FILE="VERSION.ver"
VER_CODE_MARK="\-\-\[\[ __VERSION_MARKER__ ]]--"
VER_CODE_SFMT="local VERSION = { major = %d, minor = %d, patch = %d, build_date = "$cur_date" }"
VER_CODE_FILE="FadestormLib.lua"
VER_REME_MARK="<!--[[ __VERSION_MARKER__ ]]-->"
VER_REME_SFMT="#### Current Build: $cur_date | Version: v%s"
VER_REME_FILE="README.md"

# Absolute path of the repository
repo_path=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)

if [ -d "$repo_path" ]; then
	# Check if .git is in the specified repo_path or if we're inside a git repository at repo_path
	if [ -d "$repo_path/.git" ] || git --git-dir="$repo_path" rev-parse --git-dir > /dev/null 2>&1; then
		cd "$repo_path"  # Directly go to repo to avoid accidentally committing inside a submodule
		active_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
		if [ ! -z "$active_branch" ]; then
			if [ -f "$VER_NOTE_FILE" ]; then # If the version is known, 
				read -r major minor patch < <(awk -F'.' '{print $1, $2, $3}' "$VER_NOTE_FILE")
				increment_version "$1"
			else
				major=1  # Don't increment version if it is the very first commit
			fi
			
			version="$major.$minor.$patch"
			replace_line_in_file "$VER_CODE_FILE" "$VER_CODE_MARK" "$(printf "$VER_CODE_SFMT\n" $major $minor $patch)"
			replace_line_in_file "$VER_REME_FILE" "$VER_REME_MARK" "$(printf "$VER_REME_SFMT\n" $version)"
			echo "$version" > $VER_NOTE_FILE # Confirm changes to the VERSION file
						
			if [[ "$1" != "patch" ]]; then  # Only form a release if major or minor
				echo "Tagging Release"
				#git commit --allow-empty -m "Release v$version"
				# git tag -a "release-v$version" -m "Release v$version" --sign && git tag -a "release" -m "Release" --sign
				# git push origin --tags
				
				# Create a zipped folder of other items
				#zip -r special_folder.zip folder_to_zip

				# Attach the zipped folder to the release
				#gh release upload v2.0.0 special_folder.zip
			fi
						
			echo "done."
		else
			echo "fatal: active git branch could not be ascertained."
		fi
	else
		echo "fatal: script does not rest inside of a Git repository."
	fi
else
	echo "fatal: repository path is invalid: $repo_path"
fi
