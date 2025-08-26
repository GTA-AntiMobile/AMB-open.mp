#include <YSI\YSI_Coding\y_hooks>
#include <YSI\YSI_Game\y_vehicledata>
#include <streamer>

#define MAX_GARAGES 10
#define MAX_PARKING_SPOTS_PER_GARAGE 8

enum E_GARAGE {
    Float:g_NPC_X,
    Float:g_NPC_Y,
    Float:g_NPC_Z,
    Float:g_NPC_Angle,
    g_NPC_ID,
    g_3DText_ID,
    g_Name[32],
    g_ParkingSpotCount,
    g_Active
}

new Float:Garage1NPC[4] = {1227.7659, -1560.9417, 13.6210, 359.1116};
new Garage1Name[] = "Security Garage";

new Float:Garage1Spots[][4] = {
    {1211.8729, -1556.6176, 13.3521, 90.3767},
    {1211.4741, -1540.0060, 13.3521, 267.8623},
    {1212.3710, -1527.2030, 13.3521, 89.4125}
};

new Float:GarageParkingSpots[MAX_GARAGES][8][4];
new Garage3DTextParkingSpots[MAX_GARAGES][8];

new GarageData[MAX_GARAGES][E_GARAGE];
new GarageCount = 0;

new bool:g_GarageSystemInitialized = false;
new bool:g_PlayerSyncInProgress[MAX_PLAYERS];
new g_PlayerSyncAttempts[MAX_PLAYERS];

new PlayerText:GarageTD[MAX_PLAYERS][40];
new bool:g_GarageTextDrawShown[MAX_PLAYERS];
new g_GarageSelectedVehicle[MAX_PLAYERS];
new g_GarageCurrentPage[MAX_PLAYERS];
new g_GarageTotalPages[MAX_PLAYERS];

hook OnPlayerDisconnect(playerid, reason)
{
    g_GarageTextDrawShown[playerid] = false;
    g_GarageSelectedVehicle[playerid] = -1;
    g_GarageCurrentPage[playerid] = 0;
    g_GarageTotalPages[playerid] = 0;
    g_PlayerSyncInProgress[playerid] = false;
    g_PlayerSyncAttempts[playerid] = 0;
    
    SetTimerEx("DeferredGarageCleanup", 50, false, "i", playerid);
    
    return 1;
}

hook OnGameModeInit()
{
    InitializeGarageSystem();
    
    for(new i = 0; i < MAX_VEHICLES; i++) {
        if(DynVeh[i] != -1) {
            if(i == INVALID_VEHICLE_ID || i < 0 || i >= MAX_VEHICLES) {
                DynVeh[i] = -1;
            }
        }
    }
    InitializeGarageTextDrawSystem();
    InitializeDefaultGarages();
    return 1;
}

stock InitializeDefaultGarages()
{
    AddGarage(
        Garage1NPC[0], Garage1NPC[1], Garage1NPC[2], Garage1NPC[3],
        Garage1Name,
        Garage1Spots, sizeof(Garage1Spots)
    );
}

stock AddGarage(Float:npcX, Float:npcY, Float:npcZ, Float:npcAngle, const garageName[], const Float:parkingSpots[][4], spotCount)
{
    if(GarageCount >= MAX_GARAGES) {
        printf("[GARAGE] Cannot add more garages. Maximum reached: %d", MAX_GARAGES);
        return -1;
    }
    
    GarageData[GarageCount][g_NPC_X] = npcX;
    GarageData[GarageCount][g_NPC_Y] = npcY;
    GarageData[GarageCount][g_NPC_Z] = npcZ;
    GarageData[GarageCount][g_NPC_Angle] = npcAngle;
    format(GarageData[GarageCount][g_Name], 32, garageName);
    GarageData[GarageCount][g_Active] = true;
    GarageData[GarageCount][g_ParkingSpotCount] = spotCount;
    
    for(new i = 0; i < spotCount && i < 8; i++) {
        GarageParkingSpots[GarageCount][i][0] = parkingSpots[i][0];
        GarageParkingSpots[GarageCount][i][1] = parkingSpots[i][1];
        GarageParkingSpots[GarageCount][i][2] = parkingSpots[i][2];
        GarageParkingSpots[GarageCount][i][3] = parkingSpots[i][3];
    }
    
    GarageData[GarageCount][g_NPC_ID] = CreateActor(20016, npcX, npcY, npcZ, npcAngle);
    ApplyActorAnimation(GarageData[GarageCount][g_NPC_ID], "DEALER", "shop_pay", 4.1, false, false, false, 0, 0);
    
    new labelText[128];
    format(labelText, sizeof(labelText), "{5AE44C}[%s]{FFFFFF}\nSu dung {E1D320}(Y){FFFFFF} de tuong tac\nDau xe vao vi tri dau xe truoc", garageName);
    GarageData[GarageCount][g_3DText_ID] = CreateDynamic3DTextLabel(labelText, COLOR_WHITE, npcX, npcY, npcZ + 1.0, 8.0);
    
    for(new j = 0; j < spotCount; j++) {
        new spotLabel[64];
        format(spotLabel, sizeof(spotLabel), "{FFD700}[Parking Spot %d]{FFFFFF}\nDau xe vao day\nPhai dung dung vi tri", j + 1);
        Garage3DTextParkingSpots[GarageCount][j] = CreateDynamic3DTextLabel(spotLabel, COLOR_WHITE, 
            parkingSpots[j][0], parkingSpots[j][1], parkingSpots[j][2] + 2.0, 5.0);
    }
    
    GarageCount++;
    return GarageCount - 1;
}





stock RemoveGarage(garageID)
{
    if(garageID < 0 || garageID >= GarageCount) return 0;
    
    if(GarageData[garageID][g_NPC_ID] != INVALID_ACTOR_ID) {
        DestroyActor(GarageData[garageID][g_NPC_ID]);
        GarageData[garageID][g_NPC_ID] = INVALID_ACTOR_ID;
    }
    
    if(GarageData[garageID][g_3DText_ID] != INVALID_STREAMER_ID) {
        DestroyDynamic3DTextLabel(GarageData[garageID][g_3DText_ID]);
        GarageData[garageID][g_3DText_ID] = INVALID_STREAMER_ID;
    }
    
    for(new i = 0; i < GarageData[garageID][g_ParkingSpotCount]; i++) {
        if(Garage3DTextParkingSpots[garageID][i] != INVALID_STREAMER_ID) {
            DestroyDynamic3DTextLabel(Garage3DTextParkingSpots[garageID][i]);
            Garage3DTextParkingSpots[garageID][i] = INVALID_STREAMER_ID;
        }
    }
    
    GarageData[garageID][g_Active] = false;
    printf("[GARAGE] Removed garage: %s", GarageData[garageID][g_Name]);
    
    return 1;
}

stock GetGarageInfo(garageID, &Float:npcX, &Float:npcY, &Float:npcZ, &Float:npcAngle, garageName[], nameSize)
{
    if(garageID < 0 || garageID >= GarageCount || !GarageData[garageID][g_Active]) return 0;
    
    npcX = GarageData[garageID][g_NPC_X];
    npcY = GarageData[garageID][g_NPC_Y];
    npcZ = GarageData[garageID][g_NPC_Z];
    npcAngle = GarageData[garageID][g_NPC_Angle];
    format(garageName, nameSize, "%s", GarageData[garageID][g_Name]);
    
    return 1;
}

stock GetGarageParkingSpot(garageID, spotID, &Float:x, &Float:y, &Float:z, &Float:angle)
{
    if(garageID < 0 || garageID >= GarageCount || !GarageData[garageID][g_Active]) return 0;
    if(spotID < 0 || spotID >= GarageData[garageID][g_ParkingSpotCount]) return 0;
    
    if(garageID == 0) {
        x = Garage1Spots[spotID][0];
        y = Garage1Spots[spotID][1];
        z = Garage1Spots[spotID][2];
        angle = Garage1Spots[spotID][3];
    } else {
        x = GarageParkingSpots[garageID][spotID][0];
        y = GarageParkingSpots[garageID][spotID][1];
        z = GarageParkingSpots[garageID][spotID][2];
        angle = GarageParkingSpots[garageID][spotID][3];
    }
    
    return 1;
}

stock GetPlayerGarage(playerid, &garageID = -1)
{
    for(new i = 0; i < GarageCount; i++) {
        if(GarageData[i][g_Active] && IsPlayerInRangeOfPoint(playerid, 2.0, GarageData[i][g_NPC_X], GarageData[i][g_NPC_Y], GarageData[i][g_NPC_Z])) {
            garageID = i;
            return true;
        }
    }
    return false;
}

stock IsPlayerInGarageParkingSpot(playerid, garageID, &spot = -1)
{
    if(garageID < 0 || garageID >= GarageCount || !GarageData[garageID][g_Active]) return false;
    
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    for(new i = 0; i < GarageData[garageID][g_ParkingSpotCount]; i++) {
        new Float:spotX, Float:spotY, Float:spotZ;
        
        if(garageID == 0) {
            spotX = Garage1Spots[i][0];
            spotY = Garage1Spots[i][1];
            spotZ = Garage1Spots[i][2];
        } else {
            spotX = GarageParkingSpots[garageID][i][0];
            spotY = GarageParkingSpots[garageID][i][1];
            spotZ = GarageParkingSpots[garageID][i][2];
        }
        
        if(IsPlayerInRangeOfPoint(playerid, 6.0, spotX, spotY, spotZ)) {
            spot = i;
            return true;
        }
    }
    return false;
}

stock IsVehicleInGarageParkingSpot(vehicleid, garageID, &spot = -1)
{
    if(garageID < 0 || garageID >= GarageCount || !GarageData[garageID][g_Active]) return false;
    
    if(!IsValidVehicle(vehicleid)) return false;
    
    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);
    
    for(new i = 0; i < GarageData[garageID][g_ParkingSpotCount]; i++) {
        new Float:spotX, Float:spotY, Float:spotZ;
        
        if(garageID == 0) {
            spotX = Garage1Spots[i][0];
            spotY = Garage1Spots[i][1];
            spotZ = Garage1Spots[i][2];
        } else {
            spotX = GarageParkingSpots[garageID][i][0];
            spotY = GarageParkingSpots[garageID][i][1];
            spotZ = GarageParkingSpots[garageID][i][2];
        }
        
        new Float:distance = GetDistanceBetweenPoints(x, y, z, spotX, spotY, spotZ);
        
        if(distance <= 8.0) {
            spot = i;
            return true;
        }
    }
    
    return false;
}

