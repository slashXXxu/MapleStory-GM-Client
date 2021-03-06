unit NameTag;

interface

uses
  Windows, SysUtils, StrUtils, PXT.Sprites, Generics.Collections, WZIMGFile, Classes, Global,
  WzUtils, PXT.Graphics;

type
  TNameTag = class(TSpriteEx)
  public
    class var
      ReDraw: Boolean;
      CanUse: Boolean;
      PlayerName: string;
      NameWidth: Integer;
      TargetTexture: TTexture;
    procedure DoMove(const Movecount: Single); override;
    procedure DoDraw; override;
    class procedure Create(Name: string); overload;
  end;

  TMedalTag = class(TSpriteEx)
  private
    EastWidth: Integer;
    WestWidth: Integer;
    CenterWidth: Integer;
    CenterLength: Integer;
    TagWidth: Integer;
    FontColor: Cardinal;
    R, G, B: Byte;
  public
    MedalName: string;
    TargetIndex: Integer;
    IsReDraw: Boolean;
    Entry: TWZIMGEntry;
    TargetTexture: TTexture;
    procedure InitData;
    class var
      MedalTag: TMedalTag;
    procedure TargetEvent;
    procedure DoMove(const Movecount: Single); override;
    procedure DoDraw; override;
    class procedure ReDraw; virtual;
    class procedure Delete; virtual;
    class procedure Create(ItemID: string); overload; virtual;
  end;

  TNickNameTag = class(TMedalTag)
  public

    class var
      NickNameTag: TNickNameTag;
    class procedure ReDraw; override;
    procedure DoDraw; override;
    class procedure Delete; override;
    class procedure Create(ItemID: string); overload; override;
  end;

  TLabelRingTag = class(TMedalTag)
  public
    class var
      LabelRingTag: TLabelRingTag;
    class procedure ReDraw; override;
    procedure DoDraw; override;
    class procedure Delete; override;
    class procedure Create(ItemID: string); overload; override;
  end;

implementation

uses
  MapleCharacter, ShowOptionUnit, MapleMap, AsphyreTypes, PXT.Types, PXT.Canvas;

procedure TNameTag.DoMove(const MoveCount: Single);
begin
  inherited;
  if ReDraw then
    GameCanvas.DrawTarget(TargetTexture, NameWidth, 15,
      procedure
      begin
        var NamePos := NameWidth div 2;
        if TMap.ShowChar then
        begin
          GameCanvas.FillRect(FloatRect(0, 2, NameWidth + 4, 15), cRGB1(0, 0, 0, 160));
        //  GameCanvas.Flush;
          //FontsAlt[1].TextOut(PlayerName, 3, 1, $FFFFFFFF);
          GameFont.Draw(Point2f(3,1),PlayerName,$FFFFFFFF);
        end;
      end);

  X := Player.X;
  Y := Player.Y;
  Z := Player.Z;
end;

procedure TNameTag.DoDraw;
var
  WX, WY, NamePos: Integer;
begin
  if TMap.ShowChar then
  begin
    WX := Round(Player.X) - Round(Engine.WorldX);
    WY := Round(Player.Y) - Round(Engine.WorldY);
    NamePos := NameWidth div 2;
    GameCanvas.Draw(TargetTexture, WX - NamePos, WY);
  end;
  if ReDraw then
    ReDraw := False;
end;

class procedure TNameTag.Create(Name: string);
begin
  PlayerName := Name;
  //NameWidth := FontsAlt[1].TextWidth(PlayerName) + 5;
   NameWidth:= Round(GameFont.ExtentByPixels(PlayerName).Right);
 // TargetIndex := GameTargets.Add(1, NameWidth, 15, apf_A8R8G8B8, True, True);
 // GameDevice.RenderTo(TargetEvent, 0, True, GameTargets[TargetIndex]);
  GameCanvas.DrawTarget(TargetTexture, NameWidth, 15,
    procedure
    begin
      var NamePos := NameWidth div 2;
      if TMap.ShowChar then
      begin
        GameCanvas.FillRect(FloatRect(0, 2, NameWidth + 4, 15), cRGB1(0, 0, 0, 160));
        GameCanvas.Flush;
       // FontsAlt[1].TextOut(PlayerName, 3, 1, $FFFFFFFF);
        GameFont.Draw(Point2f(3,1),PlayerName,$FFFFFFFF);
      end;
    end);

  with TNameTag.Create(SpriteEngine) do
  begin
    TruncMove := True;
  end;
