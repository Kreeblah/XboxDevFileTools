#!/usr/bin/env zsh

XBOX_RESPONSE_CODE=""
XBOX_CSRF_TOKEN=""
XBOX_RELATIVE_PATH=""
XBOX_RELATIVE_PATH_PARTS=""
XBOX_URLENCODED_STRING=""
XBOX_DIRECTORY_LISTING_JSON=""

# Parameters: None
function _xbox_login {
    XBOX_LOGIN_OUTPUT=$(curl --insecure \
                                      -sIXGET \
                                      -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                      -c - \
                                      "https://${XBOX_HOSTNAME}:${XBOX_PORT}")

    echo "Logging in to: https://${XBOX_HOSTNAME}:${XBOX_PORT}"

    _xbox_response_code "${XBOX_LOGIN_OUTPUT}"

    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Login failure.  Check credentials, host, and port."
        exit 1
    fi

    XBOX_CSRF_TOKEN_LINE=$(echo "${XBOX_LOGIN_OUTPUT}" | grep -i "^set-cookie: ")
    XBOX_CSRF_TOKEN_LINE=$(echo "${XBOX_CSRF_TOKEN_LINE}" | awk '{print $2}')
    XBOX_CSRF_TOKEN=$(echo "${XBOX_CSRF_TOKEN_LINE}" | awk -F '=' '{print $2}')
    XBOX_CSRF_TOKEN=$(echo "${XBOX_CSRF_TOKEN}" | sed 's/\r$//')
}

# Parameters: Local file path, Remote file path (/ delimited, no starting /, User Folders is assumed)
function _xbox_upload_file {
	_xbox_get_relative_path "$2"

    echo "Uploading file: $1"
    echo "Destination path: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_FILE_UPLOAD_OUTPUT=$(curl --insecure \
                                   -siXPOST \
                                   --form "file=@$1;type=application/octet-stream" \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: POST" \
                                   -H ":path: /api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}&extract=false" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}&extract=false")

    _xbox_response_code "${XBOX_FILE_UPLOAD_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to upload file: $1"
        exit 1
    fi
}

# Parameters: Local file path, Remote file path (/ delimited, no starting /, User Folders is assumed; this will be the directory your ZIP file is extracted into)
function _xbox_upload_zipped_directory {
    _xbox_get_relative_path "$2"

    echo "Uploading zipped directory: $1"
    echo "Destination path: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_ZIPPED_DIRECTORY_UPLOAD_OUTPUT=$(curl --insecure \
                                   -siXPOST \
                                   --form "file=@$1;type=application/octet-stream" \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: POST" \
                                   -H ":path: /api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}&extract=true" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}&extract=true")

    _xbox_response_code "${XBOX_ZIPPED_DIRECTORY_UPLOAD_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to upload zipped directory: $1"
        exit 1
    fi
}

# Parameters: Remote file directory, Remote file name, Local file name
function _xbox_save_file {
    _xbox_get_relative_path "$1"

    echo "Saving file: $2"
    echo "File path: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}"
    echo "Saving to: $3"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_FILE_SAVE_OUTPUT=$(curl --insecure \
                                   -D - \
                                   -s \
                                   -X GET \
                                   -o "$3" \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: GET" \
                                   -H ":path: /api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=$2&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=$2&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}")

    _xbox_response_code "${XBOX_FILE_SAVE_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to save file: $1"
        exit 1
    fi
}

# Parameters: Remote file directory, Remote file name
# Note: The same call is used to delete directories, with the directory name as the remote file name
function _xbox_delete_file {
    _xbox_get_relative_path "$1"

    echo "Deleting file: $2"
    echo "File path: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_FILE_DELETION_OUTPUT=$(curl --insecure \
                                   -siXDELETE \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: DELETE" \
                                   -H ":path: /api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=$2&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/file?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=$2&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}")

    _xbox_response_code "${XBOX_FILE_DELETION_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to delete file: $1"
        exit 1
    fi
}

# Parameters: Remote file directory, Old remote file name, New remote file name
# Note: The same call is used to rename directories, with the directory name as the old/new remote file names
function _xbox_rename_file {
    _xbox_get_relative_path "$1"

    echo "Renaming file: $2"
    echo "New file name: $3"
    echo "File path: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_FILE_RENAME_OUTPUT=$(curl --insecure \
                                   -siXPOST \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: POST" \
                                   -H ":path: /api/filesystem/apps/rename?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=$2&newfilename=$3&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "content-length: 0" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/rename?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=$2&newfilename=$3&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}")

    _xbox_response_code "${XBOX_FILE_RENAME_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to rename file: $1"
        exit 1
    fi
}

