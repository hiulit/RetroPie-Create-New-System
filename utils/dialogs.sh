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


function dialog_choose_system_name() {
    SYSTEM_PROPERTIES=()
    local input
    local previous_name

    if [[ -n "$SYSTEM_NAME" ]]; then
        previous_name="\n\nYou previously chose '$SYSTEM_NAME' as the system's name."
    fi

    input="$(dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "Set name" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --inputbox "Enter the system's name.\n\nThis is the short name used by EmulationStation internally, as well as the text used in the EmulationStation UI unless replaced by an image or logo in the theme. It is advised to choose something short and descriptive (e.g. 'favourites', 'hacks').$previous_name" \
                "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
     local return_value="$?"

    if [[ "$return_value" -eq ""$DIALOG_OK ]]; then
        if [[ -n "$input" ]]; then
            if system_exists "$input"; then
                dialog_msgbox "Error!" "'$input' system already exists."
                dialog_choose_system_name
            fi
            if has_space "$input"; then
                dialog_msgbox "Error!" "System's name can't have spaces."
                dialog_choose_system_name
            fi
            SYSTEM_NAME="$input"
            SYSTEM_PATH="$RP_ROMS_DIR/$input"
            SYSTEM_COMMAND="/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ $input %ROM%"
            SYSTEM_THEME="$input"
            SYSTEM_PROPERTIES[0]="name $SYSTEM_NAME"
            SYSTEM_PROPERTIES[2]="path $SYSTEM_PATH"
            SYSTEM_PROPERTIES[4]="command $SYSTEM_COMMAND"
            SYSTEM_PROPERTIES[6]="theme $SYSTEM_THEME"
            dialog_choose_system_fullname
        else
            dialog_msgbox "Error!" "Enter the system's name."
            dialog_choose_system_name
        fi
    elif [[ "$return_value" -eq ""$DIALOG_CANCEL ]]; then
        exit
    fi
}


function dialog_choose_system_fullname() {
    local input
    local previous_fullname

    if [[ -n "$SYSTEM_FULLNAME" ]]; then
        previous_fullname="\n\nYou previously chose '$SYSTEM_FULLNAME' as the system's full name."
    fi

    input="$(dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "Set full name" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --extra-button \
                --extra-label "Back" \
                --inputbox "Enter the system's full name.\n\nThis is the long name used in EmulationStation menus (e.g. 'My favourites games', 'Hacks and homebrew').$previous_fullname" \
                "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
     local return_value="$?"

    if [[ "$return_value" -eq ""$DIALOG_OK ]]; then
        if [[ -n "$input" ]]; then
            SYSTEM_FULLNAME="$input"
            SYSTEM_PROPERTIES[1]="fullname $SYSTEM_FULLNAME"
            dialog_choose_platform
        else
            dialog_msgbox "Error!" "Enter the system's full name."
            dialog_choose_system_fullname
        fi
    elif [[ "$return_value" -eq ""$DIALOG_CANCEL ]]; then
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_system_name
    fi
}

function dialog_choose_platform() {
    local input
    local previous_platform

    if [[ -n "$SYSTEM_PLATFORM" ]]; then
        previous_platform="\n\nYou previously chose '$SYSTEM_PLATFORM' as the system's platform."
    fi

    input="$(dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "Set platform" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --extra-button \
                --extra-label "Back" \
                --inputbox "Enter the system's platform.\n\nThis information is used for scraping.\nThis tag is optional so it may be best to omit it.\nIf you intend to use multiple emulators, for a favourites section for instance, then you can use existing gamelists to manually create a new gamelist.\nIf you are creating a section for mods or hacks, then it's unlikely you'll be able scrape metadata.$previous_platform" \
                "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
     local return_value="$?"

    if [[ "$return_value" -eq ""$DIALOG_OK ]]; then
        if [[ -n "$input" ]]; then
            SYSTEM_PLATFORM="$input"
        else
            SYSTEM_PLATFORM=""
        fi
        SYSTEM_PROPERTIES[5]="platform $SYSTEM_PLATFORM"
        dialog_choose_emulators
    elif [[ "$return_value" -eq ""$DIALOG_CANCEL ]]; then
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_system_fullname
    fi
}


function dialog_choose_emulators() {
    local systems
    local system
    local system_name_extensions=()
    local i=1
    local options=()
    local menu_items
    local menu_text
    local cmd
    local choices
    local choice

    systems="$(get_all_systems)"
    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        options+=("$i" "$system" off)
        ((i++))
    done

    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Select which systems to use in '$SYSTEM_FULLNAME'.\n4 systems maximum."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Select systems" \
        --ok-label "Next" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --checklist "$menu_text" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq ""$DIALOG_OK ]]; then
        if [[ -n "$choices" ]]; then
            IFS=" " read -r -a choices <<< "${choices[@]}"
            if [[ "${#choices[@]}" -gt 4 ]]; then
                dialog_msgbox "Error!" "Choose a maximum of 4 systems."
                dialog_choose_emulators
            else
                for choice in "${choices[@]}"; do
                    system="${options[choice*3-2]}"
                    NEW_EMULATORS+=("$system")
                    system_name_extensions+=("$(xmlstarlet sel -t -v "systemList/system[name='$system']/extension" "$ES_SYSTEMS_CFG" 2> /dev/null)")
                done
                SYSTEM_EXTENSION="${system_name_extensions[@]}"
                SYSTEM_PROPERTIES[3]="extension $SYSTEM_EXTENSION"
                dialog_create_new_system
            fi
        else
            dialog_msgbox "Error!" "Select at least 1 choice."
            dialog_choose_emulators
        fi
    elif [[ "$return_value" -eq ""$DIALOG_CANCEL ]]; then
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_platform
    fi
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
    dialog_text="The new '$SYSTEM_FULLNAME' system is ready to be created!\n\nIf you want to edit a field, you can do so now.\nIf everything is correct, click 'Ok'.\n\nWARNING: If you edit 'Name', you'll have to edit 'Path', 'Command' and 'Theme' accordingly.\n\nFields marked with (*) are mandatory."

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create system" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --form "$dialog_text" "$(((DIALOG_HEIGHT + 2)))" "$DIALOG_WIDTH" "$dialog_items")

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
            if ! grep -q -P '(?=.*?name)(?=.*?path)(?=.*?extension)(?=.*?command)^.*$' <<< "${NEW_SYSTEM_PROPERTIES[@]}"; then
                dialog_msgbox "Error!" "ERROR: '$SYSTEM_FULLNAME' system is missing 'name', 'path', 'extension' or 'command'!"
                dialog_create_new_system
            fi
            local property
            for property in "${NEW_SYSTEM_PROPERTIES[@]}"; do
                local key
                local value
                key="$(echo $property | grep  -Eo "^[^ ]+")"
                value="$(echo $property | grep -Po "(?<= ).*")"
                # Re-check if 'name, path, extension or command' are set.
                if [[ "$key" == "name" || "$key" == "path" || "$key" == "extension" || "$key" == "command" ]]; then
                    if [[ -z "$value" ]]; then
                        dialog_msgbox "Error!" "ERROR: '$SYSTEM_FULLNAME' system is missing 'name', 'path', 'extension' or 'command'!"
                        dialog_create_new_system
                    fi
                fi
                echo "--------------------------"
                echo "$key: $value"
            done
            create_new_system
            create_system_emulators_cfg
            add_emulators_to_system_emulators_cfg
            # IM_create_new_system_assets
        else
            echo "No input!"
        fi
    elif [[ "$return_value" -eq ""$DIALOG_CANCEL ]]; then
        echo "exit"
    fi

}
