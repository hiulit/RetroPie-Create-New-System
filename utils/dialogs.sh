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


function dialog_main() {
    local options=()
    local menu_items
    local menu_title
    local menu_text
    local cmd
    local choice

    options=(
        1 "Create new system"
    )
    if [[ -n "$(get_installed_systems 2> /dev/null)" ]]; then
        options+=(
            2 "Update systems"
            3 "Uninstall systems"
        )
    fi
    menu_items="$(((${#options[@]} / 2)))"
    menu_title="$SCRIPT_TITLE"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$menu_title" \
        --cancel-label "Exit" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                dialog_choose_create_new_system
                ;;
            2)
                dialog_choose_update_system
                ;;
            3)
                dialog_choose_uninstall_system
                ;;
        esac
    else
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    fi
}


function dialog_choose_create_new_system() {
    WIZARD_FLAG=0

    local options=()
    local menu_items
    local menu_title
    local menu_text
    local cmd
    local choice

    options=(
        1 "Wizard setup"
        2 "Advanced setup"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_title="Create new system"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$menu_title" \
        --ok-label "Next" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    WIZARD_FLAG=1
                    dialog_choose_system_name
                    ;;
                2)
                    dialog_create_new_system
                    ;;
            esac
        else
            dialog_msgbox "Error!" "Choose an option."
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_main
    fi
}


function dialog_choose_update_system() {
    local systems
    local system
    local i=1
    local options=()
    local menu_items
    local menu_title
    local menu_text
    local cmd
    local choices
    local choice

    systems="$(get_installed_systems)"
    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        options+=("$i" "$system" off)
        ((i++))
    done

    menu_items="$(((${#options[@]} / 2)))"
    menu_title="Update systems"
    menu_text="Choose which systems to update."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$menu_title" \
        --ok-label "Next" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --checklist "$menu_text" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choices" ]]; then
            IFS=" " read -r -a choices <<< "${choices[@]}"
            for choice in "${choices[@]}"; do
                system="${options[choice*3-2]}"
                update_system "$system"
                dialog_update_system
            done
            local return_value="$?"
            if [[ "$return_value" -eq 0 ]]; then
                dialog_msgbox "Success!" "Systems updated successfully."
            else
                dialog_msgbox "Error!" "Couldn't update some systems..."
            fi
            dialog_main
        else
            dialog_msgbox "Error!" "Choose at least 1 system."
            dialog_choose_update_system
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_main
    fi
}


function dialog_choose_uninstall_system() {
    local systems
    local system
    local i=1
    local options=()
    local menu_items
    local menu_title
    local menu_text
    local cmd
    local choices
    local choice

    systems="$(get_installed_systems)"
    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        options+=("$i" "$system" off)
        ((i++))
    done

    menu_items="$(((${#options[@]} / 2)))"
    menu_title="Uninstall systems"
    menu_text="Choose which systems to uninstall."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$menu_title" \
        --ok-label "Next" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --checklist "$menu_text" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choices" ]]; then
            IFS=" " read -r -a choices <<< "${choices[@]}"
            for choice in "${choices[@]}"; do
                system="${options[choice*3-2]}"
                remove_system "$system"
            done
            local return_value="$?"
            if [[ "$return_value" -eq 0 ]]; then
                dialog_msgbox "Success!" "Systems removed successfully."
            else
                dialog_msgbox "Error!" "Couldn't remove some systems..."
            fi
            dialog_main
        else
            dialog_msgbox "Error!" "Choose at least 1 system."
            dialog_choose_uninstall_system
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_main
    fi
}



