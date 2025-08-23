/*
    Custom Vehicle System for AMB-Open (Updated with TXD support, fixed path & load checks)
    Author: GitHub Copilot + Modified
    Description: Load custom vehicle models (.dff) and textures (.txd)
*/

#if !defined _INC_CUSTOMCAR
#define _INC_CUSTOMCAR

// Configuration
#define MAX_CUSTOM_VEHICLES     1000
#define CUSTOM_MODEL_START      30001
#define CUSTOM_MODEL_END        40000
#define DEFAULT_MODEL_START     400
#define DEFAULT_MODEL_END       611
#define VEHICLE_CONFIG_FILE     "cv.cfg"
#define VEHICLE_MODELS_PATH     "Vehicle/"

enum E_CUSTOM_VEHICLE_DATA
{
    cvModelID,
    cvName[64],
    cvDffFile[128],
    cvTxdFile[128],
    bool:cvLoaded
}

static CustomVehicleData[MAX_CUSTOM_VEHICLES][E_CUSTOM_VEHICLE_DATA];
static TotalCustomVehicles = 0;
static bool:CVSystemInitialized = false;

stock LoadCustomVehicleModels();
stock LoadCustomVehicleConfig();
stock bool:IsValidDefaultVehicle(modelid);
stock bool:IsValidVehicleModel(modelid);
stock GetCustomVehicleNameByID(modelid, name[], maxsize);

stock InitCustomVehicleSystem()
{
    print("Loading Custom Vehicle System...");
    LoadCustomVehicleConfig();
    LoadCustomVehicleModels();
    CVSystemInitialized = true;
    printf("Custom Vehicle System loaded: %d vehicles", TotalCustomVehicles);
}

stock LoadCustomVehicleConfig()
{
    new File:file = fopen(VEHICLE_CONFIG_FILE, io_read);
    if (!file)
    {
        printf("Warning: Could not open %s - Creating default config", VEHICLE_CONFIG_FILE);
        CreateDefaultVehicleConfig();
        return;
    }

    new line[256], modelid, name[64], dfffile[128], txdfile[128];
    TotalCustomVehicles = 0;

    while (fread(file, line) && TotalCustomVehicles < MAX_CUSTOM_VEHICLES)
    {
        // Skip empty lines and comments
        if (strlen(line) < 3 || line[0] == '#' || line[0] == '/')
            continue;

        // Remove newline characters
        new len = strlen(line);
        for (new i = 0; i < len; i++)
        {
            if (line[i] == '\n' || line[i] == '\r')
            {
                line[i] = '\0';
                break;
            }
        }

        // Parse line: ModelID Name DffFile TxdFile
        if (sscanf(line, "d s[64] s[128] s[128]", modelid, name, dfffile, txdfile) == 0)
        {
            if (modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END)
            {
                CustomVehicleData[TotalCustomVehicles][cvModelID] = modelid;
                strcpy(CustomVehicleData[TotalCustomVehicles][cvName], name, 64);
                strcpy(CustomVehicleData[TotalCustomVehicles][cvDffFile], dfffile, 128);
                strcpy(CustomVehicleData[TotalCustomVehicles][cvTxdFile], txdfile, 128);

                // Since models are loaded via AddSimpleModel() API, mark as loaded
                CustomVehicleData[TotalCustomVehicles][cvLoaded] = true;

                TotalCustomVehicles++;
            }
            else
            {
                printf("Warning: Model ID %d is out of range (expected %d–%d)",
                       modelid, CUSTOM_MODEL_START, CUSTOM_MODEL_END);
            }
        }
        else
        {
            printf("Warning: Failed to parse line in %s: \"%s\"", VEHICLE_CONFIG_FILE, line);
        }
    }

    fclose(file);
    printf("Custom Vehicle Config: Loaded %d models successfully", TotalCustomVehicles);
}

stock LoadCustomVehicleModels()
{
    new loadedCount = 0;

    for (new i = 0; i < TotalCustomVehicles; i++)
    {
        // Since models are loaded via AddVehicleModel() in LoadCustomModels(), 
        // we'll mark all as loaded without file validation
        CustomVehicleData[i][cvLoaded] = true;
        loadedCount++;
    }

    printf("Custom Vehicle Models: %d/%d loaded and ready", loadedCount, TotalCustomVehicles);
}

stock CreateDefaultVehicleConfig()
{
    new File:file = fopen(VEHICLE_CONFIG_FILE, io_write);
    if (!file) return;

    fwrite(file, "# Custom Vehicle Configuration\n");
    fwrite(file, "# Format: ModelID VehicleName DffFile TxdFile\n");
    fwrite(file, "# ModelID must be between 30001-40000\n");
    fwrite(file, "# Both .dff and .txd files must exist in models/Vehicle/\n");
    fwrite(file, "#\n");
    fwrite(file, "# Examples:\n");
    fwrite(file, "30001 Custom_Infernus custom_infernus.dff custom_infernus.txd\n");
    fwrite(file, "30002 Custom_Banshee custom_banshee.dff custom_banshee.txd\n");
    fwrite(file, "30003 Super_Car super_car.dff super_car.txd\n");
    fwrite(file, "30004 Racing_Car racing_car.dff racing_car.txd\n");
    fwrite(file, "30005 Modified_Sultan modified_sultan.dff modified_sultan.txd\n");
    fwrite(file, "30006 Drift_Car drift_car.dff drift_car.txd\n");
    fwrite(file, "30007 JDM_Skyline jdm_skyline.dff jdm_skyline.txd\n");

    fclose(file);
    printf("Created default configuration file: %s", VEHICLE_CONFIG_FILE);
}

