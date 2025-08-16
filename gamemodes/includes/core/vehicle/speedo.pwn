#include <YSI\YSI_Coding\y_hooks>

#define SPEEDO_UPDATE_INTERVAL 250 
#define MAX_VEHICLE_SPEED 300.0
#define FUEL_CONSUMPTION_RATE 0.1

enum E_VEHICLE_SPEEDO_DATA
{
    bool:vs_SpeedoVisible,
    vs_LastSpeed,
    vs_LastFuel,
    vs_LastHealth,
    vs_LastZone[32],
    vs_UpdateTimer
}

new PlayerSpeedoData[MAX_PLAYERS][E_VEHICLE_SPEEDO_DATA];
new PlayerText:SpeedoTD[MAX_PLAYERS][14]; 


/*================== SPEEDOMETER FUNCTIONS ==================*/

stock Float:GetVehicleFuelLevel(vehicleid)
{
    new Float:health;
    GetVehicleHealth(vehicleid, health);
    return (health / 1000.0) * 100.0; 
}

stock CreateSpeedoTextDraws(playerid)
{
    SpeedoTD[playerid][0] = CreatePlayerTextDraw(playerid, 480.0, 350.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][0], 150.0, 80.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][0], 0x000000BB);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][0], 4);
    
    SpeedoTD[playerid][1] = CreatePlayerTextDraw(playerid, 555.0, 360.0, "Vehicle Name");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][1], 0.160, 0.800);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][1], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][1], 1);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][1], 2);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][1], 1);
    
    SpeedoTD[playerid][2] = CreatePlayerTextDraw(playerid, 490.0, 375.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][2], 130.0, 6.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][2], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][2], 0x333333FF);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][2], 4);
    
    SpeedoTD[playerid][3] = CreatePlayerTextDraw(playerid, 490.0, 375.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][3], 0.0, 6.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][3], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][3], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][3], 4);
    
    SpeedoTD[playerid][4] = CreatePlayerTextDraw(playerid, 485.0, 372.0, "~b~SPD");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][4], 0.140, 0.700);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][4], 0x4A90E2FF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][4], 1);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][4], 1);
    
    SpeedoTD[playerid][5] = CreatePlayerTextDraw(playerid, 490.0, 385.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][5], 130.0, 6.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][5], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][5], 0x333333FF);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][5], 4);
    
    SpeedoTD[playerid][6] = CreatePlayerTextDraw(playerid, 490.0, 385.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][6], 130.0, 6.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][6], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][6], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][6], 4);
    
    SpeedoTD[playerid][7] = CreatePlayerTextDraw(playerid, 485.0, 382.0, "~r~HP");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][7], 0.140, 0.700);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][7], 0xFF5722FF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][7], 1);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][7], 1);
    
    SpeedoTD[playerid][8] = CreatePlayerTextDraw(playerid, 490.0, 395.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][8], 130.0, 6.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][8], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][8], 0x333333FF);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][8], 4);
    
    SpeedoTD[playerid][9] = CreatePlayerTextDraw(playerid, 490.0, 395.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][9], 130.0, 6.0);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][9], 1);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][9], 0xFFC107FF);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][9], 4);
    
    SpeedoTD[playerid][10] = CreatePlayerTextDraw(playerid, 485.0, 392.0, "~y~FL");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][10], 0.140, 0.700);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][10], 0xFFC107FF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][10], 1);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][10], 1);
    
    SpeedoTD[playerid][11] = CreatePlayerTextDraw(playerid, 555.0, 405.0, "Los Santos");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][11], 0.140, 0.700);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][11], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][11], 1);
    PlayerTextDrawAlignment(playerid, SpeedoTD[playerid][11], 2);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][11], 1);
    
    SpeedoTD[playerid][12] = CreatePlayerTextDraw(playerid, 490.0, 415.0, "~g~ENG");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][12], 0.130, 0.650);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][12], 0x4CAF50FF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][12], 1);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][12], 1);
    
    SpeedoTD[playerid][13] = CreatePlayerTextDraw(playerid, 620.0, 415.0, "~w~LGT");
    PlayerTextDrawLetterSize(playerid, SpeedoTD[playerid][13], 0.130, 0.650);
    PlayerTextDrawColor(playerid, SpeedoTD[playerid][13], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, SpeedoTD[playerid][13], 1);
    PlayerTextDrawFont(playerid, SpeedoTD[playerid][13], 1);
    
    return 1;
}

