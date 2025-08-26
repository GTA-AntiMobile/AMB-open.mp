#include <YSI\YSI_Coding\y_hooks>

#if defined _INC_HITMARKER
    #endinput
#endif
#define _INC_HITMARKER

#define MAX_HIT_MARKERS         8
#define HIT_MARKER_DURATION     2500
#define HIT_MARKER_FADE_TIME    2000
#define HIT_MARKER_UPDATE_RATE  100
#define HIT_MARKER_SPACING      16.0

enum E_HIT_TYPE
{
    HIT_TYPE_DAMAGE = 0,
    HIT_TYPE_CRITICAL,
    HIT_TYPE_HEAL,
    HIT_TYPE_ARMOR,
    HIT_TYPE_ATTACKER_DAMAGE = 10,
    HIT_TYPE_ATTACKER_CRITICAL,
    HIT_TYPE_ATTACKER_HEAL,
    HIT_TYPE_ATTACKER_ARMOR
};

enum E_HIT_MARKER_DATA
{
    bool:hm_Active,
    Float:hm_Damage,
    hm_Type,
    hm_StartTime,
    Float:hm_X,
    Float:hm_Y,
    PlayerText:hm_TextDraw,
    hm_Alpha
};

static HitMarkerData[MAX_PLAYERS][MAX_HIT_MARKERS][E_HIT_MARKER_DATA];
static PlayerHitMarkerCount[MAX_PLAYERS];
static PlayerHitMarkerTimer[MAX_PLAYERS];
static bool:HitMarkerSystemActive[MAX_PLAYERS];

static const BodyPartNames[][] = {
    "Than",  
    "Mong", 
    "Tay trai", 
    "Tay phai", 
    "Chan trai", 
    "Chan phai", 
    "Dau"
};



stock GetBodyPartName(bodypart, bodyname[], len)
{
    if(bodypart >= 0 && bodypart < sizeof(BodyPartNames))
    {
        strcpy(bodyname, BodyPartNames[bodypart], len);
    }
    else
    {
        strcpy(bodyname, "Than", len);
    }
    return 1;
}

