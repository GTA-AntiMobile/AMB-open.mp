#include <YSI\YSI_Coding\y_hooks>

// Constants for better maintainability
#define MAX_DEALERSHIP_CARS 30
#define MAX_CARS_PER_PAGE 15
#define DEALERSHIP_DIALOG_ID 9000
#define DEALERSHIP_POS_X 1529.6
#define DEALERSHIP_POS_Y -1691.2
#define DEALERSHIP_POS_Z 13.3
#define DEMO_VEHICLE_OFFSET_X 5.0
#define DEMO_VEHICLE_OFFSET_Y 3.0
#define SPAWN_VEHICLE_OFFSET_X 8.0
#define SPAWN_VEHICLE_OFFSET_Y 4.0



enum E_DEALERSHIP_CAR_DATA
{
    car_ModelID,
    car_Price,
    car_Fuel,
    car_MaxHealth,
    car_Name[32]
}

// Fixed car data - removed duplicate Tampa
new const DealershipCars[MAX_DEALERSHIP_CARS][E_DEALERSHIP_CAR_DATA] = {
    {404, 180000, 85, 950, "Perenniel"},
    {466, 165000, 80, 900, "Glendale"},
    {467, 220000, 90, 980, "Huntley"},
    {474, 175000, 85, 920, "Hermes"},
    {479, 155000, 75, 880, "Regina"},
    {491, 195000, 85, 940, "Virgo"},
    {492, 185000, 80, 930, "Greenwood"},
    {504, 285000, 95, 1050, "Bloodring Banger"},
    {540, 225000, 90, 990, "Vincent"},
    {600, 240000, 95, 1020, "Picador"},
    {602, 275000, 100, 1080, "Alpha"},
    {603, 290000, 100, 1100, "Phoenix"},
    {534, 320000, 105, 1150, "Remington"},
    {536, 350000, 110, 1200, "Blade"},
    {567, 380000, 115, 1250, "Savanna"},
    {575, 210000, 90, 1000, "Broadway"},
    {576, 230000, 95, 1030, "Tornado"},
    {412, 340000, 110, 1180, "Voodoo"},
    {518, 160000, 80, 920, "Buccaneer"},
    {585, 400000, 120, 1300, "Emperor"},
    {529, 270000, 100, 1090, "Willard"},
    {542, 250000, 95, 1040, "Clover"},
    {545, 280000, 105, 1120, "Hustler"},
    {549, 310000, 108, 1160, "Tampa"},
    {550, 330000, 112, 1190, "Sunrise"},
    {566, 295000, 102, 1130, "Tahoma"},
    {580, 265000, 98, 1070, "Stafford"},
    {439, 190000, 88, 960, "Stallion"},
    {418, 420000, 125, 1350, "Moonbeam"},
    {555, 450000, 130, 1400, "Windsor"}
};

// Player data structure
enum E_PLAYER_DEALERSHIP_DATA
{
    bool:pd_InDealership,
    pd_SelectedCar,
    pd_CurrentPage
}

new PlayerDealershipData[MAX_PLAYERS][E_PLAYER_DEALERSHIP_DATA];
new PlayerText:DealershipTD[MAX_PLAYERS][50];
new DemoVehicle[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};

// Pre-calculated values
new const TOTAL_PAGES = (MAX_DEALERSHIP_CARS + MAX_CARS_PER_PAGE - 1) / MAX_CARS_PER_PAGE;

/*================== OPTIMIZED FUNCTIONS ==================*/

