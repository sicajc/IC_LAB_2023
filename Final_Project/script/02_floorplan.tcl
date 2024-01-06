# set init_design_uniquify 1
# setDesignMode -process 180
# suppressMessage TECHLIB 1318
# restoreDesign CHIP_initail.inn.dat CHIP

#floorPlan -site core_5040 -r 1 0.75 100 100 100 100
floorPlan -dieSizeByIoHeight max -site core_5040 -r 1 0.7 100 100 100 100

#0.75
setObjFPlanBox Instance SRAM_INST/U 201.19 422.92 517.39 599.32
setObjFPlanBox Instance SRAM_DATA/U 201.19 115.24 517.39 291.64

#0.6
setObjFPlanBox Instance SRAM_INST/U 231.88 498.4 548.08 674.8
setObjFPlanBox Instance SRAM_DATA/U 231.88 100.24 548.08 276.64

setObjFPlanBox Instance SRAM_INST/U 108.44 429.92 424.64 606.32
setObjFPlanBox Instance SRAM_DATA/U 108.44 108.24 424.64 284.64

selectInst SRAM_DATA/U
flipOrRotateObject -rotate R90 -group
flipOrRotateObject -rotate R90 -group
deselectAll

addHaloToBlock 8 8 8 8 -allMacro

# fix io pin 
#getPinAssignMode -pinEditInBatch -quiet
#setPinAssignMode -pinEditInBatch true
#editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 6 -pin {{araddr_m_inf[36]} {araddr_m_inf[37]} {araddr_m_inf[38]} {araddr_m_inf[39]} {araddr_m_inf[40]} {araddr_m_inf[41]} {araddr_m_inf[42]} {araddr_m_inf[43]} {araddr_m_inf[44]} {araddr_m_inf[45]} {araddr_m_inf[46]} {araddr_m_inf[47]} {araddr_m_inf[48]} {araddr_m_inf[49]} {araddr_m_inf[50]} {araddr_m_inf[51]} {araddr_m_inf[52]} {araddr_m_inf[53]} {araddr_m_inf[54]} {araddr_m_inf[55]} {araddr_m_inf[56]} {araddr_m_inf[57]} {araddr_m_inf[58]} {araddr_m_inf[59]} {araddr_m_inf[60]} {araddr_m_inf[61]} {araddr_m_inf[62]} {araddr_m_inf[63]} {arid_m_inf[0]} {arid_m_inf[1]} {arid_m_inf[2]} {arid_m_inf[3]} {arid_m_inf[4]} {arid_m_inf[5]} {arid_m_inf[6]} {arid_m_inf[7]} {bid_m_inf[0]} {bid_m_inf[1]} {bid_m_inf[2]} {bid_m_inf[3]} {bready_m_inf[0]} {bresp_m_inf[0]} {bresp_m_inf[1]} {bvalid_m_inf[0]} {wdata_m_inf[0]} {wdata_m_inf[1]} {wdata_m_inf[2]} {wdata_m_inf[3]} {wdata_m_inf[4]} {wdata_m_inf[5]} {wdata_m_inf[6]} {wdata_m_inf[7]} {wdata_m_inf[8]} {wdata_m_inf[9]} {wdata_m_inf[10]} {wlast_m_inf[0]} {wready_m_inf[0]} {wvalid_m_inf[0]}}
#setPinAssignMode -pinEditInBatch false
#
#getPinAssignMode -pinEditInBatch -quiet
#setPinAssignMode -pinEditInBatch true
#editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 2 -spreadType center -spacing 6 -pin {{awaddr_m_inf[0]} {awaddr_m_inf[1]} {awaddr_m_inf[2]} {awaddr_m_inf[3]} {awaddr_m_inf[4]} {awaddr_m_inf[5]} {awaddr_m_inf[6]} {awaddr_m_inf[7]} {awaddr_m_inf[8]} {awaddr_m_inf[9]} {awaddr_m_inf[10]} {awaddr_m_inf[11]} {awaddr_m_inf[12]} {awaddr_m_inf[13]} {awaddr_m_inf[14]} {awaddr_m_inf[15]} {awaddr_m_inf[16]} {awaddr_m_inf[17]} {awaddr_m_inf[18]} {awaddr_m_inf[19]} {awaddr_m_inf[20]} {awaddr_m_inf[21]} {awaddr_m_inf[22]} {awaddr_m_inf[23]} {awaddr_m_inf[24]} {awaddr_m_inf[25]} {awaddr_m_inf[26]} {awaddr_m_inf[27]} {awaddr_m_inf[28]} {awaddr_m_inf[29]} {awaddr_m_inf[30]} {awaddr_m_inf[31]} {awburst_m_inf[0]} {awburst_m_inf[1]} {awid_m_inf[0]} {awid_m_inf[1]} {awid_m_inf[2]} {awid_m_inf[3]} {awlen_m_inf[0]} {awlen_m_inf[1]} {awlen_m_inf[2]} {awlen_m_inf[3]} {awlen_m_inf[4]} {awlen_m_inf[5]} {awlen_m_inf[6]} {awready_m_inf[0]} {awsize_m_inf[0]} {awsize_m_inf[1]} {awsize_m_inf[2]} {awvalid_m_inf[0]} clk IO_stall rst_n {wdata_m_inf[11]} {wdata_m_inf[12]} {wdata_m_inf[13]} {wdata_m_inf[14]} {wdata_m_inf[15]}}
#setPinAssignMode -pinEditInBatch false
#
#getPinAssignMode -pinEditInBatch -quiet
#setPinAssignMode -pinEditInBatch true
#editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection counterclockwise -side Right -layer 3 -spreadType center -spacing 6 -pin {{arburst_m_inf[0]} {arburst_m_inf[1]} {arready_m_inf[0]} {arready_m_inf[1]} {arvalid_m_inf[0]} {arvalid_m_inf[1]} {rdata_m_inf[0]} {rdata_m_inf[1]} {rdata_m_inf[2]} {rdata_m_inf[3]} {rdata_m_inf[4]} {rdata_m_inf[5]} {rdata_m_inf[6]} {rdata_m_inf[7]} {rdata_m_inf[8]} {rdata_m_inf[9]} {rdata_m_inf[10]} {rdata_m_inf[11]} {rdata_m_inf[12]} {rdata_m_inf[13]} {rdata_m_inf[14]} {rdata_m_inf[15]} {rdata_m_inf[16]} {rdata_m_inf[17]} {rdata_m_inf[18]} {rdata_m_inf[19]} {rdata_m_inf[20]} {rdata_m_inf[21]} {rdata_m_inf[22]} {rdata_m_inf[23]} {rdata_m_inf[24]} {rdata_m_inf[25]} {rdata_m_inf[26]} {rdata_m_inf[27]} {rdata_m_inf[28]} {rdata_m_inf[29]} {rdata_m_inf[30]} {rdata_m_inf[31]} {rid_m_inf[0]} {rid_m_inf[1]} {rid_m_inf[2]} {rid_m_inf[3]} {rid_m_inf[4]} {rid_m_inf[5]} {rid_m_inf[6]} {rid_m_inf[7]} {rlast_m_inf[0]} {rlast_m_inf[1]} {rready_m_inf[0]} {rready_m_inf[1]} {rresp_m_inf[0]} {rresp_m_inf[1]} {rresp_m_inf[2]} {rresp_m_inf[3]} {rvalid_m_inf[0]} {rvalid_m_inf[1]}}
#setPinAssignMode -pinEditInBatch false
#
#getPinAssignMode -pinEditInBatch -quiet
#setPinAssignMode -pinEditInBatch true
#editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection counterclockwise -side Bottom -layer 2 -spreadType center -spacing 6 -pin {{araddr_m_inf[0]} {araddr_m_inf[1]} {araddr_m_inf[2]} {araddr_m_inf[3]} {araddr_m_inf[4]} {araddr_m_inf[5]} {araddr_m_inf[6]} {araddr_m_inf[7]} {araddr_m_inf[8]} {araddr_m_inf[9]} {araddr_m_inf[10]} {araddr_m_inf[11]} {araddr_m_inf[12]} {araddr_m_inf[13]} {araddr_m_inf[14]} {araddr_m_inf[15]} {araddr_m_inf[16]} {araddr_m_inf[17]} {araddr_m_inf[18]} {araddr_m_inf[19]} {araddr_m_inf[20]} {araddr_m_inf[21]} {araddr_m_inf[22]} {araddr_m_inf[23]} {araddr_m_inf[24]} {araddr_m_inf[25]} {araddr_m_inf[26]} {araddr_m_inf[27]} {araddr_m_inf[28]} {araddr_m_inf[29]} {araddr_m_inf[30]} {araddr_m_inf[31]} {araddr_m_inf[32]} {araddr_m_inf[33]} {araddr_m_inf[34]} {araddr_m_inf[35]} {arburst_m_inf[2]} {arburst_m_inf[3]} {arlen_m_inf[0]} {arlen_m_inf[1]} {arlen_m_inf[2]} {arlen_m_inf[3]} {arlen_m_inf[4]} {arlen_m_inf[5]} {arlen_m_inf[6]} {arlen_m_inf[7]} {arlen_m_inf[8]} {arlen_m_inf[9]} {arlen_m_inf[10]} {arlen_m_inf[11]} {arlen_m_inf[12]} {arlen_m_inf[13]} {arsize_m_inf[0]} {arsize_m_inf[1]} {arsize_m_inf[2]} {arsize_m_inf[3]} {arsize_m_inf[4]} {arsize_m_inf[5]}}
#setPinAssignMode -pinEditInBatch false


getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -spreadDirection clockwise -edge 1 -layer 2 -spreadType range -offsetEnd 100 -offsetStart 450 -pin {{araddr_m_inf[32]} {araddr_m_inf[33]} {araddr_m_inf[34]} {araddr_m_inf[35]} {araddr_m_inf[36]} {araddr_m_inf[37]} {araddr_m_inf[38]} {araddr_m_inf[39]} {araddr_m_inf[40]} {araddr_m_inf[41]} {araddr_m_inf[42]} {araddr_m_inf[43]} {araddr_m_inf[44]} {araddr_m_inf[45]} {araddr_m_inf[46]} {araddr_m_inf[47]} {araddr_m_inf[48]} {araddr_m_inf[49]} {araddr_m_inf[50]} {araddr_m_inf[51]} {araddr_m_inf[52]} {araddr_m_inf[53]} {araddr_m_inf[54]} {araddr_m_inf[55]} {araddr_m_inf[56]} {araddr_m_inf[57]} {araddr_m_inf[58]} {araddr_m_inf[59]} {araddr_m_inf[60]} {araddr_m_inf[61]} {araddr_m_inf[62]} {araddr_m_inf[63]} {arburst_m_inf[2]} {arburst_m_inf[3]} {arid_m_inf[4]} {arid_m_inf[5]} {arid_m_inf[6]} {arid_m_inf[7]} {arlen_m_inf[7]} {arlen_m_inf[8]} {arlen_m_inf[9]} {arlen_m_inf[10]} {arlen_m_inf[11]} {arlen_m_inf[12]} {arlen_m_inf[13]} {arready_m_inf[1]} {arsize_m_inf[3]} {arsize_m_inf[4]} {arsize_m_inf[5]} {arvalid_m_inf[1]} {rdata_m_inf[16]} {rdata_m_inf[17]} {rdata_m_inf[18]} {rdata_m_inf[19]} {rdata_m_inf[20]} {rdata_m_inf[21]} {rdata_m_inf[22]} {rdata_m_inf[23]} {rdata_m_inf[24]} {rdata_m_inf[25]} {rdata_m_inf[26]} {rdata_m_inf[27]} {rdata_m_inf[28]} {rdata_m_inf[29]} {rdata_m_inf[30]} {rdata_m_inf[31]} {rid_m_inf[4]} {rid_m_inf[5]} {rid_m_inf[6]} {rid_m_inf[7]} {rlast_m_inf[1]} {rready_m_inf[1]} {rresp_m_inf[2]} {rresp_m_inf[3]} {rvalid_m_inf[1]}}
setPinAssignMode -pinEditInBatch false

getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -spreadDirection counterclockwise -edge 3 -layer 2 -spreadType range -offsetEnd 100 -offsetStart 450 -pin {{araddr_m_inf[0]} {araddr_m_inf[1]} {araddr_m_inf[2]} {araddr_m_inf[3]} {araddr_m_inf[4]} {araddr_m_inf[5]} {araddr_m_inf[6]} {araddr_m_inf[7]} {araddr_m_inf[8]} {araddr_m_inf[9]} {araddr_m_inf[10]} {araddr_m_inf[11]} {araddr_m_inf[12]} {araddr_m_inf[13]} {araddr_m_inf[14]} {araddr_m_inf[15]} {araddr_m_inf[16]} {araddr_m_inf[17]} {araddr_m_inf[18]} {araddr_m_inf[19]} {araddr_m_inf[20]} {araddr_m_inf[21]} {araddr_m_inf[22]} {araddr_m_inf[23]} {araddr_m_inf[24]} {araddr_m_inf[25]} {araddr_m_inf[26]} {araddr_m_inf[27]} {araddr_m_inf[28]} {araddr_m_inf[29]} {araddr_m_inf[30]} {araddr_m_inf[31]} {arburst_m_inf[0]} {arburst_m_inf[1]} {arid_m_inf[0]} {arid_m_inf[1]} {arid_m_inf[2]} {arid_m_inf[3]} {arlen_m_inf[0]} {arlen_m_inf[1]} {arlen_m_inf[2]} {arlen_m_inf[3]} {arlen_m_inf[4]} {arlen_m_inf[5]} {arlen_m_inf[6]} {arready_m_inf[0]} {arsize_m_inf[0]} {arsize_m_inf[1]} {arsize_m_inf[2]} {arvalid_m_inf[0]} {rdata_m_inf[0]} {rdata_m_inf[1]} {rdata_m_inf[2]} {rdata_m_inf[3]} {rdata_m_inf[4]} {rdata_m_inf[5]} {rdata_m_inf[6]} {rdata_m_inf[7]} {rdata_m_inf[8]} {rdata_m_inf[9]} {rdata_m_inf[10]} {rdata_m_inf[11]} {rdata_m_inf[12]} {rdata_m_inf[13]} {rdata_m_inf[14]} {rdata_m_inf[15]} {rid_m_inf[0]} {rid_m_inf[1]} {rid_m_inf[2]} {rid_m_inf[3]} {rlast_m_inf[0]} {rready_m_inf[0]} {rresp_m_inf[0]} {rresp_m_inf[1]} {rvalid_m_inf[0]}}
setPinAssignMode -pinEditInBatch false

getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection counterclockwise -edge 2 -layer 3 -spreadType center -spacing 5 -pin {{awaddr_m_inf[0]} {awaddr_m_inf[1]} {awaddr_m_inf[2]} {awaddr_m_inf[3]} {awaddr_m_inf[4]} {awaddr_m_inf[5]} {awaddr_m_inf[6]} {awaddr_m_inf[7]} {awaddr_m_inf[8]} {awaddr_m_inf[9]} {awaddr_m_inf[10]} {awaddr_m_inf[11]} {awaddr_m_inf[12]} {awaddr_m_inf[13]} {awaddr_m_inf[14]} {awaddr_m_inf[15]} {awaddr_m_inf[16]} {awaddr_m_inf[17]} {awaddr_m_inf[18]} {awaddr_m_inf[19]} {awaddr_m_inf[20]} {awaddr_m_inf[21]} {awaddr_m_inf[22]} {awaddr_m_inf[23]} {awaddr_m_inf[24]} {awaddr_m_inf[25]} {awaddr_m_inf[26]} {awaddr_m_inf[27]} {awaddr_m_inf[28]} {awaddr_m_inf[29]} {awaddr_m_inf[30]} {awaddr_m_inf[31]} {awburst_m_inf[0]} {awburst_m_inf[1]} {awid_m_inf[0]} {awid_m_inf[1]} {awid_m_inf[2]} {awid_m_inf[3]} {awlen_m_inf[0]} {awlen_m_inf[1]} {awlen_m_inf[2]} {awlen_m_inf[3]} {awlen_m_inf[4]} {awlen_m_inf[5]} {awlen_m_inf[6]} {awready_m_inf[0]} {awsize_m_inf[0]} {awsize_m_inf[1]} {awsize_m_inf[2]} {awvalid_m_inf[0]} {bid_m_inf[0]} {bid_m_inf[1]} {bid_m_inf[2]} {bid_m_inf[3]} {bready_m_inf[0]} {bresp_m_inf[0]} {bresp_m_inf[1]} {bvalid_m_inf[0]} {wdata_m_inf[0]} {wdata_m_inf[1]} {wdata_m_inf[2]} {wdata_m_inf[3]} {wdata_m_inf[4]} {wdata_m_inf[5]} {wdata_m_inf[6]} {wdata_m_inf[7]} {wdata_m_inf[8]} {wdata_m_inf[9]} {wdata_m_inf[10]} {wdata_m_inf[11]} {wdata_m_inf[12]} {wdata_m_inf[13]} {wdata_m_inf[14]} {wdata_m_inf[15]} {wlast_m_inf[0]} {wready_m_inf[0]} {wvalid_m_inf[0]}}
setPinAssignMode -pinEditInBatch false

getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.28 -pinDepth 0.7 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -edge 0 -layer 3 -spreadType center -spacing 20.16 -pin {IO_stall clk rst_n}
setPinAssignMode -pinEditInBatch false

#left-bottom X Y right-top X Y
# createPlaceBlockage -box 600.05300 779.80900 1969.50700 1035.64100 -type hard
# createPlaceBlockage -box 600.05300 508.92800 1969.50700 749.71100 -type hard
# createPlaceBlockage -box 2989.04600 1479.16800 3221.11800 2845.81700 -type hard
# createPlaceBlockage -box 590.96500 499.30700 1957.61300 757.16500 -type hard
# createPlaceBlockage -box 2292.22100 810.24500 2546.28600 2171.30800 -type hard
# createPlaceBlockage -box 590.89200 574.32800 1965.56600 823.85600 -type hard

# createPlaceBlockage -box 2296.99900 800.16500 2538.49400 2177.87200 -type hard
# createPlaceBlockage -box 634.24800 576.88100 2000.07900 814.41700 -type hard

# createPlaceBlockage -box 2034.97100 976.34500 2292.82900 2342.99400 -type hard
# createPlaceBlockage -box 616.75000 563.77200 2009.18500 834.52300 -type hard

# createPlaceBlockage -box 1809.34500 1234.20300 3175.99300 1492.06100 -type hard
# createPlaceBlockage -box 1802.89800 602.45100 3169.54700 860.30900 -type hard

# createPlaceBlockage -box 1802.89800 1002.13100 3175.99300 1253.54300 -type hard
# createPlaceBlockage -box 1802.89800 602.45100 3169.54700 860.30900 -type hard

#
# createPlaceBlockage -box 465.44400 853.92100 2432.55700 1207.86500 -type hard
# createPlaceBlockage -box 461.26800 451.08800 2430.10200 814.75800 -type hard
# createPlaceBlockage -box 2647.46800 505.43000 3366.44800 747.87700 -type hard

saveDesign ./DBS/CHIP_floorplan.inn


# setObjFPlanBox Instance U_MMSA/W0 618.693 604.32 1931.433 802.17
# setObjFPlanBox Instance U_MMSA/X0 2319.942 831.031 2517.792 2143.771