stock IsGarageParkingSpotOccupied(garageID, spot)
{
    if(garageID < 0 || garageID >= GarageCount || !GarageData[garageID][g_Active]) return true;
    if(spot < 0 || spot >= GarageData[garageID][g_ParkingSpotCount]) return true;
    
    if(garageID >= MAX_GARAGES || spot >= 8) return true;
    
    new Float:x, Float:y, Float:z;
    
    if(garageID == 0) {
        x = Garage1Spots[spot][0];
        y = Garage1Spots[spot][1];
        z = Garage1Spots[spot][2];
    } else {
        x = GarageParkingSpots[garageID][spot][0];
        y = GarageParkingSpots[garageID][spot][1];
        z = GarageParkingSpots[garageID][spot][2];
    }
    
    foreach(new vehicleid : Vehicle) {
        if(IsValidVehicle(vehicleid)) {
            new Float:vx, Float:vy, Float:vz;
            GetVehiclePos(vehicleid, vx, vy, vz);
            if(IsInRangeOfPoint(vx, vy, vz, x, y, z, 6.0)) {
                return true;
            }
        }
    }
    
    foreach(new playerid : Player) {
        if(IsPlayerConnected(playerid)) {
            if(IsPlayerInRangeOfPoint(playerid, 6.0, x, y, z)) {
                return true;
            }
        }
    }
    
    return false;
}

stock GetRandomAvailableGarageSpot(garageID)
{
    if(garageID < 0 || garageID >= GarageCount || !GarageData[garageID][g_Active]) {
        printf("[GARAGE ERROR] Invalid garage ID: %d (total: %d)", garageID, GarageCount);
        return -1;
    }
    
    new availableSpots[8], count = 0;
    new maxSpots = GarageData[garageID][g_ParkingSpotCount];
    
    if(maxSpots <= 0 || maxSpots > 8) {
        printf("[GARAGE ERROR] Invalid parking spot count: %d for garage %d", maxSpots, garageID);
        return -1;
    }
    
    for(new i = 0; i < maxSpots; i++) {
        if(!IsGarageParkingSpotOccupied(garageID, i)) {
            availableSpots[count] = i;
            count++;
        }
    }
    
    if(count == 0) {
        return -1; 
    }
    
    new selectedSpot = availableSpots[random(count)];
    return selectedSpot;
}

stock GetRandomAvailableGarageSpotWithRetry(garageID)
{
    new attempts = 0;
    while(attempts < 10) {
        new spot = GetRandomAvailableGarageSpot(garageID);
        if(spot != -1) return spot;
        attempts++;
    }
    return -1; 
}

stock IsSpawnPositionClear(Float:x, Float:y, Float:z)
{
    foreach(new vehicleid : Vehicle) {
        if(IsValidVehicle(vehicleid)) {
            new Float:vx, Float:vy, Float:vz;
            GetVehiclePos(vehicleid, vx, vy, vz);
            if(IsInRangeOfPoint(vx, vy, vz, x, y, z, 3.0)) {
                return false;
            }
        }
    }
    
    foreach(new playerid : Player) {
        if(IsPlayerConnected(playerid)) {
            new Float:px, Float:py, Float:pz;
            GetPlayerPos(playerid, px, py, pz);
            if(IsInRangeOfPoint(px, py, pz, x, y, z, 3.0)) {
                return false;
            }
        }
    }
    
    return true;
}

stock GetVehicleStatus(vehicleid, ownerid, slot)
{
    #pragma unused vehicleid
    if(PlayerVehicleInfo[ownerid][slot][pvImpounded] > 0) {
        return 3; // Impounded
    }
    
    if(PlayerVehicleInfo[ownerid][slot][pvSpawned] == 1) {
        return 2; 
    }
    
    return 1; 
}

stock ShowGarageDialog(playerid)
{
    if(!g_GarageSystemInitialized) {
        SendClientMessageEx(playerid, COLOR_RED, "Garage system chua duoc khoi tao!");
        return 0;
    }
    
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid}) {
        SendClientMessageEx(playerid, COLOR_RED, "Ban chua dang nhap!");
        return 0;
    }
    
    return ShowGarageTextDraw(playerid);
}

stock GarageParkVehicle(playerid, vehicleid, slot)
{
    if(vehicleid == INVALID_VEHICLE_ID) return 0;
    if(slot < 0 || slot >= MAX_PLAYERVEHICLES) return 0;
    if(PlayerVehicleInfo[playerid][slot][pvModelId] == 0) return 0;
    
    if(!IsValidVehicle(vehicleid)) {
        return 0;
    }
    
    new Float:health;
    GetVehicleHealth(vehicleid, health);
    if(health < 300.0) {
        SendClientMessageEx(playerid, COLOR_GREY, "Khong the cat xe khi xe cua ban hu hong qua nang.");
        return 0;
    }
    
    new Float:x, Float:y, Float:z, Float:angle;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);
    

    
    if(PlayerVehicleInfo[playerid][slot][pvSlotId] > 0) {
        new query[512];
        format(query, sizeof(query), "UPDATE `vehicles` SET `pvPosX` = '%.6f', `pvPosY` = '%.6f', `pvPosZ` = '%.6f', `pvPosAngle` = '%.6f' WHERE `id` = '%d'",
            x, y, z, angle, PlayerVehicleInfo[playerid][slot][pvSlotId]);
        mysql_pquery(MainPipeline, query, "OnVehicleParked", "iii", playerid, vehicleid, slot);
    }
    
    PlayerVehicleInfo[playerid][slot][pvPosX] = x;
    PlayerVehicleInfo[playerid][slot][pvPosY] = y;
    PlayerVehicleInfo[playerid][slot][pvPosZ] = z;
    PlayerVehicleInfo[playerid][slot][pvPosAngle] = angle;
    PlayerVehicleInfo[playerid][slot][pvHealth] = health; // Save current health
    PlayerVehicleInfo[playerid][slot][pvSpawned] = 0; // Mark as not spawned
    
    DestroyVehicle(vehicleid);
    PlayerVehicleInfo[playerid][slot][pvId] = INVALID_VEHICLE_ID;
    

    SendClientMessageEx(playerid, COLOR_GREEN, "Xe cua ban da duoc cat vao garage thanh cong!");
    return 1;
}

stock TakeOutVehicle(playerid, slot)
{
    if(slot < 0 || slot >= MAX_PLAYERVEHICLES) return 0;
    if(PlayerVehicleInfo[playerid][slot][pvModelId] == 0) return 0;
    if(PlayerVehicleInfo[playerid][slot][pvImpounded] > 0) {
        SendClientMessageEx(playerid, COLOR_RED, "Xe nay dang bi giu o DMV. Ban can lay xe ra truoc.");
        return 0;
    }
    
    new vehicleid = PlayerVehicleInfo[playerid][slot][pvId];
    if(IsValidVehicle(vehicleid)) {
        SendClientMessageEx(playerid, COLOR_RED, "Xe nay da duoc lay ra roi!");
        return 0;
    }
    
    new garageID;
    if(!GetPlayerGarage(playerid, garageID)) {
        SendClientMessageEx(playerid, COLOR_RED, "Ban phai o gan garage de lay xe!");
        return 0;
    }
    
    if(garageID < 0 || garageID >= GarageCount) {
        printf("[GARAGE ERROR] Invalid garage ID: %d for player %d", garageID, playerid);
        SendClientMessageEx(playerid, COLOR_RED, "Loi garage. Vui long thu lai.");
        return 0;
    }
    
    new spot = GetRandomAvailableGarageSpotWithRetry(garageID);
    if(spot == -1) {
        SendClientMessageEx(playerid, COLOR_RED, "Khong co cho do xe trong. Vui long cho mot chut.");
        return 0;
    }
    
    new Float:spawnX, Float:spawnY, Float:spawnZ, Float:spawnAngle;
    
    if(garageID < 0 || garageID >= GarageCount || spot < 0 || spot >= 8) {
        printf("[GARAGE ERROR] Invalid garage %d or spot %d", garageID, spot);
        SendClientMessageEx(playerid, COLOR_RED, "Loi khi lay xe. Vui long thu lai.");
        return 0;
    }

    if(garageID == 0) {
        spawnX = Garage1Spots[spot][0];
        spawnY = Garage1Spots[spot][1];
        spawnZ = Garage1Spots[spot][2] + 0.5;
        spawnAngle = Garage1Spots[spot][3];
    } else {
        spawnX = GarageParkingSpots[garageID][spot][0];
        spawnY = GarageParkingSpots[garageID][spot][1];
        spawnZ = GarageParkingSpots[garageID][spot][2] + 0.5;
        spawnAngle = GarageParkingSpots[garageID][spot][3];
    }
    
    if(spawnX == 0.0 && spawnY == 0.0 && spawnZ == 0.0) {
        printf("[GARAGE ERROR] Invalid spawn coordinates for garage %d spot %d", garageID, spot);
        SendClientMessageEx(playerid, COLOR_RED, "Loi khi lay xe. Vui long thu lai.");
        return 0;
    }
    

    
    if(!IsSpawnPositionClear(spawnX, spawnY, spawnZ)) {
        SendClientMessageEx(playerid, COLOR_RED, "Vi tri spawn bi chiem. Vui long thu lai.");
        return 0;
    }
    
    SetTimerEx("DelayedVehicleSpawn", 1000, false, "iiiffff", playerid, slot, spot, spawnX, spawnY, spawnZ, spawnAngle);
    
    return 1;
}

