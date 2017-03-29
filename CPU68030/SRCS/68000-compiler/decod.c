
/*

decod.c

*/

#define MAX 30		// nombre d'unites lexicales

// liste des unites lexicales

#define DEUXPOINTS 	1
#define POINT		2
#define PAR_OUV		3
#define PAR_FER		4
#define VIRGULE		5
#define DIESE		6
#define SYM			8
#define DREG		9
#define AREG		10
#define ABS			11

char unites[MAX][MAXS];
int typesUnites[MAX];
int nbUnites;

/********************************** finir ***********************************/

finir(char *s)
{
 printf("erreur ligne %d: %s\n",nbLigne,s);
 printf("arret de l'assemblage\n");
 exit(0); 
}

/***************************** afficher *******************************/

afficherDecodage()
{
 printf("	resultats du decodage\n");
 printf("	  label :%s:\n",label);
 printf("	  op :%s: taille :%s:\n",op,taille);
 printf("	  modeSrce :%s: regSrce :%s: valSrce :%s:\n",modeSrce,regSrce,valSrce);
 printf("	  modeDest :%s: regDest :%s: valDest :%s:\n",modeDest,regDest,valDest);
}

/******************************* afficherUL ****************************/

afficherUL()
{
 int i;
 for (i=0 ; i<nbUnites ; i++) {
  printf("unite %d = %s\n",i,unites[i]);
 }
}

/******************************* ajouterMot ***************************/

ajouterMot(char *s, int type)
{
 if ((s[0] == 'D') && (s[1] >= '0') && (s[1] <= '9') && (s[2] == 0)) type = DREG;
 else if ((s[0] == 'A') && (s[1] >= '0') && (s[1] <= '9') && (s[2] == 0)) type = AREG;
 else if ((s[0] >= '0') && (s[0] <= '9')) type = ABS;

 strcpy(unites[nbUnites],s);
 typesUnites[nbUnites] = type;
 nbUnites++;
 //printf("ajouterMot = %s\n",s);
}

/********************************** extraireMot *****************************/

/*
extraireMot
	Role
		Extraction du premier mot d'une chaine
	Resultat
		La chaine suivant le mot extrait
*/

