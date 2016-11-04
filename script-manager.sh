#!/bin/bash
##############################################################
# Copyright (C) Brault François - Mozilla Public Licence 2.0 #
# Git : https://github.com/Paco112/script-manager            #
##############################################################

VERSION="0.1"

# Specify colors utilized in the terminal
normal=$(tput sgr0)              # White
red=$(tput setaf 1)              # Red
green=$(tput setaf 2)            # Green
yellow=$(tput setaf 3)           # Yellow
blue=$(tput setaf 4)             # Blue
violet=$(tput setaf 5)           # Violet
cyan=$(tput setaf 6)             # Cyan
white=$(tput setaf 7)            # White
txtbld=$(tput bold)              # Bold
bldred=${txtbld}$(tput setaf 1)  # Bold Red
bldgrn=${txtbld}$(tput setaf 2)  # Bold Green
bldblu=${txtbld}$(tput setaf 4)  # Bold Blue
bldylw=${txtbld}$(tput setaf 3)  # Bold Yellow
bldvlt=${txtbld}$(tput setaf 5)  # Bold Violet
bldcya=${txtbld}$(tput setaf 6)  # Bold Cyan
bldwht=${txtbld}$(tput setaf 7)  # Bold White

ARGS="$@"
FORCEYES=0
BASEDIR=$(pwd)
LOG_FILE="${BASEDIR}/script-manager.log"

SCRIPT=$( readlink -m $( type -p $0 ))      # Full path of script
BASE_DIR=`dirname ${SCRIPT}`                # Directory script is run in
LISTSCRIPTS=""
TMPSOURCE="/tmp/scripts.list"
SCRIPT_NAME="${0##*/}"
CHECK_UPDATE=1
UPDATE_URL="https://raw.githubusercontent.com/Paco112/script-manager/master/script-manager.sh"
BASESCRIPTS="https://raw.githubusercontent.com/Paco112/script-manager/master/scripts/"

splashscreen() {
    clear
    echo -e "\n"
    echo -e "${bldred}              PPPPPP    AAA    CCCCC   OOOOO      1   1   2222"
    echo -e "${bldred}              PP   PP  AAAAA  CC    C OO   OO    111 111 222222"
    echo -e "${bldred}              PPPPPP  AA   AA CC      OO   OO     11  11     222"
    echo -e "${bldred}              PP      AAAAAAA CC    C OO   OO     11  11  2222"
    echo -e "${bldred}              PP      AA   AA  CCCCC   OOOO0     111 111 2222222"
    echo -e "\n"
    echo -e "${bldred}                  SSSSS   CCCCC  RRRRRR  IIIII PPPPPP  TTTTTTT"
    echo -e "${bldred}                 SS      CC    C RR   RR  III  PP   PP   TTT"
    echo -e "${bldred}                  SSSSS  CC      RRRRRR   III  PPPPPP    TTT"
    echo -e "${bldred}                      SS CC    C RR  RR   III  PP        TTT"
    echo -e "${bldred}                  SSSSS   CCCCC  RR   RR IIIII PP        TTT"
    echo -e "\n"
    echo -e "${bldred}           MM    MM   AAA   NN   NN   AAA     GGGG  EEEEEEE RRRRRR"
    echo -e "${bldred}           MMM  MMM  AAAAA  NNN  NN  AAAAA   GG  GG EE      RR   RR"
    echo -e "${bldred}           MM MM MM AA   AA NN N NN AA   AA GG      EEEEE   RRRRRR"
    echo -e "${bldred}           MM    MM AAAAAAA NN  NNN AAAAAAA GG   GG EE      RR  RR"
    echo -e "${bldred}           MM    MM AA   AA NN   NN AA   AA  GGGGGG EEEEEEE RR   RR"
    echo -e "${normal}                                                               v${VERSION}"
    echo -e "\n"
    echo -e "${normal}         Copyright (C) Brault François - Mozilla Public Licence 2.0"
    echo -e "\n"
}

getargs() {
    while getopts "dys:u:-:" opt "$@"; do
        case ${opt} in
            -)
            case "${OPTARG}" in
                disable-update)
                    CHECK_UPDATE=0
                ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                        exit 1
                    fi
                    ;;
            esac;;
            d)
                CHECK_UPDATE=0
            ;;
            y)
                FORCEYES=1
            ;;
            s)
                LISTSCRIPTS="$OPTARG"
            ;;
            u)
                BASESCRIPTS="$OPTARG"
            ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
            ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
            ;;
        esac
    done
}

