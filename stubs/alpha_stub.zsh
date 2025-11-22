#!/usr/bin/env zsh

function heading() {
	local heading="$1"
	local color_start
	local color_end
	local width=80 # Width of the block
	local padding

	# Define colors
	color_start=$(
		tput setab 5
		tput setaf 0
	)                      # Purple background, black text
	color_end=$(tput sgr0) # Reset text

	# Calculate padding for centering the heading
	padding=$(((width - ${#heading}) / 2))

	# Print the heading with a colored block
	echo
	printf "${color_start}%*s${color_end}\n" "$width" ""
	printf "${color_start}%*s%s%*s${color_end}\n" "$padding" "" "$heading" "$padding" ""
	printf "${color_start}%*s${color_end}\n" "$width" ""
	echo
}
