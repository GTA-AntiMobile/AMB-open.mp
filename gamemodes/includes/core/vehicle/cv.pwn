/*
    Custom Vehicle System for AMB-Open (Updated with TXD support)
    Author: GitHub Copilot
    Description: Load custom vehicle models (.dff) and textures (.txd)
*/

#if !defined _INC_CUSTOMCAR
#define _INC_CUSTOMCAR

// Configuration
#define MAX_CUSTOM_VEHICLES     1000
#define CUSTOM_MODEL_START      20000
#define CUSTOM_MODEL_END        30000
#define DEFAULT_MODEL_START     400
#define DEFAULT_MODEL_END       611
#define VEHICLE_CONFIG_FILE     "scriptfiles/cv.cfg"
#define VEHICLE_MODELS_PATH     "models/vehicle/"

// Vehicle data structure
enum E_CUSTOM_VEHICLE_DATA
{
    cvModelID,
    cvName[64],
    cvDffFile[128],
    cvTxdFile[128],
    bool:cvLoaded
}

// Global variables
static CustomVehicleData[MAX_CUSTOM_VEHICLES][E_CUSTOM_VEHICLE_DATA];
static TotalCustomVehicles = 0;
static bool:CVSystemInitialized = false;

// Function prototypes
stock LoadCustomVehicleModels();
stock LoadCustomVehicleConfig();
stock bool:IsValidCustomVehicle(modelid);
stock bool:IsValidDefaultVehicle(modelid);
stock GetCustomVehicleNameByID(modelid, name[], maxsize);

// Initialize system
stock InitCustomVehicleSystem()
{
    print("Loading Custom Vehicle System...");
    LoadCustomVehicleConfig();
    LoadCustomVehicleModels();
    CVSystemInitialized = true;
    printf("Custom Vehicle System loaded: %d vehicles", TotalCustomVehicles);
}

// Load vehicle configuration from file
stock LoadCustomVehicleConfig()
{
    new File:file = fopen(VEHICLE_CONFIG_FILE, io_read);
    if(!file)
    {
        printf("Warning: Could not open %s - Creating default config", VEHICLE_CONFIG_FILE);
        CreateDefaultVehicleConfig();
        return;
    }

    new line[256], modelid, name[64], dfffile[128], txdfile[128];
    TotalCustomVehicles = 0;

    while(fread(file, line) && TotalCustomVehicles < MAX_CUSTOM_VEHICLES)
    {
        // Skip empty lines and comments
        if(strlen(line) < 3 || line[0] == '#' || line[0] == '/')
            continue;

        // Remove newline characters
        new len = strlen(line);
        for(new i = 0; i < len; i++)
        {
            if(line[i] == '\n' || line[i] == '\r')
            {
                line[i] = '\0';
                break;
            }
        }

        // Parse line: ModelID Name DffFile TxdFile
        if(sscanf(line, "p< >is[64]s[128]s[128]", modelid, name, dfffile, txdfile))
        {
            if(modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END)
            {
                CustomVehicleData[TotalCustomVehicles][cvModelID] = modelid;
                strcpy(CustomVehicleData[TotalCustomVehicles][cvName], name, 64);
                strcpy(CustomVehicleData[TotalCustomVehicles][cvDffFile], dfffile, 128);
                strcpy(CustomVehicleData[TotalCustomVehicles][cvTxdFile], txdfile, 128);
                CustomVehicleData[TotalCustomVehicles][cvLoaded] = false;
                TotalCustomVehicles++;
            }
        }
    }

    fclose(file);
    printf("Loaded %d custom vehicles from config", TotalCustomVehicles);
}

