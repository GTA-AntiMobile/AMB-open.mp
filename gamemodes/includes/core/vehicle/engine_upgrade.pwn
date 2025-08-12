#include <YSI\YSI_Coding\y_hooks>

#define MAX_ENGINE_LEVEL 5
#define UPGRADE_DIALOG_ID 8000
#define ENGINE_INFO_DIALOG_ID 8001
#define MECHANIC_PICKUP_ID 1239
#define ENGINE_NORMAL_TEMP 80.0

new const EngineUpgradeCosts[MAX_ENGINE_LEVEL + 1] = {
    0, 75000, 180000, 420000, 850000, 1750000
};

new const Float:EngineSpeedMultiplier[MAX_ENGINE_LEVEL + 1] = {
    1.0, 1.03, 1.06, 1.10, 1.14, 1.18
};

new const Float:EngineAcceleration[MAX_ENGINE_LEVEL + 1] = {
    1.0, 1.02, 1.04, 1.07, 1.10, 1.14
};

new const EngineUpgradeNames[][40] = {
    "Dong Co Goc",
    "Stage 1 - Performance Kit",
    "Stage 2 - Sport Tuning", 
    "Stage 3 - Racing Setup",
    "Stage 4 - Pro Performance",
    "Stage 5 - Ultimate Power"
};

new const EngineUpgradeDesc[][60] = {
    "Dong co tieu chuan tu nha san xuat",
    "Nang cap co ban: ECU remap, air filter",
    "Nang cap the thao: turbo kit, exhaust sport",
    "Thiet lap dua: big turbo, racing injector",
    "Hieu suat cao: twin turbo, racing fuel",
    "Suc manh toi da: full race setup, NOS"
};

enum E_VEHICLE_ENGINE_DATA
{
    engine_VehicleID,
    engine_Level,           // Được thay thế bởi PlayerVehicleInfo[pvEngineUpgrade]
    Float:engine_Health,    // Không sử dụng, dùng vehicle health
    engine_LastMaintenance, // Không sử dụng
    engine_TotalDistance,   // Không sử dụng
    engine_Durability,      // Không sử dụng
    engine_LastUpdate       // Không sử dụng
}

enum E_VEHICLE_CLASS
{
    VEHICLE_CLASS_UNKNOWN,
    VEHICLE_CLASS_COMPACT,      // Xe nhỏ
    VEHICLE_CLASS_SEDAN,        // Xe sedan
    VEHICLE_CLASS_SUV,          // SUV
    VEHICLE_CLASS_SPORTS,       // Xe thể thao
    VEHICLE_CLASS_SUPER,        // Siêu xe
    VEHICLE_CLASS_BIKE,         // Xe mô tô
    VEHICLE_CLASS_TRUCK,        // Xe tải
    VEHICLE_CLASS_INDUSTRIAL    // Xe công nghiệp
}

new const Float:VehicleClassSpeedLimits[] = {
    160.0,  // Unknown
    140.0,  // Compact cars
    155.0,  // Sedan
    150.0,  // SUV
    180.0,  // Sports cars
    220.0,  // Super cars
    165.0,  // Motorcycles
    120.0,  // Trucks
    100.0   // Industrial
};

new PlayerNearMechanic[MAX_PLAYERS];
new PlayerEngineUpgradeVehicle[MAX_PLAYERS];

new Float:MechanicLocations[][4] = {
    {-2058.7, -2460.5, 30.6, 0.0},
    {1608.7, -1894.5, 13.5, 90.0},
    {-1420.5, 2584.2, 55.8, 180.0},
    {-2427.6, 1346.3, 7.1, 270.0},
    {2387.3, 1044.5, 10.8, 0.0},
    {-1904.8, 284.5, 41.0, 180.0}
};

new const MechanicNames[][40] = {
    "LS Airport Garage",
    "Downtown Tuning Shop", 
    "LV Performance Center",
    "SF Racing Garage",
    "LV East Side Garage",
    "SF Doherty Garage"
};

