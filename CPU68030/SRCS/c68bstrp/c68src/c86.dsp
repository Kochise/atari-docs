# Microsoft Developer Studio Project File - Name="c86" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 5.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=c86 - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "C86.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "C86.mak" CFG="c86 - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "c86 - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "c86 - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "c86 - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir ".\Release"
# PROP BASE Intermediate_Dir ".\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir ".\Release"
# PROP Intermediate_Dir ".\Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /W4 /GX /O2 /I "E:\DJW\PSION\SRC\C86" /D "NDEBUG" /D "WIN32" /D "_CONSOLE" /D "__STDC__" /YX /FD /c
# ADD BASE RSC /l 0x809 /d "NDEBUG"
# ADD RSC /l 0x809 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386 /out:".\c86.exe"

!ELSEIF  "$(CFG)" == "c86 - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir ".\Debug"
# PROP BASE Intermediate_Dir ".\Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir ".\Debug"
# PROP Intermediate_Dir ".\Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /W4 /Gm /GX /Zi /Od /I "E:\DJW\PSION\SRC\C86" /D "_DEBUG" /D "WIN32" /D "_CONSOLE" /D "__STDC__" /FR /YX /FD /c
# ADD BASE RSC /l 0x809 /d "_DEBUG"
# ADD RSC /l 0x809 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /out:".\c86.exe"

!ENDIF 

# Begin Target

# Name "c86 - Win32 Release"
# Name "c86 - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;hpj;bat;for;f90"
# Begin Source File

SOURCE=.\Analyze.c
# End Source File
# Begin Source File

SOURCE=.\Cglbdef.c
# End Source File
# Begin Source File

SOURCE=.\Cmain.c
# End Source File
# Begin Source File

SOURCE=.\Decl.c
# End Source File
# Begin Source File

SOURCE=.\Expr.c
# End Source File
# Begin Source File

SOURCE=.\Extern.c
# End Source File
# Begin Source File

SOURCE=.\Flow68k.c
# End Source File
# Begin Source File

SOURCE=.\Flowc30.c
# End Source File
# Begin Source File

SOURCE=.\Gen386.c
# End Source File
# Begin Source File

SOURCE=.\Gen68k.c
# End Source File
# Begin Source File

SOURCE=.\Gen86.c
# End Source File
# Begin Source File

SOURCE=.\Genarm.c
# End Source File
# Begin Source File

SOURCE=.\Genc30.c
# End Source File
# Begin Source File

SOURCE=.\Genffp.c
# End Source File
# Begin Source File

SOURCE=.\Genicode.c
# End Source File
# Begin Source File

SOURCE=.\Genieee.c
# End Source File
# Begin Source File

SOURCE=.\Genppc.c
# End Source File
# Begin Source File

SOURCE=.\Genstmt.c
# End Source File
# Begin Source File

SOURCE=.\Genutil.c
# End Source File
# Begin Source File

SOURCE=.\Getsym.c
# End Source File
# Begin Source File

SOURCE=.\Init.c
# End Source File
# Begin Source File

SOURCE=.\Intexpr.c
# End Source File
# Begin Source File

SOURCE=.\List.c
# End Source File
# Begin Source File

SOURCE=.\Memmgt.c
# End Source File
# Begin Source File

SOURCE=.\Msgout.c
# End Source File
# Begin Source File

SOURCE=.\Optimize.c
# End Source File
# Begin Source File

SOURCE=.\Out68k_a.c
# End Source File
# Begin Source File

SOURCE=.\Out68k_c.c
# End Source File
# Begin Source File

SOURCE=.\Out68k_g.c
# End Source File
# Begin Source File

SOURCE=.\Out68k_q.c
# End Source File
# Begin Source File

SOURCE=.\Outarm_o.c
# End Source File
# Begin Source File

SOURCE=.\Outc30_r.c
# End Source File
# Begin Source File

SOURCE=.\Outgen.c
# End Source File
# Begin Source File

SOURCE=.\Outppc.c
# End Source File
# Begin Source File

SOURCE=.\Outx86_a.c
# End Source File
# Begin Source File

SOURCE=.\Outx86_b.c
# End Source File
# Begin Source File

SOURCE=.\Outx86_g.c
# End Source File
# Begin Source File

SOURCE=.\Outx86_s.c
# End Source File
# Begin Source File

SOURCE=.\Peep68k.c
# End Source File
# Begin Source File

SOURCE=.\Peeparm.c
# End Source File
# Begin Source File

SOURCE=.\Peepc30.c
# End Source File
# Begin Source File

SOURCE=.\Peepppc.c
# End Source File
# Begin Source File

SOURCE=.\Peepx86.c
# End Source File
# Begin Source File

SOURCE=.\Reg68k.c
# End Source File
# Begin Source File

SOURCE=.\Regarm.c
# End Source File
# Begin Source File

SOURCE=.\Regc30.c
# End Source File
# Begin Source File

SOURCE=.\Regppc.c
# End Source File
# Begin Source File

SOURCE=.\Regx86.c
# End Source File
# Begin Source File

SOURCE=.\Stmt.c
# End Source File
# Begin Source File

SOURCE=.\Symbol.c
# End Source File
# Begin Source File

SOURCE=.\System.c
# End Source File
# Begin Source File

SOURCE=.\Types.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl;fi;fd"
# Begin Source File

SOURCE=.\Cglbdec.h
# End Source File
# Begin Source File

SOURCE=.\Chdr.h
# End Source File
# Begin Source File

SOURCE=.\Check.h
# End Source File
# Begin Source File

SOURCE=.\config.h
# End Source File
# Begin Source File

SOURCE=.\Expr.h
# End Source File
# Begin Source File

SOURCE=.\Gen386.h
# End Source File
# Begin Source File

SOURCE=.\Gen68k.h
# End Source File
# Begin Source File

SOURCE=.\gen86.h
# End Source File
# Begin Source File

SOURCE=.\genarm.h
# End Source File
# Begin Source File

SOURCE=.\genc30.h
# End Source File
# Begin Source File

SOURCE=.\genppc.h
# End Source File
# Begin Source File

SOURCE=.\Genx86.h
# End Source File
# Begin Source File

SOURCE=.\Message.h
# End Source File
# Begin Source File

SOURCE=.\Outproto.h
# End Source File
# Begin Source File

SOURCE=.\Proto.h
# End Source File
# Begin Source File

SOURCE=.\Version.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;cnt;rtf;gif;jpg;jpeg;jpe"
# End Group
# Begin Source File

SOURCE=.\C86.rsg
# End Source File
# End Target
# End Project