end;


//TMedalTag

class procedure TMedalTag.Delete;
begin
  if MedalTag <> nil then
    MedalTag.Dead;
end;

procedure TMedalTag.DoMove(const MoveCount: Single);
begin
  inherited;
  if IsReDraw then
   GameCanvas.DrawTarget(TargetTexture, 300, 100,
    procedure
    begin
      TargetEvent;
    end);
  X := Player.X;
  Y := Player.Y;
  Z := Player.Z;
end;

class procedure TMedalTag.ReDraw;
begin
  if MedalTag <> nil then
    MedalTag.IsReDraw := True;
end;

procedure TMedalTag.DoDraw;
var
  WX, WY: Integer;
begin
  if TMap.ShowChar then
  begin
    WX := Round(Player.X) - Round(Engine.WorldX);
    WY := Round(Player.Y) - Round(Engine.WorldY);
    GameCanvas.Draw(TargetTexture, WX - 150, WY + 5);
  end;
  if IsReDraw then
    IsReDraw := False;
end;

procedure FixAlphaChannel(Texture: TTexture);
var
  x, y: Integer;
  A, R, G, B: Word;
  P: PLongWord;
  Surface: TRasterSurface;
  SurfParams: TRasterSurfaceParameters;
begin
  var Width := Texture.Parameters.Width;
  var Height := Texture.Parameters.Height;
  Surface := RasterSurfaceInit(Width, Height, TPixelFormat.RGBA8);
  SurfParams := Surface.Parameters;
  Texture.Save(Surface, 0, ZeroPoint2i, ZeroIntRect);
  Texture.Clear;

  for y := 0 to Texture.Parameters.Height - 1 do
  begin
    P := SurfParams.Scanline[y];
    for x := 0 to Texture.Parameters.Width - 1 do
    begin
      R := GetR(P^);
      G := GetG(P^);
      B := GetB(P^);
      A := GetA(P^);
      if A > 150 then
        A := 255;
      P^ := cRGB1(R, G, B, A);
      Inc(P);
    end;
  end;

  Texture.Copy(Surface, 0, ZeroPoint2i, ZeroIntRect);
  Surface.Free;
end;

procedure TMedalTag.TargetEvent;
begin
  if TMap.ShowChar then
  begin
    var WestImage := EquipData[Entry.GetPath + '/w'];
    var WestX := 150 - (CenterLength + EastWidth + WestWidth) div 2;

    FixAlphaChannel(EquipImages[WestImage]);
    Engine.Canvas.Draw(EquipImages[WestImage], WestX, -WestImage.Get('origin').Vector.Y + 38, False);

    var CenterImage := EquipData[Entry.GetPath + '/c'];
    var Count := CenterLength div CenterWidth;
    FixAlphaChannel(EquipImages[CenterImage]);
    for var i := 1 to Count do
      Engine.Canvas.Draw(EquipImages[CenterImage], WestX + ((i - 1) * CenterWidth) + WestWidth, -
        CenterImage.Get('origin').Vector.Y + 38);

    var OffX: Integer;
    case CenterWidth of
      1:
        OffX := 0;
      2:
        OffX := 1;
      3..5:
        OffX := 4;
      6..13:
        OffX := 5;

      14:
        OffX := 12;
      20:
        OffX := 18;
    end;

    var EastImage := EquipData[Entry.GetPath + '/e'];
    FixAlphaChannel(EquipImages[EastImage]);
    GameCanvas.Draw(EquipImages[EastImage], WestX + CenterLength + WestWidth - OffX, -EastImage.Get('origin').Vector.Y
      + 38);

    //GameCanvas.Flush;
    //FontsAlt[1].TextOut(MedalName, WestX + WestWidth + 2, 36, ARGB(255, R, G, B));
    GameFont.Draw(Point2f( WestX + WestWidth + 2, 36),MedalName,ARGB(255,R,G,B));
   // GameCanvas.Flush;
  end;
end;