function dialog_choose_system_name() {
    SYSTEM_PROPERTIES=()
    local previous_name
    local dialog_title
    local dialog_text
    local input

    if [[ -n "$SYSTEM_NAME" ]]; then
        previous_name="\n\nYou previously chose '$SYSTEM_NAME' as the system's <name>."
    fi

    dialog_title="Wizard setup - <name>"
    dialog_text="Enter the system's <name>.\n\nThis is the short name used by EmulationStation internally, as well as the text used in the EmulationStation UI unless replaced by an image or logo in the theme. It is advised to choose something short and descriptive (e.g. 'favourites', 'hacks').$previous_name"
    input="$(dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "$dialog_title" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --extra-button \
                --extra-label "Back" \
                --inputbox "$dialog_text" \
                "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
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
            dialog_msgbox "Error!" "Enter the system's <name>."
            dialog_choose_system_name
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_create_new_system
    fi
}


function dialog_choose_system_fullname() {
    local previous_fullname
    local dialog_title
    local dialog_text
    local input

    if [[ -n "$SYSTEM_FULLNAME" ]]; then
        previous_fullname="\n\nYou previously chose '$SYSTEM_FULLNAME' as the system's <fullname>."
    fi

    dialog_title="Wizard setup - <fullname>"
    dialog_text="Enter the system's <fullname>.\n\nThis is the long name used in EmulationStation menus (e.g. 'My favourites games', 'Hacks and homebrew').$previous_fullname"
    input="$(dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "$dialog_title" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --extra-button \
                --extra-label "Back" \
                --inputbox "$dialog_text" \
                "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$input" ]]; then
            SYSTEM_FULLNAME="$input"
            SYSTEM_PROPERTIES[1]="fullname $SYSTEM_FULLNAME"
            dialog_choose_platform
        else
            dialog_msgbox "Error!" "Enter the system's <full name>."
            dialog_choose_system_fullname
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_system_name
    fi
}

function dialog_choose_platform() {
    local previous_platform
    local dialog_title
    local dialog_text
    local input

    if [[ -n "$SYSTEM_PLATFORM" ]]; then
        previous_platform="\n\nYou previously chose '$SYSTEM_PLATFORM' as the system's <platform>."
    fi

    dialog_title="Wizard setup - <platform>"
    dialog_text="Enter the system's <platform>.\n\nThis information is used for scraping.\nThis tag is optional so it may be best to omit it.\nIf you intend to use multiple emulators, for a favourites section for instance, then you can use existing gamelists to manually create a new gamelist.\nIf you are creating a section for mods or hacks, then it's unlikely you'll be able scrape metadata.$previous_platform"
    input="$(dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "$dialog_title" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --extra-button \
                --extra-label "Back" \
                --inputbox "$dialog_text" \
                "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$input" ]]; then
            SYSTEM_PLATFORM="$input"
        else
            SYSTEM_PLATFORM=""
        fi
        SYSTEM_PROPERTIES[5]="platform $SYSTEM_PLATFORM"
        dialog_choose_emulators
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_system_fullname
    fi
}


function dialog_choose_emulators() {
    local systems
    local system
    local i=1
    local options=()
    local menu_items
    local menu_title
    local menu_text
    local cmd
    local choices
    local choice
    local system_name_extensions=()

    systems="$(get_all_systems)"
    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        options+=("$i" "$system" off)
        ((i++))
    done

    menu_items="$(((${#options[@]} / 2)))"
    menu_title="Wizard setup - Choose systems"
    menu_text="Choose which systems to use in '$SYSTEM_NAME'.\n\n4 systems maximum."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$menu_title" \
        --ok-label "Next" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --checklist "$menu_text" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
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
            dialog_msgbox "Error!" "Choose at least 1 choice."
            dialog_choose_emulators
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_platform
    fi
}


