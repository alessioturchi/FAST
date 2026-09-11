#!/bin/bash
##################################################################################################
##################################################################################################
# PLOT phase
#Fancy logging
log "!!**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**%%**!!"
log " -- STARTING THE PLOT PHASE -- "
log " -- date_start_plot: "$(date +%F/%T)
log "******************************"
log "$(uptime)"
log "$(free)"
log "******************************"
check_directory "$PLOT_DIR"
#move into the plot directory
cd ${PLOT_DIR}
#remove old files
rm *.stat *.dat *.pro *.ps *.png *.gif -f
############################################
#COMPUTE RESCALED CN2 WITH WIND GRADIENT ALGORITHM
ONDOMAIN=${DOMP1}
log "  prepare cn2_new_algo_p${ONDOMAIN}.dat"
test -f "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" && rm "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" -f
${UTILDIR}/rescale_cn2_wind "${DAT_DIR}/cn2_p${ONDOMAIN}.dat" "${DAT_DIR}/vx_vy_prof_p${ONDOMAIN}.dat" "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" $CN2_WRESCALE_H $CN2_ALPHA $CN2_BETA
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_new_algo_p${ONDOMAIN}.dat"
############################################
#COMPUTE CN2 WITH OS18 METHOD
ONDOMAIN=${DOMP1}
log "  prepare cn2_OS18_p${ONDOMAIN}.dat"
test -f "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" && rm "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" -f
${UTILDIR}/compute_cn2_OS18 "${DAT_DIR}/temp_pres_p${ONDOMAIN}.dat" "${DAT_DIR}/theta_prof_p${ONDOMAIN}.dat" "${DAT_DIR}/vx_vy_prof_p${ONDOMAIN}.dat" "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_OS18_p${ONDOMAIN}.dat"
############################################
#FIRST COMPUTE REGULAR PLOTS: HERE ONDOMAIN MEANS *_p${ONDOMAIN}.dat
############################################
# WIND MODULE AND WIND DIRECTION TEMPORAL EVOLUTION LEVEL K=2,4
ONDOMAIN=${DOMP1}
#Variable for trends
ONDOMAIN_WINDTRENDS=${ONDOMAIN}
ONDOMAIN_WDTRENDS=${ONDOMAIN_WINDTRENDS}
log "  prepare wind_p${ONDOMAIN}_evollevel_k*.stat in $PLOTSTARTT to $PLOTENDT UT"
${UTILDIR}/treat_wind_evollevel "${DAT_DIR}/wind_and_temp_pres_vx_vy_p${ONDOMAIN}_k2.dat" "wind_p${ONDOMAIN}_evollevel_k2.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_evollevel_k2.stat"
${UTILDIR}/treat_wind_evollevel "${DAT_DIR}/wind_and_temp_pres_vx_vy_p${ONDOMAIN}_k3.dat" "wind_p${ONDOMAIN}_evollevel_k3.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_evollevel_k3.stat"
${UTILDIR}/treat_wind_evollevel "${DAT_DIR}/wind_and_temp_pres_vx_vy_p${ONDOMAIN}_k4.dat" "wind_p${ONDOMAIN}_evollevel_k4.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_evollevel_k4.stat"
#######
#COMPUTING WIND SPEED AVERAGE AT GROUND
log "COMPUTING WIND SPEED AVERAGE AT GROUND"
WINDAVG=$(cat "wind_p${ONDOMAIN_WINDTRENDS}_evollevel_k4.stat" |tail -n+2 |head -n 1|tr -s [:blank:]|cut -d" " -f5)
#WINDAVG=$(avgwindground "wind_p${ONDOMAIN_WINDTRENDS}_evollevel_k4.stat")
#EXIT=$?
#[ $EXIT -eq 0 ] || error "!!! ERROR evaluating wind speed at ground"
WINDAVGHIGH=0
WINDAVGHIGH=$(echo $WINDAVG'>'$WINDSPEEDHIGHLIM | bc -l)
#WINDAVG=$(echo $WINDAVG|tr -s [:blank:])
log "WINDAVG=$WINDAVG"
log "WINDSPEEDHIGHLIM=$WINDSPEEDHIGHLIM"
log "WINDAVGHIGH=$WINDAVGHIGH"
#######
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_level_time.py "wind_p${ONDOMAIN}_evollevel_k2.stat" "wind_p${ONDOMAIN}_evollevel_k3.stat" "wind_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_level_time.py "wind_p${ONDOMAIN}_evollevel_k2.stat" "wind_p${ONDOMAIN}_evollevel_k3.stat" "wind_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_level_time.py"
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wd_level_time.py "wind_p${ONDOMAIN}_evollevel_k2.stat" "wind_p${ONDOMAIN}_evollevel_k3.stat" "wind_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wd_level_time.py "wind_p${ONDOMAIN}_evollevel_k2.stat" "wind_p${ONDOMAIN}_evollevel_k3.stat" "wind_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wd_level_time.py"
############################################
# WIND MODULE TEMPORAL EVOLUTION OF VERTICAL PROFILE
ONDOMAIN=${DOMP1}
#Plot full height
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_pv_time.py "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_pv_time.py "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_pv_time.py"
#Ploot zoom
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_pv_time.py "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${CN2H2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_pv_time.py "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${CN2H2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_pv_time.py"
############################################
# WIND MODULE AVERAGED VERTICAL PROFILES
ONDOMAIN=${DOMP1}
log "  prepare wind_p${ONDOMAIN}_stats_pv.1.stat averaged in $PLOTDUSK to $PLOTFIRSTT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_wind_pv_avg "${DAT_DIR}/vx_vy_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_pv.1.stat" $PLOTDUSK $PLOTFIRSTT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_pv.1.stat"
log "  prepare wind_p${ONDOMAIN}_stats_pv.2.stat averaged in $PLOTFIRSTT to $PLOTSECONDT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_wind_pv_avg "${DAT_DIR}/vx_vy_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_pv.2.stat" $PLOTFIRSTT $PLOTSECONDT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_pv.2.stat"
log "  prepare wind_p${ONDOMAIN}_stats_pv.3.stat averaged in $PLOTSECONDT to $PLOTDAWN UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_wind_pv_avg "${DAT_DIR}/vx_vy_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_pv.3.stat" $PLOTSECONDT $PLOTDAWN $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_pv.3.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_pv_average.py "wind_p${ONDOMAIN}_stats_pv.1.stat" "wind_p${ONDOMAIN}_stats_pv.2.stat" "wind_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_pv_average.py "wind_p${ONDOMAIN}_stats_pv.1.stat" "wind_p${ONDOMAIN}_stats_pv.2.stat" "wind_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_pv_average.py"
############################################
# WIND MODULE TEMPORAL EVOLUTION FOR LINC-NIRVANA, FLAO AND ARGOS
ONDOMAIN=${DOMP1}
log "  prepare wind_p${ONDOMAIN}_stats_linc_low.stat averaged in $PLOTDUSK to $PLOTDAWN UT from 30 to 415 meters"
${UTILDIR}/treat_wind_integrate_veq "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_linc_low.stat" $PLOTSTARTT $PLOTENDT 30 415 "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_linc_low.stat"
log "  prepare wind_p${ONDOMAIN}_stats_linc_high.stat averaged in $PLOTDUSK to $PLOTDAWN UT from 5072 to 9127 meters"
${UTILDIR}/treat_wind_integrate_veq "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_linc_high.stat" $PLOTSTARTT $PLOTENDT 5072 9127 "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_linc_high.stat"
log "  prepare wind_p${ONDOMAIN}_stats_flao.stat averaged in $PLOTDUSK to $PLOTDAWN UT from 30 to 20000 meters"
${UTILDIR}/treat_wind_integrate_veq "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_flao.stat" $PLOTSTARTT $PLOTENDT 30 20000 "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_flao.stat"
log "  prepare wind_p${ONDOMAIN}_stats_argos.stat averaged in $PLOTDUSK to $PLOTDAWN UT from 30 to 560 meters"
${UTILDIR}/treat_wind_integrate_veq "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "wind_p${ONDOMAIN}_stats_argos.stat" $PLOTSTARTT $PLOTENDT 30 560 "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_p${ONDOMAIN}_stats_argos.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_flao_argos_linc.py "wind_p${ONDOMAIN}_stats_linc_low.stat" "wind_p${ONDOMAIN}_stats_linc_high.stat" "wind_p${ONDOMAIN}_stats_flao.stat" "wind_p${ONDOMAIN}_stats_argos.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_flao_argos_linc.py "wind_p${ONDOMAIN}_stats_linc_low.stat" "wind_p${ONDOMAIN}_stats_linc_high.stat" "wind_p${ONDOMAIN}_stats_flao.stat" "wind_p${ONDOMAIN}_stats_argos.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plot_wind_flao_argos_linc.py"
############################################
# ABS TEMPERATURE TEMPORAL EVOLUTION LEVEL K=2,4
ONDOMAIN=${DOMP1}
#Variable for trends
ONDOMAIN_TEMPTRENDS=${ONDOMAIN}
log "  prepare temp_p${ONDOMAIN}_evollevel_k2.stat in $PLOTSTARTT to $PLOTENDT UT"
${UTILDIR}/treat_temp_evollevel "${DAT_DIR}/wind_and_temp_pres_vx_vy_p${ONDOMAIN}_k2.dat" "temp_p${ONDOMAIN}_evollevel_k2.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing temp_p${ONDOMAIN}_evollevel_k2.stat"
${UTILDIR}/treat_temp_evollevel "${DAT_DIR}/wind_and_temp_pres_vx_vy_p${ONDOMAIN}_k3.dat" "temp_p${ONDOMAIN}_evollevel_k3.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing temp_p${ONDOMAIN}_evollevel_k3.stat"
${UTILDIR}/treat_temp_evollevel "${DAT_DIR}/wind_and_temp_pres_vx_vy_p${ONDOMAIN}_k4.dat" "temp_p${ONDOMAIN}_evollevel_k4.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing temp_p${ONDOMAIN}_evollevel_k4.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_temp_level_time.py "temp_p${ONDOMAIN}_evollevel_k2.stat" "temp_p${ONDOMAIN}_evollevel_k3.stat" "temp_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_temp_level_time.py "temp_p${ONDOMAIN}_evollevel_k2.stat" "temp_p${ONDOMAIN}_evollevel_k3.stat" "temp_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_temp_level_time.py"
############################################
# POTENTIAL TEMPERATURE VERTICAL AVERAGED PROFILES
ONDOMAIN=${DOMP1}
log "  prepare theta_prof_p${ONDOMAIN}_stats_pv.1.stat averaged in $PLOTDUSK to $PLOTFIRSTT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_theta_pv_avg "${DAT_DIR}/theta_prof_p${ONDOMAIN}.dat" "theta_prof_p${ONDOMAIN}_stats_pv.1.stat" $PLOTDUSK $PLOTFIRSTT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing theta_prof_p${ONDOMAIN}_stats_pv.1.stat"
log "  prepare theta_stats_pv.2.stat averaged in $PLOTFIRSTT to $PLOTSECONDT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_theta_pv_avg "${DAT_DIR}/theta_prof_p${ONDOMAIN}.dat" "theta_prof_p${ONDOMAIN}_stats_pv.2.stat" $PLOTFIRSTT $PLOTSECONDT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing theta_stats_pv.2.stat"
log "  prepare theta_stats_pv.3.stat averaged in $PLOTSECONDT to $PLOTDAWN UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_theta_pv_avg "${DAT_DIR}/theta_prof_p${ONDOMAIN}.dat" "theta_prof_p${ONDOMAIN}_stats_pv.3.stat" $PLOTSECONDT $PLOTDAWN $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing theta_prof_p${ONDOMAIN}_stats_pv.3.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_theta_pv_average.py "theta_prof_p${ONDOMAIN}_stats_pv.1.stat" "theta_prof_p${ONDOMAIN}_stats_pv.2.stat" "theta_prof_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_theta_pv_average.py "theta_prof_p${ONDOMAIN}_stats_pv.1.stat" "theta_prof_p${ONDOMAIN}_stats_pv.2.stat" "theta_prof_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_theta_pv_average.py"
############################################
# RELATIVE HUMIDITY TEMPORAL EVOLUTION LEVEL K=2,4
ONDOMAIN=${DOMP1}
#Variable for trends
ONDOMAIN_RHTRENDS=${ONDOMAIN}
log "  prepare rh_p${ONDOMAIN}_evollevel_k2.stat in $PLOTSTARTT to $PLOTENDT UT"
${UTILDIR}/treat_rh_evollevel "${DAT_DIR}/rh_p${ONDOMAIN}_k2.dat" "rh_p${ONDOMAIN}_evollevel_k2.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing rh_p${ONDOMAIN}_evollevel_k2.stat"
${UTILDIR}/treat_rh_evollevel "${DAT_DIR}/rh_p${ONDOMAIN}_k3.dat" "rh_p${ONDOMAIN}_evollevel_k3.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing rh_p${ONDOMAIN}_evollevel_k3.stat"
${UTILDIR}/treat_rh_evollevel "${DAT_DIR}/rh_p${ONDOMAIN}_k4.dat" "rh_p${ONDOMAIN}_evollevel_k4.stat" $PLOTSTARTT $PLOTENDT
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing rh_p${ONDOMAIN}_evollevel_k4.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_rh_level_time.py "rh_p${ONDOMAIN}_evollevel_k2.stat" "rh_p${ONDOMAIN}_evollevel_k3.stat" "rh_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_rh_level_time.py "rh_p${ONDOMAIN}_evollevel_k2.stat" "rh_p${ONDOMAIN}_evollevel_k3.stat" "rh_p${ONDOMAIN}_evollevel_k4.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_rh_level_time.py"
############################################
# RELATIVE HUMIDITY TERMPORAL EVOLUTION OF VERTICAL PROFILE
ONDOMAIN=${DOMP1}
#Plot full height
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_rh_pv_time.py "${DAT_DIR}/rh_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_rh_pv_time.py "${DAT_DIR}/rh_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_rh_pv_time.py"
############################################
# RELATIVE HUMIDITY AVERAGED VERTICAL PROFILES
ONDOMAIN=${DOMP1}
log "  prepare rh_p${ONDOMAIN}_stats_pv.1.stat averaged in $PLOTDUSK to $PLOTFIRSTT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_rh_pv_avg "${DAT_DIR}/rh_prof_p${ONDOMAIN}.dat" "rh_p${ONDOMAIN}_stats_pv.1.stat" $PLOTDUSK $PLOTFIRSTT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing rh_p${ONDOMAIN}_stats_pv.1.stat"
log "  prepare rh_p${ONDOMAIN}_stats_pv.2.stat averaged in $PLOTFIRSTT to $PLOTSECONDT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_rh_pv_avg "${DAT_DIR}/rh_prof_p${ONDOMAIN}.dat" "rh_p${ONDOMAIN}_stats_pv.2.stat" $PLOTFIRSTT $PLOTSECONDT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing rh_p${ONDOMAIN}_stats_pv.2.stat"
log "  prepare rh_p${ONDOMAIN}_stats_pv.3.stat averaged in $PLOTSECONDT to $PLOTDAWN UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_rh_pv_avg "${DAT_DIR}/rh_prof_p${ONDOMAIN}.dat" "rh_p${ONDOMAIN}_stats_pv.3.stat" $PLOTSECONDT $PLOTDAWN $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing rh_p${ONDOMAIN}_stats_pv.3.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_rh_pv_average.py "rh_p${ONDOMAIN}_stats_pv.1.stat" "rh_p${ONDOMAIN}_stats_pv.2.stat" "rh_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_rh_pv_average.py "rh_p${ONDOMAIN}_stats_pv.1.stat" "rh_p${ONDOMAIN}_stats_pv.2.stat" "rh_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_rh_pv_average.py"
############################################
# WATER COLUMN TERMPORAL EVOLUTION OF VERTICAL PROFILE
ONDOMAIN=${DOMP1}
#Plot full height
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_pv_time.py "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_pv_time.py "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wapor_pv_time.py"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_pv_time.py "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${MRH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
#Plot zoom
${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_pv_time.py "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${MRH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wapor_pv_time.py"
############################################
# WATER COLUMN AVERAGED VERTICAL PROFILES
ONDOMAIN=${DOMP1}
log "  prepare wapor_p${ONDOMAIN}_stats_pv.1.stat averaged in $PLOTDUSK to $PLOTFIRSTT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_wapor_pv_avg "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" "wapor_p${ONDOMAIN}_stats_pv.1.stat" $PLOTDUSK $PLOTFIRSTT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wapor_p${ONDOMAIN}_stats_pv.1.stat"
log "  prepare wapor_p${ONDOMAIN}_stats_pv.2.stat averaged in $PLOTFIRSTT to $PLOTSECONDT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_wapor_pv_avg "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" "wapor_p${ONDOMAIN}_stats_pv.2.stat" $PLOTFIRSTT $PLOTSECONDT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wapor_p${ONDOMAIN}_stats_pv.2.stat"
log "  prepare wapor_p${ONDOMAIN}_stats_pv.3.stat averaged in $PLOTSECONDT to $PLOTDAWN UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_wapor_pv_avg "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" "wapor_p${ONDOMAIN}_stats_pv.3.stat" $PLOTSECONDT $PLOTDAWN $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wapor_p${ONDOMAIN}_stats_pv.3.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_pv_average.py "wapor_p${ONDOMAIN}_stats_pv.1.stat" "wapor_p${ONDOMAIN}_stats_pv.2.stat" "wapor_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_pv_average.py "wapor_p${ONDOMAIN}_stats_pv.1.stat" "wapor_p${ONDOMAIN}_stats_pv.2.stat" "wapor_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wapor_pv_average.py"
############################################
# WATER COLUMN TIME EVOLUTION OF INTEGRATED MEASURE
ONDOMAIN=${DOMP1}
#Variable for trends
ONDOMAIN_WAPORTRENDS=${ONDOMAIN}
log "  prepare wapor_p${ONDOMAIN}_evol.1.stat in 02-12 UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
echo "PWV CORRECTION" "${CORRECTION_DIR}/pwv_integ.var"
${UTILDIR}/treat_wapor_evol "${DAT_DIR}/mr_prof_p${ONDOMAIN}.dat" "${DAT_DIR}/temp_pres_p${ONDOMAIN}.dat" "wapor_p${ONDOMAIN}_evol.1.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH2 "${CORRECTION_DIR}/pwv_integ.var"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wapor_p${ONDOMAIN}_evol.1.stat"
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_time.py "wapor_p${ONDOMAIN}_evol.1.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wapor_time.py "wapor_p${ONDOMAIN}_evol.1.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wapor_time.py"
############################################
# CN2 TEMPORAL EVOLUTION OF VERTICAL PROFILE
#Va editato il file per cabiare roba perché parte dal .dat
ONDOMAIN=${DOMP1}
#Plot full height
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -19.0 -15.0 ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -19.0 -15.0 ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_cn2_pv_time.py"
#Plot zoom
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${CN2H2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -18.0 -13.0 ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${CN2H2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -18.0 -13.0 ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_c2_pv_time.py"
############################################
# CN2 TEMPORAL EVOLUTION OF VERTICAL PROFILE WITH OS18 METHOD
#Va editato il file per cabiare roba perché parte dal .dat
ONDOMAIN=${DOMP1}
#Plot full height
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -19.0 -15.0 ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${PLOTTOPH2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -19.0 -15.0 ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_cn2_pv_time.py"
#Plot zoom
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${CN2H2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -18.0 -13.0 ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_time.py "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${PLOTSTARTT} ${PLOTENDT} ${PLOTBASEH1} ${CN2H2} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} -18.0 -13.0 ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_c2_pv_time.py"
############################################
# CN2 VERTICAL AVERAGED PROFILE
ONDOMAIN=${DOMP1}
log "  prepare cn2_p${ONDOMAIN}_stats_pv.1.stat averaged in $PLOTDUSK to $PLOTFIRSTT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_cn2_pv_avg "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "cn2_p${ONDOMAIN}_stats_pv.1.stat" $PLOTDUSK $PLOTFIRSTT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_p${ONDOMAIN}_stats_pv.1.stat"
log "  prepare cn2_p${ONDOMAIN}_stats_pv.2.stat averaged in $PLOTFIRSTT to $PLOTSECONDT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_cn2_pv_avg "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "cn2_p${ONDOMAIN}_stats_pv.2.stat" $PLOTFIRSTT $PLOTSECONDT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_p${ONDOMAIN}_stats_pv.2.stat"
log "  prepare cn2_p${ONDOMAIN}_stats_pv.3.stat averaged in $PLOTSECONDT $PLOTDAWN UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_cn2_pv_avg "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "cn2_p${ONDOMAIN}_stats_pv.3.stat" $PLOTSECONDT $PLOTDAWN $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_p${ONDOMAIN}_stats_pv.3.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_average.py "cn2_p${ONDOMAIN}_stats_pv.1.stat" "cn2_p${ONDOMAIN}_stats_pv.2.stat" "cn2_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_average.py "cn2_p${ONDOMAIN}_stats_pv.1.stat" "cn2_p${ONDOMAIN}_stats_pv.2.stat" "cn2_p${ONDOMAIN}_stats_pv.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_cn2_pv_average.py"
############################################
# CN2 VERTICAL AVERAGED PROFILE WITH OS18 METHOD
ONDOMAIN=${DOMP1}
log "  prepare cn2_p${ONDOMAIN}_stats_pv.1.stat averaged in $PLOTDUSK to $PLOTFIRSTT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_cn2_pv_avg "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "cn2_p${ONDOMAIN}_stats_pv.1.OS18.stat" $PLOTDUSK $PLOTFIRSTT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_p${ONDOMAIN}_stats_pv.1.OS18.stat"
log "  prepare cn2_p${ONDOMAIN}_stats_pv.2.stat averaged in $PLOTFIRSTT to $PLOTSECONDT UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_cn2_pv_avg "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "cn2_p${ONDOMAIN}_stats_pv.2.OS18.stat" $PLOTFIRSTT $PLOTSECONDT $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_p${ONDOMAIN}_stats_pv.2.OS18.stat"
log "  prepare cn2_p${ONDOMAIN}_stats_pv.3.stat averaged in $PLOTSECONDT $PLOTDAWN UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
${UTILDIR}/treat_cn2_pv_avg "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "cn2_p${ONDOMAIN}_stats_pv.3.OS18.stat" $PLOTSECONDT $PLOTDAWN $PLOTBASEH1 $PLOTTOPH2
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing cn2_p${ONDOMAIN}_stats_pv.3.OS18.stat"

echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_average.py "cn2_p${ONDOMAIN}_stats_pv.1.OS18.stat" "cn2_p${ONDOMAIN}_stats_pv.2.OS18.stat" "cn2_p${ONDOMAIN}_stats_pv.3.OS18.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_cn2_pv_average.py "cn2_p${ONDOMAIN}_stats_pv.1.OS18.stat" "cn2_p${ONDOMAIN}_stats_pv.2.OS18.stat" "cn2_p${ONDOMAIN}_stats_pv.3.OS18.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_cn2_pv_average.py"
############################################
# SEEING THETA0 and TAU0 TEMPORAL EVOLUTION OF VERTICAL PROFILE
ONDOMAIN=${DOMP1}
#Variable for trends
ONDOMAIN_SEETRENDS=${ONDOMAIN}
log "  prepare seeisotau_p${ONDOMAIN}_evol.1.stat in 02-12 UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
if [ $SUMMER -eq 1 ]; then
  echo "SEEING SUMMER CALIB CORRECTION" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2.var"
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "seeisotau_p${ONDOMAIN}_evol.1.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2.var" "${CORRECTION_DIR}/iso_integ.var" "${CORRECTION_DIR}/tau_integ_SUMMER_CALIB2.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_p${ONDOMAIN}_evol.1.stat"
else
  echo "SEEING WINTER CALIB CORRECTION" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2.var"
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "seeisotau_p${ONDOMAIN}_evol.1.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2.var" "${CORRECTION_DIR}/iso_integ.var" "${CORRECTION_DIR}/tau_integ_WINTER_CALIB2.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_p${ONDOMAIN}_evol.1.stat"
fi
log "  prepare seeisotau_p${ONDOMAIN}_evol.2.stat in 02-12 UT from $PLOTBASEH2 to $PLOTTOPH2 meters"
if [ $SUMMER -eq 1 ]; then
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "seeisotau_p${ONDOMAIN}_evol.2.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH2 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2.var" "${CORRECTION_DIR}/iso_integ.var" "${CORRECTION_DIR}/tau_integ_SUMMER_CALIB2.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_p${ONDOMAIN}_evol.2.stat"
else
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "seeisotau_p${ONDOMAIN}_evol.2.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH2 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2.var" "${CORRECTION_DIR}/iso_integ.var" "${CORRECTION_DIR}/tau_integ_WINTER_CALIB2.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_p${ONDOMAIN}_evol.2.stat"
fi
log "  prepare seeisotau_p${ONDOMAIN}_evol.3.stat in 02-12 UT from $PLOTBASEH1 to $PLOTTOPH1 meters"
if [ $SUMMER -eq 1 ]; then
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "seeisotau_p${ONDOMAIN}_evol.3.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH1 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2.var" "${CORRECTION_DIR}/iso_integ.var" "${CORRECTION_DIR}/tau_integ_SUMMER_CALIB2.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_p${ONDOMAIN}_evol.3.stat"
else
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_new_algo_p${ONDOMAIN}.dat" "seeisotau_p${ONDOMAIN}_evol.3.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH1 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2.var" "${CORRECTION_DIR}/iso_integ.var" "${CORRECTION_DIR}/tau_integ_WINTER_CALIB2.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_p${ONDOMAIN}_evol.3.stat"
fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_p${ONDOMAIN}_evol.1.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "TOT" ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_p${ONDOMAIN}_evol.1.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "TOT" ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_seeisotau_time.py"
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_p${ONDOMAIN}_evol.2.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "FA" ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_p${ONDOMAIN}_evol.2.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "FA" ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_seeisotau_time.py"
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_p${ONDOMAIN}_evol.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "BL" ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_p${ONDOMAIN}_evol.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "BL" ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_seeisotau_time.py"
############################################
# SEEING THETA0 and TAU0 TEMPORAL EVOLUTION OF VERTICAL PROFILE COMPUTED WITH OS18 METHOD
ONDOMAIN=${DOMP1}
#Variable for trends
ONDOMAIN_SEETRENDS=${ONDOMAIN}
log "  prepare seeisotau_OS18_p${ONDOMAIN}_evol.1.stat in 02-12 UT from $PLOTBASEH1 to $PLOTTOPH2 meters"
if [ $SUMMER -eq 1 ]; then
  echo "SEEING SUMMER CALIB CORRECTION" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2_OS18.var"
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "seeisotau_OS18_p${ONDOMAIN}_evol.1.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2_OS18.var" "${CORRECTION_DIR}/iso_integ_OS18.var" "${CORRECTION_DIR}/tau_integ_SUMMER_CALIB2_OS18.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_OS18_p${ONDOMAIN}_evol.1.stat"
else
  echo "SEEING WINTER CALIB CORRECTION" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2_OS18.var"
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "seeisotau_OS18_p${ONDOMAIN}_evol.1.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2_OS18.var" "${CORRECTION_DIR}/iso_integ_OS18.var" "${CORRECTION_DIR}/tau_integ_WINTER_CALIB2_OS18.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_OS18_p${ONDOMAIN}_evol.1.stat"
fi
log "  prepare seeisotau_OS18_p${ONDOMAIN}_evol.2.stat in 02-12 UT from $PLOTBASEH2 to $PLOTTOPH2 meters"
if [ $SUMMER -eq 1 ]; then
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "seeisotau_OS18_p${ONDOMAIN}_evol.2.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH2 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2_OS18.var" "${CORRECTION_DIR}/iso_integ_OS18.var" "${CORRECTION_DIR}/tau_integ_SUMMER_CALIB2_OS18.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_OS18_p${ONDOMAIN}_evol.2.stat"
else
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "seeisotau_OS18_p${ONDOMAIN}_evol.2.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH2 $PLOTTOPH2 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2_OS18.var" "${CORRECTION_DIR}/iso_integ_OS18.var" "${CORRECTION_DIR}/tau_integ_WINTER_CALIB2_OS18.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_OS18_p${ONDOMAIN}_evol.2.stat"
fi
log "  prepare seeisotau_OS18_p${ONDOMAIN}_evol.3.stat in 02-12 UT from $PLOTBASEH1 to $PLOTTOPH1 meters"
if [ $SUMMER -eq 1 ]; then
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "seeisotau_OS18_p${ONDOMAIN}_evol.3.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH1 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_SUMMER_CALIB2_OS18.var" "${CORRECTION_DIR}/iso_integ_OS18.var" "${CORRECTION_DIR}/tau_integ_SUMMER_CALIB2_OS18.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_OS18_p${ONDOMAIN}_evol.3.stat"
else
  ${UTILDIR}/treat_seeisotau_evol "${DAT_DIR}/cn2_OS18_p${ONDOMAIN}.dat" "seeisotau_OS18_p${ONDOMAIN}_evol.3.stat" $PLOTSTARTT $PLOTENDT $PLOTBASEH1 $PLOTTOPH1 "${DAT_DIR}/wind_prof_p${ONDOMAIN}.dat" "${CORRECTION_DIR}/seeing_integ_WINTER_CALIB2_OS18.var" "${CORRECTION_DIR}/iso_integ_OS18.var" "${CORRECTION_DIR}/tau_integ_WINTER_CALIB2_OS18.var"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR preparing seeisotau_OS18_p${ONDOMAIN}_evol.3.stat"
fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_OS18_p${ONDOMAIN}_evol.1.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "TOT" ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_OS18_p${ONDOMAIN}_evol.1.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "TOT" ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_seeisotau_OS18_time.py"
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_OS18_p${ONDOMAIN}_evol.2.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "FA" ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_OS18_p${ONDOMAIN}_evol.2.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "FA" ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_seeisotau_OS18_time.py"
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_OS18_p${ONDOMAIN}_evol.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "BL" ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_seeisotau_time.py "seeisotau_OS18_p${ONDOMAIN}_evol.3.stat" ${UTOFFSET} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${DAWNMINDELTA} ${DUSKMINDELTA} ${SUNSETMINDELTA} ${SUNRISEMINDELTA} "BL" ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_seeisotau_OS18_time.py"
############################################
############################################
#NOW COMPUTE 2D MAPS: HERE ONDOMAIN MEANS THE DOMAIN IN WHICH COMPUTATION IS DONE
############################################
#Generate orograpy file
ONDOMAIN=${DOM_FIRST}
${UTILDIR}/read_latlonZS "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${PLOT_DIR}/ZSlatlon.${ONDOMAIN}.stat"
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR generating ${PLOT_DIR}/ZSlatlon.${ONDOMAIN}.stat"
if [ ${DOM_SECOND} -ne ${DOM_FIRST} ]; then
  ONDOMAIN=${DOM_SECOND}
  ${UTILDIR}/read_latlonZS "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${PLOT_DIR}/ZSlatlon.${ONDOMAIN}.stat"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR generating ${PLOT_DIR}/ZSlatlon.${ONDOMAIN}.stat"
fi
############################################
# 2D WIND K=2 maps
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare wind_2d_K2_${ONDOMAIN}.*.stat at level K=2"
WIND_FILENUMUT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_K_2_d.${ONDOMAIN}_001*"|wc -l)
WIND_FILENUMVT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_K_2_d.${ONDOMAIN}_001*"|wc -l)
if [ $WIND_FILENUMUT -ne 1 ] || [ $WIND_FILENUMVT -ne 1 ]; then
  error "!!! Wrong number of ficval wind files"
fi
WIND_FILEUT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_K_2_d.${ONDOMAIN}_001*"))
WIND_FILEVT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "VT_K_2_d.${ONDOMAIN}_001*"))
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d_K2_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d_K2_${ONDOMAIN}*.stat file, check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.1_K2_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.1_K2_${ONDOMAIN}*.stat file (slice1), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.2_K2_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.2_K2_${ONDOMAIN}*.stat file (slice2), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.3_K2_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.3_K2_${ONDOMAIN}*.stat file (slice3), check logs to see where and why"
#Plot all hours and global average
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d_K2*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
done
#Plot average slices
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_K2*"|grep "\.avg\.stat"|grep "slice\.1"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_K2*"|grep "\.avg\.stat"|grep "slice\.2"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_K2*"|grep "\.avg\.stat"|grep "slice\.3"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
############################################
# 2D WIND PR=200mb maps
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare wind_2d_PR200_${ONDOMAIN}.*.stat at level PR=200mb"
WIND_FILENUMUT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_PR_200_d.${ONDOMAIN}_001*"|wc -l)
WIND_FILENUMVT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_PR_200_d.${ONDOMAIN}_001*"|wc -l)
if [ $WIND_FILENUMUT -ne 1 ] || [ $WIND_FILENUMVT -ne 1 ]; then
  error "!!! Wrong number of ficval wind files"
fi
WIND_FILEUT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_PR_200_d.${ONDOMAIN}_001*"))
WIND_FILEVT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "VT_PR_200_d.${ONDOMAIN}_001*"))
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d_PR200_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d_PR200_${ONDOMAIN}*.stat file, check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.1_PR200_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.1_PR200_${ONDOMAIN}*.stat file (slice1), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.2_PR200_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.2_PR200_${ONDOMAIN}*.stat file (slice2), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.3_PR200_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.3_PR200_${ONDOMAIN}*.stat file (slice3), check logs to see where and why"
#Plot all hours and global average
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d_PR200*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
done
#Plot average slices
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_PR200*"|grep "\.avg\.stat"|grep "slice\.1"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_PR200*"|grep "\.avg\.stat"|grep "slice\.2"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_PR200*"|grep "\.avg\.stat"|grep "slice\.3"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
############################################
# 2D WIND Z_10227 maps
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare wind_2d_Z7100_${ONDOMAIN}.*.stat at level Z=10227m"
WIND_FILENUMUT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_10227_d.${ONDOMAIN}_001*"|wc -l)
WIND_FILENUMVT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_10227_d.${ONDOMAIN}_001*"|wc -l)
if [ $WIND_FILENUMUT -ne 1 ] || [ $WIND_FILENUMVT -ne 1 ]; then
  error "!!! Wrong number of ficval wind files"
fi
WIND_FILEUT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_10227_d.${ONDOMAIN}_001*"))
WIND_FILEVT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "VT_Z_10227_d.${ONDOMAIN}_001*"))
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d_Z7100_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d_Z7100_${ONDOMAIN}*.stat file, check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.1_Z7100_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.1_Z7100_${ONDOMAIN}*.stat file (slice1), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.2_Z7100_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.2_Z7100_${ONDOMAIN}*.stat file (slice2), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.3_Z7100_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.3_Z7100_${ONDOMAIN}*.stat file (slice3), check logs to see where and why"
#Plot all hours and global average
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d_Z7100*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
done
#Plot average slices
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z7100*"|grep "\.avg\.stat"|grep "slice\.1"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z7100*"|grep "\.avg\.stat"|grep "slice\.2"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z7100*"|grep "\.avg\.stat"|grep "slice\.3"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d.py"
############################################
# 2D WIND Z_9276 maps
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare wind_2d_Z6149_${ONDOMAIN}.*.stat at level Z=9276m"
WIND_FILENUMUT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_9276_d.${ONDOMAIN}_001*"|wc -l)
WIND_FILENUMVT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_9276_d.${ONDOMAIN}_001*"|wc -l)
if [ $WIND_FILENUMUT -ne 1 ] || [ $WIND_FILENUMVT -ne 1 ]; then
  error "!!! Wrong number of ficval wind files"
fi
WIND_FILEUT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_9276_d.${ONDOMAIN}_001*"))
WIND_FILEVT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "VT_Z_9276_d.${ONDOMAIN}_001*"))
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d_Z6149_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d_Z6149_${ONDOMAIN}*.stat file, check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.1_Z6149_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.1_Z6149_${ONDOMAIN}*.stat file (slice1), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.2_Z6149_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.2_Z6149_${ONDOMAIN}*.stat file (slice2), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.3_Z6149_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.3_Z6149_${ONDOMAIN}*.stat file (slice3), check logs to see where and why"
#Plot all hours and global average
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d_Z6149*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_30.py"
done
#Plot average slices
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z6149*"|grep "\.avg\.stat"|grep "slice\.1"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_30.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z6149*"|grep "\.avg\.stat"|grep "slice\.2"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_30.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z6149*"|grep "\.avg\.stat"|grep "slice\.3"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_30.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_30.py"
############################################
# 2D WIND Z_6677 maps
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare wind_2d_Z3550_${ONDOMAIN}.*.stat at level Z=6677m"
WIND_FILENUMUT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_6677_d.${ONDOMAIN}_001*"|wc -l)
WIND_FILENUMVT=$(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_6677_d.${ONDOMAIN}_001*"|wc -l)
if [ $WIND_FILENUMUT -ne 1 ] || [ $WIND_FILENUMVT -ne 1 ]; then
  error "!!! Wrong number of ficval wind files"
fi
WIND_FILEUT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "UT_Z_6677_d.${ONDOMAIN}_001*"))
WIND_FILEVT=$(basename $(find "${FICVAL_DIR}" -maxdepth 1 -name "VT_Z_6677_d.${ONDOMAIN}_001*"))
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d_Z3550_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d_Z3550_${ONDOMAIN}*.stat file, check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.1_Z3550_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.1_Z3550_${ONDOMAIN}*.stat file (slice1), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.2_Z3550_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.2_Z3550_${ONDOMAIN}*.stat file (slice2), check logs to see where and why"
${UTILDIR}/read_latlonWIND "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/${WIND_FILEUT}" "${FICVAL_DIR}/${WIND_FILEVT}" "wind_2d.slice.3_Z3550_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing wind_2d.slice.3_Z3550_${ONDOMAIN}*.stat file (slice3), check logs to see where and why"
#Plot all hours and global average
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d_Z3550*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_60.py"
done
#Plot average slices
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z3550*"|grep "\.avg\.stat"|grep "slice\.1"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_60.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z3550*"|grep "\.avg\.stat"|grep "slice\.2"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_60.py"
FILENAME=$(basename $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_2d.*_Z3550*"|grep "\.avg\.stat"|grep "slice\.3"))
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
echo "******"
${PYTHONEXE} ${PYTHONPLOT}/plot_wind_2d_60.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${HOUR_SHIFT_PLOT}
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_2d_60.py"
############################################
# 2D SEEING MAPS
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare see_2d_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}.*.stat from ${PLOTBASEH1}m to ${PLOTTOPH2}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "see_2d_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "see_2d.slice.1_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files (slice1), check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "see_2d.slice.2_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files (slice2), check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "see_2d.slice.3_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files (slice3), check logs to see where and why"

