program LodToAsm;

uses Tos;

var
	i:integer;
	t:text;
	w:word;
	buf:array[0..65535] of byte;
	len:longint;

function ByteToHex(a:byte):string;
var
	s:string[3];
	i:integer;
begin
	s:='$00';
	i:=a and $f;
	if i<10 then
		s[3]:=Chr(Ord('0')+i)
	else
		s[3]:=Chr(Ord('a')+i-10);
	i:=(a shr 4) and $f;
	if i<10 then
		s[2]:=Chr(Ord('0')+i)
	else
		s[2]:=Chr(Ord('a')+i-10);
	ByteToHex:=s;
end;

function WordToHex(a:word):string;
var
	s:string[5];
	i,j:integer;
begin
	s:='$0000';
	for j:=1 to 4 do
	begin
		i:=a and $f;
		if i<10 then
			s[6-j]:=Chr(Ord('0')+i)
		else
			s[6-j]:=Chr(Ord('a')+i-10);
		a:=a shr 4;
	end;
	WordToHex:=s;
end;

begin
	len:=Dsp_LodToBinary('DSP.LOD',@buf[0])*3;
	Assign( t, 'DSPBIN.S' );
	Rewrite( t );

	Writeln( t, '		EXPORT dsp_bin, end_of_dspbin' );
	Writeln( t );
	Writeln( t, '		DATA');
	Writeln( t );
	Write( t, 'dsp_bin:' );
	for i:=0 to (len shr 1)-1 do begin
		w:=buf[i*2] shl 8 + buf[i*2+1];
		if (i mod 16)=0 then begin
			Writeln( t );
			Write(t, '		dc.w	',WordToHex(w));
		end
		else
			Write(t,',',WordToHex(w));
	end;
	Writeln( t );
	if (len and 1)<>0 then
		Writeln(t, '		dc.b	',ByteToHex(buf[len-1]));
	Writeln( t, 'end_of_dspbin:' );
	Close( t );
end.