stock CreateDealershipTextDraws(playerid)
{
    // Ultra modern background with glass morphism effect
    DealershipTD[playerid][0] = CreatePlayerTextDraw(playerid, 30.0, 60.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][0], 260.0, 380.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][0], 0x000000CC);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][0], 4);
    
    // Main container with premium gradient
    DealershipTD[playerid][39] = CreatePlayerTextDraw(playerid, 35.0, 65.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][39], 250.0, 370.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][39], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][39], 0x1A1A1AFF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][39], 4);
    
    // Top gradient accent bar
    DealershipTD[playerid][40] = CreatePlayerTextDraw(playerid, 35.0, 65.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][40], 250.0, 5.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][40], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][40], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][40], 4);
    
    // Premium header with modern typography
    DealershipTD[playerid][1] = CreatePlayerTextDraw(playerid, 160.0, 75.0, "~b~LUXURY ~w~CLASSIC ~y~SHOWROOM");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][1], 0.300, 1.500);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][1], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][1], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][1], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][1], 2);
    
    // Elegant subtitle
    DealershipTD[playerid][46] = CreatePlayerTextDraw(playerid, 160.0, 90.0, "~w~Timeless Elegance â€¢ Premium Collection");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][46], 0.180, 0.800);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][46], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][46], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][46], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][46], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][46], 1);
    
    // Vehicle showcase area background
    DealershipTD[playerid][48] = CreatePlayerTextDraw(playerid, 40.0, 110.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][48], 240.0, 180.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][48], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][48], 0x222222FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][48], 4);
    
    // Vehicle showcase border
    DealershipTD[playerid][49] = CreatePlayerTextDraw(playerid, 40.0, 110.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][49], 240.0, 2.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][49], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][49], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][49], 4);
    
    // Info panel with glass morphism
    DealershipTD[playerid][41] = CreatePlayerTextDraw(playerid, 40.0, 310.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][41], 240.0, 100.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][41], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][41], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][41], 4);
    
    // Info panel border
    DealershipTD[playerid][47] = CreatePlayerTextDraw(playerid, 40.0, 310.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][47], 240.0, 2.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][47], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][47], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][47], 4);
    
    // Vehicle name section
    DealershipTD[playerid][6] = CreatePlayerTextDraw(playerid, 50.0, 320.0, "~b~SELECTED VEHICLE:");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][6], 0.220, 1.100);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][6], 0x4A90E2FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][6], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][6], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][6], 2);
    
    DealershipTD[playerid][14] = CreatePlayerTextDraw(playerid, 50.0, 335.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][14], 0.250, 1.300);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][14], 0xF1C40FFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][14], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][14], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][14], 2);
    
    // Compact info layout
    DealershipTD[playerid][2] = CreatePlayerTextDraw(playerid, 50.0, 355.0, "~y~ID:~w~");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][2], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][2], 0xFFD700FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][2], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][2], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][2], 2);
    
    DealershipTD[playerid][3] = CreatePlayerTextDraw(playerid, 120.0, 355.0, "~g~FUEL:~w~");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][3], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][3], 0x50C878FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][3], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][3], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][3], 2);
    
    DealershipTD[playerid][4] = CreatePlayerTextDraw(playerid, 190.0, 355.0, "~r~HP:~w~");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][4], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][4], 0xFF6B6BFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][4], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][4], 2);
    
    // Info values
    DealershipTD[playerid][10] = CreatePlayerTextDraw(playerid, 70.0, 355.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][10], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][10], 0xFFFFFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][10], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][10], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][10], 2);
    
    DealershipTD[playerid][11] = CreatePlayerTextDraw(playerid, 140.0, 355.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][11], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][11], 0xFFFFFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][11], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][11], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][11], 2);
    
    DealershipTD[playerid][12] = CreatePlayerTextDraw(playerid, 210.0, 355.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][12], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][12], 0xFFFFFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][12], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][12], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][12], 2);
    
    // Price display
    DealershipTD[playerid][13] = CreatePlayerTextDraw(playerid, 50.0, 375.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][13], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][13], 0x4A90E2FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][13], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][13], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][13], 2);
    
    // Premium action buttons
    DealershipTD[playerid][16] = CreatePlayerTextDraw(playerid, 50.0, 425.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][16], 70.0, 25.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][16], 0x50C878DD);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][16], 4);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][16], true);
    
    DealershipTD[playerid][42] = CreatePlayerTextDraw(playerid, 52.0, 427.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][42], 66.0, 21.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][42], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][42], 4);
    
    DealershipTD[playerid][17] = CreatePlayerTextDraw(playerid, 85.0, 430.0, "~w~PURCHASE");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][17], 0.220, 1.100);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][17], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][17], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][17], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][17], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][17], 2);
    
    // Navigation buttons
    DealershipTD[playerid][33] = CreatePlayerTextDraw(playerid, 140.0, 425.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][33], 45.0, 25.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][33], 0x4A90E2DD);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][33], 4);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][33], true);
    
    DealershipTD[playerid][43] = CreatePlayerTextDraw(playerid, 142.0, 427.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][43], 41.0, 21.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][43], 0x2196F3FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][43], 4);
    
    DealershipTD[playerid][34] = CreatePlayerTextDraw(playerid, 162.5, 430.0, "~w~PREV");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][34], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][34], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][34], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][34], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][34], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][34], 2);
    
    DealershipTD[playerid][35] = CreatePlayerTextDraw(playerid, 195.0, 425.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][35], 45.0, 25.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][35], 0x4A90E2DD);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][35], 4);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][35], true);
    
    DealershipTD[playerid][44] = CreatePlayerTextDraw(playerid, 197.0, 427.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][44], 41.0, 21.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][44], 0x2196F3FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][44], 4);
    
    DealershipTD[playerid][36] = CreatePlayerTextDraw(playerid, 217.5, 430.0, "~w~NEXT");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][36], 0.200, 1.000);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][36], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][36], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][36], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][36], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][36], 2);
    
    // Page indicator
    DealershipTD[playerid][37] = CreatePlayerTextDraw(playerid, 160.0, 455.0, "~y~PAGE ~w~1~y~/~w~2");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][37], 0.220, 1.200);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][37], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][37], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][37], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][37], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][37], 2);
    
    // Vehicle grid with optimized layout
    new Float:startX = 45.0, Float:startY = 115.0;
    new Float:slotWidth = 45.0, Float:slotHeight = 48.0;
    
    for(new i = 0; i < 15; i++)
    {
        new slot = 18 + i;
        new row = i / 5;
        new col = i % 5;
        
        new Float:posX = startX + (col * slotWidth);
        new Float:posY = startY + (row * slotHeight);
        
        DealershipTD[playerid][slot] = CreatePlayerTextDraw(playerid, posX, posY, "_");
        PlayerTextDrawTextSize(playerid, DealershipTD[playerid][slot], 42.0, 45.0);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][slot], -1);
        PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][slot], 0x2A2A2AFF);
        PlayerTextDrawFont(playerid, DealershipTD[playerid][slot], 5);
        PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][slot], true);
    }
    
    // Premium accent
    DealershipTD[playerid][45] = CreatePlayerTextDraw(playerid, 160.0, 300.0, "~y~â?… ~w~LUXURY ~y~â?…");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][45], 0.250, 1.300);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][45], 0xFFD700FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][45], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][45], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][45], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][45], 2);
    
    return 1;
}

