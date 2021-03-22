#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#
# Domain Resolution Check Shell
#
# Author: StarryVoid <stars@starryvoid.com>
# Intro:  https://blog.starryvoid.com/archives/434.html
# Build:  2019/12/21 Version 1.0.1
#

# -------------- Config Start ------------

# Log
OUTPUTLOG="$(pwd)/shell.log"

# -------------- Config End ------------

# Time
DATETIME=$(date +%Y-%m-%d_%H:%M:%S)
RUNTIME=$(date +%s)
INPUTCONFIG="$1"
USESHELL="$2"

# ------------ Start ------------

check_environment () {
    if ! [ -x "$(command -v dig)" ]; then echo "Command not found \"dig\"" >> "${OUTPUTLOG}" ; exit 1; fi
}

read_config_info_file() {
    CONFIGFILE=$(echo "${INPUTCONFIG}" | grep "\-\-config=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
    if [ -f "$(pwd)/${CONFIGFILE}" ]; then
        CONFIGINFO="$(pwd)/${CONFIGFILE}"
    elif [ -f "${CONFIGFILE}" ]; then
        CONFIGINFO="${CONFIGFILE}"
    else 
        echo " Please Input Config File as \"--config=\" to Running Shell "
        echo " Example Config File Will Print for \"$(pwd)/config.example\" "
        echo -e "DOMAINNAME=\"example.com\"\nDOMAINIPVERSION=\"4\"\nDIGQUERYSERVER=\"8.8.8.8\"\nDIGQUERYTIME=\"5\"\nOLDIPADDRESS=\"1.0.1.0\"\nOLDTIME=\"1000000000\"\nOLDTTL=\"300\"\n" > "$(pwd)/config.example"
    fi
    if [ -f "${CONFIGINFO}" ]; then
        CHECKDDNSINFOFILE=1
        DOMAINNAME=$(cat < "${CONFIGINFO}" | grep "DOMAINNAME=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ ! "${DOMAINNAME}" ]]; then CHECKDDNSINFOFILE=0 ; fi
        DOMAINIPVERSION=$(cat < "${CONFIGINFO}" | grep "DOMAINIPVERSION=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ "${DOMAINIPVERSION}" != "4"  ]] && [[ "${DOMAINIPVERSION}" != "6"  ]]; then CHECKDDNSINFOFILE=0 ; fi
        DIGQUERYSERVER=$(cat < "${CONFIGINFO}" | grep "DIGQUERYSERVER=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ ! "${DIGQUERYSERVER}" ]]; then CHECKDDNSINFOFILE=0 ; fi
        DIGQUERYTIME=$(cat < "${CONFIGINFO}" | grep "DIGQUERYTIME=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ ! "${DIGQUERYTIME}" ]]; then CHECKDDNSINFOFILE=0 ; fi
        OLDIPADDRESS=$(cat < "${CONFIGINFO}" | grep "OLDIPADDRESS=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ ! "${OLDIPADDRESS}" ]]; then CHECKDDNSINFOFILE=0 ; fi
        OLDTIME=$(cat < "${CONFIGINFO}" | grep "OLDTIME=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ ! "${OLDTIME}" ]]; then CHECKDDNSINFOFILE=0 ; fi
        OLDTTL=$(cat < "${CONFIGINFO}" | grep "OLDTTL=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" )
        if [[ ! "${OLDTTL}" ]]; then CHECKDDNSINFOFILE=0 ; fi
    else
        CHECKDDNSINFOFILE=0
    fi
    if [ "${CHECKDDNSINFOFILE}" = 0 ] ; then echo "Running Time is ${DATETIME}" >> "${OUTPUTLOG}" && echo "Failed to check Config information file." >> "${OUTPUTLOG}" ; exit 1 ; fi
}

get_domain_dns_ttl() {
    if [[ "${DOMAINIPVERSION}" == "4" ]]; then
        [ -z "${TEMPDIGOUTPUTTTL}" ] && TEMPDIGOUTPUTTTL=$(dig A +nocmd +noall +answer +ttlid +time="${DIGQUERYTIME}" @"${DIGQUERYSERVER}" "${DOMAINNAME}" ) && DIGOUTPUTTTL=$( echo -c "${TEMPDIGOUTPUTTTL}" | tail -1 | awk '{print $2}' )
    elif [[ "${DOMAINIPVERSION}" == "6" ]]; then
        [ -z "${TEMPDIGOUTPUTTTL}" ] && TEMPDIGOUTPUTTTL=$(dig AAAA +nocmd +noall +answer +ttlid +time="${DIGQUERYTIME}" @"${DIGQUERYSERVER}" "${DOMAINNAME}" ) && DIGOUTPUTTTL=$( echo -c "${TEMPDIGOUTPUTTTL}" | tail -1 | awk '{print $2}' )
    fi
    if [[ ! "${DIGOUTPUTTTL}" ]]; then echo "Running Time is ${DATETIME}" >> "${OUTPUTLOG}" && echo "Failed to get domain ttl from internet." >> "${OUTPUTLOG}"; exit 1; fi
}

get_domain_dns_ip() {
    if [[ "${DOMAINIPVERSION}" == "4" ]]; then
        [ -z "${TEMPDIGOUTPUTIPADDRESS}" ] && TEMPDIGOUTPUTIPADDRESS=$(dig A +short +time="${DIGQUERYTIME}" @"${DIGQUERYSERVER}" "${DOMAINNAME}" ) && DIGOUTPUTIPADDRESS=$( echo -c "${TEMPDIGOUTPUTIPADDRESS}" | tail -1 )
    elif [[ "${DOMAINIPVERSION}" == "6" ]]; then
        [ -z "${TEMPDIGOUTPUTIPADDRESS}" ] && TEMPDIGOUTPUTIPADDRESS=$(dig A +short +time="${DIGQUERYTIME}" @"${DIGQUERYSERVER}" "${DOMAINNAME}" ) && DIGOUTPUTIPADDRESS=$( echo -c "${TEMPDIGOUTPUTIPADDRESS}" | tail -1 )
    fi
    if [[ ! "${DIGOUTPUTIPADDRESS}" ]]; then echo "Running Time is ${DATETIME}" >> "${OUTPUTLOG}" && echo "Failed to get domain public network address from internet." >> "${OUTPUTLOG}"; exit 1; fi
}

update_new_ipaddress() {
    echo "Please Edit Your Command List At Line 73"
    bash "${USESHELL}"
}

edit_config_info_file_ip() {
    sed -i "s/${OLDIPADDRESS}/${DIGOUTPUTIPADDRESS}/g" "${CONFIGINFO}"
    NEWIPADDRESS=$(cat < "${CONFIGINFO}" | grep "OLDIPADDRESS=" | awk -F "=" '{print $2}' | sed 's/\"//g' | sed "s/\'//g" ) if [[ "${DIGOUTPUTIPADDRESS}" == "${NEWIPADDRESS}" ]]; then echo "Running Time is ${DATETIME}" >> "${OUTPUTLOG}"
        echo "Config IP address has been modified to \"${DIGOUTPUTIPADDRESS}\"." >> "${OUTPUTLOG}"
        exit 0
    else
        echo "Running Time is ${DATETIME}" >> "${OUTPUTLOG}"
        echo "Config IP address modification failed." >> "${OUTPUTLOG}"
        exit 1
    fi
}
edit_config_info_file_ttl() {
    get_domain_dns_ttl
    sed -i '/OLDTIME/d' "${CONFIGINFO}"
    echo "OLDTIME=\"${RUNTIME}\"" >> "${CONFIGINFO}"
    sed -i '/OLDTTL/d' "${CONFIGINFO}"
    echo "OLDTTL=\"${DIGOUTPUTTTL}\"" >> "${CONFIGINFO}"
}

main() {
    check_environment
    read_config_info_file
    GAPTIME=$(expr "${RUNTIME}" - "${OLDTIME}")
    if [[ "${GAPTIME}" -ge "${OLDTTL}" ]]; then 
        get_domain_dns_ip
        if [[ "${DIGOUTPUTIPADDRESS}" == "${OLDIPADDRESS}" ]]; then 
            edit_config_info_file_ttl
            exit 0
        else 
            update_new_ipaddress
            edit_config_info_file_ip
            edit_config_info_file_ttl
            exit 0
        fi
    else 
        exit 0
    fi
    exit 0
}

# ------------ End ------------

main
