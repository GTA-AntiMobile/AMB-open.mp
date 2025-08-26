#include <YSI\YSI_Coding\y_hooks>

#define MAX_SLOTCAY 100
#define MAX_PLANTS_PER_PLAYER 5
#define PLANT_GROW_TIME (3 * 60 * 60)
#define PLANT_WATER_INTERVAL (5 * 60)
#define PLANT_MIN_DISTANCE 3.0
#define PLANT_FERTILIZER_BOOST 0.5
#define DIALOG_TRONGCAY         9001
#define DIALOG_CAY_INFO         9002
#define DIALOG_THUHOACH         9003
#define DIALOG_SEEDS_INFO       9004
#define DIALOG_MY_PLANTS        9005
#define DIALOG_PLANT_ADMIN_INFO 9006

#if !defined COLOR_RED
    #define COLOR_RED       0xFF0000FF
#endif
#if !defined COLOR_GREEN
    #define COLOR_GREEN     0x00FF00FF
#endif
#if !defined COLOR_ORANGE
    #define COLOR_ORANGE    0xFF9900FF
#endif
#if !defined COLOR_WHITE
    #define COLOR_WHITE     0xFFFFFFFF
#endif
enum ePlantType
{
    PLANT_TYPE_NONE,
    PLANT_TYPE_MARIJUANA,
    PLANT_TYPE_CORN,
    PLANT_TYPE_TOMATO,
    PLANT_TYPE_POTATO,
    PLANT_TYPE_TREE
};

new PlantTypeNames[][] = {
    "Khong xac dinh",
    "Can sa",
    "Ngo", 
    "Ca chua",
    "Khoai tay",
    "Cay an qua"
};

new PlantTypeObjects[] = {
    19473,
    19473,
    19308,
    19376,
    19377,
    615
};

enum ePlantData
{
    plantExists,
    plantOwner,
    plantOwnerName[MAX_PLAYER_NAME], 
    Float:plantX,
    Float:plantY,
    Float:plantZ,
    plantObject,
    Text3D:plantLabel,
    plantStartTime,
    plantLastWater,
    plantWaterCount,
    plantNeedWater,
    plantType,
    plantHealth,
    plantFertilized,
    plantYield,
    plantSoilQuality
};

new PlantData[MAX_SLOTCAY][ePlantData];

enum ePlayerPlantInventory
{
    playerSeeds[6],
    playerFertilizer,
    playerWateringCan,
    playerHarvested[6]
};

new PlayerPlantInv[MAX_PLAYERS][ePlayerPlantInventory];

stock GetSoilQuality(Float:x, Float:y, Float:z)
{
    #pragma unused x, y
    
    if(z > 50.0) return 2;
    if(z < 5.0) return 5;
    
    return random(3) + 2;
}
stock GetPlayerPlantCount(playerid)
{
    new count = 0;
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    
    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(PlantData[i][plantExists] && strcmp(PlantData[i][plantOwnerName], name, true) == 0)
            count++;
    }
    return count;
}

stock FindEmptyPlantSlot()
{
    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(!PlantData[i][plantExists]) return i;
    }
    return -1;
}

stock IsValidPlantPosition(Float:x, Float:y, Float:z)
{
    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(PlantData[i][plantExists])
        {
            if(GetDistanceBetweenCoords(PlantData[i][plantX], PlantData[i][plantY], PlantData[i][plantZ], x, y, z) < PLANT_MIN_DISTANCE)
                return 0;
        }
    }
    return 1;
}

stock GiveSeedAndSetPlantCP(playerid, planttype = PLANT_TYPE_MARIJUANA)
{
    if(PlayerPlantInv[playerid][playerSeeds][planttype] <= 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban khong co hat giong loai nay!");
        return 0;
    }
    
    if(GetPlayerPlantCount(playerid) >= MAX_PLANTS_PER_PLAYER)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban da trong toi da so cay cho phep!");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    SetPVarInt(playerid, "PlantCP", 1);
    SetPVarFloat(playerid, "PlantCP_X", x);
    SetPVarFloat(playerid, "PlantCP_Y", y);
    SetPVarFloat(playerid, "PlantCP_Z", z);
    SetPVarInt(playerid, "PlantType", planttype);

    SetPlayerCheckpoint(playerid, x, y, z, 2.0);
    new string[128];
    format(string, sizeof(string), "Ban da nhan hat giong %s, den diem checkpoint de trong cay (an Y).", PlantTypeNames[planttype]);
    SendClientMessage(playerid, COLOR_GREEN, string);
    return 1;
}