log "  prepare see_2d_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}.*.stat from ${PLOTBASEH2}m to ${PLOTTOPH2}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "see_2d_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "see_2d.slice.1_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "see_2d.slice.2_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "see_2d.slice.3_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"

log "  prepare see_2d_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}.*.stat from ${PLOTBASEH1}m to ${PLOTTOPH1}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "see_2d_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "see_2d.slice.1_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "see_2d.slice.2_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/SNG_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "see_2d.slice.3_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of see_2d_*.stat files, check logs to see where and why"

for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "see_2d_*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=2.0
  else
    #BL AND TOT
    CUTOFF_VAR=3.0
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_see_2d.py"
done
#Plot average slices
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "see_2d.*"|grep "\.avg\.stat"|grep "slice\.1"); do
  FILENAME=$(basename $i)
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=2.0
  else
   #BL AND TOT
    CUTOFF_VAR=3.0
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_see_2d.py"
done
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "see_2d.*"|grep "\.avg\.stat"|grep "slice\.2"); do
  FILENAME=$(basename $i)
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=2.0
  else
    #BL AND TOT
    CUTOFF_VAR=3.0
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_see_2d.py"
done
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "see_2d.*"|grep "\.avg\.stat"|grep "slice\.3"); do
  FILENAME=$(basename $i)
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=2.0
  else
    #BL AND TOT
    CUTOFF_VAR=3.0
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_see_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_see_2d.py"
done
############################################
# 2D ISO MAPS
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare iso_2d_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}.*.stat from ${PLOTBASEH1}m to ${PLOTTOPH2}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ISO_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "iso_2d_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of iso_2d_*.stat files, check logs to iso where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ISO_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "iso_2d.slice.1_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of iso_2d_*.stat files (slice1), check logs to iso where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ISO_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "iso_2d.slice.2_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of iso_2d_*.stat files (slice2), check logs to iso where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ISO_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "iso_2d.slice.3_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of iso_2d_*.stat files (slice3), check logs to iso where and why"

