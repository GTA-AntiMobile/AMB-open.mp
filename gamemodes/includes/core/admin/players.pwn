#include <YSI\YSI_Coding\y_hooks>

#define DIALOG_GIVEGUN 10001
#define DIALOG_SETSTAT_PLAYER  11001
#define DIALOG_SETSTAT_MENU    11002
#define DIALOG_SETSTAT_INPUT   11003
#define DIALOG_ADMIN_PANEL_INFO 11005
#define DIALOG_ADMIN_PANEL_PLAYERS 11007 
#define DIALOG_ADMIN_PANEL_ACTIONS 11008
#define DIALOG_ADMIN_PANEL_REASON 11006
#define DIALOG_PLAYER_OUTFIT_MENU 11009
#define DIALOG_PLAYER_OUTFIT_INPUT 11010

#define MAX_PANEL_PLAYERS 4
new PlayerText:PlayerPanelTD[MAX_PLAYERS][MAX_PANEL_PLAYERS * 3 + 8]; // 8 UI elements + 4 backgrounds + 4 models + 4 names = 20
new bool:PlayerPanelShowing[MAX_PLAYERS];
new PlayerPanelPage[MAX_PLAYERS];
new PlayerPanelSelectedPlayer[MAX_PLAYERS];


new const WeaponNames[][32] = {
    "Brass Knuckles", "Golf Club", "Night Stick", "Knife", "Baseball Bat", "Shovel", "Pool Cue", "Katana", "Chainsaw",
    "Purple Dildo", "Dildo", "Vibrator", "Silver Vibrator", "Flowers", "Cane", "Grenade", "Tear Gas", "Molotov",
    "Colt 45", "Silenced 9mm", "Desert Eagle", "Shotgun", "Sawn-off", "SPAS-12", "Micro Uzi", "MP5", "AK-47", "M4", "Tec-9",
    "Country Rifle", "Sniper Rifle", "Rocket Launcher", "Heat Seeking RPG", "Flamethrower", "Minigun", "Satchel Charge", "Detonator",
    "Spray Can", "Fire Extinguisher", "Camera", "Night Vision", "Thermal Vision", "Parachute"
};

new const StatName[][32] = {
    "Level",
    "ArmorUpgrade",
    "UpgradePoints",
    "Model",
    "BankAccount",
    "PhoneNumber",
    "Respect Points",
    "House1",
    "House2",
    "FMember",
    "Det",
    "Lawyer",
    "Fixer",
    "Drug",
    "Sex",
    "Box",
    "Arms",
    "Materials",
    "Pot",
    "Crack",
    "Fishing",
    "Job",
    "Rank",
    "Packages",
    "Crates",
    "Smuggler",
    "Insurance",
    "Warnings",
    "Screwdriver",
    "Age",
    "Gender",
    "NMute",
    "AdMute",
    "Faction",
    "Restricted Weapon Time",
    "Gang Warns",
    "RMute",
    "Reward Hours",
    "Playing Hours",
    "Gold Box Tokens",
    "Computer Drawings",
    "Papers",
    "Business",
    "BusinessRank",
    "Spraycan",
    "Heroin",
    "RawOpium",
    "Syringes",
    "Hunger",
    "Hunger",
    "Fitness",
    "Event Tokens",
    "Modkit"
};

new const WeaponIDs[] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9,
    10, 11, 12, 13, 14, 15, 16, 17, 18,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46
};