forward DelayedVehicleSpawn(playerid, slot, spot, Float:spawnX, Float:spawnY, Float:spawnZ, Float:spawnAngle);
public DelayedVehicleSpawn(playerid, slot, spot, Float:spawnX, Float:spawnY, Float:spawnZ, Float:spawnAngle)
{
    if(!IsPlayerConnected(playerid)) return 1;
    

    
    new vehicleid = CreateVehicle(PlayerVehicleInfo[playerid][slot][pvModelId], 
        spawnX, spawnY, spawnZ, spawnAngle,
        PlayerVehicleInfo[playerid][slot][pvColor1], 
        PlayerVehicleInfo[playerid][slot][pvColor2], -1);
    
    if(vehicleid == INVALID_VEHICLE_ID) {
        SendClientMessageEx(playerid, COLOR_RED, "Loi khi tao xe. Vui long thu lai.");
        return 1;
    }
    
    new playerVW = GetPlayerVirtualWorld(playerid);
    new playerInt = GetPlayerInterior(playerid);
    SetVehicleVirtualWorld(vehicleid, playerVW);
    LinkVehicleToInterior(vehicleid, playerInt);
    
    new Float:health = PlayerVehicleInfo[playerid][slot][pvHealth];
    if(health < 300.0) health = 1000.0; // Only set to full health if it was too low when parked
    SetVehicleHealth(vehicleid, health);
    
    for(new i = 0; i < MAX_MODS; i++) {
        if(PlayerVehicleInfo[playerid][slot][pvMods][i] != 0) {
            AddVehicleComponent(vehicleid, PlayerVehicleInfo[playerid][slot][pvMods][i]);
        }
    }
    
    PlayerVehicleInfo[playerid][slot][pvId] = vehicleid;
    PlayerVehicleInfo[playerid][slot][pvPosX] = spawnX;
    PlayerVehicleInfo[playerid][slot][pvPosY] = spawnY;
    PlayerVehicleInfo[playerid][slot][pvPosZ] = spawnZ;
    PlayerVehicleInfo[playerid][slot][pvPosAngle] = spawnAngle;
    PlayerVehicleInfo[playerid][slot][pvSpawned] = 1; // Mark as spawned
    PlayerVehicleInfo[playerid][slot][pvVW] = playerVW; // Update stored VW
    PlayerVehicleInfo[playerid][slot][pvInt] = playerInt; // Update stored interior
    
    if(PlayerVehicleInfo[playerid][slot][pvSlotId] > 0) {
        new query[512];
        format(query, sizeof(query), "UPDATE `vehicles` SET `pvPosX` = '%.6f', `pvPosY` = '%.6f', `pvPosZ` = '%.6f', `pvPosAngle` = '%.6f' WHERE `id` = '%d'",
            spawnX, spawnY, spawnZ, spawnAngle, PlayerVehicleInfo[playerid][slot][pvSlotId]);
        mysql_pquery(MainPipeline, query, "OnVehicleTakenOut", "iii", playerid, vehicleid, slot);
    }
    
    new vehicleName[323];
    Model_GetName(PlayerVehicleInfo[playerid][slot][pvModelId], vehicleName);
    format(vehicleName, sizeof(vehicleName), "Ban da lay %s ra khoi garage tai vi tri %d.", vehicleName, spot + 1);
    SendClientMessageEx(playerid, COLOR_GREEN, vehicleName);
    
    if(g_GarageTextDrawShown[playerid]) {
        UpdateGarageVehicleList(playerid);
        UpdatePaginationButtons(playerid);
    }
    
    return 1;
}



hook OnPlayerConnect(playerid)
{
    if(!g_GarageSystemInitialized) return 1;
    
    if(playerid < 0 || playerid >= MAX_PLAYERS) {
        printf("[GARAGE ERROR] Invalid player ID in OnPlayerConnect: %d", playerid);
        return 1;
    }
    
    for(new i = 0; i < 40; i++) {
        if(GarageTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, GarageTD[playerid][i]);
        }
        GarageTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    g_GarageTextDrawShown[playerid] = false;
    g_GarageSelectedVehicle[playerid] = -1;
    g_GarageCurrentPage[playerid] = 0;
    g_GarageTotalPages[playerid] = 0;
    g_PlayerSyncInProgress[playerid] = false;
    g_PlayerSyncAttempts[playerid] = 0;
    
    SetTimerEx("DelayedSyncVehicleStatus", 2000, false, "i", playerid);
    
    return 1;
}

forward DelayedSyncVehicleStatus(playerid);
public DelayedSyncVehicleStatus(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    
    if(gPlayerLogged{playerid}) {
        SyncVehicleStatusOnConnect(playerid);
    } else {
        if(g_PlayerSyncAttempts[playerid] < 3) {
            g_PlayerSyncAttempts[playerid]++;
            SetTimerEx("DelayedSyncVehicleStatus", 2000, false, "i", playerid);
        }
    }
    return 1;
}

hook OnGameModeExit()
{
    if(!g_GarageSystemInitialized) return 1;
    SaveAllVehiclesOnServerShutdown();
    
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    if(!g_GarageSystemInitialized) return 1;
    
    foreach(new i: Player) {
        if(IsPlayerConnected(i) && gPlayerLogged{i}) {
            for(new j = 0; j < MAX_PLAYERVEHICLES; j++) {
                if(IsValidVehicleSlot(j) && PlayerVehicleInfo[i][j][pvId] == vehicleid) {
                    PlayerVehicleInfo[i][j][pvSpawned] = 0;
                    PlayerVehicleInfo[i][j][pvId] = INVALID_VEHICLE_ID;
                    PlayerVehicleInfo[i][j][pvPosX] = 0.0;
                    PlayerVehicleInfo[i][j][pvPosY] = 0.0;
                    PlayerVehicleInfo[i][j][pvPosZ] = 0.0;
                    PlayerVehicleInfo[i][j][pvPosAngle] = 0.0;
                    
                    g_mysql_SaveVehicle(i, j);
                    
                    if(g_GarageTextDrawShown[i]) {
                        UpdateGarageVehicleList(i);
                    }
                    
                    return 1;
                }
            }
        }
    }
    
    return 1;
}

stock SavePlayerVehiclesOnDisconnect(playerid)
{

    if(playerid < 0 || playerid >= MAX_PLAYERS) {
        printf("[GARAGE ERROR] Invalid player ID in SavePlayerVehiclesOnDisconnect: %d", playerid);
        return 0;
    }
    
    if(!gPlayerLogged{playerid}) {
        printf("[GARAGE WARNING] Player %d not logged in during disconnect", playerid);
        return 0;
    }
    

    if(playerid >= MAX_PLAYERS) {
        printf("[GARAGE ERROR] Player ID out of bounds for PlayerVehicleInfo: %d", playerid);
        return 0;
    }
    

    if(!g_GarageSystemInitialized) {
        printf("[GARAGE ERROR] Garage system not initialized");
        return 0;
    }
    
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        if(i >= 0 && i < MAX_PLAYERVEHICLES) {
            if(PlayerVehicleInfo[playerid][i][pvModelId] != 0) {
                if(PlayerVehicleInfo[playerid][i][pvModelId] >= 400 && PlayerVehicleInfo[playerid][i][pvModelId] <= 611) {
                    if(playerid >= 0 && playerid < MAX_PLAYERS && i >= 0 && i < MAX_PLAYERVEHICLES) {
                        g_mysql_SaveVehicle(playerid, i);
                    } else {
                        printf("[GARAGE ERROR] Invalid parameters for g_mysql_SaveVehicle: playerid=%d, slot=%d", playerid, i);
                    }
                } else {
                    printf("[GARAGE WARNING] Invalid vehicle model ID %d for player %d slot %d", 
                        PlayerVehicleInfo[playerid][i][pvModelId], playerid, i);
                }
            }
        }
    }
    
    return 1;
}

stock SaveAllVehiclesOnServerShutdown()
{
    foreach(new i: Player) {
        if(i >= 0 && i < MAX_PLAYERS) {
            if(IsPlayerConnected(i) && gPlayerLogged{i}) {
                SavePlayerVehiclesOnDisconnect(i);
            }
        }
    }
    
    return 1;
}

forward SyncVehicleSystem(playerid);
stock ForceSyncVehicleStatus(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid} || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    if(playerid >= MAX_PLAYERS) {
        printf("[GARAGE ERROR] Player ID out of bounds for PlayerVehicleInfo: %d", playerid);
        return 0;
    }
    
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        if(i >= 0 && i < MAX_PLAYERVEHICLES) {
            if(playerid >= 0 && playerid < MAX_PLAYERS && i >= 0 && i < MAX_PLAYERVEHICLES) {
                if(!IsValidVehicleData(playerid, i) || IsVehicleRemoved(playerid, i)) continue;
                
                new currentVehicle = GetPlayerVehicleID(playerid);
                if(currentVehicle != INVALID_VEHICLE_ID && IsValidVehicle(currentVehicle)) {
                    new model = GetVehicleModel(currentVehicle);
                    if(model == PlayerVehicleInfo[playerid][i][pvModelId]) {
                        PlayerVehicleInfo[playerid][i][pvSpawned] = 1;
                        PlayerVehicleInfo[playerid][i][pvId] = currentVehicle;
                        
                        new Float:x, Float:y, Float:z, Float:angle;
                        GetVehiclePos(currentVehicle, x, y, z);
                        GetVehicleZAngle(currentVehicle, angle);
                        PlayerVehicleInfo[playerid][i][pvPosX] = x;
                        PlayerVehicleInfo[playerid][i][pvPosY] = y;
                        PlayerVehicleInfo[playerid][i][pvPosZ] = z;
                        PlayerVehicleInfo[playerid][i][pvPosAngle] = angle;
                        continue;
                    }
                }
                
                new foundVehicle = FindPlayerVehicleInWorld(playerid, i);
                if(foundVehicle != INVALID_VEHICLE_ID) {
                    PlayerVehicleInfo[playerid][i][pvSpawned] = 1;
                    PlayerVehicleInfo[playerid][i][pvId] = foundVehicle;
                    
                    new Float:x, Float:y, Float:z, Float:angle;
                    GetVehiclePos(foundVehicle, x, y, z);
                    GetVehicleZAngle(foundVehicle, angle);
                    PlayerVehicleInfo[playerid][i][pvPosX] = x;
                    PlayerVehicleInfo[playerid][i][pvPosY] = y;
                    PlayerVehicleInfo[playerid][i][pvPosZ] = z;
                    PlayerVehicleInfo[playerid][i][pvPosAngle] = angle;
                } else {
                    PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
                    PlayerVehicleInfo[playerid][i][pvId] = INVALID_VEHICLE_ID;
                }
            }
        }
    }
    
    return 1;
}

