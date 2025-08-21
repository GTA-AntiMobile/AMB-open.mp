#include <YSI\YSI_Coding\y_hooks>

#define DIALOG_HISTORY_MAIN         6000
#define DIALOG_HISTORY_DEATH        6001
#define DIALOG_HISTORY_MONEY        6002
#define DIALOG_HISTORY_WEAPON       6003
#define DIALOG_HISTORY_SEARCH       6004
#define DIALOG_HISTORY_PLAYER       6005
#define DIALOG_HISTORY_DATE         6006


enum eHistoryData
{
    historyId,
    historyType,
    historyPlayerId,
    historyPlayerName[MAX_PLAYER_NAME],
    historyTargetId,
    historyTargetName[MAX_PLAYER_NAME],
    historyAmount,
    historyWeaponId,
    historyReason[128],
    historyLocation[64],
    historyDate[32],
    historyExtra[128]
}

new PlayerHistoryPage[MAX_PLAYERS];
new PlayerHistoryType[MAX_PLAYERS];
new PlayerHistoryTarget[MAX_PLAYERS];
new PlayerHistoryRecords[MAX_PLAYERS]; 

#define HISTORY_THREAD_LOAD         100
#define HISTORY_THREAD_SAVE         101
#define HISTORY_THREAD_SEARCH       102


stock LogPlayerDeath(playerid, killerid, const reason[], WEAPON:weaponid, Float:x, Float:y, Float:z)
{
    new query[512], location[64], killerName[MAX_PLAYER_NAME];
    
    GetPlayerZone(playerid, location, sizeof(location));
    
    if(killerid != INVALID_PLAYER_ID) {
        GetPlayerName(killerid, killerName, sizeof(killerName));
    } else {
        format(killerName, sizeof(killerName), "Unknown");
    }
    
    new deathType = DEATH_TYPE_KILLED;
    if(killerid == INVALID_PLAYER_ID) deathType = DEATH_TYPE_ACCIDENT;
    if(killerid == playerid) deathType = DEATH_TYPE_SUICIDE;
    
    format(query, sizeof(query), 
        "INSERT INTO `player_deaths` (`player_id`, `player_name`, `killer_id`, `killer_name`, `weapon_id`, `death_type`, `reason`, `location`, `pos_x`, `pos_y`, `pos_z`, `date`) VALUES (%d, '%s', %d, '%s', %d, %d, '%s', '%s', %.2f, %.2f, %.2f, NOW())",
        GetPlayerSQLId(playerid), GetPlayerNameExt(playerid), 
        (killerid != INVALID_PLAYER_ID) ? GetPlayerSQLId(killerid) : -1, 
        killerName, _:weaponid, deathType, reason, location, x, y, z
    );
    
    mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
    
    new adminMsg[256];
    format(adminMsg, sizeof(adminMsg), "[DEATH LOG] %s da chet boi %s (Weapon: %d) tai %s", 
        GetPlayerNameExt(playerid), killerName, _:weaponid, location);
    SendMessageToAdmins(0xFF6347FF, adminMsg, 1);
}

stock LogMoneyTransfer(playerid, targetid, amount, transferType, const reason[])
{
    new query[512], targetName[MAX_PLAYER_NAME], location[64];
    
    GetPlayerZone(playerid, location, sizeof(location));
    
    if(targetid != INVALID_PLAYER_ID) {
        GetPlayerName(targetid, targetName, sizeof(targetName));
    } else {
        format(targetName, sizeof(targetName), "System");
    }
    
    format(query, sizeof(query), 
        "INSERT INTO `money_transfers` (`player_id`, `player_name`, `target_id`, `target_name`, `amount`, `transfer_type`, `reason`, `location`, `date`) VALUES (%d, '%s', %d, '%s', %d, %d, '%s', '%s', NOW())",
        GetPlayerSQLId(playerid), GetPlayerNameExt(playerid),
        (targetid != INVALID_PLAYER_ID) ? GetPlayerSQLId(targetid) : -1,
        targetName, amount, transferType, reason, location
    );
    
    mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
    
    new adminMsg[256];
    format(adminMsg, sizeof(adminMsg), "[MONEY LOG] %s chuyen $%s cho %s (%s)", 
        GetPlayerNameExt(playerid), number_format(amount), targetName, reason);
    SendMessageToAdmins(0xFFFF00FF, adminMsg, 1);
}

