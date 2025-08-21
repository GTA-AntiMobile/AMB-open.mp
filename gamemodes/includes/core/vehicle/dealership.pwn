#include <YSI\YSI_Coding\y_hooks>

enum E_DEALERSHIP_CAR_DATA
{
    car_ModelID,
    car_Price,
    car_Fuel,
    car_MaxHealth,
    car_Name[32]
}

new const DealershipCars[30][E_DEALERSHIP_CAR_DATA] = {
    {404, 180000, 85, 950, "Perenniel"},
    {466, 165000, 80, 900, "Glendale"},
    {467, 220000, 90, 980, "Huntley"},
    {474, 175000, 85, 920, "Hermes"},
    {479, 155000, 75, 880, "Regina"},
    {491, 195000, 85, 940, "Virgo"},
    {492, 185000, 80, 930, "Greenwood"},
    {504, 285000, 95, 1050, "Bloodring Banger"},
    {540, 225000, 90, 990, "Vincent"},
    {542, 195000, 85, 950, "Clover"},
    {549, 175000, 80, 920, "Tampa"},
    {550, 185000, 85, 940, "Sunrise"},
    {566, 205000, 90, 970, "Tahoma"},
    {580, 215000, 85, 980, "Stafford"},
    {585, 235000, 90, 1000, "Emperor"},
    {400, 550000, 100, 1200, "Landstalker"},
    {401, 125000, 70, 850, "Bravura"},
    {405, 95000, 65, 800, "Sentinel"},
    {410, 85000, 60, 780, "Manana"},
    {411, 750000, 100, 1300, "Infernus"},
    {415, 145000, 75, 870, "Cheetah"},
    {420, 55000, 50, 720, "Taxi"},
    {421, 65000, 55, 750, "Washington"},
    {426, 85000, 60, 790, "Premier"},
    {436, 75000, 55, 770, "Previon"},
    {439, 95000, 65, 810, "Stallion"},
    {445, 115000, 70, 840, "Admiral"},
    {451, 850000, 100, 1350, "Turismo"},
    {477, 125000, 75, 860, "ZR-350"},
    {506, 950000, 100, 1400, "Super GT"}
};

enum E_PLAYER_DEALERSHIP_DATA
{
    bool:pd_InDealership,
    pd_SelectedCar,
    pd_CurrentPage,
    Float:pd_CameraAngle,
    Float:pd_VehicleRotation,
    pd_RotationTimer
}

new PlayerDealershipData[MAX_PLAYERS][E_PLAYER_DEALERSHIP_DATA];
new PlayerText:DealershipTD[MAX_PLAYERS][50];
new DemoVehicle[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};

