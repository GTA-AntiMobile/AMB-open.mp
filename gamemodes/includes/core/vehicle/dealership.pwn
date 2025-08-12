#include <YSI\YSI_Coding\y_hooks>

#define MAX_DEALERSHIP_CARS 30
#define MAX_CARS_PER_PAGE 15
#define DEALERSHIP_DIALOG_ID 9000

enum E_DEALERSHIP_CAR_DATA
{
    car_ModelID,
    car_Price,
    car_Fuel,
    car_MaxHealth,
    car_Name[32]
}

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
    {549, 205000, 87, 940, "Tampa Classic"},
    {418, 420000, 125, 1350, "Moonbeam"}
};

new PlayerDealershipData[MAX_PLAYERS][3];
new PlayerText:DealershipTD[MAX_PLAYERS][50];
new DemoVehicle[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};


/*================== OPTIMIZED FUNCTIONS ==================*/

stock CreateDealershipTextDraws(playerid)
{
    DealershipTD[playerid][0] = CreatePlayerTextDraw(playerid, 50.0, 95.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][0], 220.0, 285.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][0], 0x000000AA);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][0], 4);
    
    DealershipTD[playerid][39] = CreatePlayerTextDraw(playerid, 55.0, 100.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][39], 210.0, 275.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][39], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][39], 0x1A1A1AFF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][39], 4);
    
    DealershipTD[playerid][40] = CreatePlayerTextDraw(playerid, 60.0, 105.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][40], 200.0, 3.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][40], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][40], 0x4A90E2FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][40], 4);
    
    DealershipTD[playerid][1] = CreatePlayerTextDraw(playerid, 160.0, 105.0, "~b~CLASSIC ~w~CARS ~y~SHOWROOM");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][1], 0.35, 1.8);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][1], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][1], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][1], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][1], 2);
    
    DealershipTD[playerid][41] = CreatePlayerTextDraw(playerid, 65.0, 280.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][41], 190.0, 85.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][41], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][41], 0x2C2C2CFF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][41], 4);
    
    DealershipTD[playerid][2] = CreatePlayerTextDraw(playerid, 75.0, 285.0, "~y~Model ID:");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][2], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][2], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][2], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][2], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][2], 2);
    
    DealershipTD[playerid][3] = CreatePlayerTextDraw(playerid, 75.0, 300.0, "~g~Nhien lieu:");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][3], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][3], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][3], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][3], 2);
    
    DealershipTD[playerid][4] = CreatePlayerTextDraw(playerid, 75.0, 315.0, "~r~Suc khoe:");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][4], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][4], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][4], 2);
    
    DealershipTD[playerid][5] = CreatePlayerTextDraw(playerid, 75.0, 330.0, "~w~Gia:");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][5], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][5], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][5], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][5], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][5], 2);
    
    DealershipTD[playerid][10] = CreatePlayerTextDraw(playerid, 145.0, 285.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][10], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][10], 0xFFD700FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][10], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][10], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][10], 2);
    
    DealershipTD[playerid][11] = CreatePlayerTextDraw(playerid, 155.0, 300.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][11], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][11], 0x50C878FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][11], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][11], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][11], 2);
    
    DealershipTD[playerid][12] = CreatePlayerTextDraw(playerid, 135.0, 315.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][12], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][12], 0xFF6B6BFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][12], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][12], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][12], 2);
    
    DealershipTD[playerid][13] = CreatePlayerTextDraw(playerid, 105.0, 330.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][13], 0.320, 1.600);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][13], 0x4A90E2FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][13], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][13], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][13], 2);
    
    DealershipTD[playerid][16] = CreatePlayerTextDraw(playerid, 70.0, 350.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][16], 50.0, 18.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][16], 0x50C878AA);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][16], 4);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][16], true);
    
    DealershipTD[playerid][42] = CreatePlayerTextDraw(playerid, 72.0, 352.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][42], 46.0, 14.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][42], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][42], 4);
    
    DealershipTD[playerid][17] = CreatePlayerTextDraw(playerid, 95.0, 352.0, "~w~MUA XE");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][17], 0.280, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][17], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][17], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][17], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][17], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][17], 2);
    
    DealershipTD[playerid][33] = CreatePlayerTextDraw(playerid, 135.0, 350.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][33], 35.0, 18.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][33], 0x4A90E2AA);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][33], 4);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][33], true);
    
    DealershipTD[playerid][43] = CreatePlayerTextDraw(playerid, 137.0, 352.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][43], 31.0, 14.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][43], 0x2196F3FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][43], 4);
    
    DealershipTD[playerid][34] = CreatePlayerTextDraw(playerid, 152.5, 352.0, "~w~<<");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][34], 0.320, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][34], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][34], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][34], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][34], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][34], 2);
    
    DealershipTD[playerid][35] = CreatePlayerTextDraw(playerid, 185.0, 350.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][35], 35.0, 18.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][35], 0x4A90E2AA);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][35], 4);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][35], true);
    
    DealershipTD[playerid][44] = CreatePlayerTextDraw(playerid, 187.0, 352.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][44], 31.0, 14.0);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][44], 0x2196F3FF);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][44], 4);
    
    DealershipTD[playerid][36] = CreatePlayerTextDraw(playerid, 202.5, 352.0, "~w~>>");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][36], 0.320, 1.400);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][36], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][36], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][36], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][36], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][36], 2);
    
    DealershipTD[playerid][37] = CreatePlayerTextDraw(playerid, 160.0, 370.0, "~y~Trang ~w~1~y~/~w~2");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][37], 0.300, 1.500);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][37], -1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][37], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][37], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][37], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][37], 2);
    
    DealershipTD[playerid][6] = CreatePlayerTextDraw(playerid, 63.0, 265.0, "Ten xe:");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][6], 0.280, 1.500);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][6], 0x4A90E2FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][6], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][6], 1);
    
    DealershipTD[playerid][14] = CreatePlayerTextDraw(playerid, 110.0, 266.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][14], 0.270, 1.399);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][14], 0xF1C40FFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][14], 1);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][14], 1);
    
    new Float:startX = 65.0, Float:startY = 130.0;
    new Float:slotWidth = 38.0, Float:slotHeight = 42.0;
    
    for(new i = 0; i < 15; i++)
    {
        new slot = 18 + i;
        new row = i / 5;
        new col = i % 5;
        
        new Float:posX = startX + (col * slotWidth);
        new Float:posY = startY + (row * slotHeight);
        
        DealershipTD[playerid][slot] = CreatePlayerTextDraw(playerid, posX, posY, "_");
        PlayerTextDrawTextSize(playerid, DealershipTD[playerid][slot], 35.0, 38.0);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][slot], -1);
        PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][slot], 0x1A1A1AFF);
        PlayerTextDrawFont(playerid, DealershipTD[playerid][slot], 5);
        PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][slot], true);
        
        // Don't set preview model here - let UpdateDealershipPage handle it
    }
    
    DealershipTD[playerid][45] = CreatePlayerTextDraw(playerid, 160.0, 265.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][45], 0.350, 1.600);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][45], 0xFFD700FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][45], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][45], 1);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][45], 2);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][45], 2);
    
    return 1;
}