CMD:seeds(playerid, params[])
{
    new string[256];
    format(string, sizeof(string), 
        "{00FF00}=== HAT GIONG CUA BAN ===\n\n\
        {FFFFFF}Can sa: {FFFF00}%d hat\n\
        {FFFFFF}Ngo: {FFFF00}%d hat\n\
        {FFFFFF}Ca chua: {FFFF00}%d hat\n\
        {FFFFFF}Khoai tay: {FFFF00}%d hat\n\
        {FFFFFF}Cay an qua: {FFFF00}%d hat\n\n\
        {FFFFFF}Phan bon: {00BFFF}%d goi\n\
        {FFFFFF}Binh tuoi: {00BFFF}%s",
        PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_MARIJUANA],
        PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_CORN],
        PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_TOMATO],
        PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_POTATO],
        PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_TREE],
        PlayerPlantInv[playerid][playerFertilizer],
        PlayerPlantInv[playerid][playerWateringCan] ? "Co" : "Khong"
    );
    ShowPlayerDialog(playerid, DIALOG_SEEDS_INFO, DIALOG_STYLE_MSGBOX, "Tui hat giong", string, "Dong", "");
    return 1;
}

CMD:plant(playerid, params[])
{
    if(isnull(params))
    {
        SendClientMessage(playerid, COLOR_WHITE, "Su dung: /plant [loai]");
        SendClientMessage(playerid, COLOR_WHITE, "Loai: marijuana, corn, tomato, potato, tree");
        return 1;
    }
    
    new planttype = PLANT_TYPE_NONE;
    if(!strcmp(params, "marijuana", true)) planttype = PLANT_TYPE_MARIJUANA;
    else if(!strcmp(params, "corn", true)) planttype = PLANT_TYPE_CORN;
    else if(!strcmp(params, "tomato", true)) planttype = PLANT_TYPE_TOMATO;
    else if(!strcmp(params, "potato", true)) planttype = PLANT_TYPE_POTATO;
    else if(!strcmp(params, "tree", true)) planttype = PLANT_TYPE_TREE;
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Loai cay khong hop le!");
        return 1;
    }
    
    GiveSeedAndSetPlantCP(playerid, planttype);
    return 1;
}

CMD:fertilize(playerid, params[])
{
    if(PlayerPlantInv[playerid][playerFertilizer] <= 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban khong co phan bon!");
        return 1;
    }
    
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(PlantData[i][plantExists] && strcmp(PlantData[i][plantOwnerName], name, true) == 0 
            && GetDistanceBetweenCoords(PlantData[i][plantX], PlantData[i][plantY], PlantData[i][plantZ], px, py, pz) < 2.0)
        {
            if(PlantData[i][plantFertilized])
            {
                SendClientMessage(playerid, COLOR_RED, "Cay nay da duoc bon phan!");
                return 1;
            }
            
            PlantData[i][plantFertilized] = 1;
            PlantData[i][plantHealth] += 20;
            if(PlantData[i][plantHealth] > 100) PlantData[i][plantHealth] = 100;
            
            PlayerPlantInv[playerid][playerFertilizer]--;
            UpdatePlantLabel(i);
            SendClientMessage(playerid, COLOR_GREEN, "Ban da bon phan cho cay thanh cong!");
            return 1;
        }
    }
    SendClientMessage(playerid, COLOR_RED, "Khong tim thay cay nao gan ban!");
    return 1;
}

