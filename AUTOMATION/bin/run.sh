#!/bin/bash
#Save the path variable
OLD_PATH="$PATH"
#Get the path of this script
THISSCRIPT="$(test -L "$0" && readlink "$0" || echo "$0")"
SCRIPTPATH="$(dirname ${THISSCRIPT})"
SCRIPTNAME="$(basename ${THISSCRIPT})"
REALPATH_NAME="$(realpath ${THISSCRIPT})"
#get globals.var
GLOBALCFG="${SCRIPTPATH}/conf.d/globals.var"
#First of all store the initial starting date
DATE_FIRST=$(date +%F/%T)
DATE_FIRST_UNIX=$(date +%s)
TODAY=$(date -u +%F)
GENERATELIST=0
#Parse global config file
source "${GLOBALCFG}"
############################
#Activate the local python version
source ${LOCPYTHONDIR}/activate
EXIT=$?
[ $EXIT -eq 0 ] || echo "!!! ERROR: CANNOT FIND LOCAL PYTHON"
[ $EXIT -eq 0 ] || exit 1 
############################
#Go to $WORKDIR
cd "${WORKDIR}"
#Parse function definitions
source "${FUNCFILE}"
#Check if something is still running and kill it
echo "**************************************************************************"
echo "${DATE_FIRST} - START run.sh"
echo "Killing old processes"
pkill -9 "$(basename ${EXE_REAL})"
pkill -9 "$(basename ${EXE_SPAWNING})"
pkill -9 "$(basename ${EXE_RUN})"
pkill -9 "$(basename ${EXE_DIAG})"
pkill -9 "$(basename ${EXE_CONV2DIA})"
pkill -9 "$(basename ${EXE_PREP_PGD})"
pkill -9 "$(basename ${EXE_PREP_NEST_PGD})"
pkill -9 "$(basename ${EXE_DIAPROG})"
pkill -9 "bzip2"
echo "Old processes killed"
#rotate logfile
rotate_log
#Start logging
log "**************************************************************************"
log " -- DATE START=$DATE_FIRST"
log " -- PROGRAM STARTING"
log " -- Start Logging"
log "******************************"
log "$(uptime)"
log "$(free)"
log "******************************"
#Check other config files are correct and parse them
source "${TIME_VAR}"
#UTC time at which forecast files should arrive
TIMESENDUTC=$(date -u -d "$TODAY $TIMESEND" +%s)
source "${RUN_VAR}"
#Compute end of simulation
ENDSIMUL=${XFMOUT[$(($NUMOUTTIMES-1))]}
ENDSIMULUNIX=$(($DATESTARTDAYBUNIX+$ENDSIMUL))
ENDSIMUL=$(($ENDSIMUL/60))
log "SIMULATION ENDS AT:      $(date -u -d @${ENDSIMULUNIX} +%F/%T)"
#Perform a couple of checks if we are not in testing mode
if [ $SEASONSPLOT -eq 1 ]; then
  if [ $TESTRUN -eq 0 ]; then
    if [ $SUNSETMINDELTA -lt 0 ]; then
      error "!!! ERROR: SUNSET $(date -u -d @${SUNSETUNIX} +%F/%T) is before start time $(date -u -d @${DATESTARTDAYBUNIX} +%F/%T) - ABORTING"
    fi
    if [ $SUNRISEMINDELTA -ge $ENDSIMUL  ]; then
      error "!!! ERROR: SUNRISE $(date -u -d @${SUNRISEUNIX} +%F/%T) is after the end of simulation $(date -u -d @${DATESTARTDAYBUNIX} +%F/%T) - ABORTING"
    fi
  fi
