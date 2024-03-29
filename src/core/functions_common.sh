#!/usr/bin/env bash
########################################################################################################################
# - Name: Linux Auto-Customizer common functions between install.sh and uninstall.sh.                                  #
# - Description: Set of functions used both in install.sh and uninstall.sh. Some of these functions are used to        #
#   manipulate and interpret the common data structures, others are auxiliar functions used by install.sh and          #
#   uninstall.sh.                                                                                                      #
# - Creation Date: 28/5/19                                                                                             #
# - Last Modified: 17/9/21                                                                                             #
# - Author & Maintainer: Aleix Mariné-Tena                                                                             #
# - Email: aleix.marine@estudiants.urv.cat                                                                             #
# - Permissions: This script can not be executed directly, only sourced to import its functions and process its own    #
#   imports. See the header of each function to see its privilege requirements.                                        #
# - Arguments: No arguments                                                                                            #
# - Usage: Sourced from functions_install.sh or functions_uninstall.sh                                                 #
# - License: GPL v2.0                                                                                                  #
########################################################################################################################


########################################################################################################################
############################################### COMMON API FUNCTIONS ###################################################
########################################################################################################################

# - Description: Executes the command received in argument 1 or prints it with a certain format depending on
#   argument 2, which can be: INFO, WARNING, ERROR, COMMAND.
#   Depending on argument 2 and the global var FLAG_IGNORE_ERRORS we may exit the program. Also, redirect the standard
#   and error output depending on the verbosity level defined in the global var FLAG_QUIETNESS.
# - Permissions: Can be called as root or as normal user presumably with the same behaviour.
# - Argument 1: Bash command to execute.
# - Argument 2: Quietness level [0, 1, 2]:
#   * 0: Full verbose: Display echoes and output from other commands
#   * 1: Quiet: Display echoes but silences output from other commands
#   * 2: Full quiet: No output any executed commands
output_proxy_executioner() {
  if [ "$2" == "INFO" ] || [ "$2" == "WARNING" ] || [ "$2" == "ERROR" ]; then
    if [ "${FLAG_QUIETNESS}" -ne 2 ]; then
      processedMessage=""
      abortProgram=0
      if [ "$2" == "INFO" ]; then
        processedMessage+="\e[36m"  # Activate cyan color
      elif [ "$2" == "WARNING" ]; then
        processedMessage+="\e[33m"  # Activate yellow color
        if [ ${FLAG_IGNORE_ERRORS} -eq 0 ]; then
          abortProgram=1
        fi
      elif [ "$2" == "ERROR" ]; then
        processedMessage+="\e[91m"  # Activate red color
        if [ ${FLAG_IGNORE_ERRORS} -lt 2 ]; then
          abortProgram=1
        fi
      fi
      processedMessage+="$(date +%Y-%m-%d_%T) -- ${2}: $1"
      processedMessage+="\e[0m"  # deactivate color after the echo
      echo -e "${processedMessage}"

      if [ ${abortProgram} -eq 1 ]; then
        output_proxy_executioner "The default behaviour for the previous message specified by the current error tolerance defines that the customizer now must exit, use -i or -w to ignore errors or to ignore warnings if you want to change this behaviour." "INFO"
        exit 1
      fi
    fi
  elif [ "$2" == "COMMAND" ]; then
    if [ "${FLAG_QUIETNESS}" -eq 0 ]; then
      $1
    else
      $1 &>/dev/null
    fi
  else
    output_proxy_executioner "The function output_proxy_executioner does not recognize $2 as a valid argument" "ERROR"
  fi
}

# - Description: Makes a bell sound.
# - Permission: Can be called as root or as user.
bell_sound()
{
  echo -en "\07"
  echo -en "\07"
  echo -en "\07"
}

# - Description: Removes file from system
# - Permissions: This function can be called as root or as user.
# - Argument 1: Absolute path of the file to be removed
remove_file() {
  rm -f "$1"
}


# - Description: Remove folder from system
# - Permissions: This function can be called as root or as user.
# - Argument 1: Absolute path of folder to be removed
remove_folder() {
  rm -Rf "$1"
}

isRoot()
{
  if [ "${EUID}" == 0 ]; then
    return 0
  else
    return 1
  fi
}

# - Description: Receives the file path of a file text which contents will be evaluated by this function to look for
#   variables with the € format (€{variable}) and translate its symbol by the actual value in running memory.
# - Permissions: Needs writing permission to the received file because it will be overwritten in place.
# - Arguments:
#   * Argument 1: Absolute path to the file which will be parsed and its € variables translated.
translate_variables()
{
  if [ ! -f "$1" ]; then
    output_proxy_executioner "The file $1 is not present or is not accessible" "WARNING"
    return
  fi
  detected_variables=($(grep -Eo "€{([A-Z]|[a-z]|_)*}" < "$1" | uniq))
  for variable in "${detected_variables[@]}"; do
    # Obtain only the variable name
    real_variable_name="$(echo "${variable}" | cut -d "{" -f2 | cut -d "}" -f1)"
    # Change variable for its real value
    sed "s@${variable}@${!real_variable_name}@g" -i "$1"
  done
}