stock ShowDealership(playerid)
{
    if(PlayerDealershipData[playerid][pd_InDealership]) return ExitDealership(playerid);
    
    // Optimized camera setup for perfect viewing angle
    new Float:cameraX = DEALERSHIP_POS_X + 8.0;
    new Float:cameraY = DEALERSHIP_POS_Y - 6.0;
    new Float:cameraZ = DEALERSHIP_POS_Z + 6.0;
    new Float:lookX = DEALERSHIP_POS_X + 2.0;
    new Float:lookY = DEALERSHIP_POS_Y + 2.0;
    new Float:lookZ = DEALERSHIP_POS_Z + 2.0;
    
    SetPlayerPos(playerid, DEALERSHIP_POS_X, DEALERSHIP_POS_Y, DEALERSHIP_POS_Z);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    
    // Perfect camera positioning for vehicle showcase
    SetPlayerCameraPos(playerid, cameraX, cameraY, cameraZ);
    SetPlayerCameraLookAt(playerid, lookX, lookY, lookZ);
    
    // Create TextDraws only if needed (optimized)
    if(DealershipTD[playerid][0] == PlayerText:INVALID_TEXT_DRAW)
    {
        CreateDealershipTextDraws(playerid);
    }
    
    // Clean up any existing demo vehicle
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
        DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    
    // Reset player data
    PlayerDealershipData[playerid][pd_SelectedCar] = -1;
    PlayerDealershipData[playerid][pd_CurrentPage] = 0;
    
    // Show interface with optimized delay
    SetTimerEx("ShowDealershipInterface", 500, false, "d", playerid);
    
    return 1;
}

