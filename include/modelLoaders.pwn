// File: include/modelLoaders.pwn
// Master Model Loading System - Handles all model types with detailed logging

// Master Model Loading System - Handles all model types with detailed logging
stock LoadCustomModelsFromConfig()
{
    printf("========================================");
    printf("STARTING CUSTOM MODEL LOADING SYSTEM");
    printf("========================================");
    
    // Statistics tracking
    new totalModels = 0, successfulModels = 0;
    new vehicleLoaded = 0, vehicleFailed = 0;
    new skinLoaded = 0, skinFailed = 0; 
    new simpleLoaded = 0, simpleFailed = 0;
    
    // Load Vehicles from custom_vehicles.cfg
    printf("[MODELS] Loading vehicles from custom_vehicles.cfg...");
    new File:vehicleFile = fopen("custom_vehicles.cfg", io_read);
    if(!vehicleFile)
    {
        printf("[MODELS] ERROR: custom_vehicles.cfg not found!");
    }
    else
    {
        new line[256], modelid, name[64], dfffile[128], txdfile[128];
        new lineCount = 0;
        
        while(fread(vehicleFile, line) && vehicleLoaded < 100)
        {
            lineCount++;
            if(strlen(line) < 3 || line[0] == '#' || line[0] == '/') continue;
            
            // Remove newlines
            new len = strlen(line);
            for(new i = 0; i < len; i++)
            {
                if(line[i] == '\n' || line[i] == '\r')
                {
                    line[i] = '\0';
                    break;
                }
            }
            
            if(sscanf(line, "d s[64] s[128] s[128]", modelid, name, dfffile, txdfile) == 0)
            {
                totalModels++;
                if(modelid >= 30001 && modelid <= 40000)
                {
                    new dffPath[144], txdPath[144];
                    format(dffPath, sizeof(dffPath), "/Vehicle/%s", dfffile);
                    format(txdPath, sizeof(txdPath), "/Vehicle/%s", txdfile);
                    
                    // Find base vehicle ID
                    new baseVehicleID = 411 + (vehicleLoaded % 201); // 411-611 range
                    
                    new isSuccess = AddVehicleModel(baseVehicleID, modelid, dffPath, txdPath);
                    if(isSuccess == 0)
                    {
                        vehicleFailed++;
                        printf("[MODELS] FAILED to load vehicle: ID %d (%s) - Line %d", modelid, name, lineCount);
                    }
                    else
                    {
                        vehicleLoaded++;
                        successfulModels++;
                    }
                }
                else
                {
                    vehicleFailed++;
                    printf("[MODELS] Vehicle ID %d out of range - Line %d", modelid, lineCount);
                }
            }
            else
            {
                vehicleFailed++;
                printf("[MODELS] Vehicle parse error - Line %d", lineCount);
            }
        }
        fclose(vehicleFile);
    }
    
    // Load Skins from skins.cfg  
    printf("[MODELS] Loading skins from skins.cfg...");
    new File:skinFile = fopen("skins.cfg", io_read);
    if(!skinFile)
    {
        printf("[MODELS] skins.cfg not found");
    }
    else
    {
        new line[256], modelid, name[64], dfffile[128], txdfile[128];
        new lineCount = 0;
        
        while(fread(skinFile, line) && skinLoaded < 100)
        {
            lineCount++;
            if(strlen(line) < 3 || line[0] == '#' || line[0] == '/') continue;
            
            // Remove newlines
            new len = strlen(line);
            for(new i = 0; i < len; i++)
            {
                if(line[i] == '\n' || line[i] == '\r')
                {
                    line[i] = '\0';
                    break;
                }
            }
            
            if(sscanf(line, "d s[64] s[128] s[128]", modelid, name, dfffile, txdfile) == 0)
            {
                totalModels++;
                if(modelid >= 20001 && modelid <= 29999)
                {
                    new dffPath[144], txdPath[144];
                    format(dffPath, sizeof(dffPath), "/skin/%s", dfffile);
                    format(txdPath, sizeof(txdPath), "/skin/%s", txdfile);
                    
                    new baseSkinID = 2 + (skinLoaded % 10);
                    if(baseSkinID > 299) baseSkinID = 1 + (skinLoaded % 299);
                    
                    new isSuccess = AddCharModel(baseSkinID, modelid, dffPath, txdPath);
                    if(isSuccess == 0)
                    {
                        skinFailed++;
                        printf("[MODELS] FAILED to load skin: ID %d (%s) - Line %d", modelid, name, lineCount);
                    }
                    else
                    {
                        skinLoaded++;
                        successfulModels++;
                    }
                }
                else
                {
                    skinFailed++;
                    printf("[MODELS] Skin ID %d out of range - Line %d", modelid, lineCount);
                }
            }
            else
            {
                skinFailed++;
                printf("[MODELS] Skin parse error - Line %d", lineCount);
            }
        }
        fclose(skinFile);
    }
    
    // Load Simple Objects from simple.cfg
    printf("[MODELS] Loading simple objects from simple.cfg...");
    new File:simpleFile = fopen("simple.cfg", io_read);
    if(!simpleFile)
    {
        printf("[MODELS] simple.cfg not found");
    }
    else
    {
        new line[256], id1, id2, extra, dfffile[128], txdfile[128];
        new lineCount = 0;
        
        while(fread(simpleFile, line) && simpleLoaded < 50)
        {
            lineCount++;
            if(strlen(line) < 3 || line[0] == '#' || line[0] == '/') continue;
            
            // Remove newlines
            new len = strlen(line);
            for(new i = 0; i < len; i++)
            {
                if(line[i] == '\n' || line[i] == '\r')
                {
                    line[i] = '\0';
                    break;
                }
            }
            
            if(sscanf(line, "d d d s[128] s[128]", id1, id2, extra, dfffile, txdfile) == 0)
            {
                totalModels++;
                new isSuccess = AddSimpleModel(id1, id2, extra, dfffile, txdfile);
                if(isSuccess == 0)
                {
                    simpleFailed++;
                    printf("[MODELS] FAILED to load simple object: %s/%s - Line %d", dfffile, txdfile, lineCount);
                }
                else
                {
                    simpleLoaded++;
                    successfulModels++;
                }
            }
            else
            {
                simpleFailed++;
                printf("[MODELS] Simple parse error - Line %d", lineCount);
            }
        }
        fclose(simpleFile);
    }
    
    // Final Summary Report
    printf("========================================");
    printf("MODEL LOADING SUMMARY");
    printf("========================================");
    printf("VEHICLES: %d loaded, %d failed", vehicleLoaded, vehicleFailed);
    printf("SKINS: %d loaded, %d failed", skinLoaded, skinFailed);
    printf("SIMPLE OBJECTS: %d loaded, %d failed", simpleLoaded, simpleFailed);
    printf("TOTAL: %d/%d models (%.1f%% success)", 
           successfulModels, totalModels, 
           totalModels > 0 ? (float(successfulModels) / float(totalModels) * 100.0) : 0.0);
    printf("========================================");
    return 1;
}
