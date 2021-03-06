#include "../common/config.h"
#include "../common/ctrycodes.h"

/*
 * Definitions for length of text, data and bss
 * of the separate modules.
 *
 * Length of BIOS text segment is different due to some extra
 * code for ALT-scancode mappings.
 *
 * Length of DESKTOP text segment is different due to some
 * differences in fmt_date() and fmt_time() which build
 * a language-specific version of the file date+time
 */

#if TOSVERSION == 0x306

/*
 * length of BIOS text segment of the US version,
 * which does not have any extra code
 */
#define BTLEN_US    $0000641C
#define DTLEN_US    $0000FBCC


#if OS_COUNTRY == CTRY_US
#define BIOSTLEN    BTLEN_US
#define DESKTLEN    DTLEN_US
#define DESKDLEN    $00000982
#define GLUELEN     $00007492
#endif

#if (OS_COUNTRY == CTRY_DE) | (OS_COUNTRY == CTRY_SG)
#define BIOSTLEN    BTLEN_US+$5A
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009DE
#define GLUELEN     $00007504
#endif

#if (OS_COUNTRY == CTRY_FR) | (OS_COUNTRY == CTRY_SF)
#define BIOSTLEN    BTLEN_US+$78
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009FA
#define GLUELEN     $00007788
#endif

#if OS_COUNTRY == CTRY_UK
#define BIOSTLEN    BTLEN_US
#define DESKTLEN    DTLEN_US
#define DESKDLEN    $00000982
#define GLUELEN     $00007492
#endif

#if OS_COUNTRY == CTRY_ES
#define BIOSTLEN    BTLEN_US+$86
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009C4
#define GLUELEN     $00007730
#endif

#if OS_COUNTRY == CTRY_IT
#define BIOSTLEN    BTLEN_US+$68
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009B6
#define GLUELEN     $000075C4
#endif

#if OS_COUNTRY == CTRY_SV
#define BIOSTLEN    BTLEN_US+$78
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $0000095E
#define GLUELEN     $00007658
#endif

#if OS_COUNTRY == CTRY_PL
#if BINEXACT
#undef RAMVERSION
#define RAMVERSION 1
#endif
#define BIOSTLEN    BTLEN_US+$5A
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009DE
#define GLUELEN     $00007504
#endif


/*
 * these are identical in all language versions
 */
#define BIOSDLEN    $000009D8
#define VDITLEN     $0000D06E
#define VDIDLEN     $00006EFA
#define BDOSTLEN    $000062AC
#define BDOSDLEN    $0000039E
#define AESTLEN     $0000CCD6
#define AESDLEN     $000006D8

#endif /* TOSVERSION == 0x306 */


#if TOSVERSION == 0x206

#define BTLEN_US    $0000603A
#define DTLEN_US    $0000FBCC

#if OS_COUNTRY == CTRY_US
#define BIOSTLEN    BTLEN_US
#define DESKTLEN    DTLEN_US
#define DESKDLEN    $00000982
#define GLUELEN     $00007492
#endif

#if (OS_COUNTRY == CTRY_DE) | (OS_COUNTRY == CTRY_SG)
#define BIOSTLEN    BTLEN_US+$5A
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009DE
#define GLUELEN     $00007504
#endif

#if (OS_COUNTRY == CTRY_FR) | (OS_COUNTRY == CTRY_SF)
#define BIOSTLEN    BTLEN_US+$78
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009FA
#define GLUELEN     $00007788
#endif

#if OS_COUNTRY == CTRY_UK
#define BIOSTLEN    BTLEN_US
#define DESKTLEN    DTLEN_US
#define DESKDLEN    $00000982
#define GLUELEN     $00007492
#endif

#if OS_COUNTRY == CTRY_ES
#define BIOSTLEN    BTLEN_US+$86
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009C4
#define GLUELEN     $00007730
#endif

#if OS_COUNTRY == CTRY_IT
#define BIOSTLEN    BTLEN_US+$68
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009B6
#define GLUELEN     $000075C4
#endif

#if OS_COUNTRY == CTRY_SV
#define BIOSTLEN    BTLEN_US+$78
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $0000095E
#define GLUELEN     $00007658
#endif

/*
 * these are identical in all language versions
 */
#define BIOSDLEN    $00000888
#define VDITLEN     $0000999A
#define VDIDLEN     $00002846
#define BDOSTLEN    $000062FC
#define BDOSDLEN    $0000039E
#define AESTLEN     $0000CCD6
#define AESDLEN     $000006D8

#endif /* TOSVERSION == 0x206 */


#if TOSVERSION == 0x208

#define BTLEN_US    $00005FEA
#define DTLEN_US    $0000FBCC

