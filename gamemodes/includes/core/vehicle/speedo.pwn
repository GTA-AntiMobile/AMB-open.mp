#include <YSI\YSI_Coding\y_hooks>

#define SPEEDO_UPDATE_INTERVAL 25     
#define SPEED_UPDATE_RATE 1            
#define HEALTH_UPDATE_RATE 5           
#define FUEL_UPDATE_RATE 5            
#define LOCATION_UPDATE_RATE 20        
#define STATUS_UPDATE_RATE 8           

#define MAX_VEHICLE_SPEED 300.0
#define FUEL_CONSUMPTION_RATE 0.1

enum E_VEHICLE_SPEEDO_DATA
{
    bool:vs_SpeedoVisible,
    vs_LastSpeed,
    vs_LastFuel,
    vs_LastHealth,
    vs_LastZone[32],
    vs_UpdateTimer,
    vs_UpdateCounter,              
    vs_LastVehicleID,             
    Float:vs_LastSpeedFloat       
}

new PlayerSpeedoData[MAX_PLAYERS][E_VEHICLE_SPEEDO_DATA];
new PlayerText:Speedo_PTD[MAX_PLAYERS][6];


/*================== SPEEDOMETER FUNCTIONS ==================*/

stock Float:GetVehicleFuelLevel(vehicleid)
{
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0.0;
    
    new Float:fuel = VehicleFuel[vehicleid];
    
    if(fuel < 0.0) fuel = 0.0;
    if(fuel > 1000.0) fuel = 100.0; 
    
    return fuel;
}

stock GetSpeedoTextureName(digit)
{
    new textureName[32];
    switch(digit) {
        case 0: format(textureName, sizeof(textureName), "mdl-2004:Asset0");
        case 1: format(textureName, sizeof(textureName), "mdl-2004:Asset1");
        case 2: format(textureName, sizeof(textureName), "mdl-2004:Asset2");
        case 3: format(textureName, sizeof(textureName), "mdl-2004:Asset3");
        case 4: format(textureName, sizeof(textureName), "mdl-2004:Asset4");
        case 5: format(textureName, sizeof(textureName), "mdl-2004:Asset5");
        case 6: format(textureName, sizeof(textureName), "mdl-2004:Asset6");
        case 7: format(textureName, sizeof(textureName), "mdl-2004:Asset7");
        case 8: format(textureName, sizeof(textureName), "mdl-2004:Asset8");
        case 9: format(textureName, sizeof(textureName), "mdl-2004:Asset9");
        default: format(textureName, sizeof(textureName), "mdl-2004:Asset0");
    }
    return textureName;
}

stock UpdateSpeedoDigits(playerid, speed)
{
    new hundreds = (speed / 100) % 10;
    new tens = (speed / 10) % 10;
    new ones = speed % 10;
    
    // Dynamic color based on speed
    new color;
    if(speed > 150)
        color = 0xFF0000FF;      // Red for dangerous speed
    else if(speed > 100)
        color = 0xFF6600FF;      // Orange for high speed
    else
        color = 0xFFFFFFFF;      // White for normal speed
    
    // Update hundreds digit
    PlayerTextDrawSetString(playerid, Speedo_PTD[playerid][0], GetSpeedoTextureName(hundreds));
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][0], color);
    PlayerTextDrawShow(playerid, Speedo_PTD[playerid][0]);
    
    // Update tens digit
    PlayerTextDrawSetString(playerid, Speedo_PTD[playerid][1], GetSpeedoTextureName(tens));
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][1], color);
    PlayerTextDrawShow(playerid, Speedo_PTD[playerid][1]);
    
    // Update ones digit
    PlayerTextDrawSetString(playerid, Speedo_PTD[playerid][2], GetSpeedoTextureName(ones));
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][2], color);
    PlayerTextDrawShow(playerid, Speedo_PTD[playerid][2]);
    
    // Keep KM/H always white
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][5], 0xFFFFFFFF);
    PlayerTextDrawShow(playerid, Speedo_PTD[playerid][5]);
}