# parameter: FILE
cleanfile() {
    local file=$1
    if [ -f ${file} ]; then
        rm ${file}
    fi
}

checkroot() {
    # Make sure only root can run our script
    if [ "$(id -u)" != "0" ]; then
       echo -e "${bldred}This script must be run as root !${normal}"
       exit 1
    fi
}

function clearlastline() {
    local numberline=${1:-1}
    for (( i=1; i<=numberline; i++ )); do
        tput cuu1 && tput el
    done
    tput el1
}

function confirm()
{
	if [ ${FORCEYES} -eq 1 ]; then
	    return 0
	fi
	local response
	local question=${1:-"Are you sure ?"}
    echo -en "\n\t"
    read -r -p "${question} [Y/n]" response
    response=${response,,} # tolower
    clearlastline 2
    if [[ "${response}" =~ ^(yes|y| ) ]] | [ -z "${response}" ]; then
        return 0
    fi
    return 1
}

checkupdate() {
    local message="${normal}Check UPDATE"
    echo -en "${yellow}[LOADING] ${message}"
    local tmpfile="/tmp/update.tmp"
    local ret=1
    cleanfile "${tmpfile}"
    wget --no-cache --no-check-certificate --progress=dot -O ${tmpfile} ${UPDATE_URL} 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    if [ $? -eq 0 ] && [ -f ${tmpfile} ] && [ $( wc -c ${tmpfile} | awk '{print $1}' ) -gt 0 ]; then
        echo -e "\r\e[0;32m     [OK]\e[0m ${message}"
        md5_src=$(md5sum "${SCRIPT_NAME}" | awk '{print $1}')
        md5_new=$(md5sum "${tmpfile}" | awk '{print $1}')
        if [ "${md5_src}" != "${md5_new}" ] && [ ! -z "${md5_new}" ]; then
            echo ">>> PACTH '${tmpfile}' => '${BASEDIR}/${SCRIPT_NAME}" >> "${LOG_FILE}" 2>&1
            echo -en "${yellow}[LOADING] Patch NEW VERSION"
            bash -c "cp '${tmpfile}' '${BASEDIR}/${SCRIPT_NAME}'" >> "${LOG_FILE}" 2>&1
            ret=$?
            if [ ${ret} -eq 0 ]; then
    		    echo -e "\r\e[0;32m     [OK]\e[0m Patch NEW VERSION"
    		    echo -e "\n\t RESTARTING ..."
    		    sleep 2
    		    exec "${BASEDIR}/${SCRIPT_NAME}" ${ARGS}
    		    exit $?
            else
                echo -e "\r\e[0;31m  [ERROR]\e[0m Patch NEW VERSION"
            fi
        else
            clearlastline
        fi
    else
        echo -e "\r\e[0;31m  [ERROR]\e[0m ${message} (${UPDATE_URL})"
    fi
    return ${ret}
}

# First parameter: MESSAGE
# Others parameters: COMMAND (! not |)
displayandexec() {
    echo ">>> EXEC $1" >> "${LOG_FILE}" 2>&1
  	local message="${normal}Exec Script $1"
  	shift
  	echo -en "${yellow}[LOADING] ${message}"
  	bash -c "$*" >> "${LOG_FILE}" 2>&1
  	local ret=$?
  	if [ ${ret} -ne 0 ]; then
    		echo -e "\r\e[0;31m  [ERROR]\e[0m ${message}"
  	else
    		echo -e "\r\e[0;32m     [OK]\e[0m ${message}"
  	fi
  	echo ">>> RETURN : ${ret}" >> "${LOG_FILE}" 2>&1
  	return ${ret}
}

