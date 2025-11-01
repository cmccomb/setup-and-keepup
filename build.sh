#!/usr/bin/env sh

# Make a place to put the scripts after we build them
rm -rf scripts || true
mkdir scripts
touch scripts/play.zsh scripts/work.zsh

# Go to the stubs directory
cd stubs || exit 1

# Function to remove subsequent shebangs
remove_extra_shebangs() {
	sed -i '' '1!{/^#!/d;}' "$1" || sed -i '1!{/^#!/d;}' "$1"
}

# Build the play stack
cat \
  alpha_stub.zsh \
        system/repo/update \
        system/check/icloud_is_signed_in \
        system/check/system_preferences_is_closed \
	installations/developer_tools/install \
	installations/homebrew/install \
	installations/homebrew/base \
	installations/homebrew/work \
	installations/homebrew/cleanup \
	installations/app_store/base \
	installations/app_store/play \
	installations/web_apps/base \
	installations/web_apps/work \
	installations/web_apps/cleanup \
	installations/ai/base \
	installations/ai/play \
	customizations/terminal/base \
	customizations/textedit/base \
	customizations/photos/base \
	customizations/safari/base \
	system/updates/base \
	system/screenshots/base \
	system/energy/base \
	system/io/base \
	interface/ui/base \
	interface/wallpaper/base \
	interface/wallpaper/play \
	interface/dock/play \
	interface/finder/base \
	installations/oh_my_zsh/install \
	>../scripts/play.zsh

# Remove subsequent shebangs from play stack
remove_extra_shebangs ../scripts/play.zsh

# Build the work stack
cat \
  alpha_stub.zsh \
        system/repo/update \
        system/check/icloud_is_signed_in \
        system/check/system_preferences_is_closed \
	installations/developer_tools/install \
	installations/homebrew/install \
	installations/homebrew/base \
	installations/homebrew/work \
	installations/homebrew/cleanup \
	installations/app_store/base \
	installations/app_store/work \
	installations/web_apps/base \
	installations/web_apps/play \
	installations/web_apps/cleanup \
	installations/ai/base \
	installations/ai/play \
	customizations/photos/base \
	customizations/terminal/base \
	customizations/textedit/base \
	customizations/safari/base \
	system/updates/base \
	system/screenshots/base \
	system/energy/base \
	system/io/base \
	interface/ui/base \
	interface/wallpaper/base \
	interface/wallpaper/play \
	interface/dock/work \
	interface/finder/base \
	installations/oh_my_zsh/install \
	>../scripts/work.zsh

# Remove subsequent shebangs from work stack
remove_extra_shebangs ../scripts/work.zsh

cd .. || exit 1