# Parameters: Remote file path (/ delimited, no starting /, User Folders is assumed), Directory name
function _xbox_create_directory {
	_xbox_get_relative_path "$2"
	echo "Creating directory at: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}\\$1"
	_xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
	local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

	_xbox_urlencode_string "$1"
	local XBOX_DIRECTORY_NAME_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_DIRECTORY_CREATION_OUTPUT=$(curl --insecure \
                                          -siXPOST \
                                          -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                          -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                          -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                          -H ":method: POST" \
                                          -H ":path: /api/filesystem/apps/folder?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&newfoldername=${XBOX_DIRECTORY_NAME_ENCODED}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}" \
                                          -H ":scheme: HTTPS" \
                                          -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                          -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                          -H "content-length: 0" \
                                          -H "x-requested-with: XMLHttpRequest" \
                                          "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/folder?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&newfoldername=${XBOX_DIRECTORY_NAME_ENCODED}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}")

    _xbox_response_code "${XBOX_DIRECTORY_CREATION_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to create directory at: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}\\$1"
        exit 1
    fi
}

# Parameters: Remote directory location (without final directory name), Remote directory name, Local zip file name
function _xbox_save_zipped_directory {
    _xbox_get_relative_path "$1"

    echo "Saving contents from directory: $2"
    echo "Directory path: \\\\\\\\${XBOX_REMOTE_PATH_PARTS[1]}\\${XBOX_REMOTE_PATH_PARTS[2]}${XBOX_RELATIVE_PATH}"
    echo "Saving to: $3"

    XBOX_RELATIVE_PATH="${XBOX_RELATIVE_PATH}\\\\$2"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    _xbox_urlencode_string "$2"
    local XBOX_URLENCODED_DIRECTORY_NAME="${XBOX_URLENCODED_STRING}"

    local XBOX_DIRECTORY_SAVE_OUTPUT=$(curl --insecure \
                                   -D - \
                                   -s \
                                   -X GET \
                                   -o "$3" \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: GET" \
                                   -H ":path: /api/filesystem/apps/folder?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=${XBOX_URLENCODED_DIRECTORY_NAME}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/folder?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&filename=${XBOX_URLENCODED_DIRECTORY_NAME}&filename=$2&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}")

    _xbox_response_code "${XBOX_DIRECTORY_SAVE_OUTPUT}"
    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to save zipped directory: $1"
        exit 1
    fi
}

# Parameters: Remote directory location
function _xbox_get_directory_listing_json {
    _xbox_get_relative_path "$1"

    echo "Getting directory listing in: $1"

    _xbox_urlencode_string "${XBOX_RELATIVE_PATH}"
    local XBOX_RELATIVE_PATH_ENCODED="${XBOX_URLENCODED_STRING}"

    local XBOX_EPOCH_MS=$(printf '%d\n' $((EPOCHREALTIME*1000)))

    local XBOX_DIRECTORY_LISTING_OUTPUT=$(curl --insecure \
                                   -D - \
                                   -s \
                                   -X GET \
                                   -u "${XBOX_USERNAME}:${XBOX_PASSWORD}" \
                                   -H "x-csrf-token: ${XBOX_CSRF_TOKEN}" \
                                   -H ":authority: ${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H ":method: GET" \
                                   -H ":path: /api/filesystem/apps/files?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}&_=${XBOX_EPOCH_MS}" \
                                   -H ":scheme: HTTPS" \
                                   -H "origin: https://${XBOX_HOSTNAME}:${XBOX_PORT}" \
                                   -H "referer: https://${XBOX_HOSTNAME}:${XBOX_PORT}/" \
                                   -H "x-requested-with: XMLHttpRequest" \
                                   "https://${XBOX_HOSTNAME}:${XBOX_PORT}/api/filesystem/apps/files?knownfolderid=${XBOX_REMOTE_PATH_PARTS[1]}&packagefullname=${XBOX_REMOTE_PATH_PARTS[2]}&path=${XBOX_RELATIVE_PATH_ENCODED}&_=${XBOX_EPOCH_MS}")

    _xbox_response_code "${XBOX_DIRECTORY_LISTING_OUTPUT}"

    if [[ "${XBOX_RESPONSE_CODE}" == "200" ]]; then
        echo "Success."
    else
        echo "Failed to get directory listing in: $1"
        exit 1
    fi

    XBOX_DIRECTORY_LISTING_JSON=$(echo "${XBOX_DIRECTORY_LISTING_OUTPUT}" | grep "^{")
}

