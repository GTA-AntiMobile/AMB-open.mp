#include <YSI\YSI_Coding\y_hooks>
#include <streamer>

#define mysql_function_query(%0,%1,%2,%3,%4,%5) mysql_function_query_internal(%0,%1,%2,%3,%4,%5)

#define DIALOG_TRUCKER_COMPANY_MAIN 9000
#define DIALOG_TRUCKER_COMPANY_INVITE 9002
#define DIALOG_TRUCKER_COMPANY_KICK   9003
#define DIALOG_TRUCKER_COMPANY_DEPOSIT 9004
#define DIALOG_TRUCKER_COMPANY_BUYVEH 9005
#define DIALOG_TRUCKER_COMPANY_SET_DIRECTOR 9006
#define DIALOG_TRUCKER_COMPANY_PLAYERLIST_INVITE 9100
#define DIALOG_TRUCKER_COMPANY_PLAYERLIST_KICK   9101
#define DIALOG_TRUCKER_COMPANY_PLAYERLIST_SETDIR 9102
#define DIALOG_TRUCKER_COMPANY_MEMBERLIST        9103
#define DIALOG_TRUCKER_COMPANY_INVITE_CONFIRM 9200
#define DIALOG_TRUCKER_COMPANY_BOX_STEP1 9601
#define DIALOG_TRUCKER_COMPANY_BOX_STEP2 9602
#define DIALOG_TRUCKER_COMPANY_BOX_STEP3 9603

#define DIALOG_TRUCKER_CERT_ADD   9701
#define DIALOG_TRUCKER_CERT_DEL   9702

#define DIALOG_COMPANY_PUTBOX 9801
#define DIALOG_TRUCKER_COMPANY_BOX_TYPE 9604

#define MAX_TRUCKER_VEHICLES 20
#define MAX_TRUCKER_BOX_SLOTS 200
#define DIALOG_COMPANY_GETBOX 9802

forward bool:CalculateGroundPlacement(playerid, &Float:ox, &Float:oy, &Float:oz);

new TruckerVehicleNames[MAX_TRUCKER_VEHICLES][32];
new TruckerVehicleGrantTime[MAX_TRUCKER_VEHICLES][32];

#define PICKUP_BOX_DISTANCE 4.0
#define BOX_TYPE_NGUYEN_LIEU 1
#define BOX_TYPE_VAT_PHAM    2
#define BOX_TYPE_DUNG_CU     3

#define SPECIAL_TRUCK_ID 554        // Vehicle ID (not model)
#define SPECIAL_BOX_OBJECT 3800
#define PLAYER_BOX_OBJECT 2969

new const BoxTypeNames[][] = {
    "Trong",        // 0
    "Nguyen Lieu",  // 1
    "Vat pham",     // 2
    "Dung cu"       // 3
};

new TruckerVehicleBoxType[MAX_TRUCKER_VEHICLES][MAX_TRUCKER_BOX_SLOTS];
new TruckerVehicleBoxAmount[MAX_TRUCKER_VEHICLES][MAX_TRUCKER_BOX_SLOTS];
new TruckerVehicleBoxName[MAX_TRUCKER_VEHICLES][MAX_TRUCKER_BOX_SLOTS][32];
new TruckerVehicleIDs[MAX_TRUCKER_VEHICLES];
new TruckerVehicleCount = 0;

#define TRUCKER_COMPANY_ID 0
#define MAX_TRUCKER_COMPANY_MEMBERS 32
#define MAX_TRUCKER_COMPANY_NAME 32
#define MAX_PLAYER_NAME 24

#define MAX_TRUCKER_COMPANIES 10

enum eTruckerCompany
{
    tcDirectorID,
    tcName[MAX_TRUCKER_COMPANY_NAME],
    tcFunds,
    tcMemberIDs[MAX_TRUCKER_COMPANY_MEMBERS],
    tcMemberCount
};
new TruckerCompany[1][eTruckerCompany];

new tcMemberName[MAX_TRUCKER_COMPANY_MEMBERS][MAX_PLAYER_NAME];
new tcMemberJoinDate[MAX_TRUCKER_COMPANY_MEMBERS][20];
new tcMemberMysqlID[MAX_TRUCKER_COMPANY_MEMBERS];


#define MAX_COMPANY_BOXES 100

enum eCompanyBox
{
    boxObjID,
    boxOwner,
    boxName[32],
    boxAmount,
    boxModel,
    boxTargetName[MAX_PLAYER_NAME],
    Text3D:boxLabelID 
};
new CompanyBoxes[MAX_COMPANY_BOXES][eCompanyBox];

new g_PlayerBoxName[MAX_PLAYERS][32];
new g_PlayerBoxAmount[MAX_PLAYERS];
new g_PlayerBoxOwner[MAX_PLAYERS];
new g_BoxInputTargetName[MAX_PLAYERS][MAX_PLAYER_NAME];
new g_BoxInputName[MAX_PLAYERS][32];
new bool:g_PlayerCarryingBox[MAX_PLAYERS];
new bool:g_PlayerCarryingSpecialBox[MAX_PLAYERS]; 

new Vehicle554BoxObject[MAX_VEHICLES]; 
new bool:Vehicle554HasBox[MAX_VEHICLES]; 
new bool:AdminOpenedBox[MAX_COMPANY_BOXES]; 
new Vehicle554BoxType[MAX_VEHICLES]; 
new Vehicle554BoxAmount[MAX_VEHICLES]; 
new Vehicle554BoxName[MAX_VEHICLES][32]; 

