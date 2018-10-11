#!/usr/bin/env bash
# retropie-create-new-system.sh
#
# RetroPie Create New System
# A tool for RetroPie to create a new system for EmulationStation.
#
# Author: hiulit
# Repository: https://github.com/hiulit/RetroPie-Create-New-System
# License: MIT License https://github.com/hiulit/RetroPie-Create-New-System/blob/master/LICENSE
#
# Requirements:
# - RetroPie 4.x.x

# Globals ####################################################################

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"

home="$(find /home -type d -name RetroPie -print -quit 2> /dev/null)"
home="${home%/RetroPie}"

readonly RP_DIR="$home/RetroPie"
readonly RP_CONFIG_DIR="/opt/retropie/configs"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly ES_SYSTEMS_CFG="/etc/emulationstation/es_systems.cfg"
readonly ES_SETTINGS_CFG="/opt/retropie/configs/all/emulationstation/es_settings.cfg"
readonly USER_ES_SYSTEM_CFG="$RP_CONFIG_DIR/all/emulationstation/es_systems.cfg"

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="RetroPie Create New System"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to create a new system for EmulationStation."

readonly DEPENDENCIES=("imagemagick" "librsvg2-bin")

readonly LOG_DIR="$SCRIPT_DIR/logs"
readonly LOG_FILE="$LOG_DIR/$(date +%F-%T).log"


# Variables ##################################################################

SYSTEM_NAME="hh"
SYSTEM_FULLNAME="Homebrew and Hacks"
SYSTEM_PATH="$RP_ROMS_DIR/$SYSTEM_NAME"
SYSTEM_EXTENSION=".nes .zip .NES .ZIP"
SYSTEM_COMMAND="/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ $SYSTEM_NAME %ROM%"
SYSTEM_PLATFORM=""
SYSTEM_THEME="$SYSTEM_NAME"

SYSTEM_NAME=""
SYSTEM_FULLNAME=""
SYSTEM_PATH=""
SYSTEM_EXTENSION=""
SYSTEM_COMMAND=""
SYSTEM_PLATFORM=""
SYSTEM_THEME=""

SYSTEM_PROPERTIES=(
    "name $SYSTEM_NAME"
    "fullname $SYSTEM_FULLNAME"
    "path $SYSTEM_PATH"
    "extension $SYSTEM_EXTENSION"
    "command $SYSTEM_COMMAND"
    "platform $SYSTEM_PLATFORM"
    "theme $SYSTEM_THEME"
)

SYSTEM_FIELDS=(
    "name"
    "fullname"
    "path"
    "extension"
    "command"
    "platform"
    "theme"
)

NEW_SYSTEM_PROPERTIES=()
NEW_EMULATORS=()

DEFAULT_THEME="carbon"

## Flags

GUI_FLAG=0
WIZARD_FLAG=0


# External resources ######################################

source "$SCRIPT_DIR/utils/base.sh"
source "$SCRIPT_DIR/utils/dialogs.sh"
source "$SCRIPT_DIR/utils/imagemagick.sh"


# Functions ##################################################################

function get_all_systems() {
    local system_names=()
    local system_name
    while read -r system_name; do
        [[ "$system_name" != "retropie" ]] && system_names+=("$system_name")
    done < <(xmlstarlet sel -t -v "systemList/system/name" "$ES_SYSTEMS_CFG" 2> /dev/null)
    echo "${system_names[@]}"
}


function get_games() {
    local games=()
    local emulator

    for emulator in "${NEW_EMULATORS[@]}"; do
        # Check if folder is not empty.
        if [[ "$(ls -A "$RP_ROMS_DIR/$emulator")" ]]; then
            local rom
            for rom in "$RP_ROMS_DIR/$emulator/"*; do
                local extension
                extension="${rom##*.}"
                # Add roms that match the extension
                if grep -q -P "(?=.*?$extension)^.*$" <<< "${NEW_SYSTEM_PROPERTIES[3]}"; then
                    games+=("$(basename "$rom")")
                fi
            done
        fi
    done
    echo "${games[@]}"
}


function get_current_theme() {
    if [[ ! -f "$ES_SETTINGS_CFG" ]]; then
        echo "$DEFAULT_THEME"
    else
        sed -n "/name=\"ThemeSet\"/ s/^.*value=['\"]\(.*\)['\"].*/\1/p" "$ES_SETTINGS_CFG"
    fi
}