CMD:myplants(playerid, params[])
{
    new count = GetPlayerPlantCount(playerid);
    if(count == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban chua trong cay nao!");
        return 1;
    }
    
    new string[1024], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(string, sizeof(string), "{00FF00}=== CAY CUA BAN (%d/%d) ===\n\n", count, MAX_PLANTS_PER_PLAYER);
    
    new plantCount = 0;
    for(new i = 0; i < MAX_SLOTCAY && plantCount < count; i++)
    {
        if(PlantData[i][plantExists] && strcmp(PlantData[i][plantOwnerName], name, true) == 0)
        {
            new left = PLANT_GROW_TIME - (gettime() - PlantData[i][plantStartTime]);
            if(PlantData[i][plantFertilized]) left = floatround(left * PLANT_FERTILIZER_BOOST);
            if(left < 0) left = 0;
            
            new tempStr[128];
            format(tempStr, sizeof(tempStr), 
                "{FFFFFF}%d. %s - Suc khoe: %d%% - Con lai: %d phut\n",
                ++plantCount,
                PlantTypeNames[PlantData[i][plantType]],
                PlantData[i][plantHealth],
                left/60
            );
            strcat(string, tempStr);
        }
    }
    
    ShowPlayerDialog(playerid, DIALOG_MY_PLANTS, DIALOG_STYLE_MSGBOX, "Danh sach cay", string, "Dong", "");
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if((newkeys & KEY_YES) && GetPVarInt(playerid, "PlantCP") == 1 && IsPlayerInRangeOfPoint(playerid, 2.0, GetPVarFloat(playerid, "PlantCP_X"), GetPVarFloat(playerid, "PlantCP_Y"), GetPVarFloat(playerid, "PlantCP_Z")))
    {
        new planttype = GetPVarInt(playerid, "PlantType");
        new string[128];
        format(string, sizeof(string), "Ban muon trong %s o khu vuc nay?", PlantTypeNames[planttype]);
        ShowPlayerDialog(playerid, DIALOG_TRONGCAY, DIALOG_STYLE_MSGBOX, "> Trong cay", string, "Co", "Khong");
        return 1;
    }
    
    if(newkeys & KEY_YES)
    {
        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));

        for(new i = 0; i < MAX_SLOTCAY; i++)
        {
            if(PlantData[i][plantExists] && GetDistanceBetweenCoords(PlantData[i][plantX], PlantData[i][plantY], PlantData[i][plantZ], px, py, pz) < 2.0)
            {
                new left = PLANT_GROW_TIME - (gettime() - PlantData[i][plantStartTime]);
                if(PlantData[i][plantFertilized]) left = floatround(left * PLANT_FERTILIZER_BOOST);
                if(left < 0) left = 0;
                
                new planter[MAX_PLAYER_NAME];
                GetPlayerName(PlantData[i][plantOwner], planter, sizeof(planter));
                
                new info[512];
                format(info, sizeof(info),
                    "{00FF00}=== THONG TIN CAY ===\n\n\
                    {FFFFFF}Loai cay: {FFFF00}%s\n\
                    {FFFFFF}Nguoi trong: {FFFF00}%s\n\
                    {FFFFFF}Suc khoe: {00BFFF}%d%%\n\
                    {FFFFFF}Chat luong dat: {00BFFF}%d/5\n\
                    {FFFFFF}So lan tuoi: {00BFFF}%d\n\
                    {FFFFFF}Thoi gian con lai: {FF9900}%d phut\n\
                    {FFFFFF}Phan bon: %s\n\
                    %s",
                    PlantTypeNames[PlantData[i][plantType]],
                    planter,
                    PlantData[i][plantHealth],
                    PlantData[i][plantSoilQuality],
                    PlantData[i][plantWaterCount],
                    left/60,
                    PlantData[i][plantFertilized] ? "{00FF00}Da bon" : "{FF0000}Chua bon",
                    PlantData[i][plantNeedWater] ? "{FF0000}Trang thai: CAN TUOI NUOC!" : "{00FF00}Trang thai: Dang phat trien"
                );

                new canHarvest = (gettime() - PlantData[i][plantStartTime] >= (PlantData[i][plantFertilized] ? floatround(PLANT_GROW_TIME * PLANT_FERTILIZER_BOOST) : PLANT_GROW_TIME));
                new isOwner = (strcmp(PlantData[i][plantOwnerName], name, true) == 0);

                if(isOwner)
                {
                    if(canHarvest)
                        ShowPlayerDialog(playerid, DIALOG_CAY_INFO, DIALOG_STYLE_MSGBOX, "THONG TIN CAY", info, "Tuoi cay", "Thu hoach");
                    else
                        ShowPlayerDialog(playerid, DIALOG_CAY_INFO, DIALOG_STYLE_MSGBOX, "THONG TIN CAY", info, "Tuoi cay", "Xoa cay");
                }
                else
                {
                    ShowPlayerDialog(playerid, DIALOG_CAY_INFO, DIALOG_STYLE_MSGBOX, "THONG TIN CAY", info, "Tuoi cay", "Dong");
                }
                SetPVarInt(playerid, "PlantInfoIdx", i);
                return 1;
            }
        }
    }
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_TRONGCAY:
        {
            if(response)
            {
                new Float:x = GetPVarFloat(playerid, "PlantCP_X");
                new Float:y = GetPVarFloat(playerid, "PlantCP_Y");
                new Float:z = GetPVarFloat(playerid, "PlantCP_Z");
                new planttype = GetPVarInt(playerid, "PlantType");

                if(PlayerPlantInv[playerid][playerSeeds][planttype] <= 0)
                {
                    SendClientMessage(playerid, COLOR_RED, "Ban khong co hat giong loai nay!");
                    DisablePlayerCheckpoint(playerid);
                    DeletePVar(playerid, "PlantCP");
                    DeletePVar(playerid, "PlantCP_X");
                    DeletePVar(playerid, "PlantCP_Y");
                    DeletePVar(playerid, "PlantCP_Z");
                    DeletePVar(playerid, "PlantType");
                    return 1;
                }

                if(!IsValidPlantPosition(x, y, z))
                {
                    SendClientMessage(playerid, COLOR_RED, "Da co nguoi trong gan vi tri nay, khong the trong them!");
                    DisablePlayerCheckpoint(playerid);
                    DeletePVar(playerid, "PlantCP");
                    DeletePVar(playerid, "PlantCP_X");
                    DeletePVar(playerid, "PlantCP_Y");
                    DeletePVar(playerid, "PlantCP_Z");
                    DeletePVar(playerid, "PlantType");
                    return 1;
                }

                new idx = FindEmptyPlantSlot();
                if(idx == -1) 
                {
                    SendClientMessage(playerid, COLOR_RED, "Da dat toi da so cay tren server!");
                    DisablePlayerCheckpoint(playerid);
                    DeletePVar(playerid, "PlantCP");
                    DeletePVar(playerid, "PlantCP_X");
                    DeletePVar(playerid, "PlantCP_Y");
                    DeletePVar(playerid, "PlantCP_Z");
                    DeletePVar(playerid, "PlantType");
                    return 1;
                }

                if(GetPlayerPlantCount(playerid) >= MAX_PLANTS_PER_PLAYER)
                {
                    SendClientMessage(playerid, COLOR_RED, "Ban da trong toi da so cay cho phep!");
                    DisablePlayerCheckpoint(playerid);
                    DeletePVar(playerid, "PlantCP");
                    DeletePVar(playerid, "PlantCP_X");
                    DeletePVar(playerid, "PlantCP_Y");
                    DeletePVar(playerid, "PlantCP_Z");
                    DeletePVar(playerid, "PlantType");
                    return 1;
                }

                PlayerPlantInv[playerid][playerSeeds][planttype]--;

                new name[MAX_PLAYER_NAME];
                GetPlayerName(playerid, name, sizeof(name));
                
                PlantData[idx][plantExists] = 1;
                PlantData[idx][plantOwner] = playerid;
                strcpy(PlantData[idx][plantOwnerName], name, MAX_PLAYER_NAME);
                PlantData[idx][plantX] = x;
                PlantData[idx][plantY] = y;
                PlantData[idx][plantZ] = z;
                PlantData[idx][plantType] = planttype;
                PlantData[idx][plantStartTime] = gettime();
                PlantData[idx][plantLastWater] = gettime();
                PlantData[idx][plantWaterCount] = 0;
                PlantData[idx][plantNeedWater] = 0;
                PlantData[idx][plantHealth] = 100;
                PlantData[idx][plantFertilized] = 0;
                PlantData[idx][plantSoilQuality] = GetSoilQuality(x, y, z);
                PlantData[idx][plantYield] = 0;
                
                PlantData[idx][plantObject] = CreateDynamicObject(PlantTypeObjects[planttype], x, y, z-1.0, 0.0, 0.0, 0.0);
                
                new label[128];
                format(label, sizeof(label), "{00FF00}%s\nDang phat trien - 3 tieng", PlantTypeNames[planttype]);
                PlantData[idx][plantLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, x, y, z, 10.0);

                DisablePlayerCheckpoint(playerid);
                DeletePVar(playerid, "PlantCP");
                DeletePVar(playerid, "PlantCP_X");
                DeletePVar(playerid, "PlantCP_Y");
                DeletePVar(playerid, "PlantCP_Z");
                DeletePVar(playerid, "PlantType");
                
                new string[128];
                format(string, sizeof(string), "Ban da trong %s thanh cong! (Slot: %d)", PlantTypeNames[planttype], idx);
                SendClientMessage(playerid, COLOR_GREEN, string);
            }
            else
            {
                DisablePlayerCheckpoint(playerid);
                DeletePVar(playerid, "PlantCP");
                DeletePVar(playerid, "PlantCP_X");
                DeletePVar(playerid, "PlantCP_Y");
                DeletePVar(playerid, "PlantCP_Z");
                DeletePVar(playerid, "PlantType");
                SendClientMessage(playerid, COLOR_ORANGE, "Ban da huy viec trong cay.");
            }
            return 1;
        }
        
        case DIALOG_CAY_INFO:
        {
            new idx = GetPVarInt(playerid, "PlantInfoIdx");
            if(idx < 0 || idx >= MAX_SLOTCAY || !PlantData[idx][plantExists]) return 1;

            if(response)
            {
                new growTime = PlantData[idx][plantFertilized] ? floatround(PLANT_GROW_TIME * PLANT_FERTILIZER_BOOST) : PLANT_GROW_TIME;
                
                if(gettime() - PlantData[idx][plantStartTime] < growTime)
                {
                    if(PlantData[idx][plantNeedWater] == 1)
                    {
                        if(!PlayerPlantInv[playerid][playerWateringCan])
                        {
                            SendClientMessage(playerid, COLOR_RED, "Ban can co binh tuoi nuoc!");
                            return 1;
                        }
                        
                        PlantData[idx][plantLastWater] = gettime();
                        PlantData[idx][plantWaterCount]++;
                        PlantData[idx][plantNeedWater] = 0;
                        PlantData[idx][plantHealth] += 10;
                        if(PlantData[idx][plantHealth] > 100) PlantData[idx][plantHealth] = 100;
                        
                        UpdatePlantLabel(idx);
                        SendClientMessage(playerid, COLOR_GREEN, "Ban da tuoi nuoc cho cay!");
                    }
                    else
                    {
                        SendClientMessage(playerid, COLOR_RED, "Chua den luc tuoi nuoc cho cay nay!");
                    }
                }
                return 1;
            }
            else
            {
                new name[MAX_PLAYER_NAME];
                GetPlayerName(playerid, name, sizeof(name));
                
                if(strcmp(PlantData[idx][plantOwnerName], name, true) == 0)
                {
                    new growTime = PlantData[idx][plantFertilized] ? floatround(PLANT_GROW_TIME * PLANT_FERTILIZER_BOOST) : PLANT_GROW_TIME;
                    
                    if(gettime() - PlantData[idx][plantStartTime] >= growTime)
                    {
                        new baseYield = 1;
                        new healthBonus = PlantData[idx][plantHealth] / 20;
                        new soilBonus = PlantData[idx][plantSoilQuality];
                        new waterBonus = PlantData[idx][plantWaterCount] / 2;
                        new fertilizerBonus = PlantData[idx][plantFertilized] ? 3 : 0;
                        
                        new totalYield = baseYield + healthBonus + soilBonus + waterBonus + fertilizerBonus;
                        if(totalYield > 15) totalYield = 15;
                        
                        PlayerPlantInv[playerid][playerHarvested][PlantData[idx][plantType]] += totalYield;
                        
                        DestroyDynamicObject(PlantData[idx][plantObject]);
                        DestroyDynamic3DTextLabel(PlantData[idx][plantLabel]);
                        PlantData[idx][plantExists] = 0;
                        
                        new string[128];
                        format(string, sizeof(string), "Ban da thu hoach thanh cong %d %s!", totalYield, PlantTypeNames[PlantData[idx][plantType]]);
                        SendClientMessage(playerid, COLOR_GREEN, string);
                    }
                    else
                    {
                        DestroyDynamicObject(PlantData[idx][plantObject]);
                        DestroyDynamic3DTextLabel(PlantData[idx][plantLabel]);
                        PlantData[idx][plantExists] = 0;
                        SendClientMessage(playerid, COLOR_ORANGE, "Ban da xoa cay thanh cong!");
                    }
                }
                else
                {
                    SendClientMessage(playerid, COLOR_RED, "Ban khong the xoa/thu hoach cay cua nguoi khac!");
                }
                return 1;
            }
        }
        
        case DIALOG_THUHOACH:
        {
            if(response)
            {
                new idx = GetPVarInt(playerid, "HarvestPlant");
                if(idx >= 0 && idx < MAX_SLOTCAY && PlantData[idx][plantExists])
                {
                    DestroyDynamicObject(PlantData[idx][plantObject]);
                    DestroyDynamic3DTextLabel(PlantData[idx][plantLabel]);
                    PlantData[idx][plantExists] = 0;
                    SendClientMessage(playerid, COLOR_GREEN, "Ban da thu hoach thanh cong!");
                }
            }
            return 1;
        }
    }
    return 0;
}

