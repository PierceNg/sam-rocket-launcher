// SAM pattern rocket launcher demo
// Copyright (c) 2023 Pierce Ng.
// Code released under MIT license.

program samrocket;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, web;

const
  TEXT_ELT = 'text';
  BUTTON_ELT = 'button';
  COUNTER_MAX = 10;

type
  TControlState = (Invalid, Ready, Counting, Launched, Aborted);

  TStateRepresentation = class(TObject)
  private
    FControlState: TControlState;
    FCounter: Integer;
  public
    property ControlState: TControlState read FControlState;
    property Counter: Integer read FCounter write FCounter;
  end;

  TView = class(TObject)
  private
    procedure Ready(sr: TStateRepresentation);
    procedure Counting(sr: TStateRepresentation);
    procedure Launched;
    procedure Aborted(sr: TStateRepresentation);
    procedure Invalid;
  public
    procedure Render(sr: TStateRepresentation);
  end;

  TModel = class(TObject)
  private
    FCounter: Integer;
    FStarted: Boolean;
    FLaunched: Boolean;
    FAborted: Boolean;
    FView: TView;
    // Below are domain-specific operations.
    procedure Decrement(CurrentCounter: Integer);
    procedure Launch;
    // Below are SAM operations.
    function NextActionPredicate(state: TStateRepresentation): Boolean;
    function StateRepresentation: TStateRepresentation;
  public
    constructor Create;
    procedure Present(Proposal: TJSObject);
    function IsReady: Boolean;
    function IsCounting: Boolean;
    function IsLaunched: Boolean;
    function IsAborted: Boolean;
  end;

  TMyApplication = class(TBrowserApplication)
  public
    procedure doRun; override;
  end;

var
  Model: TModel;
  Application : TMyApplication;

function SAM_Action_Ready(anEvent: TJSMouseEvent): Boolean;
begin
  Model.Present(new(['ready', true]));
  result := false;
end;

function SAM_Action_Start(anEvent: TJSMouseEvent): Boolean;
begin
  Model.Present(new(['start', true]));
  result := false;
end;

function SAM_Action_Abort(anEvent: TJSMouseEvent): Boolean;
begin
  Model.Present(new(['abort', true]));
  result := false;
end;

constructor TModel.Create;
begin
  inherited;
  FCounter := COUNTER_MAX;
  FStarted := false;
  FLaunched := false;
  FAborted := false;
  FView := TView.Create;
end;

procedure TModel.Decrement(CurrentCounter: Integer);
  procedure countdown;
  begin
    self.Present(new(['counter', CurrentCounter - 1]));
  end;
begin
  window.SetTimeOut(@countdown, 1000);
end;

procedure TModel.Launch;
  procedure launching;
  begin
    self.Present(new(['launch', true]));
  end;
begin
  window.SetTimeOut(@launching, 500);
end;

function TModel.StateRepresentation: TStateRepresentation;
begin
  result := TStateRepresentation.Create;
  result.FControlState := TControlState.Invalid;
  if self.IsReady then result.FControlState := TControlState.Ready;
  if self.IsCounting then result.FControlState := TControlState.Counting;
  if self.IsLaunched then result.FControlState := TControlState.Launched;
  if self.IsAborted then result.FControlState := TControlState.Aborted;
  result.Counter := self.FCounter;
end;

function TModel.NextActionPredicate(state: TStateRepresentation): Boolean;
begin
  if state.ControlState = Counting then
    begin
      if state.Counter > 0 then
        begin
          self.Decrement(self.FCounter);
          exit(true);
        end;
      if state.Counter = 0 then
        begin
          self.Launch;
          exit(true);
        end;
    end;
  exit(false);
end;

procedure TModel.Present(Proposal: TJSObject);
  function b2s(v: Boolean): String;
  begin
    result := BoolToStr(v, 't', 'f');
  end;
var
  sr: TStateRepresentation;