function get_font() {
    local theme
    theme="$(get_current_theme)"
    if [[ -z "$theme" ]]; then
        echo "WARNING: Couldn't get the current theme."
        echo "Switching to the default's theme ..."
        theme="$DEFAULT_THEME"
    fi
    local font
    font="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed')]/textlist/fontPath" \
        "$ES_THEMES_DIR/$theme/$theme.xml" 2> /dev/null)"

    if [[ -n "$font" ]]; then
        font="$ES_THEMES_DIR/$theme/$font"
    else
        # Note: the find function below returns the full path file name.
        font="$(find "$ES_THEMES_DIR/$theme/" -type f -name '*.ttf' -print -quit 2> /dev/null)"
        if [[ -z "$font" ]]; then
            echo "ERROR: Unable to get the font from the '$theme' theme files."
            echo "Aborting ..." >&2
            exit 1
        fi
    fi
    echo "$font"
}


function get_system_logo() {
    if [[ ! -f "$ES_THEMES_DIR/$theme/$system/theme.xml" ]]; then
        if [[ "$system" = *"mame-"* ]]; then
            system="mame"
        fi
    fi
    local logo
    logo="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='logo']/path" \
        "$ES_THEMES_DIR/$theme/$system/theme.xml" 2> /dev/null | head -1)"
    logo="$ES_THEMES_DIR/$theme/$system/$logo"
    if [[ -f "$logo" ]]; then
        echo "$logo"
    else
        return 1
    fi
}


function get_console() {
    if [[ ! -f "$ES_THEMES_DIR/$theme/$system/theme.xml" ]]; then
        if [[ "$system" = *"mame-"* ]]; then
            system="mame"
        fi
    fi
    local console
    console="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='console_overlay' or @name='ControllerOverlay']/path" \
        "$ES_THEMES_DIR/$theme/$system/theme.xml" 2> /dev/null | head -1)"
    console="$ES_THEMES_DIR/$theme/$system/$console"
    if [[ -f "$console" ]]; then
        echo "$console"
    else
        return 1
    fi
}


function get_theme_xml() {
    echo "$ES_THEMES_DIR/$theme/$system/theme.xml"
}


function system_exists() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a string as an argument!" >&2
        exit 1
    fi
    local system="$1"
    xmlstarlet sel -t -v "/systemList/system[name='$system']" "$USER_ES_SYSTEM_CFG" > /dev/null
}


function get_installed_systems() {
    local installed_systems=()
    local system_name
    while read -r system_name; do
        installed_systems+=("$system_name")
    done < <(xmlstarlet sel -t -m "/systemList/system[createdwith='$SCRIPT_NAME']" -v name -n "$USER_ES_SYSTEM_CFG" 2> /dev/null)
    echo "${installed_systems[@]}"
}


function copy_es_systems_cfg() {
    if [[ ! -f "$USER_ES_SYSTEM_CFG" ]]; then
        cp "$ES_SYSTEMS_CFG" "$USER_ES_SYSTEM_CFG"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 1 ]]; then
            echo "ERROR: Couldn't copy '"$ES_SYSTEMS_CFG"'" >&2
            exit 1
        fi
    fi
}


function update_system() {
    while IFS= read -r line; do
        local key
        key="$(echo "$line" | grep -o -P '(?<=\<(?!\/))[^\>]+')" # Find characters beween '<' (not followed by '/') and '>'
        local value
        value="$(echo "$line" | grep -o -P '(?<=\>).*(?=\<)')" # Find characters between '>' and '<'
        if [[ -n "$value" ]]; then
            echo "$key: $value"
        fi
        # [[ "$line" != "<system>" || "$line" != "</system>" ]] && echo "$line" # system_names+=("$system_name")
    done < <(xmlstarlet sel -t -c "systemList/system[name='$system']/node()" "$USER_ES_SYSTEM_CFG" 2> /dev/null)

    # xmlstarlet sel -t -c "systemList/system[name='$system']" "$USER_ES_SYSTEM_CFG"
    exit


    log "Updating values for system '$SYSTEM_NAME' ..."
    local message
    message="New values for '$SYSTEM_NAME':"
    underline "$message"
    for system_property in "${SYSTEM_PROPERTIES[@]}"; do
        local key
        local value
        key="$(echo $system_property | grep  -Eo "^[^ ]+")"
        value="$(echo $system_property | grep -Po "(?<= ).*")"
        if [[ -n "$value" ]]; then
            xmlstarlet ed -L -u "/systemList/system[name='$SYSTEM_NAME']/$key" -v "$value" "$USER_ES_SYSTEM_CFG"
        else
            value="-"
        fi
        echo "$key: $value"
    done
    dashes=
    for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function create_system_roms_dir() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a path as an argument!" >&2
        exit 1
    fi
    local path="$1"
    log "Creating '$path' ..."
    if [[ ! -d "$path" ]]; then
        mkdir -p "$value" && chown -R "$user":"$user" "$value"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 1 ]]; then
            log "ERROR: Couldn't create '$path'." >&2
        fi
    else
        log "WHOOPS! '$path' already exists."
    fi
    log "Done!"
}