# parameter: TASK_NAME
downloadandexec() {
    local script=$1
    if [ "${BASESCRIPTS: -1}" != "/" ]; then
        BASESCRIPTS="${BASESCRIPTS}/"
    fi
    local url="${BASESCRIPTS}${script}"
    local message="${normal}Download Script ${script}"
    local tmpfile="/tmp/script.tmp"
    if [ ${script} = "scripts.list" ]; then
        message="${normal}Download Script List"
        tmpfile=${TMPSOURCE}
    fi
    local ret=1
    if [[ ${BASESCRIPTS} == http* ]]; then
        echo -en "${yellow}[LOADING] ${message}"
        cleanfile "${tmpfile}"
        wget --no-cache --no-check-certificate --progress=dot -O ${tmpfile} ${url} 2>&1 | grep --line-buffered "%" | \
            sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
        echo -ne "\b\b\b\b"
    else
        tmpfile="./${url}"
        if [ ${script} = "scripts.list" ]; then
            cp ${tmpfile} ${TMPSOURCE}
        fi
    fi
    if [ -f ${tmpfile} ] && [ $( wc -c ${tmpfile} | awk '{print $1}' ) -gt 0 ]; then
    		echo -e "\r\e[0;32m     [OK]\e[0m ${message}"
    		if [ ${script} = "scripts.list" ]; then
    		    # Test script list file and include in source if ok
    		    echo ">>> TEST SOURCE FILE ${TMPSOURCE}" >> "${LOG_FILE}" 2>&1
    		    echo -en "${yellow}[LOADING] Test Script List"
    		    chmod +x "${TMPSOURCE}"
    		    bash -c "${TMPSOURCE}" >> "${LOG_FILE}" 2>&1
    		    ret=$?
    		    if [ ${ret} -eq 0 ]; then
    		        source "${TMPSOURCE}" >> "${LOG_FILE}" 2>&1
    		        echo -e "\r\e[0;32m     [OK]\e[0m Test Script List"
    		    else
    		        echo -e "\r\e[0;31m  [ERROR]\e[0m Test Script List"
    		    fi
    		    echo ">>> RETURN : ${ret}" >> "${LOG_FILE}" 2>&1
    		    return ${ret}
    		fi
    		displayandexec "${script}" bash "${tmpfile}"
    		ret=$?
  	else
    		echo -e "\r\e[0;31m  [ERROR]\e[0m ${message} (${url})"
  	fi
  	if [[ ${BASESCRIPTS} == http* ]]; then
  	    cleanfile "${tmpfile}"
  	fi
  	return ${ret}
}

# First parameter: search
# Second parameter: array
in_array() {
    local search=$1
    shift
    local arr=$*
    if [[ ${arr[*]} =~ $(echo "\<${search}\>") ]]; then
        return 0
    fi
    return 1
}

checkroot

getargs "${ARGS}"

splashscreen

if [ ${CHECK_UPDATE} -eq 1 ]; then
    checkupdate
fi

if ! downloadandexec "scripts.list"; then
    echo -e "\n" &&  exit 0
fi

list_scripts=($(sed -n 's/^scripts\_\([a-z0-9\_]\+\)=.*/\1/p' ${TMPSOURCE}))
cleanfile "${TMPSOURCE}"

if [ ${#list_scripts[@]} -le 0 ]; then
    echo -e "\r\e[0;31m  [ERROR]\e[0m Scripts not found in scripts.list file !\n" && exit 1
fi

clearlastline 2

for name in "${list_scripts[@]}"; do
    var_name="scripts_${name}"
    var_value=${!var_name}
    echo "${cyan}${name}${normal} => ${!var_name}"
done

good_response=0
while [ ${good_response} -eq 0 ]; do

    while [ -z "${LISTSCRIPTS}" ]; do
        echo -en "\n\t"
        read -r -p "Please enter the name of scripts to run (separated by a space) : " LISTSCRIPTS
        LISTSCRIPTS="${LISTSCRIPTS,,}" # tolower
        clearlastline 2
    done

    LISTSCRIPTS=(${LISTSCRIPTS})

    for test in "${LISTSCRIPTS[@]}"; do
        if ! in_array "${test}" "${list_scripts[@]}"; then
            good_response=0
            echo -e "\n\t\e[0;31m[ERROR]\e[0m  ${cyan}\"${test}\"${normal} it's not valid !"
            if [ ${FORCEYES} -eq 1 ]; then
                echo -e "\n" &&  exit 1
            fi
            sleep 2
            LISTSCRIPTS=""
            clearlastline 2
            break
        else
            good_response=1
        fi
    done
done

if [ ${#LISTSCRIPTS[@]} -le 0 ]; then
    echo -e "\r\e[0;31m  [ERROR]\e[0m Scripts not found !\n" && exit 1
fi

splashscreen

for master_name in "${LISTSCRIPTS[@]}"; do
    master_full_name="scripts_${master_name}"
    master_scripts=(${!master_full_name})
    for script in "${master_scripts[@]}"; do
        if ! downloadandexec "${master_name}/${script}"; then
            if ! confirm "Last script return error, do you want to continue ?"; then
                echo -e "\n" &&  exit 1
            fi
        fi
    done
done

echo -e "\n" &&  exit 0         