stock GetVehicleOwnerAndSlot(vehicleid, &ownerid, &slot)
{
    ownerid = INVALID_PLAYER_ID;
    slot = -1;
    
    for(new i = 0; i < MAX_PLAYERS; i++) {
        for(new v = 0; v < MAX_PLAYERVEHICLES; v++) {
            if(PlayerVehicleInfo[i][v][pvId] == vehicleid) {
                ownerid = i;
                slot = v;
                return 1;
            }
        }
    }
    return 0;
}

stock GetVehicleEngineLevel(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    
    new ownerid, slot;
    if(GetVehicleOwnerAndSlot(vehicleid, ownerid, slot)) {
        return PlayerVehicleInfo[ownerid][slot][pvEngineUpgrade];
    }
    return 0; 
}

stock E_VEHICLE_CLASS:GetVehicleClass(modelid)
{
    // Super cars
    new const superCars[] = {411, 506, 451, 541, 415, 429, 480, 602, 560, 565, 558, 559, 603, 477, 429};
    for(new i = 0; i < sizeof(superCars); i++) {
        if(modelid == superCars[i]) return VEHICLE_CLASS_SUPER;
    }
    
    // Sports cars
    new const sportsCars[] = {402, 409, 439, 477, 496, 506, 541, 415, 587, 589, 533, 526, 474, 545, 507};
    for(new i = 0; i < sizeof(sportsCars); i++) {
        if(modelid == sportsCars[i]) return VEHICLE_CLASS_SPORTS;
    }
    
    // Motorcycles
    if((modelid >= 448 && modelid <= 462) || modelid == 463 || modelid == 468 || modelid == 471 || modelid == 521 || modelid == 522 || modelid == 523 || modelid == 581 || modelid == 586) {
        return VEHICLE_CLASS_BIKE;
    }
    
    // Trucks and large vehicles
    new const trucks[] = {403, 413, 414, 422, 440, 443, 444, 456, 478, 482, 498, 499, 508, 514, 515, 524, 525, 531, 552, 578, 609};
    for(new i = 0; i < sizeof(trucks); i++) {
        if(modelid == trucks[i]) return VEHICLE_CLASS_TRUCK;
    }
    
    // Industrial vehicles
    new const industrial[] = {406, 407, 408, 416, 423, 427, 428, 431, 432, 433, 434, 435, 437, 486, 524, 525, 530, 552, 553, 574, 578, 582, 583, 609};
    for(new i = 0; i < sizeof(industrial); i++) {
        if(modelid == industrial[i]) return VEHICLE_CLASS_INDUSTRIAL;
    }
    
    // SUVs
    new const suvs[] = {400, 404, 479, 489, 500, 561, 585, 595};
    for(new i = 0; i < sizeof(suvs); i++) {
        if(modelid == suvs[i]) return VEHICLE_CLASS_SUV;
    }
    
    // Compact cars
    new const compacts[] = {401, 410, 418, 436, 438, 466, 467, 470, 491, 492, 516, 517, 518, 527, 529, 534, 535, 536, 540, 542, 546, 547, 549, 550, 566, 567, 575, 576, 580};
    for(new i = 0; i < sizeof(compacts); i++) {
        if(modelid == compacts[i]) return VEHICLE_CLASS_COMPACT;
    }
    return VEHICLE_CLASS_SEDAN;
}

stock Float:GetVehicleMaxSpeed(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 160.0;
    
    new modelid = GetVehicleModel(vehicleid);
    new E_VEHICLE_CLASS:vehicleClass = GetVehicleClass(modelid);
    new level = GetVehicleEngineLevel(vehicleid);
    
    new Float:baseLimit = VehicleClassSpeedLimits[_:vehicleClass];
    
    new Float:upgradeBonus = float(level) * 8.0;
    
    return baseLimit + upgradeBonus;
}

