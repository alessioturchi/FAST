#!/bin/bash
#First of all store the initial starting date
DATE_FIRST=$(date +%F/%T)
#Parse global config file
GLOBALCFG="conf.d/globals.var"
source "$GLOBALCFG"
LOGFILE="${LOGPGDFILE}"
#Go to $WORKDIR
cd "$WORKDIR"
#Parse function definitions
source "${FUNCFILE}"
#rotate logs
GENERATELIST=0
rotate_log
#Start logging
log "**************************************************************************"
log " -- DATE START=$DATE_FIRST"
log " -- PROGRAM STARTING"
log " -- Start Logging"
#Check other config files are correct and parse them
source "$PGD_VAR"
#Clear files left there by previous simulations
#clear_old
#Log config parameters
log " ** PARAMS:"
log " **   PGD GENERATION with ${MESONH_VERSION_FULL} and MPI ($MPI_ROOT)"
log " **   PGD DIRECTORY = $PGDDIR"
log " **   Site = $PGD_PREFIX"
log " **   Coordinates = LAT:${XLATCEN_VALUE} LON:${XLONCEN_VALUE}"
log " **   NESTING = $NESTING"
log "******************************"
log " **   COMPLETE LIST OF INPUT PARAMETERS:"
log " **   GLOBALCFG=$GLOBALCFG"
log " **   PGD_VAR=$PGD_VAR"
log "******************************"
#Check initial directory structure is safe
check_directory "$WORKDIR"
check_directory "$CONFDIR"
check_directory "$LOGDIR"
check_directory "$PGDDIR"
check_directory "$PREP_PGDDIR"
check_directory "$TOPODIR"

#Cycle on all the levels (outer + nesting)
log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
log " -- STARTING PREP_PGD PHASE"
log " -- date_start_prep_pgd:   "$(date +%F/%T)
#Prepare pgd files with nesting
prep_list_pgd
log " -- date_end_prep_pgd:   "$(date +%F/%T)
log " -- PREP_PGD PHASE ENDED"
mv "${LOGFILE}" "${PGDDIR}"
mv "${LOGFILEEXEPGD}" "${PGDDIR}"
