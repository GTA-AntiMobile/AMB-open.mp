#include <YSI\YSI_Coding\y_hooks>

#define LOAD_DANHBA_THREAD      100
#define SAVE_DANHBA_THREAD      101
#define DELETE_DANHBA_THREAD    102

enum E_PHONE_CONTACT {
    contact_name[32],
    contact_number[16]
}

new PlayerContacts[MAX_PLAYERS][50][E_PHONE_CONTACT]; 
new PlayerContactCount[MAX_PLAYERS];



forward ShowPhoneServices(playerid);
forward ShowPhoneContacts(playerid);
forward ShowServiceList(playerid, service);

forward ShowContactActions(playerid, contactIndex);
forward CallServiceMember(playerid, service, listitem);

forward ShowPhoneMain(playerid);
public ShowPhoneMain(playerid) {
    // Kiem tra dien thoai co bat khong
    if(PhoneOnline[playerid] > 0) {
        SendClientMessageEx(playerid, COLOR_GREY, "Dien thoai cua ban dang tat.");
        return 0;
    }
    
    new string[512];
    strcat(string, "Dich Vu\n");
    strcat(string, "Danh Ba");
    
    Dialog_Show(playerid, PhoneMain, DIALOG_STYLE_LIST, 
        "Dien Thoai", string, "Chon", "Dong");
    return 1;
}

ShowPhoneServices(playerid) {
    new string[512];
    strcat(string, "Canh Sat\n");
    strcat(string, "Bac Si\n");
    strcat(string, "Taxi");
    
    Dialog_Show(playerid, PhoneServices, DIALOG_STYLE_LIST, 
        "Dich Vu", string, "Chon", "Quay Lai");
    return 1;
}

ShowPhoneContacts(playerid) {
    new string[2048];
    
    strcat(string, "{FFFF00}Ten\t{00FF00}So Dien Thoai\n");
    
    if(PlayerContactCount[playerid] == 0) {
        strcat(string, "{FF6B6B}Chua co danh ba nao\t{FFFFFF}\n");
    } else {
        for(new i = 0; i < PlayerContactCount[playerid]; i++) {
            format(string, sizeof(string), "%s{FFFFFF}%s\t{87CEEB}%s\n", 
                string, PlayerContacts[playerid][i][contact_name], PlayerContacts[playerid][i][contact_number]);
        }
    }
    
    strcat(string, "{32CD32}+ Them danh ba\t{FFFFFF}");
    
    Dialog_Show(playerid, PhoneContacts, DIALOG_STYLE_TABLIST_HEADERS, 
        "{00BFFF}Danh Ba", string, "{32CD32}Chon", "{FF6B6B}Quay Lai");
    return 1;
}

ShowServiceList(playerid, service) {
    new string[2048], count = 0, title[64];
    
    switch(service) {
        case 1: { // Police
            strcpy(title, "Canh Sat", sizeof(title));
            
            for(new i = 0; i < MAX_PLAYERS; i++) {
                if(IsPlayerConnected(i) && IsACop(i) && PlayerInfo[i][pDuty] == 1) {
                    new name[MAX_PLAYER_NAME];
                    GetPlayerName(i, name, sizeof(name));
                    format(string, sizeof(string), "%s%s (%d)\n", string, name, PlayerInfo[i][pPnumber]);
                    count++;
                }
            }
        }
        case 2: { // Medic  
            strcpy(title, "Bac Si", sizeof(title));
            
            for(new i = 0; i < MAX_PLAYERS; i++) {
                if(IsPlayerConnected(i) && IsAMedic(i) && PlayerInfo[i][pDuty] == 1) {
                    new name[MAX_PLAYER_NAME];
                    GetPlayerName(i, name, sizeof(name));
                    format(string, sizeof(string), "%s%s (%d)\n", string, name, PlayerInfo[i][pPnumber]);
                    count++;
                }
            }
        }
        case 3: { // Taxi
            strcpy(title, "Taxi", sizeof(title));
            
            for(new i = 0; i < MAX_PLAYERS; i++) {
                if(IsPlayerConnected(i) && IsATaxiDriver(i) && PlayerInfo[i][pDuty] == 1) {
                    new name[MAX_PLAYER_NAME];
                    GetPlayerName(i, name, sizeof(name));
                    format(string, sizeof(string), "%s%s (%d)\n", string, name, PlayerInfo[i][pPnumber]);
                    count++;
                }
            }
        }
    }
    
    if(count == 0) {
        strcat(string, "Khong co ai dang lam viec");
    }
    
    switch(service) {
        case 1: Dialog_Show(playerid, PhonePoliceList, DIALOG_STYLE_LIST, title, string, "Goi", "Quay Lai");
        case 2: Dialog_Show(playerid, PhoneMedicList, DIALOG_STYLE_LIST, title, string, "Goi", "Quay Lai");  
        case 3: Dialog_Show(playerid, PhoneTaxiList, DIALOG_STYLE_LIST, title, string, "Goi", "Quay Lai");
    }
    return 1;
}

