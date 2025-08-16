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

stock CreateHitMarkerTextDraw(playerid, slot, Float:damage, type, const shootername[] = "", bodypart = 3)
{
    #pragma unused type
    new string[128];
    new bodyname[16];
    
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    
    if(strlen(shootername) > 0)
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~r~-%.0f ~w~(%s) ~y~%s", damage, shootername, bodyname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~r~-%.1f ~w~(%s) ~y~%s", damage, shootername, bodyname);
        else
            format(string, sizeof(string), "~r~-%.1f ~w~(%s) ~y~%s", damage, shootername, bodyname);
    }
    else
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~r~-%.0f ~y~%s", damage, bodyname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~r~-%.1f ~y~%s", damage, bodyname);
        else
            format(string, sizeof(string), "~r~-%.1f ~y~%s", damage, bodyname);
    }
    
    HitMarkerData[playerid][slot][hm_TextDraw] = CreatePlayerTextDraw(playerid, 
        HitMarkerData[playerid][slot][hm_CurrentX],
        HitMarkerData[playerid][slot][hm_CurrentY],
        string);
    
    PlayerTextDrawLetterSize(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0.300, 1.400);
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

stock CreateHitMarker(playerid, Float:damage, type = HIT_TYPE_DAMAGE, const shootername[] = "", bodypart = 3)
{
    if(!IsPlayerConnected(playerid))
        return 0;
    
    new slot = GetAvailableHitMarkerSlot(playerid);
    
    new Float:baseX = 480.0;
    new Float:baseY = 150.0;
    new Float:offsetY = slot * 18.0;
    
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
    
    CreateHitMarkerTextDraw(playerid, slot, damage, type, shootername, bodypart);
    
    PlayerHitMarkerCount[playerid]++;
    
    return 1;
}

stock CreateAttackerHitMarker(playerid, Float:damage, const targetname[], bodypart = 3)
{
    if(!IsPlayerConnected(playerid))
        return 0;
    
    new slot = GetAvailableHitMarkerSlot(playerid);
    
    new Float:baseX = 160.0;
    new Float:baseY = 150.0;
    new Float:offsetY = slot * 18.0;
    
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
    
    CreateAttackerHitMarkerTextDraw(playerid, slot, damage, targetname, bodypart);
    
    PlayerHitMarkerCount[playerid]++;
    
    return 1;
}

stock CreateAttackerHitMarkerTextDraw(playerid, slot, Float:damage, const targetname[], bodypart = 3)
{
    new string[128];
    new bodyname[16];
    
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    
    if(strlen(targetname) > 0)
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~y~%.0f ~w~(%s) ~g~%s", damage, targetname, bodyname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~y~%.1f ~w~(%s) ~g~%s", damage, targetname, bodyname);
        else
            format(string, sizeof(string), "~y~%.1f ~w~(%s) ~g~%s", damage, targetname, bodyname);
    }
    else
    {
        if(damage >= 100.0)
            format(string, sizeof(string), "~y~%.0f ~g~%s", damage, bodyname);
        else if(damage >= 10.0)
            format(string, sizeof(string), "~y~%.1f ~g~%s", damage, bodyname);
        else
            format(string, sizeof(string), "~y~%.1f ~g~%s", damage, bodyname);
    }
    
    HitMarkerData[playerid][slot][hm_TextDraw] = CreatePlayerTextDraw(playerid, 
        HitMarkerData[playerid][slot][hm_CurrentX], 
        HitMarkerData[playerid][slot][hm_CurrentY], 
        string);
    
    PlayerTextDrawLetterSize(playerid, HitMarkerData[playerid][slot][hm_TextDraw], 0.280, 1.300);
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
    
    CreateHitMarker(playerid, amount, HIT_TYPE_DAMAGE, shootername, bodypart);
    StartHitMarkerTimer(playerid);
    
    return 1;
}

hook OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(damagedid))
        return 1;
    
    new targetname[MAX_PLAYER_NAME];
    GetPlayerName(damagedid, targetname, sizeof(targetname));
    
    CreateAttackerHitMarker(playerid, amount, targetname, bodypart);
    StartHitMarkerTimer(playerid);
    
    return 1;
}