stock LogWeaponTake(playerid, weaponid, ammo, weaponType, groupid, const reason[])
{
    new query[512], location[64], groupName[64];
    
    GetPlayerZone(playerid, location, sizeof(location));
    
    if(weaponType == WEAPON_TYPE_GROUP) {
        format(groupName, sizeof(groupName), "Group %d", groupid);
    } else if(weaponType == WEAPON_TYPE_FAMILY) {
        format(groupName, sizeof(groupName), "Family %d", groupid);
    } else {
        format(groupName, sizeof(groupName), "Admin");
    }
    
    format(query, sizeof(query), 
        "INSERT INTO `weapon_logs` (`player_id`, `player_name`, `weapon_id`, `ammo`, `weapon_type`, `group_id`, `group_name`, `reason`, `location`, `date`) VALUES (%d, '%s', %d, %d, %d, %d, '%s', '%s', '%s', NOW())",
        GetPlayerSQLId(playerid), GetPlayerNameExt(playerid), weaponid, ammo, weaponType, groupid, groupName, reason, location
    );
    
    mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
    
    new adminMsg[256];
    format(adminMsg, sizeof(adminMsg), "[WEAPON LOG] %s lay %s tu %s tai %s", 
        GetPlayerNameExt(playerid), GetWeaponNameEx(weaponid), groupName, location);
    SendMessageToAdmins(0xFFA500FF, adminMsg, 1);
}


stock ShowHistoryMainMenu(playerid)
{
    new string[1024];
    
    strcat(string, "{FFFFFF}Loai Lich su\t{00FF00}Mo ta\t{FFFF00}Trang thai\n");
    
    strcat(string, "{FF6B6B}Tu vong\t{FFFFFF}Xem lich su nguoi choi chet\t{00FF00}Hoat dong\n");
    strcat(string, "{FFD93D}Chuyen tien\t{FFFFFF}Xem lich su giao dich tien te\t{00FF00}Hoat dong\n");
    strcat(string, "{6BCF7F}Lay sung\t{FFFFFF}Xem lich su lay sung tu group/family\t{00FF00}Hoat dong\n");
    strcat(string, "{74C0FC}Tim kiem Player\t{FFFFFF}Tim kiem theo ten hoac ID nguoi choi\t{FFFF00}Tim kiem\n");
    strcat(string, "{A29BFE}Tim kiem Ngay\t{FFFFFF}Tim kiem theo khoang thoi gian\t{FFFF00}Tim kiem\n");
    
    ShowPlayerDialog(playerid, DIALOG_HISTORY_MAIN, DIALOG_STYLE_TABLIST_HEADERS, 
        "{00FF00}AMB History System - Admin Panel", string, "Chon", "Thoat");
}

stock ShowDeathHistory(playerid, page = 0, targetid = -1)
{
    PlayerHistoryPage[playerid] = page;
    PlayerHistoryType[playerid] = HISTORY_TYPE_DEATH;
    PlayerHistoryTarget[playerid] = targetid;
    
    new query[512];
    if(targetid == -1) {
        format(query, sizeof(query), 
            "SELECT * FROM `player_deaths` ORDER BY `date` DESC LIMIT %d, 20", 
            page * 20);
    } else {
        format(query, sizeof(query), 
            "SELECT * FROM `player_deaths` WHERE `player_id` = %d ORDER BY `date` DESC LIMIT %d, 20", 
            targetid, page * 20);
    }
    
    mysql_pquery(MainPipeline, query, "OnHistoryLoad", "ii", playerid, HISTORY_TYPE_DEATH);
}

