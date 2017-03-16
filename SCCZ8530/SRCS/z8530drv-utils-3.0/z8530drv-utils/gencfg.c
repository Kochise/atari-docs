/* 
        gencfg.c - Generate z8530drv.conf from PE1CHL driver params
   
   Copyright 1994-1996, by Joerg Reuter dl1bke@lykos.oche.de

   This program is intended for Amateur Radio use. If you are running it
   for commercial purposes, please drop me a note. I am nosy...

   ! You  m u s t  recognize the appropriate legislations of your country !
   ! before you connect a radio to the SCC board and start to transmit or !
   ! receive. The GPL allows you to use the  d r i v e r,  NOT the RADIO! !

   For non-Amateur-Radio use please note that you might need a special
   allowance/licence from the designer of the SCC Board and/or the
   MODEM. 

   This program is free software; you can redistribute it and/or modify 
   it under the terms of the (modified) GNU General Public License 
   delivered with the LinuX kernel source.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should find a copy of the GNU General Public License in 
   /usr/src/linux/COPYING; 

*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <linux/timer.h>
#ifdef CONFIG_SCC_STANDALONE
#include "scc.h"
#else
#include <linux/scc.h>
#endif

#define RCS_ID "$Id: gencfg.c,v 1.4 1995/11/17 01:11:27 jreuter Exp jreuter $"

/* yes, it IS awkward... */

int devices, chan, address, spacing, Aoff, Boff, Dataoff, intack, vector,
    hdwe, param, sp, chip;
    

char *board;
    
int cs(unsigned char *s)
{
	unsigned char k[40];
	int x;

	
	strcpy(k, s);
	
	for (x = 0; k[x]; x++)
		k[x] = toupper(k[x]);
	
	s = k;

	if (*s == '0')
	{	s++;
		if (*s == 'X')
		{
			s++;
			sscanf(s,"%x",&x);
			return x;
		}
		
		return 0;
	}
	
	if (!strcmp(s,"PA0HZP") || !strcmp(s,"SCC")) return PA0HZP;
	if (!strcmp(s,"EAGLE")) return EAGLE;
	if (!strcmp(s,"PC100")) return PC100;
	if (!strcmp(s,"PRIMUS")) return PRIMUS;
	if (!strcmp(s,"DRSI")) return DRSI;
	if (!strcmp(s,"BAYCOM")) return BAYCOM;
	
	return atoi(s);
}
                   