stock ShowSpeedometer(playerid)
{
    if(PlayerSpeedoData[playerid][vs_SpeedoVisible]) return 0;
    
    if(SpeedoTD[playerid][0] == PlayerText:INVALID_TEXT_DRAW)
    {
        CreateSpeedoTextDraws(playerid);
    }
    
    for(new i = 0; i < 14; i++)
    {
        if(SpeedoTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawShow(playerid, SpeedoTD[playerid][i]);
        }
    }
    
    PlayerSpeedoData[playerid][vs_SpeedoVisible] = true;
    
    PlayerSpeedoData[playerid][vs_UpdateTimer] = SetTimerEx("UpdateSpeedometer", SPEEDO_UPDATE_INTERVAL, true, "d", playerid);
    
    return 1;
}

stock HideSpeedometer(playerid)
{
    if(!PlayerSpeedoData[playerid][vs_SpeedoVisible]) return 0;
    
    for(new i = 0; i < 14; i++)
    {
        if(SpeedoTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawHide(playerid, SpeedoTD[playerid][i]);
        }
    }
    
    PlayerSpeedoData[playerid][vs_SpeedoVisible] = false;
    
    if(PlayerSpeedoData[playerid][vs_UpdateTimer] != -1)
    {
        KillTimer(PlayerSpeedoData[playerid][vs_UpdateTimer]);
        PlayerSpeedoData[playerid][vs_UpdateTimer] = -1;
    }
    
    return 1;
}

forward UpdateSpeedometer(playerid);
public UpdateSpeedometer(playerid)
{
    if(!PlayerSpeedoData[playerid][vs_SpeedoVisible]) return 0;
    if(!IsPlayerInAnyVehicle(playerid)) 
    {
        HideSpeedometer(playerid);
        return 0;
    }
    
    static vehicleid, Float:vx, Float:vy, Float:vz, speed;
    static Float:health, healthPercent, Float:fuel, fuelPercent;
    static Float:speedWidth, Float:healthWidth, Float:fuelWidth;
    
    vehicleid = GetPlayerVehicleID(playerid);
    if(vehicleid == 0) return 0;
    
    GetVehicleVelocity(vehicleid, vx, vy, vz);
    speed = floatround(floatsqroot(vx*vx + vy*vy + vz*vz) * 181.5);
    
    if(PlayerSpeedoData[playerid][vs_LastSpeed] != speed)
    {
        PlayerSpeedoData[playerid][vs_LastSpeed] = speed;
        speedWidth = (130.0 * speed) / MAX_VEHICLE_SPEED;
        if(speedWidth > 130.0) speedWidth = 130.0;
        PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][3], speedWidth, 6.0);
        
        if(speed > 120)
            PlayerTextDrawColor(playerid, SpeedoTD[playerid][3], 0xFF5722FF);
        else if(speed > 80)
            PlayerTextDrawColor(playerid, SpeedoTD[playerid][3], 0xFFC107FF);
        else
            PlayerTextDrawColor(playerid, SpeedoTD[playerid][3], 0x4A90E2FF);
        
        PlayerTextDrawShow(playerid, SpeedoTD[playerid][3]);
    }
    
    static lastVehicleUpdate[MAX_PLAYERS] = {-1, ...};
    if(lastVehicleUpdate[playerid] != vehicleid)
    {
        PlayerTextDrawSetString(playerid, SpeedoTD[playerid][1], GetVehicleName(vehicleid));
        lastVehicleUpdate[playerid] = vehicleid;
    }
    
    static healthUpdateCounter[MAX_PLAYERS];
    if(++healthUpdateCounter[playerid] >= 3)
    {
        healthUpdateCounter[playerid] = 0;
        GetVehicleHealth(vehicleid, health);
        healthPercent = floatround((health / 1000.0) * 100.0);
        
        if(PlayerSpeedoData[playerid][vs_LastHealth] != healthPercent)
        {
            healthWidth = (130.0 * healthPercent) / 100.0;
            PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][6], healthWidth, 6.0);
            
            if(healthPercent > 60)
                PlayerTextDrawColor(playerid, SpeedoTD[playerid][6], 0x4CAF50FF);
            else if(healthPercent > 30)
                PlayerTextDrawColor(playerid, SpeedoTD[playerid][6], 0xFFC107FF);
            else
                PlayerTextDrawColor(playerid, SpeedoTD[playerid][6], 0xFF5722FF);
            
            PlayerTextDrawShow(playerid, SpeedoTD[playerid][6]);
            PlayerSpeedoData[playerid][vs_LastHealth] = healthPercent;
        }
    }
    
    static fuelUpdateCounter[MAX_PLAYERS];
    if(++fuelUpdateCounter[playerid] >= 4)
    {
        fuelUpdateCounter[playerid] = 0;
        fuel = GetVehicleFuelLevel(vehicleid); 
        fuelPercent = floatround(fuel);
        
        if(PlayerSpeedoData[playerid][vs_LastFuel] != fuelPercent)
        {
            fuelWidth = (130.0 * fuelPercent) / 100.0;
            PlayerTextDrawTextSize(playerid, SpeedoTD[playerid][9], fuelWidth, 6.0);
            
            if(fuelPercent > 25)
                PlayerTextDrawColor(playerid, SpeedoTD[playerid][9], 0xFFC107FF);
            else
                PlayerTextDrawColor(playerid, SpeedoTD[playerid][9], 0xFF5722FF);
            
            PlayerTextDrawShow(playerid, SpeedoTD[playerid][9]);
            PlayerSpeedoData[playerid][vs_LastFuel] = fuelPercent;
        }
    }
    
    static locationUpdateCounter[MAX_PLAYERS];
    if(++locationUpdateCounter[playerid] >= 15) 
    {
        locationUpdateCounter[playerid] = 0;
        new zone[32];
        GetPlayerZone(playerid, zone, sizeof(zone));
        if(strcmp(PlayerSpeedoData[playerid][vs_LastZone], zone) != 0)
        {
            PlayerTextDrawSetString(playerid, SpeedoTD[playerid][11], zone);
            format(PlayerSpeedoData[playerid][vs_LastZone], 32, "%s", zone);
        }
    }
    
    static statusUpdateCounter[MAX_PLAYERS];
    if(++statusUpdateCounter[playerid] >= 8) 
    {
        statusUpdateCounter[playerid] = 0;
        new engine, lights, alarm, doors, bonnet, boot, objective;
        GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
        
        if(engine == 1)
            PlayerTextDrawSetString(playerid, SpeedoTD[playerid][12], "~g~ENG");
        else
            PlayerTextDrawSetString(playerid, SpeedoTD[playerid][12], "~r~ENG");
        
        if(lights == 1)
            PlayerTextDrawSetString(playerid, SpeedoTD[playerid][13], "~y~LGT");
        else
            PlayerTextDrawSetString(playerid, SpeedoTD[playerid][13], "~w~LGT");
    }
    
    return 1;
}

