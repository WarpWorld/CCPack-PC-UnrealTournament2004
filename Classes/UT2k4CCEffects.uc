Class UT2k4CCEffects extends Info;

var Mutator baseMutator;

const Success = 0;
const Failed = 1;
const NotAvail = 2;
const TempFail = 3;

const CCType_Test       = 0x00;
const CCType_Start      = 0x01;
const CCType_Stop       = 0x02;
const CCType_PlayerInfo = 0xE0; //Not used for us
const CCType_Login      = 0xF0; //Not used for us
const CCType_KeepAlive  = 0xFF; //Not used for us

var int behindTimer;
const BehindTimerDefault = 15;

var int speedTimer;
const SpeedTimerDefault = 60;
const SlowTimerDefault = 15;
const SingleSlowTimerDefault = 45;

var int meleeTimer;
const MeleeTimerDefault = 60;

var int vampireTimer;
const VampireTimerDefault = 60;

var int teamDamageTimer;
const TeamDamageTimerDefault = 60;
var bool teamDamageHoldingTeam;

var int headShotTimer;
const HeadShotTimerDefault = 60;

var int thornsTimer;
const ThornsTimerDefault = 60;

var int winHalfDmgTimer;
const WinHalfDmgTimerDefault = 60;

var int momentumTimer;
const MomentumTimerDefault = 60;

var int octoJumpTimer;
const OctoJumpTimerDefault = 60;
var int origNumJumps;

var int infAdrenalineTimer;
const InfAdrenalineTimerDefault = 60;

const MaxAddedBots = 10;
var Bot added_bots[10];
var int numAddedBots;

var int forceWeaponTimer;
const ForceWeaponTimerDefault = 60;
var class<Weapon> forcedWeapon;

var int bodyEffectTimer;
const BodyEffectTimerDefault = 60;
const BigHeadScale = 4.0;
const HiddenScale = 0.0;
const FatScale = 2.0;
const SkinnyScale = 0.5;
enum EBodyEffect
{
    BE_None,
    BE_BigHead,
    BE_Headless,
    BE_NoLimbs,
    BE_Fat,
    BE_Skinny,
    BE_PintSized
};
var EBodyEffect bodyEffect;

struct ZoneFriction
{
    var name zonename;
    var float friction;
};
var ZoneFriction zone_frictions[32];
const IceFriction = 0.25;
const NormalFriction = 8;
var int iceTimer;
const IceTimerDefault = 60;

struct ZoneGravity
{
    var name zonename;
    var vector gravity;
};
var ZoneGravity zone_gravities[32];
var vector NormalGravity;
var vector MoonGrav;
var int gravityTimer;
const GravityTimerDefault = 60;

struct ZoneWater
{
    var name zonename;
    var bool water;
};
var ZoneWater zone_waters[32];
var int floodTimer;
const FloodTimerDefault = 15;

struct ZoneFog
{
    var name  zonename;
    var bool  hasFog;
    var float fogStart;
    var float fogEnd;
};
var ZoneFog zone_fogs[32];
var int fogTimer;
const FogTimerDefault = 60;
const HeavyFogStart = 4.0;
const HeavyFogEnd   = 800.0;

var int bounceTimer;
const BounceTimerDefault = 60;
var Vector BouncyCastleVelocity;

var int hotPotatoTimer;
const HotPotatoTimerDefault = 60;
const HotPotatoMaxTime = 5;

var int tauntTimer;
const TauntTimerDefault = 60;
var name curTaunt;

var int redLightTimer;
var int indLightTime;
var bool redLightGrace;
const RedLightTimerDefault = 60;
const LightMinimumTime = 3;
const RedLightMaxTime = 7;
const GreenLightMaxTime = 20;
var bool greenLight;

var int blurTimer;
const BlurTimerDefault = 60;

var int cfgMinPlayers;

var bool bFat,bFast;
var string targetPlayer;

var bool isLocal;
var bool effectSelectInit;

replication
{
    reliable if ( Role == ROLE_Authority )
        behindTimer,speedTimer,meleeTimer,iceTimer,vampireTimer,floodTimer,forceWeaponTimer,bFat,bFast,forcedWeapon,numAddedBots,targetPlayer,GetEffectList,bodyEffectTimer,bodyEffect,gravityTimer,setLimblessScale,SetAllBoneScale,ModifyPlayer,SetPawnBoneScale,SetAllPlayerAnnouncerVoice,fogTimer,tauntTimer,hotPotatoTimer,teamDamageTimer,teamDamageHoldingTeam,headShotTimer,thornsTimer,winHalfDmgTimer,momentumTimer,redLightTimer,greenLight,indLightTime,octoJumpTimer;
}

function Init(Mutator baseMut)
{
    local int i;
    local DeathMatch game;

    game = DeathMatch(Level.Game);
    
    baseMutator = baseMut;
    
    NormalGravity=class'PhysicsVolume'.Default.Gravity;
    //FloatGrav=vect(0,0,0.15);
    MoonGrav=vect(0,0,-100);  
    BouncyCastleVelocity=vect(0,0,600);  

    isLocal = Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer;
    effectSelectInit = False;

    for (i=0;i<MaxAddedBots;i++){
        added_bots[i]=None;
    }

    if (game!=None)
    {
        cfgMinPlayers = game.MinPlayers;
    }
    
}

function SendCCMessage(string msg)
{
    local PlayerController p;
    local color c;
    
    c.R=0;
    c.G=255;
    c.B=0;


    foreach AllActors(class'PlayerController',p){
        p.ClearProgressMessages();
        p.SetProgressTime(4);
        p.SetProgressMessage(0,msg,c);
    }

}

function Broadcast(string msg)
{
    Level.Game.Broadcast(self,msg);
    SendCCMessage(msg);
}

function string GenerateRGBTextCode(int r, int g, int b)
{
    if (r<=0) r=1;
    if (g<=0) g=1;
    if (b<=0) b=1;

    if (r>255) r=255;
    if (g>255) g=255;
    if (b>255) b=255;

    return chr(27)$chr(r)$chr(g)$chr(b);
}

simulated function GetEffectList(out string effects[30], out int numEffects)
{
    local int i;
    local int hotPotatoRemaining;
    local xBombingRun brGame;
    local CrowdControlBombFlag ccBomb;

    if (behindTimer > 0) {
        effects[i]="Third-Person: "$behindTimer;
        i++;
    }
    if (speedTimer > 0) {
        if(bFast){
            effects[i]="Gotta Go Fast: "$speedTimer;
        } else {
            effects[i]="Gotta Go Slow";
            if (targetPlayer!=""){
                effects[i]=effects[i]$" ("$targetPlayer$")";
            }
            effects[i]=effects[i]$": "$speedTimer;
        }
        i++;
    }
    if (meleeTimer > 0) {
        effects[i]="Melee-Only: "$meleeTimer;
        i++;
    }
    if (gravityTimer > 0) {
        effects[i]="Low-Grav: "$gravityTimer;
        i++;
    }
    if (iceTimer > 0) {
        effects[i]="Ice Physics: "$iceTimer;
        i++;
    }
    if (floodTimer > 0) {
        effects[i]="Flood: "$floodTimer;
        i++;
    }
    if (fogTimer > 0) {
        effects[i]="Silent Hill: "$fogTimer;
        i++;
    }
    if (bounceTimer > 0) {
        effects[i]="Bouncy Castle: "$bounceTimer;
        i++;
    }
    if (hotPotatoTimer > 0) {
        effects[i]="Hot Potato: "$hotPotatoTimer;

        brGame=xBombingRun(Level.Game);
        if (brGame!=None){
            ccBomb = CrowdControlBombFlag(brGame.Bomb);
            if (ccBomb!=None && ccBomb.Holder!=None){
                hotPotatoRemaining = HotPotatoMaxTime - (Level.TimeSeconds - ccBomb.GrabTime) + 1;
                effects[i] $= " ("$hotPotatoRemaining$")";
            }
        }

        i++;
    }
    if (vampireTimer > 0) {
        effects[i]="Vampire: "$vampireTimer;
        i++;
    }
    if (teamDamageTimer > 0) {
        if (teamDamageHoldingTeam){
            effects[i]="Attacking";
        } else {
            effects[i]="Defending";
        }
        effects[i]$=" Team Double Damage: "$teamDamageTimer;
        i++;
    }
    if (headShotTimer > 0) {
        effects[i]="Head Shots Only: "$headShotTimer;
        i++;
    }
    if (thornsTimer > 0) {
        effects[i]="Thorns: "$thornsTimer;
        i++;
    }
    if (forceWeaponTimer > 0) {
        effects[i]="Forced "$forcedWeapon.default.ItemName$": "$forceWeaponTimer;
        i++;
    }
    if (bodyEffectTimer > 0) {
        if (bodyEffect==BE_BigHead){
            effects[i]="Big Head Mode: ";
        } else if (bodyEffect==BE_NoLimbs){
            effects[i]="Limbless Mode: ";
        }else if (bodyEffect==BE_Fat){
            effects[i]="Full Fat: ";
        }else if (bodyEffect==BE_Skinny){
            effects[i]="Skin and Bones: ";
        }else if (bodyEffect==BE_Headless){
            effects[i]="Headless: ";
        }else if (bodyEffect==BE_PintSized){
            effects[i]="Pint-Sized: ";
        }
        effects[i]=effects[i]$bodyEffectTimer;
        i++;
    }
    if (infAdrenalineTimer > 0) {
        effects[i]="Infinite Adrenaline: "$infAdrenalineTimer;
        i++;
    }

    if (octoJumpTimer > 0) {
        effects[i]="Octojump: "$octoJumpTimer;
        i++;
    }

    if (numAddedBots > 0) {
        effects[i]="Added Bots: "$numAddedBots;
        i++;
    }
    if (tauntTimer > 0) {
        effects[i]="Taunting: "$tauntTimer;
        i++;
    }
    if (winHalfDmgTimer > 0) {
        effects[i]="Winner Half Damage: "$winHalfDmgTimer;
        i++;
    }
    if (redLightTimer > 0) {
        effects[i]="Red Light, Green Light: "$redLightTimer;
        if (greenLight){
            effects[i]=effects[i] $ GenerateRGBTextCode(0,255,0) $" (GREEN!)";
        } else {
            effects[i]=effects[i] $ GenerateRGBTextCode(255,0,0) $ " (RED!)";
        }
        effects[i]=effects[i] $ GenerateRGBTextCode(255,255,255);
        i++;
    }
    if (momentumTimer > 0) {
        effects[i]="Massive Momentum: "$momentumTimer;
        i++;
    }

    numEffects=i;
}