CUTOFF_VAR=7.0
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "iso_2d_*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_iso_2d.py"
done
#Plot average slices
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "iso_2d.*"|grep "\.avg\.stat"|grep "slice\.1"); do
  FILENAME=$(basename $i)
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_iso_2d.py"
done
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "iso_2d.*"|grep "\.avg\.stat"|grep "slice\.2"); do
  FILENAME=$(basename $i)
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_iso_2d.py"
done
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "iso_2d.*"|grep "\.avg\.stat"|grep "slice\.3"); do
  FILENAME=$(basename $i)
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_iso_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_see_2d.py"
  ls DATE_iso_hor_map_dom_Houravg_slice3-20-20000.png  
done
############################################
# 2D TAU0 MAPS
ONDOMAIN=${DOM_FIRST}
DELTAXMAP=${DOM_FIRST_DX}
log "  prepare tau_2d_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}.*.stat from ${PLOTBASEH1}m to ${PLOTTOPH2}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "tau_2d_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "tau_2d.slice.1_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files (slice1), check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "tau_2d.slice.2_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files (slice2), check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "tau_2d.slice.3_${PLOTBASEH1}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files (slice3), check logs to tau where and why"

log "  prepare tau_2d_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}.*.stat from ${PLOTBASEH2}m to ${PLOTTOPH2}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "tau_2d_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "tau_2d.slice.1_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "tau_2d.slice.2_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH2}_${PLOTTOPH2}.fic" "tau_2d.slice.3_${PLOTBASEH2}_${PLOTTOPH2}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"