# - Description: Apply standard permissions and set owner and group to the user who called root.
# - Permissions: This functions can be called as root or user.
# - Arguments:
#   * Argument 1: Path to the file or directory whose permissions are changed.
#   * Argument 2 (optional): Custom mask of permissions
apply_permissions()
{
  if [ -z "$2" ]; then
    permission_mask="755"
  else
    permission_mask="$2"
  fi

  if [ -f "$1" ]; then
    if isRoot; then  # file
      chgrp "${SUDO_USER}" "$1"
      chown "${SUDO_USER}" "$1"
    fi
    chmod "${permission_mask}" "$1"
  elif [ -d "$1" ]; then
    if isRoot; then  # directory
      chgrp "${SUDO_USER}" "$1"
      chown "${SUDO_USER}" "$1"
    fi
    chmod "${permission_mask}" "$1"
  else
    output_proxy_executioner "The file or directory $1 does not exist and its permissions could not have been changed. Skipping..." "WARNING"
  fi
  unset permission_mask
}


# - Description: Receives a Linux based path (using / as separator) and returns it converted to Windows path using
#   stdout.
# - Permission: Does not need any special permission.
# - Arguments
#   * Argument 1: Linux-based path that will be converted to Windows-based path.
convert_to_windows_path()
{
  echo "$1" | tr "/" "\\\\"
}


# - Description: Sets up a prompt in the desired point of customizer, which is used for in-place debugging. You can
#   input your desired bash statements to run commands, declare installations or call functions defined in the runtime
#   environment of the customizer.
# - Permission: Can be run as root or user.
customizer_prompt()
{
  while true; do
    read -p "customizer-prompt $ " -r cmds
    eval "${cmds}"
  done
}


# - Description: Receives an string, a separator and a position and returns the selected field via stdout
# - Permission: Can be called as root or user.
# - Argument 1: String containing fields
# - Argument 2: Separator of the fields
# - Argument 3: Field position to get
get_field()
{
  echo -n "$1" | cut -d "$2" -f"$3"
}


# - Description: Receives an string, a separator and a position and returns the same string with the selected field
#   changed with the desired value. To do that obtains the value in position and cuts from that position to the
#   beginning and from that position to the end. Then, delete the old value from these two substrings and joins them
#   with the desired value in between. Returns the new string via stdout.
# - Permission: Can be called as root or user.
# - Argument 1: String containing fields
# - Argument 2: Separator of the fields
# - Argument 3: Field position to set
# - Argument 4: Value to set
set_field()
{
  local -r value_in_pos="$(get_field "$1" "$2" "$3")"
  echo -n "$(echo "$1" | cut -d "$2" -f-"$3" | sed "s@${value_in_pos}\$@@g")$4$(echo "$1" | cut -d "$2" -f"$3"- | sed "s@^${value_in_pos}@@g")"
}


# - Description: Function to delete a concrete line of a file.
# - Permissions: can be executed indifferently as root or user.
# - Argument 1: Text to be removed.
# - Argument 2: Path to the file which contains the text to be removed.
remove_line()
{
  if [ -f "$2" ]; then
    sed "s@^$1\$@@g" -i "$2"
  else
    output_proxy_executioner "file $2 is not present, so the text $1 cannot be removed from the file. Skipping..." "WARNING"
  fi
}


# - Description: Function to append text to a file if the text is not already present.
# - Permissions: Can be executed indifferently as root or user, but we need read/write access to the file.
# - Argument 1: Text to be added.
# - Argument 2: Path to the file where we will append the text.
append_text()
{
  # If there is not a literal match: (grep -E ^LITERAL_MATCH\$) append to the file.
  if ! grep -Eqo "^$1\$" "$2"; then
    echo -e "$1" >> "$2"
  fi
}


# - Description: Generate the list that contains the list of included programs for each wrapper.
# - Permissions: Can be executed indifferently as root or user.
# - Arguments: Reads the tags property of each feature and maps that feature to a wrapper with the name of each tag.
generate_wrappers()
{
  declare -Ag WRAPPERS_KEYNAMES
  for feature_name in "${feature_keynames[@]}"; do
    load_feature_properties "${feature_name}"

    # Use tags to fill wrappers dictionary
    tags_pointer="${feature_name}_tags[@]"
    for tag in ${!tags_pointer}; do
      if [[ -v WRAPPERS_KEYNAMES["${tag}"] ]]; then
        WRAPPERS_KEYNAMES[$tag]+=" ${feature_name}"
      else
        WRAPPERS_KEYNAMES[$tag]="${feature_name}"
      fi
    done

    # Use system categories to fill wrappers dictionary
    categories_pointer="${feature_name}_systemcategories[@]"
    for category in ${!categories_pointer}; do
      if [[ -v WRAPPERS_KEYNAMES["${category}"] ]]; then
        WRAPPERS_KEYNAMES[${category}]+=" ${feature_name}"
      else
        WRAPPERS_KEYNAMES[${category}]="${feature_name}"
      fi
    done
  done
}


# - Description: Prints the list that contains the list of included programs for each wrapper.
# - Permissions: Can be executed indifferently as root or user.
display_wrappers()
{
  for key in $(echo "${!WRAPPERS_KEYNAMES[@]}" | tr ' ' $'\n' | sort -h); do
    echo "Tag: ${key} --- Feature: ${WRAPPERS_KEYNAMES[$key]}"
  done
}


# - Description: Load properties from a feature received in the first argument as a keyname
# - Permissions: Can be executed indifferently as root or user.
load_feature_properties()
{
    # Load metadata of the feature if its .dat file exists
    if [ -f "${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.dat.sh" ]; then
      source "${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.dat.sh"

      # If we find the property manual_content_available declared, we should import the function file too
      local -r manualContentPointer="$1_manualcontentavailable"
      if [ -n "${!manualContentPointer}" ]; then
        if [ -f "${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.func.sh" ]; then
          source "${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.func.sh"
        fi
      fi
    else
      output_proxy_executioner "Properties of $1 feature have not been loaded. The file ${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.dat.sh does not exist" "ERROR"
    fi
}