//One Second timer updates
function PeriodicUpdates()
{
    local bool change;

    if (behindTimer > 0) {
        behindTimer--;
        if (behindTimer <= 0) {
            StopCrowdControlEvent("third_person",true);
        } else {
            SetAllPlayersBehindView(True);
        }
    }  

    if (speedTimer > 0) {
        speedTimer--;
        if (speedTimer <= 0) {
            StopCrowdControlEvent("gotta_go_fast",true);
        }
    }  
    if (iceTimer > 0) {
        iceTimer--;
        if (iceTimer <= 0) {
            StopCrowdControlEvent("ice_physics",true);
        }
    } 
    if (meleeTimer > 0) {
        meleeTimer--;
        if (meleeTimer <= 0) {
            StopCrowdControlEvent("melee_only",true);
        }
    }  
    if (floodTimer > 0) {
        floodTimer--;
        if (floodTimer <= 0) {
            StopCrowdControlEvent("flood",true);
        }
    } 
    if (fogTimer > 0) {
        fogTimer--;
        if (fogTimer <= 0) {
            StopCrowdControlEvent("silent_hill",true);
        }
    } 
    if (bounceTimer > 0) {
        bounceTimer--;
        if (bounceTimer <= 0) {
            StopCrowdControlEvent("bouncy_castle",true);
        } else if ((bounceTimer % 2) == 0){
            BounceAllPlayers();
        }
    } 
    if (tauntTimer > 0) {
        tauntTimer--;
        if (tauntTimer <= 0) {
            StopCrowdControlEvent("thrust",true);
        } else if ((tauntTimer % 2) == 0){
            PlayTaunt(curTaunt);
        }
    } 
    if (hotPotatoTimer > 0) {
        hotPotatoTimer--;
        if (hotPotatoTimer <= 0) {
            StopCrowdControlEvent("bombing_run_hot_potato",true);
        } else {
            BRHotPotatoCheck();
        }
    } 
    if (vampireTimer > 0) {
        vampireTimer--;
        if (vampireTimer <= 0) {
            StopCrowdControlEvent("vampire_mode",true);
        }
    }  
    if (teamDamageTimer > 0) {
        teamDamageTimer--;
        if (teamDamageTimer <= 0) {
            StopCrowdControlEvent("attack_team_double_dmg",true);
        }
    }  
    if (headShotTimer > 0) {
        headShotTimer--;
        if (headShotTimer <= 0) {
            StopCrowdControlEvent("head_shots_only",true);
        }
    }  
    if (thornsTimer > 0) {
        thornsTimer--;
        if (thornsTimer <= 0) {
            StopCrowdControlEvent("thorns",true);
        }
    }  
    if (winHalfDmgTimer > 0) {
        winHalfDmgTimer--;
        if (winHalfDmgTimer <= 0) {
            StopCrowdControlEvent("winner_half_dmg",true);
        }
    }  
    if (momentumTimer > 0) {
        momentumTimer--;
        if (momentumTimer <= 0) {
            StopCrowdControlEvent("massive_momentum",true);
        }
    }  
    if (forceWeaponTimer > 0) {
        forceWeaponTimer--;
        if (forceWeaponTimer <= 0) {
            StopCrowdControlEvent("force_weapon_use",true);
        }
    }  
    if (bodyEffectTimer > 0) {
        bodyEffectTimer--;
        if (bodyEffectTimer <= 0) {
            StopCrowdControlEvent("big_head",true);
            StopCrowdControlEvent("pint_sized",true);
        }
    }  
    if (gravityTimer > 0) {
        gravityTimer--;
        if (gravityTimer <= 0) {
            StopCrowdControlEvent("low_grav",true);
        }
    }
    if (infAdrenalineTimer > 0) {
        infAdrenalineTimer--;
        if (infAdrenalineTimer <= 0) {
            StopCrowdControlEvent("infinite_adrenaline",true);
        } else {
            InfiniteAdrenalineRefill();
        }
    } 

    if (octoJumpTimer > 0) {
        octoJumpTimer--;
        if (octoJumpTimer <= 0) {
            StopCrowdControlEvent("octojump",true);
        }
    }

    if (redLightTimer > 0) {
        redLightTimer--;
        indLightTime++;
        redLightGrace=false;
        if (redLightTimer <= 0) {
            StopCrowdControlEvent("red_light_green_light",true);
        } else {
            if (indLightTime>LightMinimumTime){
                change=false;

                if (greenLight && indLightTime>GreenLightMaxTime) {
                    change = true;
                }
                if (!greenLight && indLightTime>RedLightMaxTime) {
                    change = true;
                }
                if (Rand(10)==0) { //10% chance
                    change = true;
                }

                if (change){ 
                    indLightTime=0;
                    greenLight=!greenLight; //Toggle light
                    if (greenLight){
                        Broadcast(GenerateRGBTextCode(0,255,0)$"GREEN LIGHT!");
                    } else {
                        redLightGrace=true;
                        Broadcast(GenerateRGBTextCode(255,0,0)$"RED LIGHT!");
                    }
                }
            }
        }
    }  

    

}

//Updates every tenth of a second
function ContinuousUpdates()
{
    local DeathMatch game;
    
    game = DeathMatch(Level.Game);
    
    //Want to force people to melee more frequently than once a second
    if (meleeTimer > 0) {
        ForceAllPawnsToMelee();
    }
    
    if (forceWeaponTimer > 0) {
        TopUpWeaponAmmoAllPawns(forcedWeapon);
        ForceAllPawnsToSpecificWeapon(forcedWeapon);  
    }
    
    if (game!=None){
        if (numAddedBots==0 || Level.Game.bGameEnded){
            game.MinPlayers = cfgMinPlayers;
        } else {
            game.MinPlayers = Max(cfgMinPlayers+numAddedBots, game.NumPlayers + numAddedBots);
        }
    }

    if (redLightTimer > 0 && greenLight==false && redLightGrace==false) {
        CheckRedLightMovement();
    }
}

function CheckRedLightMovement()
{
    local Pawn p;
    local TeamGame tg;
    local bool prevScoreTeamKills;

    tg = TeamGame(Level.Game);
    if (tg!=None){
        prevScoreTeamKills=tg.bScoreTeamKills;
        tg.bScoreTeamKills=false;
    }

    foreach AllActors(class'Pawn',p){
        if (VSize(p.Velocity)>10){
            p.TakeDamage
            (
                10000,
                p,
                p.Location,
                Vect(0,0,0),
                class'RedLight'
            );
        }
    }
    if (tg!=None){
        tg.bScoreTeamKills=prevScoreTeamKills;
    }
}


//Called every time there is a kill
function ScoreKill(Pawn Killer,Pawn Other)
{
    local int i;
    local DeathMatch game;

    game = DeathMatch(Level.Game);

    //Broadcast(Killer.Controller.GetHumanReadableName()$" just killed "$Other.Controller.GetHumanReadableName());
    
    //Check if the killed pawn is a bot that we don't want to respawn
    for (i=0;i<MaxAddedBots;i++){
        if (added_bots[i]!=None && added_bots[i]==Other) {
            added_bots[i]=None;
            numAddedBots--;
            if (game!=None)
            {
                game.MinPlayers = Max(cfgMinPlayers+numAddedBots, game.NumPlayers + game.NumBots - 1);
            }

            //Broadcast("Should be destroying added bot "$Other.Controller.GetHumanReadableName());
            Broadcast("Crowd Control viewer "$Other.Controller.GetHumanReadableName()$" has left the match");
            //Other.SpawnGibbedCarcass();
            Other.Destroy(); //This may cause issues if there are more mutators caring about ScoreKill.  Probably should schedule this deletion for later instead...
            break;
        }
    }    
}

simulated function ModifyPlayer(Pawn Other)
{
    if (bodyEffectTimer>0) {
        if (bodyEffect==BE_BigHead){
            Other.SetHeadScale(BigHeadScale);
        } else if (bodyEffect==BE_Headless){
            Other.SetHeadScale(HiddenScale);
        } else if (bodyEffect==BE_NoLimbs){
            SetLimblessScale(Other);
        } else if (bodyEffect==BE_Fat){
            SetAllBoneScale(Other,FatScale);
        } else if (bodyEffect==BE_Skinny){
            SetAllBoneScale(Other,SkinnyScale);
        } else if (bodyEffect==BE_PintSized){
            MakePintSized(xPawn(Other));
        }
    }

    if (speedTimer>0){
        if (bFast){
            Other.GroundSpeed = class'Pawn'.Default.GroundSpeed * 3;
        } else {
            Other.GroundSpeed = class'Pawn'.Default.GroundSpeed / 3;
        }
    }

    if (octoJumpTimer>0 && xPawn(Other)!=None){
        xPawn(Other).MaxMultiJump=7;
        xPawn(Other).MultiJumpRemaining=7;
        xPawn(Other).MultiJumpBoost=50;
    }
}

simulated function SetPawnBoneScale(Pawn p, int Slot, optional float BoneScale, optional name BoneName)
{
    if (CrowdControl(baseMutator)!=None){
        CrowdControl(baseMutator).SetPawnBoneScale(p,Slot,BoneScale,BoneName);
    } else if (OfflineCrowdControl(baseMutator)!=None){
        OfflineCrowdControl(baseMutator).SetPawnBoneScale(p,Slot,BoneScale,BoneName);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                               CROWD CONTROL UTILITY FUNCTIONS                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

function vector GetDefaultZoneGravity(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_gravities); i++) {
        if( z.name == zone_gravities[i].zonename )
            return zone_gravities[i].gravity;
        if( zone_gravities[i].zonename == '' )
            break;
    }
    return NormalGravity;
}

function SaveDefaultZoneGravity(PhysicsVolume z)
{
    local int i;
    if( z.gravity.X ~= NormalGravity.X && z.gravity.Y ~= NormalGravity.Y && z.gravity.Z ~= NormalGravity.Z ) return;
    for(i=0; i<ArrayCount(zone_gravities); i++) {
        if( z.name == zone_gravities[i].zonename )
            return;
        if( zone_gravities[i].zonename == '' ) {
            zone_gravities[i].zonename = z.name;
            zone_gravities[i].gravity = z.gravity;
            return;
        }
    }
}

function float GetDefaultZoneFriction(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_frictions); i++) {
        if( z.name == zone_frictions[i].zonename )
            return zone_frictions[i].friction;
    }
    return NormalFriction;
}

function SaveDefaultZoneFriction(PhysicsVolume z)
{
    local int i;
    if( z.GroundFriction ~= NormalFriction ) return;
    for(i=0; i<ArrayCount(zone_frictions); i++) {
        if( zone_frictions[i].zonename == '' || z.name == zone_frictions[i].zonename ) {
            zone_frictions[i].zonename = z.name;
            zone_frictions[i].friction = z.GroundFriction;
            return;
        }
    }
}
function bool GetDefaultZoneWater(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_waters); i++) {
        if( z.name == zone_waters[i].zonename )
            return zone_waters[i].water;
    }
    return True;
}

function SaveDefaultZoneWater(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_waters); i++) {
        if( zone_waters[i].zonename == '' || z.name == zone_waters[i].zonename ) {
            zone_waters[i].zonename = z.name;
            zone_waters[i].water = z.bWaterVolume;
            return;
        }
    }
}
function bool GetDefaultZoneFog(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( z.name == zone_fogs[i].zonename )
            return zone_fogs[i].hasFog;
    }
    return class'PhysicsVolume'.Default.bDistanceFog;
}

function float GetDefaultZoneFogStart(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( z.name == zone_fogs[i].zonename )
            return zone_fogs[i].fogStart;
    }
    return class'PhysicsVolume'.Default.DistanceFogStart;
}

function float GetDefaultZoneFogEnd(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( z.name == zone_fogs[i].zonename )
            return zone_fogs[i].fogEnd;
    }
    return class'PhysicsVolume'.Default.DistanceFogEnd;
}

function SaveDefaultZoneFog(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( zone_fogs[i].zonename == '' || z.name == zone_fogs[i].zonename ) {
            zone_fogs[i].zonename = z.name;
            zone_fogs[i].hasFog = z.bDistanceFog;
            zone_fogs[i].fogStart = z.DistanceFogStart;
            zone_fogs[i].fogEnd = z.DistanceFogEnd;
            return;
        }
    }
}
function GiveInventoryToPawn(Class<Inventory> className, Pawn p)
{
    local Inventory inv;
    
    inv = Spawn(className);
    inv.Touch(p);
    inv.Destroy();
}

