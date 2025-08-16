#include <YSI\YSI_Coding\y_hooks>

// Constants for better maintainability
#define MAX_ENGINE_LEVEL 5
#define UNLIMITED_ENGINE_LEVEL 999  // Admin unlimited speed level
#define UPGRADE_DIALOG_ID 8000
#define ENGINE_INFO_DIALOG_ID 8001
#define MECHANIC_PICKUP_ID 1239
#define ENGINE_NORMAL_TEMP 80.0
#define ENGINE_UPDATE_INTERVAL 1000
#define MAX_MECHANIC_LOCATIONS 6

// Engine upgrade costs
new const EngineUpgradeCosts[MAX_ENGINE_LEVEL + 1] = {
    0, 75000, 180000, 420000, 850000, 1750000
};

// Performance multipliers
new const Float:EngineSpeedMultiplier[MAX_ENGINE_LEVEL + 1] = {
    1.0, 1.03, 1.06, 1.10, 1.14, 1.18
};

new const Float:EngineAcceleration[MAX_ENGINE_LEVEL + 1] = {
    1.0, 1.02, 1.04, 1.07, 1.10, 1.14
};

// Engine upgrade names
new const EngineUpgradeNames[][40] = {
    "Dong Co Goc",
    "Stage 1 - Performance Kit",
    "Stage 2 - Sport Tuning", 
    "Stage 3 - Racing Setup",
    "Stage 4 - Pro Performance",
    "Stage 5 - Ultimate Power"
};

// Engine upgrade descriptions
new const EngineUpgradeDesc[][60] = {
    "Dong co tieu chuan tu nha san xuat",
    "Nang cap co ban: ECU remap, air filter",
    "Nang cap the thao: turbo kit, exhaust sport",
    "Thiet lap dua: big turbo, racing injector",
    "Hieu suat cao: twin turbo, racing fuel",
    "Suc manh toi da: full race setup, NOS"
};

// Vehicle classes for better performance calculation
enum E_VEHICLE_CLASS
{
    VEHICLE_CLASS_UNKNOWN,
    VEHICLE_CLASS_COMPACT,
    VEHICLE_CLASS_SEDAN,
    VEHICLE_CLASS_SUV,
    VEHICLE_CLASS_SPORTS,
    VEHICLE_CLASS_SUPER,
    VEHICLE_CLASS_BIKE,
    VEHICLE_CLASS_TRUCK,
    VEHICLE_CLASS_INDUSTRIAL
}

// Base speed limits for each vehicle class
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

// Mechanic locations
new const Float:MechanicLocations[MAX_MECHANIC_LOCATIONS][4] = {
    {-2058.7, -2460.5, 30.6, 0.0},
    {1608.7, -1894.5, 13.5, 90.0},
    {-1420.5, 2584.2, 55.8, 180.0},
    {-2427.6, 1346.3, 7.1, 270.0},
    {2387.3, 1044.5, 10.8, 0.0},
    {-1904.8, 284.5, 41.0, 180.0}
};


// Player data
new PlayerNearMechanic[MAX_PLAYERS];
new PlayerEngineUpgradeVehicle[MAX_PLAYERS];

// Pre-calculated vehicle class arrays for better performance
new const superCars[] = {411, 506, 451, 541, 415, 429, 480, 602, 560, 565, 558, 559, 603, 477};
new const sportsCars[] = {402, 409, 439, 477, 496, 506, 541, 415, 587, 589, 533, 526, 474, 545, 507};
new const trucks[] = {403, 413, 414, 422, 440, 443, 444, 456, 478, 482, 498, 499, 508, 514, 515, 524, 525, 531, 552, 578, 609};
new const industrial[] = {406, 407, 408, 416, 423, 427, 428, 431, 432, 433, 434, 435, 437, 486, 524, 525, 530, 552, 553, 574, 578, 582, 583, 609};
new const suvs[] = {400, 404, 479, 489, 500, 561, 585, 595};
new const compacts[] = {401, 410, 418, 436, 438, 466, 467, 470, 491, 492, 516, 517, 518, 527, 529, 534, 535, 536, 540, 542, 546, 547, 549, 550, 566, 567, 575, 576, 580};

