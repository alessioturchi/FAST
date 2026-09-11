#!/bin/bash
#Check if BACKUPLATER is set to 1 to see if we are running from run.sh
if [ $(set | awk -F "=" '{print $1}' |grep -x "BACKUPLATER"|wc -l) -ne 1 ]; then
  CONTROLNOW="later"
else
  if [ $BACKUPLATER -eq 0 ];then
    CONTROLNOW="now"
  else
    CONTROLNOW="later"
  fi
fi

if [ "${CONTROLNOW}" != "now" ]; then
  THISSCRIPT="$(test -L "$0" && readlink "$0" || echo "$0")"
  SCRIPTPATH="$(dirname ${THISSCRIPT})"
  SCRIPTNAME="$(basename ${THISSCRIPT})"
  REALPATH_NAME="$(realpath ${THISSCRIPT})"
  GLOBALCFG="${SCRIPTPATH}/conf.d/globals.var"
  GENERATELIST=0
  #Parse global config file
  source "${GLOBALCFG}"
  #Parse function definitions
  source "${FUNCFILE}"
  #Parte the time config file
  source "${TIME_VAR}"
  #Parse the run config file
  source "${RUN_VAR}"
  #Parse backup config file
  source "${BACKUP_VAR}"
  if [ -f "${PREPARE_DIR}/done_ascii.temp" ]; then
    DONEGROUNDASCII=1
  else
    DONEGROUNDASCII=0
  fi
  if [ -f "${PREPARE_DIR}/wind_high.temp" ]; then
    WINDAVGHIGH=1
  else
    WINDAVGHIGH=0
  fi
############################
#Activate the local python version
  source ${LOCPYTHONDIR}/activate
  EXIT=$?
  [ $EXIT -eq 0 ] || echo "!!! ERROR: CANNOT FIND LOCAL PYTHON"
  [ $EXIT -eq 0 ] || exit 1 
############################
#######################
#    !! WARNING !!    #
#######################
#OVERWRITING LOGDIR AND RELATED VARIABLES UNTIL END OF THE SCRIPT
     LOGDIR=$(find_directory_finished ${LOGDIR} ${WORKDIR})
     DATE_LASTLOG="${LOGDIR}/$(basename ${DATE_LASTLOG})"
     LOGFILE="${LOGDIR}/$(basename ${LOGFILE})"
     ERRFILE="${LOGDIR}/$(basename ${ERRFILE})"
#######################
#    !! WARNING !!    #
#######################
fi
##################################################################################################
##################################################################################################
cd ${WORKDIR}
if [ "${CONTROLNOW}" != "now" ]; then
  DOIT=0
  echo "*** ${DATE_LASTLOG}"
  file "${DATE_LASTLOG}"
  if [ -f "${DATE_LASTLOG}" ]; then
    CORRECTEND=$(cat "${DATE_LASTLOG}" |grep SIMULATION_FINISHED|cut -d"=" -f2)
    if [ ${CORRECTEND} = "T" ]; then
      DOIT=1
    else
      error_soft "!!! WARNING: BACKUP AND UPLOAD PHASE: last simulation did not yet finish - This might be a temporary problem and probably will be solved by retrying within few minutes."
      exit 0
    fi
  else
    echo "No previous simulation available - Exiting"
    exit 0
  fi
  if [ $UPLOAD -eq 1 -o $BACKUP -eq 1 ]; then
    #Check if previous simulation started
    test -f "${DATE_LASTLOG}" || error "!!! BACKUP AND UPLOAD PHASE: last simulation did not start correctly - ABORTING"
    #Check if the day is correct
    DAYRUN=$(cat "${DATE_LASTLOG}" |grep DAY|cut -d"=" -f2)
    DAYNOWUNIX=$(date -u +%s)
    DAYNOW=$(date -u -d @${DAYNOWUNIX} +%d)
    DAYSTARTBEFOREUNIX=$(($DAYSTARTBEFORE*86400))
    DAYBEFORE=$(date -u -d @$(($DAYNOWUNIX + $DAYSTARTBEFOREUNIX)) +%d)
    [ $DAYRUN -eq $(($DAYNOW + $DAYSTARTBEFORE)) ] || error_soft "!!! BACKUP AND UPLOAD PHASE:BACKUP AND UPLOAD PHASE: last simulation started on day ${DAYRUN} intead of $(($DAYNOW + $DAYSTARTBEFORE)) - continuing, however please check this"
    #Check if simulation finished correctly
    CORRECTMOVE=$(cat "${DATE_LASTLOG}" |grep MOVED_FINISHED|cut -d"=" -f2)
    [ ${CORRECTMOVE} = "T" ] || error "!!! BACKUP AND UPLOAD PHASE: last simulation did not finish correctly - ABORTING"
    #Set date to the stored one
    YEAR=$(cat "${DATE_LASTLOG}" |grep YEAR|cut -d"=" -f2)
    MONTH=$(cat "${DATE_LASTLOG}" |grep MONTH|cut -d"=" -f2)
    DAY=$(cat "${DATE_LASTLOG}" |grep DAY|cut -d"=" -f2)
    #Parse again to refresh directory path backup config file
    PARSEBACKUP=1
    source "${TIME_VAR}"
    source "${BACKUP_VAR}"
  fi