// Load vehicle models
stock LoadCustomVehicleModels()
{
    new loadedCount = 0;
    
    for(new i = 0; i < TotalCustomVehicles; i++)
    {
        new dffpath[256], txdpath[256];
        format(dffpath, sizeof(dffpath), "%s%s", VEHICLE_MODELS_PATH, CustomVehicleData[i][cvDffFile]);
        format(txdpath, sizeof(txdpath), "%s%s", VEHICLE_MODELS_PATH, CustomVehicleData[i][cvTxdFile]);
        
        // Check if both model files exist
        new File:dffFile = fopen(dffpath, io_read);
        new File:txdFile = fopen(txdpath, io_read);
        
        if(dffFile && txdFile)
        {
            fclose(dffFile);
            fclose(txdFile);
            CustomVehicleData[i][cvLoaded] = true;
            loadedCount++;
            
            printf("Loaded vehicle: %s (ID: %d) - DFF: %s, TXD: %s", 
                CustomVehicleData[i][cvName], 
                CustomVehicleData[i][cvModelID],
                CustomVehicleData[i][cvDffFile],
                CustomVehicleData[i][cvTxdFile]
            );
        }
        else
        {
            if(dffFile) fclose(dffFile);
            if(txdFile) fclose(txdFile);
            
            if(!dffFile) printf("Warning: DFF file not found: %s", dffpath);
            if(!txdFile) printf("Warning: TXD file not found: %s", txdpath);
        }
    }
    
    printf("Successfully loaded %d/%d vehicle models", loadedCount, TotalCustomVehicles);
}

// Create default configuration file
stock CreateDefaultVehicleConfig()
{
    new File:file = fopen(VEHICLE_CONFIG_FILE, io_write);
    if(!file) return;

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

// Check if model is valid custom vehicle
stock bool:IsValidCustomVehicle(modelid)
{
    if(modelid < CUSTOM_MODEL_START || modelid > CUSTOM_MODEL_END)
        return false;

    for(new i = 0; i < TotalCustomVehicles; i++)
    {
        if(CustomVehicleData[i][cvModelID] == modelid && CustomVehicleData[i][cvLoaded])
            return true;
    }
    return false;
}

// Check if model is valid default vehicle
stock bool:IsValidDefaultVehicle(modelid)
{
    return (modelid >= DEFAULT_MODEL_START && modelid <= DEFAULT_MODEL_END);
}

// Get custom vehicle name by model ID
stock GetCustomVehicleNameByID(modelid, name[], maxsize)
{
    name[0] = '\0';
    
    for(new i = 0; i < TotalCustomVehicles; i++)
    {
        if(CustomVehicleData[i][cvModelID] == modelid)
        {
            strcpy(name, CustomVehicleData[i][cvName], maxsize);
            return;
        }
    }
}

// Get default vehicle name by model ID
stock GetDefaultVehicleNameByID(modelid, name[], maxsize)
{
    static const vehicleNames[212][] = {
        "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perennial", "Sentinel", "Dumper",
        "Fire Truck", "Trashmaster", "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule",
        "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington",
        "Bobcat", "Mr. Whoopee", "BF Injection", "Hunter", "Premier", "Enforcer", "Securicar",
        "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Article Trailer",
        "Previon", "Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer",
        "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Article Trailer 2",
        "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair",
        "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider",
        "Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy",
        "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito",
        "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper", "Rancher",
        "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact",
        "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer A",
        "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey",
        "Bike", "Mountain Bike", "Beagle", "Cropdust", "Stunt", "Tanker", "Road Train",
        "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000",
        "Cement Truck", "Tow Truck", "Fortune", "Cadrona", "FBI Truck", "Willard", "Forklift",
        "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak",
        "Vortex", "Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder",
        "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite",
        "Windsor", "Monster A", "Monster B", "Uranus", "Jester", "Sultan", "Stratium", "Elegy",
        "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight", "Trailer",
        "Kart", "Mower", "Duneride", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30",
        "Huntley", "Stafford", "BF-400", "Newsvan", "Tug", "Trailer A", "Emperor", "Wayfarer",
        "Euros", "Hotdog", "Club", "Trailer B", "Trailer C", "Andromada", "Dodo", "RC Cam",
        "Launch", "Police Car (LSPD)", "Police Car (SFPD)", "Police Car (LVPD)", "Police Ranger",
        "Picador", "S.W.A.T. Van", "Alpha", "Phoenix", "Glendale", "Sadler", "Luggage Trailer A",
        "Luggage Trailer B", "Stair Trailer", "Boxville", "Farm Plow", "Utility Trailer"
    };

    new vehicleIndex = modelid - 400;
    if(vehicleIndex >= 0 && vehicleIndex < sizeof(vehicleNames))
    {
        strcpy(name, vehicleNames[vehicleIndex], maxsize);
    }
    else
    {
        strcpy(name, "Unknown Vehicle", maxsize);
    }
}

// Command: Spawn custom vehicle
CMD:cv(playerid, params[])
{
    if(!CVSystemInitialized)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Error: Vehicle system not initialized!");
        return 1;
    }

    new modelid;
    if(sscanf(params, "i", modelid))
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "Usage: /cv [modelid]");
        SendClientMessage(playerid, 0xFFFFFFFF, "Custom vehicles: 20000-30000 | Default vehicles: 400-611");
        return 1;
    }

    // Validate model ID
    if(!IsValidCustomVehicle(modelid) && !IsValidDefaultVehicle(modelid))
    {
        SendClientMessage(playerid, 0xFF0000FF, "Error: Invalid model ID! Use 400-611 or 20000-30000");
        return 1;
    }

    // Get player position
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);

    // Spawn vehicle
    new vehicleid = CreateVehicle(modelid, x + 3.0, y, z, angle, -1, -1, 60);
    
    if(vehicleid != INVALID_VEHICLE_ID)
    {
        new vehicleName[64];
        if(IsValidCustomVehicle(modelid))
        {
            GetCustomVehicleNameByID(modelid, vehicleName, sizeof(vehicleName));
            if(strlen(vehicleName) == 0)
                format(vehicleName, sizeof(vehicleName), "Custom Vehicle %d", modelid);
        }
        else
        {
            GetDefaultVehicleNameByID(modelid, vehicleName, sizeof(vehicleName));
        }
        
        new string[128];
        format(string, sizeof(string), "Vehicle spawned: %s (ID: %d, Model: %d)", vehicleName, vehicleid, modelid);
        SendClientMessage(playerid, 0x00FF00FF, string);
        
        // Put player in vehicle
        PutPlayerInVehicle(playerid, vehicleid, 0);
    }
    else
    {
        SendClientMessage(playerid, 0xFF0000FF, "Error: Failed to spawn vehicle!");
    }

    return 1;
}