stock ShowMoneyHistory(playerid, page = 0, targetid = -1)
{
    PlayerHistoryPage[playerid] = page;
    PlayerHistoryType[playerid] = HISTORY_TYPE_MONEY;
    PlayerHistoryTarget[playerid] = targetid;
    
    new query[512];
    if(targetid == -1) {
        format(query, sizeof(query), 
            "SELECT * FROM `money_transfers` ORDER BY `date` DESC LIMIT %d, 20", 
            page * 20);
    } else {
        format(query, sizeof(query), 
            "SELECT * FROM `money_transfers` WHERE `player_id` = %d OR `target_id` = %d ORDER BY `date` DESC LIMIT %d, 20", 
            targetid, targetid, page * 20);
    }
    
    mysql_pquery(MainPipeline, query, "OnHistoryLoad", "ii", playerid, HISTORY_TYPE_MONEY);
}

stock ShowWeaponHistory(playerid, page = 0, targetid = -1)
{
    PlayerHistoryPage[playerid] = page;
    PlayerHistoryType[playerid] = HISTORY_TYPE_WEAPON;
    PlayerHistoryTarget[playerid] = targetid;
    
    new query[512];
    if(targetid == -1) {
        format(query, sizeof(query), 
            "SELECT * FROM `weapon_logs` ORDER BY `date` DESC LIMIT %d, 20", 
            page * 20);
    } else {
        format(query, sizeof(query), 
            "SELECT * FROM `weapon_logs` WHERE `player_id` = %d ORDER BY `date` DESC LIMIT %d, 20", 
            targetid, page * 20);
    }
    
    mysql_pquery(MainPipeline, query, "OnHistoryLoad", "ii", playerid, HISTORY_TYPE_WEAPON);
}



stock ShowPlayerHistoryWithCount(playerid, targetid, const playername[])
{
    new query[512];
    format(query, sizeof(query), 
        "SELECT \
            (SELECT COUNT(*) FROM `player_deaths` WHERE `player_id` = %d) as death_count, \
            (SELECT COUNT(*) FROM `money_transfers` WHERE `player_id` = %d OR `target_id` = %d) as money_count, \
            (SELECT COUNT(*) FROM `weapon_logs` WHERE `player_id` = %d) as weapon_count",
        targetid, targetid, targetid, targetid);
    
    PlayerHistoryTarget[playerid] = targetid;
    SetPVarString(playerid, "SearchPlayerName", playername);
    mysql_pquery(MainPipeline, query, "OnPlayerHistoryCount", "i", playerid);
}

