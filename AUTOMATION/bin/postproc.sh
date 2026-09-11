#!/bin/bash
##################################################################################################
##################################################################################################
# DIAG phase
if [ $NODIAG -eq 0 ]; then
  #Fancy logging
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
  log " -- STARTING THE DIAG PHASE -- "
  log " -- date_start_diag: "$(date +%F/%T)
  log "******************************"
  log "$(uptime)"
  log "$(free)"
  log "******************************"
  check_directory "$DIAG_MNH"
  check_directory "$PREP_DIAG"
  #Cycle on all output files created by MESHO-NH run, except first *000.{des,lfi}
  for todia in $(find "${OUTPUT_MNH}/" -maxdepth 1 -name "*.lfi" | grep -v "000.des" |grep -v "000.lfi"|sort); do
    #Do it only if the nest level of the file is equal to a specified level (outer layer=1, first nesting=2, etc...)
    NESTLEVELDIAG=$(basename $todia|cut -d"." -f2)
    TMP=0
    while [ $TMP -lt $NUMLEVELDIAG ]; do
      if [ $NESTLEVELDIAG -eq "${DIAGLEVELARRAY[$TMP]}" ]; then
        #Integrate from HEIGHT_INF to HEIGHT_SUP. Prepare a file for each linear combination of the two parameters
        for infd in ${DIAGINFHEIGHTS[$TMP]}; do
          for supd in ${DIAGSUPHEIGHTS[$TMP]}; do
            if [ $infd -lt $supd ]; then
              FILENAME=$(basename "${todia%.lfi}")
              #Function for the DIAG phase. Produces *_dg.{des,lfi} from DIAG and dia.* from conv2dia.
              prep_list_diag "$FILENAME" "$NESTLEVELDIAG" "$infd" "$supd"
              EXIT=$?
              [ $EXIT -eq 0 ] || error "!!! ERROR RUNNING DIAG PHASE on $NAMEFILE, integrating from $infd to $supd - ABORTING"
            fi
          done
        done
      fi
      TMP=$((TMP+1))
    done
  done
  #Delete remaining useless files
  rm DIAG1.nam DIAG.nam dirconv OUTPUT_LISTING* pipe_name -f
  log " -- date_end_diag:   "$(date +%F/%T)
  log " -- DIAG PHASE ENDED -- "
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
else
  if [ $NOFICVAL -eq 0 ]; then
    check_directory "$DIAG_MNH"
    NFILES=$(find "${DIAG_MNH}" -maxdepth 1 -name "*.lfi.bz2"|wc -l)
    if [ $NFILES -gt 0 ]; then
      log " *** Decompressing files for FICVAL phase *** "
      FILETODECOMPRESS=$(find "${DIAG_MNH}" -maxdepth 1 -name "*.lfi.bz2")
      parallel --gnu -j $NUM_PROC bunzip2 ::: "$FILETODECOMPRESS"
      EXIT=$?
      [ $EXIT -eq 0 ] || error "!!! ERROR decompressing files in ${DIAG_MNH}"
    fi
  fi
fi
##################################################################################################
##################################################################################################

##################################################################################################
##################################################################################################
# EXTRACT_FICVAL phase
# Run only if $NOFICVAL=0 (else is debug, don not do it if you do not know what you are doing)
if [ $NOFICVAL -eq 0 ]; then
#Fancy logging
  log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
  log " -- STARTING THE EXTRACT_FICVAL PHASE -- "
  log " -- date_start_ficval: "$(date +%F/%T)
  log "******************************"
  log "$(uptime)"
  log "$(free)"
  log "******************************"
  check_directory "$FICVAL_DIR"
#Check something
  test -d "${DIAG_MNH}" || error "!!! ERROR RUNNING EXTRACT FICVAL PHASE, DIAG_MNH directory not present - ABORTING"
  NFILES=$(find "${DIAG_MNH}" -name "*.lfi"|wc -l)
  NFILES2=$(find "${DIAG_MNH}" -name "*.lfi.bz2"|wc -l)
  NFILES=$((NFILES+NFILES2))
#Check something more
  if [ $NFILES -eq 0 ]; then
    error "!!! ERROR RUNNING EXTRACT FICVAL PHASE, no lfi files in DIAG_MNH directory - ABORTING"
  fi
#Go into the DIAG directory
  cd "${DIAG_MNH}"
#rm old ficval files
  rm "$FICVAL_DIR/"*.fic -f
#Compute necessary orography files from the first output only
  DONE1=""
  DONE2=""
  DONEEXTRACT=""
  DONEPV=""
#Cycle on all lfi files in $DIAG_MNH - Since I removed regular lfi files all remaining ones should be diacronic
  for i in $(find "${DIAG_MNH}/" -name "*.lfi"|sort); do
    NAMEFILE=$(basename "${i%.lfi}")
    ITERNUM=$(echo "${i}"|cut -d"." -f2-|cut -d"_" -f2)
    LEVELNUM=$(echo "${NAMEFILE}" |cut -d"." -f2|cut -d"_" -f1)
    DONESTRING=$(echo "${i}"|cut -d"." -f2-|cut -d"_" -f-2)
    if [ $ITERNUM -eq 1 ]; then