stock CreateHitMarkerTextDraw(playerid, slot, Float:damage, type, const shootername[] = "", bodypart = 3, weaponid = 0)
{
    new string[256];
    new bodyname[16];
    new weaponname[32];
    
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    GetWeaponName(weaponid, weaponname, sizeof(weaponname));
    
    new colorCode[12], iconCode[8];
    if(type >= HIT_TYPE_ATTACKER_DAMAGE)
    {
        strcpy(colorCode, "~y~", sizeof(colorCode));
        strcpy(iconCode, "⚔", sizeof(iconCode));
    }
    else
    {
        strcpy(colorCode, "~r~", sizeof(colorCode));
        strcpy(iconCode, "💥", sizeof(iconCode));
    }
    
    if(strlen(shootername) > 0)
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "%s%s ~w~[~b~%.0f~w~] ~y~%s ~g~%s", iconCode, colorCode, damage, bodyname, weaponname);
        else
            format(string, sizeof(string), "%s%s ~w~[~b~%.1f~w~] ~y~%s ~g~%s", iconCode, colorCode, damage, bodyname, weaponname);
    }
    else
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "%s%s ~w~[~b~%.0f~w~] ~y~%s", iconCode, colorCode, damage, bodyname);
        else
            format(string, sizeof(string), "%s%s ~w~[~b~%.1f~w~] ~y~%s", iconCode, colorCode, damage, bodyname);
    }
    
    HitMarkerData[playerid][slot][hm_TextDraw] = CreatePlayerTextDraw(playerid, 
        HitMarkerData[playerid][slot][hm_X],
        HitMarkerData[playerid][slot][hm_Y],
        string);
    
    PlayerTextDrawLetterSize(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0.250, 1.100);
    PlayerTextDrawColor(playerid, HitMarkerData[playerid][slot][hm_TextDraw], -1);
    PlayerTextDrawSetShadow(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 2);
    PlayerTextDrawSetOutline(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 2);
    PlayerTextDrawBackgroundColor(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0x00000088);
    PlayerTextDrawAlignment(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 2);
    PlayerTextDrawFont(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    PlayerTextDrawUseBox(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    PlayerTextDrawBoxColor(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0x00000066);
    PlayerTextDrawTextSize(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0.0, 200.0);
    
    PlayerTextDrawShow(playerid, HitMarkerData[playerid][slot][hm_TextDraw]);
    
    return 1;
}

stock UpdateHitMarker(playerid, slot)
{
    if(!HitMarkerData[playerid][slot][hm_Active])
        return 0;
    
    new elapsed = GetTickCount() - HitMarkerData[playerid][slot][hm_StartTime];
    
    if(elapsed >= HIT_MARKER_DURATION)
    {
        DestroyHitMarker(playerid, slot);
        return 0;
    }
    
    if(elapsed >= HIT_MARKER_FADE_TIME)
    {
        new alpha = 255 - ((elapsed - HIT_MARKER_FADE_TIME) * 255 / (HIT_MARKER_DURATION - HIT_MARKER_FADE_TIME));
        if(alpha < 0) alpha = 0;
        
        if(HitMarkerData[playerid][slot][hm_Alpha] != alpha)
        {
            HitMarkerData[playerid][slot][hm_Alpha] = alpha;
            PlayerTextDrawColor(playerid, HitMarkerData[playerid][slot][hm_TextDraw], (alpha << 24) | 0xFFFFFF);
            PlayerTextDrawShow(playerid, HitMarkerData[playerid][slot][hm_TextDraw]);
        }
    }
    
    return 1;
}

stock DestroyHitMarker(playerid, slot)
{
    if(!HitMarkerData[playerid][slot][hm_Active])
        return 0;
    
    if(HitMarkerData[playerid][slot][hm_TextDraw] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, HitMarkerData[playerid][slot][hm_TextDraw]);
        HitMarkerData[playerid][slot][hm_TextDraw] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    HitMarkerData[playerid][slot][hm_Active] = false;
    HitMarkerData[playerid][slot][hm_Damage] = 0.0;
    HitMarkerData[playerid][slot][hm_Type] = 0;
    HitMarkerData[playerid][slot][hm_StartTime] = 0;
    HitMarkerData[playerid][slot][hm_X] = 0.0;
    HitMarkerData[playerid][slot][hm_Y] = 0.0;
    HitMarkerData[playerid][slot][hm_Alpha] = 255;
    
    PlayerHitMarkerCount[playerid]--;
    if(PlayerHitMarkerCount[playerid] < 0)
        PlayerHitMarkerCount[playerid] = 0;
    
    return 1;
}

stock GetAvailableHitMarkerSlot(playerid)
{
    for(new i = 0; i < MAX_HIT_MARKERS; i++)
    {
        if(!HitMarkerData[playerid][i][hm_Active])
            return i;
    }
    
    new oldestSlot = 0;
    new oldestTime = HitMarkerData[playerid][0][hm_StartTime];
    
    for(new i = 1; i < MAX_HIT_MARKERS; i++)
    {
        if(HitMarkerData[playerid][i][hm_StartTime] < oldestTime)
        {
            oldestTime = HitMarkerData[playerid][i][hm_StartTime];
            oldestSlot = i;
        }
    }
    
    DestroyHitMarker(playerid, oldestSlot);
    return oldestSlot;
}

stock CreateHitMarker(playerid, Float:damage, type = HIT_TYPE_DAMAGE, const shootername[] = "", bodypart = 3, weaponid = 0)
{
    if(!IsPlayerConnected(playerid) || !HitMarkerSystemActive[playerid])
        return 0;
    
    new slot = GetAvailableHitMarkerSlot(playerid);
    
    new Float:baseX = 500.0;
    new Float:baseY = 140.0;
    new Float:offsetY = slot * HIT_MARKER_SPACING;
    
    HitMarkerData[playerid][slot][hm_Active] = true;
    HitMarkerData[playerid][slot][hm_Damage] = damage;
    HitMarkerData[playerid][slot][hm_Type] = type;
    HitMarkerData[playerid][slot][hm_StartTime] = GetTickCount();
    HitMarkerData[playerid][slot][hm_X] = baseX;
    HitMarkerData[playerid][slot][hm_Y] = baseY + offsetY;
    HitMarkerData[playerid][slot][hm_Alpha] = 255;
    
    CreateHitMarkerTextDraw(playerid, slot, damage, type, shootername, bodypart, weaponid);
    
    PlayerHitMarkerCount[playerid]++;
    StartHitMarkerTimer(playerid);
    
    return 1;
}

stock CreateAttackerHitMarker(playerid, Float:damage, const targetname[], bodypart = 3, weaponid = 0)
{
    if(!IsPlayerConnected(playerid) || !HitMarkerSystemActive[playerid])
        return 0;
    
    new slot = GetAvailableHitMarkerSlot(playerid);
    
    new Float:baseX = 140.0;
    new Float:baseY = 140.0;
    new Float:offsetY = slot * HIT_MARKER_SPACING;
    
    HitMarkerData[playerid][slot][hm_Active] = true;
    HitMarkerData[playerid][slot][hm_Damage] = damage;
    HitMarkerData[playerid][slot][hm_Type] = HIT_TYPE_ATTACKER_DAMAGE;
    HitMarkerData[playerid][slot][hm_StartTime] = GetTickCount();
    HitMarkerData[playerid][slot][hm_X] = baseX;
    HitMarkerData[playerid][slot][hm_Y] = baseY + offsetY;
    HitMarkerData[playerid][slot][hm_Alpha] = 255;
    
    CreateAttackerHitMarkerTextDraw(playerid, slot, damage, targetname, bodypart, weaponid);
    
    PlayerHitMarkerCount[playerid]++;
    StartHitMarkerTimer(playerid);
    
    return 1;
}

stock CreateAttackerHitMarkerTextDraw(playerid, slot, Float:damage, const targetname[], bodypart = 3, weaponid = 0)
{
    new string[144];
    new bodyname[16];
    new weaponname[32];
    
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    GetWeaponName(weaponid, weaponname, sizeof(weaponname));
    
    if(strlen(targetname) > 0)
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~y~+%.0f ~w~(%s) ~g~%s ~b~%s", damage, targetname, bodyname, weaponname);
        else
            format(string, sizeof(string), "~y~+%.1f ~w~(%s) ~g~%s ~b~%s", damage, targetname, bodyname, weaponname);
    }
    else
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~y~+%.0f ~g~%s ~b~%s", damage, bodyname, weaponname);
        else
            format(string, sizeof(string), "~y~+%.1f ~g~%s ~b~%s", damage, bodyname, weaponname);
    }
    
    HitMarkerData[playerid][slot][hm_TextDraw] = CreatePlayerTextDraw(playerid, 
        HitMarkerData[playerid][slot][hm_X], 
        HitMarkerData[playerid][slot][hm_Y], 
        string);
    
    PlayerTextDrawLetterSize(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0.200, 0.950);
    PlayerTextDrawColor(playerid, HitMarkerData[playerid][slot][hm_TextDraw], -1);
    PlayerTextDrawSetShadow(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    PlayerTextDrawSetOutline(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    PlayerTextDrawAlignment(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 2);
    PlayerTextDrawFont(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    
    PlayerTextDrawShow(playerid, HitMarkerData[playerid][slot][hm_TextDraw]);
    
    return 1;
}

forward UpdatePlayerHitMarkers(playerid);
public UpdatePlayerHitMarkers(playerid)
{
    if(!IsPlayerConnected(playerid) || !HitMarkerSystemActive[playerid])
    {
        if(PlayerHitMarkerTimer[playerid] != -1)
        {
            KillTimer(PlayerHitMarkerTimer[playerid]);
            PlayerHitMarkerTimer[playerid] = -1;
        }
        return 0;
    }
    
    new activeMarkers = 0;
    
    for(new i = 0; i < MAX_HIT_MARKERS; i++)
    {
        if(HitMarkerData[playerid][i][hm_Active])
        {
            if(UpdateHitMarker(playerid, i))
            {
                activeMarkers++;
            }
        }
    }
    
    if(activeMarkers == 0 && PlayerHitMarkerTimer[playerid] != -1)
    {
        KillTimer(PlayerHitMarkerTimer[playerid]);
        PlayerHitMarkerTimer[playerid] = -1;
    }
    
    return 1;
}

stock InitializeHitMarkerSystem(playerid)
{
    PlayerHitMarkerCount[playerid] = 0;
    PlayerHitMarkerTimer[playerid] = -1;
    HitMarkerSystemActive[playerid] = true;
    
    for(new i = 0; i < MAX_HIT_MARKERS; i++)
    {
        HitMarkerData[playerid][i][hm_Active] = false;
        HitMarkerData[playerid][i][hm_TextDraw] = PlayerText:INVALID_TEXT_DRAW;
        HitMarkerData[playerid][i][hm_Alpha] = 255;
    }
    
    return 1;
}

stock CleanupHitMarkerSystem(playerid)
{
    if(PlayerHitMarkerTimer[playerid] != -1)
    {
        KillTimer(PlayerHitMarkerTimer[playerid]);
        PlayerHitMarkerTimer[playerid] = -1;
    }
    
    for(new i = 0; i < MAX_HIT_MARKERS; i++)
    {
        if(HitMarkerData[playerid][i][hm_Active])
        {
            DestroyHitMarker(playerid, i);
        }
    }
    
    PlayerHitMarkerCount[playerid] = 0;
    HitMarkerSystemActive[playerid] = false;
    
    return 1;
}

stock StartHitMarkerTimer(playerid)
{
    if(PlayerHitMarkerTimer[playerid] == -1 && HitMarkerSystemActive[playerid])
    {
        PlayerHitMarkerTimer[playerid] = SetTimerEx("UpdatePlayerHitMarkers", HIT_MARKER_UPDATE_RATE, true, "i", playerid);
    }
    return 1;
}

stock ToggleHitMarkerSystem(playerid, bool:toggle)
{
    if(!IsPlayerConnected(playerid))
        return 0;
    
    HitMarkerSystemActive[playerid] = toggle;
    
    if(!toggle)
    {
        CleanupHitMarkerSystem(playerid);
    }
    
    return 1;
}

stock GetHitMarkerCount(playerid)
{
    return PlayerHitMarkerCount[playerid];
}

hook OnPlayerConnect(playerid)
{
    InitializeHitMarkerSystem(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    CleanupHitMarkerSystem(playerid);
    return 1;
}

hook OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(issuerid) || issuerid == INVALID_PLAYER_ID)
        return 1;
    
    if(amount > 0.0)
    {
        new shootername[MAX_PLAYER_NAME];
        GetPlayerName(issuerid, shootername, sizeof(shootername));
        
        CreateHitMarker(playerid, amount, HIT_TYPE_DAMAGE, shootername, bodypart, weaponid);
    }
    
    return 1;
}

hook OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(damagedid))
        return 1;
    
    if(amount > 0.0)
    {
        new targetname[MAX_PLAYER_NAME];
        GetPlayerName(damagedid, targetname, sizeof(targetname));
        
        CreateAttackerHitMarker(playerid, amount, targetname, bodypart, weaponid);
    }
    
    return 1;
}