hook OnGameModeInit()
{
    LoadTruckerCompany();
    LoadTruckerCompanyMembers();
    LoadTruckerCertifiedVehicles();
    
    for(new i = 0; i < MAX_VEHICLES; i++)
    {
        Vehicle554BoxObject[i] = 0;
        Vehicle554HasBox[i] = false;
        Vehicle554BoxType[i] = 0;
        Vehicle554BoxAmount[i] = 0;
        Vehicle554BoxName[i][0] = '\0';
    }
    
    for(new i = 0; i < MAX_COMPANY_BOXES; i++)
    {
        AdminOpenedBox[i] = false;
    }
    
    foreach(new i: Player)
    {
        g_PlayerCarryingSpecialBox[i] = false;
    }
    
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    new boxid; 
    if(newkeys & KEY_YES)
    {
            
            if(g_PlayerCarryingBox[playerid] && IsPlayerNearTruck(playerid, 5.0))
            {
                new vehicleid = GetNearestTruckerVehicle(playerid, 5.0);
                
                SetPVarInt(playerid, "CompanyTruckerVehicleID", vehicleid);

                new str[2048];
                new slots = GetTruckBoxSlots(vehicleid);
                new idx = GetTruckerVehicleIndex(vehicleid);
                for(new i = 0; i < slots; i++)
                {
                    strcat(str, BoxTypeNames[TruckerVehicleBoxType[idx][i]]);
                    strcat(str, "\n");
                }
                ShowPlayerDialog(playerid, DIALOG_COMPANY_PUTBOX, DIALOG_STYLE_LIST, "Chon vi tri bo hang vao xe", str, "Bo vao", "Huy");
                return 1;
            }
            if(!g_PlayerCarryingBox[playerid] && PlayerInfo[playerid][pAdmin] >= 4)
            {
                for(new v = 1; v < MAX_VEHICLES; v++)
                {
                    if(GetVehicleModel(v) == 554 && Vehicle554HasBox[v])
                    {
                        new Float:vx, Float:vy, Float:vz;
                        GetVehiclePos(v, vx, vy, vz);
                        if(GetPlayerDistanceFromPoint(playerid, vx, vy, vz) <= 6.0) 
                        {
                            TakeBoxFromVehicle554(playerid, v);
                            return 1;
                        }
                    }
                }
            }
            
            if(!g_PlayerCarryingBox[playerid] && IsPlayerNearTruck(playerid, 5.0))
            {
                new vehicleid = GetNearestTruckerVehicle(playerid, 5.0);

                SetPVarInt(playerid, "CompanyTruckerVehicleID", vehicleid);

                new str[2048];
                new slots = GetTruckBoxSlots(vehicleid);
                new idx = GetTruckerVehicleIndex(vehicleid);
                for(new i = 0; i < slots; i++)
                {
                    if(TruckerVehicleBoxType[idx][i] != 0)
                        format(str, sizeof(str), "%s%s\n", str, TruckerVehicleBoxName[idx][i]);
                    else
                        strcat(str, "Trong\n");
                }
                ShowPlayerDialog(playerid, DIALOG_COMPANY_GETBOX, DIALOG_STYLE_LIST, "Chon vi tri lay hang tu xe", str, "Lay", "Huy");
                return 1;
            }
            if(g_PlayerCarryingBox[playerid] && PlayerInfo[playerid][pAdmin] >= 4)
            {
                new Float:px, Float:py, Float:pz;
                GetPlayerPos(playerid, px, py, pz);
                
                for(new v = 1; v < MAX_VEHICLES; v++)
                {
                    if(GetVehicleModel(v) != 0) 
                    {
                        new Float:vx, Float:vy, Float:vz;
                        GetVehiclePos(v, vx, vy, vz);
                        if(GetPlayerDistanceFromPoint(playerid, vx, vy, vz) <= 5.0) 
                        {
                            new vehicleModel = GetVehicleModel(v);
                            if(vehicleModel == 554) 
                            {
                                if(Vehicle554HasBox[v])
                                {
                                    SendClientMessage(playerid, -1, "Xe Yosemite nay da co thung hang roi!");
                                    return 1;
                                }
                                PutBoxOnVehicle554(playerid, v);
                                return 1;
                            }
                            else
                            {
                                new str[128];
                                format(str, sizeof(str), "Xe nay khong phai Yosemite! (Model: %d, ID: %d)", vehicleModel, v);
                                SendClientMessage(playerid, -1, str);
                                SendClientMessage(playerid, -1, "Ban can tim xe Yosemite (model 554) de dat thung hang!");
                                return 1; 
                            }
                        }
                    }
                }
            }
            new bool:nearYosemite = false;
            if(PlayerInfo[playerid][pAdmin] >= 4)
            {
                for(new v = 1; v < MAX_VEHICLES; v++)
                {
                    if(GetVehicleModel(v) == 554) 
                    {
                        new Float:vx, Float:vy, Float:vz;
                        GetVehiclePos(v, vx, vy, vz);
                        if(GetPlayerDistanceFromPoint(playerid, vx, vy, vz) <= 5.0)
                        {
                            nearYosemite = true;
                            break;
                        }
                    }
                }
            }
            
            if(g_PlayerCarryingBox[playerid] && !IsPlayerNearTruck(playerid, 5.0) && !nearYosemite)
            {
                new Float:ox, Float:oy, Float:oz;
                CalculateGroundPlacement(playerid, ox, oy, oz);

                for(new i = 0; i < MAX_COMPANY_BOXES; i++)
                {
                    if(CompanyBoxes[i][boxObjID] == 0)
                    {
                        new objectModel = 2969; 
                        if(g_PlayerCarryingSpecialBox[playerid])
                        {
                            objectModel = 3800;
                            AdminOpenedBox[i] = false; 
                        }
                        else
                        {
                            AdminOpenedBox[i] = false;
                        }
                        
                        CompanyBoxes[i][boxObjID] = CreateDynamicObject(objectModel, ox, oy, oz, 0.0, 0.0, 0.0);
                        CompanyBoxes[i][boxModel] = objectModel;
                        CompanyBoxes[i][boxOwner] = playerid;
                        format(CompanyBoxes[i][boxName], 32, "%s", g_PlayerBoxName[playerid]);
                        CompanyBoxes[i][boxAmount] = g_PlayerBoxAmount[playerid];
                        format(CompanyBoxes[i][boxTargetName], MAX_PLAYER_NAME, "%s", g_BoxInputTargetName[playerid]);

                        if(objectModel == 3800)
                        {
                            new label[128];
                            new targetName[MAX_PLAYER_NAME];
                            if(strlen(CompanyBoxes[i][boxTargetName]) > 0)
                            {
                                format(targetName, sizeof(targetName), "%s", CompanyBoxes[i][boxTargetName]);
                            }
                            else
                            {
                                format(targetName, sizeof(targetName), "Khong co");
                            }
                            format(label, sizeof(label), "{FFFF00}%s\n{FFFFFF}So luong: %d\n{FFFFFF}Nguoi nhan: %s\n{FF0000}[CLOSED]", 
                                CompanyBoxes[i][boxName], CompanyBoxes[i][boxAmount], targetName);
                            CompanyBoxes[i][boxLabelID] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, ox, oy, oz+1.0, 20.0);
                        }

                        ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, false, false, false, false, 0);
                        
                        RemovePlayerAttachedObject(playerid, 0);
                        g_PlayerCarryingBox[playerid] = false;
                        g_PlayerCarryingSpecialBox[playerid] = false; 
                        g_PlayerBoxOwner[playerid] = 0;
                        g_PlayerBoxName[playerid][0] = 0;
                        g_PlayerBoxAmount[playerid] = 0;
                        break;
                    }
                }
                return 1;
            }
            boxid = GetNearestCompanyBox(playerid);
            
            if(boxid != -1 && CompanyBoxes[boxid][boxModel] == 3800)
            {
                if(AdminOpenedBox[boxid])
                {
                    if(g_PlayerCarryingBox[playerid] && !g_PlayerCarryingSpecialBox[playerid])
                    {
                        SendClientMessage(playerid, COLOR_RED, "Ban dang cam thung hang nho! Hay dat thung hang xuong truoc khi lay tu thung hang lon!");
                        return 1;
                    }
                    
                    if(g_PlayerCarryingBox[playerid])
                    {
                        SendClientMessage(playerid, -1, "Ban da dang cam thung hang roi!");
                        return 1;
                    }
                    
                    if(PlayerInfo[playerid][pAdmin] >= 4)
                    {
                        SendClientMessage(playerid, -1, "Admin: Ban da mo thung hang nay roi! Chi player moi co the lay hang, admin khong the cam thung nua!");
                        return 1;
                    }
                    if(CompanyBoxes[boxid][boxAmount] <= 0)
                    {
                        SendClientMessage(playerid, -1, "Thung hang nay da het hang!");
                        return 1;
                    }

                    g_PlayerCarryingBox[playerid] = true;
                    g_PlayerCarryingSpecialBox[playerid] = false; 
                    g_PlayerBoxOwner[playerid] = playerid;
                    format(g_PlayerBoxName[playerid], 32, "%s", CompanyBoxes[boxid][boxName]);
                    g_PlayerBoxAmount[playerid] = 1;
                    SetPlayerAttachedObject(playerid, 0, 2969, 6, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0);
                    ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, false, false, false, false, 0);

                    CompanyBoxes[boxid][boxAmount]--;

                    if(CompanyBoxes[boxid][boxAmount] <= 0)
                    {
                        SendClientMessage(playerid, -1, "Ban vua lay phan hang cuoi cung trong thung nay!");
                        DestroyDynamicObject(CompanyBoxes[boxid][boxObjID]);
                        if(CompanyBoxes[boxid][boxLabelID] != Text3D:0)
                        {
                            DestroyDynamic3DTextLabel(CompanyBoxes[boxid][boxLabelID]);
                        }
                        CompanyBoxes[boxid][boxObjID] = 0;
                        CompanyBoxes[boxid][boxName][0] = '\0';
                        CompanyBoxes[boxid][boxAmount] = 0;
                        CompanyBoxes[boxid][boxOwner] = 0;
                        CompanyBoxes[boxid][boxModel] = 0;
                        CompanyBoxes[boxid][boxTargetName][0] = '\0';
                        CompanyBoxes[boxid][boxLabelID] = Text3D:0;
                        AdminOpenedBox[boxid] = false;
                    }
                    else
                    {
                        new msg[64];
                        format(msg, sizeof(msg), "Con %d hang trong thung nay.", CompanyBoxes[boxid][boxAmount]);
                        SendClientMessage(playerid, -1, msg);
                        
                        if(CompanyBoxes[boxid][boxLabelID] != Text3D:0)
                        {
                            DestroyDynamic3DTextLabel(CompanyBoxes[boxid][boxLabelID]);
                        }
                        new Float:bx, Float:by, Float:bz;
                        GetDynamicObjectPos(CompanyBoxes[boxid][boxObjID], bx, by, bz);
                        new label[128];
                        format(label, sizeof(label), "{00FF00}%s\n{FFFFFF}So luong: %d\n{00FF00}[OPEN]", 
                            CompanyBoxes[boxid][boxName], CompanyBoxes[boxid][boxAmount]);
                        CompanyBoxes[boxid][boxLabelID] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, bx, by, bz+1.0, 20.0);
                    }
                    return 1;
                } 
                else
                {
                    if(PlayerInfo[playerid][pAdmin] < 4)
                    {
                        SendClientMessage(playerid, -1, "Thung hang nay chua duoc mo boi admin! Vui long doi admin su dung /mohang!");
                        return 1;
                    }
                    
                    if(g_PlayerCarryingBox[playerid])
                    {
                        SendClientMessage(playerid, COLOR_RED, "Ban dang cam thung hang roi! Hay dat thung hang xuong truoc khi cam thung khac!");
                        return 1;
                    }
                    
                    g_PlayerCarryingBox[playerid] = true;
                    g_PlayerCarryingSpecialBox[playerid] = true; 
                    g_PlayerBoxOwner[playerid] = playerid;
                    format(g_PlayerBoxName[playerid], 32, "%s", CompanyBoxes[boxid][boxName]);
                    g_PlayerBoxAmount[playerid] = CompanyBoxes[boxid][boxAmount]; 
                    format(g_BoxInputTargetName[playerid], MAX_PLAYER_NAME, "%s", CompanyBoxes[boxid][boxTargetName]);
                    SetPlayerAttachedObject(playerid, 0, SPECIAL_BOX_OBJECT, 6, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0);
                    ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, false, false, false, false, 0);
                    
                    DestroyDynamicObject(CompanyBoxes[boxid][boxObjID]);
                    if(CompanyBoxes[boxid][boxLabelID] != Text3D:0)
                    {
                        DestroyDynamic3DTextLabel(CompanyBoxes[boxid][boxLabelID]);
                    }
                    CompanyBoxes[boxid][boxObjID] = 0;
                    CompanyBoxes[boxid][boxName][0] = '\0';
                    CompanyBoxes[boxid][boxAmount] = 0;
                    CompanyBoxes[boxid][boxOwner] = 0;
                    CompanyBoxes[boxid][boxModel] = 0;
                    CompanyBoxes[boxid][boxTargetName][0] = '\0';
                    CompanyBoxes[boxid][boxLabelID] = Text3D:0;
                    AdminOpenedBox[boxid] = false;
                    return 1;
            } 
        } 
            if(boxid != -1 && CompanyBoxes[boxid][boxModel] == 2969)
        {
            if(g_PlayerCarryingBox[playerid])
            {
                SendClientMessage(playerid, COLOR_RED, "Ban dang cam thung hang roi! Hay dat thung hang xuong truoc khi cam thung khac!");
                return 1;
            }
            
            g_PlayerCarryingBox[playerid] = true;
            g_PlayerBoxOwner[playerid] = playerid;
            format(g_PlayerBoxName[playerid], 32, "%s", CompanyBoxes[boxid][boxName]);
            g_PlayerBoxAmount[playerid] = CompanyBoxes[boxid][boxAmount];
            
            // Always use object 2969 for player boxes
            SetPlayerAttachedObject(playerid, 0, 2969, 6, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0);
            ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, false, false, false, false, 0);

            DestroyDynamicObject(CompanyBoxes[boxid][boxObjID]);
            CompanyBoxes[boxid][boxObjID] = 0;
            CompanyBoxes[boxid][boxName][0] = '\0';
            CompanyBoxes[boxid][boxAmount] = 0;
            CompanyBoxes[boxid][boxOwner] = 0;
            CompanyBoxes[boxid][boxModel] = 0;
            CompanyBoxes[boxid][boxTargetName][0] = '\0';
            CompanyBoxes[boxid][boxLabelID] = Text3D:0;

            SendClientMessage(playerid, -1, "Ban da nhat thung hang len tay!");
            return 1;
        }
    } 
    return 1;
}

