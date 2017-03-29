/******************************************************************************
 *  Asm.c - fichier principal de l'assembleur 68000                           *
 *    Guillaume Bour - U.B.O. 2000/2001                                       *

 *    version 0.0.1                                                           *

 *****************************************************************************/

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>

#include "asm.h"
#include "decod.c"
#include "tsym.c"

/** produireCode().

    �criture d'une instruction dans le tableau de code
*/
void produireCode(short val)
{
  if(tailleCode == MAXX)
    { printf("produireCode: tableau plein\n"); exit(0); }

  printf("code: 0x%04x\n", val);
  code[tailleCode++] = val;
}

/** produireData().

    �criture d'une donn�e dans le tableau de donn�es
*/
void produireData(short val)
{
  if(tailleData == MAXX)
    { printf("produireData: tableau plein\n"); exit(0); }

  printf("data: 0x%04x\n", val);
  data[tailleData++] = val;
}

/** coderFichier().

    codage assembleur de chaque ligne du fichier source.
*/
void coderFichier()
{
  static CODA = -1;

  /* on switche entre les zones DATA et CODE */
  if(strcmp(op, "DATA") == 0)
    { CODA = _DATA_; }
  else if(strcmp(op, "CODE") == 0)
    { CODA = _CODE_; }
  else
    {
      switch(CODA) 
        {
        case _DATA_: coderDonnees(); break;
        case _CODE_: coderInstruction(); break;
        default:
          if(strcmp(op, "") != 0)
            { 
              printf("directives CODE et DATA non definies\n");
              exit(-1);
            }
          break;
        }
    }
}


/* Codage des donn�es (directive DATA)

  ligne type: LABEL: DC.L 5
*/
void coderDonnees()
{
  
  /** Gestion des labels: on ins�re le nouveau label
        dans la table des �tiquettes de la zone DATA
  */
  if(strcmp(label, "") != 0)
    { 
      /* le label existe deja */
      if(tsymFind(tEtiqData, label) != -1 || tsymFind(tEtiqCode, label) != -1)
      { 
        printf("ligne %d: label '%s' d�j� existant\n", nbLigne, label);
        exit(-1); 
      }
      
      tsymPush(tEtiqData, label, tailleData); 
    }  

  /*** Gestion des variables ****/
  if(strcmp(op, "DC") == 0)
    { coderDC(_DATA_); }
  /*** Instruction non reconnue */
  else if(strcmp(op, "") != 0)
    {
      printf("ligne %d: instruction '%s' non reconnue\n", nbLigne, op);
      exit(-1);
    }
}

/* Codage des donn�es (directive CODE)

   
*/
void coderInstruction()
{
  //printf("\n	  Codage de l'instruction:\n");

  /*** Cas ou on a un label avant l'instruction **/
  if(strcmp(label, "") != 0)
  { 
    /* le label existe deja */
     if(tsymFind(tEtiqData, label) != -1 || tsymFind(tEtiqCode, label) != -1)
     { 
       printf("ligne %d: label '%s' d�j� existant\n", nbLigne, label);
       exit(-1); 
     }

     tsymPush(tEtiqCode, label, tailleCode); 
  }  

  /*** Instruction RTS ****/
  if(strcmp(op, "RTS") == 0)
  { produireCode(0x4E75); }

  /*** Instruction MOVE ***/
  else if(strcmp(op, "MOVE") == 0)
    { coderMove(); }

  /*** Instruction ADD ****/
  else if(strcmp(op, "ADD") == 0)
    { coderAdd(); }

  /*** Instruction BRA ****/
  else if(strcmp(op, "BRA") == 0)
    { coderBra(); }

  /*** Instruction BEQ ****/
  else if(strcmp(op, "BEQ") == 0)
    { coderBeq(); }
  
  /*** Instruction DC (ins�re dans le code un code directement 
         saisi en assembleur)                                  ****/
  else if(strcmp(op, "DC") == 0)
    { coderDC(_CODE_); }

  /*** Instruction non reconnue */
  else if(strcmp(op, "") != 0)
    {
      printf("ligne %d: instruction '%s' non reconnue\n", nbLigne, op);
      exit(-1);
    }

}

