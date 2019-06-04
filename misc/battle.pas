unit battle;

interface

uses
  Classes, Windows, SysUtils, Math;

type
  TBattle = class;
  TPlayer = class;
  TShipsGroup = class;

  TSList = class
  private
    FList: TList;
    FUpdating: Integer;
    function IndexOf(P: Pointer; var Index: Integer): Boolean;
    function GetCount: Integer;
    function Get(Index: Integer): Pointer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    procedure Add(P: Pointer);
    function Remove(P: Pointer): Integer;
    function RandomItem: Pointer;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: Pointer read Get; default;
    property List: TList read FList;
  end;

  TKill = record
    Group: TShipsGroup;
    DestroyedGroup: TShipsGroup;
    Count: Integer;
  end;

  TDamageTypes = record
    EM: Smallint;
    Explosive: Smallint;
    Kinetic: Smallint;
    Thermal: Smallint;
  end;

  TModTypes = record
    Hull, Shield, Handling, Tracking_speed, Damage: Word;
  end;

  // A fleet has to be split in multiple groups to give them objectives and targets
  TShipsGroup = class
  private
    FBefore: Integer;
    FKilled: Integer;

    function PrioritySort(Ship1, Ship2: TShipsGroup): Integer;
    function GetLoss: Integer;
  protected
    FBaseHandling: Single;
    FBaseHull: Word;
    FBaseShield: Word;
    FBaseWeapon_tracking_speed: Word;

    FOwner: TPlayer;
    FFleetid: Cardinal;
    FId: Cardinal;
    FHull: Single;
    FShield: Single;
    FHandling: Word;

    FTech: Byte;

    FWeapon_ammo: Word;
    FWeapon_damage: TDamageTypes;
    FWeapon_tracking_speed: Word;
    FWeapon_turrets: Word;

    FResistances: TDamageTypes;

    Fmod_hull, Fmod_shield, Fmod_handling, Fmod_tracking_speed, Fmod_damage: Word;
    Fmult_hull, Fmult_shield, Fmult_handling, Fmult_tracking_speed, Fmult_damage: Single;

    FWeaponDamages: Single; // theorical damages done by this kind of ships

    FIndex: Integer;
    FDamages: Single; // damages done by this group to other ships


    FGroupThreat: Single;

    FBestHandlingTarget: Integer;
    FPrecision: Integer; // Precision when firing : Handling + weapon_tracking_speed
    FShieldRegeneration: Cardinal;

    FCurrentTarget: TShipsGroup; // Current target

    FHasPriorityTargets: Boolean;

    FShipLoss: Cardinal;

    FRemainingAmmo: Word;
    FRemainingShips: Cardinal;
    FShipsForRound: Cardinal;

    FMiss: Cardinal;
    FHit: Cardinal;

    FUnitHull: Single;
    FUnitShield: Single;

    FChangeTargetIn: Integer;

    function GetDamages: Integer;

    function GetTarget: TShipsGroup;
    function FindTarget: TShipsGroup;

    procedure ShipDestroyed();
    procedure EnemyShipDestroyed(Group: TShipsGroup);

    function GetKill(index: Integer): TKill;
  public
    FKillList: array of TKill;

    constructor Create(Owner: TPlayer; Fleetid, Shipid: Cardinal;
                       Hull, Shield: Cardinal;
                       Handling, Weapon_ammo, Weapon_tracking_speed, Weapon_turrets: Word; Weapon_damage: TDamageTypes;
                       Mods: TModTypes; Resistances: TDamageTypes;
                       Quantity: Cardinal; Tech: Byte);
    destructor Destroy; override;

    procedure Init;

    function Fight2(): Boolean;
    procedure NewRound;
    procedure NewSubRound;

    property Owner: TPlayer read FOwner;
    property Fleetid: Cardinal read FFleetid;
    property ShipId: Cardinal read FId;

    property Before: Integer read FBefore;
    property Loss: Integer read GetLoss;
    property Killed: Integer read FKilled;
    property Damages: Integer read GetDamages;
    property Miss: Cardinal read FMiss;
    property Hit: Cardinal read FHit;

    property mod_hull: Word read Fmod_hull;
    property mod_shield: Word read Fmod_shield;
    property mod_handling: Word read Fmod_handling;
    property mod_tracking_speed: Word read Fmod_tracking_speed;
    property mod_damage: Word read Fmod_damage;
  end;

  TCombatLog = class
  public
    Round: Byte;
    PlayerId: Cardinal;
    ShipId: Cardinal;
    TargetPlayerId: Cardinal;
    TargetShipId: Cardinal;
  end;

  TPlayer = class
  private
    FBattle: TBattle;
    FId: Cardinal;

    FShipCount: Integer;

    FEnemies: TList;      // List of enemy TPlayer
    FEnemyGroups: TList;  // List of enemy TShipsGroup

    FGroups: TList;       // Ships grouped by type
    FIsWinner: Boolean;

    FSkipEvery: Integer;  // Skip a ship activation every FSkipEvery ship actions
    FShipActivations: Integer;

    FAggressive: Boolean;

    FLastLog: TCombatLog;
  public
    constructor Create(Battle: TBattle; AId: Cardinal);
    destructor Destroy; override;

    procedure AddShip(Fleetid, Shipid: Cardinal;
                       Hull, Shield: Cardinal;
                       handling, weapon_ammo, weapon_tracking_speed, weapon_turrets: Word; weapon_damage: TDamageTypes;
                       Mods: TModTypes; Resistances: TDamageTypes;
                       Quantity: Cardinal; FireAtWill: Boolean; Tech: Byte);
    procedure Init;
    procedure Over;

    procedure ShipDestroyed(Target: TShipsGroup);

    function Fight2(): Boolean;
    procedure NewRound;
    procedure NewSubRound;

    property Aggressive: Boolean read FAggressive;
    property Id: Cardinal read FId;
    property IsWinner: Boolean read FIsWinner;
  end;

  TBattle = class
  private
    FPlayers: TList;
    FGroupList: TList; // List of all groups

    FKillList: array of TKill;

    FRounds: Integer;
    FEnemyShipsRemaining: Boolean;

    FCombatLog: TList;
    FCombatLogEnabled: Boolean;

    FBattleStart: Cardinal;
    FBattleEnd: Cardinal;

    function GetPlayer(Id: Cardinal): TPlayer;
    function Fire(Ship, Target: TShipsGroup; ChanceToHit, Damage: Extended): Boolean;
    procedure ShipDestroyed(Target, ByGroup: TShipsGroup);
    procedure NewRound;
    function GetDestroyedShips(index: Integer): TKill;
    function GetDestroyedShipsCount: Integer;
    function SortGroupsByFirstShooter(Ship1, Ship2: TShipsGroup): Integer;
    function SortGroupsByOwnerId(Ship1, Ship2: TShipsGroup): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddShips(Ownerid, Fleetid, Shipid, Hull, Shield: Cardinal;
                       handling, weapon_ammo, weapon_tracking_speed, weapon_turrets: Word; weapon_damage: TDamageTypes;
                       Mods: TModTypes; Resistances: TDamageTypes;
                       Quantity: Cardinal; FireAtWill: Boolean; Tech: Byte);
    // set relation between players to friend
    procedure SetRelation(Ownerid1, Ownerid2: Cardinal);
    procedure BeginFight;
    function NextRound(MaxRounds: Integer=1): Boolean;
    procedure EndFight;
    function CanFight: Boolean;

    property BattleStart: Cardinal read FBattleStart;
    property BattleEnd: Cardinal read FBattleEnd;

    property CombatLog: TList read FCombatLog;
    property CombatLogEnabled: Boolean read FCombatLogEnabled write FCombatLogEnabled;

    property DestroyedShips[index: Integer]: TKill read GetDestroyedShips;
    property DestroyedShipsCount: Integer read GetDestroyedShipsCount;

    property GroupList: TList read FGroupList;
    property EnemyShipsRemaining: Boolean read FEnemyShipsRemaining;
    property Rounds: Integer read FRounds;
  end;