function create_new_system() {
    log "Creating system '$SYSTEM_NAME' ..."
    log
    # Check if <system> exists
    if system_exists "$SYSTEM_NAME"; then
        echo "System '$SYSTEM_NAME' already exists in '$USER_ES_SYSTEM_CFG'."

        exit

        echo
        # Show <system> values
        local message
        message="Current '$SYSTEM_NAME' values:"
        underline "$message"
        for system_property in "${SYSTEM_PROPERTIES[@]}"; do
            local key
            local value
            key="$(echo $system_property | grep  -Eo "^[^ ]+")"
            value="$(echo $system_property | grep -Po "(?<= ).*")"
            if [[ -z "$value" ]]; then
                value="-"
            fi
            echo "$key: $value"
        done
        dashes=
        for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
        echo
        # Ask if the user wants to update <system> values
        echo "Would you like to update '$SYSTEM_NAME' values?"
        local options=("Yes" "No")
        local option
        select option in "${options[@]}"; do
            case "$option" in
                Yes)
                    update_system
                    local return_value
                    return_value="$?"
                    if [[ "$return_value" -eq 0 ]]; then
                        echo
                        echo "Values for '$SYSTEM_NAME' updated successfully!"
                    else
                        echo "ERROR: Couldn't update values for '$SYSTEM_NAME'" >&2
                    fi
                    break
                    ;;
                No)
                    break
                    ;;
                *)
                    echo "Invalid option. Choose a number between 1 and ${#options[@]}." >&2
                    ;;
            esac
        done
    else
        # Create a copy of 'es_system_cfg' if it doesn't exists already.
        copy_es_systems_cfg
        # Create a new <system> called 'newSystem'.
        xmlstarlet ed -L -s "/systemList" -t elem -n "newSystem" -v "" "$USER_ES_SYSTEM_CFG"
        # Add subnodes to <newSystem>.
        for system_property in "${NEW_SYSTEM_PROPERTIES[@]}"; do
            local key
            local value
            key="$(echo $system_property | grep  -Eo "^[^ ]+")"
            value="$(echo $system_property | grep -Po "(?<= ).*")"
            # Check for missing 'name', 'path', 'extension' or 'command'.
            if [[ "$key" == "name" || "$key" == "path" || "$key" == "extension" || "$key" == "command"  ]]; then
                if [[ -z "$key" ]]; then
                    echo "ERROR: System '$SYSTEM_NAME' is missing 'name', 'path', 'extension' or 'command'!" >&2
                    # Remove <newSystem>.
                    xmlstarlet ed -L -d "/systemList/newSystem"  "$USER_ES_SYSTEM_CFG"
                    exit 1
                fi
            fi
            if [[ -n "$value" ]]; then
                xmlstarlet ed -L -s "/systemList/newSystem" -t elem -n "$key" -v "$value" "$USER_ES_SYSTEM_CFG"
                if [[ "$key" == "path" ]]; then
                    # Create the ROM folder for the new system.
                    create_system_roms_dir "$value"
                    # Create the emulators config file for the new system.
                    create_system_emulators_cfg
                fi
            fi
        done
        # Add special tag so we can know it's a system created with this script.
        xmlstarlet ed -L -s "/systemList/newSystem" -t elem -n "createdwith" -v "$SCRIPT_NAME" "$USER_ES_SYSTEM_CFG"
        # Rename <newSystem> to <system>
        xmlstarlet ed -L -r "/systemList/newSystem" -v "system" "$USER_ES_SYSTEM_CFG"
        log
        log "System '$SYSTEM_NAME' created successfully!"
        # local theme
        # theme="$(get_current_theme)"
        # [[ "$theme" == "pixel" ]] && IM_create_new_system_theme
    fi
    log
    log "All Done!"
}