log "  prepare tau_2d_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}.*.stat from ${PLOTBASEH1}m to ${PLOTTOPH1}m"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "tau_2d_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "tau_2d.slice.1_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTFIRSTEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "tau_2d.slice.2_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTFIRSTEXIT $PLOTSECONDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"
${UTILDIR}/read_latlonSEE "${FICVAL_DIR}/LATLON_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/ZS_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CHT_STAR_SUP_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH1}.fic" "tau_2d.slice.3_${PLOTBASEH1}_${PLOTTOPH1}_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSECONDEXIT $PLOTENDEXIT 
EXIT=$?
[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of tau_2d_*.stat files, check logs to tau where and why"

for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "tau_2d_*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
  FILENAME=$(basename "${i}")
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=15.0
  else
    if [ $(echo ${FILENAME}|cut -d"_" -f4) -eq $PLOTTOPH1 ]; then
      #BOUNDARY LAYER
      CUTOFF_VAR=30.0
    else
      #TOTAL
      CUTOFF_VAR=15.0
    fi
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_tau_2d.py"
done
#Plot average slices
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "tau_2d.*"|grep "\.avg\.stat"|grep "slice\.1"); do
  FILENAME=$(basename $i)
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=15.0
  else
    if [ $(echo ${FILENAME}|cut -d"_" -f4) -eq $PLOTTOPH1 ]; then
      #BOUNDARY LAYER
      CUTOFF_VAR=30.0
    else
      #TOTAL
      CUTOFF_VAR=15.0
    fi
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTDUSK} ${PLOTFIRSTT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_tau_2d.py"
done
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "tau_2d.*"|grep "\.avg\.stat"|grep "slice\.2"); do
  FILENAME=$(basename $i)
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=15.0
  else
    if [ $(echo ${FILENAME}|cut -d"_" -f4) -eq $PLOTTOPH1 ]; then
      #BOUNDARY LAYER
      CUTOFF_VAR=30.0
    else
      #TOTAL
      CUTOFF_VAR=15.0
    fi
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTFIRSTT} ${PLOTSECONDT} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_tau_2d.py"
done
for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "tau_2d.*"|grep "\.avg\.stat"|grep "slice\.3"); do
  FILENAME=$(basename $i)
  if [ $(echo ${FILENAME}|cut -d"_" -f3) -eq $PLOTBASEH2 ]; then
    #FREE ATMOSPHERE
    CUTOFF_VAR=15.0
  else
    if [ $(echo ${FILENAME}|cut -d"_" -f4) -eq $PLOTTOPH1 ]; then
      #BOUNDARY LAYER
      CUTOFF_VAR=30.0
    else
      #TOTAL
      CUTOFF_VAR=15.0
    fi
  fi
