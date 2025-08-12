#include <YSI\YSI_Coding\y_hooks>

#define DIALOG_FACTION_PANEL        (3400)
#define DIALOG_FACTION_MENU         (3401)
#define DIALOG_FACTION_MEMBERS      (3402)
#define DIALOG_FACTION_VEHICLES     (3403)
#define DIALOG_FACTION_RANKS        (3404)
#define DIALOG_FACTION_DIVISIONS    (3405)

CMD:factionpanel(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1 && !PlayerInfo[playerid][pFactionModerator])
    {
        return SendClientMessageEx(playerid, COLOR_GRAD2, "Ban khong co quyen su dung lenh nay.");
    }
    
    ShowFactionPanel(playerid);
    return 1;
}

stock ShowFactionPanel(playerid)
{
    new szDialogStr[MAX_GROUPS * (GROUP_MAX_NAME_LEN + 32)];
    new szTemp[GROUP_MAX_NAME_LEN + 32];
    new iCount = 0;
    
    strcat(szDialogStr, "ID\tTen Faction\tLoai\tNgan sach\n");
    
    for(new i = 0; i < MAX_GROUPS; i++)
    {
        if(arrGroupData[i][g_szGroupName][0])
        {
            format(szTemp, sizeof(szTemp), "%d\t{%s}%s{FFFFFF}\t%s\t$%s\n",
                i + 1,
                Group_NumToDialogHex(arrGroupData[i][g_hDutyColour]),
                arrGroupData[i][g_szGroupName],
                Group_ReturnType(arrGroupData[i][g_iGroupType]),
                number_format(arrGroupData[i][g_iBudget])
            );
            strcat(szDialogStr, szTemp);
            iCount++;
        }
    }
    
    if(iCount == 0)
    {
        strcat(szDialogStr, "Khong co faction nao ton tai.");
    }
    
    ShowPlayerDialog(playerid, DIALOG_FACTION_PANEL, DIALOG_STYLE_TABLIST_HEADERS, 
        "He Thong Quan Ly Faction", szDialogStr, "Chon", "Dong");
}

stock ShowFactionMenu(playerid, factionid)
{
    if(factionid < 0 || factionid >= MAX_GROUPS || !arrGroupData[factionid][g_szGroupName][0])
    {
        return SendClientMessageEx(playerid, COLOR_GRAD2, "Faction khong hop le.");
    }
    
    new memberCount = 0;
    foreach(new i : Player)
    {
        if(PlayerInfo[i][pMember] == factionid)
            memberCount++;
    }
    
    new vehicleCount = 0;
    for(new i = 0; i < MAX_DYNAMIC_VEHICLES; i++)
    {
        if(DynVehicleInfo[i][gv_igID] == factionid && DynVehicleInfo[i][gv_iModel] > 0)
            vehicleCount++;
    }
    
    new rankCount = String_Count(arrGroupRanks[factionid], MAX_GROUP_RANKS);
    
    new divCount = String_Count(arrGroupDivisions[factionid], MAX_GROUP_DIVS);
    
    new szDialog[512];
    format(szDialog, sizeof(szDialog),
        "Thanh vien online (%d nguoi)\n\
        Phuong tien (%d xe)\n\
        Cap bac (%d ranks)\n\
        Phong ban (%d divisions)",
        memberCount, vehicleCount, rankCount, divCount
    );
    
    new szTitle[GROUP_MAX_NAME_LEN + 32];
    format(szTitle, sizeof(szTitle), "{%s}%s {FFFFFF}- Menu", 
        Group_NumToDialogHex(arrGroupData[factionid][g_hDutyColour]), 
        arrGroupData[factionid][g_szGroupName]);
    
    ShowPlayerDialog(playerid, DIALOG_FACTION_MENU, DIALOG_STYLE_LIST, szTitle, szDialog, "Chon", "Tro lai");
    
    SetPVarInt(playerid, "FactionPanel_FactionID", factionid);
    return 1;
}