int main (int argc, char **argv)
{
	long unsigned clock;

	if (argc < 10)
	{
		fprintf(stderr,"usage: gencfg <devices> <address> <spacing> <Aoff> <Boff> <Dataoff> <intack>\n");
		fprintf(stderr,"       <vector> <clock> [hdwe] [param]\n\n");
		
		if (argc < 2)
		{
			fprintf(stderr,"<devices>: number of chips installed\n");
			fprintf(stderr,"<address>: base address of the first SCC chip\n");
			fprintf(stderr,"<spacing>: the spacing between the SCC chip base addresses\n");
			fprintf(stderr,"<Aoff>   : offset from a chip's base address to its channel A ctrl register\n");
			fprintf(stderr,"<Boff>   : offset from a chip's base address to its channel B ctrl register\n");
			fprintf(stderr,"<Dataoff>: offset from each channel's ctrl register to its data register\n");
			fprintf(stderr,"<intack> : the address of the INTACK Vector port. If none, specify 0\n");
			fprintf(stderr,"<vector> : the CPU interrupt vector for all connected SCCs\n");
			fprintf(stderr,"<clock>  : the clock frequency (PCLK) of all SCCs in Hertz\n");
			fprintf(stderr,"[hdwe]   : (optional) hardware type\n");
			fprintf(stderr,"[param]  : (optional) extra param\n\n");
		
			fprintf(stderr,"Notes:\n");
			fprintf(stderr,"(1) use this program ONLY if you configured the PE1CHL SCC driver under\n");
	    		fprintf(stderr,"    DOS before. It is much EASIER to edit /etc/z8530drv.conf and setup the\n");
   			fprintf(stderr,"    needed params there.\n\n");
    
			fprintf(stderr,"(2) all parameters must be specified in hex (0x300) or decimal (10).\n\n");

			fprintf(stderr,"(3) <clock> means the clock on the PClk pin. If you are using a DRSI\n");
    			fprintf(stderr,"    card set the \"clock\" parameter in /etc/z8530drv.conf to \"external.\"\n\n");
    		}
    		
    		fprintf(stderr,"expample for the PA0HZP card:\n");
    		fprintf(stderr,"gencfg 2 0x150 4 2 0 1 0x168 9 4915200 0 0 >z8530drv.conf\n\n");
  
    		return 1;
    	}
    	

    	devices = cs(argv[1]);
    	address = cs(argv[2]);
    	spacing = cs(argv[3]);
    	Aoff    = cs(argv[4]);
    	Boff    = cs(argv[5]);
    	Dataoff = cs(argv[6]);
    	intack  = cs(argv[7]);
    	vector  = cs(argv[8]);
    	clock   = atol(argv[9]);
  
    	if (argc > 10)
    		hdwe = cs(argv[10]);
    	else
    		hdwe = 0;

    	if (argc > 11)
    		param = cs(argv[11]);
    	else
    		param = 0;

    	switch(hdwe)
    	{
    		case PA0HZP: board = "PA0HZP";	sp = 0; 		break;
    		case EAGLE:  board = "EAGLE";	sp = address + 4; 	break;
    		case PC100:  board = "PC100";	sp = address; 		break;
    		case PRIMUS: board = "PRIMUS";  sp = address + 4;	break;
    		case DRSI:   board = "DRSI"; 	sp = address + 7;	break; 
    		case BAYCOM: board = "BAYCOM";	sp = 0;			break;
    		default:     sprintf(board,"0x%2.2x", hdwe); sp = 0;
    	}
    		
    	printf("# z8530drv.conf\n");
    	printf("# file generated by %s\n#\n#\n", RCS_ID);

	for (chip = 0; chip < devices; chip++)
	{
		printf("chip %d\n", chip+1);
		printf("data_a 0x%3.3x\n", address + spacing*chip + Aoff + Dataoff);
		printf("data_b 0x%3.3x\n", address + spacing*chip + Boff + Dataoff);
		printf("ctrl_a 0x%3.3x\n", address + spacing*chip + Aoff);
		printf("ctrl_b 0x%3.3x\n", address + spacing*chip + Boff);
		printf("irq %d\n", vector);
		printf("pclock %lu\n", clock);
		printf("board %s\n", board);
		
		if (intack)
			printf("vector 0x%3.3x\n", intack);
		if (sp)
		{
			printf("special 0x%3.3x\n", sp);
			printf("option 0x%2.2x\n", param);
		}
		
		printf("escc no\n#\n#\n#\n");
		
	}
	
	printf("# the following is a skelleton of the MODEM and KISS parameter\n");
	printf("# definitions. Adjust to your situation.\n");
	printf("#\n");
	
	for (chan = 0; chan < devices * 2; chan++)
	{
		printf("device /dev/scc%d\n", chan);
		printf("speed 1200\t# baudrate\n");
		printf("clock dpll\t# clock source\n");
		printf("mode nrzi\t# NRZI or NRZ\n");
		printf("#\n");
		printf("txdelay 36\n");
		printf("persist 64\n");
		printf("slot     8\n");
		printf("tail     8\n");
		printf("fulldup  0\n");
		printf("wait    12\n");
		printf("min      3\n");
		printf("maxkey   7\n");
		printf("idle     3\n");
		printf("maxdef 120\n");
		printf("group    0\n");
		printf("txoff  off\n");
		printf("softdcd on\n");
		printf("#\n#\n#\n");
	}
	
	printf("# EOF\n");	
	return 0;
}