forward OnHistoryLoad(playerid, loadHistoryType);
public OnHistoryLoad(playerid, loadHistoryType)
{
    new rows, fields, string[2048], temp[256];
    cache_get_data(rows, fields);
    
    if(!rows) {
        SendClientMessage(playerid, COLOR_LIGHTRED, "Khong tim thay du lieu lich su nao!");
        return 1;
    }
    
    PlayerHistoryRecords[playerid] = rows;
    
    new title[64];
    
    switch(loadHistoryType) {
        case HISTORY_TYPE_DEATH: {
            format(title, sizeof(title), "Lich su tu vong - Trang %d", PlayerHistoryPage[playerid] + 1);
            strcat(string, "{FFFFFF}Nguoi choi\t{FF6B6B}Ke giet\t{FFFF00}Vu khi\t{00FF00}Thoi gian\n");
            
            for(new i = 0; i < rows; i++) {
                new playerName[MAX_PLAYER_NAME], killerName[MAX_PLAYER_NAME], weaponId, dateStr[32];
                
                cache_get_value_name(i, "player_name", playerName);
                cache_get_value_name(i, "killer_name", killerName);
                cache_get_value_name_int(i, "weapon_id", weaponId);
                cache_get_value_name(i, "date", dateStr);
                
                format(temp, sizeof(temp), "{FFFFFF}%s\t{FF6B6B}%s\t{FFFF00}%s\t{00FF00}%s\n", 
                    playerName, killerName, GetWeaponNameEx(weaponId), dateStr);
                strcat(string, temp);
            }
        }
        
        case HISTORY_TYPE_MONEY: {
            format(title, sizeof(title), "Lich su chuyen tien - Trang %d", PlayerHistoryPage[playerid] + 1);
            strcat(string, "{FFFFFF}Nguoi gui\t{00FF00}Nguoi nhan\t{FFFF00}So tien\t{FF6B6B}Thoi gian\n");
            
            for(new i = 0; i < rows; i++) {
                new playerName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME], amount, dateStr[32];
                
                cache_get_value_name(i, "player_name", playerName);
                cache_get_value_name(i, "target_name", targetName);
                cache_get_value_name_int(i, "amount", amount);
                cache_get_value_name(i, "date", dateStr);
                
                format(temp, sizeof(temp), "{FFFFFF}%s\t{00FF00}%s\t{FFFF00}$%s\t{FF6B6B}%s\n", 
                    playerName, targetName, number_format(amount), dateStr);
                strcat(string, temp);
            }
        }
        
        case HISTORY_TYPE_WEAPON: {
            format(title, sizeof(title), "Lich su lay sung - Trang %d", PlayerHistoryPage[playerid] + 1);
            strcat(string, "{FFFFFF}Nguoi choi\t{00FF00}Vu khi\t{FFFF00}Nguon\t{FF6B6B}Thoi gian\n");
            
            for(new i = 0; i < rows; i++) {
                new playerName[MAX_PLAYER_NAME], groupName[64], weaponId, dateStr[32];
                
                cache_get_value_name(i, "player_name", playerName);
                cache_get_value_name(i, "group_name", groupName);
                cache_get_value_name_int(i, "weapon_id", weaponId);
                cache_get_value_name(i, "date", dateStr);
                
                format(temp, sizeof(temp), "{FFFFFF}%s\t{00FF00}%s\t{FFFF00}%s\t{FF6B6B}%s\n", 
                    playerName, GetWeaponNameEx(weaponId), groupName, dateStr);
                strcat(string, temp);
            }
        }
    }
    
    if(PlayerHistoryPage[playerid] > 0) {
        strcat(string, "\n{A29BFE}[<< Trang truoc]");
    }
    if(rows >= 10) { 
        strcat(string, "\n{74C0FC}[Trang tiep >>]");
    }
    
    ShowPlayerDialog(playerid, DIALOG_HISTORY_MAIN + historyType, DIALOG_STYLE_TABLIST_HEADERS, 
        title, string, "Chi tiet", "Quay lai");
        
    return 1;
}


CMD:lichsu(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1) {
        return SendClientMessage(playerid, COLOR_GREY, "Ban khong co quyen su dung lenh nay!");
    }
    
    ShowHistoryMainMenu(playerid);
    return 1;
}

CMD:plhistory(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2) {
        return SendClientMessage(playerid, COLOR_GREY, "Ban can Admin Level 2+ de su dung lenh nay!");
    }
    
    new targetid, histType;
    if(sscanf(params, "ui", targetid, histType)) {
        SendClientMessage(playerid, COLOR_WHITE, "Su dung: /plhistory [playerid] [type]");
        SendClientMessage(playerid, COLOR_GREY, "Type: 1-Death, 2-Money, 3-Weapon");
        return 1;
    }
    
    if(!IsPlayerConnected(targetid)) {
        return SendClientMessage(playerid, COLOR_GREY, "Nguoi choi khong online!");
    }
    
    switch(histType) {
        case 1: ShowDeathHistory(playerid, 0, GetPlayerSQLId(targetid));
        case 2: ShowMoneyHistory(playerid, 0, GetPlayerSQLId(targetid));
        case 3: ShowWeaponHistory(playerid, 0, GetPlayerSQLId(targetid));
        default: SendClientMessage(playerid, COLOR_GREY, "Loai lich su khong hop le!");
    }
    
    return 1;
}