fi
#Parse filedef.var
source "${FILEDEF_VAR}"
#Parse backup config file
source "${BACKUP_VAR}"
#Clear files left there by previous simulations
clear_old
#Log config parameters
log " ** PARAMS:"
log " **   Simulation run with ${MESONH_VERSION_FULL} and MPI (${MPI_ROOT})"
log " **   From ${DAYB}-${MONTH}-${YEAR} at ${#HOUR_ARRAY[0]} UT"
log " **   Number of threads used = $NUM_PROC"
log " **   REAL   DIRECTORY = $OUTDIR_REAL"
log " **   OUTPUT DIRECTORY = $OUTPUT_MNH"
log " **   DIAG DIRECTORY = $DIAG_MNH"
log " **   Time Step Model 1 = $XTSTEP_VAR s"
log " **   Time Step Ratio = ${NDTRATIO_ARRAY[@]}" 
log " **   CCLOUD = $CCLOUD_VAR"
log " **   Segment Length = $XSEGLEN s"
log " **   1st dat point domain: $DOM_FIRST"
log " **   1st dat point coordinates: $XSNG1,$YSNG1"
log " **   2nd dat point domain: $DOM_SECOND"
log " **   2nd dat point coordinates: $XSNG2,$YSNG2"
log " **   DIAG phase on levels = ${DIAGLEVELARRAY[@]}"
log "******************************"
log " **   COMPLETE LIST OF INPUT PARAMETERS:"
log_variable_file "${EXEDIR}$(echo $GLOBALCFG |cut -d"." -f2-)"
log_variable_file "${TIME_VAR}"
log_variable_file "$RUN_VAR"
log_variable_file "$FILEDEF_VAR"
log_variable_file "$BACKUP_VAR"
log "******************************"
#Store last sim date, for debug purposes
test -e "${DATE_LASTLOG}" && rm "${DATE_LASTLOG}" -f
echo '#Date last sim: '"${DATE_FIRST}" > "${DATE_LASTLOG}"
echo "SITE=$SITE_NAME" >> "${DATE_LASTLOG}"
echo "YEAR=$YEAR" >> "${DATE_LASTLOG}"
echo "MONTH=$MONTH" >> "${DATE_LASTLOG}"
echo "DAY=$DAY" >> "${DATE_LASTLOG}"
if [ $TESTRUN -eq 0 ] && [ $NOPREP -eq 0 ] && [ $NORUN -eq 0 ]; then
  if [ $PREPLISTTRUE -eq 1 ]; then
    cd "${EXEDIR}"
    env bash -c "${EXEDIR}/prep_list.sh"
    cd "${WORKDIR}"
    mv "${WORKDIR}/"*.PREP* "${LOGDIR}/"
  fi
fi

#Check initial directory structure is safe
check_directory "$WORKDIR"
check_directory "$CONFDIR"
check_directory "$LOGDIR"
check_directory "$PGDDIR"
#check_directory "$INIDIR"
#Check PGD files exist
check_pgd

#Compute timesteps for loggin purposes
log "*****************************************"
log " TIMESTEPS:"
LEVEL=0
while [ $LEVEL -lt $NESTING ]; do
  TMP=1
  STRING="scale=4;(${XTSTEP_VAR}"
  while [ $TMP -le ${LEVEL} ]; do
    STRING="${STRING}/${NDTRATIO_ARRAY[$TMP]}"
    TMP=$(($TMP+1))
  done
  STRING="${STRING})"
  TIMESTEP_ARRAY[$LEVEL]=$(echo "${STRING}"|bc -l)
  LEVEL=$(($LEVEL+1))
done
if [ $GENERATELIST -eq 0 ]; then
  TMP=0
  while [ $TMP -lt $NESTING ]; do
    log "TIMESTEP LEVEL $((TMP + 1)) = ${TIMESTEP_ARRAY[$TMP]}"
    TMP=$(($TMP+1))
  done
fi
log "*****************************************"

##################################################################################################
# PREP REAL PHASE START
##################################################################################################
# Output files for PREP_REAL, self-generated
# Run only if $NOPREP=0 (else is debug, don not do it if you do not know what you are doing)
#Cycle on all the levels (outer + nesting)
if [ $NOPREP -eq 0 -o $NORUN -eq 0 ]; then
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
  log " -- STARTING PREP_REAL PHASE"
  log " -- date_start_prep:   "$(date +%F/%T)
  log "******************************"
  log "$(uptime)"
  log "$(free)"
  log "******************************"
  check_directory "$OUTDIR_REAL"
  check_directory "$OUTDIR_PREP"
fi
DATE_STARTREAL_UNIX=$(date +%s)
if [ $NOPREP -eq 1 ] && [ $NORUN -eq 0 ]; then
  check_directory "$OUTDIR_REAL"
  NFILES=$(find "${OUTDIR_REAL}" -maxdepth 1 -name "*.lfi.bz2"|wc -l)
  if [ $NFILES -gt 0 ]; then
    log " *** Decompressing files for SIMULATION phase *** "
    FILETODECOMPRESS=$(find "${OUTDIR_REAL}" -maxdepth 1 -name "*.lfi.bz2")
    parallel --gnu -j $NUM_PROC bunzip2 ::: "$FILETODECOMPRESS"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR decompressing files in ${OUTDIR_REAL}"
  fi
fi
TMPNEST=0
TMPANA=0
#Prepare the namelists for PREP_REAL
if [ $NOPREP -eq 0 -o $NORUN -eq 0 ]; then
  log " -- Preparing NAMELISTS for PREP_REAL"
  namelists_real
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing NAMELISTS for PREP_REAL - ABORTING"
  log " -- NAMELISTS prepared, executing PREP_REAL"