function remove_system() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a system as an argument!" >&2
        exit 1
    fi
    local system="$1"
    local theme
    theme="$(get_current_theme)"
    log "Removing '$system' system ..."
    # Remove system from 'es_system.cfg'
    if xmlstarlet sel -t -v "/systemList/system[name='$system']" "$USER_ES_SYSTEM_CFG" > /dev/null; then
        xmlstarlet ed -L -d "//system[name='$system']" "$USER_ES_SYSTEM_CFG" > /dev/null
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            # Remove system from '/opt/retropie/configs'
            rm -rf "$RP_CONFIG_DIR/$system"
            # Remove system from '/home/pi/RetroPie/roms'
            rm -rf "$RP_ROMS_DIR/$system"
            # Remove system from theme
            rm -rf "$ES_THEMES_DIR/$theme/$system"

            log "'$system' removed successfully!"
        else
            log "ERROR: Couldn't remove system '$system'."
        fi
    else
        log "ERROR: Couldn't remove system '$system'. It doesn't exist!" >&2
    fi
}


function create_system_emulators_cfg() {
    log "Creating '$RP_CONFIG_DIR/$SYSTEM_NAME' ..."
    if [[ ! -d "$RP_CONFIG_DIR/$SYSTEM_NAME" ]]; then
        mkdir -p "$RP_CONFIG_DIR/$SYSTEM_NAME" && chown -R "$user":"$user" "$RP_CONFIG_DIR/$SYSTEM_NAME"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            log "Done!"
        else
            log "ERROR: Couldn't create '$RP_CONFIG_DIR/$SYSTEM_NAME'." >&2
        fi
        log "Creating '$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg' ..."
        touch "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg" && chown -R "$user":"$user" "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            log "Done!"
            add_emulators_to_system_emulators_cfg
        else
            log "ERROR: Couldn't create '$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg'." >&2
        fi
    else
        log "WHOOPS! '$RP_CONFIG_DIR/$SYSTEM_NAME' already exists."
    fi
}


function add_emulators_to_system_emulators_cfg() {
    log "Adding emulators to '$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg' ..."
    for emulator in "${NEW_EMULATORS[@]}"; do
        log "Adding '$emulator' ..."
        cat "$RP_CONFIG_DIR/$emulator/emulators.cfg" >> "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 1 ]]; then
            log "ERROR: Couldn't add '$emulator'." >&2
        fi
        # Remove 'default' emulators
        sed -i '/default/d' "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
    done
    # Remove duplicated lines
    local remove_duplicates
    remove_duplicates="$(awk '!a[$0]++' "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg")"
    echo "$remove_duplicates" > "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
    log "Done!"
}


function create_symbolic_link() {
    if [[ -z "$2" ]]; then
        echo "ERROR: '$FUNCNAME' needs a destination as a a second argument!" >&2
        exit 1
    fi
    local from
    local to
    from="$1"
    to="$2"
    ln -s "$from" "$to"
}


function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    else
        case "$1" in
#H -h, --help                   Show help message.
            -h|--help)
                echo
                underline "$SCRIPT_TITLE"
                echo "$SCRIPT_DESCRIPTION"
                echo
                echo
                echo "USAGE: sudo $0 [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H -g, --gui                    Start the GUI.
            -g|--gui)
                GUI_FLAG=1
                mkdir -p "$LOG_DIR" && chown -R "$user":"$user" "$LOG_DIR"
                touch "$LOG_FILE" && chown -R "$user":"$user" "$LOG_FILE"
                dialog_main
                ;;
#H -v, --version                Show script version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                echo "ERROR: Invalid option '$1'" >&2
                echo "Try 'sudo $0 --help' for more info." >&2
                exit 2
                ;;
        esac
    fi
}


# remove_system "hola"
# exit


function main() {
    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    check_dependencies

    get_options "$@"
}

main "$@"
