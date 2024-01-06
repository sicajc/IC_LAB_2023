# set init_design_uniquify 1
# setDesignMode -process 180
# suppressMessage TECHLIB 1318
# restoreDesign CHIP_postRoute.inn.dat CHIP

#==============add fillers================
getFillerMode -quiet
addFiller -cell FILLER64 FILLER32 FILLER16 FILLER8 FILLER4 FILLER2 FILLER1 -prefix FILLER

#addMetalFill -layer { metal1 metal2 metal3 metal4 metal5 metal6 } -timingAware sta -slackThreshold 0.2

#==============streamout================
set ProcessRoot "/RAID2/COURSE/BackUp/2023_Spring/iclab/iclabta01/UMC018_CBDK/CIC/SOCE/"
#set MemGDSFile "../04_MEM/"

setAnalysisMode -analysisType bcwc
write_sdf   -max_view av_func_mode_max \
            -min_view av_func_mode_min \
            -edges noedge \
            -splitsetuphold \
            -remashold \
            -splitrecrem \
            -min_period_edges none \
            ./StreamOut/CHIP.sdf

setStreamOutMode -specifyViaName default -SEvianames false -virtualConnection false -uniquifyCellNamesPrefix false -snapToMGrid false -textSize 1 -version 3
streamOut ./StreamOut/CHIP.gds \
            -mapFile  $ProcessRoot/streamOut.map \
            -merge "  $ProcessRoot/../Phantom/fsa0m_a_generic_core_cic.gds $ProcessRoot/../Phantom/fsa0m_a_t33_generic_io_cic.gds" \
            -stripes 1 -units 1000 -mode ALL

        
saveNetlist ./StreamOut/CHIP.v
saveNetlist -includePowerGround ./StreamOut/CHIP_PG.v

saveDesign ./StreamOut/CHIP.inn

#==================================
setAnalysisMode -analysisType bcwc
write_sdf   -max_view av_func_mode_max \
            -min_view av_func_mode_min \
            -edges noedge \
            -splitsetuphold \
            -remashold \
            -splitrecrem \
            -min_period_edges none \
            ./CHIP.sdf
        
saveNetlist ./CHIP.v
saveNetlist -includePowerGround ./CHIP_PG.v

saveDesign ./CHIP.inn

# summaryReport
summaryReport -noHtml -outfile summaryReport.rpt

# saveDesign CHIP.inn
# all_hold_analysis_views 
# all_setup_analysis_views 
# write_sdf CHIP.sdf
# saveNetlist CHIP.v

# exit

