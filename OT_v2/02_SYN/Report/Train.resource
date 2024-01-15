 
****************************************
Report : resources
Design : Train
Version: T-2022.03
Date   : Sat Nov  4 15:27:19 2023
****************************************


Resource Report for this hierarchy in file ../01_RTL/Train.v
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_1         | DW_cmp         | width=5    | gt_49 (Train.v:49)         |
| sub_x_2        | DW01_dec       | width=4    | sub_50 (Train.v:50)        |
| ne_x_4         | DW_cmp         | width=5    | ne_51 (Train.v:51)         |
| add_x_10       | DW01_inc       | width=5    | add_119 (Train.v:119)      |
| add_x_11       | DW01_inc       | width=5    | add_127 (Train.v:127)      |
| add_x_12       | DW01_inc       | width=5    | add_131 (Train.v:131)      |
| add_x_13       | DW01_inc       | width=5    | add_133 (Train.v:133)      |
| add_x_14       | DW01_inc       | width=5    | add_148 (Train.v:148)      |
| sub_x_15       | DW01_dec       | width=5    | sub_150 (Train.v:150)      |
| DP_OP_140J1_122_5012            |            |                            |
|                | DP_OP_140J1_122_5012 |      |                            |
=============================================================================

Datapath Report for DP_OP_140J1_122_5012
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_140J1_122_5012 | sub_47 (Train.v:47) sub_48 (Train.v:48)             |
|                      | eq_47 (Train.v:47) eq_48 (Train.v:48)               |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 5     |                                          |
| I2    | PI   | Unsigned | 5     |                                          |
| I3    | PI   | Unsigned | 5     |                                          |
| T0    | IFO  | Signed   | 6     | I1 - $unsigned(1'b1) ( Train.v:47 Train.v:48 ) |
| T57   | IFO  | Signed   | 32    | T0                                       |
| O1    | PO   | Unsigned | 1     | I2 == $unsigned(T57) (Train.v:47)        |
| O2    | PO   | Unsigned | 1     | I3 == $unsigned(T57) (Train.v:48)        |
==============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| gt_x_1             | DW_cmp           | apparch (area)     |                |
| sub_x_2            | DW01_dec         | apparch (area)     |                |
| ne_x_4             | DW_cmp           | apparch (area)     |                |
| add_x_10           | DW01_inc         | apparch (area)     |                |
| add_x_11           | DW01_inc         | apparch (area)     |                |
| add_x_12           | DW01_inc         | apparch (area)     |                |
| add_x_13           | DW01_inc         | apparch (area)     |                |
| add_x_14           | DW01_inc         | apparch (area)     |                |
| sub_x_15           | DW01_dec         | apparch (area)     |                |
| DP_OP_140J1_122_5012                  |                    |                |
|                    | DP_OP_140J1_122_5012 | str (area)     |                |
===============================================================================

1
