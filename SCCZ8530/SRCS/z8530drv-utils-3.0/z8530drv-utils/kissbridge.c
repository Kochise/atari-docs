/* $Id: kissbridge.c,v 1.2 1996/08/08 20:04:46 jreuter Exp jreuter $ */

/* KISSbridge --- emulates a KISS TNC for access to a AX.25 Network Device
 *
 * Copyright (c) 1996 Jörg Reuter <jreuter@lykos.tng.oche.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */ 

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <linux/netdevice.h>

#define MAXMTU 1024		/* maximum frame length we support */

char *ax25_dev;

#define KISS_FEND	192
#define KISS_FESC	219
#define KISS_TFEND	220
#define KISS_TFESC	221

enum KISS_states {KISS_START, KISS_DATA, KISS_ESC};

void kiss_encode(int fd, unsigned char *buf, int len)
{
	int cnt, cnt2;
	unsigned char mybuf[2*MAXMTU+2];

	if (len > MAXMTU)
		return;
		
	cnt2 = 0;
	mybuf[cnt2++] = KISS_FEND;
	
	for (cnt = 0; cnt < len; cnt++)
	{
		switch(buf[cnt])
		{
			case KISS_FESC:
				mybuf[cnt2++] = KISS_FESC;
				mybuf[cnt2++] = KISS_TFESC;
				break;
			case KISS_FEND:
				mybuf[cnt2++] = KISS_FESC;
				mybuf[cnt2++] = KISS_TFEND;
				break;
			default:
				mybuf[cnt2++] = buf[cnt];
		}
				
	}

	write(fd, mybuf, cnt2);
}

void kiss_decode(int fd, unsigned char *buf, int len)
{
	static unsigned char mybuf[MAXMTU];
	static int kiss_state = KISS_START;
	static int cnt2 = 0;

	struct sockaddr saddr;
	int cnt, addrlen;
	
	for (cnt = 0; cnt < len; cnt++)
	{
		switch (kiss_state)
		{
			case KISS_START:
				if (buf[cnt] == KISS_FEND)
					kiss_state = KISS_DATA;
				break;
				
			case KISS_DATA:
				switch(buf[cnt])
				{
					case KISS_FEND:
						kiss_state = KISS_START;
						addrlen = sizeof(saddr);
						strcpy(saddr.sa_data, ax25_dev);
						saddr.sa_family = AF_AX25;
						sendto(fd, mybuf, cnt2, 0, &saddr, addrlen);

						cnt2 = 0;
						break;
					case KISS_FESC:
						kiss_state = KISS_ESC;
						break;
					default:
						mybuf[cnt2++] = buf[cnt];
				}
				break;

			case KISS_ESC:
				switch(buf[cnt])
				{
					case KISS_TFEND:
						mybuf[cnt2++] = KISS_FEND;
						break;
					case KISS_TFESC:
						mybuf[cnt2++] = KISS_FESC;
						break;
					default:
						mybuf[cnt2++] = buf[cnt];
				}
				kiss_state = KISS_DATA;
				break;
		}
	}
}

int main(int argc, char **argv)
{
	int sock_fd, pty_fd;
	struct sockaddr saddr;
	int addrlen;
	unsigned char buf[2*MAXMTU+2];
	int len;
	fd_set fdset;
	struct timeval t;
	
	if (argc < 3)
	{
		fprintf(stderr,"usage: %s <device> <pty>\n", argv[0]);
		return 1;
	}
	
	ax25_dev = argv[1];
	
	sock_fd = socket(AF_INET, SOCK_PACKET, htons(ETH_P_AX25));
	if (sock_fd < 0)
	{
		perror("open socket");
		return 1;
	}
	
	pty_fd = open(argv[2], O_RDWR);
	if (pty_fd < 0)
	{
		perror("open pTTY");
		return 1;
	}
	
	if (fork())
		return 0;
		
	while(1)
	{
		FD_ZERO(&fdset);
		FD_SET(pty_fd, &fdset);
		FD_SET(sock_fd,&fdset);
		
		t.tv_sec = 0;
		t.tv_usec = 0;
		
		if (select(pty_fd+1, &fdset, NULL, NULL, NULL) < 0) 
		{
			perror("select");
			return 1;
		}
		
		if (FD_ISSET(sock_fd, &fdset))
		{
			addrlen = sizeof(saddr);
			len = recvfrom(sock_fd, buf, sizeof(buf), 0, &saddr, &addrlen);
		
			if (len < 0 && errno != EINTR)
			{
				perror("recvfrom");
				return 1;
			}
		
			if (len > 0 && !strcmp(ax25_dev, saddr.sa_data))
				kiss_encode(pty_fd, buf, len);
		}
			

		
		if (FD_ISSET(pty_fd, &fdset))
		{
			len = read(pty_fd, buf, sizeof(buf));
			
			if (len < 0)
			{
				perror("read");
				return 1;
			}

			if (len)
				kiss_decode(sock_fd, buf, len);
		}
	}
	
}
