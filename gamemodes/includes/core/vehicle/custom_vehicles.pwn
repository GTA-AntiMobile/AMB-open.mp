/*
    Custom Vehicle System for AMB-Open (Simplified Version)
    Author: GitHub Copilot + Modified  
    Description: Simple custom vehicle management with /cv command
*/

#if !defined _INC_CUSTOMCAR
#define _INC_CUSTOMCAR

// Configuration
#define CUSTOM_MODEL_START      30001
#define CUSTOM_MODEL_END        40000
#define DEFAULT_MODEL_START     400
#define DEFAULT_MODEL_END       611

// Simple validation functions
stock bool:IsValidDefaultVehicle(modelid)
{
    return (modelid >= DEFAULT_MODEL_START && modelid <= DEFAULT_MODEL_END);
}

stock bool:IsValidCustomVehicle(modelid)
{
    return (modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END);
}

CMD:cv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    new modelid, color1 = -1, color2 = -1;
    if (sscanf(params, "dD(-1)D(-1)", modelid, color1, color2))
    {
        SendClientMessage(playerid, 0x4A90E2FF, "SU DUNG: /cv [model ID] [mau1] [mau2]");
        SendClientMessage(playerid, 0xFFD700FF, "VD: /cv 30001 | /cv 30001 3 2 | /cv 411 5 7");
        SendClientMessage(playerid, 0x4CAF50FF, "Regular: 400-611, Custom: 30001-40000");
        return 1;
    }

    // Validate model ID  
    if (!(IsValidDefaultVehicle(modelid) || IsValidCustomVehicle(modelid)))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Model ID khong hop le!");
        SendClientMessage(playerid, 0xFF9800FF, "Su dung Regular (400-611) hoac Custom (30001-40000)");
        return 1;
    }

    // Set default colors if not specified
    if(color1 == -1) color1 = 0;
    if(color2 == -1) color2 = 0;

    // Validate colors
    if(!(0 <= color1 <= 255 && 0 <= color2 <= 255)) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Mau xe phai tu 0 den 255.");
        return 1;
    }

    // Get player position and create vehicle
    new Float: fVehPos[4];
    GetPlayerPos(playerid, fVehPos[0], fVehPos[1], fVehPos[2]);
    GetPlayerFacingAngle(playerid, fVehPos[3]);
    
    // Move player slightly forward to avoid spawning vehicle on player
    fVehPos[0] += 3.0 * floatsin(-fVehPos[3], degrees);
    fVehPos[1] += 3.0 * floatcos(-fVehPos[3], degrees);
    
    // Create vehicle
    new vehicleid = CreateVehicle(modelid, fVehPos[0], fVehPos[1], fVehPos[2], fVehPos[3], color1, color2, -1);
    
    if(vehicleid != INVALID_VEHICLE_ID) {
        SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
        LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
        
        new string[128], vehType[16];
        if(IsValidCustomVehicle(modelid)) {
            format(vehType, sizeof(vehType), "Custom");
        } else {
            format(vehType, sizeof(vehType), "Regular");  
        }
        
        format(string, sizeof(string), "Da tao %s vehicle (Model: %d, ID: %d)", vehType, modelid, vehicleid);
        SendClientMessage(playerid, 0x4CAF50FF, string);
    } else {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong the tao xe! Co loi xay ra.");
    }

    return 1;
}



CMD:listcv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    SendClientMessage(playerid, 0x2196F3FF, "=== CUSTOM VEHICLE INFO ===");
    SendClientMessage(playerid, 0x4CAF50FF, "Custom Vehicle Range: 30001 - 40000");
    SendClientMessage(playerid, 0xFFD700FF, "Models duoc load tu modelLoaders.pwn");
    SendClientMessage(playerid, 0x4A90E2FF, "Su dung: /cv [model_id] [mau1] [mau2]");
    
    return 1;
}