echo "******"
echo ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
echo "******"
  ${PYTHONEXE} ${PYTHONPLOT}/plot_tau_2d.py ${FILENAME} ${DELTAXMAP} ${YEARFIG} ${MONTHFIG} ${DAYFIG} ${UTOFFSET} ${PLOTSECONDT} ${PLOTDAWN} ${XSNG1} ${YSNG1} ${CUTOFF_VAR} ${HOUR_SHIFT_PLOT}
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_tau_2d.py"
done
############################################
############################################
#NOW COMPUTE VERTICAL CUTS: HERE ONDOMAIN MEANS THE DOMAIN IN WHICH COMPUTATION IS DONE
############################################
## CN2 VERTICAL CUT
#ONDOMAIN=${DOM_FIRST}
#DELTAXMAP=${DOM_FIRST_DX}
#log "  prepare cn2_cv_${ONDOMAIN}.*.stat"
#${UTILDIR}/read_latlonCV "${FICVAL_DIR}/ALT_cv_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/CN2_cv_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "cn2_cv_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
#EXIT=$?
#[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of cn2_cv_*.stat files, check logs to iso where and why"
#for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "cn2_cv_*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
#  cp "${IDLDIR}/plot_cn2_cv.pro" .
#  FILENAME=$(basename "${i}")
#  sed -e "s/cn2_cv_stat_file/${FILENAME}/g;s/DELTA_X_VAR/${DELTAXMAP}/g" -i plot_cn2_cv.pro
#  sed -e "s/BASEH_VAR/0/g;s/TOPH_VAR/10/g" -i plot_cn2_cv.pro
#  sed -e "s/NIGHTSTART_VAR/${PLOTDUSK}/g;s/NIGHTEND_VAR/${PLOTDAWN}/g" -i plot_cn2_cv.pro
#  sed -e "s/YEARF_VAR/${YEARFIG}/;s/MONTHF_VAR/${MONTHFIG}/;s/DAYF_VAR/${DAYFIG}/;s/UTOFFSET_VAR/${UTOFFSET}/" -i plot_cn2_cv.pro
#  idl -quiet -e "plot_cn2_cv"
#  EXIT=$?
#  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_cn2_cv.pro"
#done