stock SyncVehicleStatusOnConnect(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid}) return 0;
    
    ForceSyncVehicleStatus(playerid);
    
    return 1;
}

stock ForceSyncAllPlayerVehicles(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid}) return 0;
    
    return SyncVehicleSystem(playerid);
}

stock HandleVehicleRemoval(playerid, slot)
{
    if(!IsPlayerConnected(playerid) || slot < 0 || slot >= MAX_PLAYERVEHICLES) return 0;
    
    if(PlayerVehicleInfo[playerid][slot][pvModelId] == 0) return 0;
    
    new vehicleid = PlayerVehicleInfo[playerid][slot][pvId];
    if(vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid)) {
        DestroyVehicle(vehicleid);
        
        if(vehicleid >= 0 && vehicleid < MAX_VEHICLES) {
            if(DynVeh[vehicleid] != -1) {
                DynVeh[vehicleid] = -1;
            }
        }
    }
    
    PlayerVehicleInfo[playerid][slot][pvId] = INVALID_VEHICLE_ID;
    PlayerVehicleInfo[playerid][slot][pvSpawned] = 0;
    PlayerVehicleInfo[playerid][slot][pvModelId] = 0;
    
    PlayerVehicleInfo[playerid][slot][pvHealth] = 1000.0;
    
    return 1;
}

stock IsVehicleRemoved(playerid, slot)
{
    if(!IsPlayerConnected(playerid) || slot < 0 || slot >= MAX_PLAYERVEHICLES) return true;
    
    if(PlayerVehicleInfo[playerid][slot][pvModelId] == 0) return true;
    
    return false;
}

stock IsValidVehicleData(playerid, slot)
{
    if(!IsPlayerConnected(playerid) || slot < 0 || slot >= MAX_PLAYERVEHICLES) return false;
    if(PlayerVehicleInfo[playerid][slot][pvModelId] == 0) return false;
    if(PlayerVehicleInfo[playerid][slot][pvModelId] < 400 || PlayerVehicleInfo[playerid][slot][pvModelId] > 611) return false;
    
    return true;
}

stock FixVehicleSyncErrors(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid}) return 0;
    
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        if(!IsValidVehicleData(playerid, i)) continue;
        
        new vehicleid = PlayerVehicleInfo[playerid][i][pvId];
        if(vehicleid != INVALID_VEHICLE_ID && !IsValidVehicle(vehicleid)) {
            PlayerVehicleInfo[playerid][i][pvId] = INVALID_VEHICLE_ID;
            PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
        }
        
        if(PlayerVehicleInfo[playerid][i][pvSpawned] == 1 && vehicleid == INVALID_VEHICLE_ID) {
            PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
        }
        
        if(vehicleid == INVALID_VEHICLE_ID) {
            PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
        } else if(vehicleid >= 0 && vehicleid < MAX_VEHICLES) {
            if(DynVeh[vehicleid] != -1 && !IsValidVehicle(vehicleid)) {
                DynVeh[vehicleid] = -1;
            }
        }
    }
    
    return 1;
}

stock FindPlayerVehicleInWorld(playerid, slot)
{
    if(!IsValidVehicleData(playerid, slot)) return INVALID_VEHICLE_ID;
    
    new expectedModel = PlayerVehicleInfo[playerid][slot][pvModelId];
    
    new currentVehicle = GetPlayerVehicleID(playerid);
    if(currentVehicle != INVALID_VEHICLE_ID && IsValidVehicle(currentVehicle)) {
        new model = GetVehicleModel(currentVehicle);
        if(model == expectedModel) {
            return currentVehicle;
        }
    }
    
    foreach(new vehicleid : Vehicle) {
        if(vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid)) {
            new model = GetVehicleModel(vehicleid);
            if(model == expectedModel) {
                new Float:x, Float:y, Float:z;
                GetVehiclePos(vehicleid, x, y, z);
                
                new Float:playerX, Float:playerY, Float:playerZ;
                GetPlayerPos(playerid, playerX, playerY, playerZ);
                
                for(new garageID = 0; garageID < GarageCount; garageID++) {
                    if(!GarageData[garageID][g_Active]) continue;
                    
                    for(new spotID = 0; spotID < GarageData[garageID][g_ParkingSpotCount]; spotID++) {
                        new Float:spotX, Float:spotY, Float:spotZ;
                        
                        if(garageID == 0) {
                            spotX = Garage1Spots[spotID][0];
                            spotY = Garage1Spots[spotID][1];
                            spotZ = Garage1Spots[spotID][2];
                        } else {
                            spotX = GarageParkingSpots[garageID][spotID][0];
                            spotY = GarageParkingSpots[garageID][spotID][1];
                            spotZ = GarageParkingSpots[garageID][spotID][2];
                        }
                        
                        if(IsInRangeOfPoint(x, y, z, spotX, spotY, spotZ, 5.0)) {
                            return vehicleid;
                        }
                    }
                }
                
                if(IsInRangeOfPoint(x, y, z, playerX, playerY, playerZ, 50.0)) {
                    return vehicleid;
                }
            }
        }
    }
    
    return INVALID_VEHICLE_ID;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(!g_GarageSystemInitialized) return 1;
    
    if(newkeys & KEY_YES)
    {
        new garageID;
        if(GetPlayerGarage(playerid, garageID)) {
            if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
                SendClientMessageEx(playerid, COLOR_GRAD2, "Ban phai xuong xe de su dung garage!");
                return 1;
            }
            
            ShowGarageTextDraw(playerid);
        }
    }
    
    return 1;
}

hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:clickedid)
{
    if(!g_GarageSystemInitialized) return 1;
    
    if(HandleGarageTextDrawClick(playerid, clickedid)) {
        return 1;
    }
    
    return 1;
}

forward OnVehicleParked(playerid, vehicleid, slot);
public OnVehicleParked(playerid, vehicleid, slot)
{
    #pragma unused playerid, vehicleid, slot
    return 1;
}

forward OnVehicleTakenOut(playerid, vehicleid, slot);
public OnVehicleTakenOut(playerid, vehicleid, slot)
{
    #pragma unused playerid, vehicleid, slot
    return 1;
}

stock InitializeGarageSystem()
{
    if(g_GarageSystemInitialized) return 1;
    
    g_GarageSystemInitialized = true;
    GarageCount = 0;
    
    for(new i = 0; i < MAX_GARAGES; i++) {
        GarageData[i][g_NPC_X] = 0.0;
        GarageData[i][g_NPC_Y] = 0.0;
        GarageData[i][g_NPC_Z] = 0.0;
        GarageData[i][g_NPC_Angle] = 0.0;
        GarageData[i][g_NPC_ID] = INVALID_ACTOR_ID;
        GarageData[i][g_3DText_ID] = INVALID_STREAMER_ID;
        GarageData[i][g_Name][0] = '\0';
        GarageData[i][g_ParkingSpotCount] = 0;
        GarageData[i][g_Active] = false;
        
        for(new j = 0; j < MAX_PARKING_SPOTS_PER_GARAGE; j++) {
            GarageParkingSpots[i][j][0] = 0.0;
            GarageParkingSpots[i][j][1] = 0.0;
            GarageParkingSpots[i][j][2] = 0.0;
            GarageParkingSpots[i][j][3] = 0.0;
            Garage3DTextParkingSpots[i][j] = INVALID_STREAMER_ID;
        }
    }
    return 1;
}

