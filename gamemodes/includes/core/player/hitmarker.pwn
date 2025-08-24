#include <YSI\YSI_Coding\y_hooks>

#if defined _INC_HITMARKER
    #endinput
#endif
#define _INC_HITMARKER

#define MAX_HIT_MARKERS         5
#define HIT_MARKER_DURATION     3000
#define HIT_MARKER_FADE_TIME    2500
#define HIT_MARKER_UPDATE_RATE  200

#define HIT_TYPE_DAMAGE         0
#define HIT_TYPE_CRITICAL       1
#define HIT_TYPE_HEAL           2
#define HIT_TYPE_ARMOR          3
#define HIT_TYPE_ATTACKER_DAMAGE    10
#define HIT_TYPE_ATTACKER_CRITICAL  11
#define HIT_TYPE_ATTACKER_HEAL      12
#define HIT_TYPE_ATTACKER_ARMOR     13

enum E_HIT_MARKER_DATA
{
    bool:hm_Active,
    Float:hm_Damage,
    hm_Type,
    hm_Timer,
    hm_StartTime,
    Float:hm_StartX,
    Float:hm_StartY,
    Float:hm_CurrentX,
    Float:hm_CurrentY,
    Float:hm_VelocityX,
    Float:hm_VelocityY,
    PlayerText:hm_TextDraw
};

static HitMarkerData[MAX_PLAYERS][MAX_HIT_MARKERS][E_HIT_MARKER_DATA];
static PlayerHitMarkerCount[MAX_PLAYERS];
static PlayerHitMarkerTimer[MAX_PLAYERS];

stock GetBodyPartName(bodypart, bodyname[], len)
{
    switch(bodypart)
    {
        case 3: format(bodyname, len, "Than");
        case 4: format(bodyname, len, "Mong");
        case 5: format(bodyname, len, "Tay trai");
        case 6: format(bodyname, len, "Tay phai");
        case 7: format(bodyname, len, "Chan trai");
        case 8: format(bodyname, len, "Chan phai");
        case 9: format(bodyname, len, "Dau");
        default: format(bodyname, len, "Than");
    }
    return 1;
}

