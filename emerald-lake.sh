#!/bin/bash

# ------------------------------------------------------------------
# [Title] : Emerald-Lake
# [Description] : Docker registry builder (build and pus)
# [Version] : v1.0.0
# [Author] : Lucas Noga
# [Shell] : Bash v5.0.17
# [Usage] : ./emerald-lake.sh
#           ./archange.sh --debug
#           ./archange.sh --debug --config
# ------------------------------------------------------------------

PROJECT_NAME=Emerald-Lake
PROJECT_VERSION=v1.0.0

# Parameters to execute script
typeset -A CONFIG=(
  [run]=true # If run is to false we don't execute the script

  [config_file]="./settings.conf"      # Configuration file path
  [registry]=""                        # Registry DNS to push your image
  [default_registry]="localhost:5050/" # Default Folder to store if no define in settings.conf
  [debug_color]=light_blue             # Color to show log in debug mode
)

# Options params setup with command parameters
typeset -A OPTIONS=(
  [debug]=false # Debug mode to show more log
  [quiet]=false # Quiet mode when we build and push image
)

###
# Main body of script starts here
###
function main {

  read_options $@ # Read script options like (--debug)
  log_debug "Launch Project $(log_color "${PROJECT_NAME} : ${PROJECT_VERSION}" "magenta")"

  # Read .conf file (default ./setting.conf)
  read_config ${CONFIG[config_file]}

  # Build docker image and push it into your registry
  docker_builder
}

################################################################### Params Scripts ###################################################################

###
# Setup variables from config file
# $1 = path to the config file (default: ./setting.conf)
###
function read_config {
  configuration_file=$1
  log_debug "Read configuration file: $configuration_file"

  if [ ! -f "$configuration_file" ]; then
    log_color "ERROR: $configuration_file doesn't exists." "red"
    log "Exiting..."
    exit 1
  fi

  # Load configuration file
  source $configuration_file
  log_debug "Configuration file $configuration_file loaded"

  # Load the other data
  CONFIG+=([registry]=$(eval echo $REGISTRY))
  if [ -z ${CONFIG[registry]} ]; then
    CONFIG+=([registry]=${CONFIG[default_registry]})
    log "No folder define get default value of folder: $(log_color "${CONFIG[default_registry]}" "yellow")"
  fi

  log_debug "Dump: $(declare -p CONFIG)"
}

###
# Setup params passed with the script
# -d | --debug : Setup debug mode
###
function read_options {
  params=("$@") # Convert params into an array

  # Step through all params passed to the script
  for param in "${params[@]}"; do
    log_debug "Option '$param' founded"
    case $param in
    "-d" | "--debug")
      active_debug_mode
      ;;
    "-q" | "--quiet")
      active_quiet_mode
      ;;
    "-c" | "--config" | "--show-config")
      show_settings
      CONFIG+=([run]=false) # Only display config do not execute the history
      ;;
    "-s" | "--setup" | "--setup-config")
      setup_settings
      CONFIG+=([run]=false) # Only display config do not execute the history
      ;;
    *) ;;
    esac
  done

  log_debug "Dump: $(declare -p OPTIONS)"
}

###
# Active the debug mode changing options params
###
function active_debug_mode {
  OPTIONS+=([debug]=true)
  log_debug "Debug Mode Activated"
}

###
# Active the quiet mode changing options params
###
function active_quiet_mode {
  OPTIONS+=([quiet]=true)
  log_debug "Quiet Mode Activated"
}

###
# List settings in settings.conf file if they are defined
# $1: path where the settings file is (default: "./settings.conf")
###
function show_settings {
  file=$1
  # get default configuration file if no filled
  if [ -z $file ]; then
    file=${CONFIG[config_file]}
  fi

  read_config $file

  log "Here's your settings: "
  log "\t- REGISTRY:" $(log_color "${CONFIG[registry]}" "yellow")
}