stock ShowDealership(playerid)
{
    if(PlayerDealershipData[playerid][0]) return ExitDealership(playerid);
    
    SetPlayerPos(playerid, 1529.6, -1691.2, 13.3);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    
    SetPlayerCameraPos(playerid, 1535.0, -1695.0, 18.0);
    SetPlayerCameraLookAt(playerid, 1529.6, -1691.2, 15.0);
    
    if(DealershipTD[playerid][0] == PlayerText:INVALID_TEXT_DRAW)
    {
        CreateDealershipTextDraws(playerid);
    }
    
    SetTimerEx("ShowDealershipInterface", 1000, false, "d", playerid);
    
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
        DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    
    PlayerDealershipData[playerid][1] = -1;
    return 1;
}

stock ExitDealership(playerid)
{
    CancelSelectTextDraw(playerid);
    PlayerDealershipData[playerid][0] = 0;
    PlayerDealershipData[playerid][1] = -1;
    SetCameraBehindPlayer(playerid);
    
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
        DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    
    for(new i = 0; i < 50; i++)
    {
        PlayerTextDrawHide(playerid, DealershipTD[playerid][i]);
    }
    
    return 1;
}

stock UpdateCarInfo(playerid, slotIndex)
{
    new currentPage = PlayerDealershipData[playerid][2];
    new carIndex = (currentPage * MAX_CARS_PER_PAGE) + slotIndex;
    
    if(carIndex < 0 || carIndex >= MAX_DEALERSHIP_CARS) return 0;
    
    PlayerDealershipData[playerid][1] = carIndex;
    
    if(DemoVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(DemoVehicle[playerid]);
    }
    
    new Float:demoRotation = 90.0 + random(180);
    DemoVehicle[playerid] = CreateVehicle(DealershipCars[carIndex][car_ModelID], 1529.6 + 5.0, -1691.2 + 3.0, 13.3, demoRotation, random(126), random(126), 60);
    
    SetVehicleParamsEx(DemoVehicle[playerid], false, true, false, false, false, false, false);
    
    new string[64];
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][14], DealershipCars[carIndex][car_Name]);
    
    format(string, sizeof(string), "%d", DealershipCars[carIndex][car_ModelID]);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][10], string);
    
    format(string, sizeof(string), "%d%%", DealershipCars[carIndex][car_Fuel]);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][11], string);
    
    format(string, sizeof(string), "%d HP", DealershipCars[carIndex][car_MaxHealth]);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][12], string);
    
    format(string, sizeof(string), "$%s", FormatMoney(DealershipCars[carIndex][car_Price]));
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][13], string);
    
    return 1;
}