stock InitializeGarageTextDrawSystem()
{
    for(new playerid = 0; playerid < MAX_PLAYERS; playerid++) {
        g_GarageTextDrawShown[playerid] = false;
        g_GarageSelectedVehicle[playerid] = -1;
        g_GarageCurrentPage[playerid] = 0;
        g_GarageTotalPages[playerid] = 0;
        g_PlayerSyncInProgress[playerid] = false;
        g_PlayerSyncAttempts[playerid] = 0;
        
        for(new i = 0; i < 40; i++) {
            GarageTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    return 1;
}

stock CreateGarageTextDraws(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;
    
    GarageTD[playerid][0] = CreatePlayerTextDraw(playerid, 0.0, 0.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][0], 640.0, 448.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][0], 0x000000E6);
    PlayerTextDrawFont(playerid, GarageTD[playerid][0], 4);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][0], 2);
    
    // Main panel background
    GarageTD[playerid][1] = CreatePlayerTextDraw(playerid, 110.0, 90.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][1], 420.0, 340.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][1], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][1], 0x1E1E1EFF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][1], 4);
    
    // Header bar with gradient
    GarageTD[playerid][2] = CreatePlayerTextDraw(playerid, 110.0, 90.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][2], 420.0, 45.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][2], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][2], 0x2E7D32FF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][2], 4);
    
    // Accent line
    GarageTD[playerid][3] = CreatePlayerTextDraw(playerid, 110.0, 130.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][3], 420.0, 3.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][3], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][3], 0x66BB6AFF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][3], 4);
    
    // Modern garage title without special characters
    GarageTD[playerid][4] = CreatePlayerTextDraw(playerid, 320.0, 100.0, "~g~HE THONG GARAGE AMB");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][4], 0.380, 1.800);
    PlayerTextDrawColor(playerid, GarageTD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][4], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][4], 1);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][4], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][4], 2);
    
    // Modern subtitle
    GarageTD[playerid][5] = CreatePlayerTextDraw(playerid, 320.0, 120.0, "~w~He thong quan ly xe");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][5], 0.220, 1.100);
    PlayerTextDrawColor(playerid, GarageTD[playerid][5], 0xE0E0E0FF);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][5], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][5], 0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][5], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][5], 1);
    
    // Vehicle list panel background
    GarageTD[playerid][6] = CreatePlayerTextDraw(playerid, 125.0, 150.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][6], 390.0, 200.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][6], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][6], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][6], 4);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][6], 1);
    
    // Vehicle list header
    GarageTD[playerid][7] = CreatePlayerTextDraw(playerid, 320.0, 160.0, "~w~DANH SACH XE CUA BAN");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][7], 0.280, 1.400);
    PlayerTextDrawColor(playerid, GarageTD[playerid][7], -1);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][7], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][7], 0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][7], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][7], 2);
    
    // Vehicle list items - only create when needed (will be created dynamically)
    // Initialize all vehicle slots to INVALID_TEXT_DRAW
    for(new i = 0; i < 5; i++) {
        GarageTD[playerid][8 + i] = PlayerText:INVALID_TEXT_DRAW;
        GarageTD[playerid][18 + i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    // Buttons panel background
    GarageTD[playerid][28] = CreatePlayerTextDraw(playerid, 125.0, 365.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][28], 390.0, 50.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][28], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][28], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][28], 4);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][28], 1);
    
    // Modern button layout with proper sizing
    new Float:buttonY = 375.0;
    new Float:buttonWidth = 120.0;
    new Float:buttonHeight = 35.0;
    
    // LAY XE button - positioned side by side in center
    GarageTD[playerid][29] = CreatePlayerTextDraw(playerid, 240.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][29], buttonWidth, buttonHeight);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][29], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][29], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][29], 4);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][29], 1);
    
    GarageTD[playerid][30] = CreatePlayerTextDraw(playerid, 240.0 + (buttonWidth/2), buttonY + 8.0, "LAY XE");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][30], 0.280, 1.200);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][30], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][30], 2);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][30], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][30], 1);
    PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][30], 0x00000000);
    PlayerTextDrawColor(playerid, GarageTD[playerid][30], 0xFFFFFFFF);
    PlayerTextDrawSetProportional(playerid, GarageTD[playerid][30], 1);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][30], 0);
    
    // CAT XE button - positioned side by side in center
    GarageTD[playerid][31] = CreatePlayerTextDraw(playerid, 370.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][31], buttonWidth, buttonHeight);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][31], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][31], 0xFF9800FF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][31], 4);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][31], 1);
    
    GarageTD[playerid][32] = CreatePlayerTextDraw(playerid, 370.0 + (buttonWidth/2), buttonY + 8.0, "CAT XE");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][32], 0.280, 1.200);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][32], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][32], 2);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][32], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][32], 1);
    PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][32], 0x00000000);
    PlayerTextDrawColor(playerid, GarageTD[playerid][32], 0xFFFFFFFF);
    PlayerTextDrawSetProportional(playerid, GarageTD[playerid][32], 1);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][32], 0);
    
    // X button (close) - small and positioned at top right
    GarageTD[playerid][33] = CreatePlayerTextDraw(playerid, 510.0, 95.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][33], 20.0, 20.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][33], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][33], 0xF44336FF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][33], 4);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][33], 1);
    
    GarageTD[playerid][34] = CreatePlayerTextDraw(playerid, 520.0, 97.0, "X");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][34], 0.300, 1.200);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][34], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][34], 2);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][34], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][34], 1);
    PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][34], 0x00000000);
    PlayerTextDrawColor(playerid, GarageTD[playerid][34], 0xFFFFFFFF);
    PlayerTextDrawSetProportional(playerid, GarageTD[playerid][34], 1);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][34], 0);
    
    // Pagination buttons
    // Previous page button
    GarageTD[playerid][35] = CreatePlayerTextDraw(playerid, 125.0, 320.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][35], 80.0, 25.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][35], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][35], 0x2196F3FF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][35], 4);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][35], 1);
    
    GarageTD[playerid][36] = CreatePlayerTextDraw(playerid, 165.0, 325.0, "TRUOC");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][36], 0.250, 1.000);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][36], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][36], 2);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][36], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][36], 1);
    PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][36], 0x00000000);
    PlayerTextDrawColor(playerid, GarageTD[playerid][36], 0xFFFFFFFF);
    PlayerTextDrawSetProportional(playerid, GarageTD[playerid][36], 1);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][36], 0);
    
    // Next page button
    GarageTD[playerid][37] = CreatePlayerTextDraw(playerid, 435.0, 320.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, GarageTD[playerid][37], 80.0, 25.0);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][37], 1);
    PlayerTextDrawColor(playerid, GarageTD[playerid][37], 0x2196F3FF);
    PlayerTextDrawFont(playerid, GarageTD[playerid][37], 4);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][37], 1);
    
    GarageTD[playerid][38] = CreatePlayerTextDraw(playerid, 475.0, 325.0, "SAU");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][38], 0.250, 1.000);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][38], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][38], 2);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][38], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][38], 1);
    PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][38], 0x00000000);
    PlayerTextDrawColor(playerid, GarageTD[playerid][38], 0xFFFFFFFF);
    PlayerTextDrawSetProportional(playerid, GarageTD[playerid][38], 1);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][38], 0);
    
    // Page info
    GarageTD[playerid][39] = CreatePlayerTextDraw(playerid, 320.0, 325.0, "Trang 1/1");
    PlayerTextDrawLetterSize(playerid, GarageTD[playerid][39], 0.220, 1.000);
    PlayerTextDrawAlignment(playerid, GarageTD[playerid][39], 2);
    PlayerTextDrawFont(playerid, GarageTD[playerid][39], 1);
    PlayerTextDrawSetShadow(playerid, GarageTD[playerid][39], 1);
    PlayerTextDrawSetOutline(playerid, GarageTD[playerid][39], 1);
    PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][39], 0x00000000);
    PlayerTextDrawColor(playerid, GarageTD[playerid][39], 0xFFFFFFFF);
    PlayerTextDrawSetProportional(playerid, GarageTD[playerid][39], 1);
    PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][39], 0);
    
    return 1;
}

// Comprehensive vehicle sync function
stock SyncVehicleSystem(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid}) return 0;
    
    // Prevent multiple syncs at once
    if(g_PlayerSyncInProgress[playerid]) {
        g_PlayerSyncAttempts[playerid]++;
        if(g_PlayerSyncAttempts[playerid] > 3) {
            g_PlayerSyncInProgress[playerid] = false;
            g_PlayerSyncAttempts[playerid] = 0;
        }
        return 0;
    }
    
    g_PlayerSyncInProgress[playerid] = true;
    g_PlayerSyncAttempts[playerid] = 0;
    
    // Step 1: Validate all vehicle data
    ValidateAllVehicleData(playerid);
    
    // Step 2: Fix any sync errors
    FixVehicleSyncErrors(playerid);
    
    // Step 3: Update vehicle status
    UpdateVehicleStatus(playerid);
    
    // Step 4: Force database sync if needed
    ForceDatabaseSync(playerid);
    
    g_PlayerSyncInProgress[playerid] = false;
    
    return 1;
}

// Validate all vehicle data for a player
stock ValidateAllVehicleData(playerid)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        // Additional bounds checking for array access
        if(i >= 0 && i < MAX_PLAYERVEHICLES) {
            // Check if vehicle data is consistent
            if(PlayerVehicleInfo[playerid][i][pvModelId] != 0) {
                // Vehicle exists, validate its data
                if(PlayerVehicleInfo[playerid][i][pvModelId] < 400 || PlayerVehicleInfo[playerid][i][pvModelId] > 611) {
                    // Invalid model ID, reset vehicle
                    ResetVehicleSlot(playerid, i);
                    continue;
                }
                
                // Check if spawned vehicle actually exists
                if(PlayerVehicleInfo[playerid][i][pvSpawned] == 1) {
                    new vehicleid = PlayerVehicleInfo[playerid][i][pvId];
                    if(vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid)) {
                        // Vehicle marked as spawned but doesn't exist
                        PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
                        PlayerVehicleInfo[playerid][i][pvId] = INVALID_VEHICLE_ID;
                    } else if(vehicleid >= 0 && vehicleid < MAX_VEHICLES) {
                        // FIX FOR ARRAY BOUNDS ERROR - Check DynVeh array safely
                        if(DynVeh[vehicleid] != -1 && !IsValidVehicle(vehicleid)) {
                            // Vehicle exists in DynVeh but not in game, clean up
                            DynVeh[vehicleid] = -1;
                        }
                    }
                }
            }
        }
    }
    
    return 1;
}

// Reset a vehicle slot to empty state - WITH ARRAY BOUNDS FIX
stock ResetVehicleSlot(playerid, slot)
{
    if(!IsPlayerConnected(playerid) || slot < 0 || slot >= MAX_PLAYERVEHICLES) return 0;
    
    // Destroy vehicle if it exists
    new vehicleid = PlayerVehicleInfo[playerid][slot][pvId];
    if(vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid)) {
        DestroyVehicle(vehicleid);
        
        // FIX FOR ARRAY BOUNDS ERROR - Safe DynVeh cleanup
        if(vehicleid >= 0 && vehicleid < MAX_VEHICLES) {
            if(DynVeh[vehicleid] != -1) {
                DynVeh[vehicleid] = -1;
            }
        }
    }
    
    // Reset all vehicle data
    PlayerVehicleInfo[playerid][slot][pvModelId] = 0;
    PlayerVehicleInfo[playerid][slot][pvId] = INVALID_VEHICLE_ID;
    PlayerVehicleInfo[playerid][slot][pvSpawned] = 0;
    PlayerVehicleInfo[playerid][slot][pvPosX] = 0.0;
    PlayerVehicleInfo[playerid][slot][pvPosY] = 0.0;
    PlayerVehicleInfo[playerid][slot][pvPosZ] = 0.0;
    PlayerVehicleInfo[playerid][slot][pvPosAngle] = 0.0;
    PlayerVehicleInfo[playerid][slot][pvHealth] = 1000.0;
    PlayerVehicleInfo[playerid][slot][pvFuel] = 100.0;
    PlayerVehicleInfo[playerid][slot][pvImpounded] = 0;
    PlayerVehicleInfo[playerid][slot][pvSlotId] = 0;
    
    return 1;
}

