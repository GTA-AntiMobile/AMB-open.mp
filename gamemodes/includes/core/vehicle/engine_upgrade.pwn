#include <YSI\YSI_Coding\y_hooks>
#include <YSI\YSI_Coding\y_timers>

#define MAX_ENGINE_LEVEL 5
#define UNLIMITED_ENGINE_LEVEL 999  
#define UPGRADE_DIALOG_ID 8000
#define ENGINE_INFO_DIALOG_ID 8001
#define MECHANIC_PICKUP_ID 1239
#define ENGINE_NORMAL_TEMP 80.0
#define ENGINE_UPDATE_INTERVAL 2500  // Reduced from 1000ms to 2500ms
#define MAX_MECHANIC_LOCATIONS 6
#define VEHICLE_CLASS_CACHE_SIZE MAX_VEHICLES
#define ENGINE_BOOST_UPDATE_RATE 3  // Only update every 3rd OnPlayerUpdate call

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

new const Float:MechanicLocations[MAX_MECHANIC_LOCATIONS][4] = {
    {-2058.7, -2460.5, 30.6, 0.0},
    {1608.7, -1894.5, 13.5, 90.0},
    {-1420.5, 2584.2, 55.8, 180.0},
    {-2427.6, 1346.3, 7.1, 270.0},
    {2387.3, 1044.5, 10.8, 0.0},
    {-1904.8, 284.5, 41.0, 180.0}
};


new PlayerNearMechanic[MAX_PLAYERS];
new PlayerEngineUpgradeVehicle[MAX_PLAYERS];
new PlayerUpdateCounter[MAX_PLAYERS];  // Counter for update rate limiting
// Removed VehicleClassCache as it's not used in current implementation
new VehicleOwnerCache[MAX_VEHICLES];  // Cache for vehicle owners
new VehicleSlotCache[MAX_VEHICLES];   // Cache for vehicle slots
new bool:VehicleCacheValid[MAX_VEHICLES];  // Cache validity flags
new LastEngineBoostTime[MAX_PLAYERS];  // Rate limiting for engine boost

new const superCars[] = {411, 506, 451, 541, 415, 429, 480, 602, 560, 565, 558, 559, 603, 477};
new const sportsCars[] = {402, 409, 439, 477, 496, 506, 541, 415, 587, 589, 533, 526, 474, 545, 507};
new const trucks[] = {403, 413, 414, 422, 440, 443, 444, 456, 478, 482, 498, 499, 508, 514, 515, 524, 525, 531, 552, 578, 609};
new const industrial[] = {406, 407, 408, 416, 423, 427, 428, 431, 432, 433, 434, 435, 437, 486, 524, 525, 530, 552, 553, 574, 578, 582, 583, 609};
new const suvs[] = {400, 404, 479, 489, 500, 561, 585, 595};
new const compacts[] = {401, 410, 418, 436, 438, 466, 467, 470, 491, 492, 516, 517, 518, 527, 529, 534, 535, 536, 540, 542, 546, 547, 549, 550, 566, 567, 575, 576, 580};

/*================== HELPER FUNCTIONS ==================*/

stock SortIntArray(array[], size)
{
    for(new i = 0; i < size - 1; i++) {
        for(new j = 0; j < size - i - 1; j++) {
            if(array[j] > array[j + 1]) {
                new temp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = temp;
            }
        }
    }
}

stock bool:BinarySearch(const array[], size, value)
{
    new left = 0, right = size - 1;
    
    while(left <= right) {
        new mid = (left + right) / 2;
        
        if(array[mid] == value) return true;
        else if(array[mid] < value) left = mid + 1;
        else right = mid - 1;
    }
    
    return false;
}

stock InvalidateVehicleCache(vehicleid)
{
    if(vehicleid >= 0 && vehicleid < MAX_VEHICLES) {
        VehicleCacheValid[vehicleid] = false;
    }
}

/*================== OPTIMIZED FUNCTIONS ==================*/

