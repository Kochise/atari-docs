\ Exemple d'utilisation d'un module ex‚cutable du YM-Tracker
\                       FORTH 83 (forthmacs)

only forth also definitions

\ Reservation de place dans le dictionnaire et chargement du module :
  create module
  "" A:\programs\facile.tos read-open
  module ifd @ dup fsize dup allot swap fgets drop
  ifd @ close

\ D‚finition des mots permettant de d‚marrer ou d'arreter la musique :

assembler also
code call  ( addr -- )
  a7 )+ a0 lmove
  a0 ) jsr
  next
end-code

: start-music  ( -- )
\ Pour d‚marrer ou continuer la musique
  module th 2c + call
;

: stop-music  ( -- )
\ Pour arreter la musique
  module th 2e + call
;

: restart-music  ( -- )
\ Pour re-d‚marrer la musique, du d‚but
  module th 30 + call
;

cr
.( To start or to continue the music, type : start-music,) cr
.( To stop the music, type : stop-music,) cr
.( To restart the music from the beginning, type : restart-music.) cr