/*================== OPTIMIZED FUNCTIONS ==================*/

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
    for(new i = 0; i < sizeof(superCars); i++) {
        if(modelid == superCars[i]) return VEHICLE_CLASS_SUPER;
    }
    
    // Sports cars
    for(new i = 0; i < sizeof(sportsCars); i++) {
        if(modelid == sportsCars[i]) return VEHICLE_CLASS_SPORTS;
    }
    
    // Motorcycles
    if((modelid >= 448 && modelid <= 462) || modelid == 463 || modelid == 468 || modelid == 471 || modelid == 521 || modelid == 522 || modelid == 523 || modelid == 581 || modelid == 586) {
        return VEHICLE_CLASS_BIKE;
    }
    
    // Trucks and large vehicles
    for(new i = 0; i < sizeof(trucks); i++) {
        if(modelid == trucks[i]) return VEHICLE_CLASS_TRUCK;
    }
    
    // Industrial vehicles
    for(new i = 0; i < sizeof(industrial); i++) {
        if(modelid == industrial[i]) return VEHICLE_CLASS_INDUSTRIAL;
    }
    
    // SUVs
    for(new i = 0; i < sizeof(suvs); i++) {
        if(modelid == suvs[i]) return VEHICLE_CLASS_SUV;
    }
    
    // Compact cars
    for(new i = 0; i < sizeof(compacts); i++) {
        if(modelid == compacts[i]) return VEHICLE_CLASS_COMPACT;
    }
    
    return VEHICLE_CLASS_SEDAN;
}

stock Float:GetVehicleMaxSpeed(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 160.0;
    
    new level = GetVehicleEngineLevel(vehicleid);
    
    // Admin unlimited speed mode
    if(level == UNLIMITED_ENGINE_LEVEL) return 999999.0;
    
    new modelid = GetVehicleModel(vehicleid);
    new E_VEHICLE_CLASS:vehicleClass = GetVehicleClass(modelid);
    
    new Float:baseLimit = VehicleClassSpeedLimits[_:vehicleClass];
    new Float:upgradeBonus = float(level) * 8.0;
    
    return baseLimit + upgradeBonus;
}

stock SetVehicleEngineLevel(vehicleid, level)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    if(level < 0 || (level > MAX_ENGINE_LEVEL && level != UNLIMITED_ENGINE_LEVEL)) return 0;
    
    new ownerid, slot;
    if(GetVehicleOwnerAndSlot(vehicleid, ownerid, slot)) {
        PlayerVehicleInfo[ownerid][slot][pvEngineUpgrade] = level;
        g_mysql_SaveVehicle(ownerid, slot);
        return 1;
    }
    return 0;
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
    
    new Float:speedMultiplier, Float:accelMultiplier;
    
    // Special handling for unlimited engine level
    if(level == UNLIMITED_ENGINE_LEVEL) {
        speedMultiplier = 1.25;  // 125% speed boost (chỉ hơn level 5 một chút)
        accelMultiplier = 1.20;  // 120% acceleration boost (chỉ hơn level 5 một chút)
    } else {
        speedMultiplier = EngineSpeedMultiplier[level];
        accelMultiplier = EngineAcceleration[level];
    }
    
    new Float:keyBoost = 1.0;
    if(ud > 0) keyBoost = 1.06;
    if(keys & KEY_SPRINT) keyBoost *= 1.03;
    
    speedMultiplier *= keyBoost;
    accelMultiplier *= keyBoost;
    
    new Float:boostFactor, Float:accelFactor;
    
    if(level == UNLIMITED_ENGINE_LEVEL) {
        // Light boost for unlimited level
        boostFactor = (speedMultiplier - 1.0) * 0.025;  // Chỉ hơn normal một chút
        accelFactor = (accelMultiplier - 1.0) * 0.030;  // Chỉ hơn normal một chút
    } else {
        boostFactor = (speedMultiplier - 1.0) * 0.020;
        accelFactor = (accelMultiplier - 1.0) * 0.025;
        
        if(level >= 4) {
            boostFactor *= 1.10;
            accelFactor *= 1.15;
        } else if(level >= 2) {
            boostFactor *= 1.05;
            accelFactor *= 1.08;
        }
    }
    
    new Float:newVX, Float:newVY, Float:newVZ;
    
    if(level == UNLIMITED_ENGINE_LEVEL) {
        // Very light velocity boost for unlimited level
        newVX = vx + (vx * boostFactor);                // Không thêm extra boost
        newVY = vy + (vy * boostFactor);                // Không thêm extra boost
        newVZ = vz + (vz * accelFactor * 0.25);         // Giống như level thường
        
        // Không thêm forward momentum để giữ tự nhiên
    } else {
        newVX = vx + (vx * boostFactor);
        newVY = vy + (vy * boostFactor);
        newVZ = vz + (vz * accelFactor * 0.25);
    }
    
    new Float:currentSpeed = floatsqroot(newVX*newVX + newVY*newVY) * 180.0; 
    new Float:maxSpeed = GetVehicleMaxSpeed(vehicleid);
    
    // Skip speed limit for unlimited engine level (admin mode)
    if(level != UNLIMITED_ENGINE_LEVEL && currentSpeed > maxSpeed) {
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
    if(vehicleid == 0) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de nang cap dong co!");
        return 0;
    }
    
    PlayerEngineUpgradeVehicle[playerid] = vehicleid;
    new currentLevel = GetVehicleEngineLevel(vehicleid);
    new Float:currentMaxSpeed = GetVehicleMaxSpeed(vehicleid);
    new string[2048];
    
    format(string, sizeof(string), "NANG CAP DONG CO\n\n");
    format(string, sizeof(string), "%sCap hien tai: %s\n", string, EngineUpgradeNames[currentLevel]);
    format(string, sizeof(string), "%sToc do toi da hien tai: %.0f km/h\n\n", string, currentMaxSpeed);
    
    new upgradeCount = 0;
    for(new i = currentLevel + 1; i <= MAX_ENGINE_LEVEL; i++) {
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
    
    for(new i = 0; i < MAX_MECHANIC_LOCATIONS; i++) {
        new Float:distance = GetPlayerDistanceFromPoint(playerid, MechanicLocations[i][0], MechanicLocations[i][1], MechanicLocations[i][2]);
        if(distance < closestDistance && distance < 5.0) {
            closestDistance = distance;
            closestMechanic = i;
        }
    }
    
    return closestMechanic;
}