// Update vehicle status for all vehicles
stock UpdateVehicleStatus(playerid)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        // Additional bounds checking for array access
        if(i >= 0 && i < MAX_PLAYERVEHICLES) {
            if(PlayerVehicleInfo[playerid][i][pvModelId] != 0) {
                // Update vehicle status based on current state
                new vehicleid = PlayerVehicleInfo[playerid][i][pvId];
                if(vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid)) {
                    PlayerVehicleInfo[playerid][i][pvSpawned] = 1;
                } else {
                    PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
                }
            }
        }
    }
    
    return 1;
}

// Force database synchronization
stock ForceDatabaseSync(playerid)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    // Save all vehicle data to database
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        // Additional bounds checking for array access
        if(i >= 0 && i < MAX_PLAYERVEHICLES) {
            if(PlayerVehicleInfo[playerid][i][pvModelId] != 0) {
                g_mysql_SaveVehicle(playerid, i);
            }
        }
    }
    
    return 1;
}

// Safe TextDraw creation function
stock PlayerText:SafeCreatePlayerTextDraw(playerid, Float:x, Float:y, const string[])
{
    if(!IsPlayerConnected(playerid)) return PlayerText:INVALID_TEXT_DRAW;
    
    new PlayerText:textdraw = CreatePlayerTextDraw(playerid, x, y, string);
    
    // Validate the created TextDraw
    if(textdraw == PlayerText:INVALID_TEXT_DRAW) {
        return PlayerText:INVALID_TEXT_DRAW;
    }
    
    return textdraw;
}

// Safe TextDraw destruction function
stock SafeDestroyPlayerTextDraw(playerid, &PlayerText:textdraw)
{
    // For disconnect case, we don't check IsPlayerConnected since player is disconnecting
    if(textdraw != PlayerText:INVALID_TEXT_DRAW) {
        // Additional safety check for TextDraw handle and player ID
        if(playerid >= 0 && playerid < MAX_PLAYERS && _:textdraw > 0 && _:textdraw < 65535) {
            PlayerTextDrawDestroy(playerid, textdraw);
        }
        textdraw = PlayerText:INVALID_TEXT_DRAW;
        return 1;
    }
    
    return 0;
}

// Safe TextDraw show function
stock SafeShowPlayerTextDraw(playerid, PlayerText:textdraw)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    if(textdraw != PlayerText:INVALID_TEXT_DRAW) {
        if(_:textdraw > 0 && _:textdraw < 65535) {
            PlayerTextDrawShow(playerid, textdraw);
            return 1;
        }
    }
    
    return 0;
}

// Safe TextDraw hide function
stock SafeHidePlayerTextDraw(playerid, PlayerText:textdraw)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    if(textdraw != PlayerText:INVALID_TEXT_DRAW) {
        if(_:textdraw > 0 && _:textdraw < 65535) {
            PlayerTextDrawHide(playerid, textdraw);
            return 1;
        }
    }
    
    return 0;
}

// Destroy TextDraw for a player
stock DestroyGarageTextDraws(playerid)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    // Destroy all TextDraws using safe functions
    for(new i = 0; i < 40; i++) {
        SafeDestroyPlayerTextDraw(playerid, GarageTD[playerid][i]);
    }
    
    g_GarageTextDrawShown[playerid] = false;
    g_GarageSelectedVehicle[playerid] = -1;
    g_GarageCurrentPage[playerid] = 0;
    g_GarageTotalPages[playerid] = 0;
    
    return 1;
}

// Show garage TextDraw interface - OPTIMIZED
stock ShowGarageTextDraw(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid} || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    // Create TextDraws if not created
    if(!g_GarageTextDrawShown[playerid]) {
        CreateGarageTextDraws(playerid);
    }
    
    // Reset pagination
    g_GarageCurrentPage[playerid] = 0;
    g_GarageSelectedVehicle[playerid] = -1;
    
    // Update vehicle list first
    UpdateGarageVehicleList(playerid);
    
    // Show all static TextDraws using safe functions
    for(new i = 0; i < 8; i++) {
        SafeShowPlayerTextDraw(playerid, GarageTD[playerid][i]);
    }
    
    // Show button background and close button only
    SafeShowPlayerTextDraw(playerid, GarageTD[playerid][28]);
    SafeShowPlayerTextDraw(playerid, GarageTD[playerid][33]);
    SafeShowPlayerTextDraw(playerid, GarageTD[playerid][34]);
    
    // Hide action buttons initially (TAKE OUT and PARK)
    HideAllActionButtons(playerid);
    
    // Show pagination buttons
    for(new i = 35; i <= 39; i++) {
        SafeShowPlayerTextDraw(playerid, GarageTD[playerid][i]);
    }
    
    g_GarageTextDrawShown[playerid] = true;
    
    // Update status
    PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "Chon xe de quan ly");
    
    // Enable mouse cursor for TextDraw interaction
    SelectTextDraw(playerid, 0xFFFFFFFF);
    
    return 1;
}

// Hide garage TextDraw interface
stock HideGarageTextDraw(playerid)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    // Hide all static TextDraws using safe functions
    for(new i = 0; i < 8; i++) {
        SafeHidePlayerTextDraw(playerid, GarageTD[playerid][i]);
    }
    
    // Hide button TextDraws
    for(new i = 28; i <= 34; i++) {
        SafeHidePlayerTextDraw(playerid, GarageTD[playerid][i]);
    }
    
    // Hide vehicle list TextDraws
    for(new i = 0; i < 5; i++) {
        SafeHidePlayerTextDraw(playerid, GarageTD[playerid][8 + i]);
        SafeHidePlayerTextDraw(playerid, GarageTD[playerid][18 + i]);
    }
    
    // Hide pagination buttons
    for(new i = 35; i <= 39; i++) {
        SafeHidePlayerTextDraw(playerid, GarageTD[playerid][i]);
    }
    
    g_GarageTextDrawShown[playerid] = false;
    g_GarageSelectedVehicle[playerid] = -1;
    g_GarageCurrentPage[playerid] = 0;
    
    // Disable mouse cursor
    CancelSelectTextDraw(playerid);
    
    return 1;
}

// Update vehicle list in TextDraw - OPTIMIZED FOR SPEED
stock UpdateGarageVehicleList(playerid)
{
    if(!IsPlayerConnected(playerid) || playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    
    new count = 0;
    new vehicleSlots[MAX_PLAYERVEHICLES];  // Use MAX_PLAYERVEHICLES instead of 10
    
    // Get all valid vehicle slots - OPTIMIZED
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        if(PlayerVehicleInfo[playerid][i][pvModelId] != 0) {
            vehicleSlots[count] = i;
            count++;
        }
    }
    
    // Calculate pagination
    g_GarageTotalPages[playerid] = (count + 5 - 1) / 5;
    if(g_GarageTotalPages[playerid] == 0) g_GarageTotalPages[playerid] = 1;
    
    // Ensure current page is valid
    if(g_GarageCurrentPage[playerid] >= g_GarageTotalPages[playerid]) {
        g_GarageCurrentPage[playerid] = g_GarageTotalPages[playerid] - 1;
    }
    if(g_GarageCurrentPage[playerid] < 0) g_GarageCurrentPage[playerid] = 0;
    
    // Update page info - OPTIMIZED
    new pageInfo[32];
    format(pageInfo, sizeof(pageInfo), "Trang %d/%d", g_GarageCurrentPage[playerid] + 1, g_GarageTotalPages[playerid]);
    PlayerTextDrawSetString(playerid, GarageTD[playerid][39], pageInfo);
    
    // Destroy existing vehicle TextDraws first - OPTIMIZED
    for(new i = 0; i < 5; i++) {
        if(GarageTD[playerid][8 + i] != PlayerText:INVALID_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, GarageTD[playerid][8 + i]);
            GarageTD[playerid][8 + i] = PlayerText:INVALID_TEXT_DRAW;
        }
        if(GarageTD[playerid][18 + i] != PlayerText:INVALID_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, GarageTD[playerid][18 + i]);
            GarageTD[playerid][18 + i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    
    // Create TextDraws only for vehicles that exist - OPTIMIZED
    if(count == 0) {
        // No vehicles - create one slot to show message
        new Float:posX = 140.0;
        new Float:posY = 185.0;
        
        // Vehicle item background
        GarageTD[playerid][8] = CreatePlayerTextDraw(playerid, posX, posY, "LD_BUM:blkdot");
        if(GarageTD[playerid][8] != PlayerText:INVALID_TEXT_DRAW) {
            PlayerTextDrawTextSize(playerid, GarageTD[playerid][8], 360.0, 20.0);
            PlayerTextDrawAlignment(playerid, GarageTD[playerid][8], 1);
            PlayerTextDrawColor(playerid, GarageTD[playerid][8], 0x33333388);
            PlayerTextDrawFont(playerid, GarageTD[playerid][8], 4);
            PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][8], 0);
            PlayerTextDrawShow(playerid, GarageTD[playerid][8]);
        }
        
        // Vehicle item text
        GarageTD[playerid][18] = CreatePlayerTextDraw(playerid, posX + 5.0, posY + 2.0, "~r~Khong co xe nao");
        if(GarageTD[playerid][18] != PlayerText:INVALID_TEXT_DRAW) {
            PlayerTextDrawLetterSize(playerid, GarageTD[playerid][18], 0.240, 1.000);
            PlayerTextDrawAlignment(playerid, GarageTD[playerid][18], 1);
            PlayerTextDrawFont(playerid, GarageTD[playerid][18], 1);
            PlayerTextDrawSetShadow(playerid, GarageTD[playerid][18], 1);
            PlayerTextDrawSetOutline(playerid, GarageTD[playerid][18], 1);
            PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][18], 0x00000000);
            PlayerTextDrawColor(playerid, GarageTD[playerid][18], 0xFFFFFFFF);
            PlayerTextDrawSetProportional(playerid, GarageTD[playerid][18], 1);
            PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][18], 0);
            PlayerTextDrawShow(playerid, GarageTD[playerid][18]);
        }
        
        // Hide all action buttons when no vehicles
        HideAllActionButtons(playerid);
    } else {
        // Calculate start and end indices for current page - OPTIMIZED
        new startIndex = g_GarageCurrentPage[playerid] * 5;
        new endIndex = startIndex + 5;
        if(endIndex > count) endIndex = count;
        
        new vehiclesOnThisPage = endIndex - startIndex;
        
        // Create TextDraws for vehicles on current page - OPTIMIZED
        for(new i = 0; i < vehiclesOnThisPage && i < 5; i++) {
            new actualIndex = startIndex + i;
            new slot = vehicleSlots[actualIndex];
            new vehicleName[32];
            Model_GetName(PlayerVehicleInfo[playerid][slot][pvModelId], vehicleName);
            
            new status = GetVehicleStatus(INVALID_VEHICLE_ID, playerid, slot);
            new statusText[32];
            
            switch(status) {
                case 1: statusText = "~g~[Trong Garage]";
                case 2: statusText = "~y~[Ben ngoai]";
                case 3: statusText = "~r~[DMV]";
                default: statusText = "~w~[Khong xac dinh]";
            }
            
            new displayText[128];
            format(displayText, sizeof(displayText), "%d. %s %s", actualIndex + 1, vehicleName, statusText);
            
            new Float:posX = 140.0;
            new Float:posY = 185.0 + (i * 25.0);
            
            // Vehicle item background - OPTIMIZED
            GarageTD[playerid][8 + i] = CreatePlayerTextDraw(playerid, posX, posY, "LD_BUM:blkdot");
            if(GarageTD[playerid][8 + i] != PlayerText:INVALID_TEXT_DRAW) {
                PlayerTextDrawTextSize(playerid, GarageTD[playerid][8 + i], 360.0, 20.0);
                PlayerTextDrawAlignment(playerid, GarageTD[playerid][8 + i], 1);
                PlayerTextDrawColor(playerid, GarageTD[playerid][8 + i], 0x33333388);
                PlayerTextDrawFont(playerid, GarageTD[playerid][8 + i], 4);
                PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][8 + i], 1);
                PlayerTextDrawShow(playerid, GarageTD[playerid][8 + i]);
            }
            
            // Vehicle item text - OPTIMIZED
            GarageTD[playerid][18 + i] = CreatePlayerTextDraw(playerid, posX + 5.0, posY + 2.0, displayText);
            if(GarageTD[playerid][18 + i] != PlayerText:INVALID_TEXT_DRAW) {
                PlayerTextDrawLetterSize(playerid, GarageTD[playerid][18 + i], 0.240, 1.000);
                PlayerTextDrawAlignment(playerid, GarageTD[playerid][18 + i], 1);
                PlayerTextDrawFont(playerid, GarageTD[playerid][18 + i], 1);
                PlayerTextDrawSetShadow(playerid, GarageTD[playerid][18 + i], 1);
                PlayerTextDrawSetOutline(playerid, GarageTD[playerid][18 + i], 1);
                PlayerTextDrawBackgroundColor(playerid, GarageTD[playerid][18 + i], 0x00000000);
                PlayerTextDrawColor(playerid, GarageTD[playerid][18 + i], 0xFFFFFFFF);
                PlayerTextDrawSetProportional(playerid, GarageTD[playerid][18 + i], 1);
                PlayerTextDrawSetSelectable(playerid, GarageTD[playerid][18 + i], 0);
                PlayerTextDrawShow(playerid, GarageTD[playerid][18 + i]);
            }
        }
        
        // Update pagination button visibility - OPTIMIZED
        UpdatePaginationButtons(playerid);
    }
    
    return 1;
}

