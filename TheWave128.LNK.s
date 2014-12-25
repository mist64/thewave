.output	Wave128	;name for output file.
.header	WaveHdr128.rel	;name of file containing header block.
.vlir
.ramsect	$1000
.psect	$1800

WaveVars.rel		;jump table equates.
WaveInit128.rel	;init code and resident routines.
Wave2Init128.rel	;init code and resident routines.
RamSect.rel		;resident ramsect variables.

.mod	1
.psect	MainTable
Main128.rel		;jump tables and routines.
LowLvl128.rel		;resident routines.

.mod	2
.psect	ModBase
BrowseA128.rel	;web browser.
BrowseB128.rel
BrowseC128.rel
BrowseRam.rel

.mod	3
.psect	ModBase
AscTermA128.rel	;ANSI/VT100 terminal
AscTermB128.rel
VT100128.rel
AscTermC128.rel

.mod	5
.psect	ExtTable
ExtModA128.rel	;file requestors.
SelDesDir128.rel
ExtModBa128.rel	;message DBs and messages.
ExtModBb128.rel	;message DBs and messages.
ExtModCa128.rel	;ISP and BBS directory routines.
ExtModCb128.rel	;ISP and BBS directory routines.

.mod	6
.psect	COMM_BASE
SLDriver128.rel
PPPBank0.rel