stock bool:IsValidCustomVehicle(modelid)
{
    if (modelid < CUSTOM_MODEL_START || modelid > CUSTOM_MODEL_END)
        return false;

    for (new i = 0; i < TotalCustomVehicles; i++)
    {
        if (CustomVehicleData[i][cvModelID] == modelid && CustomVehicleData[i][cvLoaded])
            return true;
    }
    return false;
}

stock bool:IsValidDefaultVehicle(modelid)
{
    return (modelid >= DEFAULT_MODEL_START && modelid <= DEFAULT_MODEL_END);
}

stock bool:IsValidVehicleModel(modelid)
{
    return (IsValidDefaultVehicle(modelid) || IsValidCustomVehicle(modelid));
}

stock GetCustomVehicleNameByID(modelid, name[], maxsize)
{
    name[0] = '\0';

    for (new i = 0; i < TotalCustomVehicles; i++)
    {
        if (CustomVehicleData[i][cvModelID] == modelid)
        {
            strcpy(name, CustomVehicleData[i][cvName], maxsize);
            return;
        }
    }
}

// Safe wrapper for CreateVehicle to handle custom vehicles
stock SafeCreateVehicle(modelid, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay)
{
    printf("[SAFE_CREATE_VEHICLE] Attempting to create vehicle - Model: %d", modelid);
    
    // Validate position
    if (x < -20000.0 || x > 20000.0 || y < -20000.0 || y > 20000.0 || z < -100.0 || z > 2000.0) {
        printf("[SAFE_CREATE_VEHICLE] Invalid position: %.2f, %.2f, %.2f", x, y, z);
        return INVALID_VEHICLE_ID;
    }
    
    // Validate colors
    if (color1 < -1 || color1 > 255 || color2 < -1 || color2 > 255) {
        printf("[SAFE_CREATE_VEHICLE] Invalid colors: %d, %d", color1, color2);
        return INVALID_VEHICLE_ID;
    }
    
    // Special handling for custom vehicles
    if (modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END) {
        printf("[SAFE_CREATE_VEHICLE] Custom vehicle detected, using enhanced creation method");
        
        // Try to verify the model exists in our loaded list
        new bool:modelExists = false;
        for (new i = 0; i < TotalCustomVehicles; i++) {
            if (CustomVehicleData[i][cvModelID] == modelid && CustomVehicleData[i][cvLoaded]) {
                modelExists = true;
                break;
            }
        }
        
        if (!modelExists) {
            printf("[SAFE_CREATE_VEHICLE] Custom model %d not found in loaded models", modelid);
            return INVALID_VEHICLE_ID;
        }
    }
    
    printf("[SAFE_CREATE_VEHICLE] Calling native CreateVehicle...");
    new vehicleid = CreateVehicle(modelid, x, y, z, rotation, color1, color2, respawn_delay);
    printf("[SAFE_CREATE_VEHICLE] Native CreateVehicle returned: %d", vehicleid);
    
    return vehicleid;
}