/* Codage de l'instruction assembleur DC

   entr�es: CODA la zone o� se trouve l'instruction
   sortie : aucune
*/
void coderDC(int CODA)
{
  if(CODA == _DATA_)
    {
      /*** Selon la taille des donn�es
           Byte: 
           Word: on �crit un mot
           Long: on �crit 2 mots (poid fort puis poid faible)
      */
      switch(taille[0])
        {
        case 'B': 
        case 'W': produireData(atoi(valSrce)); break;
        case 'L': 
        default : produireData((atoi(valSrce))>>16);
                  produireData(atoi(valSrce));
        }
    } else {
      switch(taille[0])
        {
        case 'B': 
        case 'W': produireCode(atoi(valSrce)); break;
        case 'L': 
        default : produireCode((atoi(valSrce))>>16);
                  produireCode(atoi(valSrce));
        }
    }
}

/* Codage de l'instruction assembleur MOVE

   entr�es: aucune
   sorties: aucune

   !!! Traite uniquement les adressages Imm�diats et Direct(IMM et DN)
*/
void coderMove()
{
  short code,
        high_val   = 0,
        low_val    = 0;
  boolean isImmed  = false,
          isLong   = false;
  boolean SrceIsLabel = false,
          DestIsLabel = false;

  /*** Instruction MOVE ********************/
  code = 0x0000;

  /*** Codage de la taille des op�randes:
         Byte: 1 octet( 8 bits)
         Word: 1 mot  (16 bits)
         Long: 2 mot  (32 bits)
   */
  switch(taille[0])
    {
    case 'B': code |= 0x1000; break; /* eq � code |= 1<<12 */
    case 'W': code |= 0x3000; break;
    case 'L': 
    default : code |= 0x2000; isLong = true; break;
    }

  /*** Traitement DESTINATION ***************/
  /*  - Mode d'adressage Direct             */
  if(strcmp(modeDest, "DN")== 0) 
    { 
      code |= 0x0000; 
	  
      /* numero du registre.
          regDest = "D3" -> registre n� 3;
      */
      code |= atoi(regDest+1)<<9;
    }
  /*  - Mode d'adressage Imm�diat: INTERDIT */
  else if(strcmp(modeDest, "IMM") == 0)
    {
      printf("ligne %d: mode d'adressage destination invalide\n", nbLigne);
      exit(-1);
    }
  /*  - Mode d'adressage par Etiquette dans la zone DATA:
          On tranforme cet adressage en adressage par d�placement
          � partir du registre A5.
          MOVE.W #4, toto  -> MOVE.W #4, d(A5)

          NB: comme on ne connait pas � priori l'adresse de toto, 
              l'instruction sera mise � jour � l'�dition des liens
  */
  else if(strcmp(modeDest, "ETIQ") == 0)
    {
      code |= 0x0B40; /* adressage destination d(A5) */

      DestIsLabel = true;
    }
 

  /*** Traitement SOURCE ********************/
  /*  - Mode d'adressage Direct             */
  if(strcmp(modeSrce, "DN") == 0) 
    {
      code |= 0x0000;
      
      /* numero du registre.
          regSrce = "D3" -> registre n� 3;
      */
      code |= atoi(regSrce+1);
    }
  /*  - Mode d'adressage Imm�diat           */
  else if(strcmp(modeSrce, "IMM") == 0) 
    {
      code |= 0x003C;
      
      /* 
         la valeur � affecter est m�moris�e juste apr�s l'instruction:
           MOV.L #10, D3:    $263C
                             $0000
                             $000A

         NB � propos de la gestion poid fort/poid faible:
           les valeur longues(stock�es sur 32 bits) sont "invers�e",
           c�d que le poid fort est stock� avant le poid faible
           (notation Big Endian)

           (c'est aussi le cas pour les valeur de 16 bits, mais c'est
            fait intrins�quement dans le mot)
      */
      switch(isLong)
        {
        case true : high_val = (atoi(valSrce))>>16; 
 	    case false: low_val = atoi(valSrce); break;
        }

      isImmed = true;
    }
  /*  - Mode d'adressage par Etiquette dans la zone DATA:
          On tranforme cet adressage en adressage par d�placement
          � partir du registre A5.
          MOVE.W #4, toto  -> MOVE.W #4, d(A5)

          NB: comme on ne connait pas � priori l'adresse de toto, 
              l'instruction sera mise � jour � l'�dition des liens
  */
  else if(strcmp(modeSrce, "ETIQ") == 0)
    {
      code |= 0x002D; /* adressage source d(A5) */

      SrceIsLabel = true;
    }

  produireCode(code);

  /* �criture de la valeur dans le cas d'une valeur imm�diate
     (sur 16 ou 32 octets)
  */
  if(isImmed)
    { 
      if(isLong)
        { produireCode(high_val); } 

      produireCode(low_val); 
    }

  /* Nb: d�placement sur 16 bits (1 mot) */
  if(SrceIsLabel)
    {
      produireCode(0x0000);
      tsymPush(tRef, valSrce, tailleCode-1);
    }
  if(DestIsLabel)
    {
      produireCode(0x0000);
      tsymPush(tRef, valDest, tailleCode-1);
    }
}

