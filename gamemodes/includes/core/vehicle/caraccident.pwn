#include <YSI\YSI_Coding\y_hooks>

#define MIN_EJECT_SPEED 60.0      
#define DAMAGE_THRESHOLD 200.0   
#define EJECT_FORCE_MULTIPLIER 0.8  
#define ACCIDENT_IMMUNITY_TIME 3000 
#define MAX_EJECT_DISTANCE 8.0    
#define MIN_EJECT_DISTANCE 2.0    

enum E_ACCIDENT_VEHICLE_CLASS
{
    ACCIDENT_VEHICLE_MOTORCYCLE,
    ACCIDENT_VEHICLE_CAR,
    ACCIDENT_VEHICLE_TRUCK,
    ACCIDENT_VEHICLE_BOAT,
    ACCIDENT_VEHICLE_PLANE,
    ACCIDENT_VEHICLE_HELICOPTER,
    ACCIDENT_VEHICLE_OTHER
}

new Float:LastVehicleSpeed[MAX_VEHICLES];
new LastVehicleUpdate[MAX_VEHICLES];
new PlayerAccidentTimer[MAX_PLAYERS];
new bool:PlayerInAccident[MAX_PLAYERS];

stock GetVehicleDimensions(modelid, &Float:width, &Float:length, &Float:height)
{
    if(modelid == 448 || modelid == 461 || modelid == 462 || modelid == 463 || 
       modelid == 468 || modelid == 471 || modelid == 521 || modelid == 522 || 
       modelid == 523 || modelid == 581 || modelid == 586)
    {
        width = 0.8;
        length = 2.2;
        height = 1.2;
        return;
    }
    
    if(modelid == 403 || modelid == 414 || modelid == 443 || modelid == 515 || 
       modelid == 531 || modelid == 456 || modelid == 459 || modelid == 482 || 
       modelid == 530 || modelid == 569 || modelid == 590)
    {
        width = 2.5;
        length = 6.0;
        height = 2.5;
        return;
    }
    
    if(modelid >= 400 && modelid <= 611)
    {
        width = 2.0;
        length = 4.5;
        height = 1.5;
        return;
    }
    
    width = 2.0;
    length = 4.5;
    height = 1.5;
}

stock E_ACCIDENT_VEHICLE_CLASS:GetAccidentVehicleClass(modelid)
{
    if(modelid == 448 || modelid == 461 || modelid == 462 || modelid == 463 || 
       modelid == 468 || modelid == 471 || modelid == 521 || modelid == 522 || 
       modelid == 523 || modelid == 581 || modelid == 586)
    {
        return ACCIDENT_VEHICLE_MOTORCYCLE;
    }
    
    if(modelid == 403 || modelid == 414 || modelid == 443 || modelid == 515 || 
       modelid == 531 || modelid == 456 || modelid == 459 || modelid == 482 || 
       modelid == 530 || modelid == 569 || modelid == 590)
    {
        return ACCIDENT_VEHICLE_TRUCK;
    }
    
    if((modelid >= 400 && modelid <= 611) && modelid != 448 && modelid != 461 && 
       modelid != 462 && modelid != 463 && modelid != 468 && modelid != 471 && 
       modelid != 521 && modelid != 522 && modelid != 523 && modelid != 581 && 
       modelid != 586)
    {
        return ACCIDENT_VEHICLE_CAR;
    }
    
    return ACCIDENT_VEHICLE_OTHER;
}

stock Float:GetVehicleSpeedKMH(vehicleid)
{
    new Float:vx, Float:vy, Float:vz;
    GetVehicleVelocity(vehicleid, vx, vy, vz);
    return floatsqroot(vx*vx + vy*vy + vz*vz) * 180.0;
}

stock EjectPlayerFromVehicle(playerid, vehicleid, Float:speed)
{
    if(PlayerInAccident[playerid]) return 0;
    
    new modelid = GetVehicleModel(vehicleid);
    new E_ACCIDENT_VEHICLE_CLASS:vclass = GetAccidentVehicleClass(modelid);
    
    if(vclass == ACCIDENT_VEHICLE_MOTORCYCLE) return 0;
    
    new Float:vehicle_x, Float:vehicle_y, Float:vehicle_z, Float:vehicle_angle;
    GetVehiclePos(vehicleid, vehicle_x, vehicle_y, vehicle_z);
    GetVehicleZAngle(vehicleid, vehicle_angle);
    
    new Float:width, Float:length, Float:height;
    GetVehicleDimensions(modelid, width, length, height);
    
    new Float:eject_distance = (speed - MIN_EJECT_SPEED) * EJECT_FORCE_MULTIPLIER * 0.01;
    
    if(eject_distance < MIN_EJECT_DISTANCE) eject_distance = MIN_EJECT_DISTANCE;
    if(eject_distance > MAX_EJECT_DISTANCE) eject_distance = MAX_EJECT_DISTANCE;
    
    switch(vclass)
    {
        case ACCIDENT_VEHICLE_TRUCK:
        {
            eject_distance *= 0.7;
        }
        case ACCIDENT_VEHICLE_CAR:
        {
            eject_distance *= 1.0;
        }
        default:
        {
            eject_distance *= 0.8;
        }
    }
    
    new Float:eject_x, Float:eject_y, Float:eject_z;
    new Float:side_offset = width * 0.6;
    
    new side = (random(2) == 0) ? 1 : -1;
    
    eject_x = vehicle_x + (side_offset * floatsin(-vehicle_angle + 90.0 * side, degrees));
    eject_y = vehicle_y + (side_offset * floatcos(-vehicle_angle + 90.0 * side, degrees));
    
    new Float:forward_offset = eject_distance * floatsin(-vehicle_angle, degrees);
    new Float:right_offset = eject_distance * floatcos(-vehicle_angle, degrees);
    
    eject_x += forward_offset;
    eject_y += right_offset;
    eject_z = vehicle_z + 1.0;
    
    RemovePlayerFromVehicle(playerid);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    
    ApplyAnimation(playerid, "PED", "FALL_fall", 4.1, 0, 0, 0, 1, 0, 1);
    
    SetTimerEx("DelayedEjectPlayer", 25, false, "dfff", playerid, eject_x, eject_y, eject_z);
    
    new Float:health;
    GetPlayerHealth(playerid, health);
    new Float:damage = (speed - MIN_EJECT_SPEED) * 0.3;
    
    if(damage > 60.0) damage = 60.0;
    
    SetPlayerHealth(playerid, health - damage);
    
    PlayerInAccident[playerid] = true;
    PlayerAccidentTimer[playerid] = SetTimerEx("RemoveAccidentImmunity", ACCIDENT_IMMUNITY_TIME, false, "d", playerid);
    
    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
    
    return 1;
}