CallServiceMember(playerid, service, listitem) {
    // Kiem tra dien thoai co bat khong
    if(PhoneOnline[playerid] > 0) {
        SendClientMessageEx(playerid, COLOR_GREY, "Dien thoai cua ban dang tat.");
        return 0;
    }
    
    new count = 0;
    for(new i = 0; i < MAX_PLAYERS; i++) {
        new bool:isValidService = false;
        
        switch(service) {
            case 1: isValidService = (IsPlayerConnected(i) && IsACop(i) && PlayerInfo[i][pDuty] == 1);
            case 2: isValidService = (IsPlayerConnected(i) && IsAMedic(i) && PlayerInfo[i][pDuty] == 1);
            case 3: isValidService = (IsPlayerConnected(i) && IsATaxiDriver(i) && PlayerInfo[i][pDuty] == 1);
        }
        
        if(isValidService) {
            if(count == listitem) {
                new params[32];
                format(params, sizeof(params), "%d", PlayerInfo[i][pPnumber]);
                CallRemoteFunction("OnPlayerCommandText", "is", playerid, sprintf("/call %s", params));
                return 1;
            }
            count++;
        }
    }
    return 0; 
}



ShowContactActions(playerid, contactIndex) {
    new string[256], contactName[32];
    strcpy(contactName, PlayerContacts[playerid][contactIndex][contact_name], 32);
    
    strcat(string, "Goi\n");
    strcat(string, "Nhan tin\n");
    strcat(string, "Xoa");
    
    SetPVarInt(playerid, "SelectedContact", contactIndex);
    
    Dialog_Show(playerid, PhoneContactAction, DIALOG_STYLE_LIST, 
        contactName, string, "Chon", "Quay Lai");
    return 1;
}

Dialog:PhoneMain(playerid, response, listitem, inputtext[]) {
    if(!response) return 1;
    switch(listitem) {
        case 0: ShowPhoneServices(playerid);
        case 1: ShowPhoneContacts(playerid);
    }
    return 1;
}

Dialog:PhoneServices(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneMain(playerid);
        return 1;
    }
    switch(listitem) {
        case 0: ShowServiceList(playerid, 1); // Police
        case 1: ShowServiceList(playerid, 2); // Medic
        case 2: ShowServiceList(playerid, 3); // Taxi
    }
    return 1;
}

Dialog:PhoneContacts(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneMain(playerid);
        return 1;
    }
    
    if(PlayerContactCount[playerid] == 0) {
        if(listitem == 0 || listitem == 1) { 
            Dialog_Show(playerid, PhoneAddContactName, DIALOG_STYLE_INPUT, 
                "Them danh ba", 
                "Nhap ten nguoi can luu:", "Tiep", "Huy");
        }
    }
    else {
        if(listitem == PlayerContactCount[playerid]) {
            Dialog_Show(playerid, PhoneAddContactName, DIALOG_STYLE_INPUT, 
                "Them danh ba", 
                "Nhap ten nguoi can luu:", "Tiep", "Huy");
        }
        else if(listitem < PlayerContactCount[playerid]) {
            ShowContactActions(playerid, listitem);
        }
    }
    return 1;
}