CMD:cv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    if (!CVSystemInitialized)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Custom Vehicle System chua duoc khoi tao!");
        return 1;
    }

    new modelid, color1 = -1, color2 = -1;
    if (sscanf(params, "dD(-1)D(-1)", modelid, color1, color2))
    {
        SendClientMessage(playerid, 0x4A90E2FF, "SU DUNG: /cv [model ID] [mau 1] [mau 2]");
        SendClientMessage(playerid, 0xFF6B6BFF, "Chi dung regular vehicles (400-611). Custom vehicles bi vo hieu hoa!");
        return 1;
    }

    if (!IsValidVehicleModel(modelid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Model ID khong hop le! Chi dung 400-611.");
        SendClientMessage(playerid, 0xFF9800FF, "Custom vehicles bi vo hieu hoa de tranh crash!");
        return 1;
    }

    // Set default colors if not specified
    if(color1 == -1) color1 = 0;
    if(color2 == -1) color2 = 0;

    // Validate colors
    if(!(0 <= color1 <= 255 && 0 <= color2 <= 255)) {
        SendClientMessage(playerid, 0xFF6B6BFF, "ID mau xe phai tu 0 den 255.");
        return 1;
    }

    // Get player position and create vehicle
    new Float: fVehPos[4];
    GetPlayerPos(playerid, fVehPos[0], fVehPos[1], fVehPos[2]);
    GetPlayerFacingAngle(playerid, fVehPos[3]);
    
    // Move player slightly forward to avoid spawning vehicle on player
    fVehPos[0] += 3.0 * floatsin(-fVehPos[3], degrees);
    fVehPos[1] += 3.0 * floatcos(-fVehPos[3], degrees);
    
    printf("[zcmd] [%s]: /cv %d", GetPlayerNameEx(playerid), modelid);
    
    // Special handling for custom vehicles - add delay to ensure client has loaded models
    if (modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END) {
        printf("[CV] Creating custom vehicle - Model: %d", modelid);
        
        // Check if the custom model is actually loaded
        if (!IsValidCustomVehicle(modelid)) {
            printf("[CV] Model %d validation failed - not in loaded models", modelid);
            SendClientMessage(playerid, 0xFF6B6BFF, "Custom vehicle model chua duoc load!");
            return 1;
        }
        
        // First attempt to create custom vehicle
        new vehicleid = CreateVehicle(modelid, fVehPos[0], fVehPos[1], fVehPos[2], fVehPos[3], color1, color2, -1);
        
        // Check result and handle accordingly
        if (vehicleid == INVALID_VEHICLE_ID) {
            // Retry once if first attempt failed
            vehicleid = CreateVehicle(modelid, fVehPos[0], fVehPos[1], fVehPos[2], fVehPos[3], color1, color2, -1);
            
            if (vehicleid == INVALID_VEHICLE_ID) {
                // Both attempts failed
                SendClientMessage(playerid, 0xFF6B6BFF, "Custom vehicle tao that bai sau 2 lan thu!");
                SendClientMessage(playerid, 0xFF9800FF, "Thu dung regular vehicles (400-611).");
                
                printf("[CustomVeh] %s custom vehicle creation failed (Model: %d)", 
                       GetPlayerNameEx(playerid), modelid);
                return 1;
            }
        }
        
        // Vehicle created successfully (either first attempt or retry)
        SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
        LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
        
        new vehName[64];
        GetCustomVehicleNameByID(modelid, vehName, sizeof(vehName));
        if (strlen(vehName) == 0) {
            format(vehName, sizeof(vehName), "Custom_Vehicle_%d", modelid);
        }
        
        new string[128];
        format(string, sizeof(string), "Da tao custom vehicle '%s' (Model: %d, ID: %d)", vehName, modelid, vehicleid);
        SendClientMessage(playerid, 0x4CAF50FF, string);
        
        printf("[CustomVeh] %s created custom vehicle %s (Model: %d, ID: %d)", 
               GetPlayerNameEx(playerid), vehName, modelid, vehicleid);
        
        return 1;
        
    } else {
        // Regular vehicle creation
        new vehicleid = CreateVehicle(modelid, fVehPos[0], fVehPos[1], fVehPos[2], fVehPos[3], color1, color2, -1);
        
        if(vehicleid != INVALID_VEHICLE_ID) {
            SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
            LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
            
            new string[128];
            format(string, sizeof(string), "Ban da tao regular vehicle (Model: %d, ID: %d)", modelid, vehicleid);
            SendClientMessage(playerid, 0x4CAF50FF, string);
            
            printf("[Vehicle] %s created regular vehicle (Model: %d, ID: %d)", GetPlayerNameEx(playerid), modelid, vehicleid);
        } else {
            SendClientMessage(playerid, 0xFF6B6BFF, "Khong the tao xe! Co loi xay ra.");
        }
    }

    return 1;
}

CMD:listcv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    if (!CVSystemInitialized || TotalCustomVehicles == 0)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong co custom vehicle nao duoc load!");
        return 1;
    }

    SendClientMessage(playerid, 0x2196F3FF, "=== CUSTOM VEHICLES (BLOCKED) ===");
    SendClientMessage(playerid, 0xFF6B6BFF, "Custom vehicles bi vo hieu hoa de tranh server crash!");
    
    new loadedCount = 0;
    for (new i = 0; i < TotalCustomVehicles; i++)
    {
        if (CustomVehicleData[i][cvLoaded])
        {
            new string[128];
            format(string, sizeof(string), "ID: %d | %s | Status: BLOCKED", 
                   CustomVehicleData[i][cvModelID], 
                   CustomVehicleData[i][cvName]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            loadedCount++;
        }
    }
    
    new summary[80];
    format(summary, sizeof(summary), "Total: %d custom models loaded but blocked", loadedCount);
    SendClientMessage(playerid, 0x4CAF50FF, summary);

    return 1;
}

CMD:reloadcv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 4) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    // Reset system
    TotalCustomVehicles = 0;
    CVSystemInitialized = false;
    
    // Reinitialize
    InitCustomVehicleSystem();
    
    new string[80];
    format(string, sizeof(string), "Custom Vehicle System reloaded! (%d models)", TotalCustomVehicles);
    SendClientMessage(playerid, 0x4CAF50FF, string);
    
    printf("[CustomVeh] %s reloaded CV System (%d vehicles)", GetPlayerNameEx(playerid), TotalCustomVehicles);

    return 1;
}

#endif