stock GetVehicleOwnerAndSlot(vehicleid, &ownerid, &slot)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) {
        ownerid = INVALID_PLAYER_ID;
        slot = -1;
        return 0;
    }
    
    if(VehicleCacheValid[vehicleid]) {
        ownerid = VehicleOwnerCache[vehicleid];
        slot = VehicleSlotCache[vehicleid];
        
        if(ownerid != INVALID_PLAYER_ID && IsPlayerConnected(ownerid) && 
           slot >= 0 && slot < MAX_PLAYERVEHICLES && 
           PlayerVehicleInfo[ownerid][slot][pvId] == vehicleid) {
            return 1;
        }
        
        VehicleCacheValid[vehicleid] = false;
    }
    
    ownerid = INVALID_PLAYER_ID;
    slot = -1;
    
    foreach(new i: Player) {
        if(!IsPlayerConnected(i)) continue;
        
        for(new v = 0; v < MAX_PLAYERVEHICLES; v++) {
            if(PlayerVehicleInfo[i][v][pvId] == vehicleid) {
                ownerid = i;
                slot = v;
                
                VehicleOwnerCache[vehicleid] = ownerid;
                VehicleSlotCache[vehicleid] = slot;
                VehicleCacheValid[vehicleid] = true;
                
                return 1;
            }
        }
    }
    
    VehicleOwnerCache[vehicleid] = INVALID_PLAYER_ID;
    VehicleSlotCache[vehicleid] = -1;
    VehicleCacheValid[vehicleid] = true;
    
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
    static bool:initialized = false;
    static sortedSuperCars[sizeof(superCars)];
    static sortedSportsCars[sizeof(sportsCars)];
    static sortedTrucks[sizeof(trucks)];
    static sortedIndustrial[sizeof(industrial)];
    static sortedSuvs[sizeof(suvs)];
    static sortedCompacts[sizeof(compacts)];
    
    if(!initialized) {
        for(new i = 0; i < sizeof(superCars); i++) sortedSuperCars[i] = superCars[i];
        for(new i = 0; i < sizeof(sportsCars); i++) sortedSportsCars[i] = sportsCars[i];
        for(new i = 0; i < sizeof(trucks); i++) sortedTrucks[i] = trucks[i];
        for(new i = 0; i < sizeof(industrial); i++) sortedIndustrial[i] = industrial[i];
        for(new i = 0; i < sizeof(suvs); i++) sortedSuvs[i] = suvs[i];
        for(new i = 0; i < sizeof(compacts); i++) sortedCompacts[i] = compacts[i];
        
        SortIntArray(sortedSuperCars, sizeof(sortedSuperCars));
        SortIntArray(sortedSportsCars, sizeof(sortedSportsCars));
        SortIntArray(sortedTrucks, sizeof(sortedTrucks));
        SortIntArray(sortedIndustrial, sizeof(sortedIndustrial));
        SortIntArray(sortedSuvs, sizeof(sortedSuvs));
        SortIntArray(sortedCompacts, sizeof(sortedCompacts));
        
        initialized = true;
    }
    
    if((modelid >= 448 && modelid <= 462) || modelid == 463 || modelid == 468 || modelid == 471 || 
       modelid == 521 || modelid == 522 || modelid == 523 || modelid == 581 || modelid == 586) {
        return VEHICLE_CLASS_BIKE;
    }
    
    if(BinarySearch(sortedSuperCars, sizeof(sortedSuperCars), modelid)) return VEHICLE_CLASS_SUPER;
    if(BinarySearch(sortedSportsCars, sizeof(sortedSportsCars), modelid)) return VEHICLE_CLASS_SPORTS;
    if(BinarySearch(sortedTrucks, sizeof(sortedTrucks), modelid)) return VEHICLE_CLASS_TRUCK;
    if(BinarySearch(sortedIndustrial, sizeof(sortedIndustrial), modelid)) return VEHICLE_CLASS_INDUSTRIAL;
    if(BinarySearch(sortedSuvs, sizeof(sortedSuvs), modelid)) return VEHICLE_CLASS_SUV;
    if(BinarySearch(sortedCompacts, sizeof(sortedCompacts), modelid)) return VEHICLE_CLASS_COMPACT;
    
    return VEHICLE_CLASS_SEDAN;
}