Dialog:PhoneAddContactName(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneContacts(playerid);
        return 1;
    }
    if(strlen(inputtext) < 1 || strlen(inputtext) > 31) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Ten phai tu 1-31 ky tu!");
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    SetPVarString(playerid, "TempContactName", inputtext);
    
    Dialog_Show(playerid, PhoneAddContactNumber, DIALOG_STYLE_INPUT, 
        "{00FF00}Them So Moi", 
        "{FFFFFF}Nhap so dien thoai:", "Luu", "Huy");
    return 1;
}
Dialog:PhoneAddContactNumber(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneContacts(playerid);
        return 1;
    }
    if(strlen(inputtext) < 1 || strlen(inputtext) > 15) {
        SendClientMessageEx(playerid, 0xFF0000FF, "So dien thoai phai tu 1-15 ky tu!");
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    if(PlayerContactCount[playerid] >= 50) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Danh ba da day! (Toi da 50 so)");
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    new tempName[32];
    GetPVarString(playerid, "TempContactName", tempName, sizeof(tempName));
    
    new slot = PlayerContactCount[playerid];
    strcpy(PlayerContacts[playerid][slot][contact_name], tempName, 32);
    strcpy(PlayerContacts[playerid][slot][contact_number], inputtext, 16);
    PlayerContactCount[playerid]++;
    
    SavePlayerContact(playerid, slot);
    
    DeletePVar(playerid, "TempContactName");
    
    SendClientMessageEx(playerid, 0x00FF00FF, "Da luu so dien thoai thanh cong!");
    ShowPhoneContacts(playerid);
    return 1;
}
Dialog:PhonePoliceList(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneServices(playerid);
        return 1;
    }
    
    CallServiceMember(playerid, 1, listitem);
    ShowPhoneServices(playerid);
    return 1;
}
Dialog:PhoneMedicList(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneServices(playerid);
        return 1;
    }
    
    CallServiceMember(playerid, 2, listitem);
    ShowPhoneServices(playerid);
    return 1;
}
Dialog:PhoneTaxiList(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneServices(playerid);
        return 1;
    }
    
    CallServiceMember(playerid, 3, listitem);
    ShowPhoneServices(playerid);
    return 1;
}


Dialog:PhoneSMSMessage(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    if(PhoneOnline[playerid] > 0) {
        SendClientMessageEx(playerid, COLOR_GREY, "Dien thoai cua ban dang tat.");
        ShowPhoneContacts(playerid);
        DeletePVar(playerid, "SMSTarget");
        return 1;
    }
    
    if(strlen(inputtext) < 1) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Noi dung tin nhan khong duoc de trong!");
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    new targetNumber[16];
    GetPVarString(playerid, "SMSTarget", targetNumber, sizeof(targetNumber));
    
    new smsCommand[200];
    format(smsCommand, sizeof(smsCommand), "/sms %s %s", targetNumber, inputtext);
    CallRemoteFunction("OnPlayerCommandText", "is", playerid, smsCommand);
    
    DeletePVar(playerid, "SMSTarget");
    
    ShowPhoneContacts(playerid);
    return 1;
}