hook OnGameModeInit()
{
    SetTimer("PlantWaterNeedTimer", 60000, true);
    SetTimer("PlantHealthDecayTimer", 300000, true);
    
    // Khoi tao inventory cho tat ca players (neu can)
    foreach(new i: Player)
    {
        if(IsPlayerConnected(i))
        {
            InitializePlayerPlantInventory(i);
        }
        break;
    }
}

hook OnPlayerConnect(playerid)
{
    InitializePlayerPlantInventory(playerid);
    return 1;
}

stock InitializePlayerPlantInventory(playerid)
{
    for(new i = 0; i < 6; i++)
    {
        PlayerPlantInv[playerid][playerSeeds][i] = 0;
        PlayerPlantInv[playerid][playerHarvested][i] = 0;
    }
    PlayerPlantInv[playerid][playerFertilizer] = 0;
    PlayerPlantInv[playerid][playerWateringCan] = 0;
    
    PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_MARIJUANA] = 3;
    PlayerPlantInv[playerid][playerSeeds][PLANT_TYPE_CORN] = 2;
    PlayerPlantInv[playerid][playerFertilizer] = 1;
    PlayerPlantInv[playerid][playerWateringCan] = 1;
    return 1;
}

forward PlantWaterNeedTimer();
public PlantWaterNeedTimer()
{
    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(!PlantData[i][plantExists]) continue;
        
        new growTime = PlantData[i][plantFertilized] ? floatround(PLANT_GROW_TIME * PLANT_FERTILIZER_BOOST) : PLANT_GROW_TIME;
        
        if(!PlantData[i][plantNeedWater] && 
           gettime() - PlantData[i][plantLastWater] >= PLANT_WATER_INTERVAL && 
           gettime() - PlantData[i][plantStartTime] < growTime)
        {
            PlantData[i][plantNeedWater] = 1;
            UpdatePlantLabel(i);
        }
        
        if(PlantData[i][plantNeedWater] && 
           gettime() - PlantData[i][plantLastWater] > PLANT_WATER_INTERVAL + 120)
        {
            DestroyDynamicObject(PlantData[i][plantObject]);
            DestroyDynamic3DTextLabel(PlantData[i][plantLabel]);
            
            if(IsPlayerConnected(PlantData[i][plantOwner]))
                SendClientMessage(PlantData[i][plantOwner], COLOR_RED, "Cay cua ban da chet vi khong duoc tuoi nuoc!");
            
            PlantData[i][plantExists] = 0;
        }
    }
}

