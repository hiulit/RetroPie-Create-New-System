#!/usr/bin/env bash
# dialogs.sh

# Variables ############################################

readonly DIALOG_BACKTITLE="$SCRIPT_TITLE"
readonly DIALOG_HEIGHT=20
readonly DIALOG_WIDTH=60
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_HELP=2
readonly DIALOG_EXTRA=3
readonly DIALOG_ESC=255


# Functions ###########################################

function dialog_msgbox() {
    local title="$1"
    local message="$2"
    local dialog_height="$3"
    local dialog_width="$4"
    [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
    [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
    [[ -z "$dialog_height" ]] && dialog_height=8
    [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --ok-label "OK" \
        --msgbox "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_yesno() {
    local title="$1"
    local message="$2"
    local dialog_height="$3"
    local dialog_width="$4"
    [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
    [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
    [[ -z "$dialog_height" ]] && dialog_height=8
    [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --yesno "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_create_new_system() {
    local options=()
    local i=1
    local dialog_items
    local dialog_text
    local cmd
    local form_values

    local field
    for field in "${SYSTEM_FIELDS[@]}"; do
        local value
        value="$(echo ${SYSTEM_PROPERTIES[(($i - 1))]} | grep -Po "(?<= ).*")"
        if is_mandatory_field "$field"; then
            options+=("${field^}*" $i 1 "$value" $i 15 100 0)
        else
            options+=("${field^}" $i 1 "$value" $i 15 100 0)
        fi
        ((i++))
    done

    dialog_items="${#SYSTEM_FIELDS[@]}"
    dialog_text="Create a new system.\n\nFields marked with (*) are mandatory."

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$SCRIPT_TITLE" \
        --cancel-label "Exit" \
        --form "$dialog_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$dialog_items")


    form_values="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq ""$DIALOG_OK ]]; then
        if [[ -n "$form_values" ]]; then
            local i=0
            while read -r line; do
                local key="${SYSTEM_FIELDS[$i]}"
                local value="$line"
                [[ -n "$value" ]] && value="$(trim "$value")"
                NEW_SYSTEM_PROPERTIES+=("$key $value")
                ((i++))
            done <<< "$form_values"
            # Check if 'name, path, extension or command' are set.
            if ! grep -P '(?=.*?name)(?=.*?path)(?=.*?extension)(?=.*?command)^.*$' <<< "${NEW_SYSTEM_PROPERTIES[@]}"; then
                echo "ERROR: System is missing name, path, extension or command!" >&2
                exit
            fi
            local property
            for property in "${NEW_SYSTEM_PROPERTIES[@]}"; do
                local key
                local value
                key="$(echo $property | grep  -Eo "^[^ ]+")"
                value="$(echo $property | grep -Po "(?<= ).*")"
                echo "$key: $value"
            done
        else
            echo "No input!"
        fi
    elif [[ "$return_value" -eq ""$DIALOG_CANCEL ]]; then
        echo "exit"
    fi

}