###
# Setup the settings in command line for the user, if the file exists we erased it
# $1: path where the settings file is (default: "./settings.conf")
###
function setup_settings {
  file=$1
  log "Setup settings need some intels to create your settings"
  # get default configuration file if no filled
  if [ -z $file ]; then
    file=${CONFIG[config_file]}
  fi

  # Check if you want to override the file
  if [ -f $file ]; then
    override=$(ask_yes_no "$(log_color "$file" "yellow") already exists do you want to override it")
    if [ "$override" == false ]; then
      log_color "Abort settings editing - no override" "red"
      exit 0
    fi
  fi

  # Read value for the user
  registry=$(read_data "Registry Host (default: "")" "string" 1)

  typeset -A INPUTS+=(
    [REGISTRY]="$registry"
  )

  log_debug "Dump: $(declare -p INPUTS)"

  for data in "${!INPUTS[@]}"; do
    if [ $data == "PASSWORD" ]; then
      log_debug "$data -> ${INPUTS[$data]}"
    else
      log_color "$data -> ${INPUTS[$data]}" "light_blue"
    fi
  done

  confirmation=$(ask_yes_no "$(log_color "Do you want to apply this settings ?" "yellow")")
  if [ "$confirmation" == false ]; then
    log_color "Abort settings editing - no confirmation data" "red"
    exit 0
  fi

  # Write the settings
  write_settings_file $file "$(declare -p INPUTS)"

  # show the new settings
  show_settings $file
}

###
# Write the file settings the settings in command line for the user, if the file exists we erased it
# $1: [string] path where the settings file is (default: "./settings.conf")
# $2: [array] data to insert into the setting like (ip, user of else)
###
function write_settings_file {
  file=$1
  eval "declare -A DATA="${2#*=} # eval string into a new associative array

  # if file doesn't exist we create it
  if [ ! -f $file ]; then
    log_debug "Creating $(log_color "$file" "yellow")"
    touch $file
    log_debug "$(log_color "$file" "yellow") Created"
  else
    log_debug "Resetting old settings in $(log_color "$file" "yellow")"
    >$file # Resetting file
    log_debug "$(log_color "$file" "yellow") Reseted"
  fi

  echo "REGISTRY=${DATA[REGISTRY]}" >>$file
}

################################################################### Core ###################################################################

###
# Main method to run build and push docker
###
function docker_builder {
  if [ "${CONFIG[run]}" = false ]; then
    log_debug "No run history because some options block it"
    return
  fi

  # Setup name of the image
  image=$(set_image_name)
  log_debug "Image set: $image"

  # Setup tag of the image
  tag=$(set_tag)
  log_debug "Tag set: $tag"

  # Launch build the image
  build_image $image $tag

  push_image
}

###
# Build docker image from registry path as name of image
# $1 : [string] name of the future docker image
# $2 : [string] tag of the future docker image
###
# TODO A TESTER
function build_image {
  image_name=$1
  tag=$2

  # Add quiet option if debug is not activated
  [[ "${OPTIONS[quiet]}" != true ]] && params="-q" || params=""

  # build the image
  log_debug "Command: docker build $params -t $image_name:$tag ."
  docker build $params -t $image_name:$tag .

  # if something's wrong
  if [ ! $? -eq 0 ]; then
    log_color "ERROR: Failed to build docker image." "red"
    log "Exiting..."
    exit 1
  fi
  log "Image $(log_color "$registry_path:$tag" "yellow") built"
}

###
# Set the image name of the docker proposing multiple choice for the user
# between registry configured, repository remote, folder parent name, etc...
###
# TODO
function set_image_name {
  # TODO to change
  folder=$(get_parent_folder)
  echo "$folder"

  # TODO on affiche au user 3 possibilité via un array
  # 1 - le nom de registry suffixer au folder parent (ex: localhost:5050/emerald-lake)
  # 2 - le path_remote du repository (ex: git.gitlab.cruxpool.com/emerald-lake)
  # 3 - le nom du folder parent (ex: emerald-lake)

  # TODO log le nom par defaut si repo git
  # si ca convient pas on demande au user un nom
  # sinon on prend le non du projet
  # sinon on demande au user de choisir
}

###
# Ask for a user a tag to create docker image
###
function set_tag {
  default_tag=latest
  read -p "Do you want to add a tag (default: \"$default_tag\"): " tag
  if [ -z $tag ]; then tag=$default_tag; fi
  echo $tag
}

###
# Check if current directory is a git repostory
# true if a folder .git is founded false if not
###
function check_git_repo {
  if [ -d .git ]; then
    echo true
  else
    echo false
  fi
}

###
# Push docker image from local to registry
###
# TODO
function push_image {
  log_color "This feature is WIP" "magenta"
  exit 1
  ## TODO HANDLE PUSH
  # TODO avoir le remote path pour push l'app

  # TODO si ce n'est pas un repo git alors on prend celui de la config
  # TODO il faut que ce soit une option
  repo_git=$(check_git_repo)
  if ! $repo_git; then
    log_color "It's not a git repository" "yellow"
  else
    log_color "It's a git repository" "yellow"
  fi

  # get remote path
  remote_path=$(get_path_remote)
  registry_path=$(set_registry_path $remote_path)
  log_debug "The registry path is $registry_path"

  if ask_push; then push=true; else push=false; fi

  # push the image
  if [ "$push" = true ]; then
    image=$1
    tag=$2

    # Add quiet option if debug is not activated
    [[ "${OPTIONS[quiet]}" != true ]] && params="-q" || params=""

    docker push $image:$tag
  fi

}

# Get remote path of the project
function get_path_remote {
  remote_url=$(git config --get remote.origin.url)
  echo $remote_url | sed -r 's/(\.git)|(git\@gitlab\.cruxpool\.com:)//g'
}

# Set registry docker path of the project
function set_registry_path {
  remote_path=$1
  echo $REGISTRY$remote_path
}

# Ask if it's need to push the image
function ask_push {
  read -rsn1 -p "Do you want to push the image to registry [y/N] : " ask
  if [ "$ask" == 'y' ] || [ "$ask" == 'Y' ]; then
    return 0
  else
    return 1
  fi
}

################################################################### Utils functions ###################################################################

###
# Return parent folder name in lowercase
###
function get_parent_folder {
  folder=$(basename $(pwd))
  folder_lower=$(echo $folder | tr '[:upper:]' '[:lower:]')
  echo $folder_lower
}

###
# Return datetime of now (ex: 2022-01-10 23:20:35)
###
function get_datetime {
  log $(date '+%Y-%m-%d %H:%M:%S')
}

###
# Ask yes/no question for user and return boolean
# $1 : question to prompt for the user
###
function ask_yes_no {
  message=$1
  read -r -p "$message [y/N] : " ask
  if [ "$ask" == 'y' ] || [ "$ask" == 'Y' ]; then
    echo true
  else
    echo false
  fi
}

###
# Setup a read value for a user, and return it
# $1: [string] message prompt for the user
# $2: [string] type of data wanted (text, number, password)
# $3: [integer] number of character wanted at least
###
function read_data {
  message=$1
  type=$2
  min_char=$3

  if [ -z $min_char ]; then min_char=0; fi

  read_options=""
  case $type in
  "text")
    read_options="-r"
    ;;
  "number")
    read_options="-r"
    ;;
  "password")
    read_options="-rs"
    ;;
  *) ;;
  esac

  # read command value
  read $read_options -p "$message : " value

  echo $value
}

