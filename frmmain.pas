unit frmmain;
{ Copyright (c) 2018 by Preben Björn Biermann Madsen
  email: prebenbjornmadsen@gmail.com
  http://pascalcoin.frizen.eu

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  This is a part of the Pascal Coin Project.

  If you like it, consider a donation using Pascal Coin Account: 274800-71
}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Menus, Spin, httpsend, synacode;

type

  { TFormMain }

  TFormMain = class(TForm)
    btSend: TButton;
    btStart: TButton;
    edAccount: TEdit;
    edMsg: TEdit;
    edNick: TEdit;
    Image1: TImage;
    lbNick: TLabel;
    lbInterval: TLabel;
    lbAccount: TLabel;
    MainMenu1: TMainMenu;
    mmDisplay: TMemo;
    mmLog: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    seTimer: TSpinEdit;
    StatusBar1: TStatusBar;
    btRefresh: TButton;
    Timer1: TTimer;
    procedure btStartClick(Sender: TObject);
    procedure btSendClick(Sender: TObject);
    procedure btRefreshClick(Sender: TObject);
    procedure edMsgKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    FSelectedAccount: string;
    FLastBlk : string;
    FCurBlk : string;
    FSeenBefore : boolean;
    function String2Hex(const Buffer: ansistring): string;
    function Hex2Str(const Buffer: ansistring): string;
    function SendRequest(method, params: string): String;
    procedure Display(buf: ansistring);
    procedure Log(buf: ansistring);
    procedure GetAccountOperations();
    procedure Tokenize(var str, blk, pay, sen: string);

  public
    { public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{$IFDEF UNIX}
const eol = #10;
{$ELSE}
const eol = #13#10;
{$ENDIF}
const
  ChatURL = 'http://127.0.0.1:4003';
  ChatAcc = '440065';

{ TFormMain }

function TFormMain.String2Hex(const Buffer: Ansistring): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Buffer) do
  Result := UpperCase(Result + IntToHex(Ord(Buffer[i]), 2));
end;

Function TFormMain.Hex2Str(const Buffer: Ansistring): String;
var i: Integer;
begin
  Result:=''; i:=1;
  While i<Length(Buffer) Do Begin
    Result:=Result+Chr(StrToIntDef('$'+Copy(Buffer,i,2),0));
    Inc(i,2);
  End;
end;

procedure TFormMain.Display(buf: ansistring);
begin
  mmDisplay.Lines.Add(buf);
  mmDisplay.SelStart := Length(mmDisplay.Text);
end;

procedure TFormMain.Log(buf: ansistring);
begin
  mmLog.Lines.Add(buf);
//  mmLog.SelStart := Length(mmLog.Text);
end;

function TFormMain.SendRequest(method, params: string): String;
var
    response: TMemoryStream;
    request, str, url: string;
begin
    request := '{"jsonrpc":"2.0","method":"' + method + '","params":{' + params + '},"id":123}';
    Log('send: ' + request);
    str := '';
    result := '';
    url := ChatUrl;
    response := TMemoryStream.Create;
    try
      if HttpPostURL(url, request, response) then
      begin
           SetLength(str, response.Size);
           Move(response.memory^, str[1], response.size);
      end;
    finally
      response.Free;
    end;
    result := str;
end;

procedure TFormMain.btSendClick(Sender: TObject);
var
  s, str, acc: string;
  i: integer;
begin
  i := pos('-', edAccount.Text);
  if (i > 0) then acc := trim(copy(edAccount.Text, 1, i-1))
  else acc := trim(edAccount.Text);

  if ((acc = '') or (edNick.Text = '') or (edMsg.Text = '')) then
  begin
    showmessage('Input data in all edit fields, please!');
    exit;
  end;
  s := copy('chat:' + trim(edNick.Text) + '> ' + trim(edMsg.Text), 1, 255);
  Log(s);
  s := String2Hex(copy('chat:' + trim(edNick.Text) + '> ' + trim(edMsg.Text), 1, 255));
  Log(s);
  str := SendRequest('sendto', '"sender":' + acc + ',"target":' + ChatAcc + ',"amount":0.0001,"payload":"' + s + '","payload_method":"none"');
  Log(str);
  edMsg.Text := '';
end;

procedure TFormMain.btStartClick(Sender: TObject);
begin
  if btStart.Caption = 'Start' then
  begin
    Timer1.Interval := seTimer.Value * 1000;
    Timer1.Enabled := true;
    btStart.Caption := 'Stop';
    Timer1Timer(self);
    Log('Timer running');
  end
  else
  begin
    Timer1.Enabled := false;
    btStart.Caption := 'Start';
    Log('Timer stopped');
  end;
end;

procedure TFormMain.btRefreshClick(Sender: TObject);
begin
  Timer1Timer(self);
end;

procedure TFormMain.edMsgKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
  begin
    Key := 0;
    btSendClick(self);
  end;
end;

procedure TFormMain.FormActivate(Sender: TObject);
var
  str: string;
begin
  str := SendRequest('nodestatus', '');
  Log(str);
  if Pos('"ready":true', str) < 1 then
  begin
    showmessage('No Connection - Check if your wallet is running and allow connections');
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FSelectedAccount := '';
  FLastBlk := '0000';
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
//
end;

procedure TFormMain.Tokenize(var str, blk, pay, sen: string);
var
    i, j: integer;
begin
  j := pos('"block":', str) + 8;
  i := pos('"time":', str) - 1;
  blk := copy(str, j , i - j);
  i := pos('"payload":', str) + 10;
  j := pos('"sender_account":', str) - 1;
  pay := copy(str, i + 1, j - (i + 2));
  j := j + 18;
  i := pos('"dest_account":', str) - 1;
  sen := copy(str, j, i - j);
  if length(pay) > 0 then
  begin
    if pos('636861743A',pay) = 1 then pay := trim(copy(Hex2Str(pay),6, 250))
    else pay := '';
  end;
end;

procedure TFormMain.GetAccountOperations();
var
  s, str, blk, pay, sen, oph: string;
  count, i, j: integer;

label
  GetMore;
begin
  FSeenBefore := false;
  count := 0;

  str := SendRequest('getaccountoperations', '"account":' + ChatAcc + ', "start":0');

  i := pos('"block":', str);
  if i > 0 then
  begin
    i := i + 8;
    j := pos('"time":', str) - 1;
    FCurblk := copy(str, i , j - i);
  end;
  if (StrToInt(FCurBlk) <= StrToInt(FLastBlk)) then Exit;

GetMore:
  i := pos('[{', str);
  if (i > 0) then delete(str, 1, i);

  while str <> '' do
  begin
    i := pos('},', str);
    if (i > 0) then
    begin
      s := copy(str, 1, i);
      delete(str, 1, i + 2);
    end
    else
    begin
      i := pos('}]', str);
      if (i > 0) then
      begin
        s := copy(str, 1, i);
        str := '';
      end;
    end;
    blk := ''; pay := ''; sen := '';

    Tokenize(s, blk, pay, sen);

    if (blk <> '') and (StrToInt(blk) <= StrToInt(FLastBlk)) then
    begin
      FSeenBefore := True;
      FLastBlk := FCurBlk;
      Exit;
    end;

    if (pay <> '') then Display(sen + ' - ' + pay);
  end; // while

  If not FSeenBefore then
  begin
    Log('Warning - records could be missing');
//* could incr count and Goto GetMore;
  end;
  FLastBlk := FCurBlk;
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
 GetAccountOperations;
end;

end.