stock ExitDealership(playerid)
{
    // Optimized cleanup process
    CancelSelectTextDraw(playerid);
    
    // Reset player state
    PlayerDealershipData[playerid][pd_InDealership] = false;
    PlayerDealershipData[playerid][pd_SelectedCar] = -1;
    
    // Restore camera
    SetCameraBehindPlayer(playerid);
    
    // Clean up demo vehicle efficiently
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
        DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    
    // Hide all TextDraws efficiently
    for(new i = 0; i < 50; i++)
    {
        if(DealershipTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawHide(playerid, DealershipTD[playerid][i]);
        }
    }
    
    return 1;
}

stock UpdateCarInfo(playerid, slotIndex)
{
    // Optimized bounds checking
    new currentPage = PlayerDealershipData[playerid][pd_CurrentPage];
    new carIndex = (currentPage * MAX_CARS_PER_PAGE) + slotIndex;
    
    if(carIndex < 0 || carIndex >= MAX_DEALERSHIP_CARS) return 0;
    
    PlayerDealershipData[playerid][pd_SelectedCar] = carIndex;
    
    // Optimized vehicle creation with better positioning
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
    }
    
    // Perfect demo vehicle positioning
    new Float:demoX = DEALERSHIP_POS_X + 2.0;
    new Float:demoY = DEALERSHIP_POS_Y + 2.0;
    new Float:demoZ = DEALERSHIP_POS_Z;
    new Float:demoRotation = 135.0; // Perfect angle for showcase
    
    DemoVehicle[playerid] = CreateVehicle(DealershipCars[carIndex][car_ModelID], 
                                        demoX, demoY, demoZ, demoRotation, 
                                        1, 1, 60); // Fixed colors for consistency
    
    // Optimized vehicle parameters
    SetVehicleParamsEx(DemoVehicle[playerid], false, true, false, false, false, false, false);
    
    // Optimized string updates (batch processing)
    new string[64];
    
    // Update vehicle name
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][14], DealershipCars[carIndex][car_Name]);
    
    // Update info values efficiently
    format(string, sizeof(string), "%d", DealershipCars[carIndex][car_ModelID]);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][10], string);
    
    format(string, sizeof(string), "%d%%", DealershipCars[carIndex][car_Fuel]);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][11], string);
    
    format(string, sizeof(string), "%d", DealershipCars[carIndex][car_MaxHealth]);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][12], string);
    
    format(string, sizeof(string), "$%s", FormatMoney(DealershipCars[carIndex][car_Price]));
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][13], string);
    
    return 1;
}

