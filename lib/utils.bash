#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/dojoengine/dojo"
DOJOUP_INSTALLATION_SCRIPT="https://install.dojoengine.org"
TOOL_NAME="dojo"
TOOL_TEST="sozo --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/v.*' | cut -d/ -f3- |
		sed 's/^v//'
}

list_all_versions() {
	list_github_tags
}

download_dojo_up() {
	local filename url
	filename="$1"

	local repository tag

	url=$DOJOUP_INSTALLATION_SCRIPT

	local _script="dojo_up_installation_script.sh"

	echo "* Downloading $TOOL_NAME"
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
        # Use dojoup for installation
        dojoup -v "$version" || fail "An error occurred while installing $TOOL_NAME $version with dojoup."

		# Test the installation
        $TOOL_TEST || fail "An error occurred while testing $TOOL_NAME $version."

        echo "$TOOL_NAME $version installation was successful!"
	) || (
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