CMD:truckercompany(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 4 && !IsPlayerTruckerDirector(playerid))
        return SendClientMessage(playerid, -1, "Ban khong co quyen su dung chuc nang nay!");

    new str[256];
    str[0] = 0;

    strcat(str, "Moi thanh vien\n");
    strcat(str, "Kick thanh vien\n");
    strcat(str, "Danh sach thanh vien\n");
    if(PlayerInfo[playerid][pAdmin] >= 4)
    {
        strcat(str, "Cap giam doc\n");
        strcat(str, "Lay hang\n");
        strcat(str, "Cap chung chi xe\n");
        strcat(str, "Xoa chung chi xe\n");
    }

    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_MAIN, DIALOG_STYLE_LIST, "Trucker Company", str, "Chon", "Thoat");
    return 1;
}

CMD:mohang(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 4)
        return SendClientMessage(playerid, -1, "Ban khong co quyen su dung lenh nay!");
    
    new boxid = GetNearestCompanyBox(playerid);
    if(boxid == -1)
        return SendClientMessage(playerid, -1, "Ban khong dung gan thung hang nao!");
    
    if(CompanyBoxes[boxid][boxModel] != 3800)
        return SendClientMessage(playerid, -1, "Chi co the mo thung hang loai to!");
    
    if(AdminOpenedBox[boxid])
        return SendClientMessage(playerid, -1, "Thung hang nay da duoc mo roi!");
    
    if(CompanyBoxes[boxid][boxObjID] == 0)
        return SendClientMessage(playerid, -1, "Khong the mo thung hang - thung hang khong ton tai tren dat!");
    
    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, false, false, false, false, 0);
    
    AdminOpenedBox[boxid] = true;
    SendClientMessage(playerid, COLOR_LIGHTGREEN, "Ban da mo thung hang! Nguoi choi co the lay hang tu thung nay.");
    
    if(CompanyBoxes[boxid][boxLabelID] != Text3D:0)
    {
        DestroyDynamic3DTextLabel(CompanyBoxes[boxid][boxLabelID]);
    }
    new Float:bx, Float:by, Float:bz;
    GetDynamicObjectPos(CompanyBoxes[boxid][boxObjID], bx, by, bz);
    new label[128];
    format(label, sizeof(label), "{00FF00}%s\n{FFFFFF}So luong: %d\n{00FF00}[OPEN]", 
           CompanyBoxes[boxid][boxName], CompanyBoxes[boxid][boxAmount]);
    CompanyBoxes[boxid][boxLabelID] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, bx, by, bz+1.0, 20.0);
    
    new Float:x, Float:y, Float:z;
    GetDynamicObjectPos(CompanyBoxes[boxid][boxObjID], x, y, z);
    new string[128];
    format(string, sizeof(string), "Admin %s da mo thung hang %s! Ban co the den lay hang.", GetPlayerNameEx(playerid), CompanyBoxes[boxid][boxName]);
    
    foreach(new i : Player)
    {
        new Float:px, Float:py, Float:pz;
        GetPlayerPos(i, px, py, pz);
        if(GetDistanceBetweenCoords(x, y, z, px, py, pz) < 50.0)
        {
            SendClientMessage(i, COLOR_YELLOW, string);
        }
    }
    
    return 1;
}




hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_TRUCKER_COMPANY_MAIN && response)
    {
        if(PlayerInfo[playerid][pAdmin] >= 4)
        {
            switch(listitem)
            {
                case 0:
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_INVITE, DIALOG_STYLE_INPUT, "Moi Thanh Vien", "Nhap PlayerID can moi:", "Moi", "Huy");
                    return 1;
                }
                case 1:
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_KICK, DIALOG_STYLE_INPUT, "Kick Thanh Vien", "Nhap PlayerID can kick:", "Kick", "Huy");
                    return 1;
                }
                case 2:
                {
                    ShowTruckerCompanyMemberList(playerid);
                    return 1;
                }
                case 3:
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_SET_DIRECTOR, DIALOG_STYLE_INPUT, "Cap Giam Doc", "Nhap PlayerID can cap:", "Cap", "Huy");
                    return 1;
                }
                case 4:
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_BOX_STEP1, DIALOG_STYLE_INPUT, "Nhap ten nguoi nhan", "Nhap ten nguoi nhan hang:", "Tiep", "Huy");
                    return 1;
                }
                case 5: 
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_CERT_ADD, DIALOG_STYLE_INPUT, "Cap Chung Chi Xe", "Nhap ID xe can cap chung chi:", "Cap", "Huy");
                    return 1;
                }
                case 6:
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_CERT_DEL, DIALOG_STYLE_INPUT, "Xoa Chung Chi Xe", "Nhap ID xe can xoa chung chi:", "Xoa", "Huy");
                    return 1;
                }
            }
        }
        else
        {
            switch(listitem)
            {
                case 0:
                {
                    if(!IsPlayerTruckerDirector(playerid))
                        return SendClientMessage(playerid, -1, "Chi giam doc moi duoc moi thanh vien!");
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_INVITE, DIALOG_STYLE_INPUT, "Moi Thanh Vien", "Nhap PlayerID can moi:", "Moi", "Huy");
                    return 1;
                }
                case 1:
                {
                    if(!IsPlayerTruckerDirector(playerid))
                        return SendClientMessage(playerid, -1, "Chi giam doc moi duoc kick thanh vien!");
                    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_KICK, DIALOG_STYLE_INPUT, "Kick Thanh Vien", "Nhap PlayerID can kick:", "Kick", "Huy");
                    return 1;
                }
                case 2:
                {
                    ShowTruckerCompanyMemberList(playerid);
                    return 1;
                }
            }
        }
        return 1;
    }

    if(dialogid == DIALOG_TRUCKER_COMPANY_SET_DIRECTOR && response)
    {
        if(PlayerInfo[playerid][pAdmin] < 4)
            return SendClientMessage(playerid, -1, "Chi admin moi duoc chi dinh giam doc!");

        new directorid = strval(inputtext);
        if(directorid == INVALID_PLAYER_ID || !IsPlayerConnected(directorid))
            return SendClientMessage(playerid, -1, "PlayerID khong hop le!");

        new bool:isMember = false;
        for(new i = 0; i < TruckerCompany[TRUCKER_COMPANY_ID][tcMemberCount]; i++)
        {
            if(TruckerCompany[TRUCKER_COMPANY_ID][tcMemberIDs][i] == directorid)
            {
                isMember = true;
                break;
            }
        }
        if(!isMember)
            return SendClientMessage(playerid, -1, "Nguoi nay chua tham gia cong ty Trucker Delivery!");

        TruckerCompany[TRUCKER_COMPANY_ID][tcDirectorID] = directorid;
        SendClientMessage(directorid, -1, "Ban da duoc chi dinh lam giam doc Trucker Delivery!");
        SendClientMessage(playerid, -1, "Da chi dinh giam doc thanh cong!");
        SaveTruckerCompany();
        SaveTruckerCompanyMembers();
        return 1;
    }

    if(dialogid == DIALOG_TRUCKER_COMPANY_INVITE && response)
    {
        if(PlayerInfo[playerid][pAdmin] < 4 && !IsPlayerTruckerDirector(playerid))
            return SendClientMessage(playerid, -1, "Chi giam doc moi duoc moi thanh vien!");

        if(inputtext[0] == '\0')
            return ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_INVITE, DIALOG_STYLE_INPUT, "Moi Thanh Vien", "Nhap PlayerID can moi:", "Moi", "Huy");

        new inviteid = strval(inputtext);
        if(inviteid == INVALID_PLAYER_ID || !IsPlayerConnected(inviteid))
            return SendClientMessage(playerid, -1, "PlayerID khong hop le!");

        if(TruckerCompany[TRUCKER_COMPANY_ID][tcMemberCount] >= MAX_TRUCKER_COMPANY_MEMBERS)
            return SendClientMessage(playerid, -1, "Cong ty da day thanh vien!");

        new directorName[MAX_PLAYER_NAME];
        GetPlayerName(playerid, directorName, sizeof(directorName));
        new msg[128];
        format(msg, sizeof(msg), "Giam doc %s da moi ban vao Cong Ty Trucker Delivery!\nBan co muon tham gia khong?", directorName);
        ShowPlayerDialog(inviteid, DIALOG_TRUCKER_COMPANY_INVITE_CONFIRM, DIALOG_STYLE_MSGBOX, "Loi Moi Vao Cong Ty", msg, "Dong y", "Tu choi");

        SendClientMessage(playerid, -1, "Da gui loi moi den nguoi choi!");
        return 1;
    }

    if(dialogid == DIALOG_TRUCKER_COMPANY_KICK && response)
    {
        if(PlayerInfo[playerid][pAdmin] < 4 && !IsPlayerTruckerDirector(playerid))
            return SendClientMessage(playerid, -1, "Chi giam doc moi duoc kick thanh vien!");

        if(inputtext[0] == '\0')
            return ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_KICK, DIALOG_STYLE_INPUT, "Kick Thanh Vien", "Nhap PlayerID can kick:", "Kick", "Huy");

        new kickid = strval(inputtext);
        if(kickid == INVALID_PLAYER_ID || !IsPlayerConnected(kickid))
            return SendClientMessage(playerid, -1, "PlayerID khong hop le!");

        new cid = GetPlayerTruckerCompany(playerid);
        if(cid == -1)
            return SendClientMessage(playerid, -1, "Ban khong thuoc cong ty trucker nao!");

        if(kickid == playerid)
            return SendClientMessage(playerid, -1, "Khong the tu kick chinh minh!");

        for(new i = 0; i < TruckerCompany[0][tcMemberCount]; i++)
        {
            if(TruckerCompany[0][tcMemberIDs][i] == kickid)
            {
                for(new j = i; j < TruckerCompany[0][tcMemberCount] - 1; j++)
                {
                    TruckerCompany[0][tcMemberIDs][j] = TruckerCompany[0][tcMemberIDs][j+1];
                    format(tcMemberName[j], sizeof(tcMemberName[]), "%s", tcMemberName[j+1]);
                    format(tcMemberJoinDate[j], sizeof(tcMemberJoinDate[]), "%s", tcMemberJoinDate[j+1]);
                    tcMemberMysqlID[j] = tcMemberMysqlID[j+1];
                }
                TruckerCompany[0][tcMemberCount]--;
                SendClientMessage(kickid, -1, "Ban da bi kick khoi cong ty trucker!");
                SendClientMessage(playerid, -1, "Da kick thanh vien thanh cong!");
                SaveTruckerCompanyMembers();
                return 1;
            }
        }
        SendClientMessage(playerid, -1, "Nguoi nay khong phai thanh vien cong ty!");
        return 1;
    }
    if(dialogid == DIALOG_TRUCKER_COMPANY_INVITE_CONFIRM && response)
    {
        if(TruckerCompany[0][tcMemberCount] < MAX_TRUCKER_COMPANY_MEMBERS)
        {
            new idx = TruckerCompany[0][tcMemberCount];
            TruckerCompany[0][tcMemberIDs][idx] = playerid;
            format(tcMemberName[idx], MAX_PLAYER_NAME, "%s", GetPlayerNameEx(playerid));
            new year, month, day;
            getdate(year, month, day);
            format(tcMemberJoinDate[idx], 20, "%04d-%02d-%02d", year, month, day);
            tcMemberMysqlID[idx] = 0; 
            TruckerCompany[0][tcMemberCount]++;
            SaveTruckerCompanyMembers();
        }
        return 1;
    }
    else if(dialogid == DIALOG_TRUCKER_COMPANY_INVITE_CONFIRM && !response)
    {
        SendClientMessage(playerid, -1, "Ban da tu choi loi moi vao Cong Ty Trucker Delivery.");
        return 1;
    }
    if(dialogid == DIALOG_TRUCKER_COMPANY_BOX_STEP1 && response)
    {
        if(inputtext[0] == '\0') return SendClientMessage(playerid, -1, "Ban chua nhap ten nguoi nhan!");
        if(strlen(inputtext) < 3) return SendClientMessage(playerid, -1, "Ten nguoi nhan phai co it nhat 3 ky tu!");
        if(strlen(inputtext) > MAX_PLAYER_NAME-1) return SendClientMessage(playerid, -1, "Ten nguoi nhan qua dai!");
        format(g_BoxInputTargetName[playerid], MAX_PLAYER_NAME, "%s", inputtext);
        ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_BOX_TYPE, DIALOG_STYLE_LIST, "Chon loai hang", "Nguyen Lieu\nVat pham\nDung cu", "Tiep", "Huy");
        return 1;
    }
    if(dialogid == DIALOG_TRUCKER_COMPANY_BOX_TYPE && response)
    {
        g_BoxInputName[playerid][0] = 0;
        format(g_BoxInputName[playerid], 32, "%s", BoxTypeNames[listitem + 1]); 
        g_PlayerBoxOwner[playerid] = listitem + 1; 
        ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_BOX_STEP3, DIALOG_STYLE_INPUT, "Nhap so luong", "Nhap so luong:", "Tiep", "Huy");
        return 1;
    }
    if(dialogid == DIALOG_TRUCKER_COMPANY_BOX_STEP3 && response)
    {
        if(inputtext[0] == '\0') return SendClientMessage(playerid, -1, "Ban chua nhap so luong!");
        new amount = strval(inputtext);
        if(amount <= 0) return SendClientMessage(playerid, -1, "So luong phai lon hon 0!");

        new loaihang = g_PlayerBoxOwner[playerid]; // 1,2,3
        new tenhang[32];
        format(tenhang, sizeof(tenhang), "%s", BoxTypeNames[loaihang]);

        // Calculate optimized ground placement position
        new Float:ox, Float:oy, Float:oz;
        CalculateGroundPlacement(playerid, ox, oy, oz);

        for(new i = 0; i < MAX_COMPANY_BOXES; i++)
        {
            if(CompanyBoxes[i][boxObjID] == 0)
            {
                CompanyBoxes[i][boxObjID] = CreateDynamicObject(3800, ox, oy, oz, 0.0, 0.0, 0.0);
                CompanyBoxes[i][boxModel] = 3800;
                CompanyBoxes[i][boxOwner] = playerid;
                CompanyBoxes[i][boxAmount] = amount;
                format(CompanyBoxes[i][boxTargetName], MAX_PLAYER_NAME, "%s", g_BoxInputTargetName[playerid]);
                format(CompanyBoxes[i][boxName], 32, "%s", tenhang);

                new label[128];
                new targetName[MAX_PLAYER_NAME];
                if(strlen(CompanyBoxes[i][boxTargetName]) > 0)
                {
                    format(targetName, sizeof(targetName), "%s", CompanyBoxes[i][boxTargetName]);
                }
                else
                {
                    format(targetName, sizeof(targetName), "Khong co");
                }
                format(label, sizeof(label), "{FFFF00}%s\n{FFFFFF}So luong: %d\n{FFFFFF}Nguoi nhan: %s\n{FF0000}[CLOSED]", tenhang, amount, targetName);
                CompanyBoxes[i][boxLabelID] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, ox, oy, oz+1.0, 20.0);

                new str[1280];
                format(str,sizeof(str),"Ban da dat hang %s (%d) cho cong ty trucker delivery.", tenhang, amount);
                SendClientMessage(playerid, COLOR_LIGHTRED, str);
                break;
            }
        }
        return 1;
    }
    if(dialogid == DIALOG_TRUCKER_CERT_ADD && response)
    {
        if(inputtext[0] == '\0') return SendClientMessage(playerid, -1, "Ban chua nhap ID xe!");
        new vehicleid = strval(inputtext);
        if(vehicleid < 1 || vehicleid > MAX_VEHICLES) return SendClientMessage(playerid, -1, "ID xe khong hop le!");

        for(new i = 0; i < TruckerVehicleCount; i++)
            if(TruckerVehicleIDs[i] == vehicleid)
                return SendClientMessage(playerid, -1, "Xe nay da la xe trucker delivery!");

        if(TruckerVehicleCount >= MAX_TRUCKER_VEHICLES)
            return SendClientMessage(playerid, -1, "Da dat toi da so luong xe trucker delivery!");

        TruckerVehicleIDs[TruckerVehicleCount] = vehicleid;

        new vehName[32];
        format(vehName, sizeof(vehName), "%s", GetVehicleName(vehicleid));

        new year, month, day, hour, minute, second;
        getdate(year, month, day);
        gettime(hour, minute, second);
        format(TruckerVehicleGrantTime[TruckerVehicleCount], 32, "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second);

        TruckerVehicleCount++;

        new query[256];
        format(query, sizeof(query), "INSERT INTO trucker_cert_vehicles (vehicle_id, vehicle_name, grant_time) VALUES (%d, '%s', NOW()) ON DUPLICATE KEY UPDATE grant_time=NOW(), vehicle_name='%s'",
            vehicleid, vehName, vehName);
        mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SENDDATA_THREAD);

        new uid = -1;
        if(vehicleid >= 1 && vehicleid <= MAX_VEHICLES) uid = DynVeh[vehicleid];
        new string[128];
        format(string,sizeof(string),"[Admin Certificate] Ban da cap chung chi giao hang cho phuong tien %s (ID: %d) (UID: %d).", vehName, vehicleid, uid);
        SendClientMessage(playerid, COLOR_LIGHTRED, string);
        return 1;
    }
    if(dialogid == DIALOG_TRUCKER_CERT_DEL && response)
    {
        if(inputtext[0] == '\0') return SendClientMessage(playerid, -1, "Ban chua nhap ID xe!");
        new vehicleid = strval(inputtext);
        if(vehicleid < 1 || vehicleid > MAX_VEHICLES) return SendClientMessage(playerid, -1, "ID xe khong hop le!");

        new bool:found = false;
        for(new i = 0; i < TruckerVehicleCount; i++)
        {
            if(TruckerVehicleIDs[i] == vehicleid)
            {
                for(new j = i; j < TruckerVehicleCount-1; j++)
                    TruckerVehicleIDs[j] = TruckerVehicleIDs[j+1];
                TruckerVehicleCount--;
                found = true;
                break;
            }
        }
        if(!found) return SendClientMessage(playerid, -1, "Xe nay chua duoc cap chung chi!");

        new query[128];
        format(query, sizeof(query), "DELETE FROM trucker_cert_vehicles WHERE vehicle_id = %d", vehicleid);
        mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SENDDATA_THREAD);

        SendClientMessage(playerid, COLOR_LIGHTRED, "Da xoa chung chi xe trucker delivery thanh cong!");
        return 1;
    }
    if(dialogid == DIALOG_COMPANY_PUTBOX && response)
    {
        new vehicleid = GetPVarInt(playerid, "CompanyTruckerVehicleID");
        new idx = GetTruckerVehicleIndex(vehicleid);
        new slots = GetTruckBoxSlots(vehicleid);

        if(idx == -1 || vehicleid == INVALID_VEHICLE_ID || !g_PlayerCarryingBox[playerid] || listitem < 0 || listitem >= slots)
            return SendClientMessage(playerid, -1, "Co loi khi bo hang ");

        if(TruckerVehicleBoxType[idx][listitem] != 0)
            return SendClientMessage(playerid, -1, "Vi tri nay da co hang roi!");

        TruckerVehicleBoxType[idx][listitem] = 1;
        TruckerVehicleBoxAmount[idx][listitem] = g_PlayerBoxAmount[playerid];
        format(TruckerVehicleBoxName[idx][listitem], 32, "%s", g_PlayerBoxName[playerid]);

        // Animation for putting box into truck
        ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, false, false, false, false, 0);
        
        RemovePlayerAttachedObject(playerid, 0);
        g_PlayerCarryingBox[playerid] = false;
        g_PlayerBoxOwner[playerid] = 0;
        g_PlayerBoxName[playerid][0] = 0;
        g_PlayerBoxAmount[playerid] = 0;

        SendClientMessage(playerid, -1, "Ban da bo hang vao xe trucker (slot %d)!", listitem+1);
        DeletePVar(playerid, "CompanyTruckerVehicleID");
        return 1;
    }
    if(dialogid == DIALOG_COMPANY_GETBOX && response)
    {
        new vehicleid = GetPVarInt(playerid, "CompanyTruckerVehicleID");
        new idx = GetTruckerVehicleIndex(vehicleid);
        new slots = GetTruckBoxSlots(vehicleid);

        if(idx == -1 || vehicleid == INVALID_VEHICLE_ID || g_PlayerCarryingBox[playerid] || listitem < 0 || listitem >= slots)
            return SendClientMessage(playerid, -1, "Co loi khi lay hang tu xe!");

        if(TruckerVehicleBoxType[idx][listitem] == 0)
            return SendClientMessage(playerid, -1, "Vi tri nay khong co hang!");

        g_PlayerCarryingBox[playerid] = true;
        g_PlayerBoxOwner[playerid] = playerid;
        format(g_PlayerBoxName[playerid], 32, "%s", TruckerVehicleBoxName[idx][listitem]);
        g_PlayerBoxAmount[playerid] = TruckerVehicleBoxAmount[idx][listitem];
        SetPlayerAttachedObject(playerid, 0, 2969, 6, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0);
        ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, false, false, false, false, 0);

        TruckerVehicleBoxType[idx][listitem] = 0;
        TruckerVehicleBoxAmount[idx][listitem] = 0;
        TruckerVehicleBoxName[idx][listitem][0] = '\0';

        SendClientMessage(playerid, -1, "Ban da lay hang tu xe trucker (slot %d)!", listitem+1);
        DeletePVar(playerid, "CompanyTruckerVehicleID");
        return 1;
    }
    return 0;
}


