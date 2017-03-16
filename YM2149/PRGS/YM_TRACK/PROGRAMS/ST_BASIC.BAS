10    'Exemple d'utilisation d'un module ex‚cutable du YM-Tracker
20    '                    ST BASIC
30    '----------------------------------------------------------
40    clear:dim module$(11000):'        R‚servation de m‚moire
50    demarrer=varptr(module$)+44:'     Adresse pour jouer la musique
60    finir=varptr(module$)+46:'        Adresse pour arreter la musique
70    recommencer=varptr(module$)+48:'  Adresse pour recommencer du d‚but
80    'Chargement du module en m‚moire :
90    bload "a:\programs\facile.tos",varptr(module$)
100   '
110   print "Press Return to begin the song ..."
120   input a$:'                       Attente d'une touche au clavier
130   '
140   call demarrer:'                  D‚marrer la musique
150   '
160   print "Press Return to stop and exit ..."
170   input a$:'                       Attente d'une touche au clavier
180   '
190   call finir:'                     Arreter la musique
200   end
