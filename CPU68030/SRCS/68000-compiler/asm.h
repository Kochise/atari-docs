/******************************************************************************
 *  Asm.h                                                                     *
 *    Guillaume Bour - U.B.O. 2000/2001                                       *

 *    version 0.0.1                                                           *

 *****************************************************************************/

#define MAXS 80		 // taille d'une chaine standard

char label[MAXS];	 // nom de l'etiquette si elle existe
char op[MAXS];		 // nom de l'operation
char taille[MAXS];	 // "B", "W" ou "L"
char modeSrce[MAXS]; // "DN", "AN", "ANIND", "ANDEPL", "ABS", "IMM", "ETIQ"
char regSrce[MAXS];	 // nom du registre ("D0", "D1", ...)
char valSrce[MAXS];	 // valeur associée au mode (deplacement, reference, ...)
char modeDest[MAXS]; // "DN", "AN", "ANIND", "ANDEPL", "ABS", "IMM", "ETIQ"
char regDest[MAXS];  // nom du registre ("D0", "D1", ...)
char valDest[MAXS];  // valeur associée au mode (deplacement, reference, ...)

int nbLigne;		 // numero de ligne courante

/**** --- ***/
#define MAXX 100

short code[MAXX];   /* tableau des codes                    */
int tailleCode = 0; /* indice dans le tableau code          */
short data[MAXX];   /* tableau des donnees                  */
int tailleData = 0; /* indice dans le tableau data          */

/* section dans laquelle on se trouve */
#define _DATA_ 0
#define _CODE_ 1

/* Tables des références et des étiquettes                           */
struct stsym *tRef,         /* table des références                  */
             *tEtiqData,    /* table des étiquettes de la zone DATA  */
             *tEtiqCode;    /* table des étiquettes de la zone CODE  */


#define boolean int
#define false   0
#define true    1
/**** --- ***/

/*
extern int lireLigne(FILE *,char *);
extern void decomposerLigne(char *);
*/


/** produireCode().

    écriture d'une instruction dans le tableau de code
*/
void produireCode(short val);

/** produireData().

    écriture d'une donnée dans le tableau de données
*/
void produireData(short val);

/** coderFichier().

    codage assembleur de chaque ligne du fichier source.
*/
void coderFichier();

/* Codage des données (directive DATA)

  ligne type: LABEL: DC.L 5
*/
void coderDonnees();

/* Codage des données (directive CODE)

   
*/
void coderInstruction();

/* Codage de l'instruction assembleur DC

   entrées: CODA la zone où se trouve l'instruction
   sortie : aucune
*/
void coderDC(int CODA);

/* Codage de l'instruction assembleur MOVE

   entrées: aucune
   sorties: aucune

   !!! Traite uniquement les adressages Immédiats et Direct(IMM et DN)
*/
void coderMove();

/* Codage de l'instruction assembleur ADD 

   entrees: aucune
   sorties: aucune

   !!! Traite uniquement les adressages Immédiats et Direct(IMM et DN)

   ADD a deux sens de fonctionnement:
     + adresse effective vers registre
     + registre vers adresse effective

   le résultat de l'addition est toujours stocké dans la seconde opérande
*/
void coderAdd();

/* Codage de l'instruction assembleur BRA

   entrees: aucune
   sorties: aucune

   les instructions de branchement s'effectuent en 2 passe:
   passe1: on construit une table des symbole et une table des références
           qui contiennent respectivement l'@ des étiquettes et celle
           de leur références(où y fait-on appel)
   passe2: l'édition de lien. On mettra à jour le code de l'instruction de 
           branchement avec l'adresse de l'étiquette (le déplacement par
           au début du programme(mémorisé dans A5))
           -> VOIR LA FONCTION "EDITION_LIENS()"
*/
void coderBra();

/* Codage de l'instruction assembleur BEQ

   entrees: aucune
   sorties: aucune

   voir l'instruction BRA ci-dessus
*/
void coderBeq();

/* Edition des liens 

   entrées: aucune
   sortie : aucune

   pour chaque références de la table des références, 
     on recherche l'étiquette associée dans les 2 tables des étiquettes
     si elle est trouvée,
       on met à jour le code de l'instruction
     sinon
       ERREUR: référence non résolue
  fin pour
*/
void edition_liens();

/*** Creation de l'Executable ***

     entrees: le nom de l'executable
     sorties: aucune

     l'executable des structure comme suit:
       en-tete: taille code
                taille donnes
       codes
       donnees
*/
void creerExecutable(char *fic);

/** main().
 */
int main(int argc, char *argv[]);





