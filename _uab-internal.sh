#!/bin/bash
# Overridable
if [ -z "$UAB_CONF_XML" ]; then
    UAB_CONF_XML="UnityAutoBuild.xml"
fi

if [ -z "$UAB_EXEC_XMLLINT" ]; then
    UAB_EXEC_XMLLINT="xmllint"
fi
if [ -z "$UAB_EXEC_UNITY" ]; then
    UAB_EXEC_UNITY="Unity"
fi

if [ -z "$UAB_EXEC_ZIP" ]; then
    UAB_EXEC_ZIP="zip"
fi
if [ -z "$UAB_EXEC_XZ" ]; then
    UAB_EXEC_XZ="xz"
fi
if [ -z "$UAB_EXEC_TAR" ]; then
    UAB_EXEC_TAR="tar"
fi

# Consts
UAB_SRC_DIR="$(dirname "${BASH_SOURCE[0]}")"
UAB_SAMPLE_CONF="$UAB_SRC_DIR/UnityAutoBuild.xml"
UAB_CONF_SCHEMA="$UAB_SRC_DIR/UnityAutoBuild.xsd"
UAB_PATH="$(pwd)"
UAB_GIT_DIR="git"
UAB_WD="wd"
UAB_BUILDS="builds"

function uab_dropif_failed () {
    EC="$?"

    if [ $EC -ne 0 ]; then
        exit $1
    fi
}

function uab_error () {
    echo "$1" >& 2
}

function uab_validate_conf () {
    "$UAB_EXEC_XMLLINT" --noout --schema "$UAB_CONF_SCHEMA" "$UAB_CONF_XML"
}

function uab_load_init_conf () {
    if [ -z "$UAB_FETCH_SPEC" ]; then
        UAB_FETCH_SPEC="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='FetchSpec'][1])" "$UAB_CONF_XML")"
    fi
    if [ -z "$UAB_PROJECT_PATH" ]; then
        UAB_PROJECT_PATH="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='ProjectPath'][1])" "$UAB_CONF_XML")"
    fi

    cnt=$("$UAB_EXEC_XMLLINT" --xpath "count(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'])" "$UAB_CONF_XML")
    for (( i = 1; i <= $cnt; i++ )); do
        let idx=i-1
        UAB_CONFIG_ARR[$idx]="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][$i]/@id)" "$UAB_CONF_XML")"
    done
}

function uab_load_conf () {
    UAB_T_ID="$1"
    UAB_T_BASE="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/@base)" "$UAB_CONF_XML")"
    UAB_T_OUT="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/@out)" "$UAB_CONF_XML")"

    if [ "$("$UAB_EXEC_XMLLINT" --xpath "count(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/*[local-name()='Bundler'])" "$UAB_CONF_XML")" -ne 0 ]
    then
        UAB_T_BUNDLER="$("$UAB_EXEC_XMLLINT" --xpath "/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/*[local-name()='Bundler'][1]/text()" "$UAB_CONF_XML")"
    else
        UAB_T_BUNDLER=""
    fi

    UAB_T_PROP=""

    cnt="$("$UAB_EXEC_XMLLINT" --xpath "count(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/*[local-name()='Prop'])" "$UAB_CONF_XML")"
    for (( i = 1; i <= $cnt; i++ )); do
        k="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/*[local-name()='Prop'][$i]/@name)" "$UAB_CONF_XML")"
        v="$("$UAB_EXEC_XMLLINT" --xpath "string(/*[local-name()='UnityAutoBuild'][1]/*[local-name()='Targets']/*[local-name()='Config'][@id='$1']/*[local-name()='Prop'][$i]/@value)" "$UAB_CONF_XML")"
        UAB_T_PROP="$UAB_T_PROP --fix.uab.build.prop.$k=$v"
    done
}

####################
# Bundlers
####################
function uab_bundler_ZIP () {
    "$UAB_EXEC_ZIP" -qr "$1.zip" "$1"
}

function uab_bundler_TAR_XZ () {
    "$UAB_EXEC_TAR" cf - "$1" | "$UAB_EXEC_XZ" -T0 - > "$1.tar.xz"
}

function uab_bundler_TAR_GZ () {
    "$UAB_EXEC_TAR" czf "$1.tar.gz" "$1"
}