stock PlayerHasBoxOnGround(playerid)
{
    for(new i = 0; i < MAX_COMPANY_BOXES; i++)
    {
        if(CompanyBoxes[i][boxObjID] != 0)
        {
            if(CompanyBoxes[i][boxModel] == 2969 && CompanyBoxes[i][boxOwner] == playerid)
            {
                return 1;
            }
        }
    }
    return 0;
}

stock IsPlayerTruckerDirector(playerid)
{
    return TruckerCompany[TRUCKER_COMPANY_ID][tcDirectorID] == playerid;
}

stock GetPlayerTruckerCompany(playerid)
{
    for(new i = 0; i < MAX_TRUCKER_COMPANIES; i++)
        for(new j = 0; j < TruckerCompany[i][tcMemberCount]; j++)
            if(TruckerCompany[i][tcMemberIDs][j] == playerid)
                return i;
    return -1;
}

stock ShowTruckerCompanyMemberList(playerid)
{
    new str[2048], tmp[128];
    strcat(str, "Ten (ID)\tThoi gian tham gia\tTrang thai\n");
    for(new i = 0; i < TruckerCompany[0][tcMemberCount]; i++)
    {
        new memberid = TruckerCompany[0][tcMemberIDs][i];
        new status[16];
        format(status, sizeof(status), IsPlayerConnected(memberid) ? "{00FF00}Online" : "{FF0000}Offline");
        format(tmp, sizeof(tmp), "%s (%d)\t%s\t%s\n", tcMemberName[i], memberid, tcMemberJoinDate[i], status);
        strcat(str, tmp);
    }
    if(TruckerCompany[0][tcMemberCount] == 0) strcat(str, "Khong co thanh vien nao.");
    ShowPlayerDialog(playerid, DIALOG_TRUCKER_COMPANY_MEMBERLIST, DIALOG_STYLE_TABLIST_HEADERS, "Danh Sach Thanh Vien", str, "Dong", "");
}

