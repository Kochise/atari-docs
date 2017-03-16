/*	Exemple d'utilisation d'un module ex‚cutable du YM-Tracker
				TURBO-C				*/
#include <stdio.h>
#include <stdlib.h>
#include <tos.h>
#include <ext.h>
void main(){
	int handle; char *module;
	void (*commencer)(), (*arreter)(), (*recommencer)();

	module = malloc(11000); Fopen("B:\PROGRAMS\FACILE.TOS",0);
	Fread(handle,(long)10290,module); Fclose(handle);

	commencer = (long)module+(long)44; arreter = (long)module+(long)46;
	recommencer = (long)module+(long)48;

	Supexec( (long)commencer );
	printf("Hit any key to end the tune...\n"); getch();
	Supexec( (long)arreter );
}