/*================== ZONE DETECTION ==================*/

stock GetPlayerZone(playerid, zone[], len)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    // Los Santos Areas
    if(x >= -2997.40 && y >= -1115.58 && x <= -2539.19 && y <= -565.10)
        format(zone, len, "Ocean Docks");
    else if(x >= -2741.07 && y >= -1982.32 && x <= -2178.69 && y <= -1115.58)
        format(zone, len, "Los Santos Int. Airport");
    else if(x >= -2329.310 && y >= -405.679 && x <= -1796.630 && y <= -50.096)
        format(zone, len, "Bayside");
    else if(x >= -2361.510 && y >= -1648.050 && x <= -1996.680 && y <= -1314.070)
        format(zone, len, "El Corona");
    else if(x >= -2178.690 && y >= -1250.970 && x <= -1794.920 && y <= -1115.580)
        format(zone, len, "Downtown Los Santos");
    else if(x >= -1982.320 && y >= -1115.580 && x <= -1794.920 && y <= -794.620)
        format(zone, len, "Downtown Los Santos");
    else if(x >= -1794.920 && y >= -1115.580 && x <= -1213.910 && y <= -794.620)
        format(zone, len, "Commerce");
    else if(x >= -1213.910 && y >= -1115.580 && x <= -794.620 && y <= -794.620)
        format(zone, len, "Market");
    else if(x >= -1115.580 && y >= -1250.970 && x <= -794.620 && y <= -1115.580)
        format(zone, len, "Little Mexico");
    else if(x >= -2533.00 && y >= -405.679 && x <= -2329.310 && y <= -50.096)
        format(zone, len, "Bayside Marina");
    else if(x >= -2994.490 && y >= -222.589 && x <= -2593.440 && y <= 277.411)
        format(zone, len, "Bayside Tunnel");
    else if(x >= -1372.140 && y >= -405.679 && x <= -1115.580 && y <= -50.096)
        format(zone, len, "Garcia");
    else if(x >= -1115.580 && y >= -405.679 && x <= -794.620 && y <= -50.096)
        format(zone, len, "Foster Valley");
    else if(x >= -794.620 && y >= -405.679 && x <= -405.679 && y <= -50.096)
        format(zone, len, "Battery Point");
    else if(x >= -405.679 && y >= -405.679 && x <= -50.096 && y <= -50.096)
        format(zone, len, "Juniper Hill");
    else if(x >= -2741.070 && y >= -50.096 && x <= -2533.000 && y <= 277.411)
        format(zone, len, "Gant Bridge");
    else if(x >= -2533.000 && y >= -50.096 && x <= -2329.310 && y <= 277.411)
        format(zone, len, "Gant Bridge");
    else if(x >= -1996.680 && y >= -1115.580 && x <= -1794.920 && y <= -794.620)
        format(zone, len, "Pershing Square");
    else if(x >= -1996.680 && y >= -1250.970 && x <= -1794.920 && y <= -1115.580)
        format(zone, len, "City Hall");
    else if(x >= -1372.140 && y >= -50.096 && x <= -1115.580 && y <= 277.411)
        format(zone, len, "Juniper Hollow");
    else if(x >= -1115.580 && y >= -50.096 && x <= -794.620 && y <= 277.411)
        format(zone, len, "Palisades");
    else if(x >= -1115.580 && y >= -794.620 && x <= -794.620 && y <= -405.679)
        format(zone, len, "Santa Flora");
    else if(x >= -794.620 && y >= -794.620 && x <= -405.679 && y <= -405.679)
        format(zone, len, "Queens");
    else if(x >= -405.679 && y >= -794.620 && x <= -50.096 && y <= -405.679)
        format(zone, len, "King's");
    else if(x >= -50.096 && y >= -794.620 && x <= 405.679 && y <= -405.679)
        format(zone, len, "Easter Basin");
    else if(x >= -405.679 && y >= -50.096 && x <= -50.096 && y <= 277.411)
        format(zone, len, "Calton Heights");
    else if(x >= -50.096 && y >= -405.679 && x <= 405.679 && y <= -50.096)
        format(zone, len, "Chinatown");
    else if(x >= -50.096 && y >= -50.096 && x <= 405.679 && y <= 277.411)
        format(zone, len, "Financial");
    else if(x >= 405.679 && y >= -405.679 && x <= 794.620 && y <= -50.096)
        format(zone, len, "Doherty");
    else if(x >= 405.679 && y >= -50.096 && x <= 794.620 && y <= 277.411)
        format(zone, len, "Downtown San Fierro");
    else if(x >= 794.620 && y >= -405.679 && x <= 1115.580 && y <= 277.411)
        format(zone, len, "Easter Bay Airport");
    
    // Las Venturas Areas
    else if(x >= 685.0 && y >= 476.093 && x <= 3000.0 && y <= 3000.0)
        format(zone, len, "Las Venturas");
    else if(x >= 1457.390 && y >= 863.229 && x <= 1777.390 && y <= 2342.830)
        format(zone, len, "The Strip");
    else if(x >= 2087.390 && y >= 1383.230 && x <= 2437.390 && y <= 1623.280)
        format(zone, len, "Julius Thruway East");
    else if(x >= 2281.450 && y >= 1135.040 && x <= 2632.830 && y <= 1383.230)
        format(zone, len, "Four Dragons Casino");
    else if(x >= 2437.390 && y >= 1383.230 && x <= 2624.400 && y <= 1783.230)
        format(zone, len, "Rockshore East");
    else if(x >= 2381.680 && y >= -1494.030 && x <= 2421.030 && y <= -1115.580)
        format(zone, len, "Lil' Probe Inn");
    
    // Red County & Flint County
    else if(x >= -1372.140 && y >= -2593.440 && x <= -794.620 && y <= -1982.320)
        format(zone, len, "Red County");
    else if(x >= -1982.320 && y >= -2593.440 && x <= -1372.140 && y <= -1982.320)
        format(zone, len, "Flint County");
    else if(x >= -1213.910 && y >= -2892.970 && x <= -794.620 && y <= -2593.440)
        format(zone, len, "Blueberry");
    else if(x >= -1982.320 && y >= -2892.970 && x <= -1213.910 && y <= -2593.440)
        format(zone, len, "The Panopticon");
    else if(x >= -2533.000 && y >= -2741.070 && x <= -2178.690 && y <= -2178.690)
        format(zone, len, "Angel Pine");
    else if(x >= -1982.320 && y >= -2178.690 && x <= -1213.910 && y <= -1794.920)
        format(zone, len, "Dillimore");
    else if(x >= -1213.910 && y >= -2178.690 && x <= -794.620 && y <= -1794.920)
        format(zone, len, "Hilltop Farm");
    else if(x >= -1982.320 && y >= -1794.920 && x <= -1213.910 && y <= -1115.580)
        format(zone, len, "Richman");
    else if(x >= -1213.910 && y >= -1794.920 && x <= -794.620 && y <= -1115.580)
        format(zone, len, "Mulholland");
    
    // Bone County & Tierra Robada
    else if(x >= -794.620 && y >= 1659.680 && x <= 1213.910 && y <= 2997.060)
        format(zone, len, "Bone County");
    else if(x >= -2997.060 && y >= 1659.680 && x <= -794.620 && y <= 2997.060)
        format(zone, len, "Tierra Robada");
    else if(x >= -1213.910 && y >= 2997.060 && x <= 1659.680 && y <= 3000.0)
        format(zone, len, "Sherman Reservoir");
    else if(x >= -1372.140 && y >= 2381.680 && x <= -794.620 && y <= 2997.060)
        format(zone, len, "Green Palms");
    else if(x >= -2178.690 && y >= 2381.680 && x <= -1372.140 && y <= 2997.060)
        format(zone, len, "Bayside");
    else if(x >= -2997.060 && y >= 2381.680 && x <= -2178.690 && y <= 2997.060)
        format(zone, len, "Gant Bridge");
    
    // Default fallback based on general area
    else if(x >= -3000.0 && y >= -2000.0 && x <= -1500.0 && y <= 1500.0)
        format(zone, len, "Los Santos");
    else if(x >= -3000.0 && y >= -1000.0 && x <= -1500.0 && y <= 3000.0)
        format(zone, len, "San Fierro");
    else if(x >= 500.0 && y >= 500.0 && x <= 3000.0 && y <= 3000.0)
        format(zone, len, "Las Venturas");
    else if(x >= -1500.0 && y >= -3000.0 && x <= 1500.0 && y <= -1500.0)
        format(zone, len, "Red County");
    else if(x >= -1500.0 && y >= 1500.0 && x <= 1500.0 && y <= 3000.0)
        format(zone, len, "Bone County");
    else
        format(zone, len, "San Andreas");
        
    return 1;
}