fi
##############################
#Perform mpirun on PREP_REAL
TMPNEST=0
TMPANA=0
if [ $NOPREP -eq 0 -o $NORUN -eq 0 ]; then
  while [ $TMPNEST -lt $NESTING ]; do
    #Prepare links for PGD files
    check_link "${PGD_ARRAY[$TMPNEST]}.des" "${PGD_ARRAY_BASE[$TMPNEST]}.des"
    check_link "${PGD_ARRAY[$TMPNEST]}.lfi" "${PGD_ARRAY_BASE[$TMPNEST]}.lfi"
    if [ $TMPNEST -eq 0 ]; then
      check_link "${INIT_ARRAY[$TMPANA]}" "${INIT_ARRAY_BASE[$TMPANA]}"
    else
      check_link "${INIT_ARRAY[$TMPANA]}.des" "${INIT_ARRAY_BASE[$TMPANA]}.des"
      check_link "${INIT_ARRAY[$TMPANA]}.lfi" "${INIT_ARRAY_BASE[$TMPANA]}.lfi"
    fi
    #Let's start from the outer layer and descend later into the nested levels
#    #Check if we are on the first nested layer. If this is true the input should be FILE_FILEOUT_ARRAY[0], (the first one before forcing). Else everithing is standard.
#    if [ $TMPNEST -eq 1 ]; then
#      TMP=0
#    else
#      TMP=$(($TMPANA-1))
#    fi
    if [ $NOPREP -eq 0 ]; then
      #Check that we do not have cruft left from previous runs and link the things that we have to pass to prep_list_real
      #This is just to be sure that we do not have old files lingering in the directory structure
      test -L "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.des" && rm "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.des"
      test -L "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.lfi" && rm "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.lfi"
      if [ $TMPNEST -ge 1 ]; then
        #The spawning phase generatefiles INIT$TMPANA.spa.des and INIT$TMPANA.spa.lfi. This is addressed here and corrected through linkng later
        test -L "${INIT_ARRAY_BASE[$TMPANA]}.spa.des" && rm "${INIT_ARRAY_BASE[$TMPANA]}.spa.des"
        test -L "${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi" && rm "${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi"
#####################
	log " -- Generating spawning files for files for ${NAMELIST_REALSPAWNARRAY[$TMPANA]}"
	test -e SPAWN1.nam && rm SPAWN1.nam -f
	test -f "${NAMELIST_REALSPAWNARRAY[$TMPANA]}" || error "!!! REAL phase : namelist ${NAMELIST_REALSPAWNARRAY[$TMPANA]} missing - ABORTING"
	cp "${NAMELIST_REALSPAWNARRAY[$TMPANA]}" SPAWN1.nam
        #Do we really want to spam the logfile with the noisy output from MESO-NH, do we log those cruft into a separate logfile or we simply print everything onscreen?
        if [ $LOGEXE -eq 0 ]; then
          mpirun  -np 1 "${EXE_SPAWNING}"
          EXIT=$?
        elif [ $LOGEXE -eq 1 ]; then
          mpirun  -np 1 "${EXE_SPAWNING}" >> "$LOGFILEEXEREAL"
          EXIT=$?
          echo "*******************************************************" >> "$LOGFILEEXEREAL"
          echo "*******************************************************" >> "$LOGFILEEXEREAL"
        else
          mpirun  -np 1 "${EXE_SPAWNING}" >> "$LOGFILE"
          EXIT=$?
        fi
        [ $EXIT -eq 0 ] || error "!!! prep_list_real: error generating spawning files from ${NAMELIST_REALSPAWNARRAY[$TMPANA]} - ABORTING"
        for i in $(find -maxdepth 1 -type f -name "OUTPUT_LISTING*"); do
          mv "${i}" "$OUTDIR_PREP/${i}_"$(basename ${NAMELIST_REALSPAWNARRAY[$TMPANA]})
        done
        rm SPAWN1.nam -f
        log " - Spawning files fromm $(basename "${NAMELIST_REALSPAWNARRAY[$TMPANA]}") generated"
#####################
      fi
#####################
      log " - Generating initial files for ${NAMELIST_REALARRAY[$TMPANA]}"
      test -e PRE_REAL1.nam && rm PRE_REAL1.nam -f
      test -f "${NAMELIST_REALARRAY[$TMPANA]}" || error "!!! REAL phase : namelist ${NAMELIST_REALARRAY[$TMPANA]} missing - ABORTING"
      cp "${NAMELIST_REALARRAY[$TMPANA]}" PRE_REAL1.nam
      if [ $LOGEXE -eq 0 ]; then
        mpirun  -np 1 "${EXE_REAL}"
        EXIT=$?
      elif [ $LOGEXE -eq 1 ]; then
        mpirun  -np 1 "${EXE_REAL}" >> "$LOGFILEEXEREAL"
        EXIT=$?
        echo "*******************************************************" >> "$LOGFILEEXEREAL"
        echo "*******************************************************" >> "$LOGFILEEXEREAL"
      else
        mpirun  -np 1 "${EXE_REAL}" >> "$LOGFILE"
        EXIT=$?
      fi
      [ $EXIT -eq 0 ] || error "!!! prep_list_real: error generating initial files from ${NAMELIST_REALARRAY[$TMPANA]} - ABORTING"
      for i in $(find -maxdepth 1 -type f -name "OUTPUT_LISTING*"); do
        mv "${i}" "$OUTDIR_PREP/${i}_"$(basename ${NAMELIST_REALARRAY[$TMPANA]})
      done
      rm PRE_REAL1.nam -f
      log " - Initial files fromm $(basename ${NAMELIST_REALARRAY[$TMPANA]}) generated"