stock BuyCar(playerid)
{
    new carIndex = PlayerDealershipData[playerid][1];
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
    
    SetPlayerPos(playerid, 1529.6, -1691.2, 13.3);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    
    CreatePlayerVehicle(playerid, GetPlayerFreeVehicleId(playerid), 
                       DealershipCars[carIndex][car_ModelID], 
                       1529.6 + 8.0, -1691.2 + 4.0, 13.3, 0.0, 
                       1, 1, 2000000, 0, 0);
    
    new string[128];
    format(string, sizeof(string), "{50C878}[DEALERSHIP] {FFFFFF}Ban da mua thanh cong %s (Model: %d) voi gia $%s!", 
           DealershipCars[carIndex][car_Name], DealershipCars[carIndex][car_ModelID], FormatMoney(price));
    SendClientMessage(playerid, -1, string);
    
    return 1;
}

stock FormatMoney(amount)
{
    new string[32], result[32];
    format(string, sizeof(string), "%d", amount);
    
    new len = strlen(string);
    new resultPos = 0;
    
    for(new i = 0; i < len; i++)
    {
        if(i > 0 && (len - i) % 3 == 0)
        {
            result[resultPos] = ',';
            resultPos++;
        }
        result[resultPos] = string[i];
        resultPos++;
    }
    result[resultPos] = '\0';
    
    return result;
}

/*================== CALLBACKS ==================*/

