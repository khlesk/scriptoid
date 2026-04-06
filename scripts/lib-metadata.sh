#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGE_DIR="${REPO_ROOT}/package"
METADATA_PATH="${PACKAGE_DIR}/metadata.json"
XDG_DATA_HOME_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}"

require_commands() {
	local command_name

	for command_name in "$@"; do
		if ! command -v "${command_name}" >/dev/null 2>&1; then
			echo "Error: required command not found: ${command_name}" >&2
			exit 1
		fi
	done
}

require_any_command() {
	local command_name

	for command_name in "$@"; do
		if command -v "${command_name}" >/dev/null 2>&1; then
			return 0
		fi
	done

	echo "Error: one of these commands is required: $*" >&2
	exit 1
}

require_metadata_tools() {
	require_commands jq
}

metadata_value() {
	local filter="$1"

	jq -er "${filter}" "${METADATA_PATH}"
}

metadata_optional_value() {
	local filter="$1"

	jq -er "${filter} // empty" "${METADATA_PATH}" 2>/dev/null || true
}

require_package_metadata() {
	if [[ ! -d "${PACKAGE_DIR}" ]]; then
		echo "Error: package directory not found at ${PACKAGE_DIR}" >&2
		exit 1
	fi

	if [[ ! -f "${METADATA_PATH}" ]]; then
		echo "Error: metadata.json not found at ${METADATA_PATH}" >&2
		exit 1
	fi
}

load_package_metadata() {
	require_package_metadata
	require_metadata_tools

	PACKAGE_TYPE="$(metadata_value '.KPackageStructure')"
	PACKAGE_ID="$(metadata_value '.KPlugin.Id')"
	PACKAGE_VERSION="$(metadata_value '.KPlugin.Version')"
	PACKAGE_NAME="$(metadata_value '.KPlugin.Name')"
	PACKAGE_ICON="$(metadata_value '.KPlugin.Icon')"
	INSTALLED_ICON_NAME="$(metadata_value '.["X-Widget-Scripts"].Icons.InstalledName // .KPlugin.Id')"
	SCALABLE_ICON_SOURCE="$(metadata_value '.["X-Widget-Scripts"].Icons.ScalableSource // ("contents/images/" + .KPlugin.Id + ".svg")')"
	PNG_ICON_SOURCE="$(metadata_value '.["X-Widget-Scripts"].Icons.PngSource // ("contents/images/" + .KPlugin.Id + ".png")')"
	SOURCE_GITHUB_OWNER="$(metadata_optional_value '.["X-Widget-Scripts"].Source.GithubOwner')"
	SOURCE_GITHUB_REPO="$(metadata_optional_value '.["X-Widget-Scripts"].Source.GithubRepo')"
	SOURCE_GITHUB_REF="$(metadata_optional_value '.["X-Widget-Scripts"].Source.GithubRef')"
	EXAMPLES_INSTALL_DIR="${XDG_DATA_HOME_DIR}/${SOURCE_GITHUB_REPO:-${PACKAGE_ID}}/examples"
}