function SetAllPlayersGroundSpeed(int speed)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        //Broadcast("Speed before: "$p.GroundSpeed$"  Speed After: "$speed);
        p.GroundSpeed = speed;
    }
}

//The multijumps are on top of the regular jump, so numJumps=3 means you can jump 4 times
function SetAllPlayersMultiJump(int numJumps, int jumpBoost)
{
    local xPawn p;
    
    foreach AllActors(class'xPawn',p) {
        p.MaxMultiJump = numJumps;
        p.MultiJumpRemaining = numJumps;
        p.MultiJumpBoost=jumpBoost;
    }
}

function Swap(Actor a, Actor b)
{
    local vector newloc, oldloc;
    local rotator newrot;
    local Actor abase, bbase;
    local bool AbCollideActors, AbBlockActors, AbBlockPlayers;
    local EPhysics aphysics, bphysics;

    if( a == b ) return;
    
    AbCollideActors = a.bCollideActors;
    AbBlockActors = a.bBlockActors;
    AbBlockPlayers = a.bBlockPlayers;
    a.SetCollision(false, false, false);

    oldloc = a.Location;
    newloc = b.Location;
    
    b.SetLocation(oldloc);
    a.SetCollision(AbCollideActors, AbBlockActors, AbBlockPlayers);
    
    a.SetLocation(newLoc);
    
    newrot = b.Rotation;
    b.SetRotation(a.Rotation);
    a.SetRotation(newrot);

    aphysics = a.Physics;
    bphysics = b.Physics;
    abase = a.Base;
    bbase = b.Base;

    a.SetPhysics(bphysics);
    if(abase != bbase) a.SetBase(bbase);
    b.SetPhysics(aphysics);
    if(abase != bbase) b.SetBase(abase);
}

function Pawn findRandomPawn()
{
    local int num;
    local Pawn p;
    local Pawn pawns[50];
    
    num = 0;
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)==None && p.DrivenVehicle==None && p.Health>0){
            pawns[num++] = p;
        }
    }

    if( num == 0 ) return None;
    return pawns[ Rand(num) ];    
}

function RemoveAllAmmoFromPawn(Pawn p)
{
    local Inventory Inv;
    for( Inv=p.Inventory; Inv!=None; Inv=Inv.Inventory ) {
        if ( Ammunition(Inv) != None ) {
            Ammunition(Inv).AmmoAmount = 0;
        } else if (Weapon(Inv)!=None){
            Weapon(Inv).AmmoCharge[0]=0;
            Weapon(Inv).AmmoCharge[1]=0;
        }
    }      
}

function class<Ammunition> GetAmmoClassByName(String ammoName)
{
    local class<Ammunition> ammoClass;
    
    switch(ammoName){
        case "assaultammo":
            ammoClass = class'AssaultAmmo';
            break;
        case "bioammo":
            ammoClass = class'BioAmmo';
            break;
        case "flakammo":
            ammoClass = class'FlakAmmo';
            break;
        case "linkammo":
            ammoClass = class'LinkAmmo';
            break;
        case "minigunammo":
            ammoClass = class'MinigunAmmo';
            break;
        case "shockammo":
            ammoClass = class'ShockAmmo';
            break;
        case "sniperammo":
            ammoClass = class'SniperAmmo';
            break;
        case "mineammo":
            ammoClass = class'Onslaught.ONSMineAmmo';
            break;
        default:
            break;
    }
    
    return ammoClass;
}

function AddItemToPawnInventory(Pawn p, Inventory item)
{
        item.SetOwner(p);
        item.Inventory = p.Inventory;
        p.Inventory = item;
}

function bool IsWeaponRemovable(Weapon w)
{
    if (w==None){
        return False;
    }
    return w.bCanThrow;
}

function class<Weapon> GetWeaponClassByName(String weaponName)
{
    local class<Weapon> weaponClass;
    
    switch(weaponName){
        case "supershockrifle":
            weaponClass = class'SuperShockRifle';
            break;
        case "biorifle":
            weaponClass = class'BioRifle';
            break;
        case "flakcannon":
            weaponClass = class'FlakCannon';
            break;
        case "linkgun":
            weaponClass = class'LinkGun';
            break;
        case "minigun":
            weaponClass = class'Minigun';
            break;
        case "redeemer":
            weaponClass = class'Redeemer';
            break;
        case "rocketlauncher":
            weaponClass = class'RocketLauncher';
            break;
        case "shockrifle":
            weaponClass = class'ShockRifle';
            break;
        case "lightninggun":
            weaponClass = class'SniperRifle';
            break;
        case "translocator":
            weaponClass = class'Translauncher';
            break;
        case "minelayer":
            weaponClass = class'Onslaught.ONSMineLayer';
            break;
        default:
            break;
    }
    
    return weaponClass;
}

function Weapon GiveWeaponToPawn(Pawn p, class<Weapon> WeaponClass, optional bool bBringUp)
{
    local Weapon NewWeapon;
    local Inventory inv;

    inv = p.FindInventoryType(WeaponClass);
    if (inv != None ) {
            newWeapon = Weapon(inv);
            newWeapon.GiveAmmo(0,None,true);
            return newWeapon;
        }
        
    newWeapon = Spawn(WeaponClass);
    if ( newWeapon != None ) {
        newWeapon.GiveTo(p);
        newWeapon.GiveAmmo(0,None,true);
        //newWeapon.SetSwitchPriority(p);
        //newWeapon.WeaponSet(p);
        newWeapon.AmbientGlow = 0;
        if ( p.Controller.IsA('PlayerController') )
                    newWeapon.SetHand(PlayerController(p.Controller).Handedness);
        else
                    newWeapon.GotoState('Idle');
        if ( bBringUp ) {
            p.Controller.ClientSetWeapon(WeaponClass);
        }
    }
    return newWeapon;
}

function Weapon FindMeleeWeaponInPawnInventory(Pawn p)
{
	local actor Link;
    local Weapon weap;

	for( Link = p; Link!=None; Link=Link.Inventory )
	{
		if( Weapon(Link.Inventory) != None )
		{
            weap = Weapon(Link.Inventory);
			if (weap.bMeleeWeapon==True){
                return weap;
            }
		}
	}
    
    return None;
}

function ForcePawnToMeleeWeapon(Pawn p)
{
    local Weapon meleeweapon;
    
    if (p.Weapon == None || p.Weapon.bMeleeWeapon==True) {
        return;  //No need to do a lookup if it's already melee or nothing
    }
    
    meleeweapon = FindMeleeWeaponInPawnInventory(p);

    p.Controller.ClientSetWeapon(meleeweapon.Class);
}

function ForceAllPawnsToMelee()
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)==None){
            ForcePawnToMeleeWeapon(p);
        }
    }
}

//Find highest or lowest score player.
//If multiple have the same score, it'll use the first one with that score it finds
function Pawn findPawnByScore(bool highest, int avoidTeam)
{
    local Pawn cur;
    local Pawn p;
    local bool avoid;
    
    avoid = (avoidTeam!=255);
    
    cur = None;
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)!=None){
            continue; //Skip turrets and things like that
        }
        if (p.Health<=0){
            continue; //Skip anyone who might be dead
        }
        if (p.PlayerReplicationInfo==None){
            continue; //skip em if they don't have their PRI
        }
        //Broadcast(p.Controller.GetHumanReadableName()$" is on team "$p.PlayerReplicationInfo.Team);
        if (cur==None){
            if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                cur = p;
            }
        } else {
            if (highest){
                if (cur==None || p.PlayerReplicationInfo.Score > cur.PlayerReplicationInfo.Score) {
                    if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                        cur = p;
                    }
                }
            } else {
                if (cur==None || p.PlayerReplicationInfo.Score < cur.PlayerReplicationInfo.Score) {
                    if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                        cur = p;
                    }
                }            
            }
        }
    }
    return cur;
}

function int FindTeamByTeamScore(bool HighTeam)
{
    local int i,team;
    local TeamGame game;
    team = 0;

    if (Level.Game.bTeamGame==False){
        return 255;
    }
    
    game = TeamGame(Level.Game);
    
    if (game == None){
        return 255;
    }
    
    for (i=0;i<4;i++) {
        if (HighTeam) {
            if (game.Teams[i].Score > game.Teams[team].Score){
                team = i;
            }
        } else {
            if (game.Teams[i].Score < game.Teams[team].Score){
                team = i;
            }        
        }
    }
    
    return team;
}

function int FindTeamWithLeastPlayers()
{
    local Pawn p;
    local int pCount[256]; //Technically there are team ids up to 255, but really 0 to 3 and 255 are used
    local int i;
    local int lowTeam;
    
    lowTeam = 0;
    
    if (Level.Game.bTeamGame==False){
        return 255;
    }
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)==None){
            pCount[p.PlayerReplicationInfo.TeamID]++;
        }
    }
    
    for (i = 0; i < 256;i++){        
        if (pCount[i]!=0 && pCount[i] < pCount[lowTeam]) {
            lowTeam = i;
        }
    }
    //Broadcast("Lowest team is "$lowTeam);
    return lowTeam;

}


function ForcePawnToSpecificWeapon(Pawn p, class<Weapon> weaponClass)
{
    if (p.Weapon==None || p.Weapon.Class == weaponClass) {
        return;  //No need to do a lookup if it's already melee or nothing
    }
    
    p.Controller.ClientSetWeapon(weaponClass);
}

simulated function Weapon FindSpecificWeaponInPawnInventory(Pawn p,class<Weapon> weaponClass)
{
	local actor Link;

	for( Link = p; Link!=None; Link=Link.Inventory )
	{
		if( Link.Inventory!= None && Link.Inventory.Class == weaponClass )
		{
            return Weapon(Link.Inventory);
		}
	}
    
    return None;
}

function TopUpWeaponAmmoAllPawns(class<Weapon> weaponClass)
{
    local Pawn p;
    local Weapon w;
    
    foreach AllActors(class'Pawn',p) {
        if (p.IsA('Spectator') || p.Health<=0){
            continue;
        }
        w=None;
        w = FindSpecificWeaponInPawnInventory(p,weaponClass);
        
        if (w!=None){
            //if (w.AmmoType!=None && w.AmmoType.AmmoAmount==0){
                w.MaxOutAmmo();
            //}
        } else {
            GiveWeaponToPawn(p,weaponClass);
        }
        
    }
}

function bool IsGameRuleActive(class<GameRules> rule)
{
    local GameRules curRule,prevRule;

    prevRule = None;
    curRule=Level.Game.GameRulesModifiers;
    while (curRule!=None){
        if (curRule.class==rule){
            return True;
        }
        prevRule = curRule;
        curRule = curRule.NextGameRules;
    }
    return False;
}

function bool AddNewGameRule(class<GameRules> rule)
{
    local GameRules newRule;

    newRule = Spawn(rule);

    if (newRule==None){
        return False;
    }

    if (Level.Game.GameRulesModifiers==None){
        Level.Game.GameRulesModifiers=newRule;
    } else {
        Level.Game.GameRulesModifiers.AddGameRules(newRule);
    }

    return True;
}

function bool RemoveGameRule(class<GameRules> rule)
{
    local GameRules curRule,prevRule,removedRule;

    prevRule = None;
    removedRule = None;
    curRule=Level.Game.GameRulesModifiers;
    while (curRule!=None && removedRule==None){
        if (curRule.class==rule){
            removedRule = curRule;
            if (prevRule!=None){
                prevRule.NextGameRules = curRule.NextGameRules;
            } else {
                Level.Game.GameRulesModifiers = curRule.NextGameRules;
            }
        } else {
            prevRule = curRule;
            curRule = curRule.NextGameRules;
        }
    }

    if (removedRule==None){
        return False;
    }

    removedRule.Destroy();

    return True;
}