/* Codage de l'instruction assembleur ADD 

   entrees: aucune
   sorties: aucune

   !!! Traite uniquement les adressages Imm�diats et Direct(IMM et DN)

   ADD a deux sens de fonctionnement:
     + adresse effective vers registre
     + registre vers adresse effective

   le r�sultat de l'addition est toujours stock� dans la seconde op�rande
*/
void coderAdd()
{
  short code,
        high_val   = 0,
        low_val    = 0;
  boolean isImmed  = false,
          isLong   = false;
  boolean SrceIsLabel = false,
          DestIsLabel = false;

  /*** Instruction ADD *********************/
  code = 0xD000;

 /** Codage de la taille des op�randes:
        Byte: 1 octet( 8 bits)
        Word: 1 mot  (16 bits)
        Long: 2 mot  (32 bits)
   */

  switch(taille[0])
    {
    /* case 'B': code |= 0x0000; */
    case 'B': break;
    case 'W': code |= 0x0040; break;
    case 'L': 
    default : code |= 0x0080; isLong = true; break;
    }


  /*** D�termination du sens de l'op�ration:
        si on a un registre en destination, c'est le sens 
           "adresse effective vers registre"
        sinon si le registre est en source, c'est le sens 
           "registre vers adresse effective"

        cas particulier: ADD R1, R2. On prendra le sens 
           "adresse effective vers registre (voir les sp�cifications Motorola)
   */
  /*** Sens addressage effectif -> registre */
  if(strcmp(modeDest, "DN")== 0)
    {  
      
      code |= 0x0100;  /* (le 1 est pour les op-modes) */

      /* numero du registre.
          regDest = "D3" -> registre n� 3;
      */
      code |= atoi(regDest+1)<<9;

      
      /*** Traitement SOURCE ********************/
      /*  - Mode d'adressage Direct             */
      if(strcmp(modeSrce, "DN") == 0) 
        {
          code |= 0x0000;
      
          /* numero du registre.
             regSrce = "D3" -> registre n� 3;
          */
          code |= atoi(regSrce+1);
        }
      /*  - Mode d'adressage Imm�diat           */
      else if(strcmp(modeSrce, "IMM") == 0) 
        {
          code |= 0x003C;
      
          /* 
             la valeur � affecter est m�moris�e juste apr�s l'instruction:
             ADD.L #10, D3:    $263C
                               $0000
                               $000A

             NB � propos de la gestion poid fort/poid faible:
               les valeur longues(stock�es sur 32 bits) sont "invers�e",
               c�d que le poid fort est stock� avant le poid faible
               (notation Big Endian)

               (c'est aussi le cas pour les valeur de 16 bits, mais c'est
              fait intrins�quement dans le mot)
          */
          switch(isLong)
            {
            case true : high_val = (atoi(valSrce))>>16; 
            case false: low_val = atoi(valSrce); break;
            }

          isImmed = true;
        }
      /*  - Mode d'adressage par Etiquette dans la zone DATA:
          On tranforme cet adressage en adressage par d�placement
          � partir du registre A5.
          MOVE.W #4, toto  -> MOVE.W #4, d(A5)
          
          NB: comme on ne connait pas � priori l'adresse de toto, 
              l'instruction sera mise � jour � l'�dition des liens
      */
      else if(strcmp(modeSrce, "ETIQ") == 0)
        {
          code |= 0x002D; /* adressage source d(A5) */
          
          SrceIsLabel = true;
        }

   /*** Sens registre -> adressage effectif */
    } else if(strcmp(modeSrce, "DN")== 0) {
      code |= atoi(regSrce+1)<<9;

      /*** Traitement DESTINATION ******************/
      /*  - Mode d'adressage Imm�diat: INTERDIT    */
      if(strcmp(modeDest, "IMM") == 0)
        {
          printf("ligne %d: mode d'adressage destination invalide\n", nbLigne);
        }
      /*  - Mode d'adressage par Etiquette dans la zone DATA:
          On tranforme cet adressage en adressage par d�placement
          � partir du registre A5.
          MOVE.W #4, toto  -> MOVE.W #4, d(A5)
          
          NB: comme on ne connait pas � priori l'adresse de toto, 
              l'instruction sera mise � jour � l'�dition des liens
      */
      else if(strcmp(modeDest, "ETIQ") == 0)
        {
          code |= 0x002D; /* adressage source d(A5) */
          
          DestIsLabel = true;
        }

    /* s'il n'y a un registre ni en source, ni en destination, 
         alors l'op�ration est invalide
    */
    } else {
       printf("ligne %d: instruction incorrectement constitu�e\n", nbLigne);
       exit(-1);
    }

  produireCode(code);

  /* �criture de la valeur dans le cas d'une valeur imm�diate
     (sur 16 ou 32 octets)
  */
  if(isImmed)
    { 
      if(isLong)
        { produireCode(high_val); } 

      produireCode(low_val); 
    }

  /* Nb: d�placement sur 16 bits (1 mot) */
  if(SrceIsLabel)
    {
      produireCode(0x0000);
      tsymPush(tRef, valSrce, tailleCode-1);
    }
  if(DestIsLabel)
    {
      produireCode(0x0000);
      tsymPush(tRef, valDest, tailleCode-1);
    }
}


