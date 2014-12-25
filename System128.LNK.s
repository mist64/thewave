.output	System128	;name for output file.
.header	SysHdr128.rel	;name of file containing header block.
.vlir
.ramsect	$1000
.psect	$1800

WaveVars.rel		;jump table equates.
RamSect.rel		;resident ramsect variables.

.mod	1
.psect	LPrgBase
Prg2Jump.rel
PPP1Link.rel
PPP2Link.rel
TCPCode.rel
XYModem128.rel
HTTP128.rel
Telnet.rel

.mod	2
.psect	DOSBase
Dos1Stuff.rel
KrnlStuff128.rel

.mod	3
.psect	ParseHTML
Parse1HTM128.rel	;HTML parser routines.
Parse2HTM128.rel
Parse3HTM128.rel
Parse4HTM128.rel
UpperRam.rel		;ramsect variables for the parser.