simulated function ForceAllPawnsToSpecificWeapon(class<Weapon> weaponClass)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)==None && p.Health>0){
            ForcePawnToSpecificWeapon(p, weaponClass);
        }
    }
}

simulated function RestoreBodyScale()
{
    local Pawn p;
    local int i;
    foreach AllActors(class'Pawn',p){
        p.SetHeadScale(1.0);
        for(i=0;i<=20;i++)
        SetPawnBoneScale(p,i);
    }
}

simulated function SetAllBoneScale(Pawn p, float scale)
{
    
    SetPawnBoneScale(p,10,scale,'lthigh');
    SetPawnBoneScale(p,11,scale,'rthigh');
    SetPawnBoneScale(p,12,scale,'rfarm');
    SetPawnBoneScale(p,13,scale,'lfarm');
    SetPawnBoneScale(p,14,scale,'head');
    SetPawnBoneScale(p,15,scale,'spine');
    
    //p.SetBoneScale(0,scale,p.RootBone);
}

simulated function SetLimblessScale(Pawn p)
{
    SetPawnBoneScale(p,10,HiddenScale,'Bip01 L Thigh');
    SetPawnBoneScale(p,11,HiddenScale,'Bip01 R Thigh');
    //p.SetBoneScale(12,HiddenScale,'rfarm');
    //p.SetBoneScale(13,HiddenScale,'lfarm');
    SetPawnBoneScale(p,12,HiddenScale,'rshoulder');
    SetPawnBoneScale(p,13,HiddenScale,'lshoulder');
}

function SetMoonPhysics(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z)
    {
        if (enabled && Z.Gravity != MoonGrav ) {
            SaveDefaultZoneGravity(Z);
            Z.Gravity = MoonGrav;
        }
        else if ( (!enabled) && Z.Gravity == MoonGrav ) {
            Z.Gravity = GetDefaultZoneGravity(Z);
        }
    }
}

function SetIcePhysics(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z) {
        if (enabled && Z.GroundFriction != IceFriction ) {
            SaveDefaultZoneFriction(Z);
            Z.GroundFriction = IceFriction;
        }
        else if ( (!enabled) && Z.GroundFriction == IceFriction ) {
            Z.GroundFriction = GetDefaultZoneFriction(Z);
        }
    }
}

function SetFlood(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z) {
        if (enabled && Z.bWaterVolume != True ) {
            SaveDefaultZoneWater(Z);
            Z.bWaterVolume = True;
        }
        else if ( (!enabled) && Z.bWaterVolume == True ) {
            Z.bWaterVolume = GetDefaultZoneWater(Z);
        }

        if (z.bWaterVolume && z.VolumeEffect==None){
            z.VolumeEffect = EFFECT_WaterVolume(Level.ObjectPool.AllocateObject(class'EFFECT_WaterVolume'));
            z.FluidFriction=class'WaterVolume'.Default.FluidFriction;
        } else if (!z.bWaterVolume && z.VolumeEffect!=None){
            Level.ObjectPool.FreeObject(z.VolumeEffect);
            z.VolumeEffect=None;
            z.FluidFriction=class'PhysicsVolume'.Default.FluidFriction;
        }
    }
}

function SetFog(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z) {
        if (enabled) {
            SaveDefaultZoneFog(Z);
            Z.bDistanceFog = True;
            Z.DistanceFogStart = HeavyFogStart;
            Z.DistanceFogEnd   = HeavyFogEnd;
        }
        else if (!enabled) {
            Z.bDistanceFog = GetDefaultZoneFog(Z);
            Z.DistanceFogStart = GetDefaultZoneFogStart(Z);
            Z.DistanceFogEnd = GetDefaultZoneFogEnd(Z);
        }
    }
}

function UpdateAllPawnsSwimState()
{
    
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        //Broadcast("State before update was "$p.GetStateName());
        if (Vehicle(p)!=None){continue;} //Skip vehicles

        if (p.Health>0){
            if (p.HeadVolume.bWaterVolume) {
                p.setPhysics(PHYS_Swimming);
                p.SetBase(None);
                p.BreathTime = p.UnderWaterTime;
            } else {
                p.setPhysics(PHYS_Falling);
                p.BreathTime = -1.0;
            }

            if (p.IsPlayerPawn()){
                PlayerController(p.Controller).EnterStartState();
            }
        }
    }
}

function BounceAllPlayers()
{
    local Pawn P;
    
    foreach AllActors(class'Pawn',P) {
        if ( (P == None) || (P.Physics == PHYS_None) || (Vehicle(P) != None) || (P.DrivenVehicle != None) || p.Base==None || p.HeadVolume.bWaterVolume) { continue; }

        if ( P.Physics == PHYS_Walking ){
            P.SetPhysics(PHYS_Falling);
        }
        P.Velocity.Z +=  BouncyCastleVelocity.Z;
        //P.Acceleration = vect(0,0,0);
    }    
}

function BRHotPotatoCheck()
{
    local xBombingRun brGame;
    local CrowdControlBombFlag ccBomb;

    brGame=xBombingRun(Level.Game);
    if (brGame==None){
        return;
    }

    ccBomb = CrowdControlBombFlag(brGame.Bomb);
    if (ccBomb==None){
        return;
    }

    if (Level.TimeSeconds - ccBomb.GrabTime >= HotPotatoMaxTime) {
        ccBomb.Holder.TakeDamage
        (
            10000,
            ccBomb.Holder,
            ccBomb.Holder.Location,
            Vect(0,0,0),
            class'HotPotato'
        );
    }
}

function InfiniteAdrenalineRefill()
{
    local Controller c;
    
    foreach AllActors(class'Controller',c) {
        if (c.bAdrenalineEnabled==True){
            c.Adrenaline=c.AdrenalineMax;
        }
    }
}

function bool IsGameActive()
{
    return !Level.Game.bWaitingToStartMatch && !Level.Game.bGameEnded;
}

function bool IsAdrenalineActive()
{
    local Controller c;
    local AdrenalinePickup p;
    
    foreach AllActors(class'Controller',c) {
        return c.bAdrenalineEnabled;
    }

    foreach AllActors(class'AdrenalinePickup',p){
        return True;
    }

    return False;

}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                CROWD CONTROL EFFECT FUNCTIONS                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



function int SuddenDeath(string viewer)
{
    local xPawn p;
    
    foreach AllActors(class'xPawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            p.Health = 1;
            p.ShieldStrength=0;
            p.SmallShieldStrength=0;
        }
    }
    
    Broadcast(viewer$" has initiated sudden death!  All health reduced to 1, no armour!");

    return Success;
}

function int FullHeal(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Health>0){
            //Don't reduce health if someone is overhealed
            if (p.Health < 100) {
                p.Health = 100;
            }
        }
    }
    
    Broadcast("Everyone has been fully healed by "$viewer$"!");
  
    return Success;
}

function int FullArmour(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)!=None){continue;}
        p.AddShieldStrength(150);
    }
   
    Broadcast(viewer$" has given everyone full armour!");
   
    return Success;
}

function int FullAdrenaline(string viewer)
{
    local Controller c;
    
    foreach AllActors(class'Controller',c) {
        if (c.bAdrenalineEnabled==False){
            return TempFail;
        }
        c.Adrenaline=c.AdrenalineMax;
    }
   
    Broadcast(viewer$" has given everyone full adrenaline!");
   
    return Success;
}

function int GiveHealth(string viewer,int amount)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Health>0){
            p.Health = Min(p.Health + amount,199); //Let's allow this to overheal, up to 199
        }
    }
    
    Broadcast("Everyone has been given "$amount$" health by "$viewer$"!");
    
    return Success;
}

function SetAllPlayersBehindView(bool val)
{
    local PlayerController p;
    
    foreach AllActors(class'PlayerController',p) {
        p.ClientSetBehindView(val);
    }
}

function int ThirdPerson(String viewer, int duration)
{
    if (behindTimer>0) {
        return TempFail;
    }

    SetAllPlayersBehindView(True);
    
    if (duration==0){
        duration = BehindTimerDefault;
    }
    
    behindTimer = duration;

    Broadcast(viewer$" wants you to have an out of body experience!");
  
    return Success;

}

function int GiveDamageItem(String viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)!=None){continue;}
        p.EnableUDamage(30);
    }
    
    Broadcast(viewer$" gave everyone a damage powerup!");
   
    return Success;
}


function int GottaGoFast(String viewer, int duration)
{
    if (speedTimer>0) {
        return TempFail;
    }
    if (floodTimer>0) {
        return TempFail;
    }
    SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed * 3);
    if (duration==0){
        duration = SpeedTimerDefault;
    }
    speedTimer = duration;
    bFast=True;
    targetPlayer="";
    Broadcast(viewer$" made everyone fast like Sonic!");
   
    return Success;   
}

function int GottaGoSlow(String viewer, int duration)
{
    if (speedTimer>0) {
        return TempFail;
    }
    if (floodTimer>0) {
        return TempFail;
    }
    SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed / 3);

    if (duration==0){
        duration = SlowTimerDefault;
    }
    speedTimer = duration;
    bFast=False;
    targetPlayer="";
    Broadcast(viewer$" made everyone slow like a snail!");
   
    return Success;   
}

function int ThanosSnap(String viewer)
{
    local Pawn p, pawns[40];
    local int i, num, num_pawns, num_to_kill;
    //local String origDamageString;
    
    //origDamageString = Level.Game.SpecialDamageString;
    //Level.Game.SpecialDamageString = "%o got snapped by "$viewer;
    
    num_pawns=0;
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)!=None){continue;}
        if (p.Health<=0){ continue; }
        pawns[num_pawns++]=p;
    }

    if (num_pawns<2){
        return TempFail;
    }

    num_to_kill = num_pawns/2;
    
    for (i=0;i<num_to_kill;i++){
        num=Rand(num_pawns);
        pawns[num].TakeDamage
        (
            10000,
            pawns[num],
            pawns[num].Location,
            Vect(0,0,0),
            class'ThanosSnapped'				
        );
        pawns[num] = pawns[num_pawns-1];
        num_pawns--;
    }
    
    //Level.Game.SpecialDamageString = origDamageString;
    
    Broadcast(viewer$" snapped their fingers!");
  
    return Success;

}

//Leaving this here just in case we maybe want this as a standalone effect at some point?
function int swapPlayer(string viewer) {
    local Pawn a,b;
    local int tries;
    a = None;
    b = None;
    
    tries = 0; //Prevent a runaway
    
    while (tries < 5 && (a == None || b == None || a==b)) {
        a = findRandomPawn();
        b = findRandomPawn();
        tries++;
    }
    
    if (tries == 5) {
        return TempFail;
    }
    
    Swap(a,b);
    
    
    //If we swapped a bot, get them to recalculate their logic so they don't just run off a cliff
    if (a.PlayerReplicationInfo.bBot == True && Bot(a.Controller)!=None) {
        //Bot(a).WhatToDoNext('',''); //TODO
    }
    if (b.PlayerReplicationInfo.bBot == True && Bot(b.Controller)!=None) {
        //Bot(b).WhatToDoNext('',''); //TODO
    }
    
    Broadcast(viewer@"thought "$a.Controller.GetHumanReadableName()$" would look better if they were where"@b.Controller.GetHumanReadableName()@"was");

    return Success;
}

