File`Info m                                     PROG f��        y�  
� ��p����pƠ�%��(   �   �   �  �EAZY6809            <  ���g��L� ,H��A��C��E� d��A� d$<����JGg��-A p�ND@ d~�ND@f��@f ���&HB�  f  &A� d(  �f| ` �`|  �| ��` ,�  f  VA� d( � �g(A� $<�(��`�Currently Not Changeable  (  �f| ` �`|  �| ��`  �UBf  �0<NEC�  IE� 0&I(ISC��0< �NE$< � < L"KE� 0r
B���@	f0<9NEa 
�0<:NE`�@f>ND/ 0< �NE A� "Hr/g(   e  0e  9c  @c  zc| `��Q���S�`  `fB��b� IE� |r.g�Q���JAk�  Q���| ��". A� d�x(  |f$<,�0<'NEA��0<>NE` �ZSBf C !e`A� $< ����` �>This flag indicates that the
selected file is is a �Folder�
(or �Directory�).
  C [Cd  �A� �"<,xa  | ��` �FH�P�0<". NEC� <$I U@�Q���B0< �NEA� <B�rL� �D�ï�@	f0<9a 	60<:`�P� _@f>ND0U@k e�Q���0< �NENu` �PSBf 0C !e  �A� $<,���` �2If this flag is ticked, the file
is stored on disk only and is not
loaded into memory. For �Folder�: it
has not been opened since OMEn was
booted or since the floppy was
inserted.
 CC _CdHA� �"<��xa ��B�B�A� <��f(  .f��f
�   dd* �� d�E0a 
V| ��` ��` �(0. Ha 
@` ��UBf  C !e\A� $<����` � The �Read Only� flag prevents the
file from being altered by most
programs
 C d �A� $<� x��` ��This 4 character long word
indicates the type of data
contained in the Public area
of the file. This allows software
to determine if it can use a file
and how. Some common types are:
�TEXT�: standard OMEn text
�6800�: 68000 machine code
�6830�: 68030 code (etc)
�DIR:� folder (directory)
�BMxx�: bitmap (Icons, pictures),
 �xx� indicates the number of bit
 planes of colors.
 UC[Cd". � �fA� �"<Xxa �>| ��` �x` ��SBf �C !e  �A� $<X���` ��The �Not Deletable� flag prevents the
file from being deleted by most software,
but does not prevent modification of the
file, such as adding files to a folder.
 C 	d  �A� $<� x��` � This helps to match up data files
with the program that created them
in order to boot the proper appl-
ication program if the user clicks
on a data file. (Not currently
implemented by the GUI.)
 CYC[CdA�"<�xa �~| ��` ��` �8SBf �C !e �A� $<����` �The �Header Save� flag causes the OMEn file
header to be saved as the first 128 bytes
of the file on disk formats such as DOS
which have shorter headers. This saves the
OMEn extended header info. The file data
won't be DOS compatible because DOS will
try to use the header as the beginning
of the file. Header Save can't be used
on folders, nor on any file which is
on disk (it must be in memory).
 BSBf  �C !evA� $< ���` �nThis flag indicates that the file
has not been saved to disk since
it was created or last modified.
 �I�YG� L"<�X`  �SBf XC !epA� $< ���` ��This flag indicates that the file
has not been updated to its disk
since it was last modified.
 I��G� T"<�X LC 
C dnxa ��B�z|A� <��fJ( R���fBJ�g>�   b6* R���f.J�g*�   b"6�E @  "+ $K La h| ��` �~$K " La R` �nC 	dNA��� x	a �A� <��f6�   d.( R���f&�   <d* R���gB��   <d$KX����B`�` ��WBf8WCC d. ��f �a "| ��` ��C QCd .  f��a �` �^@	f<a  ` �P0<$NE". A� d��(  |f$<,�0<'NEA�p0<>NE0<#Nu@f � C~<��g*A� $<,���` ��Cant Access File
(Busy?)
 -H  | �� PC� 0E� ��"HE� |r.g�Q����  Q��� ) 0E� �a � ) pE� �a � ) lE� a �p`2< �A �J) 6jp2< �@ �=i 6 Jp`)  6g
p< �A �@ �A>p`2< �)   6gp@p`J) 7jp@?p`)  6gp@&p`)  6gp@pp`)  6gp@�0) 4a *H ) J2) N��A�YE� La  < ) P2) T��A��E� Ta& ) V2) Z��A��E� \a n  C�����g��` �"H� (HO��� O$ &B@H@��^��X X X | / B�0�Hr� O��A� 	X X | / B� O��A� 	X X 	B�HC0�H O��A� 	X X | : B� O��A� 	X X | : B�HC0�H O��A� 	X X O� Nu��� �� �� Nu=@ HG� �H��� d" BAHAt0@ deR`�@ d 0ft �t0v
�CeR`�@ : 0f<  ��� .t0�CeR`�A :��Nu` �zB�  A�$C��E� d��". �xNu n  ~��g
,��.��Nu&PA� C� 0$K��K� ��HH@�H'@ 07n H 4L�  L��'@ J7A NL�  T��'@ P7A TK� ��HH@�H'@ pK��HH@�H'@ lK� d0+ 6r�- �f� `� �- �f� `� Jk Hg*2. J�A g� | �H���$<��A� 2��L�7@ 60+ H��0< n  NH,C�荒�g��`��.��NuThe file must be Updated
for the 'HeaderSave'
change to take effect.
 ..  f`|"A� ��Nu��    You must select a file.
Drag one from a DIR window
into the File Info window.
 G G~@��,gH�� A� ��Nu��    Unable to access the file because of I/O error:
"݀"
 "PNu ���File Info for:�
�            *** Drag file Here ***             �
Extension:  �    �- Folder
Version:  �   .  �- On Disk
 
�Data Type:  �    ��`� Read Only
Creator:    �    ��-� Not Deletable
��`� Header Save 
Created: �----/--/--� �--:--:--�- Not Saved 
Modified:�----/--/--� �--:--:--�- Not Updated 
Copied:  ----/--/-- ��--:--:--
 
   �Okay: Save Changes�    �Finished�
 
             �  �                                  0���                ����0����������    