forward DelayedEjectPlayer(playerid, Float:x, Float:y, Float:z);
public DelayedEjectPlayer(playerid, Float:x, Float:y, Float:z)
{
    if(!IsPlayerConnected(playerid)) return 0;
    
    SetPlayerPos(playerid, x, y, z);
    
    new Float:vx = (random(6) - 3) * 0.1;
    new Float:vy = (random(6) - 3) * 0.1;
    new Float:vz = random(2) + 0.3;
    
    SetPlayerVelocity(playerid, vx, vy, vz);
    
    SetTimerEx("ApplyLandingAnimation", 600, false, "d", playerid);
    
    return 1;
}

forward ApplyLandingAnimation(playerid);
public ApplyLandingAnimation(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;
    
    if(PlayerInAccident[playerid])
    {
        ApplyAnimation(playerid, "PED", "KO_skid_front", 4.1, 0, 1, 1, 1, 1500, 1);
        SetTimerEx("GetUpAnimation", 1500, false, "d", playerid);
    }
    
    return 1;
}

forward GetUpAnimation(playerid);
public GetUpAnimation(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;
    
    if(PlayerInAccident[playerid])
    {
        ApplyAnimation(playerid, "PED", "getup", 4.1, 0, 0, 0, 0, 0, 1);
    }
    
    return 1;
}

forward RemoveAccidentImmunity(playerid);
public RemoveAccidentImmunity(playerid)
{
    if(IsPlayerConnected(playerid))
    {
        PlayerInAccident[playerid] = false;
        PlayerAccidentTimer[playerid] = 0;
    }
    return 1;
}

hook OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    if(PlayerInAccident[playerid]) return 1;
    
    new Float:speed = GetVehicleSpeedKMH(vehicleid);
    if(speed < MIN_EJECT_SPEED) return 1;
    
    new Float:health;
    GetVehicleHealth(vehicleid, health);
    
    if(health < 800.0)
    {
        new currentTime = GetTickCount();
        if(currentTime - LastVehicleUpdate[vehicleid] > 150)
        {
            new Float:speedDiff = LastVehicleSpeed[vehicleid] - speed;
            
            if(speedDiff > 25.0) 
            {
                EjectPlayerFromVehicle(playerid, vehicleid, LastVehicleSpeed[vehicleid]);
            }
            
            LastVehicleSpeed[vehicleid] = speed;
            LastVehicleUpdate[vehicleid] = currentTime;
        }
    }
    
    return 1;
}

hook OnPlayerUpdate(playerid)
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(PlayerInAccident[playerid]) return 1;
    
    new vehicleid = GetPlayerVehicleID(playerid);
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return 1;
    
    new Float:speed = GetVehicleSpeedKMH(vehicleid);
    new currentTime = GetTickCount();
    
    if(currentTime - LastVehicleUpdate[vehicleid] > 250)
    {
        if(LastVehicleSpeed[vehicleid] > MIN_EJECT_SPEED && speed < LastVehicleSpeed[vehicleid] * 0.4)
        {
            new Float:vehicle_health;
            GetVehicleHealth(vehicleid, vehicle_health);
            
            if(vehicle_health < 900.0)
            {
                EjectPlayerFromVehicle(playerid, vehicleid, LastVehicleSpeed[vehicleid]);
            }
        }
        
        LastVehicleSpeed[vehicleid] = speed;
        LastVehicleUpdate[vehicleid] = currentTime;
    }
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(PlayerAccidentTimer[playerid] != 0)
    {
        KillTimer(PlayerAccidentTimer[playerid]);
        PlayerAccidentTimer[playerid] = 0;
    }
    PlayerInAccident[playerid] = false;
    
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerInAccident[playerid] = false;
    PlayerAccidentTimer[playerid] = 0;
    
    return 1;
}