forward PlantHealthDecayTimer();
public PlantHealthDecayTimer()
{
    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(!PlantData[i][plantExists]) continue;
        
        if(PlantData[i][plantNeedWater])
        {
            PlantData[i][plantHealth] -= 5;
            if(PlantData[i][plantHealth] < 0) PlantData[i][plantHealth] = 0;
            
            if(PlantData[i][plantHealth] <= 10)
            {
                if(IsPlayerConnected(PlantData[i][plantOwner]))
                    SendClientMessage(PlantData[i][plantOwner], COLOR_RED, "Cay cua ban dang trong tinh trang nguy hiem!");
            }
            
            UpdatePlantLabel(i);
        }
    }
}

stock UpdatePlantLabel(idx)
{
    if(!PlantData[idx][plantExists]) return 0;
    
    new growTime = PlantData[idx][plantFertilized] ? floatround(PLANT_GROW_TIME * PLANT_FERTILIZER_BOOST) : PLANT_GROW_TIME;
    new left = growTime - (gettime() - PlantData[idx][plantStartTime]);
    if(left < 0) left = 0;
    
    new label[200];
    new healthColor[16];
    
    if(PlantData[idx][plantHealth] >= 80) strcpy(healthColor, "{00FF00}", 16);
    else if(PlantData[idx][plantHealth] >= 50) strcpy(healthColor, "{FFFF00}", 16);
    else if(PlantData[idx][plantHealth] >= 20) strcpy(healthColor, "{FF9900}", 16);
    else strcpy(healthColor, "{FF0000}", 16);
    
    if(left <= 0)
    {
        format(label, sizeof(label), 
            "{00FF00}%s {FFFFFF}(Co the thu hoach)\n%sSuc khoe: %d%%{FFFFFF}\nChat luong dat: %d/5",
            PlantTypeNames[PlantData[idx][plantType]],
            healthColor,
            PlantData[idx][plantHealth],
            PlantData[idx][plantSoilQuality]
        );
    }
    else
    {
        if(PlantData[idx][plantNeedWater])
        {
            format(label, sizeof(label), 
                "{FF0000}%s - CAN NUOC!\n%sSuc khoe: %d%%{FFFFFF}\nCon lai: %d phut",
                PlantTypeNames[PlantData[idx][plantType]],
                healthColor,
                PlantData[idx][plantHealth],
                left/60
            );
        }
        else
        {
            format(label, sizeof(label), 
                "{00FF00}%s - Dang phat trien\n%sSuc khoe: %d%%{FFFFFF}\nCon lai: %d phut",
                PlantTypeNames[PlantData[idx][plantType]],
                healthColor,
                PlantData[idx][plantHealth],
                left/60
            );
        }
    }
    
    UpdateDynamic3DTextLabelText(PlantData[idx][plantLabel], 0xFFFFFFFF, label);
    return 1;
}