#if OS_COUNTRY == CTRY_US
#define BIOSTLEN    BTLEN_US
#define DESKTLEN    DTLEN_US
#define DESKDLEN    $00000982
#define GLUELEN     $00007492
#endif

#if OS_COUNTRY == CTRY_DE
#define BIOSTLEN    BTLEN_US+$5A
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009DE
#define GLUELEN     $00007504
#endif

#if OS_COUNTRY == CTRY_FR
#define BIOSTLEN    BTLEN_US+$78
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009FA
#define GLUELEN     $00007788
#endif

#if OS_COUNTRY == CTRY_UK
#define BIOSTLEN    BTLEN_US
#define DESKTLEN    DTLEN_US
#define DESKDLEN    $00000982
#define GLUELEN     $00007492
#endif

#if OS_COUNTRY == CTRY_ES
#define BIOSTLEN    BTLEN_US+$86
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009c4
#define GLUELEN     $00007730
#endif

#if OS_COUNTRY == CTRY_IT
#define BIOSTLEN    BTLEN_US+$68
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $000009B6
#define GLUELEN     $000075C4
#endif

#if OS_COUNTRY == CTRY_SV
#define BIOSTLEN    BTLEN_US+$78
#define DESKTLEN    DTLEN_US-$2A
#define DESKDLEN    $0000095E
#define GLUELEN     $00007658
#endif

/*
 * these are identical in all language versions
 */
#define BIOSDLEN    $00000888
#define VDITLEN     $0000999A
#define VDIDLEN     $00002846
#define BDOSTLEN    $000062FC
#define BDOSDLEN    $0000039E
#define AESTLEN     $0000CCD6
#define AESDLEN     $000006D8

#endif /* TOSVERSION == 0x208 */


#ifndef BIOSTBASE
#if RAMVERSION
#define BIOSTBASE   $00380000
#else
#define BIOSTBASE   $00E00000
#endif
#endif


/*
 * now calculate addresses from above
 * The order of all TOS versions is BIOS, VDI, GEMDOS, AES, DESK (+ glued resource files)
 */
#define VDITBASE  BIOSTBASE+BIOSTLEN
#define BDOSTBASE VDITBASE+VDITLEN
#define AESTBASE  BDOSTBASE+BDOSTLEN
#define DESKTBASE AESTBASE+AESTLEN
#define ETEXT     DESKTBASE+DESKTLEN

#define BIOSDBASE ETEXT
#define VDIDBASE  BIOSDBASE+BIOSDLEN
#define BDOSDBASE VDIDBASE+VDIDLEN
#define AESDBASE  BDOSDBASE+BDOSDLEN
#define DESKDBASE AESDBASE+AESDLEN
#define EDATA     DESKDBASE+DESKDLEN+GLUELEN

#ifdef __MAKEFILE__

/*
 * the output of this is fed through bc
 */
ibase=16
obase=10

bios_tbase=BIOSTBASE
bios_tlen=BIOSTLEN
bios_dbase=BIOSDBASE
bios_dlen=BIOSDLEN
vdi_tbase=VDITBASE
vdi_tlen=VDITLEN
vdi_dbase=VDIDBASE
vdi_dlen=VDIDLEN
bdos_tbase=BDOSTBASE
bdos_tlen=BDOSTLEN
bdos_dbase=BDOSDBASE
bdos_dlen=BDOSDLEN
aes_tbase=AESTBASE
aes_tlen=AESTLEN
aes_dbase=AESDBASE
aes_dlen=AESDLEN
desk_tbase=DESKTBASE
desk_tlen=DESKTLEN
desk_dbase=DESKDBASE
desk_dlen=DESKDLEN

rombase=BIOSTBASE

print "bios_tbase=", bios_tbase, "\n"
print "bios_tlen=", bios_tlen, "\n"
print "bios_dbase=", bios_dbase, "\n"
print "bios_dlen=", bios_dlen, "\n"
print "vdi_tbase=", vdi_tbase, "\n"
print "vdi_tlen=", vdi_tlen, "\n"
print "vdi_dbase=", vdi_dbase, "\n"
print "vdi_dlen=", vdi_dlen, "\n"
print "bdos_tbase=", bdos_tbase, "\n"
print "bdos_tlen=", bdos_tlen, "\n"
print "bdos_dbase=", bdos_dbase, "\n"
print "bdos_dlen=", bdos_dlen, "\n"
print "aes_tbase=", aes_tbase, "\n"
print "aes_tlen=", aes_tlen, "\n"
print "aes_dbase=", aes_dbase, "\n"
print "aes_dlen=", aes_dlen, "\n"
print "desk_tbase=", desk_tbase, "\n"
print "desk_tlen=", desk_tlen, "\n"
print "desk_dbase=", desk_dbase, "\n"
print "desk_dlen=", desk_dlen, "\n"

print "rombase=", rombase, "\n"

quit

#endif