stock SetVehicleEngineLevel(vehicleid, level)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    if(level < 0 || level > MAX_ENGINE_LEVEL) return 0;
    
    new ownerid, slot;
    if(GetVehicleOwnerAndSlot(vehicleid, ownerid, slot)) {
        PlayerVehicleInfo[ownerid][slot][pvEngineUpgrade] = level;
        g_mysql_SaveVehicle(ownerid, slot);
        return 1;
    }
    return 0;
}

stock Float:GetVehicleEngineTemperature(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return ENGINE_NORMAL_TEMP;
    return ENGINE_NORMAL_TEMP;
}

stock GetVehicleEngineDurability(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 100;
    return 100;
}

stock ApplyEngineUpgrade(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    
    new level = GetVehicleEngineLevel(vehicleid);
    if(level == 0) return 1;
    
    new driverid = INVALID_PLAYER_ID;
    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(IsPlayerInVehicle(i, vehicleid) && GetPlayerVehicleSeat(i) == 0) {
            driverid = i;
            break;
        }
    }
    
    if(driverid == INVALID_PLAYER_ID) return 1;
    
    new Float:vx, Float:vy, Float:vz;
    GetVehicleVelocity(vehicleid, vx, vy, vz);
    new Float:speed = floatsqroot(vx*vx + vy*vy + vz*vz);
    
    if(speed < 0.05) return 1;
    
    new keys, ud, lr;
    GetPlayerKeys(driverid, keys, ud, lr);
    
    if(!(keys & KEY_SPRINT) && ud <= 0) return 1;
    
    new Float:durabilityFactor = 1.0;
    
    new Float:speedMultiplier = EngineSpeedMultiplier[level] * durabilityFactor;
    new Float:accelMultiplier = EngineAcceleration[level] * durabilityFactor;
    
    new Float:keyBoost = 1.0;
    if(ud > 0) keyBoost = 1.06;
    if(keys & KEY_SPRINT) keyBoost *= 1.03;
    
    speedMultiplier *= keyBoost;
    accelMultiplier *= keyBoost;
    
    new Float:boostFactor = (speedMultiplier - 1.0) * 0.020;
    new Float:accelFactor = (accelMultiplier - 1.0) * 0.025;
    
    if(level >= 4) {
        boostFactor *= 1.10;
        accelFactor *= 1.15;
    } else if(level >= 2) {
        boostFactor *= 1.05;
        accelFactor *= 1.08;
    }
    
    new Float:newVX = vx + (vx * boostFactor);
    new Float:newVY = vy + (vy * boostFactor);
    new Float:newVZ = vz + (vz * accelFactor * 0.25);
    
    new Float:currentSpeed = floatsqroot(newVX*newVX + newVY*newVY) * 180.0; 
    new Float:maxSpeed = GetVehicleMaxSpeed(vehicleid);
    
    if(currentSpeed > maxSpeed) {
        new Float:scaleFactor = maxSpeed / currentSpeed;
        newVX *= scaleFactor;
        newVY *= scaleFactor;
    }
    
    SetVehicleVelocity(vehicleid, newVX, newVY, newVZ);
    
    return 1;
}