fi
#Final backup procedure
if [ $UPLOAD -eq 1 ];then
  #Check if prepare_site.sh finished correctly
#  CORRECTPREP=$(cat "${DATE_LASTLOG}" |grep PREPSITE|cut -d"=" -f2)
#  [ ${CORRECTPREP} = "T" ] || error_soft "!!! WARNING: BACKUP AND UPLOAD PHASE: prepare_site did not finish correctly"
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
  log " -- STARTING THE UPLOAD PHASE -- "
  if [ ${UPLOADFIGS} -eq 1 ]; then
    log "UPLOADING ALL FIGURES"
  else
    #WINDAVGHIGH AND WINDAVG COME FROM plot.sh
    if [ $WINDAVGHIGH -eq 1 ]; then
      log "UPLOADING ONLY WIND SPEED FIGURES"
    else
      log "AVERAGE WIND SPEED ON K=4 IS: $WINDAVG"
      log "NOT UPLOADING FIGURES"
    fi
  fi
  log " -- date_start_upload: "$(date +%F/%T)
  log "******************************"
  log "$(uptime)"
  log "$(free)"
  log "******************************"
  DATE_STARTUPLOAD_UNIX=$(date +%s)
#  ssh ${REMOTE_USER}@${REMOTE_HOST} ${REMOTE_COMMAND0}
#  EXIT=$?
#  [ $EXIT -eq 0 ] || error_soft "!!! WARNING: UPLOAD PROCEDURE FAILED - remote command: ${REMOTE_COMMAND0}"
#  ssh ${REMOTE_USER}@${REMOTE_HOST} ${REMOTE_COMMAND1}
#  EXIT=$?
#  [ $EXIT -eq 0 ] || error_soft "!!! WARNING: UPLOAD PROCEDURE FAILED - remote command: ${REMOTE_COMMAND1}"
  #Wait for the correct hour to upload
#  HOURNOW=$(date -u +%H)
#  while [ $HOURNOW -lt $UPLOAD_TIME ]; do
#    sleep 10m
#    HOURNOW=$(date -u +%H)
#  done
  PLOT_DIR_FINISHED=$(find_directory_finished ${PLOT_DIR} ${WORKDIR})