procedure TMedalTag.InitData;
begin
  EastWidth := Entry.Get2('e').Canvas.Width;
  WestWidth := Entry.Get2('w').Canvas.Width;
  CenterWidth := Entry.Get2('c').Canvas.Width;
  //CenterLength := FontsAlt[1].TextWidth(MedalName) + 5;
 CenterLength := Round(GameFont.ExtentByPixels(MedalName).Right)+5;
  TagWidth := CenterLength + EastWidth + WestWidth + 30;

  var TagHeight := Entry.Get('w').Canvas.Height + 30;

  if Entry.Get('clr') <> nil then
    FontColor := 16777216 + Integer(Entry.Get('clr').Data)
  else
    FontColor := 16777215;
  R := GetR(FontColor);
  G := GetG(FontColor);
  B := GetB(FontColor);
  GameCanvas.DrawTarget(TargetTexture, 300, 100,
    procedure
    begin
      TargetEvent;
    end);

//  TargetIndex := AvatarTargets.Add(1, 300, 100, apf_A8R8G8B8, True, True);
 // GameDevice.RenderTo(TargetEvent, 0, True, AvatarTargets[TargetIndex]);

end;

class procedure TMedalTag.Create(ItemID: string);
begin
  MedalTag := TMedalTag.Create(SpriteEngine);
  with MedalTag do
  begin
    TruncMove := True;
    Tag := 1;
    var TagNum := GetImgEntry('Character.wz/Accessory/' + ItemID + '.img/info').Get('medalTag', '');
    Entry := GetImgEntry('UI.wz/NameTag.img/medal/' + string(TagNum));
    DumpData(Entry, EquipData, EquipImages);
    MedalName := GetImgEntry('String.wz/Eqp.img/Eqp/Accessory/' + RightStr(ItemID, 7)).Get('name', '');
    InitData;
  end;

end;
//NickNameTag

class procedure TNickNameTag.Delete;
begin
  if NickNameTag <> nil then
  begin
    NickNameTag.Dead;

  end;
end;

procedure TNickNameTag.DoDraw;
var
  WX, WY: Integer;
begin
  if TMap.ShowChar then
  begin
    WX := Round(Player.X) - Round(Engine.WorldX);
    WY := Round(Player.Y) - Round(Engine.WorldY);
    GameCanvas.Draw(TargetTexture, WX - 150, WY - 150);
  end;
  if IsReDraw then
    IsReDraw := False;
end;

class procedure TNickNameTag.ReDraw;
begin
  if NickNameTag <> nil then
    NickNameTag.IsReDraw := True;
end;

class procedure TNickNameTag.Create(ItemID: string);
begin
  NickNameTag := TNickNameTag.Create(SpriteEngine);

  with NickNameTag do
  begin
    TruncMove := True;
    Tag := 1;
    var TagNum := GetImgEntry('Item.wz/Install/0370.img/' + ItemID + '/info').Get('nickTag', '');
    Entry := GetImgEntry('UI.wz/NameTag.img/nick/' + string(TagNum));
    DumpData(Entry, EquipData, EquipImages);
    MedalName := GetImgEntry('String.wz/Ins.img/' + RightStr(ItemID, 7)).Get('name', '');
    InitData;
  end;

end;

//Label Ring Tag
class procedure TLabelRingTag.Delete;
begin
  if LabelRingTag <> nil then
  begin
    LabelRingTag.Dead;
  end;
end;

procedure TLabelRingTag.DoDraw;
var
  WX, WY: Integer;
begin
  if TMap.ShowChar then
  begin
    WX := Round(Player.X) - Round(Engine.WorldX);
    WY := Round(Player.Y) - Round(Engine.WorldY);
    GameCanvas.Draw(TargetTexture, WX - 150, WY - 28);
  end;
  if IsReDraw then
    IsReDraw := False;
end;

class procedure TLabelRingTag.ReDraw;
begin
  if LabelRingTag <> nil then
    LabelRingTag.IsReDraw := True;
end;

class procedure TLabelRingTag.Create(ItemID: string);
begin
  LabelRingTag := TLabelRingTag.Create(SpriteEngine);

  with LabelRingTag do
  begin
    TruncMove := True;
    Tag := 1;
    var TagNum := GetImgEntry('Character.WZ/Ring/' + ItemID + '.img/info').Get('nameTag', '');
    Entry := GetImgEntry('UI.wz/NameTag.img/' + string(TagNum));
    DumpData(Entry, EquipData, EquipImages);
    MedalName := ShowOptionForm.Edit1.Text;
    InitData;
  end;

end;

end.