stock SaveTruckerCompany()
{
    new query[256];
    format(query, sizeof(query), "REPLACE INTO trucker_company (id, name, director_id, funds) VALUES (0, '%s', %d, %d)",
        g_mysql_ReturnEscaped(TruckerCompany[0][tcName], MainPipeline),
        TruckerCompany[0][tcDirectorID],
        TruckerCompany[0][tcFunds]
    );
    mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock SaveTruckerCompanyMembers()
{
    mysql_function_query(MainPipeline, "DELETE FROM trucker_company_members WHERE company_id = 0", false, "OnQueryFinish", "i", SENDDATA_THREAD);
    new query[256];
    for(new i = 0; i < TruckerCompany[0][tcMemberCount]; i++)
    {
        format(query, sizeof(query),
            "INSERT INTO trucker_company_members (company_id, player_id, player_name, join_date) VALUES (0, %d, '%s', '%s')",
            TruckerCompany[0][tcMemberIDs][i],
            g_mysql_ReturnEscaped(tcMemberName[i], MainPipeline),
            tcMemberJoinDate[i]
        );
        mysql_function_query(MainPipeline, query, false, "OnQueryFinish", "i", SENDDATA_THREAD);
    }
}

forward OnLoadTruckerCompany();
public OnLoadTruckerCompany()
{
    if(cache_num_rows())
    {
        cache_get_field_content(0, "name", TruckerCompany[0][tcName], MainPipeline, MAX_TRUCKER_COMPANY_NAME);
        TruckerCompany[0][tcDirectorID] = cache_get_field_content_int(0, "director_id", MainPipeline);
        TruckerCompany[0][tcFunds] = cache_get_field_content_int(0, "funds", MainPipeline);
    }
    else
    {
        format(TruckerCompany[0][tcName], MAX_TRUCKER_COMPANY_NAME, "Trucker Delivery");
        TruckerCompany[0][tcDirectorID] = INVALID_PLAYER_ID;
        TruckerCompany[0][tcFunds] = 0;
        TruckerCompany[0][tcMemberCount] = 0;
        SaveTruckerCompany();
    }
}
stock LoadTruckerCompany()
{
    mysql_function_query_internal(MainPipeline, "SELECT * FROM trucker_company WHERE id = 0", true, "OnLoadTruckerCompany", "");
}

forward OnLoadTruckerCompanyMembers();
public OnLoadTruckerCompanyMembers()
{
    TruckerCompany[0][tcMemberCount] = 0;
    new rows = cache_num_rows();
    for(new i = 0; i < rows; i++)
    {
        cache_get_field_content(i, "player_name", tcMemberName[i], MainPipeline, MAX_PLAYER_NAME);
        cache_get_field_content(i, "join_date", tcMemberJoinDate[i], MainPipeline, 20);
        TruckerCompany[0][tcMemberIDs][i] = cache_get_field_content_int(i, "player_id", MainPipeline);
        tcMemberMysqlID[i] = cache_get_field_content_int(i, "mysqlid", MainPipeline);
        TruckerCompany[0][tcMemberCount]++;
    }
}
stock LoadTruckerCompanyMembers()
{
    mysql_function_query_internal(MainPipeline, "SELECT * FROM trucker_company_members WHERE company_id = 0", true, "OnLoadTruckerCompanyMembers", "");
}


stock LoadTruckerCertifiedVehicles()
{
    mysql_function_query_internal(MainPipeline, "SELECT vehicle_id, vehicle_name, grant_time FROM trucker_cert_vehicles", true, "OnLoadTruckerCertifiedVehicles", "");
}
forward OnLoadTruckerCertifiedVehicles();
public OnLoadTruckerCertifiedVehicles()
{
    TruckerVehicleCount = 0;
    new rows = cache_num_rows();
    for(new i = 0; i < rows; i++)
    {
        TruckerVehicleIDs[TruckerVehicleCount] = cache_get_field_content_int(i, "vehicle_id", MainPipeline);
        cache_get_field_content(i, "vehicle_name", TruckerVehicleNames[TruckerVehicleCount], MainPipeline, 32);
        cache_get_field_content(i, "grant_time", TruckerVehicleGrantTime[TruckerVehicleCount], MainPipeline, 32);
        TruckerVehicleCount++;
    }
}

stock IsPlayerNearTruck(playerid, Float:range = 3.0)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i = 1; i <= MAX_VEHICLES; i++)
    {
        new model = GetVehicleModel(i);
        if((model == 414 || model == 456 || model == 449 || model == 591 || model == 435) && IsCertifiedTruckerVehicle(i))
        {
            new Float:vx, Float:vy, Float:vz;
            GetVehiclePos(i, vx, vy, vz);
            if(GetDistanceBetweenCoords(px, py, pz, vx, vy, vz) < range)
            {
                return 1; 
            }
        }
    }
    return 0;
}

