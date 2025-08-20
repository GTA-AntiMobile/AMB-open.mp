/*
    Custom Vehicle System for AMB-Open (Updated with TXD support, fixed path & load checks)
    Author: GitHub Copilot + Modified
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
#define VEHICLE_CONFIG_FILE     "cv.cfg"
#define VEHICLE_MODELS_PATH     "models/vehicle/"

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
stock bool:IsValidCustomVehicle(modelid);
stock bool:IsValidDefaultVehicle(modelid);
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

                // check file existence
                if (fexist(dfffile) && fexist(txdfile))
                {
                    CustomVehicleData[TotalCustomVehicles][cvLoaded] = true;
                }
                else
                {
                    CustomVehicleData[TotalCustomVehicles][cvLoaded] = false;
                    printf("Warning: Missing files for model %d (%s)",
                           CustomVehicleData[TotalCustomVehicles][cvModelID],
                           CustomVehicleData[TotalCustomVehicles][cvName]);
                }

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

        new File:dffFile = fopen(dffpath, io_read);
        new File:txdFile = fopen(txdpath, io_read);

        if (dffFile && txdFile)
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
            if (dffFile) fclose(dffFile);
            if (txdFile) fclose(txdFile);

            CustomVehicleData[i][cvLoaded] = false;

            if (!dffFile) printf("Warning: DFF file not found: %s", dffpath);
            if (!txdFile) printf("Warning: TXD file not found: %s", txdpath);
        }
    }

    printf("Successfully validated & loaded %d/%d vehicle models", loadedCount, TotalCustomVehicles);
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
    return ((modelid >= DEFAULT_MODEL_START && modelid <= DEFAULT_MODEL_END)
            || (modelid >= CUSTOM_MODEL_START && modelid <= CUSTOM_MODEL_END));
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
    if (!CVSystemInitialized)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Error: Vehicle system not initialized!");
        return 1;
    }

    new modelid;
    if (sscanf(params, "i", modelid))
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "Usage: /cv [modelid]");
        SendClientMessage(playerid, 0xFFFFFFFF, "Custom vehicles: 20000-30000 | Default vehicles: 400-611");
        return 1;
    }

    if (!IsValidCustomVehicle(modelid) && !IsValidDefaultVehicle(modelid))
    {
        SendClientMessage(playerid, 0xFF0000FF, "Error: Invalid or unloaded vehicle model!");
        return 1;
    }

    return 1;
}

#endif