stock SendMessageToAdmins(color, const message[], level)
{
    foreach(new i : Player) {
        if(PlayerInfo[i][pAdmin] >= level) {
            SendClientMessage(i, color, message);
        }
    }
    return 1;
}


hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_HISTORY_MAIN:
        {
            if(!response) return 1;
            
            switch(listitem)
            {
                case 0: ShowDeathHistory(playerid, 0, -1);
                case 1: ShowMoneyHistory(playerid, 0, -1);
                case 2: ShowWeaponHistory(playerid, 0, -1);
                case 3: {
                    ShowPlayerDialog(playerid, DIALOG_HISTORY_SEARCH, DIALOG_STYLE_INPUT,
                        "Tim kiem theo nguoi choi", 
                        "Nhap ten hoac ID cua nguoi choi ban muon xem lich su:",
                        "Tim kiem", "Quay lai");
                }
                case 4: {
                    ShowPlayerDialog(playerid, DIALOG_HISTORY_DATE, DIALOG_STYLE_INPUT,
                        "Tim kiem theo ngay", 
                        "Nhap ngay (YYYY-MM-DD) hoac so ngay gan day (vi du: 7 cho 7 ngay gan day):",
                        "Tim kiem", "Quay lai");
                }
            }
        }
        
        case DIALOG_HISTORY_SEARCH:
        {
            if(!response) {
                ShowHistoryMainMenu(playerid);
                return 1;
            }
            
            new targetid = -1;
            
            if(IsNumeric(inputtext)) {
                targetid = strval(inputtext);
                if(!IsPlayerConnected(targetid)) {
                    SendClientMessage(playerid, COLOR_LIGHTRED, "Nguoi choi khong online!");
                    ShowHistoryMainMenu(playerid);
                    return 1;
                }
                targetid = GetPlayerSQLId(targetid);
                
                new playername[MAX_PLAYER_NAME];
                GetPlayerName(strval(inputtext), playername, sizeof(playername));
                ShowPlayerHistoryWithCount(playerid, targetid, playername);
            } else {
                new query[256];
                format(query, sizeof(query), "SELECT `id` FROM `accounts` WHERE `Username` = '%s' LIMIT 1", inputtext);
                mysql_pquery(MainPipeline, query, "OnHistoryPlayerSearch", "is", playerid, inputtext);
                return 1;
            }
        }
        
        case DIALOG_HISTORY_DATE:
        {
            if(!response) {
                ShowHistoryMainMenu(playerid);
                return 1;
            }
            
            new string[512];
            format(string, sizeof(string), 
                "{FFFFFF}Loai Lich su\t{00FF00}Mo ta\t{FFFF00}Thoi gian\n");
            format(string, sizeof(string), 
                "%s{FF6B6B}Tu vong\t{FFFFFF}Xem lich su tu vong trong ngay\t{FFFF00}%s\n", string, inputtext);
            format(string, sizeof(string), 
                "%s{FFD93D}Chuyen tien\t{FFFFFF}Xem lich su giao dich trong ngay\t{FFFF00}%s\n", string, inputtext);
            format(string, sizeof(string), 
                "%s{6BCF7F}Lay sung\t{FFFFFF}Xem lich su lay sung trong ngay\t{FFFF00}%s", string, inputtext);
                
            SetPVarString(playerid, "SearchDate", inputtext);
            ShowPlayerDialog(playerid, DIALOG_HISTORY_PLAYER, DIALOG_STYLE_TABLIST_HEADERS,
                "Lich su theo thoi gian", string, "Xem", "Quay lai");
        }
        
        case DIALOG_HISTORY_PLAYER:
        {
            if(!response) {
                ShowHistoryMainMenu(playerid);
                return 1;
            }
            
            new targetid = PlayerHistoryTarget[playerid];
            
            switch(listitem)
            {
                case 0: ShowDeathHistory(playerid, 0, targetid);
                case 1: ShowMoneyHistory(playerid, 0, targetid);
                case 2: ShowWeaponHistory(playerid, 0, targetid);
            }
            return 1;
        }
        
        case DIALOG_HISTORY_DEATH, DIALOG_HISTORY_MONEY, DIALOG_HISTORY_WEAPON:
        {
            if(!response) {
                ShowHistoryMainMenu(playerid);
                return 1;
            }
            
            new currentHistoryType = dialogid - DIALOG_HISTORY_MAIN;
            new targetid = PlayerHistoryTarget[playerid];
            
            new recordCount = PlayerHistoryRecords[playerid];
            new navigationStart = recordCount;
            
            new hasPrevButton = (PlayerHistoryPage[playerid] > 0);
            new hasNextButton = (recordCount >= 10);
            
            if(hasPrevButton && listitem == navigationStart) {
                switch(currentHistoryType) {
                    case HISTORY_TYPE_DEATH: ShowDeathHistory(playerid, PlayerHistoryPage[playerid] - 1, targetid);
                    case HISTORY_TYPE_MONEY: ShowMoneyHistory(playerid, PlayerHistoryPage[playerid] - 1, targetid);
                    case HISTORY_TYPE_WEAPON: ShowWeaponHistory(playerid, PlayerHistoryPage[playerid] - 1, targetid);
                }
                return 1;
            }
            else if(hasNextButton && listitem == navigationStart + (hasPrevButton ? 1 : 0)) {
                switch(currentHistoryType) {
                    case HISTORY_TYPE_DEATH: ShowDeathHistory(playerid, PlayerHistoryPage[playerid] + 1, targetid);
                    case HISTORY_TYPE_MONEY: ShowMoneyHistory(playerid, PlayerHistoryPage[playerid] + 1, targetid);
                    case HISTORY_TYPE_WEAPON: ShowWeaponHistory(playerid, PlayerHistoryPage[playerid] + 1, targetid);
                }
                return 1;
            }
            else if(listitem < navigationStart) {
                new msg[128];
                format(msg, sizeof(msg), "Ban da chon record thu %d (listitem: %d)", listitem + 1, listitem);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                return 1;
            }
        }
    }
    return 0;
}