stock IsCertifiedTruckerVehicle(vehicleid)
{
    for(new i = 0; i < TruckerVehicleCount; i++)
    {
        if(TruckerVehicleIDs[i] == vehicleid)
            return 1;
    }
    return 0;
}

stock GetTruckBoxSlots(vehicleid)
{
    new model = GetVehicleModel(vehicleid);
    switch(model)
    {
        case 456: return 100;
        case 449: return 50;
        case 591, 435: return 200;
        default: return 10;
    }
}



stock GetNearestTruckerVehicle(playerid, Float:range = 3.0)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i = 1; i <= MAX_VEHICLES; i++)
    {
        new model = GetVehicleModel(i);
        if((model == 414 || model == 456 || model == 449 || model == 591 || model == 435) && IsCertifiedTruckerVehicle(i))
        {
            new Float:vx, Float:vy, Float:vz;
            GetVehiclePos(i, vx, vy, vz);
            if(GetDistanceBetweenCoords(px, py, pz, vx, vy, vz) < range)
            {
                return i;
            }
        }
    }
    return INVALID_VEHICLE_ID;
}

stock GetTruckerVehicleIndex(vehicleid)
{
    for(new i = 0; i < TruckerVehicleCount; i++)
        if(TruckerVehicleIDs[i] == vehicleid)
            return i;
    return -1;
}