###
# Remember to pass an array as param into a function (pass it in param with $(declare -p array))
# $1 : [Array] associative array to reuse
###
function print_array {
  eval "declare -A func_assoc_array="${1#*=} # eval string into a new associative array
  declare -p func_assoc_array                # proof that array was successfully created
}

################################################################### Logging functions ###################################################################

###
# Simple log function to support color
###
function log {
  echo -e $@
}

typeset -A COLORS=(
  [default]='\033[0;39m'
  [black]='\033[0;30m'
  [red]='\033[0;31m'
  [green]='\033[0;32m'
  [yellow]='\033[0;33m'
  [blue]='\033[0;34m'
  [magenta]='\033[0;35m'
  [cyan]='\033[0;36m'
  [light_gray]='\033[0;37m'
  [light_grey]='\033[0;37m'
  [dark_gray]='\033[0;90m'
  [dark_grey]='\033[0;90m'
  [light_red]='\033[0;91m'
  [light_green]='\033[0;92m'
  [light_yellow]='\033[0;93m'
  [light_blue]='\033[0;94m'
  [light_magenta]='\033[0;95m'
  [light_cyan]='\033[0;96m'
  [nc]='\033[0m' # No Color
)

###
# Log the message in specific color
###
function log_color {
  message=$1
  color=$2
  log ${COLORS[$color]}$message${COLORS[nc]}
}

###
# Log the message if debug mode is activated
###
function log_debug {
  message=$@
  date=$(get_datetime)
  if [ "${OPTIONS[debug]}" = true ]; then log_color "[$date] $message" ${CONFIG[debug_color]}; fi
}

main $@