function dialog_create_new_system() {
    NEW_SYSTEM_PROPERTIES=()

    local options=()
    local i=1
    local dialog_items
    local dialog_title
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
    if [[ "$WIZARD_FLAG" -eq 1 ]]; then
        dialog_title="Wizard setup - Create new system"
    else
        dialog_title="Create new system"
    fi
    if [[ "$WIZARD_FLAG" -eq 1 ]]; then
        dialog_text="The new '$SYSTEM_NAME' system is ready to be created!\n\nIf you want to edit a field, you can do so now.\nIf everything is correct, click 'OK'.\n\nWARNING: If you edit 'Name', you'll have to edit 'Path', 'Command' and 'Theme' accordingly.\n\nFields marked with (*) are mandatory."
    else
        dialog_text="Fields marked with (*) are mandatory.\n\nMore info at: https://github.com/RetroPie/RetroPie-Setup/wiki/Add-a-New-System-in-EmulationStation"
    fi

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$dialog_title" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --form "$dialog_text" "$(((DIALOG_HEIGHT + 2)))" "$DIALOG_WIDTH" "$dialog_items")

    form_values="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
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
                dialog_msgbox "Error!" "System is missing 'name', 'path', 'extension' or 'command'."
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
                        dialog_msgbox "Error!" "System is missing 'name', 'path', 'extension' or 'command'."
                        NEW_SYSTEM_PROPERTIES=()
                        dialog_create_new_system
                    fi
                fi
                if [[ "$key" == "name" ]]; then
                    if [[ -n "$value" ]]; then
                        if system_exists "$value"; then
                            dialog_msgbox "Error!" "System '$value' already exists"
                        fi
                        if has_space "$value"; then
                            dialog_msgbox "Error!" "System's name can't have spaces."
                            SYSTEM_PROPERTIES[0]="name $(echo $value | cut -d' ' -f1)"
                            NEW_SYSTEM_PROPERTIES=()
                            dialog_create_new_system
                        fi
                    fi
                fi
            done

            create_new_system
            SYSTEM_NAME="$(echo ${NEW_SYSTEM_PROPERTIES[0]} | cut -d' ' -f2)"
            dialog_msgbox "Success!" "System '$SYSTEM_NAME' has been created successfully."

            local games
            games="$(get_games)"
            if [[ -n "$games" ]]; then
                dialog_yesno "Add ROMS" "Found ROMS for the system/s ("$(join_by , "${NEW_EMULATORS[@]}")") you have chosen!\n\nWould you like to add them to the newly created '$SYSTEM_NAME' system?" 10
                local return_value="$?"
                if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
                    dialog_choose_games
                fi
            fi
            # Check if EmulationStation is running
            if pidof emulationstation > /dev/null; then
                dialog_yesno "Info" "In order to see the new '$SYSTEM_NAME', EmulationStation need to be restarted.\n\nWould you like to restart EmulationStation?"
                local return_value="$?"
                if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
                    restart_ES
                fi
            else
                dialog_main
            fi
        else
            dialog_msgbox "Error!" "No input."
            dialog_create_new_system
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        if [[ "$WIZARD_FLAG" -eq 1 ]]; then
            dialog_choose_platform
        else
            dialog_choose_create_new_system
        fi
    fi
}