function int SwapAllPlayers(string viewer){
    //The game expects a maximum of 16 players, but it's possible to cram more in...  Just do up to 50, for safety
    local vector locs[50];
    local rotator rots[50];
    local EPhysics phys[50];
    local Actor bases[50];
    local Pawn pawns[50];
    local int numPlayers,num;
    local Pawn p;
    local int i,newLoc;

    //Collect all the information about where pawns are currently
    //and remove their collision
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)==None && p.DrivenVehicle==None && p.Health>0){
            pawns[numPlayers] = p;
            locs[numPlayers]=p.Location;
            rots[numPlayers]=p.Rotation;
            phys[numPlayers]=p.Physics;
            bases[numPlayers]=p.Base;
            numPlayers++;

            p.SetCollision(False,False,False);

            if (numPlayers==ArrayCount(Pawns)){
                break; //Hit the limit, just work amongst these ones
            }
        }
    }
    
    //Move everyone
    num = numPlayers;
    for (i=numPlayers-1;i>=0;i--){
        newLoc = Rand(num);
        //Broadcast(pawns[i].Controller.GetHumanReadableName()@"moving to location "$newLoc);
        
        pawns[i].SetLocation(locs[newLoc]);
        pawns[i].SetRotation(rots[newLoc]);
        pawns[i].SetPhysics(phys[newLoc]);
        pawns[i].SetBase(bases[newLoc]);
        
        num--;

        locs[newLoc]=locs[num];
        rots[newLoc]=rots[num];
        phys[newLoc]=phys[num];
        bases[newLoc]=bases[num];
    }

    //Re-enable collision and recalculate bot logic
    for (i=numPlayers-1;i>=0;i--){
        pawns[i].SetCollision(True,True,True);
        if (pawns[i].PlayerReplicationInfo.bBot==True && Bot(pawns[i].Controller)!=None){
            //Bot(pawns[i].Controller).WhatToDoNext('',''); //TODO
        }
    }

    Broadcast(viewer@"decided to shuffle where everyone was");

    return Success;

}


function int NoAmmo(String viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)==None){
            RemoveAllAmmoFromPawn(p);
        }
    }
    
    Broadcast(viewer$" stole all your ammo!");
    
    return Success;
}


function int GiveAmmo(String viewer, String ammoName, int amount)
{
    local class<Ammunition> ammoClass;
    local Weapon w;
    local int i;
    local bool added;
    
    ammoClass = GetAmmoClassByName(ammoName);
    
    added=False;
    foreach AllActors(class'Weapon',w) {
        if (w.Owner==None) continue;
        for (i=0;i<=1;i++){
            if (w.AmmoClass[i]==ammoClass){
                if (w.AddAmmo(ammoClass.Default.InitialAmount * amount,i)){
                    added=True;
                }
            }
        }
    }

    if (!added){
        return TempFail;
    }
    
    Broadcast(viewer$" gave everybody some ammo! ("$ammoClass.default.ItemName$")");

    return Success;
}

function int doNudge(string viewer) {
    local vector newAccel;
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        newAccel.X = Rand(501)-100;
        newAccel.Y = Rand(501)-100;
        //newAccel.Z = Rand(31);
        
        //Not super happy with how this looks,
        //Since you sort of just teleport to the new position
        p.MoveSmooth(newAccel);
    }
        
    Broadcast(viewer@"nudged you a little bit");

    return Success;
}


function int DropSelectedWeapon(string viewer) {
    local Pawn p;
    local Weapon w;

    //This won't do anything if people are being forced to a weapon, so postpone it
    if (forceWeaponTimer>0) {
        return TempFail;
    }        

    foreach AllActors(class'Pawn',p) {
        if (Vehicle(p)!=None){
            continue;
        }
        if (IsWeaponRemovable(p.Weapon)){
            w=p.Weapon;
            p.DeleteInventory(p.Weapon);
            w.bHidden=True;
            //w.bDeleteMe=True;
            w.Destroy();
        }
    }
    
    Broadcast(viewer$" stole your current weapon!");
   
    return Success;

}



function int GiveWeapon(String viewer, String weaponName)
{
    local class<Weapon> weaponClass;
    local Pawn p;

    weaponClass = GetWeaponClassByName(weaponName);
    
    foreach AllActors(class'Pawn',p) {  //Probably could just iterate over PlayerControllers, but...
        if (Vehicle(p)!=None || p.IsA('Spectator') || p.Health<=0){
            continue;
        }
        GiveWeaponToPawn(p,weaponClass);
    }
    
    Broadcast(viewer$" gave everybody a weapon! ("$weaponClass.default.ItemName$")");
  
    return Success;
}


function int StartMeleeOnlyTime(String viewer, int duration)
{
    if (meleeTimer > 0) {
        return TempFail;
    }
    if (forceWeaponTimer>0) {
        return TempFail;
    }    
    ForceAllPawnsToMelee();
    
    Broadcast(viewer@"requests melee weapons only!");
    if (duration==0){
        duration = MeleeTimerDefault;
    }
    meleeTimer = duration;
    
    return Success;
}

function int LastPlaceShield(String viewer)
{
    local Pawn p;

    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None || p.Controller==None) {
        return TempFail;
    }
    
    //Actually give them the shield belt
    //GiveInventoryToPawn(class'UT_ShieldBelt',p);
    p.AddShieldStrength(150);

    Broadcast(viewer@"gave full armour to "$p.Controller.GetHumanReadableName()$", who is in last place!");

    return Success;
}

function int LastPlaceDamage(String viewer)
{
    local Pawn p;

    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None || p.Controller==None) {
        return TempFail;
    }
    
    //Actually give them the damage bonus
    //GiveInventoryToPawn(class'UDamage',p);
    p.EnableUDamage(30);
    
    Broadcast(viewer@"gave a Damage Amplifier to "$p.Controller.GetHumanReadableName()$", who is in last place!");

    return Success;
}

function int LastPlaceUltraAdrenaline(String viewer)
{
    local Pawn p;


    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None) {
        return TempFail;
    }

    if (p.Controller.bAdrenalineEnabled==False){
        return TempFail;
    }

    if (p.Controller.GetHumanReadableName()==""){
        return TempFail;
    }
    
    p.Controller.Adrenaline=p.Controller.AdrenalineMax;
    Spawn(class'XGame.ComboSpeed',p);    
    Spawn(class'XGame.ComboBerserk',p);    
    Spawn(class'XGame.ComboDefensive',p);    
    Spawn(class'XGame.ComboInvis',p);    

    Broadcast(viewer@"triggered all adrenaline combos for "$p.Controller.GetHumanReadableName()$", who is in last place!");

    return Success;
}

function int AllPlayersBerserk(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Controller.bAdrenalineEnabled==False){
            return TempFail;
        }
        p.Controller.Adrenaline=p.Controller.AdrenalineMax;
        Spawn(class'XGame.ComboBerserk',p);
    }
   
    Broadcast(viewer$" has made everyone berserk!");
   
    return Success;
}

function int AllPlayersInvisible(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Controller.bAdrenalineEnabled==False){
            return TempFail;
        }
        p.Controller.Adrenaline=p.Controller.AdrenalineMax;
        Spawn(class'XGame.ComboInvis',p);
    }
   
    Broadcast(viewer$" has made everyone invisible!");
   
    return Success;
}

function int AllPlayersRegen(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Controller.bAdrenalineEnabled==False){
            return TempFail;
        }
        p.Controller.Adrenaline=p.Controller.AdrenalineMax;
        Spawn(class'XGame.ComboDefensive',p);
    }
   
    Broadcast(viewer$" has made everyone regenerate!");
   
    return Success;
}


function int FirstPlaceSlow(String viewer, int duration)
{
    local Pawn p;

    if (speedTimer>0) {
        return TempFail;
    }
    
    p = findPawnByScore(True,255); //Get Highest score player
    
    if (p == None) {
        return TempFail;
    }

    p.GroundSpeed = (class'Pawn'.Default.GroundSpeed / 3);
    
    if (duration == 0){
        duration = SingleSlowTimerDefault;
    }
    speedTimer = duration;
    bFast=False;
    targetPlayer=p.Controller.GetHumanReadableName();

    Broadcast(viewer$" made "$p.Controller.GetHumanReadableName()$" slow as punishment for being in first place!");

    return Success;   
}

//If teams, should find highest on winning team, and lowest on losing team
function int BlueRedeemerShell(String viewer)
{
    local Pawn high,low;
    local RedeemerProjectile missile;
    local int avoidTeam;
    
    
    high = findPawnByScore(True,FindTeamByTeamScore(False));  //Target individual player who is doing best on a team that isn't in last place
    
    if (high==None){
        return TempFail;
    }
    
    if (Level.Game.bTeamGame==True){
        avoidTeam = high.PlayerReplicationInfo.TeamID;
    } else {
        avoidTeam = 255;
    }
    
    low = findPawnByScore(False,avoidTeam);  //Find worst player who is on a different team (if a team game)
    
    if (low == None || high == low){
        return TempFail;
    }
    
    missile = Spawn(class'RedeemerProjectile',low,,high.Location);
    missile.SetOwner(low);
    missile.Instigator = low;  //Instigator is the one who gets credit for the kill
    missile.GotoState('Flying');
    missile.Explode(high.Location,high.Location);

    Broadcast(viewer$" dropped a redeemer shell on "$high.Controller.GetHumanReadableName()$"'s head, since they are in first place!");

    return Success;
}

function MakePintSized(xPawn P)
{
    if (P==None){return;}
    
    P.SetDrawscale(0.5 * P.Default.DrawScale);
    P.bCanCrouch = false;
    P.SetCollisionSize(P.CollisionRadius, 0.5*P.CollisionHeight);
    P.BaseEyeheight = 0.8 * P.CollisionHeight;
}

function EndPintSized()
{
    local xPawn P;

    foreach AllActors(class'xPawn',P){
        P.SetDrawscale(P.Default.DrawScale);
        P.bCanCrouch = P.default.bCanCrouch;
        P.BaseEyeheight = P.Default.BaseEyeheight;
        P.ForceCrouch();
    }
}

simulated function int StartPintSized(string viewer, int duration)
{
    local xPawn p;
    local bool changed;

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'xPawn',p){
        changed=True;
        MakePintSized(p);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"made everyone pint-sized!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_PintSized;
    return Success;
}

simulated function int StartBigHeadMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    //Check if game rule is already in place, fail if it is
    //This is different from what we're doing, but would interfere
    if (IsGameRuleActive(class'BigHeadRules')){
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        if (Vehicle(p)!=None){continue;}
        changed=True;
        p.SetHeadScale(BigHeadScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"inflated everyones head!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_BigHead;
    return Success;
}

simulated function int StartHeadlessMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    //Check if game rule is already in place, fail if it is
    //This is different from what we're doing, but would interfere
    if (IsGameRuleActive(class'BigHeadRules')){
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        if (Vehicle(p)!=None){continue;}
        changed=True;
        p.SetHeadScale(HiddenScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"removed everyones head!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_Headless;
    return Success;
}

simulated function int StartLimblessMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (!isLocal){
        return TempFail;
    }

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        if (Vehicle(p)!=None){continue;}
        changed=True;
        SetLimblessScale(p);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"removed everyones limbs!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_NoLimbs;
    return Success;
}

simulated function int StartFullFatMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (!isLocal){
        return TempFail;
    }

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        if (Vehicle(p)!=None){continue;}
        changed=True;
        SetAllBoneScale(p,FatScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"Puffed everyone up!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_Fat;
    return Success;
}

simulated function int StartSkinAndBonesMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (!isLocal){
        return TempFail;
    }

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        if (Vehicle(p)!=None){continue;}
        changed=True;
        SetAllBoneScale(p,SkinnyScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"made everyone skinny!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_Skinny;
    return Success;
}

function int StartVampireMode(string viewer, int duration)
{
    if (vampireTimer>0) {
        return TempFail;
    }

    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(class'WorkingVampireGameRules')){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(class'WorkingVampireGameRules')){
        return TempFail;
    }

    Broadcast(viewer@"made everyone have a taste for blood!");
    if (duration==0){
        duration = VampireTimerDefault;
    }
    vampireTimer = duration;
    return Success;
}