Dialog:PhoneContactAction(playerid, response, listitem, inputtext[]) {
    if(!response) {
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    // Kiem tra dien thoai co bat khong
    if(PhoneOnline[playerid] > 0) {
        SendClientMessageEx(playerid, COLOR_GREY, "Dien thoai cua ban dang tat.");
        ShowPhoneContacts(playerid);
        return 1;
    }
    
    new contactIndex = GetPVarInt(playerid, "SelectedContact");
    
    switch(listitem) {
        case 0: { // Call
            new contactNumber[16];
            strcpy(contactNumber, PlayerContacts[playerid][contactIndex][contact_number], 16);
            
            CallRemoteFunction("OnPlayerCommandText", "is", playerid, sprintf("/call %s", contactNumber));
            
            ShowPhoneContacts(playerid);
        }
        case 1: { // SMS
            new contactNumber[16];
            strcpy(contactNumber, PlayerContacts[playerid][contactIndex][contact_number], 16);
            SetPVarString(playerid, "SMSTarget", contactNumber);
            
            Dialog_Show(playerid, PhoneSMSMessage, DIALOG_STYLE_INPUT, 
                "Gui SMS", 
                "Nhap noi dung tin nhan:", "Gui", "Huy");
        }
        case 2: { // Delete contact
            new contactName[32];
            strcpy(contactName, PlayerContacts[playerid][contactIndex][contact_name], 32);
            
            new confirmString[128];
            format(confirmString, sizeof(confirmString), 
                "Ban co chac chan muon xoa %s khong?", contactName);
            
            Dialog_Show(playerid, PhoneDeleteConfirm, DIALOG_STYLE_MSGBOX, 
                "Xac Nhan", confirmString, "Xoa", "Huy");
        }
    }
    
    if(listitem != 2) { 
        DeletePVar(playerid, "SelectedContact");
    }
    return 1;
}

Dialog:PhoneDeleteConfirm(playerid, response, listitem, inputtext[]) {
    new contactIndex = GetPVarInt(playerid, "SelectedContact");
    
    if(response) { 
        new query[256];
        mysql_format(MainPipeline, query, sizeof(query), 
            "DELETE FROM `DanhBa` WHERE `sqlID` = %d AND `TenLienHe` = '%e' AND `SoDienThoai` = '%e'",
            GetPlayerSQLId(playerid),
            PlayerContacts[playerid][contactIndex][contact_name],
            PlayerContacts[playerid][contactIndex][contact_number]
        );
        mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", DELETE_DANHBA_THREAD);
        
        for(new i = contactIndex; i < PlayerContactCount[playerid] - 1; i++) {
            strcpy(PlayerContacts[playerid][i][contact_name], PlayerContacts[playerid][i + 1][contact_name], 32);
            strcpy(PlayerContacts[playerid][i][contact_number], PlayerContacts[playerid][i + 1][contact_number], 16);
        }
        
        PlayerContactCount[playerid]--;
        PlayerContacts[playerid][PlayerContactCount[playerid]][contact_name][0] = 0;
        PlayerContacts[playerid][PlayerContactCount[playerid]][contact_number][0] = 0;
        
        SendClientMessageEx(playerid, 0x00FF00FF, "Da xoa lien he thanh cong!");
    }
    
    DeletePVar(playerid, "SelectedContact");
    ShowPhoneContacts(playerid);
    return 1;
}

CMD:phone(playerid, params[]) {
    if(PlayerInfo[playerid][pPnumber] == 0)
	{
		SendClientMessageEx(playerid, COLOR_GRAD2, "Ban khong co dien thoai.");
		return 1;
	}
    ShowPhoneMain(playerid);
    return 1;
}


ResetPhoneData(playerid) {
    PlayerContactCount[playerid] = 0;
    for(new i = 0; i < 50; i++) {
        PlayerContacts[playerid][i][contact_name][0] = 0;
        PlayerContacts[playerid][i][contact_number][0] = 0;
    }
    
    DeletePVar(playerid, "TempContactName");
    DeletePVar(playerid, "SMSTarget");
    DeletePVar(playerid, "SelectedContact");
    
    return 1;
}

stock SavePlayerContact(playerid, contactIndex) {
    if(contactIndex < 0 || contactIndex >= PlayerContactCount[playerid]) return 0;
    
    new query[512];
    mysql_format(MainPipeline, query, sizeof(query), 
        "INSERT INTO `DanhBa` (`sqlID`, `TenLienHe`, `SoDienThoai`, `NgayCapNhat`) VALUES (%d, '%e', '%e', NOW())",
        GetPlayerSQLId(playerid),
        PlayerContacts[playerid][contactIndex][contact_name],
        PlayerContacts[playerid][contactIndex][contact_number]
    );
    mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SAVE_DANHBA_THREAD);
    return 1;
}