stock Float:GetVehicleMaxSpeed(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 160.0;
    
    new level = GetVehicleEngineLevel(vehicleid);
    
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

stock ApplyEngineUpgrade(vehicleid, driverid = INVALID_PLAYER_ID)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    
    new level = GetVehicleEngineLevel(vehicleid);
    if(level == 0) return 1;
    
    if(driverid == INVALID_PLAYER_ID) {
        foreach(new i: Player) {
            if(IsPlayerInVehicle(i, vehicleid) && GetPlayerVehicleSeat(i) == 0) {
                driverid = i;
                break;
            }
        }
    }
    
    if(driverid == INVALID_PLAYER_ID || !IsPlayerConnected(driverid)) return 1;
    
    new currentTime = GetTickCount();
    if(currentTime - LastEngineBoostTime[driverid] < 150) return 1;
    LastEngineBoostTime[driverid] = currentTime;
    
    new Float:vx, Float:vy, Float:vz;
    GetVehicleVelocity(vehicleid, vx, vy, vz);
    new Float:speed = floatsqroot(vx*vx + vy*vy + vz*vz);
    
    if(speed < 0.05) return 1;
    
    new keys, ud, lr;
    GetPlayerKeys(driverid, keys, ud, lr);
    
    if(!(keys & KEY_SPRINT) && ud <= 0) return 1;
    
    new Float:speedMultiplier, Float:accelMultiplier;
    
    if(level == UNLIMITED_ENGINE_LEVEL) {
        speedMultiplier = 1.50;  // 125% speed boost (chỉ hơn level 5 một chút)
        accelMultiplier = 2.00;  // 120% acceleration boost (chỉ hơn level 5 một chút)
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
        boostFactor = (speedMultiplier - 1.0) * 0.030;  // Chỉ hơn normal một chút
        accelFactor = (accelMultiplier - 1.0) * 0.040;  // Chỉ hơn normal một chút
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
        newVX = vx + (vx * boostFactor);                // Không thêm extra boost
        newVY = vy + (vy * boostFactor);                // Không thêm extra boost
        newVZ = vz + (vz * accelFactor * 0.40);         // Giống như level thường
        
    } else {
        newVX = vx + (vx * boostFactor);
        newVY = vy + (vy * boostFactor);
        newVZ = vz + (vz * accelFactor * 0.25);
    }
    
    new Float:currentSpeed = floatsqroot(newVX*newVX + newVY*newVY) * 180.0; 
    new Float:maxSpeed = GetVehicleMaxSpeed(vehicleid);
    
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
    
    format(string, sizeof(string), 
        "{FFFFFF}NANG CAP DONG CO\n\n\
        {FFDC00}Cap hien tai: {FFFFFF}%s\n\
        {FFDC00}Toc do toi da: {FFFFFF}%.0f km/h\n\n\
        {00FF00}CAC CAP DO NANG CAP:{FFFFFF}\n", 
        EngineUpgradeNames[currentLevel], currentMaxSpeed);
    
    new upgradeCount = 0;
    for(new i = currentLevel + 1; i <= MAX_ENGINE_LEVEL; i++) {
        new Float:newMaxSpeed = currentMaxSpeed + (float(i - currentLevel) * 8.0);
        new speedBonus = floatround((EngineSpeedMultiplier[i] - 1.0) * 100.0);
        new accelBonus = floatround((EngineAcceleration[i] - 1.0) * 100.0);
        
        format(string, sizeof(string), 
            "%s{FFDC00}%s {FFFFFF}| {00FF00}$%s\n\
            {GRAY}  Toc do: +%d%% | Gia toc: +%d%% | Max: %.0f km/h\n", 
            string, EngineUpgradeNames[i], number_format(EngineUpgradeCosts[i]),
            speedBonus, accelBonus, newMaxSpeed);
        upgradeCount++;
    }
    
    if(upgradeCount == 0) {
        strcat(string, "\n{FF6B6B}Dong co da dat cap do toi da!");
    }
    
    ShowPlayerDialog(playerid, UPGRADE_DIALOG_ID, DIALOG_STYLE_LIST, "Nang Cap Dong Co", string, "Nang cap", "Dong");
    return 1;
}