function int StartTeamDamageMode(string viewer, int duration, bool holdingTeam)
{
    local class<GameRules> newRuleClass;
    local string msg;

    if (teamDamageTimer>0) {
        return TempFail;
    }
    if (headShotTimer>0) {
        return TempFail;
    }
    if (thornsTimer>0){
        return TempFail;
    }
    if (winHalfDmgTimer>0){
        return TempFail;
    }
    if (xBombingRun(Level.Game)==None && ASGameInfo(Level.Game)==None){
        return TempFail;
    }

    if (holdingTeam){
        newRuleClass=class'OffenseDoubleDamageRules';
    } else {
        newRuleClass=class'DefenseDoubleDamageRules';
    }

    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(newRuleClass)){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(newRuleClass)){
        return TempFail;
    }

    teamDamageHoldingTeam = holdingTeam;

    msg=viewer$" made the ";
    if (holdingTeam){
        msg$="attacking";
    } else {
        msg$="defending";
    }
    msg$=" team do double damage!";

    Broadcast(msg);
    if (duration==0){
        duration = TeamDamageTimerDefault;
    }
    teamDamageTimer = duration;
    return Success;
}

function int StartHeadShotsOnly(string viewer, int duration)
{
    if (headShotTimer>0) {
        return TempFail;
    }
    if (teamDamageTimer>0) {
        return TempFail;
    }
    if (thornsTimer>0){
        return TempFail;
    }
    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(class'HeadShotsOnlyRules')){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(class'HeadShotsOnlyRules')){
        return TempFail;
    }

    Broadcast(viewer@"made only head shots count!");
    if (duration==0){
        duration = HeadShotTimerDefault;
    }
    headShotTimer = duration;
    return Success;
}

function int StartThornsMode(string viewer, int duration)
{
    if (headShotTimer>0) {
        return TempFail;
    }
    if (teamDamageTimer>0) {
        return TempFail;
    }
    if (thornsTimer>0){
        return TempFail;
    }
    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(class'ThornsRules')){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(class'ThornsRules')){
        return TempFail;
    }

    Broadcast(viewer@"gave everyone thorns!");
    if (duration==0){
        duration = ThornsTimerDefault;
    }
    thornsTimer = duration;
    return Success;
}

function int StartWinnerHalfDamageMode(string viewer, int duration)
{
    if (teamDamageTimer>0) {
        return TempFail;
    }
    if (winHalfDmgTimer>0){
        return TempFail;
    }
    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(class'WinningHalfDamageRules')){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(class'WinningHalfDamageRules')){
        return TempFail;
    }

    Broadcast(viewer@"made the winner do half damage!");
    if (duration==0){
        duration = WinHalfDmgTimerDefault;
    }

    winHalfDmgTimer = duration;
    return Success;
}

function int StartMassiveMomentum(string viewer, int duration)
{
    if (momentumTimer>0){
        return TempFail;
    }
    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(class'MassiveMomentumRules')){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(class'MassiveMomentumRules')){
        return TempFail;
    }

    Broadcast(viewer@"made all damage impart massive momentum!");
    if (duration==0){
        duration = MomentumTimerDefault;
    }

    momentumTimer = duration;
    return Success;
}

function int StartRedLightGreenLight(string viewer, int duration)
{
    if (bounceTimer>0) {
        return TempFail;
    }
    if (iceTimer>0) {
        return TempFail;
    }
    if (redLightTimer>0) {
        return TempFail;
    }

    Broadcast(viewer@"wants to play 'Red Light, Green Light'!");

    if (duration==0){
        duration = RedLightTimerDefault;
    }

    redLightTimer = duration;
    indLightTime=0;
    greenLight=True;

    return Success;
}

function int ForceWeaponUse(String viewer, String weaponName, int duration)
{
    local class<Weapon> weaponClass;
    local Pawn p;

    if (forceWeaponTimer>0) {
        return TempFail;
    }
    if (meleeTimer > 0) {
        return TempFail;
    }
    
    weaponClass = GetWeaponClassByName(weaponName);
    
    foreach AllActors(class'Pawn',p) {  //Probably could just iterate over PlayerControllers, but...
        if ((Vehicle(p)!=None) || p.IsA('Spectator') || p.Health<=0){
            continue;
        }
        GiveWeaponToPawn(p,weaponClass);
        
    }
    if (duration==0){
        duration = ForceWeaponTimerDefault;
    }
    forceWeaponTimer = duration;
    forcedWeapon = weaponClass;
     
    Broadcast(viewer$" forced everybody to use a specific weapon! ("$forcedWeapon.default.ItemName$")");
  
    return Success;

}

function int ResetDominationControlPoints(String viewer)
{
    local xDoubleDom game;
    local xDomPoint cp;
    local bool resetAny;

    game = xDoubleDom(Level.Game);
    
    if (game == None){
        return TempFail;
    }
    
    foreach AllActors(class'xDomPoint', cp) {
        if (cp.ControllingTeam!=None && cp.bControllable){
            //Level.Game.Broadcast(self,"Control Point controlled by "$cp.ControllingTeam.TeamName);
            resetAny=True;
            cp.ResetPoint(true);
        //} else {
            //Level.Game.Broadcast(self,"Control Point controlled by nobody");
        }
    }

    //Don't trigger if none of the control points were owned yet
    if (resetAny==False){
        return TempFail;
    }
    Broadcast(viewer$" reset all the control points!");
    return Success;
}

function int ReturnCTFFlags(String viewer)
{
    local CTFGame game;
    local CTFFlag flag;
    local bool resetAny;

    game = CTFGame(Level.Game);
    
    if (game == None){
        return TempFail;
    }
    
    foreach AllActors(class'CTFFlag', flag){
        if (flag.bHome==False){
            //Specifying BeginState seems unintuitive, but it bypasses the Begin: bit of the GameObject state
            //That Begin: bit causes problems if you're standing still when this comes through, as it immediately triggers you as having touched
            //the flag and gives it back to you.  This lets the flag go back even if you're standing still
            flag.GoToState('Home','BeginState');

            //Play the audio clip!
            BroadcastLocalizedMessage( Flag.MessageClass, 3, None, None, Flag.Team );
            resetAny=True;
        }
    }

    //Don't trigger if none of the control points were owned yet
    if (resetAny==False){
        return TempFail;
    }
    Broadcast(viewer$" returned the flags!");
    return Success;
}

function int EnableMoonPhysics(string viewer, int duration)
{
    if (gravityTimer>0) {
        return TempFail;
    }
    if (floodTimer>0) {
        return TempFail;
    }
    if (duration==0){
        duration = GravityTimerDefault;
    }
    Broadcast(viewer@"reduced gravity!");
    SetMoonPhysics(True);
    gravityTimer = duration;

    return Success;
}

function int EnableIcePhysics(string viewer, int duration)
{
    if (iceTimer>0) {
        return TempFail;
    }

    if (floodTimer>0) {
        return TempFail;
    }

    if (redLightTimer>0) {
        return TempFail;
    }
    
    if (duration==0){
        duration = IceTimerDefault;
    }
    
    Broadcast(viewer@"made the ground freeze!");
    SetIcePhysics(True);
    iceTimer = duration;

    return Success;
}

function int StartFlood(string viewer, int duration)
{
    if (floodTimer>0) {
        return TempFail;
    }
    if (iceTimer>0) {
        return TempFail;
    }
    if (gravityTimer>0) {
        return TempFail;
    }
    if (octoJumpTimer>0) {
        return TempFail;
    }
    if (speedTimer>0) {
        return TempFail;
    }
    Broadcast(viewer@"started a flood!");

    SetFlood(True);
    UpdateAllPawnsSwimState();
    if (duration==0){
        duration = FloodTimerDefault;
    }
    floodTimer = duration;
    return Success;
}

function int StartFog(string viewer, int duration)
{
    if (!isLocal){
        return TempFail;
    }
    if (fogTimer>0) {
        return TempFail;
    }
    Broadcast("In their restless dreams,"@viewer@"saw that town.  Silent Hill.");

    SetFog(True);
    if (duration==0){
        duration = FogTimerDefault;
    }
    fogTimer = duration;
    return Success;
}

function int StartBounce(string viewer, int duration)
{
    if (redLightTimer>0) {
        return TempFail;
    }
    if (bounceTimer>0) {
        return TempFail;
    }

    Broadcast(viewer@"threw everyone into the bouncy castle!");

    if (duration==0){
        duration = BounceTimerDefault;
    }
    bounceTimer = duration;
    return Success;
}


function int PlayTauntEffect(string viewer, int duration, optional name tauntSeq)
{
    local bool found;

    found=False;

    if (tauntTimer>0) {
        return TempFail;
    }

    found = PlayTaunt(tauntSeq);

    if (!found){
        return TempFail;
    }

    if (duration==0){
        duration = TauntTimerDefault;
    }
    tauntTimer = duration;
    curTaunt = tauntSeq;

    Broadcast(viewer@"made everyone wiggle!");

    return Success;
}

function bool PlayTaunt(optional name tauntSeq)
{
    local UnrealPlayer p;
    local Bot b;
    local bool found;
    local name tauntName;

    found=False;

    foreach AllActors(class'UnrealPlayer',p){
        if (p.Pawn==None){continue;}
        log("Playing taunt "$tauntSeq$" on player "$p.Pawn.Name);

        if (tauntSeq!=''){
            p.Taunt(tauntSeq);
        } else {
            p.RandomTaunt();
        }
        found=True;
    }

    foreach AllActors(class'Bot',b){
        if (b.Pawn==None){
            log("Skipping bot "$b.Name$" because it has no pawn");
            continue;
        }

        tauntName='';
        if (tauntSeq!=''){
            tauntName=tauntSeq;
        } else {
            tauntName=RandomBotTaunt(b);
        }

        if (!b.Pawn.FindValidTaunt(tauntName) && tauntSeq!=''){
            //If the specified taunt isn't valid for that pawn, let them do something else instead
            tauntName=RandomBotTaunt(b);
            log("Picking random taunt for "$b.Pawn.Name$" instead of the specified one because it wasn't valid");
        }

        if (tauntName!='' && b.Pawn.FindValidTaunt(tauntName)){
            b.Pawn.SetAnimAction(tauntName);
            found=True;
            log("Playing taunt "$tauntName$" on bot "$b.Pawn.Name);
        } else {
            log("Skipping bot "$b.Pawn.Name$" because it didn't find a valid taunt");
        }
    }

    return found;
}

function name RandomBotTaunt(Bot b)
{
	local int tauntNum;

	if(b.Pawn == None)
		return '';

	// First 4 taunts are 'order' anims. Don't pick them.
	tauntNum = Rand(b.Pawn.TauntAnims.Length - 4);
	return b.Pawn.TauntAnims[4 + tauntNum];
}