stock CreateHitMarkerTextDraw(playerid, slot, Float:damage, type, const shootername[] = "", bodypart = 3, weaponid = 0)
{
    #pragma unused type
    new string[128];
    new bodyname[16];
    new weaponname[32];
    
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    GetWeaponName(weaponid, weaponname, sizeof(weaponname));
    
    if(strlen(shootername) > 0)
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~r~-%.0f ~w~(%s) ~y~%s ~g~%s", damage, shootername, bodyname, weaponname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~r~-%.1f ~w~(%s) ~y~%s ~g~%s", damage, shootername, bodyname, weaponname);
        else
            format(string, sizeof(string), "~r~-%.1f ~w~(%s) ~y~%s ~g~%s", damage, shootername, bodyname, weaponname);
    }
    else
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~r~-%.0f ~y~%s ~g~%s", damage, bodyname, weaponname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~r~-%.1f ~y~%s ~g~%s", damage, bodyname, weaponname);
        else
            format(string, sizeof(string), "~r~-%.1f ~y~%s ~g~%s", damage, bodyname, weaponname);
    }
    
    HitMarkerData[playerid][slot][hm_TextDraw] = CreatePlayerTextDraw(playerid, 
        HitMarkerData[playerid][slot][hm_CurrentX],
        HitMarkerData[playerid][slot][hm_CurrentY],
        string);
    
    PlayerTextDrawLetterSize(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0.220, 1.000);
    PlayerTextDrawColor(playerid, HitMarkerData[playerid][slot][hm_TextDraw], -1);
    PlayerTextDrawSetShadow(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    PlayerTextDrawSetOutline(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    PlayerTextDrawAlignment(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 2);
    PlayerTextDrawFont(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 1);
    
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
    
    if(HitMarkerData[playerid][slot][hm_Timer] != -1)
    {
        KillTimer(HitMarkerData[playerid][slot][hm_Timer]);
        HitMarkerData[playerid][slot][hm_Timer] = -1;
    }
    
    HitMarkerData[playerid][slot][hm_Active] = false;
    HitMarkerData[playerid][slot][hm_Damage] = 0.0;
    HitMarkerData[playerid][slot][hm_Type] = 0;
    HitMarkerData[playerid][slot][hm_StartTime] = 0;
    HitMarkerData[playerid][slot][hm_StartX] = 0.0;
    HitMarkerData[playerid][slot][hm_StartY] = 0.0;
    HitMarkerData[playerid][slot][hm_CurrentX] = 0.0;
    HitMarkerData[playerid][slot][hm_CurrentY] = 0.0;
    HitMarkerData[playerid][slot][hm_VelocityX] = 0.0;
    HitMarkerData[playerid][slot][hm_VelocityY] = 0.0;
    
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
    if(!IsPlayerConnected(playerid))
        return 0;
    
    new slot = GetAvailableHitMarkerSlot(playerid);
    
    new Float:baseX = 500.0;
    new Float:baseY = 140.0;
    new Float:offsetY = slot * 14.0; // Giảm khoảng cách giữa các hitmarker
    
    HitMarkerData[playerid][slot][hm_Active] = true;
    HitMarkerData[playerid][slot][hm_Damage] = damage;
    HitMarkerData[playerid][slot][hm_Type] = type;
    HitMarkerData[playerid][slot][hm_StartTime] = GetTickCount();
    HitMarkerData[playerid][slot][hm_StartX] = baseX;
    HitMarkerData[playerid][slot][hm_StartY] = baseY + offsetY;
    HitMarkerData[playerid][slot][hm_CurrentX] = baseX;
    HitMarkerData[playerid][slot][hm_CurrentY] = baseY + offsetY;
    
    HitMarkerData[playerid][slot][hm_VelocityX] = 0.0;
    HitMarkerData[playerid][slot][hm_VelocityY] = 0.0;
    
    CreateHitMarkerTextDraw(playerid, slot, damage, type, shootername, bodypart, weaponid);
    
    PlayerHitMarkerCount[playerid]++;
    
    return 1;
}

stock CreateAttackerHitMarker(playerid, Float:damage, const targetname[], bodypart = 3, weaponid = 0)
{
    if(!IsPlayerConnected(playerid))
        return 0;
    
    new slot = GetAvailableHitMarkerSlot(playerid);
    
    new Float:baseX = 140.0;
    new Float:baseY = 140.0;
    new Float:offsetY = slot * 14.0; // Giảm khoảng cách giữa các hitmarker
    
    HitMarkerData[playerid][slot][hm_Active] = true;
    HitMarkerData[playerid][slot][hm_Damage] = damage;
    HitMarkerData[playerid][slot][hm_Type] = HIT_TYPE_DAMAGE;
    HitMarkerData[playerid][slot][hm_StartTime] = GetTickCount();
    HitMarkerData[playerid][slot][hm_StartX] = baseX;
    HitMarkerData[playerid][slot][hm_StartY] = baseY + offsetY;
    HitMarkerData[playerid][slot][hm_CurrentX] = baseX;
    HitMarkerData[playerid][slot][hm_CurrentY] = baseY + offsetY;
    
    HitMarkerData[playerid][slot][hm_VelocityX] = 0.0;
    HitMarkerData[playerid][slot][hm_VelocityY] = 0.0;
    
    CreateAttackerHitMarkerTextDraw(playerid, slot, damage, targetname, bodypart, weaponid);
    
    PlayerHitMarkerCount[playerid]++;
    
    return 1;
}

stock CreateAttackerHitMarkerTextDraw(playerid, slot, Float:damage, const targetname[], bodypart = 3, weaponid = 0)
{
    new string[128];
    new bodyname[16];
    new weaponname[32];
    
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    GetWeaponName(weaponid, weaponname, sizeof(weaponname));
    
    if(strlen(targetname) > 0)
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~y~+%.0f ~w~(%s) ~g~%s ~b~%s", damage, targetname, bodyname, weaponname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~y~+%.1f ~w~(%s) ~g~%s ~b~%s", damage, targetname, bodyname, weaponname);
        else
            format(string, sizeof(string), "~y~+%.1f ~w~(%s) ~g~%s ~b~%s", damage, targetname, bodyname, weaponname);
    }
    else
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~y~+%.0f ~g~%s ~b~%s", damage, bodyname, weaponname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~y~+%.1f ~g~%s ~b~%s", damage, bodyname, weaponname);
        else
            format(string, sizeof(string), "~y~+%.1f ~g~%s ~b~%s", damage, bodyname, weaponname);
    }
    
    HitMarkerData[playerid][slot][hm_TextDraw] = CreatePlayerTextDraw(playerid, 
        HitMarkerData[playerid][slot][hm_CurrentX], 
        HitMarkerData[playerid][slot][hm_CurrentY], 
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
    if(!IsPlayerConnected(playerid))
    {
        if(PlayerHitMarkerTimer[playerid] != -1)
        {
            KillTimer(PlayerHitMarkerTimer[playerid]);
            PlayerHitMarkerTimer[playerid] = -1;
        }
        return 0;
    }
    
    static activeMarkers;
    activeMarkers = 0;
    
    for(new i = 0; i < MAX_HIT_MARKERS; i++)
    {
        if(HitMarkerData[playerid][i][hm_Active])
        {
            UpdateHitMarker(playerid, i);
            activeMarkers++;
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
    
    for(new i = 0; i < MAX_HIT_MARKERS; i++)
    {
        HitMarkerData[playerid][i][hm_Active] = false;
        HitMarkerData[playerid][i][hm_TextDraw] = PlayerText:INVALID_TEXT_DRAW;
        HitMarkerData[playerid][i][hm_Timer] = -1;
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
    
    return 1;
}

stock StartHitMarkerTimer(playerid)
{
    if(PlayerHitMarkerTimer[playerid] == -1)
    {
        PlayerHitMarkerTimer[playerid] = SetTimerEx("UpdatePlayerHitMarkers", HIT_MARKER_UPDATE_RATE, true, "i", playerid);
    }
    return 1;
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
    
    new shootername[MAX_PLAYER_NAME];
    GetPlayerName(issuerid, shootername, sizeof(shootername));
    
    CreateHitMarker(playerid, amount, HIT_TYPE_DAMAGE, shootername, bodypart, weaponid);
    StartHitMarkerTimer(playerid);
    
    return 1;
}

hook OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(damagedid))
        return 1;
    
    new targetname[MAX_PLAYER_NAME];
    GetPlayerName(damagedid, targetname, sizeof(targetname));
    
    CreateAttackerHitMarker(playerid, amount, targetname, bodypart, weaponid);
    StartHitMarkerTimer(playerid);
    
    return 1;
}

