# === & ==
- == , 'x','z' leads to 'x'
- ===, compare bit one bit by one bit.

# IP
- Soft, RTL
- Firm, Netlist format, performance opt under specific fabric. Need not synthesizing.
- Hard macro, hardware, have moving rotation flipping feature.Has pathways wiring.

# mem
- OE > CS > R,W, HIGH AS SELECT
- CS L, data output remains stable.
- After writing in data to DI, the data would also get driven onto the output port DO.
- One cycle delay in memory compare to register