stock ShowFactionMembers(playerid, factionid)
{
    new szDialog[2048];
    new szTemp[128];
    new memberCount = 0;
    
    format(szDialog, sizeof(szDialog), 
        "{FFFF00}THANH VIEN ONLINE - {%s}%s{FFFFFF}\n\n",
        Group_NumToDialogHex(arrGroupData[factionid][g_hDutyColour]),
        arrGroupData[factionid][g_szGroupName]
    );
    
    foreach(new i : Player)
    {
        if(PlayerInfo[i][pMember] == factionid)
        {
            new rankName[GROUP_MAX_RANK_LEN] = "Chua co";
            new divName[GROUP_MAX_DIV_LEN] = "Chua co";
            
            if(0 <= PlayerInfo[i][pRank] < MAX_GROUP_RANKS && arrGroupRanks[factionid][PlayerInfo[i][pRank]][0])
            {
                format(rankName, sizeof(rankName), "%s", arrGroupRanks[factionid][PlayerInfo[i][pRank]]);
            }
            
            if(0 <= PlayerInfo[i][pDivision] < MAX_GROUP_DIVS && arrGroupDivisions[factionid][PlayerInfo[i][pDivision]][0])
            {
                format(divName, sizeof(divName), "%s", arrGroupDivisions[factionid][PlayerInfo[i][pDivision]]);
            }
            
            format(szTemp, sizeof(szTemp), "{FFFFFF}%s\n{BBBBBB}Rank: {FFFFFF}%s {BBBBBB}| Division: {FFFFFF}%s\n\n",
                GetPlayerNameEx(i), rankName, divName);
            strcat(szDialog, szTemp);
            memberCount++;
        }
    }
    
    if(memberCount == 0)
    {
        strcat(szDialog, "{FFFFFF}Khong co thanh vien nao online.");
    }
    else
    {
        format(szTemp, sizeof(szTemp), "{FFFF00}Tong cong: {FFFFFF}%d thanh vien online", memberCount);
        strcat(szDialog, szTemp);
    }
    
    ShowPlayerDialog(playerid, DIALOG_FACTION_MEMBERS, DIALOG_STYLE_MSGBOX, 
        "Thanh Vien Online", szDialog, "Tro lai", "Dong");
}

stock ShowFactionVehicles(playerid, factionid)
{
    new szDialog[2048];
    new szTemp[128];
    new vehicleCount = 0;
    new listedVehicles = 0;
    
    format(szDialog, sizeof(szDialog), 
        "{FFFF00}PHUONG TIEN - {%s}%s{FFFFFF}\n\n",
        Group_NumToDialogHex(arrGroupData[factionid][g_hDutyColour]),
        arrGroupData[factionid][g_szGroupName]
    );
    
    // Count total vehicles first
    for(new i = 0; i < MAX_DYNAMIC_VEHICLES; i++)
    {
        if(DynVehicleInfo[i][gv_igID] == factionid && DynVehicleInfo[i][gv_iModel] > 0)
            vehicleCount++;
    }
    
    if(vehicleCount > 0)
    {
        strcat(szDialog, "{FFFFFF}Danh sach phuong tien:\n\n");
        
        for(new i = 0; i < MAX_DYNAMIC_VEHICLES && listedVehicles < 15; i++)
        {
            if(DynVehicleInfo[i][gv_igID] == factionid && DynVehicleInfo[i][gv_iModel] > 0)
            {
                format(szTemp, sizeof(szTemp), "{FFFFFF}%s {BBBBBB}(Vehicle ID: %d)\n", 
                    VehicleName[DynVehicleInfo[i][gv_iModel] - 400], 
                    DynVehicleInfo[i][gv_iSpawnedID]);
                strcat(szDialog, szTemp);
                listedVehicles++;
            }
        }
        
        if(vehicleCount > 15)
        {
            format(szTemp, sizeof(szTemp), "\n{BBBBBB}... va %d phuong tien khac", vehicleCount - 15);
            strcat(szDialog, szTemp);
        }
        
        format(szTemp, sizeof(szTemp), "\n\n{FFFF00}Tong cong: {FFFFFF}%d phuong tien", vehicleCount);
        strcat(szDialog, szTemp);
    }
    else
    {
        strcat(szDialog, "{FFFFFF}Faction nay khong co phuong tien nao.");
    }
    
    ShowPlayerDialog(playerid, DIALOG_FACTION_VEHICLES, DIALOG_STYLE_MSGBOX, 
        "Phuong Tien Faction", szDialog, "Tro lai", "Dong");
}

stock ShowFactionRanks(playerid, factionid)
{
    new szDialog[2048];
    new szTemp[256];
    new rankCount = 0;
    
    format(szDialog, sizeof(szDialog), 
        "{FFFF00}CAP BAC - {%s}%s{FFFFFF}\n\n",
        Group_NumToDialogHex(arrGroupData[factionid][g_hDutyColour]),
        arrGroupData[factionid][g_szGroupName]
    );
    
    for(new i = 0; i < MAX_GROUP_RANKS; i++)
    {
        if(arrGroupRanks[factionid][i][0])
        {
            format(szTemp, sizeof(szTemp), "{FFFFFF}Rank %d: {BBBBBB}%s\n", i, arrGroupRanks[factionid][i]);
            strcat(szDialog, szTemp);
            
            new memberList[256] = "";
            new memberCount = 0;
            new bool:hasMembers = false;
            
            foreach(new p : Player)
            {
                if(PlayerInfo[p][pMember] == factionid && PlayerInfo[p][pRank] == i)
                {
                    if(hasMembers)
                    {
                        strcat(memberList, ", ");
                    }
                    strcat(memberList, GetPlayerNameEx(p));
                    hasMembers = true;
                    memberCount++;
                    
                    if(memberCount >= 10)
                    {
                        strcat(memberList, "...");
                        break;
                    }
                }
            }
            
            if(hasMembers)
            {
                format(szTemp, sizeof(szTemp), "{00FF00}Thanh vien: {FFFFFF}%s\n\n", memberList);
                strcat(szDialog, szTemp);
            }
            else
            {
                strcat(szDialog, "{FF0000}Khong co thanh vien nao\n\n");
            }
            
            rankCount++;
        }
    }
    
    if(rankCount == 0)
    {
        strcat(szDialog, "{FFFFFF}Faction nay chua co cap bac nao duoc thiet lap.");
    }
    else
    {
        format(szTemp, sizeof(szTemp), "{FFFF00}Tong cong: {FFFFFF}%d cap bac", rankCount);
        strcat(szDialog, szTemp);
    }
    
    ShowPlayerDialog(playerid, DIALOG_FACTION_RANKS, DIALOG_STYLE_MSGBOX, 
        "Cap Bac Faction", szDialog, "Tro lai", "Dong");
}