stock SavePlantToDatabase(idx)
{
    if(!PlantData[idx][plantExists]) return 0;
    
    new query[512];
    format(query, sizeof(query),
        "INSERT INTO plants (owner, x, y, z, type, start_time, last_water, water_count, need_water, health, fertilized, soil_quality) VALUES ('%s', %.2f, %.2f, %.2f, %d, %d, %d, %d, %d, %d, %d, %d)",
        PlantData[idx][plantOwnerName],
        PlantData[idx][plantX],
        PlantData[idx][plantY], 
        PlantData[idx][plantZ],
        PlantData[idx][plantType],
        PlantData[idx][plantStartTime],
        PlantData[idx][plantLastWater],
        PlantData[idx][plantWaterCount],
        PlantData[idx][plantNeedWater],
        PlantData[idx][plantHealth],
        PlantData[idx][plantFertilized],
        PlantData[idx][plantSoilQuality]
    );
    mysql_tquery(mysql, query);
    return 1;
}

stock LoadPlayerPlants(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    new query[128];
    format(query, sizeof(query), "SELECT * FROM plants WHERE owner = '%s'", name);
    mysql_tquery(mysql, query, "OnPlayerPlantsLoaded", "d", playerid);
    return 1;
}

forward OnPlayerPlantsLoaded(playerid);
public OnPlayerPlantsLoaded(playerid)
{
    new rows = cache_num_rows();
    if(rows == 0) return 1;
    
    for(new row = 0; row < rows; row++)
    {
        new idx = FindEmptyPlantSlot();
        if(idx == -1) break;
        
        PlantData[idx][plantExists] = 1;
        PlantData[idx][plantOwner] = playerid;
        
        new temp[64];
        cache_get_field_content(row, "owner", PlantData[idx][plantOwnerName], MYSQL_INVALID_HANDLE, MAX_PLAYER_NAME);
        
        cache_get_field_content(row, "x", temp); PlantData[idx][plantX] = floatstr(temp);
        cache_get_field_content(row, "y", temp); PlantData[idx][plantY] = floatstr(temp);
        cache_get_field_content(row, "z", temp); PlantData[idx][plantZ] = floatstr(temp);
        
        cache_get_field_content(row, "type", temp); PlantData[idx][plantType] = strval(temp);
        cache_get_field_content(row, "start_time", temp); PlantData[idx][plantStartTime] = strval(temp);
        cache_get_field_content(row, "last_water", temp); PlantData[idx][plantLastWater] = strval(temp);
        cache_get_field_content(row, "water_count", temp); PlantData[idx][plantWaterCount] = strval(temp);
        cache_get_field_content(row, "need_water", temp); PlantData[idx][plantNeedWater] = strval(temp);
        cache_get_field_content(row, "health", temp); PlantData[idx][plantHealth] = strval(temp);
        cache_get_field_content(row, "fertilized", temp); PlantData[idx][plantFertilized] = strval(temp);
        cache_get_field_content(row, "soil_quality", temp); PlantData[idx][plantSoilQuality] = strval(temp);
        
        PlantData[idx][plantObject] = CreateDynamicObject(
            PlantTypeObjects[PlantData[idx][plantType]], 
            PlantData[idx][plantX], 
            PlantData[idx][plantY], 
            PlantData[idx][plantZ] - 1.0, 
            0.0, 0.0, 0.0
        );
        
        PlantData[idx][plantLabel] = CreateDynamic3DTextLabel(
            "Dang tai...", 
            0xFFFFFFFF, 
            PlantData[idx][plantX], 
            PlantData[idx][plantY], 
            PlantData[idx][plantZ], 
            10.0
        );
        
        UpdatePlantLabel(idx);
    }
    return 1;
}