function int TeamBalance(string viewer)
{
    local Pawn p;
    local TeamGame tg;
    local UnrealTeamInfo NewTeam;
    local String playerName;
    local bool found;
    
    tg=TeamGame(Level.Game);
    if (tg==None){
        return TempFail;
    }

    //Don't allow this effect in single player ladder matches - it screws things up too much
    if (tg.CurrentGameProfile!=None && tg.CurrentGameProfile.bInLadderGame){
        return TempFail;
    }

    p = findPawnByScore(True,255); //Get Highest score player

    if (p == None || p.Controller==None || p.PlayerReplicationInfo==None) {
        return TempFail;
    }
    
    playerName = p.Controller.GetHumanReadableName();

    found=False;
    foreach AllActors(class'UnrealTeamInfo',NewTeam){
        if (newTeam!=p.Controller.PlayerReplicationInfo.Team){
            found=True;
            break;
        }
    }

    if (NewTeam==None || found==False){
        Broadcast("New team was none?");
        return TempFail;
    }

    p.Controller.StartSpot=None;

    if ( p.Controller.PlayerReplicationInfo.Team != None ) {
        p.Controller.PlayerReplicationInfo.Team.RemoveFromTeam(p.Controller);
    }

    if (NewTeam.AddToTeam(p.Controller)){
        tg.BroadcastLocalizedMessage( tg.GameMessageClass, 3, p.Controller.PlayerReplicationInfo, None, NewTeam );
    }

    p.PlayerChangedTeam();
    p.NotifyTeamChanged();
    p.Controller.Restart();

    Broadcast(viewer@"thought the teams needed to be rebalanced, so moved "$playerName$" to the other team!");

    return Success;
}

simulated function int SetAllPlayerAnnouncerVoice(string viewer, string announcer)
{
    local PlayerController pc;
    local string voiceName;
    local class<AnnouncerVoice> VoiceClass;
    
    if (!isLocal){
        return TempFail;
    }
    voiceName="";

    //For reasons, the announcer name doesn't include the package name, so attach it here
    announcer = "UnrealGame."$announcer;

    VoiceClass = class<AnnouncerVoice>(DynamicLoadObject(announcer,class'Class'));

    foreach AllActors(class'PlayerController',pc){
        if (pc.Pawn == None || pc.Pawn.Health<=0) { continue;}
        
        pc.StatusAnnouncer.Destroy();
        pc.StatusAnnouncer = pc.Spawn(VoiceClass);
        pc.RewardAnnouncer.Destroy();
        pc.RewardAnnouncer = pc.Spawn(VoiceClass);
        pc.PrecacheAnnouncements();

        voiceName = VoiceClass.Default.AnnouncerName;
    }

    if (voiceName==""){
        return TempFail;
    }

    Broadcast(viewer@"changed the announcer to "$voiceName);

    return Success;

}

function int HealOnslaughtCores(string viewer)
{
    local ONSPowerCore core;
    local bool found;

    found=false;
    foreach AllActors(class'ONSPowerCore',core){
        if (core.bFinalCore){
            if (core.Health>=core.DamageCapacity){continue;}
            core.Health = core.DamageCapacity;
            found=true;
        }
    }

    if (!found){
        return TempFail;
    }

    Broadcast(viewer@"fully healed the power cores!");

    return Success;
}

function int ResetOnslaughtPowerNodes(string viewer)
{
    local ONSPowerCore core;
    local bool found;

    found=false;
    foreach AllActors(class'ONSPowerCore',core){
        if (!core.bFinalCore && core.DefenderTeamIndex<2){
            core.PowerCoreReset();
            found=true;
        }
    }

    if (!found){
        return TempFail;
    }

    Broadcast(viewer@"reset all the power nodes!");

    return Success;
}

function int FumbleBombingRunBall(string viewer)
{
    local xBombingRun brGame;
    local int throwSpeed;

    brGame=xBombingRun(Level.Game);
    if (brGame==None){
        return TempFail;
    }

    if (brGame.Bomb==None){
        return TempFail;
    }

    if (brGame.Bomb.Holder==None){
        return TempFail;
    }

    throwSpeed = 2000+Rand(1000);
    brGame.Bomb.BroadcastLocalizedMessage( brGame.Bomb.MessageClass, 2, brGame.Bomb.Holder.PlayerReplicationInfo, None, brGame.Teams[brGame.Bomb.Holder.PlayerReplicationInfo.Team.TeamIndex] );
    brGame.Bomb.Throw(brGame.Bomb.Holder.Location,VRand()*throwSpeed);

    Broadcast(viewer@"caused the ball to be fumbled!");

    return Success;
}

function int BombingRunHotPotato(string viewer, int duration)
{
    local xBombingRun brGame;
    local CrowdControlBombFlag ccBomb;

    brGame=xBombingRun(Level.Game);
    if (brGame==None){
        return TempFail;
    }

    if (hotPotatoTimer>0) {
        return TempFail;
    }

    ccBomb = CrowdControlBombFlag(brGame.Bomb);
    if (ccBomb==None){
        Broadcast("The ball isn't a crowd control ball!");
        return TempFail;
    }

    if (ccBomb.Holder!=None){
        ccBomb.GrabTime=Level.TimeSeconds; //Reset the grab time to now
    }

    Broadcast(viewer@"made the ball a hot potato!");

    if (duration==0){
        duration = HotPotatoTimerDefault;
    }
    hotPotatoTimer = duration;
    return Success;
}

function int StartInfiniteAdrenaline(string viewer, int duration)
{
    local Controller c;
    
    if (infAdrenalineTimer>0){
        return TempFail;
    }

    foreach AllActors(class'Controller',c) {
        if (c.bAdrenalineEnabled==False){
            return TempFail;
        }
        c.Adrenaline=c.AdrenalineMax;
    }
   
    Broadcast(viewer$" has given everyone infinite adrenaline!");

    if (duration==0){
        duration = InfAdrenalineTimerDefault;
    }
    infAdrenalineTimer = duration;
    return Success;
}

function int StartOctoJump(String viewer, int duration)
{
    local xPawn p;

    if (octoJumpTimer>0) {
        return TempFail;
    }
    if (floodTimer>0) {
        return TempFail;
    }
    foreach AllActors(class'xPawn',p){
        origNumJumps=p.MaxMultiJump;
        break;
    }

    SetAllPlayersMultiJump(7,50);

    if (duration==0){
        duration = OctoJumpTimerDefault;
    }
    octoJumpTimer = duration;
    Broadcast(viewer$" made everyone able to jump 8 times!");
   
    return Success;   
}

function EndOctoJump()
{
    SetAllPlayersMultiJump(origNumJumps,class'xPawn'.Default.MultiJumpBoost);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                  CROWD CONTROL EFFECT MAPPING                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

function ResetEffectSelectability()
{
    effectSelectInit=False;
}

function HandleEffectSelectability(UT2k4CrowdControlLink ccLink)
{
    local bool adrenaline;
    local bool ladderGame;

    if (effectSelectInit==False){
        ladderGame = (Level.Game.CurrentGameProfile!=None && Level.Game.CurrentGameProfile.bInLadderGame);

        ccLink.sendEffectSelectability("full_fat",isLocal);
        ccLink.sendEffectSelectability("skin_and_bones",isLocal);
        ccLink.sendEffectSelectability("limbless",isLocal);
        ccLink.sendEffectSelectability("silent_hill",isLocal);
        ccLink.sendEffectSelectability("announcer",isLocal);
        ccLink.sendEffectSelectability("reset_domination_control_points",xDoubleDom(Level.Game)!=None);
        ccLink.sendEffectSelectability("return_ctf_flags",CTFGame(Level.Game)!=None);
        ccLink.sendEffectSelectability("team_balance",TeamGame(Level.Game)!=None && !ladderGame);
        ccLink.sendEffectSelectability("heal_onslaught_cores",ONSOnslaughtGame(Level.Game)!=None);
        ccLink.sendEffectSelectability("reset_onslaught_links",ONSOnslaughtGame(Level.Game)!=None);
        ccLink.sendEffectSelectability("fumble_bombing_run_ball",xBombingRun(Level.Game)!=None);
        ccLink.sendEffectSelectability("bombing_run_hot_potato",xBombingRun(Level.Game)!=None);
        ccLink.sendEffectSelectability("attack_team_double_dmg",xBombingRun(Level.Game)!=None || ASGameInfo(Level.Game)!=None);
        ccLink.sendEffectSelectability("defend_team_double_dmg",xBombingRun(Level.Game)!=None || ASGameInfo(Level.Game)!=None);
    
        //Adrenaline is disabled in Onslaught
        adrenaline = IsAdrenalineActive();
        ccLink.sendEffectSelectability("full_adrenaline",adrenaline);
        ccLink.sendEffectSelectability("last_place_ultra_adrenaline",adrenaline);
        ccLink.sendEffectSelectability("all_berserk",adrenaline);
        ccLink.sendEffectSelectability("all_invisible",adrenaline);
        ccLink.sendEffectSelectability("all_regen",adrenaline);
    
        effectSelectInit=True;
    }
}

function int BranchCrowdControlType(string code, string param[5], string viewer, int type, int duration) {
    local int result;

    switch (type){
        case CCType_Start:
            result = doCrowdControlEvent(code,param,viewer,type,duration);
            break;
        case CCType_Stop:
            if (code==""){
                //Stop all
                StopAllCrowdControlEvents();
            } else {
                //Stop specific effect
                result = StopCrowdControlEvent(code);
            }
            break;
        default:
            result = Failed;
            break;
    }

    return result;
}

//Make sure to add any timed effects into this list
function StopAllCrowdControlEvents()
{
    StopCrowdControlEvent("third_person");
    StopCrowdControlEvent("gotta_go_fast"); //and gotta_go_slow, first_place_slow
    StopCrowdControlEvent("ice_physics");
    StopCrowdControlEvent("melee_only"); //and all forced weapon modes
    StopCrowdControlEvent("vampire_mode");
    StopCrowdControlEvent("big_head"); //and all body horror effects
    StopCrowdControlEvent("low_grav");
    StopCrowdControlEvent("flood");
    StopCrowdControlEvent("silent_hill");
    StopCrowdControlEvent("bouncy_castle");
    StopCrowdControlEvent("bombing_run_hot_potato");
    StopCrowdControlEvent("attack_team_double_dmg");
    StopCrowdControlEvent("head_shots_only");
    StopCrowdControlEvent("infinite_adrenaline");
    StopCrowdControlEvent("thorns");
    StopCrowdControlEvent("octojump");
    StopCrowdControlEvent("pint_sized");
    StopCrowdControlEvent("thrust");
    StopCrowdControlEvent("winner_half_dmg");
    StopCrowdControlEvent("red_light_green_light");
    StopCrowdControlEvent("massive_momentum");
}

function int StopCrowdControlEvent(string code, optional bool bKnownStop)
{
    switch(code) {
        case "third_person":
            if (bKnownStop || behindTimer > 0){
                SetAllPlayersBehindView(False);
                Broadcast("Returning to first person view...");
                behindTimer=0;
            }
            break;
        case "gotta_go_fast":
        case "gotta_go_slow":
        case "first_place_slow":
            if (bKnownStop || speedTimer > 0){
                SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed);
                Broadcast("Returning to normal move speed...");
                speedTimer=0;
                targetPlayer="";
            }
            break;
        case "ice_physics":
            if (bKnownStop || iceTimer > 0){
                SetIcePhysics(False);
                Broadcast("The ground thaws...");
                iceTimer=0;
            }
            break;
        case "melee_only":
            if (bKnownStop || meleeTimer > 0){
                Broadcast("You may use ranged weapons again...");
                meleeTimer=0;
            }
            break;
        case "force_weapon_use":
        case "force_instagib":
        case "force_redeemer":
            if (bKnownStop || forceWeaponTimer > 0){
                Broadcast("You can use any weapon again...");
                forcedWeapon = None;
                forceWeaponTimer=0;
            }
            break;
        case "vampire_mode":
            if (bKnownStop || vampireTimer > 0){
                RemoveGameRule(class'WorkingVampireGameRules');
                Broadcast("You no longer feed on the blood of others...");
                vampireTimer=0;
            }
            break;
        case "big_head":
        case "headless":
        case "limbless":
        case "full_fat":
        case "skin_and_bones":
            if (bKnownStop || bodyEffectTimer > 0){
                Broadcast("Your body returns to normal...");
                RestoreBodyScale();
                BodyEffect = BE_None;
                bodyEffectTimer=0;
            }
            break;
        case "pint_sized":
            if (bKnownStop || bodyEffectTimer > 0){
                Broadcast("Your body returns to normal...");
                EndPintSized();
                BodyEffect = BE_None;
                bodyEffectTimer=0;
            }
            break;
        case "low_grav":
            if (bKnownStop || gravityTimer > 0){
                SetMoonPhysics(False);
                Broadcast("Gravity returns to normal...");
                gravityTimer=0;
            }
            break;
        case "flood":
            if (bKnownStop || floodTimer > 0){
                SetFlood(False);
                UpdateAllPawnsSwimState();
                Broadcast("The flood drains away...");
                floodTimer=0;
            }
            break;
        case "silent_hill":
            if (bKnownStop || fogTimer > 0){
                SetFog(False);
                Broadcast("The fog drifts away...");
                fogTimer=0;
            }
            break;
        case "bouncy_castle":
            if (bKnownStop || bounceTimer > 0){
                Broadcast("The bouncy castle disappeared...");
                bounceTimer=0;
            }
            break;
        case "thrust":
            if (bKnownStop || tauntTimer > 0){
                Broadcast("The time for taunting has ended...");
                tauntTimer=0;
                curTaunt='';
            }
            break;
        case "bombing_run_hot_potato":
            if (bKnownStop || hotPotatoTimer > 0){
                Broadcast("The hot potato cools off...");
                hotPotatoTimer=0;
            }
            break;
        case "attack_team_double_dmg":
        case "defend_team_double_dmg":
            if (bKnownStop || teamDamageTimer > 0){
                RemoveGameRule(class'DefenseDoubleDamageRules');
                RemoveGameRule(class'OffenseDoubleDamageRules');
                Broadcast("Team damage returns to normal...");
                teamDamageTimer=0;
            }
            break;
        case "head_shots_only":
            if (bKnownStop || headShotTimer > 0){
                RemoveGameRule(class'HeadShotsOnlyRules');
                Broadcast("Damage other than head shots count again...");
                headShotTimer=0;
            }
            break;
        case "thorns":
            if (bKnownStop || thornsTimer > 0){
                RemoveGameRule(class'ThornsRules');
                Broadcast("The thorns wither away...");
                thornsTimer=0;
            }
            break;
        case "infinite_adrenaline":
            if (bKnownStop || infAdrenalineTimer > 0){
                Broadcast("Your adrenaline has limits again...");
                infAdrenalineTimer=0;
            }
            break;
        case "octojump":
            if (bKnownStop || octoJumpTimer > 0){
                EndOctoJump();
                Broadcast("You lose the ability to jump 8 times...");
                octoJumpTimer=0;
            }
            break;
        case "winner_half_dmg":
            if (bKnownStop || winHalfDmgTimer > 0){
                RemoveGameRule(class'WinningHalfDamageRules');
                Broadcast("The winner can do full damage again...");
                winHalfDmgTimer=0;
            }
            break;
        case "red_light_green_light":
            if (bKnownStop || redLightTimer > 0){
                Broadcast("'Red Light, Green Light' is over!");
                redLightTimer=0;
                indLightTime=0;
            }
            break;
        case "massive_momentum":
            if (bKnownStop || momentumTimer > 0){
                RemoveGameRule(class'MassiveMomentumRules');
                Broadcast("Damage imparts normal momentum again...");
                momentumTimer=0;
            }
            break;
            
    }
    return Success;
}