forward OnPlayerSearchResult(playerid, const playername[]);
public OnPlayerSearchResult(playerid, const playername[])
{
    new rows, fields;
    cache_get_data(rows, fields);
    
    if(!rows) {
        SendClientMessage(playerid, COLOR_LIGHTRED, "Khong tim thay nguoi choi nay trong database!");
        ShowHistoryMainMenu(playerid);
        return 1;
    }
    
    new targetSQLId;
    cache_get_value_name_int(0, "id", targetSQLId);
    
    new string[256];
    format(string, sizeof(string), 
        "Chon loai lich su ban muon xem cho nguoi choi: %s\n\n1. Lich su tu vong\n2. Lich su chuyen tien\n3. Lich su lay sung",
        playername);
        
    PlayerHistoryTarget[playerid] = targetSQLId;
    ShowPlayerDialog(playerid, DIALOG_HISTORY_PLAYER, DIALOG_STYLE_LIST,
        "Chon loai lich su", string, "Xem", "Quay lai");
    
    return 1;
}

forward OnHistoryPlayerSearch(playerid, const playername[]);
public OnHistoryPlayerSearch(playerid, const playername[])
{
    new rows, fields;
    cache_get_data(rows, fields);
    
    if(!rows) {
        SendClientMessage(playerid, COLOR_LIGHTRED, "Khong tim thay nguoi choi trong database!");
        ShowHistoryMainMenu(playerid);
        return 1;
    }
    
    new targetSQLId;
    cache_get_value_name_int(0, "id", targetSQLId);
    
    ShowPlayerHistoryWithCount(playerid, targetSQLId, playername);
    
    return 1;
}


