.output	Wave64	;name for output file.
.header	WaveHdr64.rel	;name of file containing header block.
.vlir
.ramsect	$1000
.psect	$1800

WaveVars.rel		;jump table equates.
WaveInit64.rel	;init code and resident routines.
Wave2Init64.rel	;init code and resident routines.
RamSect.rel		;resident ramsect variables.

.mod	1
.psect	MainTable
Main64.rel		;jump tables and routines.
LowLvl64.rel		;resident routines.

.mod	2
.psect	ModBase
BrowseA64.rel	;web browser.
BrowseB64.rel
BrowseC64.rel
BrowseRam.rel

.mod	3
.psect	ModBase
AscTermA64.rel	;ANSI/VT100 terminal
AscTermB64.rel
VT10064.rel
AscTermC64.rel

.mod	5
.psect	ExtTable
ExtModA64.rel	;file requestors.
SelDesDir64.rel
ExtModBa64.rel	;message DBs and messages.
ExtModBb64.rel	;message DBs and messages.
ExtModCa64.rel	;ISP and BBS directory routines.
ExtModCb64.rel	;ISP and BBS directory routines.

.mod	6
.psect	COMM_BASE
SLDriver64.rel
PPPBank0.rel

;.mod	7
;.psect	$8000
;DB1Box64.rel