stock SaveAllPlayerContacts(playerid) {
    new query[256];
    mysql_format(MainPipeline, query, sizeof(query), 
        "DELETE FROM `DanhBa` WHERE `sqlID` = %d", GetPlayerSQLId(playerid));
    mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", DELETE_DANHBA_THREAD);
    
    for(new i = 0; i < PlayerContactCount[playerid]; i++) {
        mysql_format(MainPipeline, query, sizeof(query), 
            "INSERT INTO `DanhBa` (`sqlID`, `TenLienHe`, `SoDienThoai`, `NgayCapNhat`) VALUES (%d, '%e', '%e', NOW())",
            GetPlayerSQLId(playerid),
            PlayerContacts[playerid][i][contact_name],
            PlayerContacts[playerid][i][contact_number]
        );
        mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SAVE_DANHBA_THREAD);
    }
    return 1;
}

stock LoadPlayerContacts(playerid) {
    new query[256];
    mysql_format(MainPipeline, query, sizeof(query), 
        "SELECT `TenLienHe`, `SoDienThoai` FROM `DanhBa` WHERE `sqlID` = %d ORDER BY `NgayTao` ASC", 
        GetPlayerSQLId(playerid));
    mysql_function_query(MainPipeline, query, true, "OnLoadPlayerContacts", "i", playerid);
    return 1;
}

forward OnLoadPlayerContacts(playerid);
public OnLoadPlayerContacts(playerid) {
    if(!IsPlayerConnected(playerid)) return 0;
    
    PlayerContactCount[playerid] = 0;
    for(new i = 0; i < 50; i++) {
        PlayerContacts[playerid][i][contact_name][0] = 0;
        PlayerContacts[playerid][i][contact_number][0] = 0;
    }
    
    new rows = cache_num_rows();
    if(rows > 0) {
        new contactName[32], contactNumber[16];
        
        for(new i = 0; i < rows && i < 50; i++) {
            cache_get_value_name(i, "TenLienHe", contactName, sizeof(contactName));
            cache_get_value_name(i, "SoDienThoai", contactNumber, sizeof(contactNumber));
            
            strcpy(PlayerContacts[playerid][i][contact_name], contactName, 32);
            strcpy(PlayerContacts[playerid][i][contact_number], contactNumber, 16);
            PlayerContactCount[playerid]++;
        }
        
        printf("[PHONE] Loaded %d DanhBa for player %s (ID: %d)", PlayerContactCount[playerid], GetPlayerNameEx(playerid), playerid);
    }
    return 1;
}

stock InitPlayerPhone(playerid) {
    LoadPlayerContacts(playerid);
    return 1;
}

stock SavePlayerPhoneOnDisconnect(playerid) {
    if(PlayerContactCount[playerid] > 0) {
        SaveAllPlayerContacts(playerid);
    }
    ResetPhoneData(playerid);
    return 1;
}