function GetChanceToHit(WeaponTracking, TargetHandling: Extended; Tech, TargetTech: Byte): Extended;
function GetWeaponDamage(WeaponDamage, ShipResistance: TDamageTypes): Extended;

function AverageHitsToKill(WeaponDamage: TDamageTypes; WeaponTrackingSpeed, TargetHull, TargetShield, TargetHandling: Extended; TargetResistance: TDamageTypes; Tech, TargetTech: Byte): Extended;
function AverageHitsOn(WeaponDamage: TDamageTypes; WeaponTrackingSpeed, TargetHull, TargetShield, TargetHandling: Extended; TargetResistance: TDamageTypes; Tech, TargetTech: Byte): Extended;

function DamageTypes(EM, Explosive, Kinetic, Thermal: Smallint): TDamageTypes;
function ModTypes(Hull, Damage, Handling, Shield, Tracking_speed: Word): TModTypes;
   {
var
  t1: Int64 = 0;
  t2: Int64 = 0;
  t3: Int64 = 0;
  t4: Int64 = 0;  }

implementation

function DamageTypes(EM, Explosive, Kinetic, Thermal: Smallint): TDamageTypes;
begin
  Result.EM := EM;
  Result.Explosive := Explosive;
  Result.Kinetic := Kinetic;
  Result.Thermal := Thermal;
end;

function ModTypes(Hull, Damage, Handling, Shield, Tracking_speed: Word): TModTypes;
begin
  Result.Damage := Damage;
  Result.Handling := Handling;
  Result.Hull := Hull;
  Result.Shield := Shield;
  Result.Tracking_speed := Tracking_speed;
end;

type
  TShipListSortCompare = function(Item1, Item2: TShipsGroup): Integer of object;

procedure QuickSort(SortList: PPointerList; L, R: Integer;
  SCompare: TShipListSortCompare);