stock BuyCar(playerid)
{
    new carIndex = PlayerDealershipData[playerid][pd_SelectedCar];
    if(carIndex < 0 || carIndex >= MAX_DEALERSHIP_CARS) return 0;
    
    new price = DealershipCars[carIndex][car_Price];
    
    if(GetPlayerMoney(playerid) < price)
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[DEALERSHIP] {FFFFFF}Ban khong du tien! Can them $%s", 
               FormatMoney(price - GetPlayerMoney(playerid)));
        SendClientMessage(playerid, -1, string);
        return 0;
    }
    
    GivePlayerMoney(playerid, -price);
    ExitDealership(playerid);
    
    SetPlayerPos(playerid, DEALERSHIP_POS_X, DEALERSHIP_POS_Y, DEALERSHIP_POS_Z);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    
    CreatePlayerVehicle(playerid, GetPlayerFreeVehicleId(playerid), 
                       DealershipCars[carIndex][car_ModelID], 
                       DEALERSHIP_POS_X + SPAWN_VEHICLE_OFFSET_X, 
                       DEALERSHIP_POS_Y + SPAWN_VEHICLE_OFFSET_Y, 
                       DEALERSHIP_POS_Z, 0.0, 
                       1, 1, 2000000, 0, 0);
    
    new string[128];
    format(string, sizeof(string), "{50C878}[DEALERSHIP] {FFFFFF}Ban da mua thanh cong %s (Model: %d) voi gia $%s!", 
           DealershipCars[carIndex][car_Name], DealershipCars[carIndex][car_ModelID], FormatMoney(price));
    SendClientMessage(playerid, -1, string);
    
    return 1;
}

/*================== CALLBACKS ==================*/

hook OnPlayerConnect(playerid)
{
    PlayerDealershipData[playerid][pd_InDealership] = false;
    PlayerDealershipData[playerid][pd_SelectedCar] = -1;
    PlayerDealershipData[playerid][pd_CurrentPage] = 0;
    DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    
    for(new i = 0; i < 50; i++)
    {
        DealershipTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
        DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    return 1;
}

hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(!PlayerDealershipData[playerid][pd_InDealership]) return 0;
    
    if(playertextid == DealershipTD[playerid][16])
    {
        BuyCar(playerid);
        return 1;
    }
    
    if(playertextid == DealershipTD[playerid][33])
    {
        if(PlayerDealershipData[playerid][pd_CurrentPage] > 0)
        {
            PlayerDealershipData[playerid][pd_CurrentPage]--;
            UpdateDealershipPage(playerid);
        }
        return 1;
    }
    
    if(playertextid == DealershipTD[playerid][35])
    {
        if(PlayerDealershipData[playerid][pd_CurrentPage] < TOTAL_PAGES - 1)
        {
            PlayerDealershipData[playerid][pd_CurrentPage]++;
            UpdateDealershipPage(playerid);
        }
        return 1;
    }
    
    for(new i = 0; i < 15; i++)
    {
        if(playertextid == DealershipTD[playerid][18 + i])
        {
            new currentPage = PlayerDealershipData[playerid][pd_CurrentPage];
            new carIndex = (currentPage * MAX_CARS_PER_PAGE) + i;
            if(carIndex < MAX_DEALERSHIP_CARS)
            {
                UpdateCarInfo(playerid, i);
            }
            return 1;
        }
    }
    
    return 0;
}

hook OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(Text:INVALID_TEXT_DRAW == clickedid)
    {
        if(PlayerDealershipData[playerid][pd_InDealership])
        {
            ExitDealership(playerid);
        }
    }
    return 1;
}

/*================== TIMERS ==================*/

