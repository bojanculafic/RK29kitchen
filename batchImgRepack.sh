#!/bin/bash
#set -vx 

#settings for auto fix
mymodel="CUBE U9GT 2"
myopt="quiet"
mysystem=400
mysystemfs="ext3"
mycache=64
myuserdata=2048

usage(){
	echo Usage:
	echo    $0 path_to_image/file.img
}

if [ "x$1" == "x" ]
then
	usage
	exit 1
fi

BASEDIR=`dirname $0`
pushd "$BASEDIR"
BASEDIR=`pwd`
popd

WORKDIR=`dirname $1`
pushd "$WORKDIR"
WORKDIR=`pwd`"/"
popd

BINDIR="${BASEDIR}/bin"
LOGFILE="${BASEDIR}/log"
PLUGINS="${BASEDIR}/plugins"
PATH="${BINDIR}":$PATH
tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/rk29$$

export BASEDIR WORKDIR BINDIR LOGFILE PATH tempfile PLUGINS

trap "rm -f $tempfile" 0 1 2 5 15

declare MENUITEM
declare FUNCTION

rm "${LOGFILE}"
touch "${LOGFILE}"
chmod +x "${BINDIR}/"*


for file in `ls -1 "${PLUGINS}"/[0-9][0-9]\.*\.sh`
do
	chmod +x $file
	source $file
done

cd "${WORKDIR}"
workdir_Test
if [ ${WORKTYPE} -ne 4 ]
then
	usage
	exit 1
fi

#unpack img
extractImage_ExtractImgFile $1
extractImage_ExtractProcess

#parse && edit parameter file
PARAMFILE="parameter"
parameter_Parse
if [ ${PARAMFILEPARSED} -ne 1 ]
then
	return
fi
parameter_Edit "$mymodel" "$myopt" $mysystem $mycache $myuserdata
parameter_Make

resizeSystem_Process $[$mysystem-1] "$mysystemfs"

installApps_SU
installApps_BB
installApps_AllAPK

echo You can make changes manually now.
echo -n Make update.img y/n [y]?
read a
case "$a" in
        "y"|"Y"|"")
                makeUpdateProcess
                ;;
esac
