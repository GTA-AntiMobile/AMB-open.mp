#include <YSI\YSI_Coding\y_hooks>


new Float:LastVehicleSpeed[MAX_VEHICLES];
new LastVehicleUpdate[MAX_VEHICLES];

new PlayerAccidentTimer[MAX_PLAYERS];
new bool:PlayerInAccident[MAX_PLAYERS];

// Constants
#define MIN_EJECT_SPEED 80.0     
#define DAMAGE_THRESHOLD 200.0   
#define EJECT_FORCE 2.5          
#define ACCIDENT_IMMUNITY_TIME 3000 

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

stock E_ACCIDENT_VEHICLE_CLASS:GetAccidentVehicleClass(modelid)
{
    if(modelid == 448 || modelid == 461 || modelid == 462 || modelid == 463 || 
       modelid == 468 || modelid == 471 || modelid == 521 || modelid == 522 || 
       modelid == 523 || modelid == 581 || modelid == 586)
    {
        return ACCIDENT_VEHICLE_MOTORCYCLE;
    }
    
    if((modelid >= 400 && modelid <= 611) && modelid != 448 && modelid != 461 && 
       modelid != 462 && modelid != 463 && modelid != 468 && modelid != 471 && 
       modelid != 521 && modelid != 522 && modelid != 523 && modelid != 581 && 
       modelid != 586)
    {
        if(!(modelid == 403 || modelid == 414 || modelid == 443 || modelid == 515 || 
             modelid == 531 || modelid == 456 || modelid == 459 || modelid == 482 || 
             modelid == 530 || modelid == 569 || modelid == 590))
        {
            return ACCIDENT_VEHICLE_CAR;
        }
    }
    
    return ACCIDENT_VEHICLE_OTHER;
}

stock Float:GetVehicleSpeedKMH(vehicleid)
{
    new Float:vx, Float:vy, Float:vz;
    GetVehicleVelocity(vehicleid, vx, vy, vz);
    return floatsqroot(vx*vx + vy*vy + vz*vz) * 180.0; // Convert to km/h
}

stock EjectPlayerFromVehicle(playerid, vehicleid, Float:speed)
{
    if(PlayerInAccident[playerid]) return 0; // Already in accident
    
    new modelid = GetVehicleModel(vehicleid);
    new E_ACCIDENT_VEHICLE_CLASS:vclass = GetAccidentVehicleClass(modelid);
    
    if(vclass == ACCIDENT_VEHICLE_MOTORCYCLE) return 0;
    
    new Float:x, Float:y, Float:z, Float:angle;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);
    
    new Float:ejectX, Float:ejectY, Float:ejectZ;
    new Float:force = EJECT_FORCE * (speed / 100.0); // Scale force with speed
    
    switch(vclass)
    {
        case ACCIDENT_VEHICLE_CAR:
        {
            new side = random(2) ? 1 : -1; // Random side
            ejectX = x + (force * floatsin(-angle + 90.0 * side, degrees));
            ejectY = y + (force * floatcos(-angle + 90.0 * side, degrees));
            ejectZ = z + 1.5;
        }
        default:
        {
            ejectX = x + (force * floatsin(-angle + 180.0, degrees));
            ejectY = y + (force * floatcos(-angle + 180.0, degrees));
            ejectZ = z + 1.5;
        }
    }
    
    RemovePlayerFromVehicle(playerid);
    
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    ApplyAnimation(playerid, "PED", "FALL_fall", 4.1, 0, 0, 0, 1, 0, 1);
    
    SetTimerEx("DelayedEjectPlayer", 50, false, "dfff", playerid, ejectX, ejectY, ejectZ);
    
    new Float:health;
    GetPlayerHealth(playerid, health);
    new Float:damage = (speed - MIN_EJECT_SPEED) * 0.5; // Scale damage with speed
    if(damage > 80.0) damage = 80.0; // Cap damage
    
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
    
    new Float:vx = (random(4) - 2) * 0.2;
    new Float:vy = (random(4) - 2) * 0.2;
    new Float:vz = random(2) + 0.5;
    
    SetPlayerVelocity(playerid, vx, vy, vz);
    
    SetTimerEx("ApplyLandingAnimation", 800, false, "d", playerid);
    
    return 1;
}

forward ApplyLandingAnimation(playerid);
public ApplyLandingAnimation(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;
    if(PlayerInAccident[playerid])
    {
        ApplyAnimation(playerid, "PED", "KO_skid_front", 4.1, 0, 1, 1, 1, 2000, 1);
        
        SetTimerEx("GetUpAnimation", 2000, false, "d", playerid);
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
    if(PlayerInAccident[playerid]) return 1; // Already in accident
    
    new Float:speed = GetVehicleSpeedKMH(vehicleid);
    
    if(speed < MIN_EJECT_SPEED) return 1;
    
    new Float:health;
    GetVehicleHealth(vehicleid, health);
    
    if(health < 800.0)
    {
        new currentTime = GetTickCount();
        if(currentTime - LastVehicleUpdate[vehicleid] > 100) // Update every 100ms
        {
            new Float:speedDiff = LastVehicleSpeed[vehicleid] - speed;
            
            if(speedDiff > 30.0) 
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
    
    if(currentTime - LastVehicleUpdate[vehicleid] > 200)
    {
        if(LastVehicleSpeed[vehicleid] > MIN_EJECT_SPEED && speed < LastVehicleSpeed[vehicleid] * 0.3)
        {
            new Float:vehicle_health;
            GetVehicleHealth(vehicleid, vehicle_health);
            
            if(vehicle_health < 900.0) // Vehicle damaged
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