//Effects missing that were in UT99
//Spawn a bot (attack/defend)

//Ideas that could be added:
//-Spawn a vehicle (all the ONSVehicle types, I guess) - would need various space checks and stuff
//-Play a (random?) announcement
//-Objective holder (Flag or ball) goes slow
//-Can throw ball harder (or softer?)
//-Multiple Bombing Run Balls (Multiball)
//-Swap goal locations (Ball goal or flags)
//-Reset Bombing Run Ball
//-General half damage for a minute (mutually exclusive with team damage effects)
//-Bombing run ball knocks you back when you receive it

simulated function int doCrowdControlEvent(string code, string param[5], string viewer, int type, int duration) {
    
    //Universal checks
    if(!IsGameActive()){ //Only allow effects while the game is actually active
        return TempFail;
    }
    
    switch(code) {
        case "sudden_death":  //Everyone loses all armour and goes down to one health
            return SuddenDeath(viewer);
        case "full_heal":  //Everyone gets brought up to 100 health (not brought down if overhealed though)
            return FullHeal(viewer);
        case "full_armour": //Everyone gets a shield belt
            return FullArmour(viewer);
        case "full_adrenaline":
            return FullAdrenaline(viewer);
        case "give_health": //Give an arbitrary amount of health.  Allows overhealing, up to 199
            return GiveHealth(viewer,Int(param[0]));
        case "third_person":  //Switches to behind view for everyone
            return ThirdPerson(viewer,duration);
        case "bonus_dmg":   //Gives everyone a damage bonus item (triple damage)
            return GiveDamageItem(viewer);
        case "gotta_go_fast":  //Makes everyone really fast for a minute
            return GottaGoFast(viewer, duration);
        case "gotta_go_slow":  //Makes everyone really slow for 15 seconds (A minute was too much!)
            return GottaGoSlow(viewer, duration);
        case "thanos":  //Every player has a 50% chance of being killed
            return ThanosSnap(viewer);
        case "swap_player_position":  //Picks two random players and swaps their positions
            return SwapAllPlayers(viewer); //Swaps ALL players
        case "no_ammo":  //Removes all ammo from all players
            return NoAmmo(viewer); 
        case "give_ammo":  //Gives X boxes of a particular ammo type to all players
            return giveAmmo(viewer,param[0],Int(param[1]));
        case "nudge":  //All players get nudged slightly in a random direction
            return doNudge(viewer);
        case "drop_selected_item":  //Destroys the currently equipped weapon (Except for melee, translocator, and enforcers)
            return DropSelectedWeapon(viewer);
        case "give_weapon":  //Gives all players a specific weapon
            return GiveWeapon(viewer,param[0]);
        case "give_instagib":  //This is separate so that it can be priced differently
            return GiveWeapon(viewer,"supershockrifle");
        case "give_redeemer":  //This is separate so that it can be priced differently
            return GiveWeapon(viewer,"redeemer");
        case "melee_only": //Force everyone to use melee for the duration (continuously check weapon and switch to melee choice)
            return StartMeleeOnlyTime(viewer,duration);
        case "last_place_shield": //Give last place player a shield belt
            return LastPlaceShield(viewer);
        case "last_place_bonus_dmg": //Give last place player a bonus damage item
            return LastPlaceDamage(viewer);
        case "first_place_slow": //Make the first place player really slow   
            return FirstPlaceSlow(viewer, duration);
        case "blue_redeemer_shell": //Blow up first place player
            return BlueRedeemerShell(viewer);
        case "vampire_mode":  //Inflicting damage heals you for the damage dealt
            return StartVampireMode(viewer, duration);
        case "force_weapon_use": //Give everybody a weapon, then force them to use it for the duration.  Ammo tops up if run out  
            return ForceWeaponUse(viewer,param[0],duration);
        case "force_instagib": //Give everybody an enhanced shock rifle, then force them to use it for the duration.  Ammo tops up if run out  
            return ForceWeaponUse(viewer,"supershockrifle",duration);
        case "force_redeemer": //Give everybody a redeemer, then force them to use it for the duration.  Ammo tops up if run out  
            return ForceWeaponUse(viewer,"redeemer",duration);
        case "reset_domination_control_points":
            return ResetDominationControlPoints(viewer);
        case "return_ctf_flags":
            return ReturnCTFFlags(viewer);
        case "big_head":
            return StartBigHeadMode(viewer,duration);
        case "headless":
            return StartHeadlessMode(viewer,duration);
        case "limbless":
            return StartLimblessMode(viewer,duration); //TODO: Make this work in multiplayer somehow
        case "full_fat":
            return StartFullFatMode(viewer,duration); //TODO: Make this work in multiplayer somehow
        case "skin_and_bones":
            return StartSkinAndBonesMode(viewer,duration); //TODO: Make this work in multiplayer somehow
        case "low_grav":
            return EnableMoonPhysics(viewer, duration); 
        case "ice_physics":
            return EnableIcePhysics(viewer, duration);
        case "flood":
            return StartFlood(viewer, duration);
        case "last_place_ultra_adrenaline":
            return LastPlaceUltraAdrenaline(viewer);
        case "all_berserk":
            return AllPlayersBerserk(viewer);
        case "all_invisible":
            return AllPlayersInvisible(viewer);
        case "all_regen":
            return AllPlayersRegen(viewer);
        case "thrust":
            return PlayTauntEffect(viewer,duration,'PThrust');
        case "team_balance":
            return TeamBalance(viewer);
        case "announcer":
            return SetAllPlayerAnnouncerVoice(viewer,param[0]); //TODO: Make this work in multiplayer somehow
        case "silent_hill":
            return StartFog(viewer, duration);//TODO: Make this work in multiplayer somehow
        case "bouncy_castle":
            return StartBounce(viewer, duration); 
        case "heal_onslaught_cores":
            return HealOnslaughtCores(viewer);
        case "reset_onslaught_links":
            return ResetOnslaughtPowerNodes(viewer);
        case "fumble_bombing_run_ball":
            return FumbleBombingRunBall(viewer);
        case "bombing_run_hot_potato":
            return BombingRunHotPotato(viewer,duration);
        case "attack_team_double_dmg":
            return StartTeamDamageMode(viewer, duration, true);
        case "defend_team_double_dmg":
            return StartTeamDamageMode(viewer, duration, false);
        case "head_shots_only":
            return StartHeadShotsOnly(viewer,duration);
        case "infinite_adrenaline":
            return StartInfiniteAdrenaline(viewer,duration);
        case "thorns":
            return StartThornsMode(viewer,duration);
        case "octojump":
            return StartOctoJump(viewer,duration);
        case "pint_sized":
            return StartPintSized(viewer,duration);
        case "winner_half_dmg":
            return StartWinnerHalfDamageMode(viewer,duration);
        case "red_light_green_light":
            return StartRedLightGreenLight(viewer,duration);
        case "massive_momentum":
            return StartMassiveMomentum(viewer,duration);
        default:
            Broadcast("Got Crowd Control Effect -   code: "$code$"   viewer: "$viewer );
            break;
        
    }
    
    return Success;
}

defaultproperties
{
      bHidden=True
      bAlwaysRelevant=True
      bNetTemporary=False
      RemoteRole=ROLE_SimulatedProxy
      NetUpdateFrequency=4.000000
}