forward ShowDealershipInterface(playerid);
public ShowDealershipInterface(playerid)
{
    // Optimized interface display with batch processing
    if(!PlayerDealershipData[playerid][pd_InDealership])
    {
        // Show all TextDraws efficiently
        for(new i = 0; i < 50; i++)
        {
            if(DealershipTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
            {
                PlayerTextDrawShow(playerid, DealershipTD[playerid][i]);
            }
        }
        
        // Set player state
        PlayerDealershipData[playerid][pd_InDealership] = true;
        PlayerDealershipData[playerid][pd_CurrentPage] = 0;
        
        // Update page and enable selection
        UpdateDealershipPage(playerid);
        SelectTextDraw(playerid, 0xA3B4C5FF);
    }
    else
    {
        ExitDealership(playerid);
    }
    return 1;
}

/*================== COMMANDS ==================*/

CMD:dealership(playerid, params[])
{
    ShowDealership(playerid);
    return 1;
}

CMD:gotodealer(playerid, params[])
{
    SetPlayerPos(playerid, DEALERSHIP_POS_X, DEALERSHIP_POS_Y, DEALERSHIP_POS_Z);
    SetPlayerFacingAngle(playerid, 0.0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    SendClientMessage(playerid, -1, "{4A90E2}[CLASSIC CARS] {FFFFFF}Chao mung den showroom xe co dien!");
    return 1;
}

CMD:carlist(playerid, params[])
{
    new string[128];
    format(string, sizeof(string), "{4A90E2}[CLASSIC CARS] {FFFFFF}Co %d xe classic trong showroom (%d trang)", MAX_DEALERSHIP_CARS, TOTAL_PAGES);
    SendClientMessage(playerid, -1, string);
    return 1;
}

/*================== INITIALIZATION ==================*/

hook OnFeatureSystemInit()
{
    Create3DTextLabel("{4A90E2}â?… PREMIUM CLASSIC SHOWROOM â?…\n{FFFFFF}Exclusive Collection of Classic Vehicles\n{F1C40F}Use /dealership to browse vehicles", 
                      -1, DEALERSHIP_POS_X, DEALERSHIP_POS_Y, DEALERSHIP_POS_Z, 30.0, 0, true);
    
    printf("[DEALERSHIP] Premium system initialized with %d vehicles (%d pages)", MAX_DEALERSHIP_CARS, TOTAL_PAGES);
    return 1;
}

/*================== UTILITY FUNCTIONS ==================*/

stock UpdateDealershipPage(playerid)
{
    new currentPage = PlayerDealershipData[playerid][pd_CurrentPage];
    new startIndex = currentPage * MAX_CARS_PER_PAGE;
    
    for(new i = 0; i < 15; i++)
    {
        new slot = 18 + i;
        new carIndex = startIndex + i;
        
        if(carIndex < MAX_DEALERSHIP_CARS)
        {
            PlayerTextDrawSetPreviewModel(playerid, DealershipTD[playerid][slot], DealershipCars[carIndex][car_ModelID]);
            PlayerTextDrawSetPreviewRot(playerid, DealershipTD[playerid][slot], -9.0, 0.0, -22.0, 1.0);
            PlayerTextDrawSetPreviewVehCol(playerid, DealershipTD[playerid][slot], 1, 0);
            PlayerTextDrawShow(playerid, DealershipTD[playerid][slot]);
        }
        else
        {
            PlayerTextDrawSetPreviewModel(playerid, DealershipTD[playerid][slot], 0);
            PlayerTextDrawSetString(playerid, DealershipTD[playerid][slot], "");
            PlayerTextDrawHide(playerid, DealershipTD[playerid][slot]);
        }
    }
    
    // Update page indicator
    new string[32];
    format(string, sizeof(string), "~y~PAGE ~w~%d~y~/~w~%d", currentPage + 1, TOTAL_PAGES);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][37], string);
    
    // Update navigation button colors with premium styling
    new const disabledColor = 0x444444DD;
    new const disabledTextColor = 0x666666FF;
    new const enabledColor = 0x4A90E2DD;
    new const enabledTextColor = 0x2196F3FF;
    
    // Previous button
    if(currentPage <= 0)
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][33], disabledColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][43], disabledTextColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][34], disabledTextColor);
    }
    else
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][33], enabledColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][43], enabledTextColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][34], -1);
    }
    
    // Next button
    if(currentPage >= TOTAL_PAGES - 1)
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][35], disabledColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][44], disabledTextColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][36], disabledTextColor);
    }
    else
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][35], enabledColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][44], enabledTextColor);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][36], -1);
    }
    
    return 1;
}