# - Description: Unloads properties loaded from the ${FEATURE_KEYNAME}.dat.sh and functions from the
#   ${FEATURE_KEYNAME}.func.sh
# - Permissions: Can be executed indifferently as root or user.
# - Argument 1: Keyname of the properties to unload.
unload_feature_properties()
{
    # Unload functions
    unset -f "$1_install_pre"
    unset -f "$1_install_mid"
    unset -f "$1_install_post"
    unset -f "$1_uninstall_pre"
    unset -f "$1_uninstall_mid"
    unset -f "$1_uninstall_post"

    # Unload properties from the .dat.sh
    if [ -f "${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.dat.sh" ]; then
      # Select non-commentary lines
      while read -r line; do
        local variable
        variable="$(echo "${line}" | grep -v "^[[:blank:]]*#" | cut -d "=" -f1)"
        if [ -z "${variable}" ]; then
          continue
        fi
        unset "${variable}"
      done < "${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.dat.sh"
    else
      output_proxy_executioner "Properties of $1 feature have not been found, so they can not be unloaded. The file
${CUSTOMIZER_PROJECT_FOLDER}/data/features/$1/$1.dat.sh does not exist. " "ERROR"
    fi

    # Finally unset ${FEATURENAME}_flagsruntime, which is a dynamically declared variable
    unset "$1_flagsruntime"
}


# - Description: Performs a post-install clean by using cleaning option of package manager
# - Permission: Can be called as root or user.
post_install_clean()
{
  if isRoot; then
    if [ "${FLAG_AUTOCLEAN}" -gt 0 ]; then
      output_proxy_executioner "Attempting to clean orphaned dependencies and useless packages via ${DEFAULT_PACKAGE_MANAGER}." "INFO"
      output_proxy_executioner "${PACKAGE_MANAGER_AUTOCLEAN}" "COMMAND"
      output_proxy_executioner "Finished." "INFO"
    fi
    if [ "${FLAG_AUTOCLEAN}" -eq 2 ]; then
      output_proxy_executioner "Attempting to clean orphaned dependencies and useless packages via ${DEFAULT_PACKAGE_MANAGER}." "INFO"
      output_proxy_executioner "${PACKAGE_MANAGER_AUTOREMOVE}" "COMMAND"
      output_proxy_executioner "Finished." "INFO"
    fi
  fi
}


# - Description: Updates the system by using the package manager
# - Permission: Can be called as root or as user.
update_environment()
{
  output_proxy_executioner "Rebuilding path cache" "INFO"
  output_proxy_executioner "hash -r" "COMMAND"
  output_proxy_executioner "Rebuilding font cache" "INFO"
  output_proxy_executioner "fc-cache -f" "COMMAND"
  output_proxy_executioner "Reload .bashrc shell environment" "INFO"
  output_proxy_executioner "source ${FUNCTIONS_PATH}" "COMMAND"
}


# - Description: Ensures that the customizer_options.sh is present and sources it into the customizer environment.
# - Permission: Can be called as root or user.
import_custom_options()
{
  if [ -f "${DATA_FOLDER}/customizer_options.sh" ]; then
    source "${DATA_FOLDER}/customizer_options.sh"
  fi
}


# - Description: Prints to standard output a table that contains all the arguments that customizer accepts along with
#   the commands that installs.
# - Permissions: Can be called as root or user with the same behaviour.
autogen_help()
{
  # TODO: create autogen_help with new metadata
  echo
}


# - Description: Generates the file table.md in the pwd directory. This table contains all the readme lines property of
#   each feature. This lines are previously processed and filled with the arguments, which are defined in another
#   property.
# - Privileges: Can be called as root or user and will generate the same file but with the corresponding chmod
#   permissions to a privileges or non-privileged user.
autogen_readme()
{
  local features_table_lines="
| Icon | Name | Arguments | Description | Execution |
|-------------|----------------------|------------------------------------------------------|------------|-------------|"
  local github_url="https://media.githubusercontent.com/media/AleixMT/Linux-Auto-Customizer/master"
  local html_prefix="<img src=\""
  local html_suffix="\" width=\"200\" height=\"200\" />"
  local icon_path=""
  for keyname in "${feature_keynames[@]}"; do
    load_feature_properties "${keyname}"
    local arguments_pointer="${keyname}_arguments[@]"
    local name_pointer="${keyname}_name"

    local icon_path="$(readme_deduce_icon "${keyname}")"
    icon_value="${html_prefix}${github_url}${icon_path}${html_suffix}"

    local description_pointer="${keyname}_description"

    local usage_value="- Binaries in Path: "
    local binaries_pointers="${keyname}_binariesinstalledpaths[@]"
    for binary in "${!binaries_pointers}"; do
      usage_value+="$(echo "${binary}" | cut -d ';' -f2), "
    done

    filekey_path=""
    usage_value+="- Functions in shell environment: "
    local filekeys_pointers="${keyname}_filekeys[@]"
    local feature_function_names=""
    for filekey in "${!filekeys_pointers}"; do
      filekey_name="${keyname}_${filekey}_content"

      feature_function_names="$(cat "${CUSTOMIZER_PROJECT_FOLDER}/data/features/${keyname}/${!filekey_name}" | grep -Eo "^([a-z]|[A-Z])+([a-z]|[A-Z]|_)*\\(\\)" | uniq)"

      for feature_function_name in "${feature_function_names}"; do
        # Append name without parenthesis
        usage_value+="$(echo "${feature_function_name}" | grep -Eo "^([a-z]|[A-Z])+([a-z]|[A-Z]|_)*"), "
      done
    done

    local usage_value+="- Keyboard shortcuts: "
    local shortcuts_pointers="${keyname}_binariesinstalledpaths[@]"
    for shortcut_keyboard in "${!shortcuts_pointers}"; do
      usage_value+="$(echo "${shortcut_keyboard}" | cut -d ';' -f2), "
    done

    features_table_lines+=$'\n'"| ${icon_value} | ${!name_pointer} | ${!arguments_pointer} | ${!description_pointer} | ${usage_value} |"
    unload_feature_properties "${keyname}"
  done


  features_table_lines+=$'\n'"Customizer currently has available $(echo "${feature_keynames[@]}" | wc -w) features."
  echo "${features_table_lines}" > "${CUSTOMIZER_PROJECT_FOLDER}/doc/FEATURES.md"
}