/* Codage de l'instruction assembleur BRA

   entrees: aucune
   sorties: aucune

   les instructions de branchement s'effectuent en 2 passe:
   passe1: on construit une table des symbole et une table des r�f�rences
           qui contiennent respectivement l'@ des �tiquettes et celle
           de leur r�f�rences(o� y fait-on appel)
   passe2: l'�dition de lien. On mettra � jour le code de l'instruction de 
           branchement avec l'adresse de l'�tiquette (le d�placement par
           au d�but du programme(m�moris� dans A5))
           -> VOIR LA FONCTION "EDITION_LIENS()"
*/
void coderBra()
{
  /* Etape 1: on ecrit le code de BRA (0 pour le d�placement 16 bits) */
  produireCode(0x6000);
  produireCode(0x0000);

  /* Etape 2: on insere la reference dans le tableau des references */
  tsymPush(tRef, valSrce, tailleCode-1);
}

/* Codage de l'instruction assembleur BEQ

   entrees: aucune
   sorties: aucune

   voir l'instruction BRA ci-dessus
*/
void coderBeq()
{
  /* Etape 1: on ecrit le code de BEQ */
  //produireCode(0x0000); --> r�cup�rer le code!!
  //produireCode(0x0000);

  /* Etape 2: on insere la reference dans le tableau des references */
  //tsymPush(tRef, valSrce, tailleCode-1);
}