# Parameters: Relative path to convert to Xbox format
function _xbox_get_relative_path {
    local XBOX_RELATIVE_PATH_TOKEN=""
    XBOX_REMOTE_PATH_PARTS=(${(s[/])1})
    XBOX_RELATIVE_PATH="\\"
    for XBOX_RELATIVE_PATH_TOKEN ("${XBOX_REMOTE_PATH_PARTS[@]:2}") XBOX_RELATIVE_PATH="${XBOX_RELATIVE_PATH}\\${XBOX_RELATIVE_PATH_TOKEN}"
}

# Parameters: Curl header payload
function _xbox_response_code {
	XBOX_HEADER_STATUS_LINE=$(echo "$1" | grep -i "^HTTP/2 ")
	XBOX_RESPONSE_CODE=$(echo "${XBOX_HEADER_STATUS_LINE}" | awk '{print $2}')
}

# Parameters: String to URL encode
function _xbox_urlencode_string {
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    XBOX_URLENCODED_STRING=""

    local i length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) XBOX_URLENCODED_STRING=${XBOX_URLENCODED_STRING}$(printf '%s' "$c") ;;
            *) XBOX_URLENCODED_STRING=${XBOX_URLENCODED_STRING}$(printf '%%%02X' "'$c") ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

# Parameters: Directory containing local files, Remote directory
function _xbox_upload_files_from_directory {
    for file in $1/*(.); do
    	echo "$file"
        _xbox_upload_file "$file" "$2"
    done
}

zmodload zsh/zutil
zmodload zsh/datetime
autoload is-at-least

if ! is-at-least 5.8 ${ZSH_VERSION}; then
    echo "This script requires zsh 5.8 or higher."
    exit 1
fi

zparseopts -D -E -F - u:=XBOX_USERNAME -username:=XBOX_USERNAME p:=XBOX_PASSWORD -password:=XBOX_PASSWORD h:=XBOX_HOSTNAME -hostname:=XBOX_HOSTNAME t:=XBOX_PORT -port:=XBOX_PORT l:=XBOX_LOCAL_FILE_DIRECTORY -local-directory:=XBOX_LOCAL_FILE_DIRECTORY r:=XBOX_REMOTE_FILE_DIRECTORY -remote-directory:=XBOX_REMOTE_FILE_DIRECTORY || exit 1

end_opts=$@[(i)(--|-)]
set -- "${@[0,end_opts-1]}" "${@[end_opts+1,-1]}"

if [[ -z "${XBOX_USERNAME}" ]]; then
    echo "Username not provided."
    exit 1
else
    XBOX_USERNAME="${XBOX_USERNAME[2]}"
fi

if [[ -z "${XBOX_PASSWORD}" ]]; then
    echo "Password not provided."
    exit 1
else
    XBOX_PASSWORD="${XBOX_PASSWORD[2]}"
fi

if [[ -z "${XBOX_HOSTNAME}" ]]; then
    echo "Xbox hostname not provided."
    exit 1
else
    XBOX_HOSTNAME="${XBOX_HOSTNAME[2]}"
fi

if [[ -z "${XBOX_PORT}" ]]; then
    XBOX_PORT="11443"
else
    XBOX_PORT="${XBOX_PORT[2]}"
fi

if [[ -z "${XBOX_LOCAL_FILE_DIRECTORY}" ]]; then
    echo "Local file directory not provided."
    exit 1
else
    XBOX_LOCAL_FILE_DIRECTORY="${XBOX_LOCAL_FILE_DIRECTORY[2]}"
fi

if [[ -z "${XBOX_REMOTE_FILE_DIRECTORY}" ]]; then
    echo "Remote directory not provided"
    exit 1
else
    XBOX_REMOTE_FILE_DIRECTORY="${XBOX_REMOTE_FILE_DIRECTORY[2]}"
fi

_xbox_login
_xbox_upload_files_from_directory "${XBOX_LOCAL_FILE_DIRECTORY}" "${XBOX_REMOTE_FILE_DIRECTORY}"