CreatePlayerPanelTextDraws(playerid)
{
    // Expanded background - Much larger size
    PlayerPanelTD[playerid][0] = CreatePlayerTextDraw(playerid, 10.0, 40.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][0], 620.0, 400.0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][0], 0x000000CC);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][0], 4);
    
    // Main container - Expanded
    PlayerPanelTD[playerid][1] = CreatePlayerTextDraw(playerid, 15.0, 45.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][1], 610.0, 390.0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][1], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][1], 0x1A1A1AFF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][1], 4);
    
    // Top accent bar - Full width
    PlayerPanelTD[playerid][2] = CreatePlayerTextDraw(playerid, 15.0, 45.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][2], 610.0, 5.0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][2], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][2], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][2], 4);
    
    // Header - Centered in expanded panel
    PlayerPanelTD[playerid][3] = CreatePlayerTextDraw(playerid, 320.0, 58.0, "~b~ADMIN ~w~PLAYER ~y~MANAGEMENT");
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][3], 0.320, 1.600);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][3], 0);
    PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][3], 1);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][3], 2);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][3], 2);
    
    // Subtitle - Expanded
    PlayerPanelTD[playerid][4] = CreatePlayerTextDraw(playerid, 320.0, 75.0, "~w~Professional Control • Advanced Features");
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][4], 0.190, 0.850);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][4], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][4], 1);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][4], 2);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][4], 1);
    
    // Close button - Moved to new position
    PlayerPanelTD[playerid][5] = CreatePlayerTextDraw(playerid, 610.0, 58.0, "~r~X");
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][5], 2);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][5], 0xFF4757FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][5], 1);
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][5], 0.32, 1.3);
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][5], 18.0, 18.0);
    PlayerTextDrawSetSelectable(playerid, PlayerPanelTD[playerid][5], 1);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][5], 1);
    
    // Showcase area - Expanded size
    PlayerPanelTD[playerid][6] = CreatePlayerTextDraw(playerid, 25.0, 95.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][6], 590.0, 280.0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][6], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][6], 0x222222FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][6], 4);
    
    // Showcase border - Full width
    PlayerPanelTD[playerid][7] = CreatePlayerTextDraw(playerid, 25.0, 95.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][7], 590.0, 2.0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][7], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][7], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][7], 4);
    
    // Navigation panel - Expanded width
    PlayerPanelTD[playerid][8] = CreatePlayerTextDraw(playerid, 25.0, 385.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][8], 590.0, 40.0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][8], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][8], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][8], 4);
    
    // Navigation buttons - Repositioned for expanded panel
    PlayerPanelTD[playerid][9] = CreatePlayerTextDraw(playerid, 50.0, 400.0, "~g~PREV");
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][9], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][9], 0x2ED573FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][9], 1);
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][9], 0.27, 1.1);
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][9], 70.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, PlayerPanelTD[playerid][9], 1);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][9], 1);
    PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][9], 0);
    
    PlayerPanelTD[playerid][10] = CreatePlayerTextDraw(playerid, 550.0, 400.0, "~g~NEXT");
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][10], 1);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][10], 0x2ED573FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][10], 1);
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][10], 0.27, 1.1);
    PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][10], 70.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, PlayerPanelTD[playerid][10], 1);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][10], 1);
    PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][10], 0);
    
    // Page info - Centered in expanded panel
    PlayerPanelTD[playerid][11] = CreatePlayerTextDraw(playerid, 320.0, 400.0, "~y~PAGE ~w~1~y~/~w~1");
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][11], 2);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][11], 0xFFD700FF);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][11], 1);
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][11], 0.28, 1.1);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][11], 1);
    PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][11], 0);
    
    // Player slots - Expanded layout with more space
    new Float:startX = 50.0, Float:startY = 120.0;
    new Float:slotWidth = 140.0;
    
    for(new i = 0; i < MAX_PANEL_PLAYERS; i++)
    {
        new Float:x = startX + (i * slotWidth);
        new Float:y = startY;
        
        // Player preview model - Larger size for expanded panel
        PlayerPanelTD[playerid][12 + i] = CreatePlayerTextDraw(playerid, x, y, "_");
        PlayerTextDrawTextSize(playerid, PlayerPanelTD[playerid][12 + i], 125.0, 150.0);
        PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][12 + i], -1);
        PlayerTextDrawBackgroundColor(playerid, PlayerPanelTD[playerid][12 + i], 0x2A2A2AFF);
        PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][12 + i], 5);
        PlayerTextDrawSetSelectable(playerid, PlayerPanelTD[playerid][12 + i], true);
        PlayerTextDrawSetPreviewModel(playerid, PlayerPanelTD[playerid][12 + i], 26);
        PlayerTextDrawSetPreviewRot(playerid, PlayerPanelTD[playerid][12 + i], -9.0, 0.0, -22.0, 1.0);
        
        // Player name - Below model, centered with larger text
        PlayerPanelTD[playerid][16 + i] = CreatePlayerTextDraw(playerid, x + 62.5, y + 155.0, "~w~Empty");
        PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][16 + i], 2);
        PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][16 + i], 0xFFFFFFFF);
        PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][16 + i], 1);
        PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][16 + i], 0.20, 0.9);
        PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][16 + i], 1);
        PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][16 + i], 0);
    }
    
    // Premium accent - Positioned for expanded panel
    PlayerPanelTD[playerid][19] = CreatePlayerTextDraw(playerid, 320.0, 330.0, "~y~ADMIN CONTROL PANEL");
    PlayerTextDrawLetterSize(playerid, PlayerPanelTD[playerid][19], 0.24, 1.2);
    PlayerTextDrawColor(playerid, PlayerPanelTD[playerid][19], 0xFFD700FF);
    PlayerTextDrawSetShadow(playerid, PlayerPanelTD[playerid][19], 1);
    PlayerTextDrawSetOutline(playerid, PlayerPanelTD[playerid][19], 0);
    PlayerTextDrawAlignment(playerid, PlayerPanelTD[playerid][19], 2);
    PlayerTextDrawFont(playerid, PlayerPanelTD[playerid][19], 1);
    
    return 1;
}

DestroyPlayerPanelTextDraws(playerid)
{
    for(new i = 0; i < MAX_PANEL_PLAYERS * 3 + 8; i++)
    {
        if(PlayerPanelTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, PlayerPanelTD[playerid][i]);
            PlayerPanelTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    return 1;
}

UpdatePlayerPanelData(playerid)
{
    new count = 0;
    new playerList[MAX_PLAYERS];
    
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            playerList[count] = i;
            count++;
        }
    }
    
    new totalPages = (count / MAX_PANEL_PLAYERS) + (count % MAX_PANEL_PLAYERS ? 1 : 0);
    if(totalPages == 0) totalPages = 1;
    
    new startIndex = PlayerPanelPage[playerid] * MAX_PANEL_PLAYERS;
    
    new pageInfo[48];
    format(pageInfo, sizeof(pageInfo), "~y~PAGE ~w~%d~y~/~w~%d", PlayerPanelPage[playerid] + 1, totalPages);
    PlayerTextDrawSetString(playerid, PlayerPanelTD[playerid][11], pageInfo);
    
    for(new i = 0; i < MAX_PANEL_PLAYERS; i++)
    {
        new playerIndex = startIndex + i;
        
        if(playerIndex < count)
        {
            new targetid = playerList[playerIndex];
            
            PlayerTextDrawSetPreviewModel(playerid, PlayerPanelTD[playerid][12 + i], GetPlayerSkin(targetid));
            PlayerTextDrawSetPreviewRot(playerid, PlayerPanelTD[playerid][12 + i], -9.0, 0.0, -22.0, 1.0);
            
            new name[MAX_PLAYER_NAME + 20];
            GetPlayerName(targetid, name, sizeof(name));
            format(name, sizeof(name), "~w~%s ~b~(ID:%d)", name, targetid);
            PlayerTextDrawSetString(playerid, PlayerPanelTD[playerid][16 + i], name);
            
            PlayerTextDrawShow(playerid, PlayerPanelTD[playerid][12 + i]); // Model
            PlayerTextDrawShow(playerid, PlayerPanelTD[playerid][16 + i]); // Name
        }
        else
        {
            PlayerTextDrawSetPreviewModel(playerid, PlayerPanelTD[playerid][12 + i], 0);
            PlayerTextDrawSetString(playerid, PlayerPanelTD[playerid][16 + i], "");
            PlayerTextDrawHide(playerid, PlayerPanelTD[playerid][12 + i]);
            PlayerTextDrawHide(playerid, PlayerPanelTD[playerid][16 + i]);
        }
    }
    
    return 1;
}