stock GetNearestCompanyBox(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i = 0; i < MAX_COMPANY_BOXES; i++)
    {
        if(CompanyBoxes[i][boxObjID] != 0)
        {
            new Float:bx, Float:by, Float:bz;
            GetDynamicObjectPos(CompanyBoxes[i][boxObjID], bx, by, bz);
            if(GetDistanceBetweenCoords(px, py, pz, bx, by, bz) < PICKUP_BOX_DISTANCE)
                return i;
        }
    }
    return -1;
}

// Simple and reliable ground placement like balo.pwn
stock bool:CalculateGroundPlacement(playerid, &Float:ox, &Float:oy, &Float:oz)
{
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);

    new Float:distance = 1.5; // Closer to player
    ox = x + (distance * floatsin(-angle, degrees));
    oy = y + (distance * floatcos(-angle, degrees));
    oz = z - 1.0; // Lower ground placement for better positioning
    
    return true; // Always successful with this simple method
}

stock IsPlayerNearVehicle554(playerid, Float:range = 3.0)
{
    return 1; 
}

stock GetNearestVehicle554(playerid, Float:range = 3.0)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    
    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(554, vx, vy, vz);
    if(GetDistanceBetweenCoords(px, py, pz, vx, vy, vz) < range)
    {
        return 554; 
    }
    return INVALID_VEHICLE_ID;
}

stock IsPlayerNearSpecificVehicle(playerid, vehicleid, Float:range = 3.0)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    
    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(vehicleid, vx, vy, vz);
    
    new Float:distance = GetDistanceBetweenCoords(px, py, pz, vx, vy, vz);
    return (distance <= range);
}

stock PutBoxOnVehicle554(playerid, vehicleid)
{
    if(Vehicle554HasBox[vehicleid])
    {
        SendClientMessage(playerid, -1, "Xe nay da co thung hang roi!");
        return 0;
    }
    
    Vehicle554BoxObject[vehicleid] = CreateDynamicObject(3800, 0.0, 0.0, -1000.0, 0.0, 0.0, 0.0, -1, -1, -1, 300.0, 300.0);
    AttachDynamicObjectToVehicle(Vehicle554BoxObject[vehicleid], vehicleid, 0.000, -2.158, -0.420, 0.000, 0.000, 0.000);

    Vehicle554HasBox[vehicleid] = true;
    Vehicle554BoxType[vehicleid] = 1; 
    Vehicle554BoxAmount[vehicleid] = g_PlayerBoxAmount[playerid];
    format(Vehicle554BoxName[vehicleid], 32, "%s", g_PlayerBoxName[playerid]);
    
    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, false, false, false, false, 0);
    
    RemovePlayerAttachedObject(playerid, 0);
    g_PlayerCarryingBox[playerid] = false;
    g_PlayerCarryingSpecialBox[playerid] = false;
    g_PlayerBoxOwner[playerid] = 0;
    g_PlayerBoxName[playerid][0] = 0;
    g_PlayerBoxAmount[playerid] = 0;
    return 1;
}

stock TakeBoxFromVehicle554(playerid, vehicleid)
{
    if(!Vehicle554HasBox[vehicleid])
    {
        SendClientMessage(playerid, -1, "Xe nay khong co thung hang!");
        return 0;
    }
    
    g_PlayerCarryingBox[playerid] = true;
    g_PlayerCarryingSpecialBox[playerid] = true; 
    g_PlayerBoxOwner[playerid] = playerid;
    format(g_PlayerBoxName[playerid], 32, "%s", Vehicle554BoxName[vehicleid]);
    g_PlayerBoxAmount[playerid] = Vehicle554BoxAmount[vehicleid];
    SetPlayerAttachedObject(playerid, 0, SPECIAL_BOX_OBJECT, 6, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0);
    ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, false, false, false, false, 0);
    
    DestroyDynamicObject(Vehicle554BoxObject[vehicleid]);
    Vehicle554BoxObject[vehicleid] = 0;
    Vehicle554HasBox[vehicleid] = false;
    Vehicle554BoxType[vehicleid] = 0;
    Vehicle554BoxAmount[vehicleid] = 0;
    Vehicle554BoxName[vehicleid][0] = '\0';
    
    if(PlayerInfo[playerid][pAdmin] >= 4)
    {
        SendClientMessage(playerid, COLOR_LIGHTGREEN, "Admin: Ban da lay thung hang tu xe 554! Co the dat xuong dat va dung /mohang de cho player lay.");
    }
    else
    {
        SendClientMessage(playerid, COLOR_LIGHTGREEN, "Ban da lay thung hang tu xe 554!");
    }
    return 1;
}