stock CreateDealershipTextDraws(playerid)
{
    DealershipTD[playerid][0] = CreatePlayerTextDraw(playerid, 150.0, 120.0, "");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][0], 0.0, 0.0);
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][0], 490.0, 240.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][0], -1);
    PlayerTextDrawUseBox(playerid, DealershipTD[playerid][0], 1);
    PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][0], 0x000000BB);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][0], 0);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][0], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][0], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][0], 0);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][0], 0);
    
    DealershipTD[playerid][1] = CreatePlayerTextDraw(playerid, 320.0, 125.0, "AMB SHOWROOM");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][1], 0.5, 2.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][1], 2);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][1], 0x4A90E2FF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][1], 1);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][1], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][1], 2);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][1], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][1], 0);
    
    new Float:startX = 160.0, Float:startY = 150.0;
    new Float:carWidth = 100.0, Float:carHeight = 30.0;
    new slot = 0;
    
    for(new row = 0; row < 5; row++)
    {
        for(new col = 0; col < 3; col++)
        {
            new tdIndex = 2 + slot;
            new Float:x = startX + (col * 110.0);
            new Float:y = startY + (row * 35.0);
            
            DealershipTD[playerid][tdIndex] = CreatePlayerTextDraw(playerid, x, y, "");
            PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][tdIndex], 0.0, 0.0);
            PlayerTextDrawTextSize(playerid, DealershipTD[playerid][tdIndex], x + carWidth, y + carHeight);
            PlayerTextDrawAlignment(playerid, DealershipTD[playerid][tdIndex], 1);
            PlayerTextDrawColor(playerid, DealershipTD[playerid][tdIndex], -1);
            PlayerTextDrawSetPreviewModel(playerid, DealershipTD[playerid][tdIndex], 411);
            PlayerTextDrawSetPreviewRot(playerid, DealershipTD[playerid][tdIndex], -9.0, 0.0, -22.0, 1.0);
            PlayerTextDrawSetPreviewVehCol(playerid, DealershipTD[playerid][tdIndex], 1, 0);
            PlayerTextDrawUseBox(playerid, DealershipTD[playerid][tdIndex], 1);
            PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][tdIndex], 0x222222AA);
            PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][tdIndex], 0);
            PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][tdIndex], 0);
            PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][tdIndex], 255);
            PlayerTextDrawFont(playerid, DealershipTD[playerid][tdIndex], 5);
            PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][tdIndex], 0);
            PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][tdIndex], 0);
            PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][tdIndex], 1);
            
            slot++;
        }
    }
    
    DealershipTD[playerid][17] = CreatePlayerTextDraw(playerid, 320.0, 330.0, "Chon mot chiec xe de xem thong tin");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][17], 0.3, 1.2);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][17], 2);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][17], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][17], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][17], 1);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][17], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][17], 2);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][17], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][17], 0);
    
    DealershipTD[playerid][18] = CreatePlayerTextDraw(playerid, 320.0, 350.0, "MUA XE");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][18], 0.4, 1.5);
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][18], 80.0, 20.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][18], 2);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][18], 0xFFFFFFFF);
    PlayerTextDrawUseBox(playerid, DealershipTD[playerid][18], 1);
    PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][18], 0x50C878AA);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][18], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][18], 0);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][18], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][18], 2);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][18], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][18], 0);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][18], 1);
    
    DealershipTD[playerid][19] = CreatePlayerTextDraw(playerid, 200.0, 350.0, "< TRUOC");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][19], 0.3, 1.2);
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][19], 60.0, 15.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][19], 2);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][19], 0xFFFFFFFF);
    PlayerTextDrawUseBox(playerid, DealershipTD[playerid][19], 1);
    PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][19], 0x4A90E2AA);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][19], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][19], 0);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][19], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][19], 2);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][19], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][19], 0);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][19], 1);
    
    DealershipTD[playerid][20] = CreatePlayerTextDraw(playerid, 440.0, 350.0, "TIEP >");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][20], 0.3, 1.2);
    PlayerTextDrawTextSize(playerid, DealershipTD[playerid][20], 60.0, 15.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][20], 2);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][20], 0xFFFFFFFF);
    PlayerTextDrawUseBox(playerid, DealershipTD[playerid][20], 1);
    PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][20], 0x4A90E2AA);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][20], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][20], 0);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][20], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][20], 2);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][20], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][20], 0);
    PlayerTextDrawSetSelectable(playerid, DealershipTD[playerid][20], 1);
    
    DealershipTD[playerid][21] = CreatePlayerTextDraw(playerid, 320.0, 355.0, "Trang 1/2");
    PlayerTextDrawLetterSize(playerid, DealershipTD[playerid][21], 0.25, 1.0);
    PlayerTextDrawAlignment(playerid, DealershipTD[playerid][21], 2);
    PlayerTextDrawColor(playerid, DealershipTD[playerid][21], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][21], 0);
    PlayerTextDrawSetOutline(playerid, DealershipTD[playerid][21], 1);
    PlayerTextDrawBackgroundColor(playerid, DealershipTD[playerid][21], 255);
    PlayerTextDrawFont(playerid, DealershipTD[playerid][21], 2);
    PlayerTextDrawSetProportional(playerid, DealershipTD[playerid][21], 1);
    PlayerTextDrawSetShadow(playerid, DealershipTD[playerid][21], 0);
    
    return 1;
}