ShowPlayerPanel(playerid)
{
    if(PlayerInfo[playerid][pAdmin] < 1337)
        return SendClientMessage(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    
    CreatePlayerPanelTextDraws(playerid);
    PlayerPanelPage[playerid] = 0;
    PlayerPanelShowing[playerid] = true;
    
    UpdatePlayerPanelData(playerid);
    
    for(new i = 0; i < 12; i++)
    {
        PlayerTextDrawShow(playerid, PlayerPanelTD[playerid][i]);
    }
    PlayerTextDrawShow(playerid, PlayerPanelTD[playerid][19]); // Premium accent
    
    SelectTextDraw(playerid, 0x00FF00FF);
    return 1;
}

HidePlayerPanel(playerid)
{
    if(PlayerPanelShowing[playerid])
    {
        DestroyPlayerPanelTextDraws(playerid);
        PlayerPanelShowing[playerid] = false;
        CancelSelectTextDraw(playerid);
    }
    return 1;
}

GetPlayerFromPanelSlot(playerid, slot)
{
    new count = 0;
    new startIndex = PlayerPanelPage[playerid] * MAX_PANEL_PLAYERS;
    new targetIndex = startIndex + slot;
    
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            if(count == targetIndex)
            {
                return i;
            }
            count++;
        }
    }
    return INVALID_PLAYER_ID;
}

ShowPlayerManagementMenu(playerid, targetid)
{
    new managementMenu[512];
    format(managementMenu, sizeof(managementMenu), 
        "Xem thong tin chi tiet\n"\
        "Give Weapon (Cap vu khi)\n"\
        "Set Stats (Chinh sua thong so)\n"\
        "Heal (Hoi mau)\n"\
        "Give Armor (Cap giap)\n"\
        "Set Money (Chinh tien)\n"\
        "Teleport den\n"\
        "Teleport nguoi choi den toi\n"\
        "Spectate\n"\
        "Freeze/Unfreeze\n"\
        "Kick\n"\
        "Ban");
    
    new title[64];
    format(title, sizeof(title), "Quan ly: %s", GetPlayerNameEx(targetid));
    ShowPlayerDialog(playerid, DIALOG_PLAYER_OUTFIT_MENU, DIALOG_STYLE_LIST, title, managementMenu, "Chon", "Dong");
    return 1;
}

CMD:playerpanel(playerid, params[])
{
    return ShowPlayerPanel(playerid);
}

CMD:panel(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1337)
        return SendClientMessage(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");

    new playerList[2048];
    new count = 0;
    
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            new playerName[MAX_PLAYER_NAME];
            GetPlayerName(i, playerName, sizeof(playerName));
            new Float:health, Float:armour;
            GetPlayerHealth(i, health);
            GetPlayerArmour(i, armour);
            
            format(playerList, sizeof(playerList), "%s%s (ID: %d) | HP: %.0f | Armor: %.0f\n", 
                playerList, playerName, i, health, armour);
            count++;
        }
    }
    
    if(count == 0)
    {
        return SendClientMessage(playerid, COLOR_GRAD1, "Khong co nguoi choi nao online.");
    }
    
    new title[64];
    format(title, sizeof(title), "Nguoi choi online (%d)", count);
    ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_PLAYERS, DIALOG_STYLE_LIST, title, playerList, "Chon", "Dong");
    return 1;
}

CMD:setstat(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1337)
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");

    new list[2048];
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            format(list, sizeof(list), "%s%s (%d)\n", list, GetPlayerNameEx(i), i);
        }
    }
    ShowPlayerDialog(playerid, DIALOG_SETSTAT_PLAYER, DIALOG_STYLE_LIST, "> Chon Player", list, "Chon", "Huy");
    return 1;
}

CMD:givegun(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 4)
    {
        new targetid;
        if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, -1, "{873D37}SU DUNG:{9E9E9E} /givegun [playerid]");
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, "Nguoi choi khong hop le.");

        SetPVarInt(playerid, "GiveGunTarget", targetid);

        new list[1024];
        for(new i = 0; i < sizeof(WeaponNames); i++)
        {
            format(list, sizeof(list), "%s%s\n", list, WeaponNames[i]);
        }
        ShowPlayerDialog(playerid, DIALOG_GIVEGUN, DIALOG_STYLE_LIST, "> Give Weapon", list, "Select", "Cancel");
        return 1;
    }
    return 1;
}