stock ShowEngineUpgradeDialog(playerid)
{
    new vehicleid = GetPlayerVehicleID(playerid);
    if(vehicleid == 0)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de nang cap dong co!");
        return 0;
    }
    
    PlayerEngineUpgradeVehicle[playerid] = vehicleid;
    new currentLevel = GetVehicleEngineLevel(vehicleid);
    new Float:currentMaxSpeed = GetVehicleMaxSpeed(vehicleid);
    new string[2048];
    
    format(string, sizeof(string), "NANG CAP DONG CO\n\n");
    format(string, sizeof(string), "%sCap hien tai: %s\n", string, EngineUpgradeNames[currentLevel]);
    format(string, sizeof(string), "%sDo ben: %d%%\n", string, 100); // Luôn 100% vì không có durability system
    format(string, sizeof(string), "%sToc do toi da hien tai: %.0f km/h\n\n", string, currentMaxSpeed);
    
    new upgradeCount = 0;
    for(new i = currentLevel + 1; i <= MAX_ENGINE_LEVEL; i++)
    {
        new Float:newMaxSpeed = currentMaxSpeed + (float(i - currentLevel) * 8.0);
        format(string, sizeof(string), "%s%s\n", string, EngineUpgradeNames[i]);
        format(string, sizeof(string), "%sGia: $%s\n", string, number_format(EngineUpgradeCosts[i]));
        format(string, sizeof(string), "%sToc do: +%d%% | Gia toc: +%d%%\n", 
            string, 
            floatround((EngineSpeedMultiplier[i] - 1.0) * 100.0),
            floatround((EngineAcceleration[i] - 1.0) * 100.0)
        );
        format(string, sizeof(string), "%sToc do toi da: %.0f km/h\n\n", string, newMaxSpeed);
        upgradeCount++;
    }
    
    if(upgradeCount == 0) {
        strcat(string, "Dong co da dat cap do toi da!");
    }
    
    ShowPlayerDialog(playerid, UPGRADE_DIALOG_ID, DIALOG_STYLE_LIST, "Nang Cap Dong Co", string, "Nang cap", "Dong");
    return 1;
}

stock ShowEngineInfoDialog(playerid, vehicleid)
{
    new string[1024];
    new level = GetVehicleEngineLevel(vehicleid);
    new durability = 100; 
    new Float:maxSpeed = GetVehicleMaxSpeed(vehicleid);
    
    format(string, sizeof(string), "THONG TIN DONG CO\n\n");
    format(string, sizeof(string), "%sStage: %s\n", string, EngineUpgradeNames[level]);
    format(string, sizeof(string), "%sMo ta: %s\n\n", string, EngineUpgradeDesc[level]);
    
    if(level > 0) {
        format(string, sizeof(string), "%sTang toc do: +%d%%\n", 
            string, floatround((EngineSpeedMultiplier[level] - 1.0) * 100.0));
        format(string, sizeof(string), "%sTang gia toc: +%d%%\n", 
            string, floatround((EngineAcceleration[level] - 1.0) * 100.0));
        format(string, sizeof(string), "%sToc do toi da: %.0f km/h\n\n", string, maxSpeed);
    } else {
        format(string, sizeof(string), "%sToc do toi da: %.0f km/h\n\n", string, maxSpeed);
    }
    
    format(string, sizeof(string), "%sDo ben: %d%%\n", string, durability);
    
    ShowPlayerDialog(playerid, ENGINE_INFO_DIALOG_ID, DIALOG_STYLE_MSGBOX, "Thong Tin Dong Co", string, "Dong", "");
    return 1;
}

stock RepairVehicleEngine(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    
    RepairVehicle(vehicleid);
    SetVehicleHealth(vehicleid, 1000.0);
    
    return 1;
}

stock GetNearestMechanic(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    new Float:closestDistance = 999999.0;
    new closestMechanic = -1;
    
    for(new i = 0; i < sizeof(MechanicLocations); i++)
    {
        new Float:distance = GetPlayerDistanceFromPoint(playerid, MechanicLocations[i][0], MechanicLocations[i][1], MechanicLocations[i][2]);
        if(distance < closestDistance && distance < 5.0)
        {
            closestDistance = distance;
            closestMechanic = i;
        }
    }
    
    return closestMechanic;
}

hook OnFeatureSystemInit()
{
    for(new i = 0; i < sizeof(MechanicLocations); i++)
    {
        CreatePickup(MECHANIC_PICKUP_ID, 1, MechanicLocations[i][0], MechanicLocations[i][1], MechanicLocations[i][2]);
    }
    
    SetTimer("DelayedEngineInit", 500, false);
    return 1;
}

forward DelayedEngineInit();
public DelayedEngineInit()
{
    SetTimer("EnhancedEngineMonitor", 1000, true);
    return 1;
}