// Command: Help
CMD:cvhelp(playerid, params[])
{
    SendClientMessage(playerid, 0xFFFFFFFF, "=== Custom Vehicle System Help ===");
    SendClientMessage(playerid, 0xFFFFFFFF, "/cv [modelid] - Spawn a vehicle");
    SendClientMessage(playerid, 0xFFFFFFFF, "Default vehicles: 400-611 (SA-MP default vehicles)");
    SendClientMessage(playerid, 0xFFFFFFFF, "Custom vehicles: 20000-30000 (loaded from models/vehicle/)");
    SendClientMessage(playerid, 0xFFFFFFFF, "Config file: scriptfiles/cv.cfg");
    SendClientMessage(playerid, 0xFFFFFFFF, "Required files: .dff (model) and .txd (texture)");
    
    new string[128];
    format(string, sizeof(string), "Total custom vehicles loaded: %d", TotalCustomVehicles);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

// Hook to initialize system when gamemode starts
public OnGameModeInit()
{
    InitCustomVehicleSystem();
    
    #if defined CV_OnGameModeInit
        return CV_OnGameModeInit();
    #else
        return 1;
    #endif
}
#if defined _ALS_OnGameModeInit
    #undef OnGameModeInit
#else
    #define _ALS_OnGameModeInit
#endif

#define OnGameModeInit CV_OnGameModeInit
#if defined CV_OnGameModeInit
    forward CV_OnGameModeInit();
#endif

#endif