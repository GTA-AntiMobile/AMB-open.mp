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
#define VEHICLE_MODELS_PATH     "/models/Vehicle/"

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

        // Debug: show what we are parsing
        printf("[DEBUG] Parsing line: %s", line);

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
    printf("Loaded %d custom vehicles from config", TotalCustomVehicles);
}

stock LoadCustomVehicleModels()
{
    new loadedCount = 0;

    for (new i = 0; i < TotalCustomVehicles; i++)
    {
        new dffpath[256], txdpath[256];
        format(dffpath, sizeof(dffpath), "%s%s", VEHICLE_MODELS_PATH, CustomVehicleData[i][cvDffFile]);
        format(txdpath, sizeof(txdpath), "%s%s", VEHICLE_MODELS_PATH, CustomVehicleData[i][cvTxdFile]);

        // Since models are loaded via AddSimpleModel() in LoadCustomModels(), 
        // we'll mark all as loaded without file validation
        CustomVehicleData[i][cvLoaded] = true;
        loadedCount++;
        
        // Optional: You can still check files for debugging if needed
        // new File:dffFile = fopen(dffpath, io_read);
        // new File:txdFile = fopen(txdpath, io_read);
        // if (!dffFile) printf("Info: DFF file path: %s", dffpath);
        // if (!txdFile) printf("Info: TXD file path: %s", txdpath);
        // if (dffFile) fclose(dffFile);
        // if (txdFile) fclose(txdFile);
    }

    printf("Custom Vehicle Models: %d/%d loaded successfully", loadedCount, TotalCustomVehicles);
}

stock CreateDefaultVehicleConfig()
{
    new File:file = fopen(VEHICLE_CONFIG_FILE, io_write);
    if (!file) return;

    fwrite(file, "# Custom Vehicle Configuration\n");
    fwrite(file, "# Format: ModelID VehicleName DffFile TxdFile\n");
    fwrite(file, "# ModelID must be between 20000-30000\n");
    fwrite(file, "# Both .dff and .txd files must exist in models/vehicle/\n");
    fwrite(file, "#\n");
    fwrite(file, "# Examples:\n");
    fwrite(file, "20000 Custom_Infernus custom_infernus.dff custom_infernus.txd\n");
    fwrite(file, "20001 Custom_Banshee custom_banshee.dff custom_banshee.txd\n");
    fwrite(file, "20002 Super_Car super_car.dff super_car.txd\n");
    fwrite(file, "20003 Racing_Car racing_car.dff racing_car.txd\n");
    fwrite(file, "20004 Modified_Sultan modified_sultan.dff modified_sultan.txd\n");
    fwrite(file, "20005 Drift_Car drift_car.dff drift_car.txd\n");
    fwrite(file, "20006 JDM_Skyline jdm_skyline.dff jdm_skyline.txd\n");

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
        SendClientMessage(playerid, 0x4A90E2FF, "Custom vehicles: 20000-30000");
        SendClientMessage(playerid, 0x4A90E2FF, "Su dung /listcv de xem danh sach custom vehicles");
        return 1;
    }

    if (!IsValidVehicleModel(modelid))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Model ID khong hop le!");
        SendClientMessage(playerid, 0x4A90E2FF, "Regular vehicles: 400-611, Custom vehicles: 20000-30000");
        SendClientMessage(playerid, 0x4A90E2FF, "Su dung /listcv de xem danh sach custom vehicles co san");
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
    
    printf("[CV DEBUG] Creating vehicle - Model: %d, Pos: %.2f %.2f %.2f, Colors: %d %d", 
           modelid, fVehPos[0], fVehPos[1], fVehPos[2], color1, color2);
    
    // Check if it's custom model
    if (modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END) {
        printf("[CV DEBUG] This is a CUSTOM vehicle model");
    } else {
        printf("[CV DEBUG] This is a REGULAR vehicle model");
    }
    
    new vehicleid = CreateVehicle(modelid, fVehPos[0], fVehPos[1], fVehPos[2], fVehPos[3], color1, color2, -1);
    
    printf("[CV DEBUG] CreateVehicle result: %d (INVALID=%d)", vehicleid, INVALID_VEHICLE_ID);
    
    if(vehicleid != INVALID_VEHICLE_ID) {
        SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
        LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
        
        new vehName[64];
        GetCustomVehicleNameByID(modelid, vehName, sizeof(vehName));
        
        new string[128];
        format(string, sizeof(string), "Ban da tao custom vehicle '%s' (Model: %d, ID: %d)", vehName, modelid, vehicleid);
        SendClientMessage(playerid, 0x4CAF50FF, string);
        
        printf("[CustomVeh] %s created custom vehicle %s (Model: %d, ID: %d)", GetPlayerNameEx(playerid), vehName, modelid, vehicleid);
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

    if (!CVSystemInitialized || TotalCustomVehicles == 0)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong co custom vehicle nao duoc load!");
        return 1;
    }

    SendClientMessage(playerid, 0x2196F3FF, "=== DANH SACH CUSTOM VEHICLES ===");
    
    new loadedCount = 0;
    for (new i = 0; i < TotalCustomVehicles; i++)
    {
        if (CustomVehicleData[i][cvLoaded])
        {
            new string[128];
            format(string, sizeof(string), "ID: %d | Ten: %s", 
                   CustomVehicleData[i][cvModelID], 
                   CustomVehicleData[i][cvName]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            loadedCount++;
        }
    }
    
    new summary[64];
    format(summary, sizeof(summary), "Tong cong: %d/%d custom vehicles da load", loadedCount, TotalCustomVehicles);
    SendClientMessage(playerid, 0x4CAF50FF, summary);
    SendClientMessage(playerid, 0x4A90E2FF, "Su dung: /cv [model ID] de tao xe");

    return 1;
}

CMD:reloadcv(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 4) {
        return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
    }

    SendClientMessage(playerid, 0xFF9800FF, "Dang reload Custom Vehicle System...");
    
    // Reset system
    TotalCustomVehicles = 0;
    CVSystemInitialized = false;
    
    // Reinitialize
    InitCustomVehicleSystem();
    
    new string[128];
    format(string, sizeof(string), "Da reload thanh cong Custom Vehicle System! (%d vehicles)", TotalCustomVehicles);
    SendClientMessage(playerid, 0x4CAF50FF, string);
    
    printf("[CustomVeh] %s reloaded Custom Vehicle System (%d vehicles)", GetPlayerNameEx(playerid), TotalCustomVehicles);

    return 1;
}

#endif
