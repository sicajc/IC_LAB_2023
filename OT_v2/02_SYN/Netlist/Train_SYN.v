/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : T-2022.03
// Date      : Sat Nov  4 15:27:19 2023
/////////////////////////////////////////////////////////////


module Train ( clk, rst_n, in_valid, data, out_valid, result );
  input [3:0] data;
  input clk, rst_n, in_valid;
  output out_valid, result;
  wire   n280, n281, n282, n284, n285, n286, n287, n289, n290, n291, n292,
         n294, n295, n296, n297, n299, n300, n301, n302, n304, n305, n306,
         n307, n309, n310, n311, n312, n314, n315, n316, n317, n319, n320,
         n321, n322, n324, n325, n326, n327, n329, n330, n331, n332, n334,
         n335, n336, n337, n338, n339, n340, n341, n342, n344, n345, n346,
         n347, n348, n349, n350, n351, n352, n353, n354, n355, n356, n357,
         n358, n359, n360, n361, n362, n363, n364, n365, n366, n367, n368,
         n369, n370, n371, n372, n373, n374, n375, n376, n377, n378, n379,
         n380, n381, n382, n383, n384, n385, n386, n387, n388, n389, n390,
         n391, n392, n393, n394, n395, n397, n398, n399, n400, n401, n402,
         n403, n404, n405, n406, n407, n408, n409, n410, n411, n412, n413,
         n414, n415, n416, n417, n418, n419, n420, n421, n422, n423, n424,
         n425, n426, n427, n428, n429, n430, n431, n432, n433, n434, n435,
         n436, n437, n438, n439, n440, n441, n442, n443, n444, n445, n446,
         n447, n448, n449, n450, n451, n452, n453, n454, n455, n456, n457,
         n458, n459, n460, n461, n462, n463, n464, n465, n466, n467, n468,
         n469, n470, n471, n472, n473, n474, n475, n476, n477, n478, n479,
         n480, n481, n482, n483, n484, n485, n486, n487, n488, n489, n490,
         n491, n492, n493, n494, n495, n496, n497, n498, n499, n500, n501,
         n502, n503, n504, n505, n506, n507, n508, n509, n510, n511, n512,
         n513, n514, n515, n516, n517, n518, n519, n520, n521, n522, n523,
         n524, n525, n526, n527, n528, n529, n530, n531, n532, n533, n534,
         n535, n536, n537, n538, n539, n540, n541, n542, n543, n544, n545,
         n546, n547, n548, n549, n550, n551, n552, n553, n554, n555, n556,
         n557, n558, n559, n560, n561, n562, n563, n564, n565, n566, n567,
         n568, n569, n570, n571, n572, n573, n574, n575, n576, n577, n578,
         n579, n580, n581, n582, n583, n584, n585, n586, n587, n588, n589,
         n590, n591, n592, n593, n594, n595, n596, n597, n598, n599, n600,
         n601, n602, n603, n604, n605, n606, n607, n608, n609, n610, n611,
         n612, n613, n614, n615, n616, n617, n618, n619, n620, n621, n622,
         n623, n624, n625, n626, n627, n628, n629, n630, n631, n632, n633,
         n634, n635, n636, n637, n638, n639, n640, n641, n642, n643, n644,
         n645, n646, n647, n648, n649, n650, n651, n652, n653, n654, n655,
         n656, n657, n658, n659, n660, n661, n662, n663, n664, n665, n666,
         n667, n668, n669, n670, n671, n672, n673, n674, n675, n676, n677,
         n678, n679, n680, n681, n682, n683, n684, n685, n686, n687, n688,
         n689, n690, n691, n692, n693, n694, n695, n696, n697, n698, n699,
         n700, n701, n702, n703, n704, n705, n706, n707, n708, n709, n710,
         n711, n712, n713, n714, n715, n716, n717, n718, n719, n720, n721,
         n722, n723, n724, n725, n726, n727, n728, n729, n730, n731, n732,
         n733;
  wire   [2:0] cur_state;
  wire   [4:0] cnt;
  wire   [3:0] number_of_carriages_ff;
  wire   [4:0] order_ptr;
  wire   [4:0] in_train_cnt;
  wire   [3:0] current_target_ff;
  wire   [4:0] stack_ptr;
  wire   [43:0] stack;
  wire   [43:0] desired_order_rf;

  DFFRHQXL stack_reg_10__0_ ( .D(n411), .CK(clk), .RN(n412), .Q(stack[0]) );
  DFFRHQXL cur_state_reg_2_ ( .D(n399), .CK(clk), .RN(n412), .Q(cur_state[2])
         );
  DFFRHQXL cur_state_reg_1_ ( .D(n397), .CK(clk), .RN(n412), .Q(cur_state[1])
         );
  DFFRHQXL number_of_carriages_ff_reg_0_ ( .D(n403), .CK(clk), .RN(n412), .Q(
        number_of_carriages_ff[0]) );
  DFFRHQXL number_of_carriages_ff_reg_1_ ( .D(n402), .CK(clk), .RN(n412), .Q(
        number_of_carriages_ff[1]) );
  DFFRHQXL number_of_carriages_ff_reg_2_ ( .D(n401), .CK(clk), .RN(n412), .Q(
        number_of_carriages_ff[2]) );
  DFFRHQXL number_of_carriages_ff_reg_3_ ( .D(n400), .CK(clk), .RN(n412), .Q(
        number_of_carriages_ff[3]) );
  DFFRHQXL cur_state_reg_0_ ( .D(n398), .CK(clk), .RN(n412), .Q(cur_state[0])
         );
  DFFRHQXL cnt_reg_1_ ( .D(n342), .CK(clk), .RN(n412), .Q(cnt[1]) );
  DFFRHQXL cnt_reg_2_ ( .D(n341), .CK(clk), .RN(n412), .Q(cnt[2]) );
  DFFRHQXL cnt_reg_3_ ( .D(n340), .CK(clk), .RN(n412), .Q(cnt[3]) );
  DFFRHQXL cnt_reg_4_ ( .D(n339), .CK(clk), .RN(n412), .Q(cnt[4]) );
  DFFRHQXL order_ptr_reg_1_ ( .D(n395), .CK(clk), .RN(n412), .Q(order_ptr[1])
         );
  DFFRHQXL order_ptr_reg_2_ ( .D(n394), .CK(clk), .RN(n412), .Q(order_ptr[2])
         );
  DFFRHQXL order_ptr_reg_3_ ( .D(n393), .CK(clk), .RN(n412), .Q(order_ptr[3])
         );
  DFFRHQXL order_ptr_reg_4_ ( .D(n392), .CK(clk), .RN(n412), .Q(order_ptr[4])
         );
  DFFRHQXL desired_order_rf_reg_10__0_ ( .D(n391), .CK(clk), .RN(n412), .Q(
        desired_order_rf[0]) );
  DFFRHQXL desired_order_rf_reg_10__1_ ( .D(n380), .CK(clk), .RN(n412), .Q(
        desired_order_rf[1]) );
  DFFRHQXL desired_order_rf_reg_10__2_ ( .D(n369), .CK(clk), .RN(n412), .Q(
        desired_order_rf[2]) );
  DFFRHQXL desired_order_rf_reg_10__3_ ( .D(n358), .CK(clk), .RN(n412), .Q(
        desired_order_rf[3]) );
  DFFRHQXL desired_order_rf_reg_0__0_ ( .D(n390), .CK(clk), .RN(n412), .Q(
        desired_order_rf[40]) );
  DFFRHQXL desired_order_rf_reg_0__1_ ( .D(n379), .CK(clk), .RN(n412), .Q(
        desired_order_rf[41]) );
  DFFRHQXL desired_order_rf_reg_0__2_ ( .D(n368), .CK(clk), .RN(n412), .Q(
        desired_order_rf[42]) );
  DFFRHQXL desired_order_rf_reg_0__3_ ( .D(n357), .CK(clk), .RN(n412), .Q(
        desired_order_rf[43]) );
  DFFRHQXL desired_order_rf_reg_1__0_ ( .D(n389), .CK(clk), .RN(n412), .Q(
        desired_order_rf[36]) );
  DFFRHQXL desired_order_rf_reg_1__1_ ( .D(n378), .CK(clk), .RN(n412), .Q(
        desired_order_rf[37]) );
  DFFRHQXL desired_order_rf_reg_1__2_ ( .D(n367), .CK(clk), .RN(n412), .Q(
        desired_order_rf[38]) );
  DFFRHQXL desired_order_rf_reg_1__3_ ( .D(n356), .CK(clk), .RN(n412), .Q(
        desired_order_rf[39]) );
  DFFRHQXL desired_order_rf_reg_2__0_ ( .D(n388), .CK(clk), .RN(n412), .Q(
        desired_order_rf[32]) );
  DFFRHQXL desired_order_rf_reg_2__1_ ( .D(n377), .CK(clk), .RN(n412), .Q(
        desired_order_rf[33]) );
  DFFRHQXL desired_order_rf_reg_2__2_ ( .D(n366), .CK(clk), .RN(n412), .Q(
        desired_order_rf[34]) );
  DFFRHQXL desired_order_rf_reg_2__3_ ( .D(n355), .CK(clk), .RN(n412), .Q(
        desired_order_rf[35]) );
  DFFRHQXL desired_order_rf_reg_3__0_ ( .D(n387), .CK(clk), .RN(n412), .Q(
        desired_order_rf[28]) );
  DFFRHQXL desired_order_rf_reg_3__1_ ( .D(n376), .CK(clk), .RN(n412), .Q(
        desired_order_rf[29]) );
  DFFRHQXL desired_order_rf_reg_3__2_ ( .D(n365), .CK(clk), .RN(rst_n), .Q(
        desired_order_rf[30]) );
  DFFRHQXL desired_order_rf_reg_3__3_ ( .D(n354), .CK(clk), .RN(n412), .Q(
        desired_order_rf[31]) );
  DFFRHQXL desired_order_rf_reg_4__0_ ( .D(n386), .CK(clk), .RN(n412), .Q(
        desired_order_rf[24]) );
  DFFRHQXL desired_order_rf_reg_4__1_ ( .D(n375), .CK(clk), .RN(n412), .Q(
        desired_order_rf[25]) );
  DFFRHQXL desired_order_rf_reg_4__2_ ( .D(n364), .CK(clk), .RN(n412), .Q(
        desired_order_rf[26]) );
  DFFRHQXL desired_order_rf_reg_4__3_ ( .D(n353), .CK(clk), .RN(n412), .Q(
        desired_order_rf[27]) );
  DFFRHQXL desired_order_rf_reg_5__0_ ( .D(n385), .CK(clk), .RN(n412), .Q(
        desired_order_rf[20]) );
  DFFRHQXL desired_order_rf_reg_5__1_ ( .D(n374), .CK(clk), .RN(n412), .Q(
        desired_order_rf[21]) );
  DFFRHQXL desired_order_rf_reg_5__2_ ( .D(n363), .CK(clk), .RN(n412), .Q(
        desired_order_rf[22]) );
  DFFRHQXL desired_order_rf_reg_5__3_ ( .D(n352), .CK(clk), .RN(n412), .Q(
        desired_order_rf[23]) );
  DFFRHQXL desired_order_rf_reg_6__0_ ( .D(n384), .CK(clk), .RN(n412), .Q(
        desired_order_rf[16]) );
  DFFRHQXL desired_order_rf_reg_6__1_ ( .D(n373), .CK(clk), .RN(n412), .Q(
        desired_order_rf[17]) );
  DFFRHQXL desired_order_rf_reg_6__2_ ( .D(n362), .CK(clk), .RN(n412), .Q(
        desired_order_rf[18]) );
  DFFRHQXL desired_order_rf_reg_6__3_ ( .D(n351), .CK(clk), .RN(n412), .Q(
        desired_order_rf[19]) );
  DFFRHQXL desired_order_rf_reg_7__0_ ( .D(n383), .CK(clk), .RN(n412), .Q(
        desired_order_rf[12]) );
  DFFRHQXL desired_order_rf_reg_7__1_ ( .D(n372), .CK(clk), .RN(n412), .Q(
        desired_order_rf[13]) );
  DFFRHQXL desired_order_rf_reg_7__2_ ( .D(n361), .CK(clk), .RN(n412), .Q(
        desired_order_rf[14]) );
  DFFRHQXL desired_order_rf_reg_7__3_ ( .D(n350), .CK(clk), .RN(n412), .Q(
        desired_order_rf[15]) );
  DFFRHQXL desired_order_rf_reg_8__0_ ( .D(n382), .CK(clk), .RN(n412), .Q(
        desired_order_rf[8]) );
  DFFRHQXL desired_order_rf_reg_8__1_ ( .D(n371), .CK(clk), .RN(n412), .Q(
        desired_order_rf[9]) );
  DFFRHQXL desired_order_rf_reg_8__2_ ( .D(n360), .CK(clk), .RN(n412), .Q(
        desired_order_rf[10]) );
  DFFRHQXL desired_order_rf_reg_8__3_ ( .D(n349), .CK(clk), .RN(n412), .Q(
        desired_order_rf[11]) );
  DFFRHQXL desired_order_rf_reg_9__0_ ( .D(n381), .CK(clk), .RN(n412), .Q(
        desired_order_rf[4]) );
  DFFRHQXL current_target_ff_reg_0_ ( .D(n347), .CK(clk), .RN(n412), .Q(
        current_target_ff[0]) );
  DFFRHQXL desired_order_rf_reg_9__1_ ( .D(n370), .CK(clk), .RN(n412), .Q(
        desired_order_rf[5]) );
  DFFRHQXL current_target_ff_reg_1_ ( .D(n346), .CK(clk), .RN(n412), .Q(
        current_target_ff[1]) );
  DFFRHQXL desired_order_rf_reg_9__2_ ( .D(n359), .CK(clk), .RN(n412), .Q(
        desired_order_rf[6]) );
  DFFRHQXL current_target_ff_reg_2_ ( .D(n345), .CK(clk), .RN(n412), .Q(
        current_target_ff[2]) );
  DFFRHQXL desired_order_rf_reg_9__3_ ( .D(n348), .CK(clk), .RN(n412), .Q(
        desired_order_rf[7]) );
  DFFRHQXL current_target_ff_reg_3_ ( .D(n344), .CK(clk), .RN(n412), .Q(
        current_target_ff[3]) );
  DFFRHQXL in_train_cnt_reg_0_ ( .D(n338), .CK(clk), .RN(n412), .Q(
        in_train_cnt[0]) );
  DFFRHQXL in_train_cnt_reg_1_ ( .D(n337), .CK(clk), .RN(n412), .Q(
        in_train_cnt[1]) );
  DFFRHQXL in_train_cnt_reg_2_ ( .D(n336), .CK(clk), .RN(n412), .Q(
        in_train_cnt[2]) );
  DFFRHQXL in_train_cnt_reg_3_ ( .D(n335), .CK(clk), .RN(n412), .Q(
        in_train_cnt[3]) );
  DFFRHQXL in_train_cnt_reg_4_ ( .D(n334), .CK(clk), .RN(n412), .Q(
        in_train_cnt[4]) );
  DFFRHQXL stack_ptr_reg_4_ ( .D(n410), .CK(clk), .RN(n412), .Q(stack_ptr[4])
         );
  DFFRHQXL stack_ptr_reg_0_ ( .D(n407), .CK(clk), .RN(n412), .Q(stack_ptr[0])
         );
  DFFRHQXL stack_ptr_reg_3_ ( .D(n406), .CK(clk), .RN(n412), .Q(stack_ptr[3])
         );
  DFFRHQXL stack_ptr_reg_2_ ( .D(n405), .CK(clk), .RN(n412), .Q(stack_ptr[2])
         );
  DFFRHQXL stack_ptr_reg_1_ ( .D(n404), .CK(clk), .RN(n412), .Q(stack_ptr[1])
         );
  DFFRHQXL stack_reg_9__0_ ( .D(n329), .CK(clk), .RN(n412), .Q(stack[4]) );
  DFFRHQXL stack_reg_9__3_ ( .D(n327), .CK(clk), .RN(n412), .Q(stack[7]) );
  DFFRHQXL stack_reg_9__2_ ( .D(n326), .CK(clk), .RN(n412), .Q(stack[6]) );
  DFFRHQXL stack_reg_9__1_ ( .D(n325), .CK(clk), .RN(n412), .Q(stack[5]) );
  DFFRHQXL stack_reg_8__0_ ( .D(n324), .CK(clk), .RN(n412), .Q(stack[8]) );
  DFFRHQXL stack_reg_8__3_ ( .D(n322), .CK(clk), .RN(n412), .Q(stack[11]) );
  DFFRHQXL stack_reg_8__2_ ( .D(n321), .CK(clk), .RN(n412), .Q(stack[10]) );
  DFFRHQXL stack_reg_8__1_ ( .D(n320), .CK(clk), .RN(n412), .Q(stack[9]) );
  DFFRHQXL stack_reg_4__0_ ( .D(n304), .CK(clk), .RN(n412), .Q(stack[24]) );
  DFFRHQXL stack_reg_4__3_ ( .D(n302), .CK(clk), .RN(n412), .Q(stack[27]) );
  DFFRHQXL stack_reg_4__2_ ( .D(n301), .CK(clk), .RN(rst_n), .Q(stack[26]) );
  DFFRHQXL stack_reg_4__1_ ( .D(n300), .CK(clk), .RN(rst_n), .Q(stack[25]) );
  DFFRHQXL stack_reg_6__0_ ( .D(n314), .CK(clk), .RN(rst_n), .Q(stack[16]) );
  DFFRHQXL stack_reg_6__3_ ( .D(n312), .CK(clk), .RN(rst_n), .Q(stack[19]) );
  DFFRHQXL stack_reg_6__2_ ( .D(n311), .CK(clk), .RN(n412), .Q(stack[18]) );
  DFFRHQXL stack_reg_6__1_ ( .D(n310), .CK(clk), .RN(n412), .Q(stack[17]) );
  DFFRHQXL stack_reg_10__3_ ( .D(n332), .CK(clk), .RN(n412), .Q(stack[3]) );
  DFFRHQXL stack_reg_10__2_ ( .D(n331), .CK(clk), .RN(n412), .Q(stack[2]) );
  DFFRHQXL stack_reg_10__1_ ( .D(n330), .CK(clk), .RN(n412), .Q(stack[1]) );
  DFFRHQXL stack_reg_2__0_ ( .D(n294), .CK(clk), .RN(n412), .Q(stack[32]) );
  DFFRHQXL stack_reg_2__3_ ( .D(n292), .CK(clk), .RN(n412), .Q(stack[35]) );
  DFFRHQXL stack_reg_2__2_ ( .D(n291), .CK(clk), .RN(n412), .Q(stack[34]) );
  DFFRHQXL stack_reg_2__1_ ( .D(n290), .CK(clk), .RN(n412), .Q(stack[33]) );
  DFFRHQXL stack_reg_7__0_ ( .D(n319), .CK(clk), .RN(n412), .Q(stack[12]) );
  DFFRHQXL stack_reg_7__3_ ( .D(n317), .CK(clk), .RN(n412), .Q(stack[15]) );
  DFFRHQXL stack_reg_7__2_ ( .D(n316), .CK(clk), .RN(n412), .Q(stack[14]) );
  DFFRHQXL stack_reg_7__1_ ( .D(n315), .CK(clk), .RN(n412), .Q(stack[13]) );
  DFFRHQXL stack_reg_3__0_ ( .D(n299), .CK(clk), .RN(rst_n), .Q(stack[28]) );
  DFFRHQXL stack_reg_3__3_ ( .D(n297), .CK(clk), .RN(n412), .Q(stack[31]) );
  DFFRHQXL stack_reg_3__2_ ( .D(n296), .CK(clk), .RN(n412), .Q(stack[30]) );
  DFFRHQXL stack_reg_3__1_ ( .D(n295), .CK(clk), .RN(rst_n), .Q(stack[29]) );
  DFFRHQXL stack_reg_5__0_ ( .D(n309), .CK(clk), .RN(n412), .Q(stack[20]) );
  DFFRHQXL stack_reg_5__3_ ( .D(n307), .CK(clk), .RN(n412), .Q(stack[23]) );
  DFFRHQXL stack_reg_5__2_ ( .D(n306), .CK(clk), .RN(n412), .Q(stack[22]) );
  DFFRHQXL stack_reg_5__1_ ( .D(n305), .CK(clk), .RN(n412), .Q(stack[21]) );
  DFFRHQXL stack_reg_1__0_ ( .D(n289), .CK(clk), .RN(n412), .Q(stack[36]) );
  DFFRHQXL stack_reg_1__3_ ( .D(n287), .CK(clk), .RN(rst_n), .Q(stack[39]) );
  DFFRHQXL stack_reg_1__2_ ( .D(n286), .CK(clk), .RN(n412), .Q(stack[38]) );
  DFFRHQXL stack_reg_1__1_ ( .D(n285), .CK(clk), .RN(n412), .Q(stack[37]) );
  DFFRHQXL stack_reg_0__0_ ( .D(n284), .CK(clk), .RN(n412), .Q(stack[40]) );
  DFFRHQXL stack_reg_0__3_ ( .D(n282), .CK(clk), .RN(n412), .Q(stack[43]) );
  DFFRHQXL stack_reg_0__2_ ( .D(n281), .CK(clk), .RN(n412), .Q(stack[42]) );
  DFFRHQXL stack_reg_0__1_ ( .D(n280), .CK(clk), .RN(n412), .Q(stack[41]) );
  JKFFSXL cnt_reg_0_ ( .J(n733), .K(n732), .CK(clk), .SN(n412), .Q(n731), .QN(
        cnt[0]) );
  JKFFSXL order_ptr_reg_0_ ( .J(n728), .K(n729), .CK(clk), .SN(n412), .Q(n730), 
        .QN(order_ptr[0]) );
  DFFRHQXL out_valid_reg ( .D(n409), .CK(clk), .RN(n412), .Q(out_valid) );
  DFFRHQXL result_reg ( .D(n408), .CK(clk), .RN(n412), .Q(result) );
  NOR2XL U415 ( .A(n611), .B(n610), .Y(n634) );
  NOR2XL U416 ( .A(n634), .B(n633), .Y(n645) );
  NOR2XL U417 ( .A(number_of_carriages_ff[0]), .B(number_of_carriages_ff[1]), 
        .Y(n425) );
  NOR2XL U418 ( .A(n533), .B(n589), .Y(n614) );
  NOR2XL U419 ( .A(n533), .B(n596), .Y(n624) );
  NOR2XL U420 ( .A(n659), .B(n487), .Y(n493) );
  NOR2XL U421 ( .A(order_ptr[2]), .B(n670), .Y(n478) );
  NOR2XL U422 ( .A(cnt[0]), .B(n557), .Y(n566) );
  NOR2XL U423 ( .A(n660), .B(n659), .Y(n657) );
  NOR2XL U424 ( .A(n661), .B(n729), .Y(n662) );
  NOR2XL U425 ( .A(n621), .B(n620), .Y(n619) );
  NOR2XL U426 ( .A(stack_ptr[4]), .B(n540), .Y(n585) );
  NOR2XL U427 ( .A(cur_state[0]), .B(cur_state[2]), .Y(n661) );
  NOR2XL U428 ( .A(n509), .B(n669), .Y(n511) );
  NOR2XL U429 ( .A(cur_state[2]), .B(cur_state[1]), .Y(n733) );
  NOR2X1 U430 ( .A(n538), .B(n579), .Y(n586) );
  NOR2X1 U431 ( .A(in_train_cnt[1]), .B(n579), .Y(n485) );
  NOR2X1 U432 ( .A(n512), .B(n541), .Y(n522) );
  OAI31XL U433 ( .A0(n596), .A1(stack_ptr[3]), .A2(stack_ptr[2]), .B0(n721), 
        .Y(n612) );
  NOR2X1 U434 ( .A(stack_ptr[0]), .B(n588), .Y(n613) );
  NOR2X1 U435 ( .A(cnt[2]), .B(n562), .Y(n576) );
  NOR2X1 U436 ( .A(n512), .B(n419), .Y(n492) );
  NOR2X1 U437 ( .A(n731), .B(n557), .Y(n571) );
  NOR2X1 U438 ( .A(n664), .B(order_ptr[1]), .Y(n509) );
  NOR2X1 U439 ( .A(n537), .B(n592), .Y(n588) );
  NOR2X1 U440 ( .A(cnt[4]), .B(n435), .Y(n555) );
  NOR2X1 U441 ( .A(cnt[0]), .B(n435), .Y(n414) );
  NOR2X1 U442 ( .A(n729), .B(n720), .Y(n490) );
  NOR2X1 U443 ( .A(n529), .B(stack_ptr[2]), .Y(n537) );
  NOR2X1 U444 ( .A(n729), .B(n733), .Y(n465) );
  NOR2X1 U445 ( .A(cnt[1]), .B(n568), .Y(n559) );
  NOR2X1 U446 ( .A(n530), .B(stack_ptr[0]), .Y(n621) );
  NOR2X1 U447 ( .A(cnt[2]), .B(n575), .Y(n565) );
  NOR2X1 U448 ( .A(n589), .B(stack_ptr[1]), .Y(n620) );
  NOR2X1 U449 ( .A(n533), .B(n531), .Y(n592) );
  NOR2X1 U450 ( .A(n568), .B(n575), .Y(n570) );
  NOR2X1 U451 ( .A(stack_ptr[2]), .B(n589), .Y(n615) );
  NOR2X1 U452 ( .A(stack_ptr[0]), .B(stack_ptr[1]), .Y(n531) );
  INVX2 U453 ( .A(n413), .Y(n412) );
  NAND2XL U454 ( .A(n732), .B(data[0]), .Y(n578) );
  NAND2XL U455 ( .A(n720), .B(in_valid), .Y(n553) );
  MXI2XL U456 ( .A(n632), .B(current_target_ff[3]), .S0(n631), .Y(n633) );
  NAND2XL U457 ( .A(n555), .B(n554), .Y(n557) );
  OAI211XL U458 ( .A0(in_train_cnt[1]), .A1(n651), .B0(in_train_cnt[0]), .C0(
        n649), .Y(n416) );
  NOR2BXL U459 ( .AN(n621), .B(n592), .Y(n622) );
  AND2XL U460 ( .A(n621), .B(n592), .Y(n623) );
  AND2XL U461 ( .A(n589), .B(n588), .Y(n616) );
  INVXL U462 ( .A(n620), .Y(n596) );
  NOR2X1 U463 ( .A(n650), .B(n649), .Y(n647) );
  INVXL U464 ( .A(n524), .Y(n526) );
  NOR3XL U465 ( .A(stack_ptr[3]), .B(stack_ptr[4]), .C(n579), .Y(n524) );
  OR2XL U466 ( .A(stack_ptr[4]), .B(n580), .Y(n721) );
  NAND2XL U467 ( .A(stack_ptr[1]), .B(n614), .Y(n538) );
  NOR2X1 U468 ( .A(n730), .B(order_ptr[3]), .Y(n474) );
  NOR2X1 U469 ( .A(order_ptr[3]), .B(order_ptr[0]), .Y(n475) );
  NOR2X1 U470 ( .A(n502), .B(n730), .Y(n476) );
  NOR2X1 U471 ( .A(order_ptr[0]), .B(n502), .Y(n477) );
  NOR2X1 U472 ( .A(n438), .B(n670), .Y(n469) );
  NOR2X1 U473 ( .A(n440), .B(n438), .Y(n468) );
  NOR2X1 U474 ( .A(n439), .B(n670), .Y(n471) );
  NOR2X1 U475 ( .A(n440), .B(n439), .Y(n470) );
  NAND2XL U476 ( .A(n576), .B(n731), .Y(n573) );
  AOI211XL U477 ( .A0(in_train_cnt[3]), .A1(n608), .B0(in_train_cnt[4]), .C0(
        n418), .Y(n419) );
  AOI21XL U478 ( .A0(n417), .A1(n416), .B0(n415), .Y(n418) );
  AOI22XL U479 ( .A0(in_train_cnt[1]), .A1(n651), .B0(in_train_cnt[2]), .B1(
        n659), .Y(n417) );
  OAI22XL U480 ( .A0(in_train_cnt[2]), .A1(n659), .B0(in_train_cnt[3]), .B1(
        n608), .Y(n415) );
  AOI2BB1XL U481 ( .A0N(n551), .A1N(n637), .B0(n425), .Y(n639) );
  INVXL U482 ( .A(n587), .Y(n630) );
  NOR2BXL U483 ( .AN(n619), .B(n626), .Y(n587) );
  NAND2XL U484 ( .A(n626), .B(n721), .Y(n628) );
  OAI211XL U485 ( .A0(n655), .A1(n654), .B0(n653), .C0(n652), .Y(n656) );
  OAI222XL U486 ( .A0(n630), .A1(n601), .B0(n628), .B1(n600), .C0(n626), .C1(
        n599), .Y(n655) );
  AND2XL U487 ( .A(n585), .B(n522), .Y(n515) );
  INVXL U488 ( .A(n722), .Y(n726) );
  AOI2BB1XL U489 ( .A0N(n579), .A1N(n721), .B0(n720), .Y(n722) );
  AOI31XL U490 ( .A0(n615), .A1(n524), .A2(n530), .B0(n720), .Y(n718) );
  INVXL U491 ( .A(n710), .Y(n711) );
  AOI21XL U492 ( .A0(n624), .A1(n524), .B0(n720), .Y(n710) );
  INVXL U493 ( .A(n714), .Y(n715) );
  AOI2BB1XL U494 ( .A0N(n534), .A1N(n526), .B0(n720), .Y(n714) );
  INVXL U495 ( .A(n706), .Y(n707) );
  AOI2BB1XL U496 ( .A0N(n538), .A1N(n526), .B0(n720), .Y(n706) );
  INVXL U497 ( .A(n716), .Y(n717) );
  AOI31XL U498 ( .A0(n621), .A1(n524), .A2(n533), .B0(n720), .Y(n716) );
  INVXL U499 ( .A(n699), .Y(n701) );
  INVXL U500 ( .A(n708), .Y(n709) );
  AOI31XL U501 ( .A0(n621), .A1(stack_ptr[2]), .A2(n524), .B0(n720), .Y(n708)
         );
  INVXL U502 ( .A(n712), .Y(n713) );
  AOI31XL U503 ( .A0(n531), .A1(stack_ptr[2]), .A2(n524), .B0(n720), .Y(n712)
         );
  INVXL U504 ( .A(n704), .Y(n705) );
  AOI21XL U505 ( .A0(n537), .A1(n515), .B0(n720), .Y(n704) );
  NAND2XL U506 ( .A(n700), .B(in_train_cnt[1]), .Y(n727) );
  NAND2XL U507 ( .A(n700), .B(in_train_cnt[2]), .Y(n725) );
  INVXL U508 ( .A(n702), .Y(n703) );
  NAND2XL U509 ( .A(n700), .B(in_train_cnt[3]), .Y(n724) );
  AOI31XL U510 ( .A0(n615), .A1(n515), .A2(n530), .B0(n720), .Y(n702) );
  INVXL U511 ( .A(n531), .Y(n529) );
  NAND2XL U512 ( .A(stack_ptr[1]), .B(n615), .Y(n534) );
  AOI21XL U513 ( .A0(n721), .A1(n728), .B0(n522), .Y(n535) );
  INVXL U514 ( .A(n512), .Y(n700) );
  OAI21XL U515 ( .A0(n540), .A1(n537), .B0(n580), .Y(n626) );
  INVXL U516 ( .A(n535), .Y(n523) );
  NAND2XL U517 ( .A(n523), .B(n729), .Y(n536) );
  NAND2XL U518 ( .A(n537), .B(n540), .Y(n580) );
  INVXL U519 ( .A(n536), .Y(n581) );
  AOI21XL U520 ( .A0(n700), .A1(n538), .B0(n535), .Y(n583) );
  INVXL U521 ( .A(n681), .Y(n694) );
  NOR2X1 U522 ( .A(n510), .B(n438), .Y(n466) );
  NOR2X1 U523 ( .A(n510), .B(n439), .Y(n467) );
  AOI31XL U524 ( .A0(cnt[0]), .A1(n576), .A2(n575), .B0(n720), .Y(n681) );
  INVXL U525 ( .A(n680), .Y(n693) );
  AOI2BB1XL U526 ( .A0N(cnt[1]), .A1N(n573), .B0(n720), .Y(n680) );
  INVXL U527 ( .A(n679), .Y(n692) );
  AOI21XL U528 ( .A0(n571), .A1(n570), .B0(n720), .Y(n679) );
  INVXL U529 ( .A(n678), .Y(n691) );
  AOI21XL U530 ( .A0(n566), .A1(n570), .B0(n720), .Y(n678) );
  INVXL U531 ( .A(n677), .Y(n690) );
  AOI21XL U532 ( .A0(n571), .A1(n559), .B0(n720), .Y(n677) );
  INVXL U533 ( .A(n676), .Y(n689) );
  AOI21XL U534 ( .A0(n566), .A1(n559), .B0(n720), .Y(n676) );
  INVXL U535 ( .A(n675), .Y(n688) );
  AOI21XL U536 ( .A0(n571), .A1(n565), .B0(n720), .Y(n675) );
  INVXL U537 ( .A(n674), .Y(n687) );
  AOI21XL U538 ( .A0(n566), .A1(n565), .B0(n720), .Y(n674) );
  INVXL U539 ( .A(n673), .Y(n686) );
  AOI31XL U540 ( .A0(n571), .A1(n568), .A2(n575), .B0(n720), .Y(n673) );
  INVXL U541 ( .A(n672), .Y(n685) );
  AOI31XL U542 ( .A0(n566), .A1(n568), .A2(n575), .B0(n720), .Y(n672) );
  NAND2XL U543 ( .A(n732), .B(data[3]), .Y(n695) );
  NAND2XL U544 ( .A(n732), .B(data[2]), .Y(n683) );
  NAND2XL U545 ( .A(n732), .B(data[1]), .Y(n682) );
  INVXL U546 ( .A(n671), .Y(n684) );
  AOI2BB1XL U547 ( .A0N(n575), .A1N(n573), .B0(n720), .Y(n671) );
  INVXL U548 ( .A(n729), .Y(n664) );
  AOI21XL U549 ( .A0(n729), .A1(n503), .B0(n490), .Y(n507) );
  OR2XL U550 ( .A(n440), .B(order_ptr[2]), .Y(n510) );
  INVXL U551 ( .A(n509), .Y(n670) );
  NAND2XL U552 ( .A(cnt[3]), .B(n555), .Y(n562) );
  OAI2BB1XL U553 ( .A0N(cur_state[0]), .A1N(n698), .B0(n733), .Y(n696) );
  INVXL U554 ( .A(n419), .Y(n541) );
  INVXL U555 ( .A(n492), .Y(n545) );
  AND2XL U556 ( .A(n665), .B(n661), .Y(n720) );
  NAND2XL U557 ( .A(n661), .B(cur_state[1]), .Y(n512) );
  MXI2XL U558 ( .A(n575), .B(cnt[1]), .S0(n639), .Y(n430) );
  NAND2XL U559 ( .A(cur_state[0]), .B(n733), .Y(n435) );
  OAI222XL U560 ( .A0(n630), .A1(n595), .B0(n628), .B1(n594), .C0(n626), .C1(
        n593), .Y(n660) );
  AOI31XL U561 ( .A0(n621), .A1(n515), .A2(n533), .B0(n720), .Y(n699) );
  NAND2XL U562 ( .A(n700), .B(in_train_cnt[0]), .Y(n723) );
  OAI2BB2XL U563 ( .B0(n668), .B1(n664), .A0N(out_valid), .A1N(n662), .Y(n409)
         );
  NOR3XL U564 ( .A(n666), .B(n665), .C(cur_state[2]), .Y(n729) );
  INVXL U565 ( .A(n490), .Y(n728) );
  INVXL U566 ( .A(n435), .Y(n732) );
  AOI2BB2XL U567 ( .B0(n727), .B1(n726), .A0N(n726), .A1N(stack[41]), .Y(n280)
         );
  AOI2BB2XL U568 ( .B0(n725), .B1(n726), .A0N(n726), .A1N(stack[42]), .Y(n281)
         );
  AOI2BB2XL U569 ( .B0(n724), .B1(n726), .A0N(n726), .A1N(stack[43]), .Y(n282)
         );
  AOI2BB2XL U570 ( .B0(n723), .B1(n726), .A0N(n726), .A1N(stack[40]), .Y(n284)
         );
  AOI2BB2XL U571 ( .B0(n727), .B1(n719), .A0N(n719), .A1N(stack[37]), .Y(n285)
         );
  AOI2BB2XL U572 ( .B0(n725), .B1(n719), .A0N(n719), .A1N(stack[38]), .Y(n286)
         );
  AOI2BB2XL U573 ( .B0(n724), .B1(n719), .A0N(n719), .A1N(stack[39]), .Y(n287)
         );
  OAI21XL U574 ( .A0(n723), .A1(n718), .B0(n520), .Y(n289) );
  AOI2BB2XL U575 ( .B0(n727), .B1(n711), .A0N(n711), .A1N(stack[21]), .Y(n305)
         );
  AOI2BB2XL U576 ( .B0(n725), .B1(n711), .A0N(n711), .A1N(stack[22]), .Y(n306)
         );
  AOI2BB2XL U577 ( .B0(n724), .B1(n711), .A0N(n711), .A1N(stack[23]), .Y(n307)
         );
  OAI21XL U578 ( .A0(n723), .A1(n710), .B0(n517), .Y(n309) );
  AOI2BB2XL U579 ( .B0(n727), .B1(n715), .A0N(n715), .A1N(stack[29]), .Y(n295)
         );
  AOI2BB2XL U580 ( .B0(n725), .B1(n715), .A0N(n715), .A1N(stack[30]), .Y(n296)
         );
  AOI2BB2XL U581 ( .B0(n724), .B1(n715), .A0N(n715), .A1N(stack[31]), .Y(n297)
         );
  OAI21XL U582 ( .A0(n723), .A1(n714), .B0(n527), .Y(n299) );
  AOI2BB2XL U583 ( .B0(n727), .B1(n707), .A0N(n707), .A1N(stack[13]), .Y(n315)
         );
  AOI2BB2XL U584 ( .B0(n725), .B1(n707), .A0N(n707), .A1N(stack[14]), .Y(n316)
         );
  AOI2BB2XL U585 ( .B0(n724), .B1(n707), .A0N(n707), .A1N(stack[15]), .Y(n317)
         );
  OAI21XL U586 ( .A0(n723), .A1(n706), .B0(n525), .Y(n319) );
  AOI2BB2XL U587 ( .B0(n727), .B1(n717), .A0N(n717), .A1N(stack[33]), .Y(n290)
         );
  AOI2BB2XL U588 ( .B0(n725), .B1(n717), .A0N(n717), .A1N(stack[34]), .Y(n291)
         );
  AOI2BB2XL U589 ( .B0(n724), .B1(n717), .A0N(n717), .A1N(stack[35]), .Y(n292)
         );
  OAI21XL U590 ( .A0(n723), .A1(n716), .B0(n521), .Y(n294) );
  AOI2BB2XL U591 ( .B0(n727), .B1(n701), .A0N(n701), .A1N(stack[1]), .Y(n330)
         );
  AOI2BB2XL U592 ( .B0(n725), .B1(n701), .A0N(n701), .A1N(stack[2]), .Y(n331)
         );
  AOI2BB2XL U593 ( .B0(n724), .B1(n701), .A0N(n701), .A1N(stack[3]), .Y(n332)
         );
  AOI2BB2XL U594 ( .B0(n727), .B1(n709), .A0N(n709), .A1N(stack[17]), .Y(n310)
         );
  AOI2BB2XL U595 ( .B0(n725), .B1(n709), .A0N(n709), .A1N(stack[18]), .Y(n311)
         );
  AOI2BB2XL U596 ( .B0(n724), .B1(n709), .A0N(n709), .A1N(stack[19]), .Y(n312)
         );
  OAI21XL U597 ( .A0(n723), .A1(n708), .B0(n519), .Y(n314) );
  AOI2BB2XL U598 ( .B0(n727), .B1(n713), .A0N(n713), .A1N(stack[25]), .Y(n300)
         );
  AOI2BB2XL U599 ( .B0(n725), .B1(n713), .A0N(n713), .A1N(stack[26]), .Y(n301)
         );
  AOI2BB2XL U600 ( .B0(n724), .B1(n713), .A0N(n713), .A1N(stack[27]), .Y(n302)
         );
  OAI21XL U601 ( .A0(n723), .A1(n712), .B0(n518), .Y(n304) );
  AOI2BB2XL U602 ( .B0(n727), .B1(n705), .A0N(n705), .A1N(stack[9]), .Y(n320)
         );
  AOI2BB2XL U603 ( .B0(n725), .B1(n705), .A0N(n705), .A1N(stack[10]), .Y(n321)
         );
  AOI2BB2XL U604 ( .B0(n724), .B1(n705), .A0N(n705), .A1N(stack[11]), .Y(n322)
         );
  AOI2BB2XL U605 ( .B0(n727), .B1(n703), .A0N(n703), .A1N(stack[5]), .Y(n325)
         );
  AOI2BB2XL U606 ( .B0(n725), .B1(n703), .A0N(n703), .A1N(stack[6]), .Y(n326)
         );
  AOI2BB2XL U607 ( .B0(n724), .B1(n703), .A0N(n703), .A1N(stack[7]), .Y(n327)
         );
  OAI222XL U608 ( .A0(n536), .A1(n529), .B0(n579), .B1(n619), .C0(n530), .C1(
        n528), .Y(n404) );
  AOI2BB1XL U609 ( .A0N(n589), .A1N(n664), .B0(n535), .Y(n528) );
  OAI222XL U610 ( .A0(n534), .A1(n579), .B0(n533), .B1(n532), .C0(n536), .C1(
        n588), .Y(n405) );
  OAI21XL U611 ( .A0(n583), .A1(n540), .B0(n539), .Y(n406) );
  AOI22XL U612 ( .A0(n581), .A1(n626), .B0(n586), .B1(n540), .Y(n539) );
  AOI32XL U613 ( .A0(n579), .A1(n589), .A2(n536), .B0(stack_ptr[0]), .B1(n523), 
        .Y(n407) );
  OAI2BB1XL U614 ( .A0N(n586), .A1N(n585), .B0(n584), .Y(n410) );
  OAI2BB1XL U615 ( .A0N(n583), .A1N(n582), .B0(stack_ptr[4]), .Y(n584) );
  AOI2BB2XL U616 ( .B0(n581), .B1(n580), .A0N(n579), .A1N(stack_ptr[3]), .Y(
        n582) );
  AOI2BB2XL U617 ( .B0(n695), .B1(n694), .A0N(n694), .A1N(desired_order_rf[7]), 
        .Y(n348) );
  AOI2BB2XL U618 ( .B0(n683), .B1(n694), .A0N(n694), .A1N(desired_order_rf[6]), 
        .Y(n359) );
  AOI2BB2XL U619 ( .B0(n682), .B1(n694), .A0N(n694), .A1N(desired_order_rf[5]), 
        .Y(n370) );
  OAI21XL U620 ( .A0(n578), .A1(n681), .B0(n577), .Y(n381) );
  AOI2BB2XL U621 ( .B0(n695), .B1(n693), .A0N(n693), .A1N(desired_order_rf[11]), .Y(n349) );
  AOI2BB2XL U622 ( .B0(n683), .B1(n693), .A0N(n693), .A1N(desired_order_rf[10]), .Y(n360) );
  AOI2BB2XL U623 ( .B0(n682), .B1(n693), .A0N(n693), .A1N(desired_order_rf[9]), 
        .Y(n371) );
  OAI21XL U624 ( .A0(n578), .A1(n680), .B0(n574), .Y(n382) );
  AOI2BB2XL U625 ( .B0(n695), .B1(n692), .A0N(n692), .A1N(desired_order_rf[15]), .Y(n350) );
  AOI2BB2XL U626 ( .B0(n683), .B1(n692), .A0N(n692), .A1N(desired_order_rf[14]), .Y(n361) );
  AOI2BB2XL U627 ( .B0(n682), .B1(n692), .A0N(n692), .A1N(desired_order_rf[13]), .Y(n372) );
  OAI21XL U628 ( .A0(n578), .A1(n679), .B0(n572), .Y(n383) );
  AOI2BB2XL U629 ( .B0(n695), .B1(n691), .A0N(n691), .A1N(desired_order_rf[19]), .Y(n351) );
  AOI2BB2XL U630 ( .B0(n683), .B1(n691), .A0N(n691), .A1N(desired_order_rf[18]), .Y(n362) );
  AOI2BB2XL U631 ( .B0(n682), .B1(n691), .A0N(n691), .A1N(desired_order_rf[17]), .Y(n373) );
  OAI21XL U632 ( .A0(n578), .A1(n678), .B0(n556), .Y(n384) );
  AOI2BB2XL U633 ( .B0(n695), .B1(n690), .A0N(n690), .A1N(desired_order_rf[23]), .Y(n352) );
  AOI2BB2XL U634 ( .B0(n683), .B1(n690), .A0N(n690), .A1N(desired_order_rf[22]), .Y(n363) );
  AOI2BB2XL U635 ( .B0(n682), .B1(n690), .A0N(n690), .A1N(desired_order_rf[21]), .Y(n374) );
  OAI21XL U636 ( .A0(n578), .A1(n677), .B0(n558), .Y(n385) );
  AOI2BB2XL U637 ( .B0(n695), .B1(n689), .A0N(n689), .A1N(desired_order_rf[27]), .Y(n353) );
  AOI2BB2XL U638 ( .B0(n683), .B1(n689), .A0N(n689), .A1N(desired_order_rf[26]), .Y(n364) );
  AOI2BB2XL U639 ( .B0(n682), .B1(n689), .A0N(n689), .A1N(desired_order_rf[25]), .Y(n375) );
  OAI21XL U640 ( .A0(n578), .A1(n676), .B0(n560), .Y(n386) );
  AOI2BB2XL U641 ( .B0(n695), .B1(n688), .A0N(n688), .A1N(desired_order_rf[31]), .Y(n354) );
  AOI2BB2XL U642 ( .B0(n683), .B1(n688), .A0N(n688), .A1N(desired_order_rf[30]), .Y(n365) );
  AOI2BB2XL U643 ( .B0(n682), .B1(n688), .A0N(n688), .A1N(desired_order_rf[29]), .Y(n376) );
  OAI21XL U644 ( .A0(n578), .A1(n675), .B0(n564), .Y(n387) );
  AOI2BB2XL U645 ( .B0(n695), .B1(n687), .A0N(n687), .A1N(desired_order_rf[35]), .Y(n355) );
  AOI2BB2XL U646 ( .B0(n683), .B1(n687), .A0N(n687), .A1N(desired_order_rf[34]), .Y(n366) );
  AOI2BB2XL U647 ( .B0(n682), .B1(n687), .A0N(n687), .A1N(desired_order_rf[33]), .Y(n377) );
  OAI21XL U648 ( .A0(n578), .A1(n674), .B0(n567), .Y(n388) );
  AOI2BB2XL U649 ( .B0(n695), .B1(n686), .A0N(n686), .A1N(desired_order_rf[39]), .Y(n356) );
  AOI2BB2XL U650 ( .B0(n683), .B1(n686), .A0N(n686), .A1N(desired_order_rf[38]), .Y(n367) );
  AOI2BB2XL U651 ( .B0(n682), .B1(n686), .A0N(n686), .A1N(desired_order_rf[37]), .Y(n378) );
  OAI21XL U652 ( .A0(n578), .A1(n673), .B0(n569), .Y(n389) );
  AOI2BB2XL U653 ( .B0(n695), .B1(n685), .A0N(n685), .A1N(desired_order_rf[43]), .Y(n357) );
  AOI2BB2XL U654 ( .B0(n683), .B1(n685), .A0N(n685), .A1N(desired_order_rf[42]), .Y(n368) );
  AOI2BB2XL U655 ( .B0(n682), .B1(n685), .A0N(n685), .A1N(desired_order_rf[41]), .Y(n379) );
  OAI21XL U656 ( .A0(n578), .A1(n672), .B0(n561), .Y(n390) );
  AOI2BB2XL U657 ( .B0(n695), .B1(n684), .A0N(n684), .A1N(desired_order_rf[3]), 
        .Y(n358) );
  AOI2BB2XL U658 ( .B0(n683), .B1(n684), .A0N(n684), .A1N(desired_order_rf[2]), 
        .Y(n369) );
  AOI2BB2XL U659 ( .B0(n682), .B1(n684), .A0N(n684), .A1N(desired_order_rf[1]), 
        .Y(n380) );
  OAI21XL U660 ( .A0(n578), .A1(n671), .B0(n563), .Y(n391) );
  OAI2BB2XL U661 ( .B0(n730), .B1(n670), .A0N(order_ptr[1]), .A1N(n669), .Y(
        n395) );
  OAI32XL U662 ( .A0(cnt[1]), .A1(n435), .A2(n731), .B0(n423), .B1(n575), .Y(
        n342) );
  NAND4XL U663 ( .A(n545), .B(n544), .C(n543), .D(n553), .Y(n398) );
  AOI32XL U664 ( .A0(n665), .A1(cur_state[2]), .A2(n541), .B0(cur_state[0]), 
        .B1(cur_state[2]), .Y(n544) );
  OAI22XL U665 ( .A0(n720), .A1(n549), .B0(n553), .B1(n548), .Y(n400) );
  INVXL U666 ( .A(data[3]), .Y(n548) );
  OAI22XL U667 ( .A0(n720), .A1(n547), .B0(n553), .B1(n546), .Y(n401) );
  INVXL U668 ( .A(data[2]), .Y(n546) );
  OAI22XL U669 ( .A0(n720), .A1(n551), .B0(n553), .B1(n550), .Y(n402) );
  INVXL U670 ( .A(data[1]), .Y(n550) );
  OAI22XL U671 ( .A0(n720), .A1(n637), .B0(n553), .B1(n552), .Y(n403) );
  OAI2BB1XL U672 ( .A0N(n665), .A1N(cur_state[0]), .B0(cur_state[2]), .Y(n431)
         );
  OAI2BB1XL U673 ( .A0N(n668), .A1N(n729), .B0(n667), .Y(n399) );
  OAI2BB1XL U674 ( .A0N(n666), .A1N(n665), .B0(cur_state[2]), .Y(n667) );
  INVXL U675 ( .A(n522), .Y(n579) );
  INVXL U676 ( .A(rst_n), .Y(n413) );
  INVXL U677 ( .A(n424), .Y(n427) );
  INVXL U678 ( .A(n718), .Y(n719) );
  OR3XL U679 ( .A(n503), .B(n664), .C(n502), .Y(n505) );
  INVXL U680 ( .A(data[0]), .Y(n552) );
  INVXL U681 ( .A(cur_state[0]), .Y(n666) );
  INVXL U682 ( .A(cur_state[1]), .Y(n665) );
  NOR2BXL U683 ( .AN(n733), .B(n414), .Y(n423) );
  INVXL U684 ( .A(cnt[1]), .Y(n575) );
  INVXL U685 ( .A(current_target_ff[3]), .Y(n608) );
  INVXL U686 ( .A(current_target_ff[1]), .Y(n651) );
  INVXL U687 ( .A(current_target_ff[2]), .Y(n659) );
  INVXL U688 ( .A(current_target_ff[0]), .Y(n649) );
  NAND2XL U689 ( .A(in_train_cnt[1]), .B(in_train_cnt[0]), .Y(n491) );
  INVXL U690 ( .A(in_train_cnt[0]), .Y(n434) );
  NAND2XL U691 ( .A(n522), .B(n434), .Y(n432) );
  NAND2XL U692 ( .A(n661), .B(n432), .Y(n486) );
  NAND2XL U693 ( .A(current_target_ff[1]), .B(current_target_ff[0]), .Y(n487)
         );
  AOI211XL U694 ( .A0(n659), .A1(n487), .B0(n493), .C0(n545), .Y(n420) );
  AOI221XL U695 ( .A0(n485), .A1(in_train_cnt[2]), .B0(n486), .B1(
        in_train_cnt[2]), .C0(n420), .Y(n421) );
  OAI31XL U696 ( .A0(in_train_cnt[2]), .A1(n579), .A2(n491), .B0(n421), .Y(
        n336) );
  INVXL U697 ( .A(cnt[2]), .Y(n568) );
  AOI21XL U698 ( .A0(n565), .A1(cnt[0]), .B0(n559), .Y(n422) );
  OAI22XL U699 ( .A0(n423), .A1(n568), .B0(n422), .B1(n435), .Y(n341) );
  INVXL U700 ( .A(number_of_carriages_ff[1]), .Y(n551) );
  INVXL U701 ( .A(number_of_carriages_ff[0]), .Y(n637) );
  AOI221XL U702 ( .A0(number_of_carriages_ff[0]), .A1(cnt[0]), .B0(n637), .B1(
        n731), .C0(cnt[4]), .Y(n429) );
  INVXL U703 ( .A(number_of_carriages_ff[2]), .Y(n547) );
  NAND2XL U704 ( .A(n547), .B(n425), .Y(n424) );
  NAND2XL U705 ( .A(number_of_carriages_ff[3]), .B(n424), .Y(n640) );
  AOI2BB1XL U706 ( .A0N(n547), .A1N(n425), .B0(n427), .Y(n635) );
  OAI22XL U707 ( .A0(n640), .A1(cnt[3]), .B0(cnt[2]), .B1(n635), .Y(n426) );
  AOI221XL U708 ( .A0(n640), .A1(cnt[3]), .B0(n635), .B1(cnt[2]), .C0(n426), 
        .Y(n428) );
  INVXL U709 ( .A(number_of_carriages_ff[3]), .Y(n549) );
  NAND2XL U710 ( .A(n427), .B(n549), .Y(n641) );
  NAND4XL U711 ( .A(n430), .B(n429), .C(n428), .D(n641), .Y(n542) );
  OAI211XL U712 ( .A0(n435), .A1(n542), .B0(n512), .C0(n431), .Y(n397) );
  AOI2BB1XL U713 ( .A0N(n545), .A1N(current_target_ff[0]), .B0(n720), .Y(n433)
         );
  OAI211XL U714 ( .A0(n661), .A1(n434), .B0(n433), .C0(n432), .Y(n338) );
  INVXL U715 ( .A(cnt[3]), .Y(n554) );
  NAND2XL U716 ( .A(n554), .B(n732), .Y(n697) );
  NAND2XL U717 ( .A(cnt[0]), .B(n570), .Y(n698) );
  NOR2BXL U718 ( .AN(n697), .B(n696), .Y(n437) );
  INVXL U719 ( .A(cnt[4]), .Y(n436) );
  OAI22XL U720 ( .A0(n437), .A1(n436), .B0(n562), .B1(n698), .Y(n339) );
  AOI22XL U721 ( .A0(current_target_ff[2]), .A1(n465), .B0(n732), .B1(
        desired_order_rf[42]), .Y(n448) );
  NAND2XL U722 ( .A(n729), .B(order_ptr[1]), .Y(n440) );
  INVXL U723 ( .A(n475), .Y(n439) );
  INVXL U724 ( .A(n474), .Y(n438) );
  AOI22XL U725 ( .A0(desired_order_rf[30]), .A1(n467), .B0(
        desired_order_rf[26]), .B1(n466), .Y(n447) );
  AOI22XL U726 ( .A0(desired_order_rf[18]), .A1(n469), .B0(n468), .B1(
        desired_order_rf[10]), .Y(n442) );
  AOI22XL U727 ( .A0(desired_order_rf[22]), .A1(n471), .B0(
        desired_order_rf[14]), .B1(n470), .Y(n441) );
  OAI2BB1XL U728 ( .A0N(n442), .A1N(n441), .B0(order_ptr[2]), .Y(n446) );
  AOI22XL U729 ( .A0(desired_order_rf[38]), .A1(n475), .B0(
        desired_order_rf[34]), .B1(n474), .Y(n444) );
  INVXL U730 ( .A(order_ptr[3]), .Y(n502) );
  AOI22XL U731 ( .A0(n477), .A1(desired_order_rf[6]), .B0(n476), .B1(
        desired_order_rf[2]), .Y(n443) );
  OAI2BB1XL U732 ( .A0N(n444), .A1N(n443), .B0(n478), .Y(n445) );
  NAND4XL U733 ( .A(n448), .B(n447), .C(n446), .D(n445), .Y(n345) );
  AOI22XL U734 ( .A0(current_target_ff[0]), .A1(n465), .B0(n732), .B1(
        desired_order_rf[40]), .Y(n456) );
  AOI22XL U735 ( .A0(desired_order_rf[28]), .A1(n467), .B0(
        desired_order_rf[24]), .B1(n466), .Y(n455) );
  AOI22XL U736 ( .A0(desired_order_rf[16]), .A1(n469), .B0(n468), .B1(
        desired_order_rf[8]), .Y(n450) );
  AOI22XL U737 ( .A0(desired_order_rf[20]), .A1(n471), .B0(
        desired_order_rf[12]), .B1(n470), .Y(n449) );
  OAI2BB1XL U738 ( .A0N(n450), .A1N(n449), .B0(order_ptr[2]), .Y(n454) );
  AOI22XL U739 ( .A0(desired_order_rf[36]), .A1(n475), .B0(
        desired_order_rf[32]), .B1(n474), .Y(n452) );
  AOI22XL U740 ( .A0(n477), .A1(desired_order_rf[4]), .B0(n476), .B1(
        desired_order_rf[0]), .Y(n451) );
  OAI2BB1XL U741 ( .A0N(n452), .A1N(n451), .B0(n478), .Y(n453) );
  NAND4XL U742 ( .A(n456), .B(n455), .C(n454), .D(n453), .Y(n347) );
  AOI22XL U743 ( .A0(current_target_ff[1]), .A1(n465), .B0(n732), .B1(
        desired_order_rf[41]), .Y(n464) );
  AOI22XL U744 ( .A0(desired_order_rf[29]), .A1(n467), .B0(
        desired_order_rf[25]), .B1(n466), .Y(n463) );
  AOI22XL U745 ( .A0(desired_order_rf[17]), .A1(n469), .B0(n468), .B1(
        desired_order_rf[9]), .Y(n458) );
  AOI22XL U746 ( .A0(desired_order_rf[21]), .A1(n471), .B0(
        desired_order_rf[13]), .B1(n470), .Y(n457) );
  OAI2BB1XL U747 ( .A0N(n458), .A1N(n457), .B0(order_ptr[2]), .Y(n462) );
  AOI22XL U748 ( .A0(desired_order_rf[37]), .A1(n475), .B0(
        desired_order_rf[33]), .B1(n474), .Y(n460) );
  AOI22XL U749 ( .A0(n477), .A1(desired_order_rf[5]), .B0(n476), .B1(
        desired_order_rf[1]), .Y(n459) );
  OAI2BB1XL U750 ( .A0N(n460), .A1N(n459), .B0(n478), .Y(n461) );
  NAND4XL U751 ( .A(n464), .B(n463), .C(n462), .D(n461), .Y(n346) );
  AOI22XL U752 ( .A0(current_target_ff[3]), .A1(n465), .B0(n732), .B1(
        desired_order_rf[43]), .Y(n484) );
  AOI22XL U753 ( .A0(desired_order_rf[31]), .A1(n467), .B0(
        desired_order_rf[27]), .B1(n466), .Y(n483) );
  AOI22XL U754 ( .A0(desired_order_rf[19]), .A1(n469), .B0(n468), .B1(
        desired_order_rf[11]), .Y(n473) );
  AOI22XL U755 ( .A0(desired_order_rf[23]), .A1(n471), .B0(
        desired_order_rf[15]), .B1(n470), .Y(n472) );
  OAI2BB1XL U756 ( .A0N(n473), .A1N(n472), .B0(order_ptr[2]), .Y(n482) );
  AOI22XL U757 ( .A0(desired_order_rf[39]), .A1(n475), .B0(
        desired_order_rf[35]), .B1(n474), .Y(n480) );
  AOI22XL U758 ( .A0(n477), .A1(desired_order_rf[7]), .B0(n476), .B1(
        desired_order_rf[3]), .Y(n479) );
  OAI2BB1XL U759 ( .A0N(n480), .A1N(n479), .B0(n478), .Y(n481) );
  NAND4XL U760 ( .A(n484), .B(n483), .C(n482), .D(n481), .Y(n344) );
  AOI22XL U761 ( .A0(in_train_cnt[1]), .A1(n486), .B0(in_train_cnt[0]), .B1(
        n485), .Y(n489) );
  OAI211XL U762 ( .A0(current_target_ff[1]), .A1(current_target_ff[0]), .B0(
        n492), .C0(n487), .Y(n488) );
  NAND2XL U763 ( .A(n489), .B(n488), .Y(n337) );
  NAND3XL U764 ( .A(order_ptr[1]), .B(order_ptr[2]), .C(order_ptr[0]), .Y(n503) );
  NAND2XL U765 ( .A(n729), .B(n502), .Y(n506) );
  OAI22XL U766 ( .A0(n507), .A1(n502), .B0(n506), .B1(n503), .Y(n393) );
  NOR2BXL U767 ( .AN(in_train_cnt[2]), .B(n491), .Y(n494) );
  NAND2XL U768 ( .A(n522), .B(n494), .Y(n497) );
  NAND2XL U769 ( .A(current_target_ff[3]), .B(n493), .Y(n501) );
  OAI211XL U770 ( .A0(current_target_ff[3]), .A1(n493), .B0(n492), .C0(n501), 
        .Y(n496) );
  OAI21XL U771 ( .A0(n494), .A1(n579), .B0(n661), .Y(n499) );
  NAND2XL U772 ( .A(in_train_cnt[3]), .B(n499), .Y(n495) );
  OAI211XL U773 ( .A0(in_train_cnt[3]), .A1(n497), .B0(n496), .C0(n495), .Y(
        n335) );
  INVXL U774 ( .A(n497), .Y(n498) );
  AOI22XL U775 ( .A0(in_train_cnt[4]), .A1(n499), .B0(in_train_cnt[3]), .B1(
        n498), .Y(n500) );
  OAI21XL U776 ( .A0(n545), .A1(n501), .B0(n500), .Y(n334) );
  INVXL U777 ( .A(order_ptr[4]), .Y(n504) );
  AOI32XL U778 ( .A0(n507), .A1(order_ptr[4]), .A2(n506), .B0(n505), .B1(n504), 
        .Y(n392) );
  NAND2XL U779 ( .A(n729), .B(n730), .Y(n508) );
  NAND2XL U780 ( .A(n728), .B(n508), .Y(n669) );
  INVXL U781 ( .A(order_ptr[2]), .Y(n636) );
  OAI22XL U782 ( .A0(n511), .A1(n636), .B0(n730), .B1(n510), .Y(n394) );
  INVXL U783 ( .A(stack_ptr[3]), .Y(n540) );
  NAND2XL U784 ( .A(n704), .B(stack[8]), .Y(n513) );
  OAI21XL U785 ( .A0(n723), .A1(n704), .B0(n513), .Y(n324) );
  INVXL U786 ( .A(stack_ptr[0]), .Y(n589) );
  INVXL U787 ( .A(stack_ptr[1]), .Y(n530) );
  NAND2XL U788 ( .A(n702), .B(stack[4]), .Y(n514) );
  OAI21XL U789 ( .A0(n723), .A1(n702), .B0(n514), .Y(n329) );
  INVXL U790 ( .A(stack_ptr[2]), .Y(n533) );
  NAND2XL U791 ( .A(n699), .B(stack[0]), .Y(n516) );
  OAI21XL U792 ( .A0(n723), .A1(n699), .B0(n516), .Y(n411) );
  NAND2XL U793 ( .A(n710), .B(stack[20]), .Y(n517) );
  NAND2XL U794 ( .A(n712), .B(stack[24]), .Y(n518) );
  NAND2XL U795 ( .A(n708), .B(stack[16]), .Y(n519) );
  NAND2XL U796 ( .A(n718), .B(stack[36]), .Y(n520) );
  NAND2XL U797 ( .A(n716), .B(stack[32]), .Y(n521) );
  NAND2XL U798 ( .A(n706), .B(stack[12]), .Y(n525) );
  NAND2XL U799 ( .A(n714), .B(stack[28]), .Y(n527) );
  AOI221XL U800 ( .A0(n530), .A1(n700), .B0(n589), .B1(n700), .C0(n535), .Y(
        n532) );
  NAND2XL U801 ( .A(n732), .B(n542), .Y(n543) );
  NAND2XL U802 ( .A(n678), .B(desired_order_rf[16]), .Y(n556) );
  NAND2XL U803 ( .A(n677), .B(desired_order_rf[20]), .Y(n558) );
  NAND2XL U804 ( .A(n676), .B(desired_order_rf[24]), .Y(n560) );
  NAND2XL U805 ( .A(n672), .B(desired_order_rf[40]), .Y(n561) );
  NAND2XL U806 ( .A(n671), .B(desired_order_rf[0]), .Y(n563) );
  NAND2XL U807 ( .A(n675), .B(desired_order_rf[28]), .Y(n564) );
  NAND2XL U808 ( .A(n674), .B(desired_order_rf[32]), .Y(n567) );
  NAND2XL U809 ( .A(n673), .B(desired_order_rf[36]), .Y(n569) );
  NAND2XL U810 ( .A(n679), .B(desired_order_rf[12]), .Y(n572) );
  NAND2XL U811 ( .A(n680), .B(desired_order_rf[8]), .Y(n574) );
  NAND2XL U812 ( .A(n681), .B(desired_order_rf[4]), .Y(n577) );
  AOI22XL U813 ( .A0(stack[18]), .A1(n614), .B0(stack[14]), .B1(n613), .Y(n591) );
  AOI22XL U814 ( .A0(stack[30]), .A1(n616), .B0(n615), .B1(stack[34]), .Y(n590) );
  AND2XL U815 ( .A(n591), .B(n590), .Y(n595) );
  AOI222XL U816 ( .A0(n621), .A1(stack[6]), .B0(n620), .B1(stack[10]), .C0(
        n619), .C1(stack[2]), .Y(n594) );
  AOI222XL U817 ( .A0(stack[26]), .A1(n624), .B0(stack[22]), .B1(n623), .C0(
        stack[38]), .C1(n622), .Y(n593) );
  NAND2XL U818 ( .A(stack[42]), .B(n612), .Y(n658) );
  AOI22XL U819 ( .A0(n614), .A1(stack[17]), .B0(n613), .B1(stack[13]), .Y(n598) );
  AOI22XL U820 ( .A0(n616), .A1(stack[29]), .B0(n615), .B1(stack[33]), .Y(n597) );
  AND2XL U821 ( .A(n598), .B(n597), .Y(n601) );
  AOI222XL U822 ( .A0(n621), .A1(stack[5]), .B0(n620), .B1(stack[9]), .C0(n619), .C1(stack[1]), .Y(n600) );
  AOI222XL U823 ( .A0(n624), .A1(stack[25]), .B0(n623), .B1(stack[21]), .C0(
        n622), .C1(stack[37]), .Y(n599) );
  OAI2BB1XL U824 ( .A0N(stack[41]), .A1N(n612), .B0(current_target_ff[1]), .Y(
        n654) );
  AOI22XL U825 ( .A0(n614), .A1(stack[16]), .B0(n613), .B1(stack[12]), .Y(n603) );
  AOI22XL U826 ( .A0(n616), .A1(stack[28]), .B0(n615), .B1(stack[32]), .Y(n602) );
  AND2XL U827 ( .A(n603), .B(n602), .Y(n606) );
  AOI222XL U828 ( .A0(n621), .A1(stack[4]), .B0(n620), .B1(stack[8]), .C0(n619), .C1(stack[0]), .Y(n605) );
  AOI222XL U829 ( .A0(n624), .A1(stack[24]), .B0(n623), .B1(stack[20]), .C0(
        n622), .C1(stack[36]), .Y(n604) );
  OAI222XL U830 ( .A0(n630), .A1(n606), .B0(n628), .B1(n605), .C0(n626), .C1(
        n604), .Y(n650) );
  NAND2XL U831 ( .A(stack[40]), .B(n612), .Y(n648) );
  INVXL U832 ( .A(n612), .Y(n611) );
  AOI22XL U833 ( .A0(stack[40]), .A1(n649), .B0(stack[41]), .B1(n651), .Y(n607) );
  OAI2BB1XL U834 ( .A0N(stack[43]), .A1N(n608), .B0(n607), .Y(n609) );
  OAI22XL U835 ( .A0(stack[42]), .A1(n609), .B0(n659), .B1(n609), .Y(n610) );
  OAI2BB1XL U836 ( .A0N(stack[43]), .A1N(n612), .B0(current_target_ff[3]), .Y(
        n632) );
  AOI22XL U837 ( .A0(n614), .A1(stack[19]), .B0(n613), .B1(stack[15]), .Y(n618) );
  AOI22XL U838 ( .A0(n616), .A1(stack[31]), .B0(n615), .B1(stack[35]), .Y(n617) );
  AND2XL U839 ( .A(n618), .B(n617), .Y(n629) );
  AOI222XL U840 ( .A0(n621), .A1(stack[7]), .B0(n620), .B1(stack[11]), .C0(
        n619), .C1(stack[3]), .Y(n627) );
  AOI222XL U841 ( .A0(n624), .A1(stack[27]), .B0(n623), .B1(stack[23]), .C0(
        n622), .C1(stack[39]), .Y(n625) );
  OAI222XL U842 ( .A0(n630), .A1(n629), .B0(n628), .B1(n627), .C0(n626), .C1(
        n625), .Y(n631) );
  MXI2XL U843 ( .A(n636), .B(order_ptr[2]), .S0(n635), .Y(n644) );
  AOI221XL U844 ( .A0(number_of_carriages_ff[0]), .A1(order_ptr[0]), .B0(n637), 
        .B1(n730), .C0(order_ptr[4]), .Y(n643) );
  OAI22XL U845 ( .A0(order_ptr[3]), .A1(n640), .B0(order_ptr[1]), .B1(n639), 
        .Y(n638) );
  AOI221XL U846 ( .A0(n640), .A1(order_ptr[3]), .B0(order_ptr[1]), .B1(n639), 
        .C0(n638), .Y(n642) );
  NAND4XL U847 ( .A(n644), .B(n643), .C(n642), .D(n641), .Y(n663) );
  NAND2XL U848 ( .A(n645), .B(n663), .Y(n646) );
  AOI221XL U849 ( .A0(n650), .A1(n649), .B0(n648), .B1(n647), .C0(n646), .Y(
        n653) );
  NAND2XL U850 ( .A(n655), .B(n651), .Y(n652) );
  AOI221XL U851 ( .A0(n660), .A1(n659), .B0(n658), .B1(n657), .C0(n656), .Y(
        n668) );
  OAI2BB2XL U852 ( .B0(n664), .B1(n663), .A0N(n662), .A1N(result), .Y(n408) );
  OAI2BB2XL U853 ( .B0(n698), .B1(n697), .A0N(cnt[3]), .A1N(n696), .Y(n340) );
endmodule