# - Description: Loads another set of calls for a certain package manager defined in $1_package_manager_override
generic_package_manager_override() {
  # Other dependencies to install with the package manager before the main package of software if present
  local -r package_manager_override="$1_package_manager_override"
  if [ -n "${!package_manager_override}" ]; then
    # An override is defined
    if [ "${!package_manager_override}" == "${DEFAULT_PACKAGE_MANAGER}" ]; then
      # The override is the same package manager that we have, skip loading config
      return
    else
      # Check if the desired package to override is in the supported package managers list
      for recognised_package_manager in "${RECOGNISED_PACKAGE_MANAGERS[@]}"; do
        if [ "${recognised_package_manager}" == "${!package_manager_override}" ]; then
          # Load config for the package manager and save the previous conf, also raise the flag to undo this changes at
          # the end of this installation
          STACKED_PACKAGE_MANAGER="${DEFAULT_PACKAGE_MANAGER}"
          POP_PACKAGE_MANAGER=1
          "initialize_package_manager_${!package_manager_override}"
          return
        fi
      done
      output_proxy_executioner "${!package_manager_override} is not a recognised package manager, so its
  configuration will not be loaded. Variable $1_package_manager_override needs to be one of the following elements:
  ${RECOGNISED_PACKAGE_MANAGERS[*]}" "ERROR"
      exit 1
    fi
  fi
}