hook OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    new deathReason[64];
    if(killerid == INVALID_PLAYER_ID) {
        format(deathReason, sizeof(deathReason), "Tu vong do tai nan");
    } else if(killerid == playerid) {
        format(deathReason, sizeof(deathReason), "Tu tu");
    } else {
        format(deathReason, sizeof(deathReason), "Bi giet boi %s", GetPlayerNameExt(killerid));
    }
    
    LogPlayerDeath(playerid, killerid, deathReason, reason, x, y, z);
    return 1;
}

stock LoggedTransferStorage(playerid, targetid, amount, const reason[])
{
    TransferStorage(targetid, -1, playerid, 0, 1, amount, -1, -1);
    
    LogMoneyTransfer(playerid, targetid, amount, MONEY_TYPE_GIVE, reason);
    
    return 1;
}

stock LoggedBankDeposit(playerid, amount)
{
    if(PlayerInfo[playerid][pCash] >= amount) {
        PlayerInfo[playerid][pCash] -= amount;
        PlayerInfo[playerid][pAccount] += amount;
        
        LogMoneyTransfer(playerid, INVALID_PLAYER_ID, amount, MONEY_TYPE_BANK_DEPOSIT, "Gui tien vao ngan hang");
        
        return 1;
    }
    return 0;
}

stock LoggedBankWithdraw(playerid, amount)
{
    if(PlayerInfo[playerid][pAccount] >= amount) {
        PlayerInfo[playerid][pAccount] -= amount;
        PlayerInfo[playerid][pCash] += amount;
        
        LogMoneyTransfer(playerid, INVALID_PLAYER_ID, amount, MONEY_TYPE_BANK_WITHDRAW, "Rut tien tu ngan hang");
        
        return 1;
    }
    return 0;
}

stock LoggedFamilyWeaponTake(playerid, weaponid, familyid)
{
    LogWeaponTake(playerid, weaponid, 60000, WEAPON_TYPE_FAMILY, familyid, "Lay sung tu family safe");
    return 1;
}

stock LoggedGroupWeaponTake(playerid, weaponid, groupid)
{
    LogWeaponTake(playerid, weaponid, 60000, WEAPON_TYPE_GROUP, groupid, "Lay sung tu group locker");
    return 1;
}

forward OnPlayerHistoryCount(playerid);
public OnPlayerHistoryCount(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    
    if(!rows) {
        SendClientMessage(playerid, COLOR_LIGHTRED, "Khong the lay thong tin so luong lich su!");
        ShowHistoryMainMenu(playerid);
        return 1;
    }
    
    new death_count, money_count, weapon_count;
    cache_get_value_name_int(0, "death_count", death_count);
    cache_get_value_name_int(0, "money_count", money_count);
    cache_get_value_name_int(0, "weapon_count", weapon_count);
    
    new playername[MAX_PLAYER_NAME];
    GetPVarString(playerid, "SearchPlayerName", playername, sizeof(playername));
    
    new string[512];
    format(string, sizeof(string), 
        "{FFFFFF}Loai Lich su\t{00FF00}Mo ta\t{FFFF00}So luong\n");
    format(string, sizeof(string), 
        "%s{FF6B6B}Tu vong\t{FFFFFF}Xem lich su chet cua nguoi nay\t{FFFF00}%d\n", string, death_count);
    format(string, sizeof(string), 
        "%s{FFD93D}Chuyen tien\t{FFFFFF}Xem lich su giao dich tien te\t{FFFF00}%d\n", string, money_count);
    format(string, sizeof(string), 
        "%s{6BCF7F}Lay sung\t{FFFFFF}Xem lich su lay sung\t{FFFF00}%d", string, weapon_count);
    
    new title[128];
    format(title, sizeof(title), "Lich su cua %s", playername);
    
    ShowPlayerDialog(playerid, DIALOG_HISTORY_PLAYER, DIALOG_STYLE_TABLIST_HEADERS,
        title, string, "Xem", "Quay lai");
    
    return 1;
}