CMD:reloadcv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 4) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    SendClientMessage(playerid, 0x4CAF50FF, "Custom Vehicle System noted!");
    SendClientMessage(playerid, 0xFFD700FF, "Models se duoc reload khi restart server");
    
    printf("[CustomVeh] %s requested CV info", GetPlayerNameEx(playerid));

    return 1;
}

CMD:dcv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    new target_modelid;
    if(sscanf(params, "D(-1)", target_modelid)) {
        SendClientMessage(playerid, 0x4A90E2FF, "SU DUNG: /dcv [model ID]");
        SendClientMessage(playerid, 0xFFD700FF, "VD: /dcv 30002 | /dcv (de xoa xe custom gan nhat)");
        SendClientMessage(playerid, 0x4CAF50FF, "Chi xoa xe Custom (30001-40000)");
        return 1;
    }

    new vehicleid = INVALID_VEHICLE_ID;
    
    if(target_modelid == -1) {
        vehicleid = GetPlayerVehicleID(playerid);
        new Float:distance = 999.0;
        
        if(vehicleid == INVALID_VEHICLE_ID) {
            new Float:player_x, Float:player_y, Float:player_z;
            GetPlayerPos(playerid, player_x, player_y, player_z);
            
            for(new i = 1; i < MAX_VEHICLES; i++) {
                if(IsValidVehicle(i)) {
                    new modelid = GetVehicleModel(i);
                    if(IsValidCustomVehicle(modelid)) {
                        new Float:veh_x, Float:veh_y, Float:veh_z;
                        GetVehiclePos(i, veh_x, veh_y, veh_z);
                        
                        new Float:current_distance = GetPlayerDistanceFromPoint(playerid, veh_x, veh_y, veh_z);
                        if(current_distance < distance) {
                            distance = current_distance;
                            vehicleid = i;
                        }
                    }
                }
            }
            
            if(vehicleid != INVALID_VEHICLE_ID && distance > 10.0) {
                SendClientMessage(playerid, 0xFF6B6BFF, "Khong tim thay xe custom nao gan ban!");
                return 1;
            }
        }
    } else {
        if(!IsValidCustomVehicle(target_modelid)) {
            SendClientMessage(playerid, 0xFF6B6BFF, "Model ID khong hop le! Chi co the xoa xe Custom (30001-40000)!");
            return 1;
        }
        
        new Float:player_x, Float:player_y, Float:player_z;
        GetPlayerPos(playerid, player_x, player_y, player_z);
        new Float:distance = 999.0;
        
        for(new i = 1; i < MAX_VEHICLES; i++) {
            if(IsValidVehicle(i)) {
                new modelid = GetVehicleModel(i);
                if(modelid == target_modelid) {
                    new Float:veh_x, Float:veh_y, Float:veh_z;
                    GetVehiclePos(i, veh_x, veh_y, veh_z);
                    
                    new Float:current_distance = GetPlayerDistanceFromPoint(playerid, veh_x, veh_y, veh_z);
                    if(current_distance < distance) {
                        distance = current_distance;
                        vehicleid = i;
                    }
                }
            }
        }
        
        if(vehicleid == INVALID_VEHICLE_ID) {
            SendClientMessage(playerid, 0xFF6B6BFF, "Khong tim thay xe co Model ID %d!", target_modelid);
            return 1;
        }
    }
    
    if(vehicleid != INVALID_VEHICLE_ID) {
        new modelid = GetVehicleModel(vehicleid);
        DestroyVehicle(vehicleid);
        
        new string[128];
        format(string, sizeof(string), "Da xoa xe Custom (Model: %d, Vehicle ID: %d)", modelid, vehicleid);
        SendClientMessage(playerid, 0x4CAF50FF, string);
        
        printf("[CustomVeh] %s deleted custom vehicle (Model: %d, Vehicle ID: %d)", GetPlayerNameEx(playerid), modelid, vehicleid);
    } else {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong the xoa xe!");
    }

    return 1;
}

#endif