# - Description: Get another unique string using the first argument as current element. The first argument is to be
#   expected as an integer, an empty string or nothing:
#   - if is an integer: return next integer
#   - if is empty string: return string "2"
#   - if nothing: return empty string
# - Permission: Can be called as root or user.
# - Argument 1: Current anticollisioner number
get_next_collisioner()
{
  if [ $# -eq 0 ]; then
    echo ""
  elif [ -z "$1" ]; then
    echo "2"
  elif echo "$1" | grep -Eqo "[0-9]+"; then
    echo "$((1 + $1))"
  else
    output_proxy_executioner "Unexpected input in get_next_collisioner(): $1" "ERROR"
  fi
}


########################################################################################################################
############################################### COMMON MAIN FUNCTIONS ##################################################
########################################################################################################################

# - Description: Processes the arguments received from the outside and activates or deactivates flags and calls
#   add_program to append a keyname to the list of features to install.
# - Permission: Can be called as root or user.
# - Argument 1, 2, 3... : Arguments for the whole program.
argument_processing()
{
  while [ $# -gt 0 ]; do
    key="$1"

    case "${key}" in
      ### BEHAVIOURAL ARGUMENTS ###
      -v|--verbose)
        FLAG_QUIETNESS=0
      ;;
      -q|--quiet)
        FLAG_QUIETNESS=1
      ;;
      -Q|--Quiet)
        FLAG_QUIETNESS=2
      ;;

      -s|--skip|--skip-if-installed)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          output_proxy_executioner "You have set to not overwrite features in uninstall mode, this will uninstall only the features that are not installed." "WARNING"
        fi
        FLAG_OVERWRITE=0
      ;;
      -o|--overwrite|--overwrite-if-present)
        FLAG_OVERWRITE=1
      ;;

      -w|--warning|--exit-on-warning)
        FLAG_IGNORE_ERRORS=0
      ;;
      -e|--exit|--exit-on-error)
        FLAG_IGNORE_ERRORS=1
      ;;
      -i|--ignore|--ignore-errors)
        FLAG_IGNORE_ERRORS=2
      ;;

      # TODO flag autoclean reduce to two states
      -c|--clean)
        FLAG_AUTOCLEAN=0
      ;;
      -C|--Clean)
        FLAG_AUTOCLEAN=2
      ;;

      -k|--keep-system-outdated)
        FLAG_UPGRADE=0
      ;;
      -u|--update)
        FLAG_UPGRADE=1
      ;;
      -U|--upgrade|--Upgrade)
        FLAG_UPGRADE=2
      ;;

      -f|--favorites|--set-favorites)
        FLAG_FAVORITES=1
      ;;
      -z|--no-favorites)
        FLAG_FAVORITES=0
      ;;

      -a|--autostart)
        FLAG_AUTOSTART=1
      ;;
      -r|--regular)
        FLAG_AUTOSTART=0
      ;;

      -n|--not)
        FLAG_INSTALL=0
      ;;
      -y|--yes)
        FLAG_INSTALL=1
      ;;

      -p|--privilege-check)
        FLAG_SKIP_PRIVILEGES_CHECK=0
      ;;
      -P|--skip-privilege-check)
        FLAG_SKIP_PRIVILEGES_CHECK=1
      ;;

      -t|--not-cached)
        FLAG_CACHE=0
      ;;
      -T|--cached|--cache|--use-cache)
        FLAG_CACHE=1
      ;;

      -O|--Overrides|--allow-overrides)
        FLAG_PACKAGE_MANAGER_ALLOW_OVERRIDES=1
      ;;
      -x)
        FLAG_PACKAGE_MANAGER_ALLOW_OVERRIDES=0
      ;;

      # TODO propagate state to each installation, so it follow s the customizer convention of state machine
      -d|--dependencies)
        FLAG_IGNORE_DEPENDENCIES=0
      ;;
      -D|--ignore-dependencies)
        FLAG_IGNORE_DEPENDENCIES=1
      ;;

      --commands)  # Print list of possible arguments and finish the program
        local all_arguments+=("${feature_keynames[@]}")
        all_arguments+=("${auxiliary_arguments[@]}")
        all_arguments+=("${WRAPPERS_KEYNAMES[@]}")
        echo "${all_arguments[@]}"
        exit 0
      ;;

      --readme|readme|features|FEATURES|FEATURES.sh|features.sh)
        # Print list of possible arguments and finish the program
        autogen_readme
        exit 0
      ;;

      -h)
        output_proxy_executioner "echo ${help_common}${help_simple}" "COMMAND"
        exit 0
      ;;
      -H|--help)
        output_proxy_executioner "echo ${help_common}${help_arguments}${help_individual_arguments_header}$(autogen_help)${help_wrappers}" "COMMAND"
        exit 0
      ;;

      --show-wrappers)
        generate_wrappers
        display_wrappers
        exit 0
      ;;

      --debug)
        customizer_prompt
      ;;

      --user|--normal)
        add_programs_with_x_permissions 1
      ;;
      --root|--superuser|--su)
        add_programs_with_x_permissions 0
      ;;
      --ALL|--all|--All)
        add_programs_with_x_permissions 2
      ;;

      --flush=favorites)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          remove_all_favorites
        fi
      ;;

      --flush=keybindings)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          remove_all_keybindings
        fi
      ;;

      --flush=functions)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          remove_all_functions
        fi
      ;;

      --flush=initializations)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          remove_all_initializations
        fi
      ;;

      --flush=structures)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          remove_structures
        fi
      ;;

      --flush=cache)
        if [ "${FLAG_MODE}" == "uninstall" ]; then
          rm -Rf "${CACHE_FOLDER}"
        fi
      ;;

      *)
        # Individual argument
        # A feature key name was not detected in the current argument ${key}. Try a wrapper.
        # But first check that the argument has characters and also check that those characters are valid characters
        # for a variable in bash (regexp [a-zA-Z_][a-zA-Z_0-9]*, which is equal to any string using alphanumeric
        # characters beginning with ant alphabetic characters and containing underscores at any position)
        if [ -z "${key}" ] || ! echo "${key}" | grep -Eqo "^[aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_][aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_0-9]*$"; then
          output_proxy_executioner "The current argument \"${key}\" is empty or not valid" "WARNING"
          shift
          continue
        fi
        # Indirect expand wrapper variable
        generate_wrappers  # Fill WRAPPERS_KEYNAMES dictionary
        local wrapper_key
        wrapper_key="$(echo "${key}" | tr "-" "_")"
        local set_of_features="${WRAPPERS_KEYNAMES[${wrapper_key}]}"
        if [ -z "${set_of_features}" ]; then
          # If there are no wrappers corresponding with this key, the last possibility is that the key is actually a
          # feature keyname, which we try to add to installation.
          add_program "${key}"
        else
          # There is a wrapper corresponding with this key, so we add each program that is in the wrapper.
          add_programs "${set_of_features}"
        fi
      ;;
    esac
    shift
  done

  # If we don't receive arguments we try to install everything that we can given our permissions
  if [ ${#added_feature_keynames[@]} -eq 0 ]; then
    output_proxy_executioner "No arguments provided to install feature. Use -h or --help to display information about \
usage. Aborting..." "ERROR"
    return
  fi
}


add_programs_with_x_permissions()
{
  for i in "${feature_keynames[@]}"; do
    if [ "$1" -ne 2 ]; then
      flag_privileges="$(deduce_privileges "${matched_keyname}")"
      if [ "$1" -eq "${flag_privileges}" ]; then
        add_program "$i"
      fi
    else
      add_program "$i"
    fi
  done
}


# - Description: Accepts N individual arguments representing feature keynames and adds them to the installation.
#   Useful for adding many arguments at the same time, like with a wrapper.
# - Permission: Can be called as root or as user.
# - Argument 1: Feature keyname to be added.
# - Argument 2, 3, 4... : Feature keyname to be added
add_programs()
{
  while [ $# -gt 0 ]; do
    add_program "$1"
    shift
  done
}

deduce_privileges()
{
  local -r flags_override_pointer="$1_flagsoverride"
  local flags_override_stringbuild=""
  if [ -n "${!flags_override_pointer}" ]; then  # If flagsoverride property is defined for this feature
    flags_override_stringbuild="${!flags_override_pointer}"
  else  # flagsoverride not defined, load template
    flags_override_stringbuild="${flagsoverride_template}"
  fi

  # The first flag indicates override permissions. Process FLAG_SKIP_PRIVILEGES_CHECK in here
  local flag_privileges=
  flag_privileges="$(get_field "${flags_override_stringbuild}" ";" "1")"
  if [ -z "${flag_privileges}" ]; then
    # If override not present, check if we need to use a package manager or install a package to deduce if we need
    # special permissions
    local -r packageNames="$1_packagenames"
    local -r downloadKeys="$1_downloadKeys[*]"
    # If there are needed dependencies, do not consider them when determining the permissions needed for the features
    # local -r dependencies="$1_packagedependencies[*]"
    if [ -n "${!packageNames}" ]; then
      flag_privileges=0
    # elif [ -n "${!dependencies}" ]; then
    #   flag_privileges=0
    elif [ -n "${!downloadKeys}" ]; then
      # We do not enforce require permissions unless we see a package download type
      local special_permission=0
      for downloadKey in ${!downloadKeys}; do
        local download_type="$1_${downloadKey}_type"
        if [ "${download_type}" == "package" ]; then
          special_permission=1
        fi
      done
      if [ "${special_permission}" -eq 1 ]; then
        flag_privileges=0
      else
        flag_privileges=2
      fi
    else
      flag_privileges=2
    fi
  fi
  echo "${flag_privileges}"
}


# - Description: Receives an argument and add or remove the corresponding feature for that argument to the installation
#   list. Also, if adding the installation of a program, save the current state of the flags, taking in account the flag
#   states that have to be overwritten. Some flags are processed in here, while others are "passed" indirectly to
#   execute_installation.
# - Permission: Can be called indistinctly as root or user with same behaviour.
# - Argument 1: Outside argument that can match a feature keyname (fast match with binary search) or an argument (slow
#   match looping through all the arguments, obtained by indirect expansion using every feature keyname)
add_program()
{
  local matched_keyname=""
  # fast match against keynames
  local processed_argument=
  processed_argument="$(echo "$1" | tr "-" "_")"  # Convert - to _
  for keyname in "${feature_keynames[@]}"; do
    if [ "${processed_argument//^_*/}" == "${keyname}" ]; then
      matched_keyname="${keyname}"
      break
    fi
  done

  # Try fuzzy match but with restrictions: We do not fuze caps
  if [ -z "${matched_keyname}" ]; then
    # We did not achieve fast match. Loop through elements in all arguments property of all features looking for match
    processed_argument="$(echo "${processed_argument}")"  # Literal match
    for keyname in "${feature_keynames[@]}"; do
      local arguments_pointer="${keyname}_arguments[@]"
      for argument in "${!arguments_pointer}"; do  # Expand arguments of each feature using feature_keyname
        if [ "${argument}" == "${processed_argument}" ] || [ "$(echo "${argument}" | tr -d "_")" == "$(echo "${processed_argument}" | tr -d "_")" ]; then  # Flexible match
          matched_keyname="${keyname}"  # Save the match
          break  # Break the inner loop
        fi
      done
      if [ -n "${matched_keyname}" ]; then  # If we have already matched something  break external loop and continue
        break
      fi
    done
  fi

  # Try fuzzy match
  if [ -z "${matched_keyname}" ]; then
    # We did not achieve fast match. Loop through elements in all arguments property of all features looking for match
    processed_argument="$(echo "${processed_argument}" | tr '[:upper:]' '[:lower:]')"  # Convert to lowercase
    for keyname in "${feature_keynames[@]}"; do
      local arguments_pointer="${keyname}_arguments[@]"
      for argument in "${!arguments_pointer}"; do  # Expand arguments of each feature using feature_keyname
        if [ "${argument}" == "${processed_argument}" ] || [ "$(echo "${argument}" | tr -d "_")" == "$(echo "${processed_argument}" | tr -d "_")" ] ; then  # Flexible match
          matched_keyname="${keyname}"  # Save the match
          break  # Break the inner loop
        fi
      done
      if [ -n "${matched_keyname}" ]; then  # If we have already matched something  break external loop and continue
        break
      fi
    done
  fi


  # If we do not have a match after checking all args, this arg is not valid
  if [ -z "${matched_keyname}" ]; then
    output_proxy_executioner "$1 is not a recognized command, skipping to next argument" "WARNING"
    return
  fi

  # Here matched_keyname matches a valid feature. Process its flagsoverride and add or remove from added_feature_keynames
  if [ "${FLAG_INSTALL}" == 1 ]; then
    # First process FLAG_PACKAGE_MANAGER_ALLOW_OVERRIDES, which is not included in the flagsoverride
    if [ ${FLAG_PACKAGE_MANAGER_ALLOW_OVERRIDES} -eq 0 ]; then
      # Check if there is an override and if it is different from the current package manager
      local -r package_manager_override="${matched_keyname}_package_manager_override"
      if [ -n "${!package_manager_override}" ] && [ "${!package_manager_override}" != "${DEFAULT_PACKAGE_MANAGER}" ]; then
        output_proxy_executioner "A change in the default package managers to perform installations is required to install ${matched_keyname}, use -O to allow overrides. Skipping this feature..." "WARNING"
        return
      fi
    fi

    # Addition mode, we need to add keyname to added_feature_keynames and build flags
    local -r flags_override_pointer="${matched_keyname}_flagsoverride"
    local flags_override_stringbuild=""
    if [ -n "${!flags_override_pointer}" ]; then  # If flagsoverride property is defined for this feature
      flags_override_stringbuild="${!flags_override_pointer}"
    else  # flagsoverride not defined, load template
      flags_override_stringbuild="${flagsoverride_template}"
    fi

    # The first flag indicates override permissions. Process FLAG_SKIP_PRIVILEGES_CHECK in here
    local flag_privileges=
    flag_privileges="$(deduce_privileges "${matched_keyname}")"
    # Process FLAG_SKIP_PRIVILEGES_CHECK. If 1 skip privilege check
    if [ "${FLAG_SKIP_PRIVILEGES_CHECK}" -eq 0 ] && [ "${flag_privileges}" -ne 2 ]; then
      if isRoot && [ "${flag_privileges}" -eq 1 ]; then
        output_proxy_executioner "$1 enforces user permissions to be executed. Rerun without root privileges or use -P to avoid this behaviour. Skipping this program..." "ERROR"
      fi
      if ! isRoot && [ "${flag_privileges}" -eq 0 ]; then
        output_proxy_executioner "$1 enforces root permissions to be executed. Rerun with root privileges or use -P to avoid this behaviour. Skipping this program..." "ERROR"
      fi
    fi
    # No need to pass to the execute installation the permissions of each feature, they are already processed here
    # flags_override_stringbuild="$(set_field "${flags_override_stringbuild}" ";" "1" "${flag_privileges}")"

    # Second flag overwrite bit
    local flag_overwrite=
    flag_overwrite="$(get_field "${flags_override_stringbuild}" ";" "2")"
    if [ -z "${flag_overwrite}" ]; then
      flag_overwrite="${FLAG_OVERWRITE}"  # If not present in override, inherit from runtime flags
    fi
    # No need to pass to the execute installation the override, it can be processed here
    # Process flag_overwrite. if installation is already present show error
    if [ "${flag_overwrite}" -eq 0 ]; then
      # Change of _ to - again to allow the matches of commands that have - in its name
      if grep -qE "^${matched_keyname}\$" < "${INSTALLED_FEATURES}"; then
        output_proxy_executioner "${matched_keyname} is installed. Continuing installation without selecting this feature... Use -o to skip this behaviour and select this feature." "WARNING"
        return 1
      fi
    fi

    # Third flag ignore errors
    local flag_errors=
    flag_errors="$(get_field "${flags_override_stringbuild}" ";" "3")"
    if [ -z "${flag_errors}" ]; then
      flag_errors="${FLAG_IGNORE_ERRORS}"  # If not present in override, inherit from runtime flags
    fi
    flags_override_stringbuild="$(set_field "${flags_override_stringbuild}" ";" "3" "${flag_errors}")"

    # Fourth flag quietness bit
    local flag_quietness=
    flag_quietness="$(get_field "${flags_override_stringbuild}" ";" "4")"
    if [ -z "${flag_quietness}" ]; then
      flag_quietness="${FLAG_QUIETNESS}"  # If not present in override, inherit from runtime flags
    fi
    flags_override_stringbuild="$(set_field "${flags_override_stringbuild}" ";" "4" "${flag_quietness}")"

    # Fifth flag favorites bit
    local flag_favorites=
    flag_favorites="$(get_field "${flags_override_stringbuild}" ";" "5")"
    if [ -z "${flag_favorites}" ]; then
      flag_favorites="${FLAG_FAVORITES}"  # If not present in override, inherit from runtime flags
    fi
    flags_override_stringbuild="$(set_field "${flags_override_stringbuild}" ";" "5" "${flag_favorites}")"

    # Sixth flag autostart
    local flag_autostart=
    flag_autostart="$(get_field "${flags_override_stringbuild}" ";" "6")"
    if [ -z "${flag_autostart}" ]; then
      flag_autostart="${FLAG_AUTOSTART}"  # If not present in override, inherit from runtime flags
    fi
    flags_override_stringbuild="$(set_field "${flags_override_stringbuild}" ";" "6" "${flag_autostart}")"

    # At this point flags_override_stringbuild have all flags merged inside (override and runtime)

    # Declare runtime flags for accession in execute_feature
    declare -g "${matched_keyname}_flagsruntime=${flags_override_stringbuild}"
    # Add this feature in the result list
    added_feature_keynames+=("${matched_keyname}")
  else
    # Deletion mode

    # Delete from the result array
    for i in "${!added_feature_keynames[@]}"; do
      if [ "${added_feature_keynames[i]}" == "${matched_keyname}" ]; then
        unset "added_feature_keynames[${i}]"
      fi
    done
    added_feature_keynames=("${added_feature_keynames[@]}")
  fi
}


# - Description: Reads the array added_feature_keynames where are stored the keynames of features that have to be
#   installed, interprets or delegates the flags and runs the generic_(un)install
# - Permission: Can be called indistinctly as root or user but it can skip or show error if the permissions do not
#   coincide with the required ones.
execute_installation()
{
  # flagsruntime ${FLAG_IGNORE_ERRORS};${FLAG_QUIETNESS};${FLAG_FAVORITES};${FLAG_AUTOSTART}
  for keyname in "${added_feature_keynames[@]}"; do
    local flags_pointer="${keyname}_flagsruntime"
    local flag_ignore_errors=
    flag_ignore_errors="$(get_field "${!flags_pointer}" ";" "3")"  # local, processed here
    FLAG_QUIETNESS="$(get_field "${!flags_pointer}" ";" "4")"  # Global, so it can be accessed during installations
    FLAG_FAVORITES="$(get_field "${!flags_pointer}" ";" "5")"  # Global, accessed in generic_install
    FLAG_AUTOSTART="$(get_field "${!flags_pointer}" ";" "6")"  # Global, accessed in generic_install
    # Process flag_ignore_errors
    if [ "${flag_ignore_errors}" -eq 0 ]; then
      set -e
    fi

    CURRENT_INSTALLATION_FOLDER="${BIN_FOLDER}/${keyname}"
    CURRENT_INSTALLATION_KEYNAME="${keyname}"

    output_proxy_executioner "Attemptying to ${FLAG_MODE} ${keyname}." "INFO"

    load_feature_properties "${CURRENT_INSTALLATION_KEYNAME}"

    output_proxy_executioner "generic_installation ${keyname}" "COMMAND"

    unload_feature_properties "${CURRENT_INSTALLATION_KEYNAME}"

    output_proxy_executioner "${keyname} ${FLAG_MODE}ed." "INFO"

    # Return flag errors to bash defaults (ignore errors)
    set +e
  done
}


########################################################################################################################
################################################## GENERIC INSTALL #####################################################
########################################################################################################################

# - Description: Installs a user program in a generic way relying on variables declared in feature_data.sh and the name
#   of a feature. The corresponding data has to be declared following the pattern %FEATURENAME_%PROPERTIES. This is
#   because indirect expansion is used to obtain the data to install each feature of a certain program to install.
#   Depending on the properties set, some subfunctions will be activated to install related features.
#   Also performs the manual execution of paths of the feature and calls generic functions to install the common
#   part of the features such as desktop launchers, sourced .bashrc functions...
# - Permissions: Can be executed as root or user.
generic_installation() {
  # Substitute dashes for underscores. Dashes are not allowed in variable names
  local -r featurename="${CURRENT_INSTALLATION_KEYNAME//-/_}"
  local -r manualcontentavailable="${CURRENT_INSTALLATION_KEYNAME}_manualcontentavailable"
  generic_package_manager_override "${featurename}"

  # Remove the installation folder to avoid collisions
  rm -Rf "${CURRENT_INSTALLATION_FOLDER}"
  if [ "$(echo "${!manualcontentavailable}" | cut -d ";" -f1)" == "1" ]; then
    "${FLAG_MODE}_${CURRENT_INSTALLATION_KEYNAME}_pre"
  fi

  "generic_${FLAG_MODE}_gpgSignatures"
  "generic_${FLAG_MODE}_sources"
  "generic_${FLAG_MODE}_dependencies"
  "generic_${FLAG_MODE}_packageManager"

  "generic_${FLAG_MODE}_cloneRepositories"

  "generic_${FLAG_MODE}_downloads"

  "generic_${FLAG_MODE}_pythonVirtualEnvironment"
  if [ "$(echo "${!manualcontentavailable}" | cut -d ";" -f2)" == "1" ]; then
    "${FLAG_MODE}_${CURRENT_INSTALLATION_KEYNAME}_mid"
  fi

  "generic_${FLAG_MODE}_files"
  "generic_${FLAG_MODE}_movefiles"
  "generic_${FLAG_MODE}_dynamic_launcher"
  if [ "${OS_NAME}" == "WSL2" ]; then
    "generic_${FLAG_MODE}_WSL2_dynamic_launcher"
  fi

  "generic_${FLAG_MODE}_functions"
  "generic_${FLAG_MODE}_initializations"

  # TODO refactor using get dynamic launcher and serving the fklag install in a similar manner of how we servce the autostart flag
  "generic_${FLAG_MODE}_favorites" "${featurename}"
  # TODO refactor to remove _. Ensure that MIME_ASSOCIATION_PATH is present. Property asscoiatedfiletypes need an associated
  # TODO desktop launcher to add the file asscoaitions, arbitrarily choose the first or extend this behaviour in get dynamic launcher
  "generic_${FLAG_MODE}_file_associations"
  "generic_${FLAG_MODE}_keybindings"
  "generic_${FLAG_MODE}_pathlinks"
  if [ "$(echo "${!manualcontentavailable}" | cut -d ";" -f3)" == "1" ]; then
    "${FLAG_MODE}_${CURRENT_INSTALLATION_KEYNAME}_post"
  fi
  if [ "${FLAG_MODE}" == "install" ]; then
    if ! grep -qE "^${CURRENT_INSTALLATION_KEYNAME}\$" < "${INSTALLED_FEATURES}"; then
      echo "${CURRENT_INSTALLATION_KEYNAME}" >> "${INSTALLED_FEATURES}"
    fi
  elif [ "${FLAG_MODE}" == "uninstall" ]; then
    remove_line "${CURRENT_INSTALLATION_KEYNAME}" "${INSTALLED_FEATURES}"
  fi

  if [ "${POP_PACKAGE_MANAGER}" == 1 ]; then
    "initialize_package_manager_${STACKED_PACKAGE_MANAGER}"
    POP_PACKAGE_MANAGER=0
  fi
}


if [ -f "${CUSTOMIZER_PROJECT_FOLDER}/data/core/common_data.sh" ]; then
  source "${CUSTOMIZER_PROJECT_FOLDER}/data/core/common_data.sh"
else
  # output without output_proxy_executioner because it does not exist at this point, since we did not source common_data
  # yet
  echo -e "\e[91m$(date +%Y-%m-%d_%T) -- ERROR: common_data.sh not found. Aborting..."
  exit 1
fi