var
  I, J: Integer;
  P, T: Pointer;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SCompare(SortList^[I], P) < 0 do
        Inc(I);
      while SCompare(SortList^[J], P) > 0 do
        Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(SortList, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure SortList(List: TList; Compare: TShipListSortCompare);
begin
  if (List <> nil) and (List.List <> nil) and (List.Count > 0) then
    QuickSort(List.List, 0, List.Count-1, Compare);
end;

function GetChanceToHit(WeaponTracking, TargetHandling: Extended; Tech, TargetTech: Byte): Extended;
var
  ChanceHit, ChanceDodge, ChanceEvade: Single;
begin
  if TargetHandling = 1 then
  begin
    Result := 1.0;
    Exit;
  end;

  ChanceHit := WeaponTracking / 1000;
  ChanceDodge := TargetHandling / 1000;
  ChanceEvade := (TargetHandling - WeaponTracking) / 1000;

  if ChanceHit > 1 then
  begin
    ChanceDodge := ChanceDodge - (ChanceHit-1);
    ChanceHit := 1;
  end;

  while Tech < TargetTech do
  begin
   // ChanceDodge := ChanceDodge * 1.25;
   // ChanceEvade := ChanceEvade * 1.25;
    ChanceHit := ChanceHit * 0.85;

    Inc(Tech);
  end;

  while Tech > TargetTech do
  begin
   // ChanceDodge := ChanceDodge * 1.25;
   // ChanceEvade := ChanceEvade * 1.25;
    ChanceHit := ChanceHit * 1.10;
    Dec(Tech);
  end;

  if ChanceDodge < 0 then ChanceDodge := 0;
  if ChanceDodge > 0.90 then ChanceDodge := 0.90;

  if ChanceEvade < 0 then ChanceEvade := 0;
  if ChanceEvade > 0.90 then ChanceEvade := 0.90;

  Result :=  ChanceHit * (1-ChanceDodge) * (1-ChanceEvade);

  if Result > 1 then Result := 1;
  if Result = 0 then Result := 0.0000001;
{
  Result := (WeaponTracking - TargetHandling) / 1000;
  if Result > 1 then Result := 1;
  if Result <= 0 then Result := 0.0000001;
  }
end;

// Compute damage according to resistance
function CompDamage(Damage, Resistance: Smallint): Extended;
var
  Protection: Extended;
begin
  // bigger damage reduces damage reduction
  // 100 damage reduce resistance by 10%
  //Resistance := Resistance - Damage / 10;

  Result := Damage;

  // Additional damage recution
  // damage = 1
  // resist = 20 (1/2 = 50% reduc)
  Protection := Resistance/10;
  if Protection > 0 then
  begin
    if Result < Protection then Result := Result*(Result/Protection);
  end;

  Result := Max(Result * (1 - Resistance/100), 0);
end;

function GetWeaponDamage(WeaponDamage, ShipResistance: TDamageTypes): Extended;
begin
  if (WeaponDamage.EM = 0) and (WeaponDamage.Explosive = 0) and (WeaponDamage.Kinetic = 0) and (WeaponDamage.Thermal = 0) then
  begin
    Result := 0;
    Exit;
  end;

  if (ShipResistance.EM = 0) and (ShipResistance.Explosive = 0) and (ShipResistance.Kinetic = 0) and (ShipResistance.Thermal = 0) then
  begin
    Result := WeaponDamage.EM + WeaponDamage.Explosive + WeaponDamage.Kinetic + WeaponDamage.Thermal;
    Exit;
  end;

  Result := CompDamage(WeaponDamage.EM, ShipResistance.EM) +
            CompDamage(WeaponDamage.Explosive, ShipResistance.Explosive) +
            CompDamage(WeaponDamage.Kinetic, ShipResistance.Kinetic) +
            CompDamage(WeaponDamage.Thermal, ShipResistance.Thermal);
end;

function AverageHitsToKill(WeaponDamage: TDamageTypes; WeaponTrackingSpeed, TargetHull, TargetShield, TargetHandling: Extended; TargetResistance: TDamageTypes; Tech, TargetTech: Byte): Extended;
var
  total_hp: Extended;
  damage: Extended;
begin
  total_hp := TargetHull + TargetShield;
  damage := Min(GetWeaponDamage(WeaponDamage, TargetResistance), total_hp);

  Result := total_hp / ( Max(damage, 0.00001) * GetChanceToHit(WeaponTrackingSpeed, TargetHandling, Tech, TargetTech) );

  if Result = 0 then Result := MaxInt;
end;

function AverageHitsOn(WeaponDamage: TDamageTypes; WeaponTrackingSpeed, TargetHull, TargetShield, TargetHandling: Extended; TargetResistance: TDamageTypes; Tech, TargetTech: Byte): Extended;
var
  total_hp: Extended;
  damage: Extended;
begin
  total_hp := TargetHull + TargetShield;
  damage := Min(GetWeaponDamage(WeaponDamage, TargetResistance), total_hp);

  Result := Max(damage, 0.00001) * GetChanceToHit(WeaponTrackingSpeed, TargetHandling, Tech, TargetTech);
end;

function TShipsGroup.PrioritySort(Ship1, Ship2: TShipsGroup): Integer;
var
  Sc1, Sc2: Extended;
begin
{
  Sc1 := ( FWeapon_turrets / AverageHitsToKill(FWeapon_damage, FBaseWeapon_tracking_speed, Ship1.Group.FHull, Ship1.Group.FBaseShield, Ship1.Group.FBaseHandling, Ship1.Group.FResistances) ) *
         ( Ship1.Group.FWeapon_turrets / AverageHitsToKill(Ship1.Group.FWeapon_damage, Ship1.Group.FBaseWeapon_tracking_speed, FHull, FBaseShield, FBaseHandling, FResistances) );

  Sc2 := ( FWeapon_turrets / AverageHitsToKill(FWeapon_damage, FBaseWeapon_tracking_speed, Ship2.Group.FHull, Ship2.Group.FBaseShield, Ship2.Group.FBaseHandling, Ship2.Group.FResistances) ) *
         ( Ship2.Group.FWeapon_turrets / AverageHitsToKill(Ship2.Group.FWeapon_damage, Ship2.Group.FBaseWeapon_tracking_speed, FHull, FBaseShield, FBaseHandling, FResistances) );
}

  Sc1 := AverageHitsOn(FWeapon_damage, FBaseWeapon_tracking_speed, Ship1.FBaseHull, Ship1.FBaseShield, Ship1.FBaseHandling, Ship1.FResistances, FTech, Ship1.FTech);
  Sc2 := AverageHitsOn(FWeapon_damage, FBaseWeapon_tracking_speed, Ship2.FBaseHull, Ship2.FBaseShield, Ship2.FBaseHandling, Ship2.FResistances, FTech, Ship2.FTech);

  if Sc1 > Sc2 then
    Result := -1
  else
  if Sc1 < Sc2 then
    Result := 1
  else
    Result := 0;
end;

procedure ShuffleList(List: TList);
var
  I: Integer;
  Count: Integer;
  B: Boolean;
begin
  Count := List.Count;
  B := False;

  for I := 0 to Count-1 do
  begin
    List.Exchange(I, Random(Count));
    if B then
    begin
      List.Exchange(I, (Count-1 + I) div 2);
      B := False;
    end
    else
      B := True;
  end;
end;

{ TBattle }

procedure TBattle.AddShips(Ownerid, Fleetid, Shipid, Hull, Shield: Cardinal;
  handling, weapon_ammo, weapon_tracking_speed, weapon_turrets: Word; weapon_damage: TDamageTypes;
  Mods: TModTypes; Resistances: TDamageTypes;
  Quantity: Cardinal; FireAtWill: Boolean; Tech: Byte);
var
  P: TPlayer;
begin
  P := GetPlayer(Ownerid);

  P.AddShip(Fleetid, Shipid, Hull, Shield, Handling,
            weapon_ammo, weapon_tracking_speed, weapon_turrets, weapon_damage,
            Mods, Resistances,
            quantity, FireAtWill, Tech);
end;

procedure TBattle.BeginFight;
var
  I: Integer;
begin
  FBattleStart := GetTickCount;

  for I := 0 to FCombatLog.Count-1 do
    TCombatLog(FCombatLog[I]).Free;
  FCombatLog.Clear;
  FRounds := 0;

  for I := 0 to FPlayers.Count-1 do
    TPlayer(FPlayers[I]).Init;

  // sort the group list to know who shoot first
  SortList(FGroupList, SortGroupsByFirstShooter);
end;

// Return if a fight can happen
// no fight can happen if everyone is friend
function TBattle.CanFight: Boolean;
var
  I, J: Integer;
begin
  for I := 0 to FPlayers.Count-1 do
  begin
    if TPlayer(FPlayers[I]).FShipCount > 0 then
    for J := 0 to TPlayer(FPlayers[I]).FEnemies.Count-1 do
      if TPlayer(TPlayer(FPlayers[I]).FEnemies[J]).FShipCount > 0 then
      begin
        Result := True;
        Exit;
      end;
  end;

  Result := False;
end;

constructor TBattle.Create;
begin
  Randomize;

  FCombatLog := TList.Create;

  FGroupList := TList.Create;
  FPlayers := TList.Create;
end;

destructor TBattle.Destroy;
var
  I: Integer;
begin
  for I := 0 to FCombatLog.Count-1 do
    TCombatLog(FCombatLog[I]).Free;
  FCombatLog.Free;

  for I := 0 to FPlayers.Count-1 do
    TPlayer(FPlayers[I]).Free;

  FPlayers.Free;
  
  FGroupList.Free;

  inherited;
end;

procedure TBattle.EndFight;
var
  I, J, L: Integer;
  List: TSList;
  Group: TShipsGroup;
begin
  // battle is over
  for I := 0 to FPlayers.Count-1 do
    TPlayer(FPlayers[I]).Over;

  // Sort groups by owner
  SortList(FGroupList, SortGroupsByOwnerId);

  for I := 0 to FGroupList.Count-1 do
  begin
    Group := TShipsGroup(FGroupList[I]);

    for J := 0 to High(Group.FKillList) do
    begin
      L := Length(FKillList);

      SetLength(FKillList, L+1);
      FKillList[L] := Group.FKillList[J];
    end;
  end;

  FBattleEnd := GetTickCount;
end;

function TBattle.NextRound(MaxRounds: Integer): Boolean;
var
  R, I: Integer;
  AmmoRemaining, StillFighting: Boolean;
begin
  Result := CanFight();

  if not Result then Exit;

  // rounds
  for R := 1 to MaxRounds do
  begin
    NewRound;

    repeat
      AmmoRemaining := False;

      // prepare players for a new subround
      for I := 0 to FPlayers.Count-1 do
        TPlayer(FPlayers[I]).NewSubRound;

      // Make every group fire
      for I := 0 to FGroupList.Count-1 do
        if TShipsGroup(FGroupList[I]).Fight2() then
          AmmoRemaining := true;

    until not AmmoRemaining;

    if not CanFight() then
    begin
      Result := False;
      Break;
    end;
  end;
end;

// Return whether it hits or not
function TBattle.Fire(Ship, Target: TShipsGroup; ChanceToHit, Damage: Extended): Boolean;
var
  X: Extended;
begin
  Result := False;

  if FCombatLogEnabled then
  begin
    if (Ship.Owner.FLastLog = nil) or (Ship.Owner.FLastLog.ShipId <> Ship.FId) or (Ship.Owner.FLastLog.TargetPlayerId <> Target.Owner.Id) or (Ship.Owner.FLastLog.TargetShipId <> Target.FId) then
    begin
      Ship.Owner.FLastLog := TCombatLog.Create;
      Ship.Owner.FLastLog.PlayerId := Ship.Owner.FId;
      Ship.Owner.FLastLog.ShipId := Ship.FId;
      Ship.Owner.FLastLog.TargetPlayerId := Target.Owner.FId;
      Ship.Owner.FLastLog.TargetShipId := Target.FId;
      FCombatLog.Add(Ship.Owner.FLastLog);
    end;
  end;

  X := Random;
  if X > ChanceToHit then
  begin
    Inc(Ship.FMiss);
    Exit; // Missed !
  end;

  Inc(Ship.FHit);

  Result := True;

  if Target.FUnitShield > 0 then Damage := Damage * 0.75;

  if Damage > Target.FUnitShield then
  begin
    Ship.FDamages := Ship.FDamages + Target.FUnitShield;
    Damage := Damage - Target.FUnitShield;

    Target.FUnitShield := 0;

    Damage := Damage * Ship.Fmult_damage;

    if Damage > Target.FUnitHull then
    begin
      Ship.FDamages := Ship.FDamages + Target.FUnitHull;
      Target.FUnitHull := 0;
    end
    else
    begin
      Ship.FDamages := Ship.FDamages + Damage;
      Target.FUnitHull := Target.FUnitHull - Damage;
    end;

    if Target.FUnitHull = 0 then
      ShipDestroyed(Target, Ship)
  end
  else
  begin
    Target.FUnitShield := Target.FUnitShield - Damage;
    Ship.FDamages := Ship.FDamages + Damage;
  end;
end;

function TBattle.GetDestroyedShips(index: Integer): TKill;
begin
  Result := FKillList[index];
end;

function TBattle.GetDestroyedShipsCount: Integer;
begin
  Result := Length(FKillList);
end;

function TBattle.GetPlayer(Id: Cardinal): TPlayer;
var
  I: Integer;
begin
  // retrieve combatant if already exists
  for I := 0 to FPlayers.Count-1 do
    if TPlayer(FPlayers[I]).Id = Id then
    begin
      Result := TPlayer(FPlayers[I]);
      Exit;
    end;

  // Create a new combatant
  Result := TPlayer.Create(Self, Id);

  FPlayers.Add(Result);

  // Add it as an enemy for other combatant
  for I := 0 to FPlayers.Count-1 do
    if FPlayers[I] <> Result then
    begin
      TPlayer(FPlayers[I]).FEnemies.Add(Result);
      Result.FEnemies.Add(FPlayers[I]);
    end;
end;

procedure TBattle.NewRound;
var
  I: Integer;
  LLog: TCombatLog;
begin
  Inc(FRounds);

  // Notice each opponent that a new round begin
  for I := 0 to FPlayers.Count-1 do
    TPlayer(FPlayers[I]).NewRound;

  if FCombatLogEnabled then
  begin
    LLog := TCombatLog.Create;
    LLog.Round := FRounds;

    FCombatLog.Add(LLog);
  end;
end;

procedure TBattle.SetRelation(Ownerid1, Ownerid2: Cardinal);
var
  P1, P2: TPlayer;
begin
  P1 := GetPlayer(Ownerid1);
  P2 := GetPlayer(Ownerid2);

  P1.FEnemies.Remove(P2);
  P2.FEnemies.Remove(P1);
end;

procedure TBattle.ShipDestroyed(Target, ByGroup: TShipsGroup);
var
  Player: TPlayer;
begin
  Player := TPlayer(Target.FOwner);

  Target.ShipDestroyed;

  ByGroup.EnemyShipDestroyed(Target);
end;

// sort the groups by "first shooter" order
function TBattle.SortGroupsByFirstShooter(Ship1, Ship2: TShipsGroup): Integer;
begin
  if Ship1.FTech > Ship2.FTech then
    Result := 1
  else
  if Ship1.FTech < Ship2.FTech then
    Result := -1
  else
  begin
    if Ship1.FWeapon_ammo > Ship2.FWeapon_ammo then
      Result := 1
    else
    if Ship1.FWeapon_ammo < Ship2.FWeapon_ammo then
      Result := -1
    else
      Result := 0;
  end;
end;

function TBattle.SortGroupsByOwnerId(Ship1, Ship2: TShipsGroup): Integer;
begin
  if Ship1.Owner.Id < Ship2.Owner.Id then
    Result := -1
  else
  if Ship1.Owner.Id > Ship2.Owner.Id then
    Result := 1
  else
    Result := 0;
end;

{ TPlayer }

procedure TPlayer.AddShip(Fleetid, Shipid: Cardinal;
  Hull, Shield: Cardinal;
  handling, weapon_ammo, weapon_tracking_speed, weapon_turrets: Word; weapon_damage: TDamageTypes;
  Mods: TModTypes; Resistances: TDamageTypes;
  Quantity: Cardinal; FireAtWill: Boolean; Tech: Byte);
var
  Grp: TShipsGroup;
begin
  FAggressive := FAggressive or FireAtWill;

  Grp := TShipsGroup.Create(Self, Fleetid, Shipid, Hull, Shield, Handling,
                            weapon_ammo, weapon_tracking_speed, weapon_turrets, weapon_damage,
                            Mods, Resistances,
                            Quantity, Tech);
  FGroups.Add(Grp);
  FBattle.FGroupList.Add(Grp)
end;

constructor TPlayer.Create(Battle: TBattle; AId: Cardinal);
begin
  FAggressive := False;

  FBattle := Battle;
  FId := AId;

  FEnemies := TList.Create;
  FEnemyGroups := TList.Create;

  FShipCount := 0;

  FGroups := TList.Create;

  FIsWinner := False;

  FShipActivations := 0;
  FSkipEvery := 0;
end;

destructor TPlayer.Destroy;
var
  I: Integer;
begin
  FEnemies.Free;
  FEnemyGroups.Free;

  for I := 0 to FGroups.Count-1 do
    TShipsGroup(FGroups[I]).Free;
  FGroups.Free;

  inherited;
end;

function TPlayer.Fight2(): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to FGroups.Count-1 do
    if TShipsGroup(FGroups[I]).Fight2() then
      Result := True;
end;

procedure TPlayer.Init;
var
  I, J: Integer;
  P: TPlayer;
begin
  // Remove enemies that are not aggressive if we are not aggressive
  if not FAggressive then
  begin
    for I := FEnemies.Count-1 downto 0 do
    begin
      if not TPlayer(FEnemies[I]).FAggressive then
        FEnemies.Delete(I);
    end;
  end;

  // Initialize the list of enemy groups
  for I := 0 to FEnemies.Count-1 do
  begin
    P := TPlayer(FEnemies[I]);

    for J := 0 to P.FGroups.Count-1 do
      FEnemyGroups.Add(P.FGroups[J]);
  end;

  ShuffleList(FEnemyGroups);

  // Init the groups
  for I := 0 to FGroups.Count-1 do
    TShipsGroup(FGroups[I]).Init;
end;

// Call NewRound for every ship group
procedure TPlayer.NewRound;
var
  I: Integer;
begin
  for I := 0 to FGroups.Count-1 do
    TShipsGroup(FGroups[I]).NewRound;
end;

// Call NewSubRound for every ship group
procedure TPlayer.NewSubRound;
var
  I: Integer;
begin
  for I := 0 to FGroups.Count-1 do
    TShipsGroup(FGroups[I]).NewSubRound;
end;

// Called when battle is over
procedure TPlayer.Over;
var
  I: Integer;
  Grp: TShipsGroup;
begin
  FIsWinner := False;

  // Check if there are any enemy left
  for I := 0 to FEnemyGroups.Count-1 do
  begin
    Grp := TShipsGroup(FEnemyGroups[I]);

    if Grp.Before > Grp.Loss then
      Exit;
  end;

  // Check that some ships remain to be declared "winner"
  for I := 0 to FGroups.Count-1 do
  begin
    Grp := TShipsGroup(FGroups[I]);
    if Grp.FBefore > Grp.Loss then
    begin
      FIsWinner := True;
      Exit;
    end;
  end;
end;

procedure TPlayer.ShipDestroyed(Target: TShipsGroup);
begin
  Dec(FShipCount);
end;

{ TShipsGroup }

constructor TShipsGroup.Create(Owner: TPlayer; Fleetid, Shipid: Cardinal;
  Hull, Shield: Cardinal;
  Handling, Weapon_ammo, Weapon_tracking_speed, Weapon_turrets: Word; Weapon_damage: TDamageTypes;
  Mods: TModTypes; Resistances: TDamageTypes;
  Quantity: Cardinal; Tech: Byte);
var
  I: Integer;
begin
  FOwner := Owner;
  FId := ShipId;

  FTech := Tech;

  FRemainingShips := Quantity;

  Inc(FOwner.FShipCount, Quantity);

  FShipLoss := 0;

  FKilled := 0;

  // Assign ship stats
  FFleetid := Fleetid;
  FId := Shipid;
  FHull := Hull;

  FResistances := Resistances;
  FWeapon_damage := Weapon_damage;

  FBaseHandling := Handling;
  FBaseHull := Hull;
  FBaseShield := Shield;
  FBaseWeapon_tracking_speed := Weapon_tracking_speed;


  // Assign raw bonus
  Fmod_hull := Mods.Hull;
  Fmod_shield := Mods.Shield;
  Fmod_handling := Mods.Handling;
  Fmod_tracking_speed := Mods.Tracking_speed;
  Fmod_damage := Mods.Damage;


  Fmult_hull := Fmod_hull/100;

  // compute the effective multiplicator for each bonus
{
  if Fmod_shield > 100 then
    Fmult_shield := (100 + (Fmod_shield-100)/2) / 100
  else   }
    Fmult_shield := Fmod_shield/100;

  Fmult_handling := (100 + (Fmod_handling-100)/10) / 100;
  Fmult_tracking_speed := (100 + (Fmod_tracking_speed-100)/10) / 100;

  if Fmod_damage > 100 then
    Fmult_damage := (100 + (Fmod_damage-100)/10) / 100
  else
    Fmult_damage := Fmod_damage/100;

  //
  // Compute ship protection : shield < 100% can decrease it
  //
  FHull := Hull*Fmult_hull;
  FShield := Shield*Fmult_shield;          // compute the value of the shield
  FHandling := Trunc(Handling*Fmult_handling);// Max(Handling*Fmult_handling, 1);
  if FHandling <= 1 then FHandling := 1;


  FWeaponDamages := (weapon_damage.EM+weapon_damage.Explosive+weapon_damage.Kinetic+weapon_damage.Thermal) * Weapon_turrets * Log10(1+Weapon_tracking_speed);// / 10;

  FWeapon_ammo := Weapon_ammo;
  FWeapon_tracking_speed := Trunc(Weapon_tracking_speed*Fmult_tracking_speed);//mod_tracking_speed/100);
  FWeapon_turrets := Weapon_turrets;


  FPrecision := Weapon_tracking_speed;

  // Compute the type of target we want for this group
  FBestHandlingTarget := Trunc(FPrecision * 1.5);

  FHasPriorityTargets := True;

  FUnitHull := FHull;
  FUnitShield := FShield;

  FBefore := Quantity;
end;

destructor TShipsGroup.Destroy;
{var
  I: Integer;}
begin
{
  for I := 0 to FToFree.Count-1 do
    Dispose(FToFree[I]);

  FToFree.Free;
  FShips.Free;
  FTargets.Free;

  Dispose(FMainShip);
}
  inherited;
end;

function TShipsGroup.FindTarget: TShipsGroup;
var
  I, J, C: Integer;
  Grp: TShipsGroup;
  TargetList: TList;
begin
  TargetList := TList.Create;

  // Retrieve the possible targets from the list of enemy ships

  for I := 0 to FOwner.FEnemyGroups.Count-1 do
  begin
    Grp := TShipsGroup(FOwner.FEnemyGroups[I]);

    if (Grp.FWeaponDamages > 0) and (Grp.FRemainingShips > 0) then
    begin
      TargetList.Add(Grp);
    end;
  end;

  // If no prioritary targets, fill the secondary targets
  if TargetList.Count = 0 then
  begin
    FHasPriorityTargets := False;

    for I := 0 to FOwner.FEnemyGroups.Count-1 do
    begin
      Grp := TShipsGroup(FOwner.FEnemyGroups[I]);

      if (Grp.FRemainingShips > 0) then
      begin
        TargetList.Add(Grp);
      end;
    end;
  end;

  if TargetList.Count > 0 then
  begin
    // Sort the list by priority
    ShuffleList(TargetList);
    SortList(TargetList, PrioritySort);

    Result := TargetList[0];
  end
  else
    Result := nil;

  TargetList.Free;
end;

function TShipsGroup.GetTarget: TShipsGroup;
{var
  Index: Integer;
  A, B: Int64;}
begin
  if (FChangeTargetIn <= 0) or ((FCurrentTarget <> nil) and (FCurrentTarget.FRemainingShips <= 0)) then //or ((GetWeaponPenetration(FWeapon_power, FCurrentTarget.Group.FProtection) = 0) and (FCurrentTarget.Shield = 0)) then
    FCurrentTarget := nil;

  if FCurrentTarget = nil then
  begin
    FCurrentTarget := FindTarget;

    FChangeTargetIn := 10;
  end;
{
  Index := FTargets.Count-1;

  while (FCurrentTarget = nil) and (Index >= 0) do
  begin
    FCurrentTarget := PShip(FTargets[Index]);

    // Check if the target is still alive
    if FCurrentTarget.Hull = 0 then
    begin
      // Delete from our target list
      FTargets.Delete(Index);

      // If there's no more targets, try to re-fill it
      if Index = 0 then
      begin
//        QueryPerformanceCounter(A);

        FillTargetList;

//        QueryPerformanceCounter(B);

//        t4 := t4 + (B - A);

        Index := FTargets.Count-1;
      end;

      FCurrentTarget := nil;
    end;

    Dec(Index);
  end;            }

  Result := FCurrentTarget;
end;

procedure TShipsGroup.Init;
begin
end;

procedure TShipsGroup.NewRound;
var
  I: Integer;
begin
  FRemainingAmmo := FWeapon_ammo;
  FShipsForRound := FRemainingShips;
end;

function TShipsGroup.GetLoss: Integer;
begin
  Result := FShipLoss;
end;

procedure TShipsGroup.EnemyShipDestroyed(Group: TShipsGroup);
var
  I: Integer;
begin
  Dec(FChangeTargetIn);

  Inc(FKilled);

  for I := 0 to High(FKillList) do
    if FKillList[I].DestroyedGroup = Group then
    begin
      Inc(FKillList[I].Count);
      Exit;
    end;

  I := Length(FKillList);
  SetLength(FKillList, I+1);
  FKillList[I].Group := Self;
  FKillList[I].DestroyedGroup := Group;
  FKillList[I].Count := 1;
end;

function TShipsGroup.Fight2(): Boolean;
var
  I: Cardinal;
  LastTarget, Target: TShipsGroup;
  Hit, Dmg: Extended;
  A, B: Int64;
begin
  Result := False;
  if FRemainingAmmo = 0 then Exit;

  I := FShipsForRound * Min(FRemainingAmmo, FWeapon_Turrets);

  // remove number of ammo used
  if FRemainingAmmo >= FWeapon_Turrets then
    Dec(FRemainingAmmo, FWeapon_Turrets)
  else
    FRemainingAmmo := 0;

  LastTarget := nil;
  Hit := 0;
  Dmg := 0;

  while I > 0 do
  begin

//    QueryPerformanceCounter(A);

    Target := GetTarget;

//    QueryPerformanceCounter(B);

//    t1 := t1 + (B - A);


//    QueryPerformanceCounter(A);

    if Target = nil then Break;  // Target = nil when no more targets
    if (LastTarget <> Target) then
    begin
      Hit := GetChanceToHit(FWeapon_tracking_speed, Target.FHandling, FTech, Target.FTech);
      Dmg := GetWeaponDamage(FWeapon_damage, Target.FResistances);
      LastTarget := Target;
    end;

//    QueryPerformanceCounter(B);

//    t2 := t2 + (B - A);

    Result := True;

//    QueryPerformanceCounter(A);

    FOwner.FBattle.Fire(Self, Target, Hit, Dmg);

//    QueryPerformanceCounter(B);

//    t3 := t3 + (B - A);

    Dec(I);
  end;
end;

procedure TShipsGroup.NewSubRound;
begin

end;

function TShipsGroup.GetDamages: Integer;
begin
  Result := Round(Min(FDamages, 2000000000));
end;

function TShipsGroup.GetKill(index: Integer): TKill;
begin
  Result := FKillList[index];
end;

procedure TShipsGroup.ShipDestroyed();
begin
  Dec(FRemainingShips);
  Inc(FShipLoss);

  // Remove ship from owner shiplist
  FOwner.ShipDestroyed(Self);

  if FRemainingShips > 0 then
  begin
    FUnitHull := FHull;
    FUnitShield := FShield;
  end;
end;

{ TSList }

function SimpleListCompare(P1, P2: Pointer): Integer;
begin
  if P1 = P2 then
    Result := 0
  else
  if Cardinal(P1) > Cardinal(P2) then
    Result := 1
  else
    Result := -1
end;

procedure TSList.Add(P: Pointer);
var
  Index: Integer;
begin
  if FUpdating = 0 then
  begin
    if not IndexOf(P, Index) then
      FList.Insert(Index, P);
  end
  else
    FList.Add(P);
end;

procedure TSList.BeginUpdate;
begin
  Inc(FUpdating);
end;

constructor TSList.Create;
begin
  FList := TList.Create;
  FUpdating := 0;
end;

destructor TSList.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TSList.EndUpdate;
begin
  Dec(FUpdating);
  
  if FUpdating = 0 then
    FList.Sort(SimpleListCompare);
end;

function TSList.Get(Index: Integer): Pointer;
begin
  Result := FList[Index];
end;

function TSList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TSList.IndexOf(P: Pointer; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := FList.Count-1;
  while L <= H do
  begin
    I := (L + H) shr 1;

    C := SimpleListCompare(FList[I], P);

    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
      end;
    end;
  end;

  Index := L;
end;

function TSList.RandomItem: Pointer;
begin
  Result := FList[Random(FList.Count)];
end;

function TSList.Remove(P: Pointer): Integer;
begin
  if IndexOf(P, Result) then
    FList.Delete(Result)
  else
    Result := -1;
end;

end.

