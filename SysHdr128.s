;************************************************************************
;
;		SysHdr128
;
;************************************************************************

	.header		;start of header section

	.word	0	;first two bytes are always zero
	.byte	3		;width in bytes
	.byte	21	;and height in scanlines of:


	.byte	$80 | 3	;Commodore file type, with bit 7 set.
	.byte	4	;Geos file type
	.byte	1	;Geos file structure type
	.word	$1800	;start address of program (where to load to)
	.word	$03ff	;usually end address, but only needed for
				;desk accessories.
	.word	$1800	;init address of program (where to JMP to)

	.byte	"WaveSys128  ",VERSLETTER,VERSMAJOR,".",VERSMINOR,0,0,0,$c0
			;permanent filename: 12 characters,
			;followed by 4 character version number,
			;followed by 3 zeroes,
			;followed by 40/80 column flag.

	.byte	"Maurice Randall    ",0
			;twenty character author name

	;end of header section which is checked for accuracy
	.block	160-117	;skip 43 bytes...
	.byte	"Telecommunications For Wheels 128."

	.endh