stock CreateSpeedoTextDraws(playerid)
{
    Speedo_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 470.000, 346.000, "mdl-2004:Asset0");
    PlayerTextDrawTextSize(playerid, Speedo_PTD[playerid][0], 22.000, 25.000);
    PlayerTextDrawAlignment(playerid, Speedo_PTD[playerid][0], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, Speedo_PTD[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, Speedo_PTD[playerid][0], 0);
    PlayerTextDrawBackgroundColour(playerid, Speedo_PTD[playerid][0], 255);
    PlayerTextDrawFont(playerid, Speedo_PTD[playerid][0], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Speedo_PTD[playerid][0], true);

    Speedo_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 482.000, 346.000, "mdl-2004:Asset0");
    PlayerTextDrawTextSize(playerid, Speedo_PTD[playerid][1], 22.000, 25.000);
    PlayerTextDrawAlignment(playerid, Speedo_PTD[playerid][1], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][1], -1);
    PlayerTextDrawSetShadow(playerid, Speedo_PTD[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, Speedo_PTD[playerid][1], 0);
    PlayerTextDrawBackgroundColour(playerid, Speedo_PTD[playerid][1], 255);
    PlayerTextDrawFont(playerid, Speedo_PTD[playerid][1], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Speedo_PTD[playerid][1], true);

    Speedo_PTD[playerid][2] = CreatePlayerTextDraw(playerid, 494.000, 346.000, "mdl-2004:Asset0");
    PlayerTextDrawTextSize(playerid, Speedo_PTD[playerid][2], 22.000, 25.000);
    PlayerTextDrawAlignment(playerid, Speedo_PTD[playerid][2], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][2], -1);
    PlayerTextDrawSetShadow(playerid, Speedo_PTD[playerid][2], 0);
    PlayerTextDrawSetOutline(playerid, Speedo_PTD[playerid][2], 0);
    PlayerTextDrawBackgroundColour(playerid, Speedo_PTD[playerid][2], 255);
    PlayerTextDrawFont(playerid, Speedo_PTD[playerid][2], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Speedo_PTD[playerid][2], true);

    Speedo_PTD[playerid][3] = CreatePlayerTextDraw(playerid, 489.000, 368.000, "100.0");
    PlayerTextDrawLetterSize(playerid, Speedo_PTD[playerid][3], 0.230, 0.999);
    PlayerTextDrawAlignment(playerid, Speedo_PTD[playerid][3], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, Speedo_PTD[playerid][3], 1);
    PlayerTextDrawSetOutline(playerid, Speedo_PTD[playerid][3], 0);
    PlayerTextDrawBackgroundColour(playerid, Speedo_PTD[playerid][3], 150);
    PlayerTextDrawFont(playerid, Speedo_PTD[playerid][3], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Speedo_PTD[playerid][3], true);

    Speedo_PTD[playerid][4] = CreatePlayerTextDraw(playerid, 516.000, 368.000, "ML");
    PlayerTextDrawLetterSize(playerid, Speedo_PTD[playerid][4], 0.260, 0.999);
    PlayerTextDrawAlignment(playerid, Speedo_PTD[playerid][4], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, Speedo_PTD[playerid][4], 1);
    PlayerTextDrawSetOutline(playerid, Speedo_PTD[playerid][4], 0);
    PlayerTextDrawBackgroundColour(playerid, Speedo_PTD[playerid][4], 150);
    PlayerTextDrawFont(playerid, Speedo_PTD[playerid][4], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Speedo_PTD[playerid][4], true);

    Speedo_PTD[playerid][5] = CreatePlayerTextDraw(playerid, 512.000, 353.000, "KM/H");
    PlayerTextDrawLetterSize(playerid, Speedo_PTD[playerid][5], 0.230, 1.399);
    PlayerTextDrawAlignment(playerid, Speedo_PTD[playerid][5], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Speedo_PTD[playerid][5], -1);
    PlayerTextDrawSetShadow(playerid, Speedo_PTD[playerid][5], 0);
    PlayerTextDrawSetOutline(playerid, Speedo_PTD[playerid][5], 0);
    PlayerTextDrawBackgroundColour(playerid, Speedo_PTD[playerid][5], 150);
    PlayerTextDrawFont(playerid, Speedo_PTD[playerid][5], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Speedo_PTD[playerid][5], true);
    return 1;
}

