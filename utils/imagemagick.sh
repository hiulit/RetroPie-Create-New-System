#!/usr/bin/env bash
# imagemagick.sh

function IM_create_new_system_assets() {
    local extension
    local font
    local image_h
    local image_w
    local system
    local system_console
    local system_label
    local system_logo
    local system_logo_text
    local system_text
    local theme
    local system_theme_xml
    local user_console
    local user_system_name

    system="retropie"
    theme="$(get_current_theme)"
    font="$(get_font)"

    system_console="$(get_console)"
    system_logo="$(get_system_logo)"
    system_theme_xml="$(get_theme_xml)"

    extension="${system_console##*.}"
    if [[ "$extension" == "svg" ]]; then
        echo "ERROR: Can't use SVG images... Sorry!"
        exit
    fi

    if [[ "${#EMULATORS[@]}" -gt 4 ]]; then
        echo "ERROR: Maximum number of emulators is 4."
        exit
    fi

    image_h=500
    image_w=500
    system_text="A cande more nauer"
    system_logo_text="New system"
    user_system_name="hh"

    user_console="$ES_THEMES_DIR/$theme/$user_system_name/$(basename "$system_console")"
    user_logo="$ES_THEMES_DIR/$theme/$user_system_name/$(basename "$system_logo")"

    tmp_system_label="$ES_THEMES_DIR/$theme/$user_system_name/tmp-system_label.$extension"
    tmp_composite_image="$ES_THEMES_DIR/$theme/$user_system_name/tmp-multiple-systems.$extension"
    tmp_system_logo="$ES_THEMES_DIR/$theme/$user_system_name/tmp-system-logo.$extension"

    # image_w="$(identify -format "%[fx:w]" "$ES_THEMES_DIR/$theme/$user_system_name/console.$extension")"
    # image_h="$(identify -format "%[fx:h]" "$ES_THEMES_DIR/$theme/$user_system_name/console.$extension")"

    # Create user system folder and copy the 'console', 'system logo' and 'theme xml'.
    mkdir -p "$ES_THEMES_DIR/$theme/$user_system_name"
    cp "$system_console" "$ES_THEMES_DIR/$theme/$user_system_name"
    cp "$system_logo" "$ES_THEMES_DIR/$theme/$user_system_name"
    cp "$system_theme_xml" "$ES_THEMES_DIR/$theme/$user_system_name"

    # Create the system label.
    convert \
        -size "$image_w"x"$(((image_h*25/100)))" \
        canvas:"rgba(0,0,0,0.5)" \
        "$tmp_system_label"

    # Add text to system label.
    convert "$tmp_system_label" \
        -size "$image_w"x"$(((image_h*20/100)))" \
        -background none \
        -fill white \
        -font "$font" \
        -gravity center \
        caption:"$system_text" \
        -composite \
        "$tmp_system_label"

    # Create composite image.
    convert \
        -size "$image_w"x"$image_h" \
        canvas:"transparent" \
        "$tmp_composite_image"

    local emulator
    local i=1
    for emulator in "${EMULATORS[@]}"; do
        local geometry
        local gravity
        local image_h_per
        local image_w_per
        local system
        local system_console
        local tmp_system_image

        system="$emulator"
        system_console="$(get_console)"
        geometry="+0+0"
        gravity="center"
        image_h_per=100
        image_w_per=100
        tmp_system_image="$ES_THEMES_DIR/$theme/$user_system_name/tmp-$system.$extension"


        if [[ "${#EMULATORS[@]}" -eq 2 ]]; then
            geometry="+$(((image_w*5/100)))+0"
            image_w_per=50
            image_h_per=50
             if [[ "$i" -eq 1 ]]; then
                gravity="west"
            elif [[ "$i" -eq 2 ]]; then
                gravity="east"
            fi
        fi
        if [[ "${#EMULATORS[@]}" -eq 3 ]]; then
            image_w_per=50
            image_h_per=50
            if [[ "$i" -eq 1 ]]; then
                gravity="northwest"
            elif [[ "$i" -eq 2 ]]; then
                gravity="northeast"
            elif [[ "$i" -eq 3 ]]; then
                gravity="southwest"
                geometry="+$(((image_w*5/100)))+$(((image_h*25/100)))"
            fi
        fi
        if [[ "${#EMULATORS[@]}" -eq 4 ]]; then
            image_w_per=50
            image_h_per=50
            if [[ "$i" -eq 1 ]]; then
                gravity="northwest"
            elif [[ "$i" -eq 2 ]]; then
                gravity="northeast"
            elif [[ "$i" -eq 3 ]]; then
                gravity="southwest"
                geometry="+$(((image_w*5/100)))+$(((image_h*25/100)))"
            elif [[ "$i" -eq 4 ]]; then
                gravity="southeast"
                geometry="+$(((image_w*5/100)))+$(((image_h*25/100)))"
            fi
        fi

        # Resize the console image.
        convert \
            -scale "$(((image_w*image_w_per/100)))"x"$(((image_h*image_h_per/100)))" \
            "$system_console" "$tmp_system_image"

        # Add the console image to the composite image.
        convert "$tmp_composite_image" "$tmp_system_image" \
            -gravity "$gravity" \
            -geometry "$geometry" \
            -composite \
            "$tmp_composite_image"

        ((i++))
    done

    # Addd the system label to the composite image.
    convert "$tmp_composite_image" "$tmp_system_label" \
        -gravity south \
        -composite \
        "$user_console"

    # Create logo.
    convert \
        -size "$image_w"x"$(((image_h*25/100)))" \
        canvas:"transparent" \
        "$tmp_system_logo"

    # Add text to the logo.
    convert "$tmp_system_logo" \
        -size "$image_w"x"$(((image_h*20/100)))" \
        -background none \
        -fill white \
        -font "$font" \
        -gravity center \
        caption:"$system_logo_text" \
        -composite \
        "$user_logo"

    # Remove temporary files.
    find "$ES_THEMES_DIR/$theme/$user_system_name" -maxdepth 1 -type f  -name 'tmp-*' -delete
}