begin
  if Proposal.hasOwnProperty('ready') then
    if Boolean(Proposal['ready']) then
      begin
        self.FCounter := COUNTER_MAX;
        self.FStarted := false;
        self.FLaunched := false;
        self.FAborted := false;
      end;

  if Proposal.hasOwnProperty('counter') then
    self.FCounter := Integer(Proposal['counter']);

  if Proposal.hasOwnProperty('start') then
    self.FStarted := Boolean(Proposal['start']);

  if Proposal.hasOwnProperty('launch') then
    self.FLaunched := Boolean(Proposal['launch']);

  if Proposal.hasOwnProperty('abort') then
    self.FAborted := Boolean(Proposal['abort']);

  sr := self.StateRepresentation;
  //writeln(Format('counter=%d; started=%s; launched=%s; aborted=%s', [FCounter, b2s(FStarted), b2s(FLaunched), b2s(FAborted)]));
  self.NextActionPredicate(sr);
  self.FView.Render(sr);
end;

function TModel.IsReady: Boolean;
begin
  result := (FCounter = COUNTER_MAX)
         and not FStarted
         and not FLaunched
         and not FAborted;
end;

function TModel.IsCounting: Boolean;
begin
  result := (FCounter <= COUNTER_MAX)
         and (FCounter >= 0)
         and FStarted
         and not FLaunched
         and not FAborted;
end;

function TModel.IsLaunched: Boolean;
begin
  result := (FCounter = 0)
         and FStarted
         and FLaunched
         and not FAborted;
end;

function TModel.IsAborted: Boolean;
begin
  result := (FCounter <= COUNTER_MAX)
         and (FCounter >= 0)
         and FStarted
         and not FLaunched
         and FAborted;
end;

procedure TView.Ready(sr: TStateRepresentation);
var
  btn: TJSHtmlButtonElement;
begin
  Document.GetElementById(TEXT_ELT).innerHtml := Format('Counter = %d', [sr.Counter]);
  btn := TJSHtmlButtonElement(Document.GetElementById(BUTTON_ELT));
  btn.OnClick := @SAM_Action_Start;
  btn.innerHtml := 'Start';
end;

procedure TView.Counting(sr: TStateRepresentation);
var
  btn: TJSHtmlButtonElement;
begin
  Document.GetElementById(TEXT_ELT).innerHtml := Format('Countdown %d...', [sr.Counter]);
  btn := TJSHtmlButtonElement(Document.GetElementById(BUTTON_ELT));
  btn.OnClick := @SAM_Action_Abort;
  btn.innerHtml := 'Abort';
end;

procedure TView.Launched;
var
  btn: TJSHtmlButtonElement;
begin
  Document.GetElementById(TEXT_ELT).innerHtml := 'Launched!';
  btn := TJSHtmlButtonElement(Document.GetElementById(BUTTON_ELT));
  btn.OnClick := @SAM_Action_Ready;
  btn.innerHtml := 'Next Rocket';
end;

procedure TView.Aborted(sr: TStateRepresentation);
var
  btn: TJSHtmlButtonElement;
begin
  Document.GetElementById(TEXT_ELT).innerHtml := Format('Aborted when countdown at %d', [sr.Counter]);
  btn := TJSHtmlButtonElement(Document.GetElementById(BUTTON_ELT));
  btn.OnClick := @SAM_Action_Ready;
  btn.innerHtml := 'New Rocket';
end;

procedure TView.Invalid;
var
  btn: TJSHtmlButtonElement;
begin
  Document.GetElementById(TEXT_ELT).innerHtml := 'SHOULD NOT HAPPEN: Model state is invalid';
  btn := TJSHtmlButtonElement(Document.GetElementById(BUTTON_ELT));
  btn.OnClick := @SAM_Action_Ready;
  btn.innerHtml := 'Start Over';
end;

procedure TView.Render(sr: TStateRepresentation);
begin
  case sr.ControlState of
    TControlState.Ready: self.Ready(sr);
    TControlState.Counting: self.Counting(sr);
    TControlState.Launched: self.Launched;
    TControlState.Aborted: self.Aborted(sr);
    TControlState.Invalid: self.Invalid;
  end;
end;

procedure TMyApplication.doRun;
begin
  Model.Present(new(['ready', true]));
end;

begin
  Model := TModel.Create;
  Application := TMyApplication.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