forward ContinueEngineInit();
public ContinueEngineInit()
{
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerNearMechanic[playerid] = 0;
    PlayerEngineUpgradeVehicle[playerid] = INVALID_VEHICLE_ID;
    return 1;
}

hook OnPlayerUpdate(playerid)
{
    new mechanicId = GetNearestMechanic(playerid);
    
    if(mechanicId != -1)
    {
        PlayerNearMechanic[playerid] = 1;
    }
    else
    {
        PlayerNearMechanic[playerid] = 0;
    }
    
    if(IsPlayerInAnyVehicle(playerid) && GetPlayerVehicleSeat(playerid) == 0)
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        ApplyEngineUpgrade(vehicleid);
    }
    
    return 1;
}


hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == UPGRADE_DIALOG_ID)
    {
        if(!response) return 1;
        
        new vehicleid = PlayerEngineUpgradeVehicle[playerid];
        if(vehicleid == INVALID_VEHICLE_ID || !IsPlayerInVehicle(playerid, vehicleid))
        {
            SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de nang cap!");
            return 1;
        }
        
        if(!PlayerNearMechanic[playerid])
        {
            SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai o gan tho may de nang cap dong co!");
            return 1;
        }
        
        new currentLevel = GetVehicleEngineLevel(vehicleid);
        new targetLevel = currentLevel + 1 + listitem;
        
        if(targetLevel > MAX_ENGINE_LEVEL)
        {
            SendClientMessage(playerid, 0xFF6B6BFF, "Cap nang cap khong hop le!");
            return 1;
        }
        
        new cost = EngineUpgradeCosts[targetLevel];
        if(GetPlayerMoney(playerid) < cost)
        {
            new string[128];
            format(string, sizeof(string), "Ban can them $%s de nang cap len %s", 
                number_format(cost - GetPlayerMoney(playerid)), EngineUpgradeNames[targetLevel]);
            SendClientMessage(playerid, 0xFF6B6BFF, string);
            return 1;
        }
        
        new confirmString[512];
        format(confirmString, sizeof(confirmString),
            "XAC NHAN NANG CAP DONG CO\n\n\
            Nang cap len: %s\n\
            Chi phi: $%s\n\
            Tang toc do: +%d%%\n\
            Tang gia toc: +%d%%\n\n\
            Ban co chac chan muon nang cap?",
            EngineUpgradeNames[targetLevel],
            number_format(cost),
            floatround((EngineSpeedMultiplier[targetLevel] - 1.0) * 100.0),
            floatround((EngineAcceleration[targetLevel] - 1.0) * 100.0)
        );
        
        SetPVarInt(playerid, "EngineUpgradeTarget", targetLevel);
        
        ShowPlayerDialog(playerid, UPGRADE_DIALOG_ID + 1, DIALOG_STYLE_MSGBOX, 
            "Xac Nhan Nang Cap", confirmString, "Dong y", "Huy");
        return 1;
    }
    else if(dialogid == UPGRADE_DIALOG_ID + 1)
    {
        if(!response) 
        {
            DeletePVar(playerid, "EngineUpgradeTarget");
            return 1;
        }
        
        new vehicleid = PlayerEngineUpgradeVehicle[playerid];
        new targetLevel = GetPVarInt(playerid, "EngineUpgradeTarget");
        new cost = EngineUpgradeCosts[targetLevel];
        
        if(!IsPlayerInVehicle(playerid, vehicleid) || !PlayerNearMechanic[playerid] || GetPlayerMoney(playerid) < cost)
        {
            SendClientMessage(playerid, 0xFF6B6BFF, "Khong the hoan thanh nang cap. Vui long thu lai!");
            DeletePVar(playerid, "EngineUpgradeTarget");
            return 1;
        }
        
        GivePlayerMoney(playerid, -cost);
        SetVehicleEngineLevel(vehicleid, targetLevel);
        
        new string[256];
        format(string, sizeof(string), 
            "Nang cap thanh cong! Dong co cua ban hien la %s!\n\
            Tang toc do: +%d%% | Tang gia toc: +%d%%",
            EngineUpgradeNames[targetLevel],
            floatround((EngineSpeedMultiplier[targetLevel] - 1.0) * 100.0),
            floatround((EngineAcceleration[targetLevel] - 1.0) * 100.0)
        );
        SendClientMessage(playerid, 0x50C878FF, string);
        
        DeletePVar(playerid, "EngineUpgradeTarget");
        return 1;
    }
    return 0;
}