/* Edition des liens 

   entr�es: aucune
   sortie : aucune

   pour chaque r�f�rences de la table des r�f�rences, 
     on recherche l'�tiquette associ�e dans les 2 tables des �tiquettes
     si elle est trouv�e,
       on met � jour le code de l'instruction
     sinon
       ERREUR: r�f�rence non r�solue
  fin pour
*/
void edition_liens()
{
  int i,
      refPos,
      etiqPos;
  char *etiqName;

  for(i = 0; i < tsymGetSize(tRef); i++)
    {
      tsymGetNameVal(tRef, i, &etiqName, &refPos);   

      /* cas g�n�ral         : �tiquette dans DATA */
      if(tsymFind(tEtiqData, etiqName) != -1)
        {
          etiqPos = tsymGetVal(tEtiqData, etiqName);
          code[refPos] = etiqPos * 2;    
        }
      /* cas des Branchements: �tiquette dans CODE */
      else if(tsymFind(tEtiqCode, etiqName) != -1)
        {
          etiqPos = tsymGetVal(tEtiqCode, etiqName);
          code[refPos] = etiqPos * 2;    
        }
      else
        {
          printf("r�f�rence %s non r�solue\n", etiqName); 
          exit(-1); 
        }
    }
}

/*** Creation de l'Executable ***

     entrees: le nom de l'executable
     sorties: aucune

     l'executable des structure comme suit:
       en-tete: taille code
                taille donn�es
       codes
       donnees
*/
void creerExecutable(char *fic)
{
  int fd,
      taille;

  fd = open(fic, O_WRONLY|O_CREAT|O_TRUNC);

  taille = tailleCode*2; /* un code fait 2 octets */
  write(fd, &taille, 4);
  taille = tailleData*2;
  write(fd, &taille, 4);
  write(fd, code, tailleCode*2);
  write(fd, data, tailleData*2);
  close(fd);
}


/************************************** main *********************************/

int main(int argc, char *argv[])
{
 int res;
 char ligne[80];
 char fsrce[80];
 char fdest[80];
 char s0[80];
 FILE *f;

 /* Creation de la table des etiquettes et de celle des references */
 tRef = tsymAlloc();
 tEtiqData = tsymAlloc();
 tEtiqCode = tsymAlloc();
 /****/

 if (argc != 2) {
  printf("asm fichier.s");
  exit(0);
 }

 strcpy(fsrce,argv[1]);
 if ((fsrce[strlen(fsrce)-1] != 's') || (fsrce[strlen(fsrce)-2] != '.')) 
   {
     printf("asm fichier.s");
     exit(0);
   }
 
 strcpy(fdest,argv[1]);
 fdest[strlen(fdest)-1] = 'x';

 f = fopen(fsrce,"r");
 for (nbLigne=1 ;; nbLigne++) 
   {
     res = lireLigne(f,ligne);
     if (res == 0) 
       { break; }
     
     printf("ligne %d: %s\n",nbLigne,ligne);
     decomposerUL(ligne);
     //afficherUL();
     
     afficherDecodage();
     coderFichier();

     read(0,s0,80);
   }

 fclose(f);
	
 /* affichage des tables des etiquettes et des references */
 printf("table des etiquettes DATA\n");
 tsymDisplay(tEtiqData);
 printf("table des etiquettes CODE\n");
 tsymDisplay(tEtiqCode);
 printf("table des  references\n");
 tsymDisplay(tRef);

 /* edition des liens */
 edition_liens();

 /* Ecriture du fichier binaire */
 creerExecutable(fdest);
 
 return(0);
}




