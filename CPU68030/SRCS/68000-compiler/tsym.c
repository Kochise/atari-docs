
/*

tsym.c		Y. Autret
		4 decembre 1997

Gestion d'une table de symboles

*/


/************************************ tsym **********************************/

/*
tsym
	Role
		Definition de la structure table de symboles
*/

#define MAXSYM	10	/* nombre maximal de symboles */
#define MAXS	80	/* taille maximale d'un symbole */

struct stsym {
 char name[MAXSYM][MAXS];
 int val[MAXSYM];
 int nbsym;
};

/********************************** tsymError *******************************/

/*
tsymError
	Role
		Signale les erreurs et arrete le programme
*/

int tsymError(char *s)
{
 printf("\n\n");
 printf("!! erreur dans la gestion d'une table de symboles\n");
 printf("!! %s",s);
 printf("\n\n");
 exit(0);
}

/********************************** tsymAlloc *******************************/

/*
tsymAlloc
	Role
		Allocation d'une table de symboles
*/

struct stsym *tsymAlloc()
{
 struct stsym *tds;
 /*
 printf("sizeof = %d\n",sizeof(struct stsym));
 */
 tds = (struct stsym *)malloc(sizeof(struct stsym));
 tds->nbsym = 0;
 return(tds);
}

/******************************** tsymGetSize *******************************/

/*
tsymGetSize
	Role
		Retourne le nombre d'elements de la table
*/

int tsymGetSize(struct stsym *tds)
{
 return(tds->nbsym);
}

/******************************* tsymGetNameVal *****************************/

/*
tsymGetNameVal
	Role
		Retourne le nom et la valeur d'un element de la table.
		Le numero de l'element est fourni en parametre.
*/

int tsymGetNameVal(struct stsym *tds, int num, char **name, int *val)
{
 if (num >= tds->nbsym) tsymError("erreur d'acces (tsymGetNameVal)");
 *name = (tds->name[num]);
 *val = tds->val[num];
}

/********************************** tsymPush ********************************/

/*
tsymPush
	Role
		Empile un nouveau symbole dans la table
	Remarque
		Ne verifie pas si le symbole existe deja.
		Utiliser tsymFind si necessaire.
*/

tsymPush(struct stsym *tds, char *name, int val)
{
 if (tds->nbsym >= MAXSYM) tsymError("table des symbole pleine");
 if (strlen(name) >= MAXS) tsymError("symbole trop long");
 strcpy(tds->name[tds->nbsym],name);
 tds->val[tds->nbsym] = val;
 tds->nbsym++;
}

/********************************** tsymFind ********************************/

/*
tsymFind
	Role
		Recherche un symbole dans la table.
		Retourne le numero du symbole si la recherche est un succes.
		Retourne -1 si le symbole n'est pas trouve.
*/

int tsymFind(struct stsym *tds, char *name)
{
 int i;
 for (i=0 ; i<tds->nbsym ; i++) {
  if (strcmp(tds->name[i],name) == 0) return(i);
 }
 return(-1);
}

/********************************* tsymGetVal *******************************/

/*
tsymGetVal
	Role
		Retourne la valeur d'un symbole.
		Declenche une erreur si le symbole n'est pas trouve.
*/

int tsymGetVal(struct stsym *tds, char *name)
{
 int pos;
 char *s;
 int val;
 pos = tsymFind(tds,name);
 if (pos == -1) tsymError("symbole inexistant (tsymGetVal)");
 tsymGetNameVal(tds,pos,&s,&val);
 return(val);
}

/********************************* tsymDisplay ******************************/

/*
tsymDisplay
	Role
		Affiche une table de symbole
*/

int tsymDisplay(struct stsym *tds)
{
 int i;
 char *s;
 int val;
 printf("affichage d'une table de symboles\n");
 for (i=0 ; i<tsymGetSize(tds) ; i++) {
  tsymGetNameVal(tds,i,&s,&val);
  printf("element %d : (%s:%d)\n",i,s,val);
 }
 printf("\n");
}

/************************************ main **********************************/

essai() {
 struct stsym *tds;
 int i;
 char *s;
 int val;

 tds = tsymAlloc();

 tsymPush(tds,"xa",33);
 tsymPush(tds,"xb",44);
 tsymPush(tds,"xc",443);
 tsymPush(tds,"xd",445);
 tsymPush(tds,"x23456789",444);

 printf("\n");
 printf("le numero du symbole xc est %d\n",tsymFind(tds,"xc"));
 printf("le numero du symbole xe est %d\n",tsymFind(tds,"xe"));

 printf("\n");
 printf("valeur de xc: %d\n",tsymGetVal(tds,"xc"));
 printf("valeur de xb: %d\n",tsymGetVal(tds,"xb"));
 printf("\n");

 printf("affichage de la table\n");
 for (i=0 ; i<tsymGetSize(tds) ; i++) {
  tsymGetNameVal(tds,i,&s,&val);
  printf("element %d : (%s:%d)\n",i,s,val);
 }
 printf("\n");

}