forward EnhancedEngineMonitor();
public EnhancedEngineMonitor()
{
    for(new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++)
    {
        new driverid = INVALID_PLAYER_ID;
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(IsPlayerInVehicle(i, vehicleid) && GetPlayerVehicleSeat(i) == 0)
            {
                driverid = i;
                break;
            }
        }
        
        if(driverid == INVALID_PLAYER_ID) continue;
        
        new level = GetVehicleEngineLevel(vehicleid);
        if(level > 0)
        {
            ApplyEngineUpgrade(vehicleid);
        }
    }
}

CMD:nangcapdongco(playerid, params[])
{
    if(!PlayerNearMechanic[playerid])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai o gan tho may de nang cap dong co!");
        return 1;
    }
    
    if(!IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de nang cap dong co!");
        return 1;
    }
    
    if(GetPlayerVehicleSeat(playerid) != 0)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Chi tai xe moi co the nang cap dong co!");
        return 1;
    }
    
    ShowEngineUpgradeDialog(playerid);
    return 1;
}

CMD:kiemtradongco(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de kiem tra dong co!");
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    ShowEngineInfoDialog(playerid, vehicleid);
    return 1;
}

CMD:suadongco(playerid, params[])
{
    if(!PlayerNearMechanic[playerid])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai o gan tho may de sua chua dong co!");
        return 1;
    }
    
    if(!IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de sua chua!");
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    new level = GetVehicleEngineLevel(vehicleid);
    new repairCost = (level > 0) ? (level * 15000) : 5000;
    
    if(GetPlayerMoney(playerid) < repairCost)
    {
        new string[128];
        format(string, sizeof(string), "Ban can $%s de sua chua dong co!", number_format(repairCost));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 1;
    }
    
    GivePlayerMoney(playerid, -repairCost);
    RepairVehicleEngine(vehicleid);
    RepairVehicle(vehicleid);
    
    new string[128];
    format(string, sizeof(string), "Dong co da duoc sua chua hoan toan! Chi phi: $%s", number_format(repairCost));
    SendClientMessage(playerid, 0x50C878FF, string);
    
    return 1;
}