stock ShowEngineInfoDialog(playerid, vehicleid)
{
    new string[1024];
    new level = GetVehicleEngineLevel(vehicleid);
    new Float:maxSpeed = GetVehicleMaxSpeed(vehicleid);
    new modelid = GetVehicleModel(vehicleid);
    new E_VEHICLE_CLASS:vehicleClass = GetVehicleClass(modelid);
    
    new className[20];
    switch(vehicleClass) {
        case VEHICLE_CLASS_SUPER: className = "Super Car";
        case VEHICLE_CLASS_SPORTS: className = "Sports Car";
        case VEHICLE_CLASS_SEDAN: className = "Sedan";
        case VEHICLE_CLASS_SUV: className = "SUV";
        case VEHICLE_CLASS_COMPACT: className = "Compact";
        case VEHICLE_CLASS_TRUCK: className = "Truck";
        case VEHICLE_CLASS_INDUSTRIAL: className = "Industrial";
        case VEHICLE_CLASS_BIKE: className = "Motorcycle";
        default: className = "Unknown";
    }
    
    format(string, sizeof(string), 
        "{FFFFFF}THONG TIN DONG CO\n\n\
        {FFDC00}Loai xe: {FFFFFF}%s\n\
        {FFDC00}Cap do: {FFFFFF}%s\n\
        {FFDC00}Mo ta: {GRAY}%s\n\n", 
        className, EngineUpgradeNames[level], EngineUpgradeDesc[level]);
    
    if(level > 0) {
        format(string, sizeof(string), 
            "%s{00FF00}HIEU SUAT:\n\
            {FFFFFF}Tang toc do: {00FF00}+%d%%\n\
            {FFFFFF}Tang gia toc: {00FF00}+%d%%\n\
            {FFFFFF}Toc do toi da: {FFDC00}%.0f km/h\n", 
            string,
            floatround((EngineSpeedMultiplier[level] - 1.0) * 100.0),
            floatround((EngineAcceleration[level] - 1.0) * 100.0),
            maxSpeed);
    } else {
        format(string, sizeof(string), "%s{FFFFFF}Toc do toi da: {FFDC00}%.0f km/h\n", string, maxSpeed);
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
    PlayerUpdateCounter[playerid] = 0;
    LastEngineBoostTime[playerid] = 0;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    for(new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++) {
        if(VehicleCacheValid[vehicleid] && VehicleOwnerCache[vehicleid] == playerid) {
            VehicleCacheValid[vehicleid] = false;
        }
    }
    return 1;
}

stock InvalidatePlayerVehicleCache(playerid)
{
    for(new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++) {
        if(VehicleCacheValid[vehicleid] && VehicleOwnerCache[vehicleid] == playerid) {
            VehicleCacheValid[vehicleid] = false;
        }
    }
}

hook OnPlayerUpdate(playerid)
{
    PlayerUpdateCounter[playerid]++;
    if(PlayerUpdateCounter[playerid] % ENGINE_BOOST_UPDATE_RATE != 0) {
        return 1;
    }
    
    if(PlayerUpdateCounter[playerid] % (ENGINE_BOOST_UPDATE_RATE * 5) == 0) {
        new mechanicId = GetNearestMechanic(playerid);
        PlayerNearMechanic[playerid] = (mechanicId != -1) ? 1 : 0;
    }
    
    if(IsPlayerInAnyVehicle(playerid) && GetPlayerVehicleSeat(playerid) == 0) {
        new vehicleid = GetPlayerVehicleID(playerid);
        ApplyEngineUpgrade(vehicleid, playerid);  
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
    static vehicleCheckOffset = 0;
    new vehiclesChecked = 0;
    new maxChecksPerCall = 50;  // Limit checks per timer call
    
    for(new offset = 0; offset < MAX_VEHICLES && vehiclesChecked < maxChecksPerCall; offset++) {
        new vehicleid = ((vehicleCheckOffset + offset) % MAX_VEHICLES) + 1;
        
        new ownerid, slot;
        if(!GetVehicleOwnerAndSlot(vehicleid, ownerid, slot)) continue;
        if(ownerid == INVALID_PLAYER_ID) continue;
        
        new level = PlayerVehicleInfo[ownerid][slot][pvEngineUpgrade];
        if(level == 0) continue;
        
        new driverid = INVALID_PLAYER_ID;
        foreach(new i: Player) {
            if(IsPlayerInVehicle(i, vehicleid) && GetPlayerVehicleSeat(i) == 0) {
                driverid = i;
                break;
            }
        }
        
        if(driverid != INVALID_PLAYER_ID) {
            ApplyEngineUpgrade(vehicleid, driverid);
        }
        
        vehiclesChecked++;
    }
    
    vehicleCheckOffset = (vehicleCheckOffset + maxChecksPerCall) % MAX_VEHICLES;
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