## WIND VERTICAL CUT
#ONDOMAIN=${DOM_SECOND}
#DELTAXMAP=${DOM_SECOND_DX}
#log "  prepare wind_cv_${ONDOMAIN}.*.stat"
#${UTILDIR}/read_latlonCV "${FICVAL_DIR}/ALT_cv_d.${ONDOMAIN}.fic" "${FICVAL_DIR}/MUTVT_cv_d.${ONDOMAIN}_001_${PLOTBASEH1}_${PLOTTOPH2}.fic" "wind_cv_${ONDOMAIN}" $PLOTSTARTEXIT $PLOTENDEXIT $PLOTSTARTEXIT $PLOTENDEXIT 
#EXIT=$?
#[ $EXIT -eq 0 ] || error "!!! ERROR preparing one of wind_cv_*.stat files, check logs to iso where and why"
#for i in $(find "${PLOT_DIR}" -maxdepth 1 -name "wind_cv_*"|sort|grep -v "\.med\.stat"|grep -v "slice"); do
#  cp "${IDLDIR}/plot_wind_cv.pro" .
#  FILENAME=$(basename "${i}")
#  sed -e "s/wind_cv_stat_file/${FILENAME}/g;s/DELTA_X_VAR/${DELTAXMAP}/g" -i plot_wind_cv.pro
#  sed -e "s/BASEH_VAR/0/g;s/TOPH_VAR/10/g" -i plot_wind_cv.pro
#  sed -e "s/NIGHTSTART_VAR/${PLOTDUSK}/g;s/NIGHTEND_VAR/${PLOTDAWN}/g" -i plot_wind_cv.pro
#  sed -e "s/YEARF_VAR/${YEARFIG}/;s/MONTHF_VAR/${MONTHFIG}/;s/DAYF_VAR/${DAYFIG}/;s/UTOFFSET_VAR/${UTOFFSET}/" -i plot_wind_cv.pro
#  idl -quiet -e "plot_wind_cv"
#  EXIT=$?
#  [ $EXIT -eq 0 ] || error "!!! ERROR plotting plot_wind_cv.pro"
#done
############################################
##################################################################################################
# FILE CONVERSION AND ANIMATION
############################################
log " -- GENERATING ANIMATED GIF -- "
log " -- date_start_gengif: "$(date +%F/%T)