CMD:setengine(playerid, params[])
{
    new targetid, level;
    if(sscanf(params, "ud", targetid, level))
    {
        SendClientMessage(playerid, 0x4A90E2FF, "Su dung: /setengine [playerid] [level 0-5]");
        return 1;
    }
    
    if(!IsPlayerConnected(targetid) || !IsPlayerInAnyVehicle(targetid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Nguoi choi khong hop le hoac khong o trong xe!");
        return 1;
    }
    
    if(level < 0 || level > MAX_ENGINE_LEVEL)
    {
        new string[64];
        format(string, sizeof(string), "Level phai tu 0 den %d!", MAX_ENGINE_LEVEL);
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(targetid);
    SetVehicleEngineLevel(vehicleid, level);
    
    new targetName[MAX_PLAYER_NAME];
    GetPlayerName(targetid, targetName, sizeof(targetName));
    
    new string[128];
    format(string, sizeof(string), "Da set engine level %d cho xe cua %s", level, targetName);
    SendClientMessage(playerid, 0x50C878FF, string);
    
    format(string, sizeof(string), "Admin da set dong co cua ban thanh %s", EngineUpgradeNames[level]);
    SendClientMessage(targetid, 0x4A90E2FF, string);
    
    return 1;
}

CMD:garage(playerid, params[])
{
    new string[1024];
    strcat(string, "DANH SACH GARAGE\n\n");
    
    for(new i = 0; i < sizeof(MechanicLocations); i++)
    {
        new Float:distance = GetPlayerDistanceFromPoint(playerid, MechanicLocations[i][0], MechanicLocations[i][1], MechanicLocations[i][2]);
        format(string, sizeof(string), "%s%d. %s (%.1fm)\n", string, i+1, MechanicNames[i], distance);
    }
    
    strcat(string, "\nSu dung /tpgarage [1-6] de di chuyen den garage");
    
    ShowPlayerDialog(playerid, 9998, DIALOG_STYLE_MSGBOX, "Danh Sach Garage", string, "Dong", "");
    return 1;
}

CMD:tpgarage(playerid, params[])
{
    new garageid;
    if(sscanf(params, "d", garageid))
    {
        SendClientMessage(playerid, 0x4A90E2FF, "Su dung: /tpgarage [1-6] hoac /garage de xem danh sach");
        return 1;
    }
    
    garageid--;
    
    if(garageid < 0 || garageid >= sizeof(MechanicLocations))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "ID garage khong hop le! Su dung 1-6");
        return 1;
    }
    
    if(IsPlayerInAnyVehicle(playerid))
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        SetVehiclePos(vehicleid, MechanicLocations[garageid][0] + 3, MechanicLocations[garageid][1], MechanicLocations[garageid][2]);
        SetVehicleZAngle(vehicleid, MechanicLocations[garageid][3]);
    }
    else
    {
        SetPlayerPos(playerid, MechanicLocations[garageid][0] + 2, MechanicLocations[garageid][1], MechanicLocations[garageid][2]);
        SetPlayerFacingAngle(playerid, MechanicLocations[garageid][3]);
    }
    
    new string[128];
    format(string, sizeof(string), "Da di chuyen den %s!", MechanicNames[garageid]);
    SendClientMessage(playerid, 0x50C878FF, string);
    
    return 1;
}

CMD:speedlimit(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de kiem tra toc do toi da!");
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    new modelid = GetVehicleModel(vehicleid);
    new E_VEHICLE_CLASS:vehicleClass = GetVehicleClass(modelid);
    new level = GetVehicleEngineLevel(vehicleid);
    new Float:maxSpeed = GetVehicleMaxSpeed(vehicleid);
    new Float:baseSpeed = VehicleClassSpeedLimits[_:vehicleClass];
    
    new className[32];
    switch(vehicleClass) {
        case VEHICLE_CLASS_COMPACT: className = "Xe Compact";
        case VEHICLE_CLASS_SEDAN: className = "Xe Sedan";
        case VEHICLE_CLASS_SUV: className = "SUV";
        case VEHICLE_CLASS_SPORTS: className = "Xe The Thao";
        case VEHICLE_CLASS_SUPER: className = "Sieu Xe";
        case VEHICLE_CLASS_BIKE: className = "Xe May";
        case VEHICLE_CLASS_TRUCK: className = "Xe Tai";
        case VEHICLE_CLASS_INDUSTRIAL: className = "Xe Cong Nghiep";
        default: className = "Khong Xac Dinh";
    }
    
    new string[256];
    format(string, sizeof(string),
        "THONG TIN TOC DO XE\n\n\
        Loai xe: %s\n\
        Dong co: %s\n\
        Toc do co ban: %.0f km/h\n\
        Toc do toi da: %.0f km/h\n\
        Bonus tu dong co: +%.0f km/h",
        className,
        EngineUpgradeNames[level],
        baseSpeed,
        maxSpeed,
        maxSpeed - baseSpeed
    );
    
    ShowPlayerDialog(playerid, 9997, DIALOG_STYLE_MSGBOX, "Thong Tin Toc Do", string, "Dong", "");
    return 1;
}