hook OnPlayerConnect(playerid)
{
    PlayerDealershipData[playerid][0] = 0;
    PlayerDealershipData[playerid][1] = -1;
    PlayerDealershipData[playerid][2] = 0;
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
    if(!PlayerDealershipData[playerid][0]) return 0;
    
    if(playertextid == DealershipTD[playerid][16])
    {
        BuyCar(playerid);
        return 1;
    }
    
    if(playertextid == DealershipTD[playerid][33])
    {
        if(PlayerDealershipData[playerid][2] > 0)
        {
            PlayerDealershipData[playerid][2]--;
            UpdateDealershipPage(playerid);
        }
        return 1;
    }
    
    if(playertextid == DealershipTD[playerid][35])
    {
        new totalPages = (MAX_DEALERSHIP_CARS + MAX_CARS_PER_PAGE - 1) / MAX_CARS_PER_PAGE;
        if(PlayerDealershipData[playerid][2] < totalPages - 1)
        {
            PlayerDealershipData[playerid][2]++;
            UpdateDealershipPage(playerid);
        }
        return 1;
    }
    
    for(new i = 0; i < 15; i++)
    {
        if(playertextid == DealershipTD[playerid][18 + i])
        {
            new currentPage = PlayerDealershipData[playerid][2];
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
        if(PlayerDealershipData[playerid][0])
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
    if(PlayerDealershipData[playerid][0] == 0)
    {
        for(new i = 0; i < 50; i++)
        {
            PlayerTextDrawShow(playerid, DealershipTD[playerid][i]);
        }
        
        PlayerDealershipData[playerid][0] = 1;
        PlayerDealershipData[playerid][2] = 0;
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
    SetPlayerPos(playerid, 1529.6, -1691.2, 13.3);
    SetPlayerFacingAngle(playerid, 0.0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    SendClientMessage(playerid, -1, "{4A90E2}[CLASSIC CARS] {FFFFFF}Chao mung den showroom xe co dien!");
    return 1;
}

CMD:carlist(playerid, params[])
{
    new string[128];
    format(string, sizeof(string), "{4A90E2}[CLASSIC CARS] {FFFFFF}Co %d xe classic trong showroom (2 trang)", MAX_DEALERSHIP_CARS);
    SendClientMessage(playerid, -1, string);
    return 1;
}

/*================== INITIALIZATION ==================*/

hook OnFeatureSystemInit()
{
    Create3DTextLabel("{4A90E2}Xe Co Dien Classic\n{FFFFFF}Showroom xe co dien\n{F1C40F}Su dung /dealership de xem xe", 
                      -1, 1529.6, -1691.2, 13.3, 30.0, 0, true);
    
    printf("[DEALERSHIP] System initialized with %d vehicles", MAX_DEALERSHIP_CARS);
    return 1;
}

/*================== UTILITY FUNCTIONS ==================*/

stock UpdateDealershipPage(playerid)
{
    new currentPage = PlayerDealershipData[playerid][2];
    new totalPages = (MAX_DEALERSHIP_CARS + MAX_CARS_PER_PAGE - 1) / MAX_CARS_PER_PAGE;
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
            // Completely hide empty slots and remove any preview model
            PlayerTextDrawSetPreviewModel(playerid, DealershipTD[playerid][slot], 0);
            PlayerTextDrawSetString(playerid, DealershipTD[playerid][slot], "");
            PlayerTextDrawHide(playerid, DealershipTD[playerid][slot]);
        }
    }
    
    new string[32];
    format(string, sizeof(string), "~y~Trang ~w~%d~y~/~w~%d", currentPage + 1, totalPages);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][37], string);
    
    if(currentPage <= 0)
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][33], 0x666666AA);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][43], 0x808080FF);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][34], 0x808080FF);
    }
    else
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][33], 0x4A90E2AA);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][43], 0x2196F3FF);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][34], -1);
    }
    
    if(currentPage >= totalPages - 1)
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][35], 0x666666AA);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][44], 0x808080FF);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][36], 0x808080FF);
    }
    else
    {
        PlayerTextDrawColor(playerid, DealershipTD[playerid][35], 0x4A90E2AA);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][44], 0x2196F3FF);
        PlayerTextDrawColor(playerid, DealershipTD[playerid][36], -1);
    }
    
    return 1;
}