#####################
      mv "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.des" "${FILE_FILEOUT_ARRAY[$TMPANA]}.des" || error "!!! Error moving ${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.des to ${FILE_FILEOUT_ARRAY[$TMPANA]}.des"
      mv "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.lfi" "${FILE_FILEOUT_ARRAY[$TMPANA]}.lfi" || error "!!! Error moving ${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.lfi to ${FILE_FILEOUT_ARRAY[$TMPANA]}.lfi"
      if [ $TMPNEST -ge 1 ]; then
        mv "${INIT_ARRAY_BASE[$TMPANA]}.spa.des" "$OUTDIR_REAL/${INIT_ARRAY_BASE[$TMPANA]}.spa.des" || error "!!! Error moving ${INIT_ARRAY_BASE[$TMPANA]}.spa.des to ${INIT_ARRAY[$TMPANA]}.spa.des"
        mv "${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi" "$OUTDIR_REAL/${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi" || error "!!! Error moving ${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi to ${INIT_ARRAY[$TMPANA]}.spa.lfi"
      fi
    fi
    check_link "${FILE_FILEOUT_ARRAY[$TMPANA]}.des" "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.des"
    check_link "${FILE_FILEOUT_ARRAY[$TMPANA]}.lfi" "${FILE_FILEOUT_ARRAY_BASE[$TMPANA]}.lfi"
    if [ $TMPNEST -ge 1 ]; then
      check_link "$OUTDIR_REAL/${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi" "${INIT_ARRAY_BASE[$TMPANA]}.spa.des"
      check_link "$OUTDIR_REAL/${INIT_ARRAY_BASE[$TMPANA]}.spa.des" "${INIT_ARRAY_BASE[$TMPANA]}.spa.lfi"
    fi
    #Increment TMPANA (CALLNUMBER)
    TMPANA=$(($TMPANA+1))
    if [ $TMPANA -ge $NUMANA ]; then
      #increment TMPNEST (NESTLEVEL)
      TMPNEST=$(($TMPNEST+1))
    fi
  done
#  if [ $PREPLISTTRUE -eq 1 ]; then
#    mv "${WORKDIR}/1.PREP_EXP_REAL*" "${OUTDIR_REAL}/"
#  fi
fi
##################################################################################################
##################################################################################################