/*================== CALLBACKS ==================*/

hook OnFeatureSystemInit()
{
    for(new i = 0; i < MAX_MECHANIC_LOCATIONS; i++) {
        CreatePickup(MECHANIC_PICKUP_ID, 1, MechanicLocations[i][0], MechanicLocations[i][1], MechanicLocations[i][2]);
    }
    
    SetTimer("EngineMonitor", ENGINE_UPDATE_INTERVAL, true);
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
    PlayerNearMechanic[playerid] = (mechanicId != -1) ? 1 : 0;
    
    if(IsPlayerInAnyVehicle(playerid) && GetPlayerVehicleSeat(playerid) == 0) {
        new vehicleid = GetPlayerVehicleID(playerid);
        ApplyEngineUpgrade(vehicleid);
    }
    
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == UPGRADE_DIALOG_ID) {
        if(!response) return 1;
        
        new vehicleid = PlayerEngineUpgradeVehicle[playerid];
        if(vehicleid == INVALID_VEHICLE_ID || !IsPlayerInVehicle(playerid, vehicleid)) {
            SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de nang cap!");
            return 1;
        }
        
        if(!PlayerNearMechanic[playerid]) {
            SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai o gan tho may de nang cap dong co!");
            return 1;
        }
        
        new currentLevel = GetVehicleEngineLevel(vehicleid);
        new targetLevel = currentLevel + 1 + listitem;
        
        if(targetLevel > MAX_ENGINE_LEVEL) {
            SendClientMessage(playerid, 0xFF6B6BFF, "Cap nang cap khong hop le!");
            return 1;
        }
        
        new cost = EngineUpgradeCosts[targetLevel];
        if(GetPlayerMoney(playerid) < cost) {
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
    else if(dialogid == UPGRADE_DIALOG_ID + 1) {
        if(!response) {
            DeletePVar(playerid, "EngineUpgradeTarget");
            return 1;
        }
        
        new vehicleid = PlayerEngineUpgradeVehicle[playerid];
        new targetLevel = GetPVarInt(playerid, "EngineUpgradeTarget");
        new cost = EngineUpgradeCosts[targetLevel];
        
        if(!IsPlayerInVehicle(playerid, vehicleid) || !PlayerNearMechanic[playerid] || GetPlayerMoney(playerid) < cost) {
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

/*================== TIMERS ==================*/

forward EngineMonitor();
public EngineMonitor()
{
    for(new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++) {
        new driverid = INVALID_PLAYER_ID;
        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerInVehicle(i, vehicleid) && GetPlayerVehicleSeat(i) == 0) {
                driverid = i;
                break;
            }
        }
        
        if(driverid == INVALID_PLAYER_ID) continue;
        
        new level = GetVehicleEngineLevel(vehicleid);
        if(level > 0) {
            ApplyEngineUpgrade(vehicleid);
        }
    }
}

/*================== COMMANDS ==================*/

CMD:nangcapdongco(playerid, params[])
{
    if(!PlayerNearMechanic[playerid]) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai o gan tho may de nang cap dong co!");
        return 1;
    }
    
    if(!IsPlayerInAnyVehicle(playerid)) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de nang cap dong co!");
        return 1;
    }
    
    if(GetPlayerVehicleSeat(playerid) != 0) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Chi tai xe moi co the nang cap dong co!");
        return 1;
    }
    
    ShowEngineUpgradeDialog(playerid);
    return 1;
}