CMD:testhit(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessageEx(playerid, COLOR_GREY, "You don't have permission to use this command.");
    
    new Float:damage, shootername[MAX_PLAYER_NAME], bodypart;
    if(sscanf(params, "fs[24]i", damage, shootername, bodypart))
    {
        SendClientMessageEx(playerid, COLOR_WHITE, "USAGE: /testhit [damage] [shooter_name] [bodypart]");
        SendClientMessageEx(playerid, COLOR_GREY, "Bodyparts: 3=Than, 4=Mong, 5=Tay trai, 6=Tay phai, 7=Chan trai, 8=Chan phai, 9=Dau");
        SendClientMessageEx(playerid, COLOR_GREY, "Example: /testhit 25.5 TestPlayer 9");
        return 1;
    }
    
    if(damage < 0.1 || damage > 999.9)
        return SendClientMessageEx(playerid, COLOR_GREY, "Damage must be between 0.1 and 999.9");
    
    if(bodypart < 3 || bodypart > 9)
        return SendClientMessageEx(playerid, COLOR_GREY, "Bodypart must be between 3-9");
    
    CreateHitMarker(playerid, damage, HIT_TYPE_DAMAGE, shootername, bodypart);
    StartHitMarkerTimer(playerid);
    
    new string[128], bodyname[16];
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    format(string, sizeof(string), "Created hit marker: %.1f damage from %s at %s", damage, shootername, bodyname);
    SendClientMessageEx(playerid, COLOR_LIGHTBLUE, string);
    
    return 1;
}

CMD:testhitdamage(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessageEx(playerid, COLOR_GREY, "You don't have permission to use this command.");
    
    new Float:damage;
    if(sscanf(params, "f", damage)) damage = 35.5;
    
    if(damage < 0.1 || damage > 999.9)
        return SendClientMessageEx(playerid, COLOR_GREY, "Damage must be between 0.1 and 999.9");
    
    new bodypart = 3 + random(7);
    
    new testshooter[] = "TestShooter";
    CreateHitMarker(playerid, damage, HIT_TYPE_DAMAGE, testshooter, bodypart);
    StartHitMarkerTimer(playerid);
    
    new string[128], bodyname[16];
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    format(string, sizeof(string), "Created victim hit marker: %.1f damage at %s", damage, bodyname);
    SendClientMessageEx(playerid, COLOR_LIGHTBLUE, string);
    
    return 1;
}

CMD:testattackerhit(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessageEx(playerid, COLOR_GREY, "You don't have permission to use this command.");
    
    new Float:damage;
    if(sscanf(params, "f", damage)) damage = 35.5;
    
    if(damage < 0.1 || damage > 999.9)
        return SendClientMessageEx(playerid, COLOR_GREY, "Damage must be between 0.1 and 999.9");
    
    new bodypart = 3 + random(7);
    
    new testtarget[] = "TestTarget";
    CreateAttackerHitMarker(playerid, damage, testtarget, bodypart);
    StartHitMarkerTimer(playerid);
    
    new string[128], bodyname[16];
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    format(string, sizeof(string), "Created attacker hit marker: %.1f damage at %s", damage, bodyname);
    SendClientMessageEx(playerid, COLOR_YELLOW, string);
    
    return 1;
}

CMD:testbothhit(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessageEx(playerid, COLOR_GREY, "You don't have permission to use this command.");
    
    new Float:damage;
    if(sscanf(params, "f", damage)) damage = 35.5;
    
    if(damage < 0.1 || damage > 999.9)
        return SendClientMessageEx(playerid, COLOR_GREY, "Damage must be between 0.1 and 999.9");
    
    new bodypart = 3 + random(7);
    
    new testshooter[] = "TestShooter";
    CreateHitMarker(playerid, damage, HIT_TYPE_DAMAGE, testshooter, bodypart);
    
    new testtarget[] = "TestTarget";
    CreateAttackerHitMarker(playerid, damage, testtarget, bodypart);
    
    StartHitMarkerTimer(playerid);
    
    new string[128], bodyname[16];
    GetBodyPartName(bodypart, bodyname, sizeof(bodyname));
    format(string, sizeof(string), "Created both hit markers: %.1f damage at %s", damage, bodyname);
    SendClientMessageEx(playerid, COLOR_LIGHTGREEN, string);
    
    return 1;
}

CMD:testrapid(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessageEx(playerid, COLOR_GREY, "You don't have permission to use this command.");
    
    new testshooter[] = "RapidShooter";
    CreateHitMarker(playerid, 25.5, HIT_TYPE_DAMAGE, testshooter, 9);
    CreateHitMarker(playerid, 31.2, HIT_TYPE_DAMAGE, testshooter, 3);
    CreateHitMarker(playerid, 28.8, HIT_TYPE_DAMAGE, testshooter, 5);
    CreateHitMarker(playerid, 22.3, HIT_TYPE_DAMAGE, testshooter, 7);
    CreateHitMarker(playerid, 35.1, HIT_TYPE_DAMAGE, testshooter, 3);
    
    StartHitMarkerTimer(playerid);
    SendClientMessageEx(playerid, COLOR_YELLOW, "Created rapid fire hit markers on RIGHT SIDE - clear aiming view!");
    
    return 1;
}