##########################
# LATLON
##########################
#Do this only one one file per domanin (level), since it's the same
      if [ $(echo "${DONE1}"|grep "${LEVELNUM}"|wc -l) -eq 0 ]; then
        ${EXE_DIAPROG}  &>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
CONVALLIJ2LL
quit
EOF
        EXIT=$?
        [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING CONVALLIJ2LL FICVAL on $NAMEFILE - ABORTING"
        if [ -e FICVAL ]; then
          #Filter away * and , in order to read it from fortran program
          sed -e 's/*/ /g' -i FICVAL
          sed -e 's/\,/ /g' -i FICVAL
          NAMEFILESHORT=$(echo "${NAMEFILE}"|cut -d"_" -f-1)
          mv FICVAL ${FICVAL_DIR}/LATLON_${NAMEFILESHORT}.fic
          log " - LATLON_${NAMEFILESHORT}.fic prepared"
        else
          error "!!! ERROR EXTRACTING CONVALLIJ2LL FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
        fi
        DONE1="$DONE1 ${LEVELNUM}"
      fi
##########################
# OROGRAPHY ZS
##########################
#Do this only one one file per domanin (level), since it's the same
      if [ $(echo "${DONE2}"|grep "${LEVELNUM}"|wc -l) -eq 0 ]; then
        ${EXE_DIAPROG} &>>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
ZS
quit
EOF
        EXIT=$?
        [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING ZS FICVAL on $NAMEFILE - ABORTING"
        if [ -e FICVAL ]; then
          NAMEFILESHORT=$(echo "${NAMEFILE}"|cut -d"_" -f-1)
          mv FICVAL ${FICVAL_DIR}/ZS_${NAMEFILESHORT}.fic
          log " - ZS_${NAMEFILESHORT}.fic prepared"
        else
          error "!!! ERROR EXTRACTING ZS FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
        fi
        DONE2="$DONE2 ${LEVELNUM}"
      fi
##########################
# ALTITUDES CV
##########################
#Do this only on one file per domanin (level), since it's the same
      if [ $(echo "${DONE3}"|grep "${LEVELNUM}"|wc -l) -eq 0 ]; then
        TMPLISTCV1=($CVLIST_DOM_FIRST)
        TMPLISTCV2=($CVLIST_DOM_SECOND)
        if [ ${LEVELNUM} -eq ${DOM_FIRST} ]; then
          NLEVEL=0
        elif [ ${LEVELNUM} -eq ${DOM_SECOND} ];then
          NLEVEL=1
        else
          error "!!! In FICVAL ALT: Selected level does not correspond to any PVLIST in run.var - ABORTING"
        fi

        if [ ${#TMPLISTCV1[@]} -gt 0 ] || [ ${#TMPLISTCV2[@]} -gt 0 ]; then
          ${EXE_DIAPROG} &>>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
LDEFCV2IND=T
NIDEBCV=${STARTCV_I[$NLEVEL]}
NJDEBCV=${STARTCV_J[$NLEVEL]}
NIFINCV=${ENDCV_I[$NLEVEL]}
NJFINCV=${ENDCV_J[$NLEVEL]}
ALT_cv_
quit
EOF
          EXIT=$?
          [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING ALT CV FICVAL on $NAMEFILE - ABORTING"
          if [ -e FICVAL ]; then
            mv FICVAL ${FICVAL_DIR}/ALT_cv_${NAMEFILESHORT}.fic
            log " - ALT_cv_${NAMEFILESHORT}.fic prepared"
          else
            error "!!! ERROR EXTRACTING ALT CV FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
          fi
          DONE3="$DONE3 ${LEVELNUM}"
        fi
      fi
    fi
#Compute physical parameters for each output file
    if [ $ITERNUM -ge 1 ]; then
##########################
# PARAMETER EXTRACTIONS
##########################
#ON DOMP1 RUN ALWAYS THE EXSTRACTLIST_MULTIHEIGHT
      if [ ${LEVELNUM} -eq ${DOM_FIRST} ]; then
        #Create bash arrays from extract lists
        EXTRACTLIST=${EXTRACTLIST_MULTIHEIGHT}
        EXTLISTARRAY=($EXTRACTLIST)
        for extr in ${EXTLISTARRAY[@]}; do
          ${EXE_DIAPROG} &>>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
${extr}
quit
EOF
          EXIT=$?
          [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING ${extr} FICVAL on $NAMEFILE - ABORTING"
          if [ -e FICVAL ]; then
            mv FICVAL ${FICVAL_DIR}/${extr}_${NAMEFILE}.fic
            log " - ${extr}_${NAMEFILE}.fic prepared"
          else
            error "!!! ERROR EXTRACTING ${extr} FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
          fi
        done
#Prepare for next extraction of regular parameters on a single height file
        EXTRACTLIST=${EXTRACTLIST_DOM_FIRST}
        EXTLISTARRAY=($EXTRACTLIST)
      elif [ ${LEVELNUM} -eq ${DOM_SECOND} ];then
#ON DOMP2 NO MULTIHEIGHT EXTRACTION
#Prepare for next extraction of regular parameters on a single height file
        EXTRACTLIST=${EXTRACTLIST_DOM_SECOND}
        EXTLISTARRAY=($EXTRACTLIST)
      else
        error "!!! In FICVAL: Selected level does not correspond to any EXTRACTLIST in run.var - ABORTING"
      fi
#Do this only one one file per exit number (ITERNUM), since it's the same
      if [ $(echo "${DONEEXTRACT}"|grep "${DONESTRING}"|wc -l) -eq 0 ]; then
        for extr in ${EXTLISTARRAY[@]}; do
          ${EXE_DIAPROG} &>>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
${extr}
quit
EOF
          EXIT=$?
          [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING ${extr} FICVAL on $NAMEFILE - ABORTING"
          if [ -e FICVAL ]; then
            mv FICVAL ${FICVAL_DIR}/${extr}_${NAMEFILE}.fic
            log " - ${extr}_${NAMEFILE}.fic prepared"
          else
            error "!!! ERROR EXTRACTING ${extr} FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
          fi
        done
        DONEEXTRACT="$DONEEXTRACT ${DONESTRING}"
      fi
##########################
# VERTICAL PROFILES
##########################
      if [ ${LEVELNUM} -eq ${DOM_FIRST} ]; then
        #Create bash arrays from extract lists
        PVLISTARRAY=($PVLIST_DOM_FIRST)
        NLEVEL=0
      elif [ ${LEVELNUM} -eq ${DOM_SECOND} ];then
        PVLISTARRAY=($PVLIST_DOM_SECOND)
        NLEVEL=1
      else
        error "!!! In FICVAL: Selected level does not correspond to any PVLIST in run.var - ABORTING"
      fi
      if [ $(echo "${DONEPV}"|grep "${DONESTRING}"|wc -l) -eq 0 ]; then
        for extr in ${PVLISTARRAY[@]}; do
          ${EXE_DIAPROG} &>>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
PROFILE=1
NIDEBCOU=${STARTPV_I[$NLEVEL]}
NJDEBCOU=${STARTPV_J[$NLEVEL]}
NLMAX=2
NLANGLE=0
${extr}_pv_
quit
EOF
          EXIT=$?
          [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING ${extr} PV FICVAL on $NAMEFILE - ABORTING"
          if [ -e FICVAL ]; then
            mv FICVAL ${FICVAL_DIR}/${extr}_pv_${NAMEFILE}.fic
            log " - ${extr}_pv_${NAMEFILE}.fic prepared"
          else
            error "!!! ERROR EXTRACTING ${extr} PV FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
          fi
        done
        DONEPV="$DONEPV ${DONESTRING}"
      fi
##########################
# VERTICAL CUTS
##########################
      if [ ${LEVELNUM} -eq ${DOM_FIRST} ]; then
        #Create bash arrays from extract lists
        CVLISTARRAY=($CVLIST_DOM_FIRST)
        NLEVEL=0
      elif [ ${LEVELNUM} -eq ${DOM_SECOND} ];then
        CVLISTARRAY=($CVLIST_DOM_SECOND)
        NLEVEL=1
      else
        error "!!! In FICVAL: Selected level does not correspond to any CVLIST in run.var - ABORTING"
      fi
      if [ $(echo "${DONECV}"|grep "${DONESTRING}"|wc -l) -eq 0 ]; then
        for extr in ${CVLISTARRAY[@]}; do
          ${EXE_DIAPROG} &>>${LOGFILEEXEFICVAL} <<EOF
_file_'${NAMEFILE}'
LPRINT=T
LDEFCV2IND=T
NIDEBCV=${STARTCV_I[$NLEVEL]}
NJDEBCV=${STARTCV_J[$NLEVEL]}
NIFINCV=${ENDCV_I[$NLEVEL]}
NJFINCV=${ENDCV_J[$NLEVEL]}
${extr}_cv_
quit
EOF
          EXIT=$?
          [ $EXIT -eq 0 ] || error "!!! ERROR EXTRACTING ${extr} CV FICVAL on $NAMEFILE - ABORTING"
          if [ -e FICVAL ]; then
            mv FICVAL ${FICVAL_DIR}/${extr}_cv_${NAMEFILE}.fic
            log " - ${extr}_cv_${NAMEFILE}.fic prepared"
          else
            error "!!! ERROR EXTRACTING ${extr} CV FICVAL on $NAMEFILE - NO FICVAL PRESENT AFTER EXTRACTION - ABORTING"
          fi
        done
        DONECV="$DONECV ${DONESTRING}"
      fi
    fi
  done
#remove cruft files
  rm gmeta OUT_DIA dir.* FICJD -f
fi
##################################################################################################
##################################################################################################