#Generate list of generated files. Not really used but useful in debugging
if [ $NOPREP -eq 0 -o $NORUN -eq 0 ]; then
  NUMFILEOUT=${#FILE_FILEOUT_ARRAY[@]}
  if [ $NUMFILEOUT -ne $(($NUMHOURS+$NUMPGD-1)) ]; then
    error "!!! In filedef.var: The number of FILEOUT files and PGD files is incompatible - ABORTING"
  fi
fi
DATE_ENDREAL_UNIX=$(date +%s)
log " -- date_end_prep:   "$(date +%F/%T)
log " -- PREP_REAL PHASE ENDED"

##################################################################################################
# EXE PHASE START
##################################################################################################
# SIMULATION START, namelsits are self-generated
# Prepare NAMELISTS
if [ $NORUN -eq 0 ]; then
  #Fancy logging
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
  log " -- Starting the EXSEG phase -- "
  log " -- date_start_sim: "$(date +%F/%T)
  log "******************************"
  log "$(uptime)"
  log "$(free)"
  log "******************************"
  check_directory "$OUTPUT_MNH"
  check_directory "$DAT_DIR"
  check_directory "$PREP_MNH"
fi
if [ $NORUN -eq 0 ]; then
  #Prepare namelists for each level of nesting. They end up in $OUTPUT_MNH/
  log " -- Preparing NAMELISTS for EXSEG phase"
  GENERATELIST=0
  prep_list_run
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing NAMELISTS for EXSEG - ABORTING"
  log " -- NAMELISTS prepared, executing EXSEG"
fi
# Run only if $NORUN=0 (else is debug, don not do it if you do not know what you are doing)
DATE_STARTEXE_UNIX=$(date +%s)
if [ $NORUN -eq 0 ]; then
  log " -- STARTING THE SIMULATION -- "
  #If old namelists are present delete them
  [ $(find . -name "EXSEG*"|wc -l) -gt 0 ] && rm EXSEG* -f
  [ $(find . -name "SURF*"|wc -l) -gt 0 ] && rm SURF* -f
  #Copy previously generated namelists in $WORKDIR with the name that MESO-NH likes
  for i in $(find "${PREP_MNH}/" -name "EXSEG*"|sort); do
    NAMENLFILE=$(basename "$i")
    NUMRUN=$(basename "$i"|cut -d"." -f1|cut -d"G" -f2)
    cp "$PREP_MNH/${NAMENLFILE}" EXSEG${NUMRUN}.nam
    cp "$PREP_MNH/${NAMENLFILE}" SURF${NUMRUN}.nam
  done
  #Do we really want to spam the logfile with the noisy output from MESO-NH, do we log those cruft into a separate logfile or we simply print everything onscreen?
  if [ $LOGEXE -eq 0 ]; then
    mpirun -np ${NUM_PROC} "${EXE_RUN}"
    EXIT=$?
  elif [ $LOGEXE -eq 1 ]; then
    mpirun -np ${NUM_PROC} "${EXE_RUN}" >> "$LOGFILEEXERUN"
    EXIT=$?
    echo "*******************************************************" >> "$LOGFILEEXERUN"
    echo "*******************************************************" >> "$LOGFILEEXERUN"
  else
    mpirun --report-bindings --map-by core --bind-to core -np ${NUM_PROC} "${EXE_RUN}" >> "$LOGFILE"
    EXIT=$?
  fi
  [ $EXIT -eq 0 ] || error "!!! ERROR RUNNING THE SIMULATION - ABORTING"
  log " -- date_end_sim:   "$(date +%F/%T)
  log " -- SIMULATION ENDED -- "
  #Move output files into "${OUTPUT_MNH}/"
  mv OUTPUT_* "${PREP_MNH}/"
  mv *.y${YEAR}.???.{des,lfi} "${OUTPUT_MNH}/"
#  if [ $PREPLISTTRUE -eq 1 ]; then
#    cp *.dat "${OUTPUT_MNH}/"
#    cp "$LOGFILEEXERUN" "${OUTPUT_MNH}/${NAM_SIMU}_a.out"
#    mv "${WORKDIR}/1.PREP_EXP_REAL*" "${OUTDIR_REAL}/"
#  fi
  mv *.dat "${DAT_DIR}/"
  #remove the namelists and any unwanted file or link
  rm *.nam -f
  rm pipe_name -f
  rm PRESSURE -f
  rm REMAP* -f
  rm file_for_xtransfer -f
  for i in $(find -maxdepth 1 -type l); do
    rm "${i}" -f
  done
  #Compute total number of .lfi files created by simulation
  NUMOUTCREATED=$(find "${OUTPUT_MNH}/" -maxdepth 1 -name "*.lfi"|wc -l)
  #Compute the theoretical number of files to be produced from intial variables
  THEORETICALNUM=$(echo "scale=0;$XSEGLEN/$OUTTIMESTEP"|bc -l)
  #If $NUMOUTTIMES is less than the above number, then you must consider only $NUMOUTTIMES .lfi files
  if [ $NUMOUTTIMES -lt $THEORETICALNUM ]; then
    THEORETICALNUM=$NUMOUTTIMES
  fi
  #ADD the 000 first output
  THEORETICALNUM=$(($THEORETICALNUM+1))
  #Multiply by $NESTING
  THEORETICALNUM=$(($THEORETICALNUM*$NESTING))
  if [ $NUMOUTCREATED -ne $THEORETICALNUM ]; then
    error "!!! ERRROR: SOME OR ALL OUTPUT FILES MISSING! ($NUMOUTCREATED != $THEORETICALNUM)- ABORTING"
  fi
else
  if [ $NODIAG -eq 0 ]; then
    check_directory "$OUTPUT_MNH"
    NFILES=$(find "${OUTPUT_MNH}" -maxdepth 1 -name "*.lfi.bz2"|wc -l)
    if [ $NFILES -gt 0 ]; then
      log " *** Decompressing files for DIAG phase *** "
      FILETODECOMPRESS=$(find "${OUTPUT_MNH}" -maxdepth 1 -name "*.lfi.bz2")
      parallel --gnu -j $NUM_PROC bunzip2 ::: "$FILETODECOMPRESS"
      EXIT=$?
      [ $EXIT -eq 0 ] || error "!!! ERROR decompressing files in ${OUTPUT_MNH}"
    fi
  fi
fi
DATE_ENDEXE_UNIX=$(date +%s)
##################################################################################################
##################################################################################################

##################################################################################################
# POSTPROC PHASE START
##################################################################################################
# DIAG phase and FICVAL phase start
# DIAG starts only if $NODIAG=0 (else is debug, don not do it if you do not know what you are doing)
# FICVAL starts only if $FICVAL=0 (else is debug, don not do it if you do not know what you are doing)
DATE_STARTDIAG_UNIX=$(date +%s)
source ${EXEDIR}/postproc.sh
DATE_ENDDIAG_UNIX=$(date +%s)
rm FICJD OUT_DIA -f
##################################################################################################
##################################################################################################

##################################################################################################
# PLOT PHASE START
##################################################################################################
# PLOT phase start
# Run only if $NOPLOT=0 (else is debug, don not do it if you do not know what you are doing)

DATE_STARTPLOT_UNIX=$(date +%s)
if [ $NOPLOT -eq 0 ]; then
  cd ${WORKDIR}
#  source ${EXEDIR}/plot_cn2wind.sh
  source ${EXEDIR}/plot_python.sh
#  source ${EXEDIR}/plot.sh
fi
DATE_ENDPLOT_UNIX=$(date +%s)

rm FICJD OUT_DIA -f
##################################################################################################
##################################################################################################
#Final steps, optionally compress output files and backup
#Fancy logging
log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
log " -- STARTING THE COMPRESS PHASE -- "
log " -- date_start_compress: "$(date +%F/%T)
log "******************************"
log "$(uptime)"
log "$(free)"
log "******************************"
DATE_STARTBK_UNIX=$(date +%s)
if [ $DOZIPREAL -eq 1 ]; then
  NFILES=$(find "${OUTDIR_REAL}" -maxdepth 1 -name "*.lfi"|wc -l)
  if [ $NFILES -ge 1 ]; then
    FILETOCOMPRESS=$(find "${OUTDIR_REAL}" -maxdepth 1 -name "*.lfi")
    log " *** Compressing files in ${OUTDIR_REAL} *** "
    parallel --gnu -j $NUM_PROC bzip2 ::: "$FILETOCOMPRESS"
    EXIT=$?
  else
    EXIT=0
  fi
  [ $EXIT -eq 0 ] || error "!!! ERROR compressing files in ${OUTDIR_REAL}"
fi
if [ $DOZIPOUT -eq 1 ]; then
  NFILES=$(find "${OUTPUT_MNH}" -maxdepth 1 -name "*.lfi"|wc -l)
  if [ $NFILES -ge 1 ]; then
    FILETOCOMPRESS=$(find "${OUTPUT_MNH}" -maxdepth 1 -name "*.lfi")
    log " *** Compressing files in ${OUTPUT_MNH} *** "
    parallel --gnu -j $NUM_PROC bzip2 ::: "$FILETOCOMPRESS"
    EXIT=$?
  else
    EXIT=0
  fi
  [ $EXIT -eq 0 ] || error "!!! ERROR compressing files in ${OUTPUT_MNH}"
fi
if [ $DOZIPDIAG -eq 1 ]; then
  NFILES=$(find "${DIAG_MNH}" -maxdepth 1 -name "*.lfi"|wc -l)
  if [ $NFILES -ge 1 ]; then
    FILETOCOMPRESS=$(find "${DIAG_MNH}" -maxdepth 1 -name "*.lfi")
    log " *** Compressing files in ${DIAG_MNH} *** "
    parallel --gnu -j $NUM_PROC bzip2 ::: "$FILETOCOMPRESS"
    EXIT=$?
  else
    EXIT=0
  fi
  [ $EXIT -eq 0 ] || error "!!! ERROR compressing files in ${DIAG_MNH}"
fi

#Move also the runscript and config files, for documentation, backup and reproducibility
log " - Backing up scripts"
check_directory "${LOGDIR}/BACKUP_SCRIPT"
if [ $PREPLISTTRUE -eq 1 ]; then
  mv "${LOGDIR}/"*.PREP* "${LOGDIR}/BACKUP_SCRIPT"
fi
cp -r "${EXEDIR}" "${LOGDIR}/BACKUP_SCRIPT/"
EXIT=$?
[ $EXIT -eq 0 ] || error_soft "!!! WARNING: Failed to copy ${EXEDIR} to ${LOGDIR}"
#    cp -r "${CONFDIR}" "${LOGDIR}/BACKUP_SCRIPT/"
#    EXIT=$?
#    [ $EXIT -eq 0 ] || error_soft WARNING: "!!! BACKUP FAILED - Failed to copy ${CONFDIR}"
log " - Backup scripts finished"

# MOVE THINGS INTO FINISHED DIRECTORY AND PREPARE FOR FUTURE BACKUP

if [ $UPLOAD -eq 1 -o $BACKUP -eq 1 ]; then
  test -e "${PREPARE_DIR}" && rm "${PREPARE_DIR}" -rf
  check_directory "${PREPARE_DIR}"
  if [ $BACKUP_REAL -eq 1 ]; then
    log "Moving ${OUTDIR_REAL} to ${PREPARE_DIR}"
    move_directory_finished "${OUTDIR_REAL}" "${WORKDIR}" "OUTDIR_REAL"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR: move_directory_finished: error moving directory ${OUTDIR_REAL}"
  else
    log "Deleting ${OUTDIR_REAL}"
    rm "${OUTDIR_REAL}" -rf
  fi
  if  [ $BACKUP_RUN -eq 1 ]; then
    log "Moving ${OUTPUT_MNH} to ${PREPARE_DIR}"
    move_directory_finished "${OUTPUT_MNH}" "${WORKDIR}" "OUTPUT_MNH"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR: move_directory_finished: error moving directory ${OUTPUT_MNH}"
  else
    log "Deleting ${OUTPUT_MNH}"
    rm "${OUTPUT_MNH}" -rf
  fi
  if  [ $BACKUP_DIAG -eq 1 ]; then
    log "Moving ${DIAG_MNH} to ${PREPARE_DIR}"
    move_directory_finished "${DIAG_MNH}" "${WORKDIR}" "DIAG_MNH"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR: move_directory_finished: error moving directory ${DIAG_MNH}"
  else
    log "Deleting ${DIAG_MNH}"
    rm "${DIAG_MNH}" -rf
  fi
  if  [ $BACKUP_POSTPROC -eq 1 ]; then
    log "Moving ${ASCII_DIR} to ${PREPARE_DIR}"
    move_directory_finished "${ASCII_DIR}" "${WORKDIR}" "ASCII_DIR"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR: move_directory_finished: error moving directory ${ASCII_DIR}"
    log "Moving ${PLOT_DIR} to ${PREPARE_DIR}"
    move_directory_finished "${PLOT_DIR}" "${WORKDIR}" "PLOT_DIR"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR: move_directory_finished: error moving directory ${PLOT_DIR}"
  else
    log "Deleting ${ASCII_DIR}"
    rm "${ASCII_DIR}" -rf
    log "Deleting ${PLOT_DIR}"
    rm "${PLOT_DIR}" -rf
  fi
  if [ $BACKUP_LOG -eq 1 ]; then
    log "Moving ${LOGDIR} to ${PREPARE_DIR}"
    test -e "${HOME}/sim.out" && cp "${HOME}/sim.out" "${LOGDIR}/"
    test -e "${WORKDIR}/nohup.out" && cp "${WORKDIR}/nohup.out" "${LOGDIR}/"
    move_directory_finished "${LOGDIR}" "${WORKDIR}" "LOGDIR"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR: move_directory_finished: error moving directory ${LOGDIR}"
#######################
#    !! WARNING !!    #
#######################
#OVERWRITING LOGDIR AND RELATED VARIABLES UNTIL END OF THE SCRIPT
     LOGDIR=$(find_directory_finished ${LOGDIR} ${WORKDIR})
     DATE_LASTLOG="${LOGDIR}/$(basename ${DATE_LASTLOG})"
     LOGFILE="${LOGDIR}/$(basename ${LOGFILE})"
     ERRFILE="${LOGDIR}/$(basename ${ERRFILE})"
     echo "MOVED_FINISHED=T" >> "${DATE_LASTLOG}"
#######################
#    !! WARNING !!    #
#######################
  fi
#SAVE THE FOLLOWING STATE FOR backup.sh
#DONEGROUNDASCII comes from plot.sh
  if [ $DONEGROUNDASCII -eq 1 ]; then
    echo "1" > "${PREPARE_DIR}/done_ascii.temp"
  fi
#WINDAVGHIGH comes from plot.sh
  if [ $WINDAVGHIGH -eq 1 ]; then
    echo "1" > "${PREPARE_DIR}/wind_high.temp"
  fi
fi

DATE_ENDBK_UNIX=$(date +%s)

##################################################################################################
#As the last thing store the final time and print it
log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
log " -- END OF PROCEDURE -- "
log "******************************"
log "$(uptime)"
log "$(free)"
log "******************************"
DATE_LAST=$(date +%F/%T)
DATE_LAST_UNIX=$(date +%s)
REALTIME=$((DATE_ENDREAL_UNIX - DATE_STARTREAL_UNIX))
REALTIME=$(echo "scale=0;($REALTIME/60)"|bc -l)
EXETIME=$((DATE_ENDEXE_UNIX - DATE_STARTEXE_UNIX))
EXETIME=$(echo "scale=0;($EXETIME/60)"|bc -l)
DIAGTIME=$((DATE_ENDDIAG_UNIX - DATE_STARTDIAG_UNIX))
DIAGTIME=$(echo "scale=0;($DIAGTIME/60)"|bc -l)
PLOTTIME=$((DATE_ENDPLOT_UNIX - DATE_STARTPLOT_UNIX))
PLOTTIME=$(echo "scale=0;($PLOTTIME/60)"|bc -l)
BKTIME=$((DATE_ENDBK_UNIX - DATE_STARTBK_UNIX))
BKTIME=$(echo "scale=0;($BKTIME/60)"|bc -l)
echo "SIMULATION_FINISHED=T" >> "${DATE_LASTLOG}"
log "Process started on date                : $DATE_FIRST"
log "Process ended on date                  : $DATE_LAST"
log "Time spent on REAL (min)               : $REALTIME"
log "Time spent on EXE (min)                : $EXETIME"
log "Time spent on POSTPROC (min)           : $DIAGTIME"
log "Time spent on PLOT (min)               : $PLOTTIME"
log "Time spent on COMPRESS and MOVE (min)  : $BKTIME"
TOTALTIME=$((DATE_LAST_UNIX - DATE_FIRST_UNIX))
TOTALTIME=$(echo "scale=0;($TOTALTIME/60)"|bc -l)
log "Total time elapsed (min)               : $TOTALTIME"

echo "datefor=$YEARB$MONTHB$DAYB" "xseglen=$XSEGLEN" "base_init=$BASEINITNAME" "site=$SITE_NAME" "dom=$NESTING" "tstep=${TIMESTEP_ARRAY[@]}" "start=$DATE_FIRST" "stop=$DATE_LAST" "timetot=$TOTALTIME" "prepreal=$REALTIME" "exe=$EXETIME" "postproc=$DIAGTIME" "plot=$PLOTTIME" "move=$BKTIME" "Nproc=${NUM_PROC}" "windavgK4=$WINDAVG" >> "${LOG_TIME_CUMULATIVE}"

##################################################################################################
##################################################################################################
##################################################################################################
if [ $BACKUPLATER -eq 0 ]; then
  cd "${EXEDIR}"
  source ${EXEDIR}/backup.sh
fi
# FINISH EVERYTHING AND SEND A NOTE
TIMESTAMP=$(date +%F/%T)
[ $TESTRUN -eq 0 ] && send_mail_finished "${MAIL_PREFIX}: FINISHED FRCST=$YEARB$MONTHB$DAYB ${SITE_NAME} ${TIMESTAMP}" "${TIMESTAMP} - Simulation run from init $BASEINITNAME, forecast relative to night starting $YEARB$MONTHB$DAYB UT ($YEARFIG$MONTHFIG$DAYFIG MST). AVERAGE WIND SPEED ON K=4 IS: $WINDAVG. timetot=${TOTALTIME} prepreal=${REALTIME} exe=${EXETIME} postproc=${DIAGTIME} plot=${PLOTTIME} move=${BKTIME} Nproc=${NUM_PROC}"

#SET BACK THE PATH VARIABLE
PATH="$OLD_PATH"
############################
#Deactivate the local python version
deactivate
############################

#As a final step, store the necessary data for the autoregression scripts
test -e "${AUTOREGRESSION_BASE_DIR}/config/" || mkdir -p "${AUTOREGRESSION_BASE_DIR}/config/"
FILTERVARS="${AUTOREGRESSION_BASE_DIR}/config/${YEARB}${MONTHB}${DAYB}_AR_configs.conf"
#Store the following variables for the AUTOREGRESSION filter
echo "AUTOREGRESSION_STORE_DIR string ${AUTOREGRESSION_STORE_DIR}" > ${FILTERVARS}
echo "UTOFFSET int ${UTOFFSET}" >> ${FILTERVARS}
echo "YEARFIG string ${YEARFIG}" >> ${FILTERVARS}
echo "MONTHFIG string ${MONTHFIG}" >> ${FILTERVARS}
echo "DAYFIG string ${DAYFIG}" >> ${FILTERVARS}
echo "DAWNMINDELTA int ${DAWNMINDELTA}" >> ${FILTERVARS}
echo "DUSKMINDELTA int ${DUSKMINDELTA}" >> ${FILTERVARS}
echo "SUNSETMINDELTA int ${SUNSETMINDELTA}" >> ${FILTERVARS}
echo "SUNRISEMINDELTA int ${SUNRISEMINDELTA}" >> ${FILTERVARS}
echo "REMOTE_USER string ${REMOTE_USER}" >> ${FILTERVARS}
echo "REMOTE_HOST string ${REMOTE_HOST}" >> ${FILTERVARS}
echo "REMOTE_PATH_ARCHIVE string ${REMOTE_PATH_ARCHIVE}" >> ${FILTERVARS}

if [ ${ARUPLOAD} -eq 1 ]; then
  rsync -av ${HOME}/AUTOREGRESSION/ ${REMOTE_USER}@${REMOTE_AR}:${REMOTE_PATH_AUTOREG}
  rsync -av ${HOME}/AUTOREGRESSION/ ${REMOTE_USER}@${REMOTE_AR_BK}:${REMOTE_PATH_AUTOREG}
fi