// TextDraw Click Handler
hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(!PlayerPanelShowing[playerid]) return 0;
    
    // Close button
    if(playertextid == PlayerPanelTD[playerid][5])
    {
        HidePlayerPanel(playerid);
        return 1;
    }
    
    // Previous page button
    if(playertextid == PlayerPanelTD[playerid][9])
    {
        if(PlayerPanelPage[playerid] > 0)
        {
            PlayerPanelPage[playerid]--;
            UpdatePlayerPanelData(playerid);
        }
        return 1;
    }
    
    // Next page button
    if(playertextid == PlayerPanelTD[playerid][10])
    {
        new count = 0;
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(IsPlayerConnected(i)) count++;
        }
        new totalPages = (count / MAX_PANEL_PLAYERS) + (count % MAX_PANEL_PLAYERS ? 1 : 0);
        
        if(PlayerPanelPage[playerid] < totalPages - 1)
        {
            PlayerPanelPage[playerid]++;
            UpdatePlayerPanelData(playerid);
        }
        return 1;
    }
    
    // Player slots - Preview models
    for(new i = 0; i < MAX_PANEL_PLAYERS; i++)
    {
        if(playertextid == PlayerPanelTD[playerid][12 + i])
        {
            new targetid = GetPlayerFromPanelSlot(playerid, i);
            if(targetid != INVALID_PLAYER_ID)
            {
                PlayerPanelSelectedPlayer[playerid] = targetid;
                ShowPlayerManagementMenu(playerid, targetid);
            }
            return 1;
        }
    }
    
    return 0;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_GIVEGUN && response)
    {
        new targetid = GetPVarInt(playerid, "GiveGunTarget");
        if(!IsPlayerConnected(targetid)) {
            SendClientMessage(playerid, -1, "Nguoi choi khong hop le.");
            return 1;
        }
        if(listitem < 0 || listitem >= sizeof(WeaponIDs)) return 1;
        new weaponid = WeaponIDs[listitem];

        for(new slot = 0; slot < 12; slot++)
        {
            new wid, ammo;
            GetPlayerWeaponData(targetid, slot, wid, ammo);
            if(wid == weaponid)
            {
                new msg[128];
                format(msg, sizeof(msg), "Nguoi choi %s da co vu khi %s roi!", GetPlayerNameEx(targetid), WeaponNames[listitem]);
                SendClientMessage(playerid, 0xFF0000FF, msg);
                return 1;
            }
        }
        GivePlayerWeapon(targetid, weaponid, 100);
        new msg[128];
        format(msg, sizeof(msg), "[ADMIN GIVEGUN] Ban da cap vu khi %s cho %s.", WeaponNames[listitem], GetPlayerNameEx(targetid));
        SendClientMessage(playerid, COLOR_LIGHTRED, msg);
        return 1;
    }
    if(dialogid == DIALOG_SETSTAT_PLAYER && response)
    {
        new targetid = -1, name[24];
        sscanf(inputtext, "s[24]", name);
        new len = strlen(inputtext);
        for(new i = len-2; i >= 0; i--) {
            if(inputtext[i] == '(') {
                targetid = strval(inputtext[i+1]);
                break;
            }
        }
        if(targetid == -1 || !IsPlayerConnected(targetid))
            return SendClientMessage(playerid, -1, "Khong tim thay nguoi choi.");
        SetPVarInt(playerid, "SetStatTarget", targetid);

        new statlist[2048];
        statlist[0] = EOS;
        for(new i = 0; i < sizeof(StatName); i++)
        {
            format(statlist, sizeof(statlist), "%s%s\n", statlist, StatName[i]);
        }
        ShowPlayerDialog(playerid, DIALOG_SETSTAT_MENU, DIALOG_STYLE_LIST, "Chon stat de set", statlist, "Chon", "Huy");
        return 1;
    }
    if(dialogid == DIALOG_SETSTAT_MENU && response)
    {
        SetPVarInt(playerid, "SetStatType", listitem);
        new statname[32];
        format(statname, sizeof(statname), "%s", StatName[listitem]);
        new caption[64];
        format(caption, sizeof(caption), "Nhap gia tri moi cho %s", statname);
        ShowPlayerDialog(playerid, DIALOG_SETSTAT_INPUT, DIALOG_STYLE_INPUT, caption, "Nhap gia tri:", "Xac nhan", "Huy");
        return 1;
    }
    if(dialogid == DIALOG_SETSTAT_INPUT && response)
    {
        new targetid = GetPVarInt(playerid, "SetStatTarget");
        new statid = GetPVarInt(playerid, "SetStatType");
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, "Nguoi choi khong hop le.");

        new value = strval(inputtext);
        if(value < 0 && (statid == 0 || statid == 1 || statid == 3 || statid == 4)) // Level, ArmorUpgrade, UpgradePoints, Model
            return SendClientMessage(playerid, -1, "Khong duoc nhap so am cho stat nay!");
        new string[1280];
        switch(statid)
        {
            case 0:
            {
                PlayerInfo[targetid][pLevel] = value;
                SetPlayerScore(targetid, value);
            }
            case 1: PlayerInfo[targetid][pSHealth] = value;
            case 2: PlayerInfo[targetid][gPupgrade] = value;
            case 3: PlayerInfo[targetid][pModel] = value;
            case 4: PlayerInfo[targetid][pAccount] = value;
            case 5:
            {
                if(value == 0)
                {
                    PlayerInfo[targetid][pPnumber] = value;
                    format(string, sizeof(string), "   %s had their phone removed", GetPlayerNameEx(targetid));
                }
                else
                {
                    new query[128];
                    SetPVarInt(targetid, "WantedPh", value);
                    SetPVarInt(targetid, "CurrentPh", PlayerInfo[targetid][pPnumber]);
                    SetPVarInt(targetid, "PhChangeCost", 50000);
                    SetPVarInt(targetid, "PhChangerId", playerid);
                    format(query, sizeof(query), "SELECT `Username` FROM `accounts` WHERE `PhoneNr` = '%d'",value);
                    mysql_function_query(MainPipeline, query, true, "OnPhoneNumberCheck", "ii", targetid, 4);
                    return 1;
                }
            }
            case 6: PlayerInfo[targetid][pExp] = value;
            case 7: PlayerInfo[targetid][pPhousekey] = value;
            case 8: PlayerInfo[targetid][pPhousekey2] = value;
            case 9: PlayerInfo[targetid][pFMember] = value;
            case 10: PlayerInfo[targetid][pMechSkill] = value;
            case 11: PlayerInfo[targetid][pDetSkill] = value;
            case 12: PlayerInfo[targetid][pLawSkill] = value;
            case 13: PlayerInfo[targetid][pMechSkill] = value;
            case 14: PlayerInfo[targetid][pDrugsSkill] = value;
            case 15: PlayerInfo[targetid][pSexSkill] = value;
            case 16: PlayerInfo[targetid][pBoxSkill] = value;
            case 17: PlayerInfo[targetid][pArmsSkill] = value;
            case 18: PlayerInfo[targetid][pMats] = value;
            case 19: PlayerInfo[targetid][pPot] = value;
            case 20: PlayerInfo[targetid][pCrack] = value;
            case 21: PlayerInfo[targetid][pFishSkill] = value;
            case 22: PlayerInfo[targetid][pJob] = value;
            case 23: PlayerInfo[targetid][pRank] = value;
            case 24: SetPVarInt(playerid, "Packages", value);
            case 25: PlayerInfo[targetid][pCrates] = value;
            case 26: PlayerInfo[targetid][pSmugSkill] = value;
            case 27: PlayerInfo[targetid][pInsurance] = value;
            case 28: PlayerInfo[targetid][pWarns] = value;
            case 29: PlayerInfo[targetid][pScrewdriver] = value;
            case 30: PlayerInfo[targetid][pSex] = value;
            case 31: PlayerInfo[targetid][pNMuteTotal] = value;
            case 32: PlayerInfo[targetid][pADMuteTotal] = value;
            case 33: PlayerInfo[targetid][pMember] = value;
            case 34: 
            {
                if(PlayerInfo[targetid][pConnectHours] >= 2) {
						PlayerInfo[targetid][pWRestricted] = value;
						format(string, sizeof(string), "   %s's Weapon Restricted Time has been set to %d.", GetPlayerNameEx(targetid), value);
					}
					else {
						return SendClientMessageEx(playerid, COLOR_GREY, "You cannot set this on a person who has under 2 playing hours.");
					}
            }
            case 35: PlayerInfo[targetid][pGangWarn] = value;
            case 36: PlayerInfo[targetid][pRMutedTotal] = value;
            case 37: PlayerInfo[targetid][pRewardHours] = value;
            case 38: PlayerInfo[targetid][pConnectHours] = value;
            case 39: PlayerInfo[targetid][pGoldBoxTokens] = value;
            case 40: PlayerInfo[targetid][pRewardDrawChance] = value;
            case 41: PlayerInfo[targetid][pPaper] = value;
            case 42: 
            {
                if (value < 0 || value >= MAX_BUSINESSES) return 1;
				PlayerInfo[targetid][pBusiness] = value;
            }
            case 43:
            {
                if (value < 0 || value > 5) return 1;
				PlayerInfo[targetid][pBusinessRank] = value;
            }
            case 44: PlayerInfo[targetid][pSpraycan] = value;
            case 45: PlayerInfo[targetid][pHeroin] = value;
            case 46: PlayerInfo[targetid][pRawOpium] = value;
            case 47: PlayerInfo[targetid][pSyringes] = value;
            case 48:
            {
                if (value <= 0)
                {
                    value = 1;
                    PlayerInfo[playerid][pHungerTimer] = 1799;
                } else if (value > 100)
                {
                    value = 100;
                }

                PlayerInfo[playerid][pHungerDeathTimer] = 0;

                PlayerInfo[targetid][pHunger] = value;
            }
            case 49: PlayerInfo[targetid][pFitness] = value;
            case 50: PlayerInfo[targetid][pTrickortreat] = value;
            case 51: PlayerInfo[targetid][pRimMod] = value;
        }

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Da set %s cua %s thanh %d.", StatName[statid], GetPlayerNameEx(targetid), value);
        SendClientMessage(playerid, COLOR_LIGHTRED, msg);
        return 1;
    }
    if(dialogid == DIALOG_ADMIN_PANEL_REASON && response)
    {
        new targetid = GetPVarInt(playerid, "PanelTarget");
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, "Nguoi choi khong hop le.");
        new action = GetPVarInt(playerid, "PanelKickOrBan"); // 0 = Kick, 1 = Ban

        if(strlen(inputtext) < 2) return SendClientMessage(playerid, -1, "Ban phai nhap ly do!");

        if(action == 0)
        {
            new msg[128];
            format(msg, sizeof(msg), "[ADMIN] %s da bi kick. Ly do: %s", GetPlayerNameEx(targetid), inputtext);
            SendClientMessageToAll(COLOR_LIGHTRED, msg);
            Kick(targetid);
        }
        else
        {
            new msg[128];
            format(msg, sizeof(msg), "[ADMIN] %s da bi ban. Ly do: %s", GetPlayerNameEx(targetid), inputtext);
            SendClientMessageToAll(COLOR_LIGHTRED, msg);
            Ban(targetid);
        }
        return 1;
    }
    if(dialogid == DIALOG_ADMIN_PANEL_PLAYERS && response)
    {
        new targetid = -1;
        new currentIndex = 0;
        
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(IsPlayerConnected(i))
            {
                if(currentIndex == listitem)
                {
                    targetid = i;
                    break;
                }
                currentIndex++;
            }
        }
        
        if(targetid == -1 || !IsPlayerConnected(targetid)) 
            return SendClientMessage(playerid, -1, "Nguoi choi khong hop le.");
        
        SetPVarInt(playerid, "PanelTarget", targetid);
        
        new name[MAX_PLAYER_NAME];
        GetPlayerName(targetid, name, sizeof(name));
        new dialog[512];
        format(dialog, sizeof(dialog),
            "Xem thong tin chi tiet\nSpectate\nKick\nBan\nSet Stat\nGive Weapon\nTeleport den\nTeleport nguoi choi den toi\nHeal\nArmor\nFreeze\nUnfreeze"
        );
        new title[64];
        format(title, sizeof(title), "Quan ly: %s (ID: %d)", name, targetid);
        ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_ACTIONS, DIALOG_STYLE_LIST, title, dialog, "Chon", "Quay lai");
        return 1;
    }
    
    if(dialogid == DIALOG_ADMIN_PANEL_ACTIONS && response)
    {
        new targetid = GetPVarInt(playerid, "PanelTarget");
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, "Nguoi choi khong hop le.");

        switch(listitem)
        {
            case 0: // Xem thông tin chi tiết
            {
                new name[MAX_PLAYER_NAME];
                GetPlayerName(targetid, name, sizeof(name));
                new Float:health, Float:armour;
                GetPlayerHealth(targetid, health);
                GetPlayerArmour(targetid, armour);
                new Float:x, Float:y, Float:z;
                GetPlayerPos(targetid, x, y, z);
                new connectTime = PlayerInfo[targetid][pConnectHours];
                new level = PlayerInfo[targetid][pLevel];
                new cash = PlayerInfo[targetid][pCash];
                new bank = PlayerInfo[targetid][pAccount];
                new ping = GetPlayerPing(targetid);
                
                new info[1024];
                format(info, sizeof(info),
                    "=== THONG TIN CHI TIET ===\n\n"\
                    "Ten: %s\n"\
                    "ID: %d\n"\
                    "Level: %d\n"\
                    "Thoi gian choi: %d gio\n"\
                    "Mau: %.1f\n"\
                    "Giap: %.1f\n"\
                    "Tien mat: $%s\n"\
                    "Tien ngan hang: $%s\n"\
                    "Ping: %d ms\n"\
                    "Vi tri: %.1f, %.1f, %.1f\n"\
                    "Virtual World: %d\n"\
                    "Interior: %d",
                    name, targetid, level, connectTime, health, armour,
                    number_format(cash), number_format(bank), ping,
                    x, y, z, GetPlayerVirtualWorld(targetid), GetPlayerInterior(targetid)
                );
                ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_INFO, DIALOG_STYLE_MSGBOX, "Thong tin nguoi choi", info, "Dong", "");
            }
            case 1: // Spectate
            {
                TogglePlayerSpectating(playerid, true);
                PlayerSpectatePlayer(playerid, targetid);
                new msg[128];
                format(msg, sizeof(msg), "Ban dang spectate %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
            }
            case 2: // Kick
            {
                SetPVarInt(playerid, "PanelKickOrBan", 0);
                ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_REASON, DIALOG_STYLE_INPUT, "Nhap ly do kick", "Nhap ly do kick nguoi choi nay:", "Kick", "Huy");
            }
            case 3: // Ban
            {
                SetPVarInt(playerid, "PanelKickOrBan", 1);
                ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_REASON, DIALOG_STYLE_INPUT, "Nhap ly do ban", "Nhap ly do ban nguoi choi nay:", "Ban", "Huy");
            }
            case 4: // Set Stat
            {
                SetPVarInt(playerid, "SetStatTarget", targetid);
                new statlist[2048];
                statlist[0] = EOS;
                for(new i = 0; i < sizeof(StatName); i++)
                {
                    format(statlist, sizeof(statlist), "%s%s\n", statlist, StatName[i]);
                }
                ShowPlayerDialog(playerid, DIALOG_SETSTAT_MENU, DIALOG_STYLE_LIST, "Chon stat de set", statlist, "Chon", "Huy");
            }
            case 5: // Give Weapon
            {
                SetPVarInt(playerid, "GiveGunTarget", targetid);
                new list[1024];
                for(new i = 0; i < sizeof(WeaponNames); i++)
                {
                    format(list, sizeof(list), "%s%s\n", list, WeaponNames[i]);
                }
                ShowPlayerDialog(playerid, DIALOG_GIVEGUN, DIALOG_STYLE_LIST, "> Give Weapon", list, "Select", "Cancel");
            }
            case 6: // Teleport đến
            {
                new Float:x, Float:y, Float:z;
                GetPlayerPos(targetid, x, y, z);
                SetPlayerPos(playerid, x + 1, y, z);
                SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
                SetPlayerInterior(playerid, GetPlayerInterior(targetid));
                new msg[128];
                format(msg, sizeof(msg), "Ban da teleport den %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
            }
            case 7: // Teleport người chơi đến tôi
            {
                new Float:x, Float:y, Float:z;
                GetPlayerPos(playerid, x, y, z);
                SetPlayerPos(targetid, x + 1, y, z);
                SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
                SetPlayerInterior(targetid, GetPlayerInterior(playerid));
                new msg[128];
                format(msg, sizeof(msg), "Ban da teleport %s (ID: %d) den cho minh", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Admin %s da teleport ban den cho ho", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_YELLOW, msg);
            }
            case 8: // Heal
            {
                SetPlayerHealth(targetid, 100.0);
                new msg[128];
                format(msg, sizeof(msg), "Ban da heal %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Admin %s da heal ban", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_YELLOW, msg);
            }
            case 9: // Armor
            {
                SetPlayerArmour(targetid, 100.0);
                new msg[128];
                format(msg, sizeof(msg), "Ban da cap armor cho %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Admin %s da cap armor cho ban", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_YELLOW, msg);
            }
            case 10: // Freeze
            {
                TogglePlayerControllable(targetid, false);
                new msg[128];
                format(msg, sizeof(msg), "Ban da freeze %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Ban da bi freeze boi admin %s", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_RED, msg);
            }
            case 11: // Unfreeze
            {
                TogglePlayerControllable(targetid, true);
                new msg[128];
                format(msg, sizeof(msg), "Ban da unfreeze %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Ban da duoc unfreeze boi admin %s", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_GREEN, msg);
            }
        }
        return 1;
    }
    
    // Player Management Menu
    if(dialogid == DIALOG_PLAYER_OUTFIT_MENU && response)
    {
        new targetid = PlayerPanelSelectedPlayer[playerid];
        if(!IsPlayerConnected(targetid)) 
            return SendClientMessage(playerid, COLOR_GRAD1, "Nguoi choi khong hop le.");
        
        switch(listitem)
        {
            case 0: // Xem thông tin chi tiết
            {
                new name[MAX_PLAYER_NAME];
                GetPlayerName(targetid, name, sizeof(name));
                new Float:health, Float:armour;
                GetPlayerHealth(targetid, health);
                GetPlayerArmour(targetid, armour);
                new Float:x, Float:y, Float:z;
                GetPlayerPos(targetid, x, y, z);
                new connectTime = PlayerInfo[targetid][pConnectHours];
                new level = PlayerInfo[targetid][pLevel];
                new cash = PlayerInfo[targetid][pCash];
                new bank = PlayerInfo[targetid][pAccount];
                new ping = GetPlayerPing(targetid);
                
                new info[1024];
                format(info, sizeof(info),
                    "=== THONG TIN CHI TIET ===\n\n"\
                    "Ten: %s\n"\
                    "ID: %d\n"\
                    "Level: %d\n"\
                    "Thoi gian choi: %d gio\n"\
                    "Mau: %.1f\n"\
                    "Giap: %.1f\n"\
                    "Tien mat: $%s\n"\
                    "Tien ngan hang: $%s\n"\
                    "Ping: %d ms\n"\
                    "Vi tri: %.1f, %.1f, %.1f\n"\
                    "Virtual World: %d\n"\
                    "Interior: %d",
                    name, targetid, level, connectTime, health, armour,
                    number_format(cash), number_format(bank), ping,
                    x, y, z, GetPlayerVirtualWorld(targetid), GetPlayerInterior(targetid)
                );
                ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_INFO, DIALOG_STYLE_MSGBOX, "Thong tin nguoi choi", info, "Dong", "");
            }
            case 1: // Give Weapon
            {
                SetPVarInt(playerid, "GiveGunTarget", targetid);
                new list[1024];
                for(new i = 0; i < sizeof(WeaponNames); i++)
                {
                    format(list, sizeof(list), "%s%s\n", list, WeaponNames[i]);
                }
                ShowPlayerDialog(playerid, DIALOG_GIVEGUN, DIALOG_STYLE_LIST, "> Give Weapon", list, "Select", "Cancel");
            }
            case 2: // Set Stats
            {
                SetPVarInt(playerid, "SetStatTarget", targetid);
                new statlist[2048];
                statlist[0] = EOS;
                for(new i = 0; i < sizeof(StatName); i++)
                {
                    format(statlist, sizeof(statlist), "%s%s\n", statlist, StatName[i]);
                }
                ShowPlayerDialog(playerid, DIALOG_SETSTAT_MENU, DIALOG_STYLE_LIST, "Chon stat de set", statlist, "Chon", "Huy");
            }
            case 3: // Heal
            {
                SetPlayerHealth(targetid, 100.0);
                new msg[128];
                format(msg, sizeof(msg), "Ban da heal %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Admin %s da heal ban", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_YELLOW, msg);
            }
            case 4: // Give Armor
            {
                SetPlayerArmour(targetid, 100.0);
                new msg[128];
                format(msg, sizeof(msg), "Ban da cap armor cho %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Admin %s da cap armor cho ban", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_YELLOW, msg);
            }
            case 5: // Set Money
            {
                SetPVarInt(playerid, "MoneyTarget", targetid);
                ShowPlayerDialog(playerid, DIALOG_PLAYER_OUTFIT_INPUT, DIALOG_STYLE_INPUT, 
                    "Set Money", "Nhap so tien muon set (tien mat):", "Set", "Huy");
            }
            case 6: // Teleport đến
            {
                new Float:x, Float:y, Float:z;
                GetPlayerPos(targetid, x, y, z);
                SetPlayerPos(playerid, x + 1, y, z);
                SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
                SetPlayerInterior(playerid, GetPlayerInterior(targetid));
                new msg[128];
                format(msg, sizeof(msg), "Ban da teleport den %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
            }
            case 7: // Teleport người chơi đến tôi
            {
                new Float:x, Float:y, Float:z;
                GetPlayerPos(playerid, x, y, z);
                SetPlayerPos(targetid, x + 1, y, z);
                SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
                SetPlayerInterior(targetid, GetPlayerInterior(playerid));
                new msg[128];
                format(msg, sizeof(msg), "Ban da teleport %s (ID: %d) den cho minh", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
                format(msg, sizeof(msg), "Admin %s da teleport ban den cho ho", GetPlayerNameEx(playerid));
                SendClientMessage(targetid, COLOR_YELLOW, msg);
            }
            case 8: // Spectate
            {
                TogglePlayerSpectating(playerid, true);
                PlayerSpectatePlayer(playerid, targetid);
                new msg[128];
                format(msg, sizeof(msg), "Ban dang spectate %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                SendClientMessage(playerid, COLOR_YELLOW, msg);
            }
            case 9: // Freeze/Unfreeze
            {
                if(GetPVarInt(targetid, "IsFrozen"))
                {
                    TogglePlayerControllable(targetid, true);
                    DeletePVar(targetid, "IsFrozen");
                    new msg[128];
                    format(msg, sizeof(msg), "Ban da unfreeze %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                    SendClientMessage(playerid, COLOR_YELLOW, msg);
                    format(msg, sizeof(msg), "Ban da duoc unfreeze boi admin %s", GetPlayerNameEx(playerid));
                    SendClientMessage(targetid, COLOR_GREEN, msg);
                }
                else
                {
                    TogglePlayerControllable(targetid, false);
                    SetPVarInt(targetid, "IsFrozen", 1);
                    new msg[128];
                    format(msg, sizeof(msg), "Ban da freeze %s (ID: %d)", GetPlayerNameEx(targetid), targetid);
                    SendClientMessage(playerid, COLOR_YELLOW, msg);
                    format(msg, sizeof(msg), "Ban da bi freeze boi admin %s", GetPlayerNameEx(playerid));
                    SendClientMessage(targetid, COLOR_RED, msg);
                }
            }
            case 10: // Kick
            {
                SetPVarInt(playerid, "PanelTarget", targetid);
                SetPVarInt(playerid, "PanelKickOrBan", 0);
                ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_REASON, DIALOG_STYLE_INPUT, 
                    "Nhap ly do kick", "Nhap ly do kick nguoi choi nay:", "Kick", "Huy");
            }
            case 11: // Ban
            {
                SetPVarInt(playerid, "PanelTarget", targetid);
                SetPVarInt(playerid, "PanelKickOrBan", 1);
                ShowPlayerDialog(playerid, DIALOG_ADMIN_PANEL_REASON, DIALOG_STYLE_INPUT, 
                    "Nhap ly do ban", "Nhap ly do ban nguoi choi nay:", "Ban", "Huy");
            }
        }
        return 1;
    }
    
    // Set Money Input
    if(dialogid == DIALOG_PLAYER_OUTFIT_INPUT && response)
    {
        new targetid = GetPVarInt(playerid, "MoneyTarget");
        if(!IsPlayerConnected(targetid)) 
            return SendClientMessage(playerid, COLOR_GRAD1, "Nguoi choi khong hop le.");
        
        new amount = strval(inputtext);
        if(amount < 0) 
            return SendClientMessage(playerid, COLOR_GRAD1, "So tien khong hop le!");
        
        PlayerInfo[targetid][pCash] = amount;
        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Da set tien mat cua %s thanh $%s", 
            GetPlayerNameEx(targetid), number_format(amount));
        SendClientMessage(playerid, COLOR_LIGHTRED, msg);
        
        format(msg, sizeof(msg), "Admin %s da set tien mat cua ban thanh $%s", 
            GetPlayerNameEx(playerid), number_format(amount));
        SendClientMessage(targetid, COLOR_YELLOW, msg);
        return 1;
    }
    
    return 0;
}

hook OnPlayerDisconnect(playerid, reason)
{
    HidePlayerPanel(playerid);
    PlayerPanelPage[playerid] = 0;
    PlayerPanelSelectedPlayer[playerid] = INVALID_PLAYER_ID;
    
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerPanelShowing[i])
        {
            UpdatePlayerPanelData(i);
        }
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerPanelShowing[playerid] = false;
    PlayerPanelPage[playerid] = 0;
    PlayerPanelSelectedPlayer[playerid] = INVALID_PLAYER_ID;
    
    for(new i = 0; i < MAX_PANEL_PLAYERS * 3 + 8; i++)
    {
        PlayerPanelTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerPanelShowing[i])
        {
            UpdatePlayerPanelData(i);
        }
    }
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_SECONDARY_ATTACK || (newkeys & KEY_NO && !(oldkeys & KEY_NO)))
    {
        if(PlayerPanelShowing[playerid])
        {
            HidePlayerPanel(playerid);
            return 1; 
        }
    }
    return 1;
}

hook OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(PlayerPanelShowing[playerid] && clickedid == Text:INVALID_TEXT_DRAW)
    {
        HidePlayerPanel(playerid);
        return 1;
    }
    return 1;
}