CMD:suadongco(playerid, params[])
{
    if(!PlayerNearMechanic[playerid]) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai o gan tho may de sua chua dong co!");
        return 1;
    }
    
    if(!IsPlayerInAnyVehicle(playerid)) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban phai ngoi trong xe de sua chua!");
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    new level = GetVehicleEngineLevel(vehicleid);
    new repairCost = (level > 0) ? (level * 15000) : 5000;
    
    if(GetPlayerMoney(playerid) < repairCost) {
        new string[128];
        format(string, sizeof(string), "Ban can $%s de sua chua dong co!", number_format(repairCost));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 1;
    }
    
    GivePlayerMoney(playerid, -repairCost);
    RepairVehicleEngine(vehicleid);
    
    new string[128];
    format(string, sizeof(string), "Dong co da duoc sua chua hoan toan! Chi phi: $%s", number_format(repairCost));
    SendClientMessage(playerid, 0x50C878FF, string);
    
    return 1;
}

CMD:setengine(playerid, params[])
{
    new vehicleid, level;
    if(sscanf(params, "dd", vehicleid, level)) {
        SendClientMessage(playerid, 0x4A90E2FF, "Su dung: /setengine [vehicleid] [level 0-5] hoac [999 = unlimited]");
        return 1;
    }
    
    if(vehicleid < 1 || vehicleid >= MAX_VEHICLES) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Vehicle ID khong hop le!");
        return 1;
    }
    
    if(level < 0 || (level > MAX_ENGINE_LEVEL && level != UNLIMITED_ENGINE_LEVEL)) {
        new string[128];
        format(string, sizeof(string), "Level phai tu 0 den %d hoac 999 (unlimited speed)!", MAX_ENGINE_LEVEL);
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 1;
    }
    
    if(SetVehicleEngineLevel(vehicleid, level)) {
        new string[256];
        if(level == UNLIMITED_ENGINE_LEVEL) {
            format(string, sizeof(string), "Da set UNLIMITED SPEED cho xe ID %d (khong gioi han toc do)", vehicleid);
        } else {
            format(string, sizeof(string), "Da set engine level %d cho xe ID %d", level, vehicleid);
        }
        SendClientMessage(playerid, 0x50C878FF, string);
    } else {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong the set engine level cho xe nay!");
    }
    
    return 1;
}

CMD:unlimitedspeed(playerid, params[])
{
    new vehicleid;
    if(sscanf(params, "d", vehicleid)) {
        SendClientMessage(playerid, 0x4A90E2FF, "Su dung: /unlimitedspeed [vehicleid]");
        return 1;
    }
    
    if(vehicleid < 1 || vehicleid >= MAX_VEHICLES) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Vehicle ID khong hop le!");
        return 1;
    }
    
    if(SetVehicleEngineLevel(vehicleid, UNLIMITED_ENGINE_LEVEL)) {
        new string[256];
        format(string, sizeof(string), "Da bat UNLIMITED SPEED cho xe ID %d! Xe nay co gia toc +20%% va khong gioi han toc do!", vehicleid);
        SendClientMessage(playerid, 0x50C878FF, string);
    } else {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong the set unlimited speed cho xe nay!");
    }
    
    return 1;
}