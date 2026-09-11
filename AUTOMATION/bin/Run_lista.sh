#!/bin/bash
FILE_LIST=LISTAgrib
FILEDEF_FILE=run.var
CONFDDIR="conf.d/"
GLOBALCFG="conf.d/globals.var"
source "${GLOBALCFG}"

TESTDIR="${WORKDIR}/CPUTEST"
RUNFILE="${WORKDIR}/RUN_ALL.sh"
test -d "${TESTDIR}" || mkdir -p "${TESTDIR}"
cp -a "${EXEDIR}/crossc2d.py" "${TESTDIR}"
cp -a "${EXEDIR}/multi.py" "${TESTDIR}"

DATELIST=$(cat "${FILE_LIST}"|grep "*"|cut -d"*" -f2-)
DATE_ARRAY=($DATELIST)
NUMDATE="${#DATE_ARRAY[@]}"

GRIBLIST=$(cat "${FILE_LIST}"|grep -v "*")
GRIB_ARRAY=($GRIBLIST)
NUMGRIB="${#GRIB_ARRAY[@]}"

TMP1=0
TMP2=0

echo "" > "${RUNFILE}"

while [ $TMP1 -lt $NUMDATE ]; do
  YEAR=$(echo ${DATE_ARRAY[$TMP1]}|cut -d"/" -f1)
  MONTH=$(echo ${DATE_ARRAY[$TMP1]}|cut -d"/" -f2)
  DAY=$(echo ${DATE_ARRAY[$TMP1]}|cut -d"/" -f3)
  echo $YEAR $MONTH $DAY
  cp "${FILEDEF_FILE}" "${CONFDDIR}" -f
  sed -e "s/YEAR_VAR/$YEAR/;s/MONTH_VAR/$MONTH/;s/DAY_VAR/$DAY/" -i "${CONFDDIR}/${FILEDEF_FILE}"
  env bash -c ./prep_list.sh >> "${RUNFILE}"
  echo "cd ${TESTDIR}" >> "${RUNFILE}"
  echo "python multi.py 80" >> "${RUNFILE}"
  echo "cd ${WORKDIR}" >> "${RUNFILE}"
  echo "sleep 1m" >> "${RUNFILE}"
  TMP1=$(($TMP1+1))
done

chmod 775 "${RUNFILE}"
