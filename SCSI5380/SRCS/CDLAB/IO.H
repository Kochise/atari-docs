/*
 * IO.H  -  Fonctions d'interfa�age avec SCSIDRV
 * Librairie de fonctions SCSI en C, s'appuyant sur la SCSI LIB.
 *
 * Copyright 2004 Francois Galea
 *
 * This file is part of CDLab.
 *
 * CDLab is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * CDLab is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Foobar; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __IO_H__
#define __IO_H__

/* D�finitions de formats de commandes */
typedef struct
{
  unsigned char  Command;
  unsigned char  LunAdr;
  unsigned short Adr;
  unsigned char  Len;
  unsigned char  Flags;
} scsi_cmd6;

typedef struct
{
  unsigned char  Command;
  unsigned char  Lun;
  unsigned long  Adr;
  unsigned char  Reserved;
  unsigned char  LenHigh;
  unsigned char  LenLow;
  unsigned char  Flags;
} scsi_cmd10;

typedef struct
{
  unsigned char  Command;
  unsigned char  Lun;
  unsigned long  Adr;
  unsigned long  Len;
  unsigned char  Reserved;
  unsigned char  Flags;
} scsi_cmd12;

/* D�finition d'une commande SCSI */
typedef struct
{
  short *        Handle;      /* Handle f�r Bus und Ger�t             */
  char *         Cmd;         /* Zeiger auf CmdBlock                  */
  unsigned short CmdLen;      /* L�nge des Cmd-Block (f�r ACSI n�tig) */
  void *         Buffer;      /* Datenpuffer                          */
  unsigned long  TransferLen; /* �bertragungsl�nge                    */
  char *         SenseBuffer; /* Puffer f�r ReqSense (18 Bytes)       */
  unsigned long  Timeout;     /* Timeout in 1/200 sec                 */
  unsigned short Flags;       /* Bitvektor f�r Ablaufw�nsche          */
    #define Disconnect 0x10   /* versuche disconnect                  */
} scsi_cmd;

/* D�finitions utiles et vari�es */
struct parm_head6
{
  unsigned char reserved0;
  unsigned char MediumType;
  unsigned char HostApplicationCode;
  unsigned char BlockDescLen;
};

struct parm_head10
{
  unsigned char reserved0;
  unsigned char reserved1;
  unsigned char MediumType;
  unsigned char HostApplicationCode;
  unsigned char reserved4;
  unsigned char reserved5;
  unsigned short BlockDescLen;
};

struct block_desc {
  unsigned long Blocks;                  /* Byte HH = DensityCode */
  unsigned long BlockLen;                /* Byte HH = Reserved    */
};

struct private
{
  unsigned long BusIds;
  char          resrvd[28];
};

struct bus_info
{
  struct private private;
   /* f�r den Treiber */
  char  bus_name[20];
   /* zB 'SCSI', 'ACSI', 'PAK-SCSI' */
  unsigned short bus_no;
   /* Nummer, unter der der Bus anzusprechen ist */
  unsigned short features;
      #define cArbit     0x01    /* auf dem Bus wird arbitriert                          */
      #define cAllCmds   0x02    /* hier k�nnen ale SCSI-Cmds abgesetzt werden           */
      #define cTargCtrl  0x04    /* Das Target steuert den Ablauf (so soll's sein!)      */
      #define cTarget    0x08    /* auf diesem Bus kann man sich als Target installieren */
      #define cCanDisconnect 0x10 /* Disconnect ist m�glich                             */
      #define cScatterGather 0x20 /* scatter gather bei virtuellem RAM m�glich */
  /* bis zu 16 Features, die der Bus kann, zB Arbit,
   * Full-SCSI (alle SCSI-Cmds im Gegensatz zu ACSI)
   * Target oder Initiator gesteuert
   * Ein SCSI-Handle ist auch ein Zeiger auf eine Kopie dieser Information!
   */
  unsigned long max_len;
  /* maximale Transferl�nge auf diesem Bus (in Bytes)
   * entspricht zB bei ACSI der Gr��e des FRB
   */
};

struct dlong
{
  unsigned long hi;
  unsigned long lo;
};

struct dev_info
{
  char         private[32];
  struct dlong scsi_id;
};

/* Prototypes */
scsi_cmd * set_cmd(
  short CmdLen,               /* Taille du bloc de commande (6,10,12) */
  unsigned short Opcode,      /* Opcode de la commande */
  unsigned long BlockAdr,     /* Champ d'adresse du bloc de comande */
  unsigned long TransferLen,  /* Champ de longueur du bloc de commande */
  void *Buffer,               /* Buffer d'entr�e ou de sortie */
  unsigned long Len );        /* Longueur des infos � envoyer ou recevoir */
int scsi_init( void );
int scsi_in( scsi_cmd * Cmd );
int scsi_out( scsi_cmd * Cmd );
int io_get_first_bus( struct bus_info * info );
int io_get_next_bus( struct bus_info * info );
int io_get_first_device( short bus_no, struct dev_info * dev );
int io_get_next_device( short bus_no, struct dev_info * dev );
io_check_device( short bus_no, int scsi_id, char * name,
                 unsigned short * features );
short * io_open_device( short bus_no, const struct dlong * id,
                        unsigned long * max_len );
int io_close_device( short * handle );

#endif

