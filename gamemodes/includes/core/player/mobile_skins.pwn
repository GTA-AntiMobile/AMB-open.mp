#include <YSI\YSI_Coding\y_hooks>

hook OnPlayerRequestDownload(playerid, DOWNLOAD_REQUEST:type, crc)
{
    return 1;
}

new PlayerText:TempSkinTD[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};

stock LoadCustomSkinForMobile(playerid, modelid)
{
    if(IsPlayerAndroid(playerid))
    {
        TempSkinTD[playerid] = CreatePlayerTextDraw(playerid, -50.0, -50.0, "_");
        PlayerTextDrawTextSize(playerid, TempSkinTD[playerid], 1.0, 1.0);
        PlayerTextDrawFont(playerid, TempSkinTD[playerid], 5);
        PlayerTextDrawSetPreviewModel(playerid, TempSkinTD[playerid], modelid);
        PlayerTextDrawSetPreviewRot(playerid, TempSkinTD[playerid], 0.0, 0.0, 0.0, 1.0);
        PlayerTextDrawShow(playerid, TempSkinTD[playerid]);
        
        SetTimerEx("CleanupTempTD", 500, false, "d", playerid);
        
        SetTimerEx("DelayedSetSkin", 2000, false, "dd", playerid, modelid);
        SendClientMessage(playerid, -1, "{4A90E2}[MOBILE] {FFFFFF}Dang tai custom skin...");
    }
    else
    {
        SetPlayerSkin(playerid, modelid);
    }
    return 1;
}

forward CleanupTempTD(playerid);
public CleanupTempTD(playerid)
{
    if(TempSkinTD[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawHide(playerid, TempSkinTD[playerid]);
        PlayerTextDrawDestroy(playerid, TempSkinTD[playerid]);
        TempSkinTD[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }
    return 1;
}

stock bool:IsPlayerAndroid(playerid)
{
    new client[32];
    GetPlayerVersion(playerid, client, sizeof(client));
    return (strfind(client, "Android", true) != -1 || strfind(client, "Mobile", true) != -1);
}

forward DelayedSetSkin(playerid, modelid);
public DelayedSetSkin(playerid, modelid)
{
    if(IsPlayerConnected(playerid))
    {
        SetPlayerSkin(playerid, modelid);
        SendClientMessage(playerid, -1, "{4CAF50}[MOBILE] {FFFFFF}Custom skin da duoc tai!");
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(TempSkinTD[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, TempSkinTD[playerid]);
        TempSkinTD[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }
    return 1;
}

CMD:customskin(playerid, params[])
{
    if(isnull(params))
    {
        SendClientMessage(playerid, -1, "{FF6B6B}Su dung: {FFFFFF}/customskin [20001/20002/20003]");
        return 1;
    }
    
    new modelid = strval(params);
    if(modelid < 20001 || modelid > 20003)
    {
        SendClientMessage(playerid, -1, "{FF6B6B}Chi co skin: {FFFFFF}20001 (Dylan), 20002 (Brian), 20003 (LAPD)");
        return 1;
    }
    
    LoadCustomSkinForMobile(playerid, modelid);
    return 1;
}
