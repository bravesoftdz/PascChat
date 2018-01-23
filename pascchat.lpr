program pascchat;
{ Copyright (c) 2018 by Preben Björn Biermann Madsen
  email: prebenbjornmadsen@gmail.com
  http://pascalcoin.frizen.eu

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  This is a part of the Pascal Coin Project.

  If you like it, consider a donation using Pascal Coin Account: 274800-71
}
{$mode objfpc}{$H+}
{$DEFINE UseCThreads}
uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, frmmain
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