char * extraireMot(char *s)
{
 char c;
 char mot[80];
 char *ptrmot;
 for (;;) {
  if ((*s != ' ') && (*s != '\t')) break;
  s++;
 }
 c = *s;
 if (c == 0) return((char *)-1);
 if (c == ';') {
  return((char *)-1);
 }

 else if (c == ':') {ajouterMot(":",DEUXPOINTS); return(s+1);}
 else if (c == '.') {ajouterMot(".",POINT); return(s+1);}
 else if (c == '(') {ajouterMot("(",PAR_OUV); return(s+1);}
 else if (c == ')') {ajouterMot(")",PAR_FER); return(s+1);}
 else if (c == ',') {ajouterMot(",",VIRGULE); return(s+1);}
 else if (c == '#') {ajouterMot("#",DIESE); return(s+1);}
 else if (((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_')) {
  ptrmot = mot;
  for (;;) {
   if (((c < 'A') || (c > 'Z')) && ((c < '0') || (c > '9')) && (c != '_')) break;
   if (c == 0) break;
   *ptrmot++ = c;
   s++;
   c = *s;
  }
  *ptrmot = 0;
  ajouterMot(mot,SYM);
  if (c == 0) return((char *)-1);
  return(s);
 }
 else {
  printf("%d\n",((int)c)&0xff);
  finir("caractere illegal ou non traite");
 }
}

/************************ maj ******************************/

mettreEnMajuscules(char *s)
{
 char c;
 for (;;) {
  c = *s;
  //printf("c=%c\n",c);
  if (c == 0) break;
  if ((c >= 'a') && (c <= 'z')) {
   c = c - 'a' + 'A';
   //printf("C=%c\n",c);
   *s = c;
   //printf("D=%c\n",c);
  }
  s++;
 }
}

/*********************** decomposerUL **********************/

/*
decomposerUL
	role
		decompose une ligne en unites lexicales
		les unites sont rangees dans le tableau "unites"
*/

decomposerUL(char *s0)
{
 int pos;
 char s00[MAXS];
 char *s;

 nbUnites = 0;
 strcpy(s00,s0);
 s = s00;

 mettreEnMajuscules(s);
 //printf("maj: %s\n",s);

 for (;;) {
  s = extraireMot(s);
  if (s == (char *)-1) break;
 }

 //printf("fin extraction\n");
 strcpy(label,"");
 strcpy(op,"");
 strcpy(taille,"");
 strcpy(modeSrce,"");
 strcpy(regSrce,"");
 strcpy(valSrce,"");
 strcpy(modeDest,"");
 strcpy(regDest,"");
 strcpy(valDest,"");


 pos = 0;
 if (pos >= nbUnites) return;

 if ((typesUnites[0] == SYM) && (typesUnites[1] == DEUXPOINTS)) {
  strcpy(label,unites[0]);
  pos = 2;
 }

 if (pos >= nbUnites) return;

 if (typesUnites[pos] == SYM) {
  strcpy(op,unites[pos]);
  pos++;
 }
 else {
  finir("instruction manquante");
 }

 if (pos >= nbUnites) return;

 if ((typesUnites[pos] == POINT) && (typesUnites[pos+1] == SYM)) {
  strcpy(taille,unites[pos+1]);
  pos+=2;
 }

 if (pos >= nbUnites) return;

 if ((typesUnites[pos] == DIESE) && // #valeur
     (typesUnites[pos+1] == ABS)) {
  strcpy(modeSrce,"IMM");
  strcpy(valSrce,unites[pos+1]);
  pos+=2;
 }
 else if (typesUnites[pos] == DREG) { // Dn
  strcpy(modeSrce,"DN");
  strcpy(regSrce,unites[pos]);
  pos++;
 }
 else if (typesUnites[pos] == AREG) { // An
  strcpy(modeSrce,"AN");
  strcpy(regSrce,unites[pos]);
  pos++;
 }
 else if ((typesUnites[pos] == PAR_OUV) && // (An)
     (typesUnites[pos+1] == AREG) &&
     (typesUnites[pos+2] == PAR_FER)) {
  strcpy(modeSrce,"ANIND");
  strcpy(regSrce,unites[pos+1]);
  pos+=3;
 }
 else if ((typesUnites[pos] == ABS) && // d(An)
     (typesUnites[pos+1] == PAR_OUV) &&
     (typesUnites[pos+2] == AREG) &&
     (typesUnites[pos+3] == PAR_FER)) {
  strcpy(modeSrce,"ANDEPL");
  strcpy(regSrce,unites[pos+2]);
  strcpy(valSrce,unites[pos]);
  pos+=4;
 }
 else if (typesUnites[pos] == ABS) { // Abs
  strcpy(modeSrce,"ABS");
  strcpy(valSrce,unites[pos]);
  pos++;
 }
 else if (typesUnites[pos] == SYM) { // Etiq
  strcpy(modeSrce,"ETIQ");
  strcpy(valSrce,unites[pos]);
  pos++;
 }

 if (pos >= nbUnites) return;

 if (typesUnites[pos] != VIRGULE)
  finir("parametre incorrect");

 pos++;

 if (typesUnites[pos] == DREG) { // Dn
  strcpy(modeDest,"DN");
  strcpy(regDest,unites[pos]);
  pos++;
 }
 else if (typesUnites[pos] == AREG) { // An
  strcpy(modeDest,"AN");
  strcpy(regDest,unites[pos]);
  pos++;
 }
 else if ((typesUnites[pos] == PAR_OUV) && // (An)
     (typesUnites[pos+1] == AREG) &&
     (typesUnites[pos+2] == PAR_FER)) {
  strcpy(modeDest,"ANIND");
  strcpy(regDest,unites[pos+1]);
  pos+=3;
 }
 else if ((typesUnites[pos] == SYM) && // d(An)
     (typesUnites[pos+1] == PAR_OUV) &&
     (typesUnites[pos+2] == AREG) &&
     (typesUnites[pos+3] == PAR_FER)) {
  strcpy(modeDest,"ANDEPL");
  strcpy(regDest,unites[pos+2]);
  strcpy(valDest,unites[pos]);
  pos+=4;
 }
 else if (typesUnites[pos] == ABS) { // Abs
  strcpy(modeDest,"ABS");
  strcpy(valDest,unites[pos]);
  pos++;
 }
 else if (typesUnites[pos] == SYM) { // Etiq
  strcpy(modeDest,"ETIQ");
  strcpy(valDest,unites[pos]);
  pos++;
 }

 if (pos < nbUnites) finir("instruction incorrecte, trop de parametres");

}

/************************************ lireLigne **************************/

/*
lireLigne
	Role
		Lecture de la ligne courante d'un fichier
	Resultat
		0 si fin de fichier atteinte
		1 sinon
*/
int lireLigne(FILE *f, char *s)
{
  int count;
  int c;
  *s = 0;
  for (;;) 
    {
      /* count = fread(s,1,1,f); */
      c = fgetc(f);
      if (c != '\r') 
        {
          if (c == -1) 
            {
              *s = 0;
              return(0);
            }

          if (c == '\n') 
            {
              *s = 0;
              return(1);
            }

          *s++ = c;
        }
    }
}

/*
decomposerUL1(char *s)
{
 char s0[80];
 printf("ligne: %s\n",s);
 decomposerUL(s);
 afficherUL();
 afficher();
 read(0,s0,80);
}
*/

/*
xxmain()
{
 decomposerUL1("X: MOVE.L #2,D2");
 decomposerUL1("MOVE.L D3,D2");
 decomposerUL1(" move.l D1,D2");
 decomposerUL1(" move.l A1,D2");
 decomposerUL1(" move.l (A1),D2");
 decomposerUL1(" move.l 34(A2),D2");
}
*/

