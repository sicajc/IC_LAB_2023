# set init_design_uniquify 1
# setDesignMode -process 180
# suppressMessage TECHLIB 1318
# restoreDesign CHIP_powerplan.inn.dat CHIP

createBasicPathGroups -expanded
get_path_groups
setPlaceMode -prerouteAsObs {2 3 4 5}
# with io
#setPlaceMode -congEffort auto -timingDriven 1 -clkGateAware 1 -powerDriven 0 -ignoreScan 1 -reorderScan 1 -ignoreSpare 0 -placeIOPins 1 -moduleAwareSpare 0 -preserveRouting 1 -rmAffectedRouting 0 -checkRoute 0 -swapEEQ 0
place_opt_design

redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

# ECO 1
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -preCTS
timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

# ECO 2
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -preCTS
timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

saveDesign ./DBS/CHIP_preCTS.inn

# setPlaceMode -prerouteAsObs {2 3}
# setPlaceMode -fp false
# placeDesign -noPrePlaceOpt
# setDrawView place

# timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

# setOptMode -fixCap true -fixTran true -fixFanoutLoad true
# optDesign -preCTS

# timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

# saveDesign CHIP_preCTS.inn