// Hide all action buttons (TAKE OUT and PARK) - OPTIMIZED
stock HideAllActionButtons(playerid)
{
    // Hide TAKE OUT button
    PlayerTextDrawHide(playerid, GarageTD[playerid][29]);
    PlayerTextDrawHide(playerid, GarageTD[playerid][30]);
    
    // Hide PARK button
    PlayerTextDrawHide(playerid, GarageTD[playerid][31]);
    PlayerTextDrawHide(playerid, GarageTD[playerid][32]);
}

// Show action buttons based on selected vehicle status - OPTIMIZED
stock ShowActionButtons(playerid, slot)
{
    if(slot == -1) {
        HideAllActionButtons(playerid);
        return;
    }
    
    new status = GetVehicleStatus(INVALID_VEHICLE_ID, playerid, slot);
    
    // Show TAKE OUT button only if vehicle is in garage
    if(status == 1) {
        PlayerTextDrawShow(playerid, GarageTD[playerid][29]);
        PlayerTextDrawShow(playerid, GarageTD[playerid][30]);
        
        // Hide PARK button
        PlayerTextDrawHide(playerid, GarageTD[playerid][31]);
        PlayerTextDrawHide(playerid, GarageTD[playerid][32]);
    }
    // Show PARK button only if vehicle is outside
    else if(status == 2) {
        // Hide TAKE OUT button
        PlayerTextDrawHide(playerid, GarageTD[playerid][29]);
        PlayerTextDrawHide(playerid, GarageTD[playerid][30]);
        
        PlayerTextDrawShow(playerid, GarageTD[playerid][31]);
        PlayerTextDrawShow(playerid, GarageTD[playerid][32]);
    }
    // Hide both buttons if vehicle is impounded or invalid status
    else {
        HideAllActionButtons(playerid);
    }
}

// Update pagination button visibility - OPTIMIZED
stock UpdatePaginationButtons(playerid)
{
    // Show/hide previous page button
    if(g_GarageCurrentPage[playerid] > 0) {
        PlayerTextDrawShow(playerid, GarageTD[playerid][35]);
        PlayerTextDrawShow(playerid, GarageTD[playerid][36]);
    } else {
        PlayerTextDrawHide(playerid, GarageTD[playerid][35]);
        PlayerTextDrawHide(playerid, GarageTD[playerid][36]);
    }
    
    // Show/hide next page button
    if(g_GarageCurrentPage[playerid] < g_GarageTotalPages[playerid] - 1) {
        PlayerTextDrawShow(playerid, GarageTD[playerid][37]);
        PlayerTextDrawShow(playerid, GarageTD[playerid][38]);
    } else {
        PlayerTextDrawHide(playerid, GarageTD[playerid][37]);
        PlayerTextDrawHide(playerid, GarageTD[playerid][38]);
    }
}

// Handle TextDraw click
stock HandleGarageTextDrawClick(playerid, PlayerText:clickedid)
{
    if(!IsPlayerConnected(playerid) || !g_GarageTextDrawShown[playerid]) return 0;
    
    // Get count of valid vehicles first
    new count = 0;
    new vehicleSlots[MAX_PLAYERVEHICLES];
    
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        if(IsValidVehicleData(playerid, i) && !IsVehicleRemoved(playerid, i)) {
            vehicleSlots[count] = i;
            count++;
        }
    }
    
    // Calculate current page range
    new startIndex = g_GarageCurrentPage[playerid] * 5;
    new endIndex = startIndex + 5;
    if(endIndex > count) endIndex = count;
    
    // Check vehicle list clicks - only for visible slots on current page
    for(new i = 0; i < (endIndex - startIndex) && i < 5; i++) {
        if(GarageTD[playerid][8 + i] != PlayerText:INVALID_TEXT_DRAW) {
            if(clickedid == GarageTD[playerid][8 + i]) {
                SelectGarageVehicle(playerid, startIndex + i);
                return 1;
            }
        }
    }
    
    // Check button clicks
    if(clickedid == GarageTD[playerid][29]) {
        HandleTakeOutButton(playerid);
        return 1;
    }
    
    if(clickedid == GarageTD[playerid][31]) {
        HandleParkButton(playerid);
        return 1;
    }
    
    if(clickedid == GarageTD[playerid][33]) {
        HideGarageTextDraw(playerid);
        return 1;
    }
    
    // Check pagination buttons
    if(clickedid == GarageTD[playerid][35]) {
        if(g_GarageCurrentPage[playerid] > 0) {
            g_GarageCurrentPage[playerid]--;
            g_GarageSelectedVehicle[playerid] = -1;
            UpdateGarageVehicleList(playerid);
        }
        return 1;
    }
    
    if(clickedid == GarageTD[playerid][37]) {
        if(g_GarageCurrentPage[playerid] < g_GarageTotalPages[playerid] - 1) {
            g_GarageCurrentPage[playerid]++;
            g_GarageSelectedVehicle[playerid] = -1;
            UpdateGarageVehicleList(playerid);
        }
        return 1;
    }
    
    return 0;
}

// Select a vehicle in the TextDraw interface - OPTIMIZED
stock SelectGarageVehicle(playerid, listIndex)
{
    if(!IsPlayerConnected(playerid)) return 0;
    
    new count = 0;
    new vehicleSlots[MAX_PLAYERVEHICLES];
    
    // Get valid vehicle slots - OPTIMIZED
    for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
        if(PlayerVehicleInfo[playerid][i][pvModelId] != 0) {
            vehicleSlots[count] = i;
            count++;
        }
    }
    
    if(listIndex >= count) return 0;
    
    g_GarageSelectedVehicle[playerid] = vehicleSlots[listIndex];
    
    // Update status text - OPTIMIZED
    new vehicleName[32];
    Model_GetName(PlayerVehicleInfo[playerid][vehicleSlots[listIndex]][pvModelId], vehicleName);
    new statusText[128];
    format(statusText, sizeof(statusText), "Da chon: %s", vehicleName);
    PlayerTextDrawSetString(playerid, GarageTD[playerid][5], statusText);
    
    // Show appropriate action buttons based on vehicle status - OPTIMIZED
    ShowActionButtons(playerid, vehicleSlots[listIndex]);
    
    // Highlight selected vehicle - OPTIMIZED
    new startIndex = g_GarageCurrentPage[playerid] * 5;
    new endIndex = startIndex + 5;
    if(endIndex > count) endIndex = count;
    
    for(new i = 0; i < (endIndex - startIndex) && i < 5; i++) {
        if(GarageTD[playerid][8 + i] != PlayerText:INVALID_TEXT_DRAW) {
            if(startIndex + i == listIndex) {
                PlayerTextDrawColor(playerid, GarageTD[playerid][8 + i], 0x4CAF50FF);
            } else {
                PlayerTextDrawColor(playerid, GarageTD[playerid][8 + i], 0x33333388);
            }
            PlayerTextDrawShow(playerid, GarageTD[playerid][8 + i]);
        }
    }
    
    return 1;
}