stock ShowDealershipInterface(playerid)
{
    for(new i = 0; i < 22; i++)
    {
        PlayerTextDrawShow(playerid, DealershipTD[playerid][i]);
    }
    UpdateDealershipPage(playerid);
    SelectTextDraw(playerid, 0x4A90E2FF);
    return 1;
}

stock HideDealershipInterface(playerid)
{
    for(new i = 0; i < 22; i++)
    {
        PlayerTextDrawHide(playerid, DealershipTD[playerid][i]);
    }
    CancelSelectTextDraw(playerid);
    return 1;
}

stock UpdateDealershipPage(playerid)
{
    new currentPage = PlayerDealershipData[playerid][pd_CurrentPage];
    new startIndex = currentPage * 15;
    
    for(new i = 0; i < 15; i++)
    {
        new tdIndex = 2 + i;
        new carIndex = startIndex + i;
        
        if(carIndex < 30)
        {
            PlayerTextDrawSetPreviewModel(playerid, DealershipTD[playerid][tdIndex], DealershipCars[carIndex][car_ModelID]);
            PlayerTextDrawSetPreviewRot(playerid, DealershipTD[playerid][tdIndex], -9.0, 0.0, -22.0, 1.0);
            PlayerTextDrawSetPreviewVehCol(playerid, DealershipTD[playerid][tdIndex], 1, 0);
            PlayerTextDrawShow(playerid, DealershipTD[playerid][tdIndex]);
        }
        else
        {
            PlayerTextDrawHide(playerid, DealershipTD[playerid][tdIndex]);
        }
    }
    
    new string[32];
    format(string, sizeof(string), "Trang %d/2", currentPage + 1);
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][21], string);
    PlayerTextDrawShow(playerid, DealershipTD[playerid][21]);
    
    if(currentPage <= 0)
    {
        PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][19], 0x666666AA);
    }
    else
    {
        PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][19], 0x4A90E2AA);
    }
    
    if(currentPage >= 1)
    {
        PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][20], 0x666666AA);
    }
    else
    {
        PlayerTextDrawBoxColor(playerid, DealershipTD[playerid][20], 0x4A90E2AA);
    }
    
    PlayerTextDrawShow(playerid, DealershipTD[playerid][19]);
    PlayerTextDrawShow(playerid, DealershipTD[playerid][20]);
    
    return 1;
}

stock UpdateCarInfo(playerid, slotIndex)
{
    new currentPage = PlayerDealershipData[playerid][pd_CurrentPage];
    new carIndex = (currentPage * 15) + slotIndex;
    
    if(carIndex >= 30) return 0;
    
    PlayerDealershipData[playerid][pd_SelectedCar] = carIndex;
    
    new string[128];
    format(string, sizeof(string), "%s - $%s~n~Fuel: %d%% | Health: %d", 
           DealershipCars[carIndex][car_Name], 
           FormatMoney(DealershipCars[carIndex][car_Price]),
           DealershipCars[carIndex][car_Fuel],
           DealershipCars[carIndex][car_MaxHealth]);
    
    PlayerTextDrawSetString(playerid, DealershipTD[playerid][17], string);
    PlayerTextDrawShow(playerid, DealershipTD[playerid][17]);
    
    return 1;
}