#Convert to gif
#LISTTOCONVERT=$(find "${PLOT_DIR}" -maxdepth 1 -name "*.gif")
#parallel --gnu -j $NUM_PROC ${UTILDIR}/convert_script.sh ::: "$LISTTOCONVERT"
for i in $(find "${PLOT_DIR}" -name "*_hor_map_dom*.png"); do
  convert "${i}" "${i%.*}.gif"
  rm "${i}" -f
done

LISTABASEFILENAME=""
for lbase in $(find "${PLOT_DIR}" -maxdepth 1 -name "*_hor_map_dom*"|rev|cut -d"_" -f3- |cut -d"_" -f-4|rev|sort|uniq); do
  LISTABASEFILENAME="$LISTABASEFILENAME $(basename $lbase)"
done
#  LISTABASEFILENAME="DATE_see_hor_map_dom DATE_iso_hor_map_dom DATE_tau_hor_map_dom"
for nbf in $LISTABASEFILENAME; do
  listaH1=""
  for list in $(find "${PLOT_DIR}" -maxdepth 1 -name "${nbf}_dom_*"|grep -v ANIM|grep -v "\.avg\.stat"|grep -v "slice"| rev|cut -d"_" -f1|cut -d"-" -f2|rev|sort|uniq); do
    listaH1="$listaH1 $(basename $list)"
  done
  for list in $(find "${PLOT_DIR}" -maxdepth 1 -name "${nbf}_dom_*"|grep -v ANIM|grep -v "\.avg\.stat"|grep -v "slice"| rev|cut -d"_" -f1|cut -d"." -f2|cut -d"-" -f1|rev|sort|uniq); do
    listaH2="$listaH2 $(basename $list)"
  done
  FLAGINTEGRAL=1
  if [ $(echo $listaH1|grep "\.gif"|wc -l) -gt 0 ]; then
    FLAGINTEGRAL=0
  fi
  if [ $FLAGINTEGRAL -eq 1 ]; then
    for nh1 in $listaH1; do
      for nh2 in $listaH2; do
        NFILES=$(find "${PLOT_DIR}" -maxdepth 1 -name "${nbf}_dom_*" |grep "${nh1}-${nh2}\.gif"|grep -v "Houravg"|grep -v "slice"|grep -v "med\.gif"|grep -v "_ANIM"|wc -l)
        LISTAGIF=$(ls ${nbf}_* |grep "${nh1}-${nh2}\.gif"|sort|grep -v "Houravg"|grep -v "med\.gif"|grep -v "slice"|grep -v "_ANIM")
        NAMEANIMFILE="${nbf}_dom_ANIM-${nh1}-${nh2}.gif"
        if [ $NFILES -ge 1 ]; then
          create_anim
          rm $LISTAGIF -f
        fi
      done
    done
  else
    NFILES=$(find "${PLOT_DIR}" -maxdepth 1 -name "${nbf}_dom_*"|grep "\.gif"|grep -v "avg\.gif"|grep -v "slice"|grep -v "med\.gif"|grep -v "_ANIM"|wc -l)
    LISTAGIF=$(ls ${nbf}_* |grep "\.gif"|sort|grep -v "avg\.gif"|grep -v "slice"|grep -v "med\.gif"|grep -v "_ANIM")
    NAMEANIMFILE="${nbf}_dom_ANIM.gif"
    if [ $NFILES -ge 1 ]; then
      create_anim
      rm $LISTAGIF -f
    fi
  fi
done

############################################
# GENERATE TRENDS FILE
############################################
DONETRENDS=0
if [ ${UPLOADFIGS} -eq 1 ]; then
  log "**********"
  log "GENERATING TRENDS FILE"
  log "**********"
  ${UTILDIR}/trends "${YEARFIG}${MONTHFIG}${DAYFIG}" "seeisotau_p${ONDOMAIN_SEETRENDS}_evol.1.stat" "wind_p${ONDOMAIN_WINDTRENDS}_evollevel_k4.stat" "wind_p${ONDOMAIN_WDTRENDS}_evollevel_k4.stat" "temp_p${ONDOMAIN_TEMPTRENDS}_evollevel_k4.stat" "rh_p${ONDOMAIN_RHTRENDS}_evollevel_k4.stat" "wapor_p${ONDOMAIN_WAPORTRENDS}_evol.1.stat"  "trends.dat"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR generating trends"
  DONETRENDS=1
else
  if [ $WINDAVGHIGH -eq 1 ]; then
    log "**********"
    log "AVERAGE WIND SPEED ON K=4 IS:"$WINDAVG
    log "OVERWRITING TRENDS WIND SPEED TIME EVOLUTION AT GROUND"
    log "**********"  
    ${UTILDIR}/trends_redo "${TRENDSDIR}/${YEARB}${MONTHB}${DAYB}_trends.dat" "wind_p${ONDOMAIN_WINDTRENDS}_evollevel_k4.stat" "trends.dat"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR generating trends"
    DONETRENDS=1
  else
    log "**********"
    log "AVERAGE WIND SPEED ON K=4 IS:"$WINDAVG
    log "DOING NOTHING FOR TRENDS"
    log "**********"  
  fi
fi
if [ $DONETRENDS -eq 1 ]; then
  check_directory "$TRENDSDIR"
  mv trends.dat "${TRENDSDIR}/${YEARB}${MONTHB}${DAYB}_trends.dat"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR storing trends"
fi
############################################
# GENERATE OUTPUT FILE FOR GROUND PARAMETERS
############################################
#TSTAMPSTART=$(date -u -d "${YEARB}-${MONTHB}-${DAB} ${HOUR_ARRAY[0]}:00:00" +%s)
DONEGROUNDASCII=0
TSTAMPSTART=$DATESTARTDAYBUNIX
if [ ${UPLOADFIGS} -eq 1 ]; then
  log "**********"
  log "GENERATING GROUND ASCII OUTPUTS FILE"
  log "**********"
  ${UTILDIR}/finalascii "${YEARFIG}${MONTHFIG}${DAYFIG}" ${TSTAMPSTART} $PLOTSTARTT $PLOTENDT "temp_p${ONDOMAIN_TEMPTRENDS}_evollevel_k4.stat" "wind_p${ONDOMAIN_WINDTRENDS}_evollevel_k4.stat" "rh_p${ONDOMAIN_RHTRENDS}_evollevel_k4.stat" "seeisotau_p${ONDOMAIN_SEETRENDS}_evol.1.stat" "$DUSKUNIX" "$DAWNUNIX" "output.dat"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR generating final ascii output for ground parameters"
  DONEGROUNDASCII=1
else
  if [ $WINDAVGHIGH -eq 1 ]; then
    log "**********"
    log "AVERAGE WIND SPEED ON K=4 IS: $WINDAVG"
    log "OVERWRITING GROUND ASCII OUTPUTS FOR WIND SPEED TIME EVOLUTION AT GROUND"
    log "**********"  
    ${UTILDIR}/finalascii_redo "${FINALOUTDIR}/${YEARB}${MONTHB}${DAYB}_params_output.dat" $PLOTSTARTT $PLOTENDT "wind_p${ONDOMAIN_WINDTRENDS}_evollevel_k4.stat" "output.dat"
    EXIT=$?
    [ $EXIT -eq 0 ] || error "!!! ERROR generating final ascii output for ground parameters"
    DONEGROUNDASCII=1
  else
    log "**********"
    log "AVERAGE WIND SPEED ON K=4 IS: $WINDAVG"
    log "DOING NOTHING FOR ASCII OUTPUTS AT GROUND"
    log "**********"  
  fi