stock ShowFactionDivisions(playerid, factionid)
{
    new szDialog[2048];
    new szTemp[256];
    new divCount = 0;
    
    format(szDialog, sizeof(szDialog), 
        "{FFFF00}PHONG BAN - {%s}%s{FFFFFF}\n\n",
        Group_NumToDialogHex(arrGroupData[factionid][g_hDutyColour]),
        arrGroupData[factionid][g_szGroupName]
    );
    
    for(new i = 0; i < MAX_GROUP_DIVS; i++)
    {
        if(arrGroupDivisions[factionid][i][0])
        {
            format(szTemp, sizeof(szTemp), "{FFFFFF}%s\n", arrGroupDivisions[factionid][i]);
            strcat(szDialog, szTemp);
            
            new memberList[256] = "";
            new memberCount = 0;
            new bool:hasMembers = false;
            
            foreach(new p : Player)
            {
                if(PlayerInfo[p][pMember] == factionid && PlayerInfo[p][pDivision] == i)
                {
                    if(hasMembers)
                    {
                        strcat(memberList, ", ");
                    }
                    strcat(memberList, GetPlayerNameEx(p));
                    hasMembers = true;
                    memberCount++;
                    
                    if(memberCount >= 10)
                    {
                        strcat(memberList, "...");
                        break;
                    }
                }
            }
            
            if(hasMembers)
            {
                format(szTemp, sizeof(szTemp), "{00FF00}Thanh vien: {FFFFFF}%s\n\n", memberList);
                strcat(szDialog, szTemp);
            }
            else
            {
                strcat(szDialog, "{FF0000}Khong co thanh vien nao\n\n");
            }
            
            divCount++;
        }
    }
    
    if(divCount == 0)
    {
        strcat(szDialog, "{FFFFFF}Faction nay chua co phong ban nao duoc thiet lap.");
    }
    else
    {
        format(szTemp, sizeof(szTemp), "{FFFF00}Tong cong: {FFFFFF}%d phong ban", divCount);
        strcat(szDialog, szTemp);
    }
    
    ShowPlayerDialog(playerid, DIALOG_FACTION_DIVISIONS, DIALOG_STYLE_MSGBOX, 
        "Phong Ban Faction", szDialog, "Tro lai", "Dong");
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_FACTION_PANEL:
        {
            if(!response) return 1;
            
            new selectedFaction = -1;
            new currentItem = 0;
            
            for(new i = 0; i < MAX_GROUPS; i++)
            {
                if(arrGroupData[i][g_szGroupName][0])
                {
                    if(currentItem == listitem)
                    {
                        selectedFaction = i;
                        break;
                    }
                    currentItem++;
                }
            }
            
            if(selectedFaction != -1)
            {
                ShowFactionMenu(playerid, selectedFaction);
            }
            return 1;
        }
        
        case DIALOG_FACTION_MENU:
        {
            if(!response)
            {
                ShowFactionPanel(playerid);
                return 1;
            }
            
            new factionid = GetPVarInt(playerid, "FactionPanel_FactionID");
            
            switch(listitem)
            {
                case 0: ShowFactionMembers(playerid, factionid);
                case 1: ShowFactionVehicles(playerid, factionid);
                case 2: ShowFactionRanks(playerid, factionid);
                case 3: ShowFactionDivisions(playerid, factionid);
            }
            return 1;
        }
        
        case DIALOG_FACTION_MEMBERS, DIALOG_FACTION_VEHICLES, DIALOG_FACTION_RANKS, DIALOG_FACTION_DIVISIONS:
        {
            if(response)
            {
                new factionid = GetPVarInt(playerid, "FactionPanel_FactionID");
                ShowFactionMenu(playerid, factionid);
            }
            return 1;
        }
    }
    return 0;
}