stock BuyCar(playerid)
{
    new carIndex = PlayerDealershipData[playerid][pd_SelectedCar];
    if(carIndex == -1) 
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[DEALERSHIP] {FFFFFF}Ban chua chon xe nao!");
        return 0;
    }
    
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
    
    HideDealershipInterface(playerid);
    PlayerDealershipData[playerid][pd_InDealership] = false;
    
    SetPlayerPos(playerid, 1963.0, -1768.0, 13.5);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    
    CreatePlayerVehicle(playerid, GetPlayerFreeVehicleId(playerid), 
                       DealershipCars[carIndex][car_ModelID], 
                       1965.0, -1768.0, 13.5, 0.0, 
                       1, 1, 2000000, 0, 0);
    
    new string[128];
    format(string, sizeof(string), "{50C878}[DEALERSHIP] {FFFFFF}Ban da mua thanh cong %s voi gia $%s!", 
           DealershipCars[carIndex][car_Name], FormatMoney(price));
    SendClientMessage(playerid, -1, string);
    
    return 1;
}

CMD:dealership(playerid, params[])
{
    if(PlayerDealershipData[playerid][pd_InDealership])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[DEALERSHIP] {FFFFFF}Ban da o trong showroom roi!");
        return 1;
    }
    
    PlayerDealershipData[playerid][pd_InDealership] = true;
    PlayerDealershipData[playerid][pd_SelectedCar] = -1;
    PlayerDealershipData[playerid][pd_CurrentPage] = 0;
    
    ShowDealershipInterface(playerid);
    SendClientMessage(playerid, 0x4A90E2FF, "{4A90E2}[AMB SHOWROOM] {FFFFFF}Chao mung ban den voi AMB Showroom!");
    
    return 1;
}

CMD:exitdealership(playerid, params[])
{
    if(!PlayerDealershipData[playerid][pd_InDealership])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[DEALERSHIP] {FFFFFF}Ban khong o trong showroom!");
        return 1;
    }
    
    HideDealershipInterface(playerid);
    PlayerDealershipData[playerid][pd_InDealership] = false;
    SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[DEALERSHIP] {FFFFFF}Ban da thoat khoi showroom!");
    
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerDealershipData[playerid][pd_InDealership] = false;
    PlayerDealershipData[playerid][pd_SelectedCar] = -1;
    PlayerDealershipData[playerid][pd_CurrentPage] = 0;
    PlayerDealershipData[playerid][pd_CameraAngle] = 0.0;
    PlayerDealershipData[playerid][pd_VehicleRotation] = 0.0;
    PlayerDealershipData[playerid][pd_RotationTimer] = -1;
    DemoVehicle[playerid] = INVALID_VEHICLE_ID;
    
    for(new i = 0; i < 50; i++)
    {
        DealershipTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    CreateDealershipTextDraws(playerid);
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(PlayerDealershipData[playerid][pd_RotationTimer] != -1)
    {
        KillTimer(PlayerDealershipData[playerid][pd_RotationTimer]);
        PlayerDealershipData[playerid][pd_RotationTimer] = -1;
    }
    
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
    
    if(playertextid == DealershipTD[playerid][18])
    {
        BuyCar(playerid);
        return 1;
    }
    
    if(playertextid == DealershipTD[playerid][19])
    {
        if(PlayerDealershipData[playerid][pd_CurrentPage] > 0)
        {
            PlayerDealershipData[playerid][pd_CurrentPage]--;
            UpdateDealershipPage(playerid);
        }
        return 1;
    }
    
    if(playertextid == DealershipTD[playerid][20])
    {
        if(PlayerDealershipData[playerid][pd_CurrentPage] < 1)
        {
            PlayerDealershipData[playerid][pd_CurrentPage]++;
            UpdateDealershipPage(playerid);
        }
        return 1;
    }
    
    for(new i = 0; i < 15; i++)
    {
        if(playertextid == DealershipTD[playerid][2 + i])
        {
            UpdateCarInfo(playerid, i);
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
            HideDealershipInterface(playerid);
            PlayerDealershipData[playerid][pd_InDealership] = false;
            SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[DEALERSHIP] {FFFFFF}Ban da thoat khoi showroom!");
        }
    }
    return 1;
}