fi
if [ $DONEGROUNDASCII -eq 1 ]; then
  check_directory "$FINALOUTDIR"
  #THE FOLLOWING DESTINATION NAME IS ALSO USED IN backup.sh !!! PLEASE PAY ATTENTION TO CHANGES
  mv output.dat "${FINALOUTDIR}/${YEARB}${MONTHB}${DAYB}_params_output.dat"
  EXIT=$?
  [ $EXIT -eq 0 ] || error "!!! ERROR storing final ascii outputs"
fi
############################################
# DATE ALL OUTPUT FILES and remove cruft
############################################
##########################
#Copy stat files for the Kalman stuff
check_directory "${AUTOREGRESSION_DIR}"
check_directory "${AUTOREGRESSION_STORE_DIR}"

AUTOREGRESSION_FILE_LIST="seeisotau_p1_evol.1.stat HF_seeisotau_p1_evol.1.stat wind_p1_evollevel_k4.stat HF_wind_p1_evollevel_k4.stat temp_p1_evollevel_k4.stat HF_temp_p1_evollevel_k4.stat rh_p1_evollevel_k4.stat HF_rh_p1_evollevel_k4.stat wapor_p1_evol.1.stat HF_wapor_p1_evol.1.stat"

for seefile in ${AUTOREGRESSION_FILE_LIST}; do
  #Copy file to the backup location
  if test -e ${AUTOREGRESSION_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}; then
    error_soft "WARNING: simulation is copying over an already existing file for the Autoregression filter: ${AUTOREGRESSION_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}"
  fi
  test -f "${seefile}"|| error_soft "ERROR SOFT: ${seefile} missing! AUTOREGRESSION WILL FAIL"
  cp "${seefile}" "${AUTOREGRESSION_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}" -f
  [ $EXIT -eq 0 ] || error_soft "!!! ERROR copying Autoregression file ${seefile} to ${AUTOREGRESSION_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}"

  #Copy file to the proper storage location for AUTOREGRESSION program
  if test -e ${AUTOREGRESSION_STORE_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}; then
    error_soft "WARNING: simulation is copying over an already existing file for the Autoregression filter: ${AUTOREGRESSION_STORE_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}"
  fi
  test -f "${seefile}"|| error_soft "ERROR SOFT: ${seefile} missing! AUTOREGRESSION WILL FAIL"
  cp "${seefile}" "${AUTOREGRESSION_STORE_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}" -f
  [ $EXIT -eq 0 ] || error_soft "!!! ERROR copying Autoregression file ${seefile} to ${AUTOREGRESSION_STORE_DIR}/${YEARB}${MONTHB}${DAYB}_${seefile}"
done

##########################
if [ $TESTRUN -eq 0 ]; then
  rm *.pro -f
  rm *.stat -f
fi
cp ${CONFDIR}/DATE_pageready.png .
for todate in $(ls DATE_*); do
  BASE_NAME=$(echo "${todate}"|cut -d"_" -f2-)
#  test -d DAILY || mkdir DAILY
#  cp "${todate}" "DAILY/DAY0_${BASE_NAME}"
#  rm DAILY/*.dat -f
  mv "${todate}" "${YEARFIG}${MONTHFIG}${DAYFIG}_${BASE_NAME}"
done
check_directory "${PLOTDAT_DIR}"
mv *.dat "${PLOTDAT_DIR}/"

############################################
# DO SOME ORDERING OF FIGURE FILES
############################################
check_directory "${PLOT_DIR}/ARCHIVE"
check_directory "${PLOT_DIR}/ARCHIVE/READY"
cp ${PLOT_DIR}/*_pageready.png ${PLOT_DIR}/ARCHIVE/READY/
check_directory "${PLOT_DIR}/ARCHIVE/CN2"
mv ${PLOT_DIR}/*cn2_*.png ${PLOT_DIR}/ARCHIVE/CN2/
check_directory "${PLOT_DIR}/ARCHIVE/ISO/ISO_EVOL"
mv ${PLOT_DIR}/*iso_evol_*.png ${PLOT_DIR}/ARCHIVE/ISO/ISO_EVOL/
check_directory "${PLOT_DIR}/ARCHIVE/ISO/MAPS"
mv ${PLOT_DIR}/*iso_hor_*.gif ${PLOT_DIR}/ARCHIVE/ISO/MAPS/
check_directory "${PLOT_DIR}/ARCHIVE/RH/RH_PV"
mv ${PLOT_DIR}/*rh_pv*.png ${PLOT_DIR}/ARCHIVE/RH/RH_PV/
check_directory "${PLOT_DIR}/ARCHIVE/RH/RH_LEVEL"
mv ${PLOT_DIR}/*rh_k*.png ${PLOT_DIR}/ARCHIVE/RH/RH_LEVEL/
check_directory "${PLOT_DIR}/ARCHIVE/SEE/SEE_EVOL"
mv ${PLOT_DIR}/*see_evol*.png ${PLOT_DIR}/ARCHIVE/SEE/SEE_EVOL/
check_directory "${PLOT_DIR}/ARCHIVE/SEE/MAPS"
mv ${PLOT_DIR}/*see_hor*.gif ${PLOT_DIR}/ARCHIVE/SEE/MAPS/
check_directory "${PLOT_DIR}/ARCHIVE/TAU/TAU_EVOL"
mv ${PLOT_DIR}/*tau_evol*.png ${PLOT_DIR}/ARCHIVE/TAU/TAU_EVOL/
check_directory "${PLOT_DIR}/ARCHIVE/TAU/MAPS"
mv ${PLOT_DIR}/*tau_hor*.gif ${PLOT_DIR}/ARCHIVE/TAU/MAPS/
check_directory "${PLOT_DIR}/ARCHIVE/TEMP/POT_PV"
mv ${PLOT_DIR}/*theta_pv*.png ${PLOT_DIR}/ARCHIVE/TEMP/POT_PV/
check_directory "${PLOT_DIR}/ARCHIVE/TEMP/ABS_LEVEL"
mv ${PLOT_DIR}/*tempabs_k*.png ${PLOT_DIR}/ARCHIVE/TEMP/ABS_LEVEL/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/MAPS_K2"
mv ${PLOT_DIR}/*windK2_hor*.gif ${PLOT_DIR}/ARCHIVE/WIND/MAPS_K2/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/MAPS_PR200"
mv ${PLOT_DIR}/*windPR200_hor*.gif ${PLOT_DIR}/ARCHIVE/WIND/MAPS_PR200/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/MAPS_LINC"
mv ${PLOT_DIR}/*windZ*_hor*.gif ${PLOT_DIR}/ARCHIVE/WIND/MAPS_LINC/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WD_LEVEL"
mv ${PLOT_DIR}/*winddir_k*.png ${PLOT_DIR}/ARCHIVE/WIND/WD_LEVEL/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WD_PV"
mv ${PLOT_DIR}/*winddir_pv*.png ${PLOT_DIR}/ARCHIVE/WIND/WD_PV/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WS_LEVEL"
mv ${PLOT_DIR}/*wind_k*.png ${PLOT_DIR}/ARCHIVE/WIND/WS_LEVEL/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WS_PV"
mv ${PLOT_DIR}/*wind_pv*.png ${PLOT_DIR}/ARCHIVE/WIND/WS_PV/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WS_LINC"
mv ${PLOT_DIR}/*wind_linc*.png ${PLOT_DIR}/ARCHIVE/WIND/WS_LINC/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WS_FLAO"
mv ${PLOT_DIR}/*wind_flao*.png ${PLOT_DIR}/ARCHIVE/WIND/WS_FLAO/
check_directory "${PLOT_DIR}/ARCHIVE/WIND/WS_ARGOS"
mv ${PLOT_DIR}/*wind_argos*.png ${PLOT_DIR}/ARCHIVE/WIND/WS_ARGOS/
check_directory "${PLOT_DIR}/ARCHIVE/WAPOR/WV_PV"
mv ${PLOT_DIR}/*wapor_pv*.png ${PLOT_DIR}/ARCHIVE/WAPOR/WV_PV/
check_directory "${PLOT_DIR}/ARCHIVE/WAPOR/WV_EVOL"
mv ${PLOT_DIR}/*wapor_evol_*.png ${PLOT_DIR}/ARCHIVE/WAPOR/WV_EVOL/

#Go to $WORKDIR
cd "${WORKDIR}"
##################################################################################################
##################################################################################################