CMD:giveseed(playerid, params[])
{
    new targetid, type, amount;
    if(sscanf(params, "ddd", targetid, type, amount))
    {
        SendClientMessage(playerid, COLOR_WHITE, "Su dung: /giveseed [playerid] [type] [amount]");
        SendClientMessage(playerid, COLOR_WHITE, "Type: 1-Marijuana, 2-Corn, 3-Tomato, 4-Potato, 5-Tree");
        return 1;
    }
    
    if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Player khong online!");
    if(type < 1 || type > 5) return SendClientMessage(playerid, COLOR_RED, "Loai hat giong khong hop le!");
    if(amount < 1 || amount > 100) return SendClientMessage(playerid, COLOR_RED, "So luong khong hop le!");
    
    PlayerPlantInv[targetid][playerSeeds][type] += amount;
    
    new string[128], adminName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, adminName, sizeof(adminName));
    GetPlayerName(targetid, targetName, sizeof(targetName));
    
    format(string, sizeof(string), "Admin %s da cho ban %d hat giong %s", adminName, amount, PlantTypeNames[type]);
    SendClientMessage(targetid, COLOR_GREEN, string);
    
    format(string, sizeof(string), "Ban da cho %s %d hat giong %s", targetName, amount, PlantTypeNames[type]);
    SendClientMessage(playerid, COLOR_GREEN, string);
    return 1;
}

CMD:plantinfo(playerid, params[])
{
    new totalPlants = 0;
    new activePlayers = 0;
    
    for(new i = 0; i < MAX_SLOTCAY; i++)
    {
        if(PlantData[i][plantExists]) totalPlants++;
    }
    
    foreach(new i: Player)
    {
        if(IsPlayerConnected(i) && GetPlayerPlantCount(i) > 0) activePlayers++;
    }
    
    new string[256];
    format(string, sizeof(string), 
        "{00FF00}=== THONG KE HE THONG TRONG CAY ===\n\n\
        {FFFFFF}Tong so cay dang trong: {FFFF00}%d/%d\n\
        {FFFFFF}So nguoi choi dang trong cay: {FFFF00}%d\n\
        {FFFFFF}Ty le su dung: {FFFF00}%.1f%%",
        totalPlants, MAX_SLOTCAY,
        activePlayers,
        float(totalPlants) / float(MAX_SLOTCAY) * 100.0
    );
    
    ShowPlayerDialog(playerid, DIALOG_PLANT_ADMIN_INFO, DIALOG_STYLE_MSGBOX, "Thong ke he thong", string, "Dong", "");
    return 1;
}