function dialog_update_system() {
    NEW_SYSTEM_PROPERTIES=()

    local options=()
    local i=1
    local dialog_items
    local dialog_title
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
    dialog_title="Update '$(echo ${SYSTEM_PROPERTIES[0]} | cut -d' ' -f2)' system"
    dialog_text="WARNING: If you edit 'Name', you'll have to edit 'Path', 'Command' and 'Theme' accordingly.\n\nFields marked with (*) are mandatory."

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$dialog_title" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --form "$dialog_text" "$(((DIALOG_HEIGHT + 2)))" "$DIALOG_WIDTH" "$dialog_items")

    form_values="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$form_values" ]]; then
            local i=0
            while read -r line; do
                local key
                key="${SYSTEM_FIELDS[$i]}"
                local value
                value="$line"
                [[ -n "$value" ]] && value="$(trim "$value")"
                NEW_SYSTEM_PROPERTIES+=("$key $value")
                ((i++))
            done <<< "$form_values"

            # Check if 'name, path, extension or command' are set.
            if ! grep -q -P '(?=.*?name)(?=.*?path)(?=.*?extension)(?=.*?command)^.*$' <<< "${NEW_SYSTEM_PROPERTIES[@]}"; then
                dialog_msgbox "Error!" "System is missing 'name', 'path', 'extension' or 'command'."
                dialog_update_system
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
                        dialog_msgbox "Error!" "System is missing 'name', 'path', 'extension' or 'command'."
                        NEW_SYSTEM_PROPERTIES=()
                        dialog_update_system
                    fi
                fi
                if [[ "$key" == "name" ]]; then
                    if [[ -n "$value" ]]; then
                        if system_exists "$value"; then
                            dialog_msgbox "Error!" "System '$value' already exists"
                        fi
                        if has_space "$value"; then
                            dialog_msgbox "Error!" "System's name can't have spaces."
                            SYSTEM_PROPERTIES[0]="name $(echo $value | cut -d' ' -f1)"
                            NEW_SYSTEM_PROPERTIES=()
                            dialog_update_system
                        fi
                    fi
                fi
            done

            # Update values
            underline "New values for '$SYSTEM_NAME'"
            for system_property in "${NEW_SYSTEM_PROPERTIES[@]}"; do
                local key
                local value
                key="$(echo $system_property | grep  -Eo "^[^ ]+")"
                value="$(echo $system_property | grep -Po "(?<= ).*")"
                if [[ "$key" == "name" ]]; then
                    local system_name
                    system_name="$(echo ${SYSTEM_PROPERTIES[0]} | cut -d' ' -f2)"
                else
                    local system_name
                    system_name="$(echo ${NEW_SYSTEM_PROPERTIES[0]} | cut -d' ' -f2)"
                fi
                if [[ -n "$value" ]]; then
                    xmlstarlet ed -L -u "/systemList/system[name='$system_name']/$key" -v "$value" "$USER_ES_SYSTEM_CFG"
                    log "<$key>$value</$key>"
                fi
            done
            log
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_update_system
    fi
}


function dialog_choose_games() {
    local options=()
    local emulator
    local i=1
    local dialog_items
    local dialog_title
    local dialog_text
    local cmd
    local choices
    local choice

    for emulator in "${NEW_EMULATORS[@]}"; do
        # Check if folder is not empty.
        if [[ "$(ls -A "$RP_ROMS_DIR/$emulator")" ]]; then
            local rom
            for rom in "$RP_ROMS_DIR/$emulator/"*; do
                local extension
                extension="${rom##*.}"
                # Add roms that match the extension
                if grep -q -P "(?=.*?$extension)^.*$" <<< "${NEW_SYSTEM_PROPERTIES[3]}"; then
                    options+=("$i" "$emulator - $(basename "$rom")" off)
                    ((i++))
                fi
            done
        fi
    done

    dialog_items="${#options[@]}"
    dialog_title="Choose ROMS"
    dialog_text="Choose which ROMS to add to '$SYSTEM_NAME'."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$dialog_title" \
        --ok-label "Next" \
        --cancel-label "Exit" \
        --checklist "$dialog_text" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$dialog_items")

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choices" ]]; then
            IFS=" " read -r -a choices <<< "${choices[@]}"
            local choice
            for choice in "${choices[@]}"; do
                local emulator
                local rom
                emulator="${options[choice*3-2]%% - *}"
                rom="${options[choice*3-2]#* - }"
                create_symbolic_link "$RP_ROMS_DIR/$emulator/$rom" "$RP_ROMS_DIR/$SYSTEM_NAME/$rom"
            done
            dialog_msgbox "Success!" "ROMS added to '$SYSTEM_NAME' successfully."
        else
            dialog_msgbox "Error!" "Choose at least 1 game!"
            dialog_choose_games
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" || "$return_value" -eq "$DIALOG_ESC" ]]; then
        log "Script stopped by the user at $(date +%F\ %T) ... Bye!"
        exit 0
    fi
}