// Handle Take Out button click
stock HandleTakeOutButton(playerid)
{
    if(g_GarageSelectedVehicle[playerid] == -1) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Vui long chon xe truoc!");
        return 0;
    }
    
    new slot = g_GarageSelectedVehicle[playerid];
    new status = GetVehicleStatus(INVALID_VEHICLE_ID, playerid, slot);
    
    if(status != 1) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Xe khong o trong garage!");
        return 0;
    }
    
    // Take out the vehicle
    if(TakeOutVehicle(playerid, slot)) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~g~Lay xe thanh cong!");
        
        // Hide TextDraw immediately after successful action
        HideGarageTextDraw(playerid);
    } else {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Khong the lay xe!");
    }
    
    return 1;
}

// Handle Park button click
stock HandleParkButton(playerid)
{
    if(g_GarageSelectedVehicle[playerid] == -1) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Vui long chon xe truoc!");
        return 0;
    }
    
    new slot = g_GarageSelectedVehicle[playerid];
    new status = GetVehicleStatus(INVALID_VEHICLE_ID, playerid, slot);
    
    if(status != 2) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Xe khong o ben ngoai!");
        return 0;
    }
    
    // Get the vehicle ID from the selected slot
    new vehicleid = PlayerVehicleInfo[playerid][slot][pvId];
    
    if(vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid)) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Xe khong ton tai!");
        return 0;
    }
    
    // Check if vehicle is in a parking spot - improved logic
    new spot;
    new bool:foundSpot = false;
    
    // Check all garages for parking spots
    for(new garageID = 0; garageID < GarageCount; garageID++) {
        if(GarageData[garageID][g_Active]) {
            if(IsVehicleInGarageParkingSpot(vehicleid, garageID, spot)) {
                foundSpot = true;
                break;
            }
        }
    }
    
    if(!foundSpot) {
        // Debug: Get vehicle position and show distances to all parking spots
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(vehicleid, vx, vy, vz);
        
        new debugMsg[256];
        format(debugMsg, sizeof(debugMsg), "~r~Xe phai o vi tri dau xe! (X:%.1f Y:%.1f Z:%.1f)", vx, vy, vz);
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], debugMsg);
        
        return 0;
    }
    
    // Park the vehicle
    if(GarageParkVehicle(playerid, vehicleid, slot)) {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~g~Cat xe thanh cong!");
        
        // Hide TextDraw immediately after successful action
        HideGarageTextDraw(playerid);
    } else {
        PlayerTextDrawSetString(playerid, GarageTD[playerid][5], "~r~Khong the cat xe!");
    }
    
    return 1;
}



// ==================== ADMIN COMMANDS ====================

// Admin command to manage garage
CMD:garagemanage(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 4) {
        SendClientMessageEx(playerid, COLOR_GRAD2, "Ban khong co quyen su dung lenh nay!");
        return 1;
    }
    
    new option[32];
    if(sscanf(params, "s[32]", option)) {
        SendClientMessageEx(playerid, COLOR_GRAD2, "SU DUNG: /garagemanage [option]");
        SendClientMessageEx(playerid, COLOR_GRAD2, "OPTIONS: stats, forcepark, list");
        return 1;
    }
    
    if(strcmp(option, "stats", true) == 0) {
        // Show garage statistics
        new totalVehicles = 0, inGarage = 0, outside = 0, impounded = 0;
        
        foreach(new i: Player) {
            // Strict bounds checking to prevent array access errors
            if(i >= 0 && i < MAX_PLAYERS && IsPlayerConnected(i) && gPlayerLogged{i}) {
                for(new j = 0; j < MAX_PLAYERVEHICLES; j++) {
                    // Additional bounds checking for array access
                    if(j >= 0 && j < MAX_PLAYERVEHICLES) {
                        // Additional safety check before accessing PlayerVehicleInfo
                        if(i >= 0 && i < MAX_PLAYERS && j >= 0 && j < MAX_PLAYERVEHICLES) {
                            if(PlayerVehicleInfo[i][j][pvModelId] != 0) {
                                totalVehicles++;
                                
                                new status = GetVehicleStatus(INVALID_VEHICLE_ID, i, j);
                                switch(status) {
                                    case 1: inGarage++;
                                    case 2: outside++;
                                    case 3: impounded++;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        new statsMsg[256];
        format(statsMsg, sizeof(statsMsg), "GARAGE STATS: Tong xe: %d | Trong garage: %d | Ben ngoai: %d | DMV: %d", 
            totalVehicles, inGarage, outside, impounded);
        SendClientMessageEx(playerid, COLOR_GRAD2, statsMsg);
    }
    else if(strcmp(option, "forcepark", true) == 0) {
        // Force park all spawned vehicles
        new parkedCount = 0;
        
        foreach(new i: Player) {
            // Strict bounds checking to prevent array access errors
            if(i >= 0 && i < MAX_PLAYERS && IsPlayerConnected(i) && gPlayerLogged{i}) {
                for(new j = 0; j < MAX_PLAYERVEHICLES; j++) {
                    // Additional bounds checking for array access
                    if(j >= 0 && j < MAX_PLAYERVEHICLES) {
                        // Additional safety check before accessing PlayerVehicleInfo
                        if(i >= 0 && i < MAX_PLAYERS && j >= 0 && j < MAX_PLAYERVEHICLES) {
                            if(PlayerVehicleInfo[i][j][pvSpawned] == 1) {
                                new vehicleid = PlayerVehicleInfo[i][j][pvId];
                                if(vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid)) {
                                    if(GarageParkVehicle(i, vehicleid, j)) {
                                        parkedCount++;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        new parkMsg[128];
        format(parkMsg, sizeof(parkMsg), "Da cat %d xe vao garage.", parkedCount);
        SendClientMessageEx(playerid, COLOR_GRAD2, parkMsg);
    }
    else if(strcmp(option, "list", true) == 0) {
        // List all vehicles in storage
        SendClientMessageEx(playerid, COLOR_GRAD2, "=== DANH SACH XE TRONG GARAGE ===");
        
        foreach(new i: Player) {
            // Strict bounds checking to prevent array access errors
            if(i >= 0 && i < MAX_PLAYERS && IsPlayerConnected(i) && gPlayerLogged{i}) {
                new playerVehicles = 0;
                for(new j = 0; j < MAX_PLAYERVEHICLES; j++) {
                    // Additional bounds checking for array access
                    if(j >= 0 && j < MAX_PLAYERVEHICLES) {
                        // Additional safety check before accessing PlayerVehicleInfo
                        if(i >= 0 && i < MAX_PLAYERS && j >= 0 && j < MAX_PLAYERVEHICLES) {
                            if(PlayerVehicleInfo[i][j][pvModelId] != 0) {
                                playerVehicles++;
                            }
                        }
                    }
                }
                
                if(playerVehicles > 0) {
                    new listMsg[128];
                    format(listMsg, sizeof(listMsg), "%s: %d xe", GetPlayerNameEx(i), playerVehicles);
                    SendClientMessageEx(playerid, COLOR_GRAD2, listMsg);
                }
            }
        }
    }
    else {
        SendClientMessageEx(playerid, COLOR_GRAD2, "SU DUNG: /garagemanage [option]");
        SendClientMessageEx(playerid, COLOR_GRAD2, "OPTIONS: stats, forcepark, list");
    }
    
    return 1;
}

// Show garage dialog (redirects to TextDraw interface)
stock ShowGarageDialog(playerid)
{
    if(!IsPlayerConnected(playerid) || !gPlayerLogged{playerid}) return 0;
    
    // Show TextDraw interface instead of dialog
    ShowGarageTextDraw(playerid);
    
    return 1;
}

stock IsValidVehicleIDForArray(vehicleid)
{
    if(vehicleid == INVALID_VEHICLE_ID) return false;
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return false;
    return true;
}

stock GetDynVehID(vehicleid)
{
    if(!IsValidVehicleIDForArray(vehicleid)) return -1;
    return DynVeh[vehicleid];
}

stock SetDynVehID(vehicleid, value)
{
    if(!IsValidVehicleIDForArray(vehicleid)) return 0;
    DynVeh[vehicleid] = value;
    return 1;
}

stock SafeDynVehAccess(vehicleid)
{
    if(vehicleid == INVALID_VEHICLE_ID) return -1;
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return -1;
    return DynVeh[vehicleid];
}

// Deferred garage cleanup to prevent disconnect timeout
forward DeferredGarageCleanup(playerid);
public DeferredGarageCleanup(playerid) {
    if(!IsValidPlayerID(playerid)) return 0;
    
    // Cleanup TextDraws
    for(new i = 0; i < 40; i++) {
        if(GarageTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, GarageTD[playerid][i]);
            GarageTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    
    // Cleanup vehicle data
    if(playerid >= 0 && playerid < MAX_PLAYERS) {
        for(new i = 0; i < MAX_PLAYERVEHICLES; i++) {
            if(PlayerVehicleInfo[playerid][i][pvId] == INVALID_VEHICLE_ID) {
                PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
            }
            if(PlayerVehicleInfo[playerid][i][pvId] != INVALID_VEHICLE_ID && 
               PlayerVehicleInfo[playerid][i][pvId] >= 0 && 
               PlayerVehicleInfo[playerid][i][pvId] < MAX_VEHICLES) {
                if(DynVeh[PlayerVehicleInfo[playerid][i][pvId]] != -1) {
                    DynVeh[PlayerVehicleInfo[playerid][i][pvId]] = -1;
                }
            } else if(PlayerVehicleInfo[playerid][i][pvId] == INVALID_VEHICLE_ID) {
                PlayerVehicleInfo[playerid][i][pvSpawned] = 0;
            }
        }
    }
    
    return 1;
}