hook OnPlayerSpawn(playerid)
{
    InitPlayerPhone(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    SavePlayerPhoneOnDisconnect(playerid);
    return 1;
}

forward ShareMyPhoneNumber(playerid, targetid);
public ShareMyPhoneNumber(playerid, targetid) {
    if(!IsPlayerConnected(targetid)) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Nguoi choi khong online!");
        return 0;
    }
    
    new senderName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, senderName, sizeof(senderName));
    GetPlayerName(targetid, targetName, sizeof(targetName));
    new senderPhone[16];
    format(senderPhone, sizeof(senderPhone), "%d", PlayerInfo[playerid][pPnumber]);
    
    for(new i = 0; i < PlayerContactCount[targetid]; i++) {
        if(!strcmp(PlayerContacts[targetid][i][contact_name], senderName, true) || 
           !strcmp(PlayerContacts[targetid][i][contact_number], senderPhone, true)) {
            SendClientMessageEx(playerid, 0xFF0000FF, "Nguoi do da co so dien thoai cua ban roi!");
            return 0;
        }
    }
    
    if(PlayerContactCount[targetid] >= 50) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Danh ba cua nguoi do da day!");
        return 0;
    }
    
    new slot = PlayerContactCount[targetid];
    strcpy(PlayerContacts[targetid][slot][contact_name], senderName, 32);
    strcpy(PlayerContacts[targetid][slot][contact_number], senderPhone, 16);
    PlayerContactCount[targetid]++;
    
    new query[512];
    mysql_format(MainPipeline, query, sizeof(query), 
        "INSERT INTO `DanhBa` (`sqlID`, `TenLienHe`, `SoDienThoai`, `NgayCapNhat`) VALUES (%d, '%e', '%e', NOW())",
        GetPlayerSQLId(targetid), senderName, senderPhone);
    mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SAVE_DANHBA_THREAD);
    
    SendClientMessageEx(playerid, 0x00FF00FF, "Da chia se so dien thoai cua ban thanh cong!");
    
    new message[128];
    format(message, sizeof(message), "%s da chia se so dien thoai (%s) cho ban!", senderName, senderPhone);
    SendClientMessageEx(targetid, 0x00FFFFFF, message);
    
    return 1;
}

forward DoSharePhoneNumber(playerid, targetid);
public DoSharePhoneNumber(playerid, targetid) {
    // Kiem tra dien thoai co bat khong
    if(PhoneOnline[playerid] > 0) {
        SendClientMessageEx(playerid, COLOR_GREY, "Dien thoai cua ban dang tat.");
        return 0;
    }
    
    if(!IsPlayerConnected(targetid)) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Nguoi choi khong online!");
        return 0;
    }
    
    new senderName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, senderName, sizeof(senderName));
    GetPlayerName(targetid, targetName, sizeof(targetName));
    new senderPhone[16];
    format(senderPhone, sizeof(senderPhone), "%d", PlayerInfo[playerid][pPnumber]);
    
    for(new i = 0; i < PlayerContactCount[targetid]; i++) {
        if(!strcmp(PlayerContacts[targetid][i][contact_name], senderName, true) || 
           !strcmp(PlayerContacts[targetid][i][contact_number], senderPhone, true)) {
            SendClientMessageEx(playerid, 0xFF0000FF, "Nguoi do da co so dien thoai cua ban roi!");
            return 0;
        }
    }
    
    if(PlayerContactCount[targetid] >= 50) {
        SendClientMessageEx(playerid, 0xFF0000FF, "Danh ba cua nguoi do da day!");
        return 0;
    }
    
    new slot = PlayerContactCount[targetid];
    strcpy(PlayerContacts[targetid][slot][contact_name], senderName, 32);
    strcpy(PlayerContacts[targetid][slot][contact_number], senderPhone, 16);
    PlayerContactCount[targetid]++;
    
    new query[512];
    mysql_format(MainPipeline, query, sizeof(query), 
        "INSERT INTO `DanhBa` (`sqlID`, `TenLienHe`, `SoDienThoai`, `NgayCapNhat`) VALUES (%d, '%e', '%e', NOW())",
        GetPlayerSQLId(targetid), senderName, senderPhone);
    mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SAVE_DANHBA_THREAD);
    
    SendClientMessageEx(playerid, 0x00FF00FF, "Da chia se so dien thoai cua ban thanh cong!");
    
    new message[128];
    format(message, sizeof(message), "%s da chia se so dien thoai (%s) cho ban!", senderName, senderPhone);
    SendClientMessageEx(targetid, 0x00FFFFFF, message);
    
    return 1;
}