#MOVE THINGS IN THE APPROPRIATE ARCHIVE DIRECTORY
  if [ ${UPLOADFIGS} -eq 1 ]; then
    log "rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH_ARCHIVE}"
    rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH_ARCHIVE}
    EXIT=$?
    [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD PROCEDURE FAILED - syncing ARCHIVE"
    rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/ ${REMOTE_USER_BK}@${REMOTE_HOST_BK}:${REMOTE_PATH_ARCHIVE_BK}
    EXIT=$?
    [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD BACKUP PROCEDURE FAILED - syncing ARCHIVE"
  else
    #WINDAVGHIGH COMES FROM plot.sh
    if [ $WINDAVGHIGH -eq 1 ]; then
      rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/WIND/WS_LEVEL/ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH_ARCHIVE}WIND/WS_LEVEL/
      EXIT=$?
      [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD PROCEDURE FAILED - syncing ARCHIVE/WIND/WS_LEVEL/"
      rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/WIND/WS_LEVEL/ ${REMOTE_USER_BK}@${REMOTE_HOST_BK}:${REMOTE_PATH_ARCHIVE_BK}WIND/WS_LEVEL/
      EXIT=$?
      [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD BACKUP PROCEDURE FAILED - syncing ARCHIVE/WIND/WS_LEVEL/"

      rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/WIND/MAPS_K2/ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH_ARCHIVE}WIND/MAPS_K2/
      EXIT=$?
      [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD PROCEDURE FAILED - syncing ARCHIVE/WIND/MAPS_K2/"
      rsync -aO ${PLOT_DIR_FINISHED}/ARCHIVE/WIND/MAPS_K2/ ${REMOTE_USER_BK}@${REMOTE_HOST_BK}:${REMOTE_PATH_ARCHIVE_BK}WIND/MAPS_K2/
      EXIT=$?
      [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD BACKUP PROCEDURE FAILED - syncing ARCHIVE/WIND/MAPS_K2/"
    fi
  fi
###########################################
#SYNCING OUTPUTS GROUND DIRECTORY TO BKSERVER
  DOTHEUPLOAD=0
  if [ ${UPLOADFIGS} -eq 1 ]; then
    DOTHEUPLOAD=1
  else
    if [ $WINDAVGHIGH -eq 1 ]; then
      DOTHEUPLOAD=1
    fi
  fi
  if [ $DOTHEUPLOAD -eq 1 ]; then
    #DONEGROUNDASCII comes from plot.sh
    if [ $DONEGROUNDASCII -eq 1 ]; then
      GROUTFILE="${FINALOUTDIR}/${YEARB}${MONTHB}${DAYB}_params_output.dat"
      rsync -aO ${GROUTFILE} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH_OUTPUTS_GROUND}
      EXIT=$?
      [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD PROCEDURE FAILED - syncing OUTPUTS to ${REMOTE_HOST}"
      rsync -aO ${GROUTFILE} ${REMOTE_USER_BK}@${REMOTE_HOST_BK}:${REMOTE_PATH_OUTPUTS_GROUND_BK}
      EXIT=$?
      [ $EXIT -eq 0 ] || error_soft "!!! UPLOAD PROCEDURE FAILED - syncing OUTPUTS to ${REMOTE_HOST_BK}"
    fi
  fi
###########################################
  DATE_ENDUPLOAD_UNIX=$(date +%s)
  UPLOADTIME=$((DATE_STARTUPLOAD_UNIX - DATE_ENDUPLOAD_UNIX))
  UPLOADTIME=$(echo "scale=0;($UPLOADTIME/60)"|bc -l)
  log " ** Upload finished"
  log "Time spent on UPLOAD \(min\)           : $UPLOADTIME"
  echo "UPLOAD=T" >> "${DATE_LASTLOG}"
fi
############################################
#LOCAL BACKUP
############################################
if [ $BACKUP -eq 1 ];then
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
  log " -- STARTING THE BACKUP PHASE -- "
  log " -- date_start_backup: "$(date +%F/%T)
  log "******************************"
  log "$(uptime)"
  log "$(free)"
  log "******************************"
#LOCAL BACKUP OF FIGURES
  if [ ${UPLOADFIGS} -eq 1 ]; then
    if [ $BACKUPFIGURES -eq 1 ]; then
      check_directory "${BACKUP_FIGURES_DIR}"
      rsync -a ${PLOT_DIR_FINISHED}/ARCHIVE/ ${BACKUP_FIGURES_DIR}/
    fi
  else
    #WINDAVGHIGH COMES FROM plot.sh
    if [ $WINDAVGHIGH -eq 1 ]; then
      if [ $BACKUPFIGURES -eq 1 ]; then
        check_directory "${BACKUP_FIGURES_DIR}"
        rsync -a ${PLOT_DIR_FINISHED}/ARCHIVE/WIND/WS_LEVEL/ ${BACKUP_FIGURES_DIR}/WIND/WS_LEVEL/
        rsync -a ${PLOT_DIR_FINISHED}/ARCHIVE/WIND/MAPS_K2/ ${BACKUP_FIGURES_DIR}/WIND/MAPS_K2/
      fi
    fi
  fi
#START THE REAL BACKUP
  DATE_STARTMOVE_UNIX=$(date +%s)
  log " ** Backup on ${BACKUP_DIR}/"
  TMP=$(basename "${OUTPUT_MNH}")
#  check_directory "${BACKUP_DIR}"
  if [ $BACKUP_REAL -eq	1 ]; then
    check_directory "${BACKUP_REAL_NAME}"
    OUTDIR_REAL_FINISHED=$(find_directory_finished ${OUTDIR_REAL} ${WORKDIR})
    mv -T "${OUTDIR_REAL_FINISHED}" "${BACKUP_REAL_NAME}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${OUTDIR_REAL_FINISHED}"
#  else
#    rm "${OUTDIR_REAL_FINISHED}" -rf
  fi
  if [ $BACKUP_RUN -eq 1 ]; then
    OUTPUT_MNH_FINISHED=$(find_directory_finished ${OUTPUT_MNH} ${WORKDIR})
    check_directory "${BACKUP_RUN_NAME}"
    mv -T "${OUTPUT_MNH_FINISHED}" "${BACKUP_RUN_NAME}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${OUTPUT_MNH_FINISHED}"
#  else
#    rm "${OUTPUT_MNH_FINISHED}" -rf
  fi
  if [ $BACKUP_DIAG -eq 1 ]; then
    DIAG_MNH_FINISHED=$(find_directory_finished ${DIAG_MNH} ${WORKDIR})
    check_directory "${BACKUP_DIAG_NAME}"
    mv -T "${DIAG_MNH_FINISHED}" "${BACKUP_DIAG_NAME}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${DIAG_MNH_FINISHED}"
#  else
#    rm "${DIAG_MNH_FINISHED}" -rf
  fi
  if [ $BACKUP_POSTPROC -eq 1 ]; then
    ASCII_DIR_FINISHED=$(find_directory_finished ${ASCII_DIR} ${WORKDIR})
    DAT_DIR_FINISHED=$(find_directory_finished ${DAT_DIR} ${WORKDIR})
    FICVAL_DIR_FINISHED=$(find_directory_finished ${FICVAL_DIR} ${WORKDIR})
    AUTOREGRESSION_DIR_FINISHED=$(find_directory_finished ${AUTOREGRESSION_DIR} ${WORKDIR})
    DAT_DIR_FINISHED=$(find_directory_finished ${DAT_DIR} ${WORKDIR})
    PLOT_DIR_FINISHED=$(find_directory_finished ${PLOT_DIR} ${WORKDIR})
    PLOTDAT_DIR_FINISHED=$(find_directory_finished ${PLOTDAT_DIR} ${WORKDIR})

###############################################
#ADD HEADERS TO DAT FILES
    if [ -e "${DAT_DIR_FINISHED}"/cn2_new_algo_p1.dat ]; then
      addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC,  CN2(m^-2/3), ALT(m), TIME(s) -- CORRECTION_FROM_H=${CN2_WRESCALE_H} ALPHA=${CN2_ALPHA} BETA=${CN2_BETA}" "${DAT_DIR_FINISHED}"/cn2_new_algo_p1.dat
    fi
    if [ -e "${DAT_DIR_FINISHED}"/cn2_new_algo_p2.dat ]; then
      addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC,  CN2(m^-2/3), ALT(m), TIME(s) -- CORRECTION_FROM_H=${CN2_WRESCALE_H} ALPHA=${CN2_ALPHA} BETA=${CN2_BETA}" "${DAT_DIR_FINISHED}"/cn2_new_algo_p2.dat
    fi

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = CHT TIME(s)" "${DAT_DIR_FINISHED}"/cht_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = CHT TIME(s)" "${DAT_DIR_FINISHED}"/cht_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC,  CN2(m^-2/3), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/cn2_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC,  CN2(m^-2/3), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/cn2_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = ISO TIME(s)" "${DAT_DIR_FINISHED}"/iso_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = ISO TIME(s)" "${DAT_DIR_FINISHED}"/iso_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, LM(m), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/lm_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, LM(m), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/lm_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p1_k2.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p1_k3.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p1_k4.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p1_k5.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p1_k6.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p2_k2.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p2_k3.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p2_k4.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p2_k5.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = MR TIME(s)" "${DAT_DIR_FINISHED}"/mr_p2_k6.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, PRVT PRCT, ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/mr_prof_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, PRVT PRCT, ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/mr_prof_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, PHI3(dimensionless), ALT(m)" "${DAT_DIR_FINISHED}"/phi3_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, PHI3(dimensionless), ALT(m)" "${DAT_DIR_FINISHED}"/phi3_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p1_k2.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p1_k3.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p1_k4.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p1_k5.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p1_k6.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p2_k2.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p2_k3.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p2_k4.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p2_k5.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = RH(%), TIME(s)" "${DAT_DIR_FINISHED}"/rh_p2_k6.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, RH(%), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/rh_prof_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, RH(%), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/rh_prof_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = SEE TIME(s)" "${DAT_DIR_FINISHED}"/see_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = SEE TIME(s)" "${DAT_DIR_FINISHED}"/see_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST} - From level ${SEESTPOINT}" "Data columns = SEE TIME(s)" "${DAT_DIR_FINISHED}"/see_p1_v.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND} - From level ${SEESTPOINT}" "Data columns = SEE TIME(s)" "${DAT_DIR_FINISHED}"/see_p2_v.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, ABS_TEMP(K), PRESSURE(Pa), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/temp_pres_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, ABS_TEMP(K), PRESSURE(Pa), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/temp_pres_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, POT_TEMP(K), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/theta_prof_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, POT_TEMP(K), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/theta_prof_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, Vx(m/s), Vy(m/s), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/vx_vy_prof_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, Vx(m/s), Vy(m/s), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/vx_vy_prof_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p1_k2.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p1_k3.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p1_k4.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p1_k5.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p1_k6.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p2_k2.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p2_k3.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p2_k4.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p2_k5.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = WIND(m/s), ABS_TEMP(K), PRESSURE(Pa), Vx(m/s), Vy(m/s), TIME(s)" "${DAT_DIR_FINISHED}"/wind_and_temp_pres_vx_vy_p2_k6.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_FIRST}" "Data columns = NPROC, WIND(m/s), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/wind_prof_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, WIND(m/s), ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/wind_prof_p2.dat

    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, ZW2, ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/ws_prof_p1.dat
    addheaders "Start of simulation (yyyy/mm/dd:hh) = ${YEARB}/${MONTHB}/${DAYB}-${HOUR_ARRAY[0]}:00 - Domain ${DOM_SECOND}" "Data columns = NPROC, ZW2, ALT(m), TIME(s)" "${DAT_DIR_FINISHED}"/ws_prof_p2.dat
###############################################

    check_directory "${BACKUP_MNHDAT_NAME}"
    check_directory "${BACKUP_POSTPROC_NAME}"
    mv "${DAT_DIR_FINISHED}" "${BACKUP_MNHDAT_NAME_DAT}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${DAT_DIR_FINISHED}"
    mv "${FICVAL_DIR_FINISHED}" "${BACKUP_MNHDAT_NAME_FICVAL}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${FICVAL_DIR_FINISHED}"
    mv "${AUTOREGRESSION_DIR_FINISHED}" "${BACKUP_MNHDAT_NAME_AUTOREGRESSION}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${AUTOREGRESSION_DIR_FINISHED}"
    mv "${PLOTDAT_DIR_FINISHED}" "${BACKUP_POSTPROC_NAME_ASCII}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${PLOTDAT_DIR_FINISHED}"
    mv "${PLOT_DIR_FINISHED}" "${BACKUP_POSTPROC_NAME_PLOT}"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! BACKUP FAILED - Failed to move ${PLOT_DIR_FINISHED}"
#  else
#    rm "${ASCII_DIR_FINISHED} ${PLOT_DIR_FINISHED}" -rf
  fi
#  cp -r "${PGDDIR}" "${BACKUP_DIR}/"
  DATE_ENDMOVE_UNIX=$(date +%s)
  MOVETIME=$((DATE_STARTMOVE_UNIX - DATE_ENDMOVE_UNIX))
  MOVETIME=$(echo "scale=0;($MOVETIME/60)"|bc -l)
  log " ** Backup finished"
  log "Time spent on BACKUP \(min\)           : $MOVETIME"
  echo "BACKUP=T" >> "${DATE_LASTLOG}"
#Finish
#Finally Move the $LOGDIR
  if [ $BACKUP_LOG -eq 1 ]; then
    CURRENTDIR=$(pwd)
#    check_directory "${BACKUP_LOG_NAME}"
#    cd "$(dirname ${LOGDIR})"
#    tar cvzf LOGS.tgz "$(basename ${LOGDIR})"
    EXIT=$?
    [ $EXIT -eq 0 ] || error_soft "!!! WARNING: BACKUP FAILED - Failed to compress ${LOGDIR}"
#    mv LOGS.tgz "${BACKUP_LOG_NAME}/LOGS_${YEAR}${MONTH}${DAY}${TAIL_DIR}.tgz"
    mv "${LOGDIR}" "${BACKUP_LOG_NAME}/"
    EXIT=$?
    [ $EXIT -eq 0 ] || error_soft "!!! WARNING: BACKUP FAILED - Failed to move ${LOGDIR}"
    cd "${CURRENTDIR}"
    rm "${LOGDIR}" -rf
    EXIT=$?
    [ $EXIT -eq 0 ] || error_soft "!!! WARNING: BACKUP FAILED - Failed to remove ${LOGDIR}"
  else
    rm "${LOGDIR}" -rf
  fi
#Fix permissions on files
  find "${BACKUP_BASE_NAME}" -type f -print -exec chmod 444 {} \;
#Compress the backup
  cd "${BACKUP_DIR}"
  NAMEDIR=$(basename "${BACKUP_BASE_NAME}")
  NAMETAR="${NAMEDIR}.tar.bz2"
  tar -cvjpf "${NAMETAR}" "${NAMEDIR}"
  cd "${WORKDIR}"
  rm "${BACKUP_BASE_NAME}" -rf
fi

test -d "${PREPARE_DIR}" && rm "${PREPARE_DIR}" -rf

# FINISH EVERYTHING AND SEND A NOTE
#TIMESTAMP=$(date +%F/%T)
#[ $TESTRUN -eq 0 ] && send_mail_finished "BACKUP AND UPLOAD FINISHED ${SITE_NAME} ${TIMESTAMP}" "${TIMESTAMP} - "
##################################################################################################
##################################################################################################