/*================== HOOKS ==================*/

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
    {
        ShowSpeedometer(playerid);
    }
    else if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
    {
        HideSpeedometer(playerid);
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerSpeedoData[playerid][vs_SpeedoVisible] = false;
    PlayerSpeedoData[playerid][vs_LastSpeed] = 0;
    PlayerSpeedoData[playerid][vs_LastFuel] = 0;
    PlayerSpeedoData[playerid][vs_LastHealth] = 0;
    PlayerSpeedoData[playerid][vs_UpdateTimer] = -1;
    format(PlayerSpeedoData[playerid][vs_LastZone], 32, "");
    
    for(new i = 0; i < 14; i++)
    {
        SpeedoTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(PlayerSpeedoData[playerid][vs_UpdateTimer] != -1)
    {
        KillTimer(PlayerSpeedoData[playerid][vs_UpdateTimer]);
        PlayerSpeedoData[playerid][vs_UpdateTimer] = -1;
    }
    
    return 1;
}

/*================== COMMANDS ==================*/

CMD:speedo(playerid, params[])
{
    if(PlayerSpeedoData[playerid][vs_SpeedoVisible])
    {
        HideSpeedometer(playerid);
        SendClientMessage(playerid, COLOR_YELLOW, "{FFC107}[SPEEDOMETER] {FFFFFF}Da tat speedometer.");
    }
    else
    {
        if(IsPlayerInAnyVehicle(playerid))
        {
            ShowSpeedometer(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "{4CAF50}[SPEEDOMETER] {FFFFFF}Da bat speedometer.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[SPEEDOMETER] {FFFFFF}Ban phai o trong xe de su dung speedometer!");
        }
    }
    return 1;
}