stock ShowSpeedometer(playerid)
{
    if(PlayerSpeedoData[playerid][vs_SpeedoVisible]) return 0;
    
    if(Speedo_PTD[playerid][0] == PlayerText:INVALID_TEXT_DRAW)
    {
        CreateSpeedoTextDraws(playerid);
    }
    
    for(new i = 0; i < 6; i++)
    {
        if(Speedo_PTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawShow(playerid, Speedo_PTD[playerid][i]);
        }
    }
    
    PlayerSpeedoData[playerid][vs_SpeedoVisible] = true;
    
    PlayerSpeedoData[playerid][vs_UpdateTimer] = SetTimerEx("UpdateSpeedometer", SPEEDO_UPDATE_INTERVAL, true, "d", playerid);
    
    return 1;
}

stock HideSpeedometer(playerid)
{
    if(!PlayerSpeedoData[playerid][vs_SpeedoVisible]) return 0;
    
    for(new i = 0; i < 6; i++)
    {
        if(Speedo_PTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawHide(playerid, Speedo_PTD[playerid][i]);
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
    
    new vehicleid = GetPlayerVehicleID(playerid);
    if(vehicleid == 0) return 0;
    
    PlayerSpeedoData[playerid][vs_UpdateCounter]++;
    
    if(PlayerSpeedoData[playerid][vs_UpdateCounter] % SPEED_UPDATE_RATE == 0)
    {
        new Float:vx, Float:vy, Float:vz;
        GetVehicleVelocity(vehicleid, vx, vy, vz);
        new Float:currentSpeed = floatsqroot(vx*vx + vy*vy + vz*vz) * 181.5;
        new speed = floatround(currentSpeed);
        
        // Ensure speed is within reasonable bounds
        if(speed < 0) speed = 0;
        if(speed > 999) speed = 999;
        
        // Always update for smoother display
        if(PlayerSpeedoData[playerid][vs_LastSpeed] != speed)
        {
            PlayerSpeedoData[playerid][vs_LastSpeed] = speed;
            PlayerSpeedoData[playerid][vs_LastSpeedFloat] = currentSpeed;
            
            // Update digital speed display using texture digits
            UpdateSpeedoDigits(playerid, speed);
        }
    }
    
    if(PlayerSpeedoData[playerid][vs_UpdateCounter] % FUEL_UPDATE_RATE == 0)
    {
        new Float:fuel = GetVehicleFuelLevel(vehicleid);
        new fuelInt = floatround(fuel);
        
        if(PlayerSpeedoData[playerid][vs_LastFuel] != fuelInt)
        {
            PlayerSpeedoData[playerid][vs_LastFuel] = fuelInt;
            
            // Update fuel display with text
            new fuelText[16];
            format(fuelText, sizeof(fuelText), "%.1f", fuel);
            PlayerTextDrawSetString(playerid, Speedo_PTD[playerid][3], fuelText);
            PlayerTextDrawShow(playerid, Speedo_PTD[playerid][3]);
        }
    }
    
    // Ensure all TextDraws are visible every few updates
    if(PlayerSpeedoData[playerid][vs_UpdateCounter] % 10 == 0)
    {
        for(new i = 0; i < 6; i++)
        {
            if(Speedo_PTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
            {
                PlayerTextDrawShow(playerid, Speedo_PTD[playerid][i]);
            }
        }
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
    PlayerSpeedoData[playerid][vs_UpdateCounter] = 0;
    PlayerSpeedoData[playerid][vs_LastVehicleID] = -1;
    PlayerSpeedoData[playerid][vs_LastSpeedFloat] = 0.0;
    format(PlayerSpeedoData[playerid][vs_LastZone], 32, "");
    
    for(new i = 0; i < 6; i++)
    {
        Speedo_PTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
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