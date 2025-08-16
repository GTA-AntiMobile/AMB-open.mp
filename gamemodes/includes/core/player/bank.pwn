#include <YSI\YSI_Coding\y_hooks>

#define MAX_BANK_ACCOUNTS 1000
#define BANK_DIALOG_ID 8000
#define BANK_TRANSFER_DIALOG_ID 8002
#define BANK_AMOUNT_DIALOG_ID 8003

#define MIN_TRANSACTION_AMOUNT 1
#define MAX_TRANSACTION_AMOUNT 10000000
#define MAX_CASH_LIMIT 50000000
#define MAX_BANK_LIMIT 100000000
#define TRANSACTION_COOLDOWN 3 // seconds
#define MAX_DAILY_TRANSACTIONS 50

#define BANK_POS_X 1459.0
#define BANK_POS_Y -1010.0
#define BANK_POS_Z 26.8

#define BANK_TD_BASE_X 150.0
#define BANK_TD_BASE_Y 120.0

enum E_PLAYER_BANK_DATA
{
    bool:pb_InBank,
    pb_SelectedOption,
    pb_TransferTarget,
    pb_TransferAmount,
    pb_LastTransaction,
    pb_DailyTransactions,
    pb_LastTransactionDay
}

enum E_BANK_MENU_OPTIONS
{
    BANK_OPTION_BALANCE = 0,
    BANK_OPTION_DEPOSIT,
    BANK_OPTION_WITHDRAW,
    BANK_OPTION_TRANSFER,
    BANK_OPTION_EXIT
}

new PlayerBankData[MAX_PLAYERS][E_PLAYER_BANK_DATA];
new PlayerText:BankTD[MAX_PLAYERS][23];

stock CreateBankTextDraws(playerid)
{
    BankTD[playerid][0] = CreatePlayerTextDraw(playerid, 120.0, 100.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][0], 360.0, 300.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][0], 0x000000DD);
    PlayerTextDrawFont(playerid, BankTD[playerid][0], 4);
    
    BankTD[playerid][1] = CreatePlayerTextDraw(playerid, 125.0, 105.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][1], 350.0, 290.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][1], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][1], 0x1A1A1AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][1], 4);
    
    BankTD[playerid][2] = CreatePlayerTextDraw(playerid, 125.0, 105.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][2], 350.0, 5.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][2], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][2], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, BankTD[playerid][2], 4);
    
    BankTD[playerid][3] = CreatePlayerTextDraw(playerid, 300.0, 120.0, "~g~$$ ~w~NGAN HANG QUOC GIA ~g~$$");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][3], 0.350, 1.600);
    PlayerTextDrawColor(playerid, BankTD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][3], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][3], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][3], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][3], 2);
    
    BankTD[playerid][4] = CreatePlayerTextDraw(playerid, 300.0, 140.0, "~w~Dich Vu Ngan Hang An Toan • Phuc Vu 24/7");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][4], 0.200, 1.000);
    PlayerTextDrawColor(playerid, BankTD[playerid][4], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][4], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][4], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][4], 1);
    
    BankTD[playerid][5] = CreatePlayerTextDraw(playerid, 135.0, 160.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][5], 330.0, 60.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][5], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][5], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][5], 4);
    
    BankTD[playerid][6] = CreatePlayerTextDraw(playerid, 135.0, 160.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][6], 330.0, 2.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][6], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][6], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, BankTD[playerid][6], 4);
    
    BankTD[playerid][7] = CreatePlayerTextDraw(playerid, 145.0, 170.0, "~g~CHU TAI KHOAN:");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][7], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][7], 0x4CAF50FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][7], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][7], 1);
    PlayerTextDrawFont(playerid, BankTD[playerid][7], 2);
    
    BankTD[playerid][8] = CreatePlayerTextDraw(playerid, 145.0, 185.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][8], 0.250, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][8], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][8], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][8], 1);
    PlayerTextDrawFont(playerid, BankTD[playerid][8], 2);
    
    BankTD[playerid][9] = CreatePlayerTextDraw(playerid, 350.0, 170.0, "~g~SO DU:");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][9], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][9], 0x4CAF50FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][9], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][9], 1);
    PlayerTextDrawFont(playerid, BankTD[playerid][9], 2);
    
    BankTD[playerid][10] = CreatePlayerTextDraw(playerid, 350.0, 185.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][10], 0.280, 1.400);
    PlayerTextDrawColor(playerid, BankTD[playerid][10], 0xFFD700FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][10], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][10], 1);
    PlayerTextDrawFont(playerid, BankTD[playerid][10], 2);
    
    BankTD[playerid][11] = CreatePlayerTextDraw(playerid, 145.0, 200.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][11], 0.180, 0.900);
    PlayerTextDrawColor(playerid, BankTD[playerid][11], 0xAAAAAAFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][11], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][11], 1);
    PlayerTextDrawFont(playerid, BankTD[playerid][11], 1);
    
    BankTD[playerid][12] = CreatePlayerTextDraw(playerid, 135.0, 240.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][12], 330.0, 140.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][12], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][12], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][12], 4);
    
    BankTD[playerid][13] = CreatePlayerTextDraw(playerid, 300.0, 250.0, "~w~DICH VU NGAN HANG");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][13], 0.250, 1.300);
    PlayerTextDrawColor(playerid, BankTD[playerid][13], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][13], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][13], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][13], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][13], 2);
    
    new Float:buttonY = 275.0;
    new Float:buttonSpacing = 25.0;
    
    BankTD[playerid][14] = CreatePlayerTextDraw(playerid, 145.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][14], 100.0, 20.0);
    PlayerTextDrawColor(playerid, BankTD[playerid][14], 0x4CAF50DD);
    PlayerTextDrawFont(playerid, BankTD[playerid][14], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][14], true);
    
    BankTD[playerid][15] = CreatePlayerTextDraw(playerid, 195.0, buttonY + 2.0, "~w~GUI TIEN");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][15], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][15], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][15], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][15], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][15], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][15], 2);
    
    buttonY += buttonSpacing;
    BankTD[playerid][16] = CreatePlayerTextDraw(playerid, 145.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][16], 100.0, 20.0);
    PlayerTextDrawColor(playerid, BankTD[playerid][16], 0xFF5722DD);
    PlayerTextDrawFont(playerid, BankTD[playerid][16], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][16], true);
    
    BankTD[playerid][17] = CreatePlayerTextDraw(playerid, 195.0, buttonY + 2.0, "~w~RUT TIEN");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][17], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][17], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][17], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][17], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][17], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][17], 2);
    
    buttonY += buttonSpacing;
    BankTD[playerid][18] = CreatePlayerTextDraw(playerid, 145.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][18], 100.0, 20.0);
    PlayerTextDrawColor(playerid, BankTD[playerid][18], 0x2196F3DD);
    PlayerTextDrawFont(playerid, BankTD[playerid][18], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][18], true);
    
    BankTD[playerid][19] = CreatePlayerTextDraw(playerid, 195.0, buttonY + 2.0, "~w~CHUYEN TIEN");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][19], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][19], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][19], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][19], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][19], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][19], 2);
    
    BankTD[playerid][20] = CreatePlayerTextDraw(playerid, 355.0, 275.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][20], 100.0, 20.0);
    PlayerTextDrawColor(playerid, BankTD[playerid][20], 0x757575DD);
    PlayerTextDrawFont(playerid, BankTD[playerid][20], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][20], true);
    
    BankTD[playerid][21] = CreatePlayerTextDraw(playerid, 405.0, 277.0, "~w~THOAT");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][21], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][21], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][21], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][21], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][21], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][21], 2);
    
    BankTD[playerid][22] = CreatePlayerTextDraw(playerid, 300.0, 385.0, "~g~An Toan • Tin Cay • Chuyen Nghiep");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][22], 0.180, 0.900);
    PlayerTextDrawColor(playerid, BankTD[playerid][22], 0x4CAF50FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][22], 0);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][22], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][22], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][22], 1);
    
    return 1;
}

stock ShowBankInterface(playerid)
{
    if(PlayerBankData[playerid][pb_InBank]) return ExitBank(playerid);
    
    if(BankTD[playerid][0] == PlayerText:INVALID_TEXT_DRAW)
    {
        CreateBankTextDraws(playerid);
    }
    
    UpdateBankAccountInfo(playerid);
    
    for(new i = 0; i < 23; i++)
    {
        if(BankTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawShow(playerid, BankTD[playerid][i]);
        }
    }
    
    PlayerBankData[playerid][pb_InBank] = true;
    SelectTextDraw(playerid, 0xA3B4C5FF);
    
    return 1;
}

stock ExitBank(playerid)
{
    CancelSelectTextDraw(playerid);
    
    for(new i = 0; i < 23; i++)
    {
        if(BankTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawHide(playerid, BankTD[playerid][i]);
        }
    }
    
    PlayerBankData[playerid][pb_InBank] = false;
    
    return 1;
}

stock UpdateBankAccountInfo(playerid)
{
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    PlayerTextDrawSetString(playerid, BankTD[playerid][8], playerName);
    
    new balanceStr[32];
    format(balanceStr, sizeof(balanceStr), "$%s", FormatMoney(PlayerInfo[playerid][pAccount]));
    PlayerTextDrawSetString(playerid, BankTD[playerid][10], balanceStr);
    
    new accountStr[64];
    format(accountStr, sizeof(accountStr), "~w~Ma Tai Khoan: ~y~#%06d", playerid + 100001);
    PlayerTextDrawSetString(playerid, BankTD[playerid][11], accountStr);
    
    return 1;
}

stock bool:IsValidAmount(amount)
{
    return (amount >= MIN_TRANSACTION_AMOUNT && amount <= MAX_TRANSACTION_AMOUNT);
}

stock bool:CanMakeTransaction(playerid)
{
    new currentTime = gettime();
    if(currentTime - PlayerBankData[playerid][pb_LastTransaction] < TRANSACTION_COOLDOWN)
    {
        new remainingTime = TRANSACTION_COOLDOWN - (currentTime - PlayerBankData[playerid][pb_LastTransaction]);
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}Vui long doi %d giay truoc khi thuc hien giao dich tiep theo!", remainingTime);
        SendClientMessage(playerid, -1, string);
        return false;
    }
    
    new currentDay = currentTime / 86400; // seconds in a day
    if(PlayerBankData[playerid][pb_LastTransactionDay] != currentDay)
    {
        PlayerBankData[playerid][pb_DailyTransactions] = 0;
        PlayerBankData[playerid][pb_LastTransactionDay] = currentDay;
    }
    
    if(PlayerBankData[playerid][pb_DailyTransactions] >= MAX_DAILY_TRANSACTIONS)
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Ban da dat gioi han giao dich trong ngay!");
        return false;
    }
    
    return true;
}

stock UpdateTransactionData(playerid)
{
    PlayerBankData[playerid][pb_LastTransaction] = gettime();
    PlayerBankData[playerid][pb_DailyTransactions]++;
}

stock ValidateAmountInput(const input[], &amount)
{
    new cleanInput[32];
    new pos = 0;
    
    for(new i = 0; i < strlen(input) && pos < 31; i++)
    {
        if((input[i] >= '0' && input[i] <= '9') || (i == 0 && input[i] == '-'))
        {
            cleanInput[pos] = input[i];
            pos++;
        }
    }
    cleanInput[pos] = '\0';
    
    if(strlen(cleanInput) == 0)
    {
        amount = 0;
        return false;
    }
    
    amount = strval(cleanInput);
    
    if(amount <= 0)
    {
        return false;
    }
    
    if(amount < 0)
    {
        return false;
    }
    
    return IsValidAmount(amount);
}

stock DepositMoney(playerid, amount)
{
    if(!CanMakeTransaction(playerid)) return 0;
    
    if(!IsValidAmount(amount))
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! (Toi thieu: $%s - Toi da: $%s)", 
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        SendClientMessage(playerid, -1, string);
        return 0;
    }
    
    if(PlayerInfo[playerid][pCash] < amount)
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Ban khong co du tien mat!");
        return 0;
    }
    
    if(PlayerInfo[playerid][pAccount] + amount > MAX_BANK_LIMIT)
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}Vuot qua gioi han tai khoan! Toi da: $%s", 
               FormatMoney(MAX_BANK_LIMIT));
        SendClientMessage(playerid, -1, string);
        return 0;
    }
    
    PlayerInfo[playerid][pCash] -= amount;
    PlayerInfo[playerid][pAccount] += amount;
    
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
    
    UpdateTransactionData(playerid);
    
    UpdateBankAccountInfo(playerid);
    
    new string[128];
    format(string, sizeof(string), "{4CAF50}[BANK] {FFFFFF}Ban da gui $%s vao tai khoan. So du hien tai: $%s", 
           FormatMoney(amount), FormatMoney(PlayerInfo[playerid][pAccount]));
    SendClientMessage(playerid, -1, string);
    
    return 1;
}

stock WithdrawMoney(playerid, amount)
{
    if(!CanMakeTransaction(playerid)) return 0;
    
    if(!IsValidAmount(amount))
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! (Toi thieu: $%s - Toi da: $%s)", 
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        SendClientMessage(playerid, -1, string);
        return 0;
    }
    
    if(PlayerInfo[playerid][pAccount] < amount)
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Tai khoan khong co du tien!");
        return 0;
    }
    
    if(PlayerInfo[playerid][pCash] + amount > MAX_CASH_LIMIT)
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}Vuot qua gioi han tien mat! Toi da: $%s", 
               FormatMoney(MAX_CASH_LIMIT));
        SendClientMessage(playerid, -1, string);
        return 0;
    }
    
    PlayerInfo[playerid][pAccount] -= amount;
    PlayerInfo[playerid][pCash] += amount;
    
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
    
    UpdateTransactionData(playerid);
    
    UpdateBankAccountInfo(playerid);
    
    new string[128];
    format(string, sizeof(string), "{FF5722}[BANK] {FFFFFF}Ban da rut $%s tu tai khoan. So du con lai: $%s", 
           FormatMoney(amount), FormatMoney(PlayerInfo[playerid][pAccount]));
    SendClientMessage(playerid, -1, string);
    
    return 1;
}

stock TransferMoney(playerid, targetPlayerID, amount)
{
    if(!CanMakeTransaction(playerid)) return 0;
    
    if(!IsValidAmount(amount))
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! (Toi thieu: $%s - Toi da: $%s)", 
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        SendClientMessage(playerid, -1, string);
        return 0;
    }
    
    if(!IsPlayerConnected(targetPlayerID))
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Nguoi choi khong online!");
        return 0;
    }
    
    if(playerid == targetPlayerID)
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Ban khong the chuyen tien cho chinh minh!");
        return 0;
    }
    
    new fee = (amount * 2) / 100;
    if(fee < 1) fee = 1; 
    new totalDeduction = amount + fee;
    
    if(PlayerInfo[playerid][pAccount] < totalDeduction)
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Khong du tien de tra phi chuyen khoan!");
        return 0;
    }
    
    if(PlayerInfo[targetPlayerID][pAccount] + amount > MAX_BANK_LIMIT)
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Tai khoan nguoi nhan da dat gioi han!");
        return 0;
    }
    
    PlayerInfo[playerid][pAccount] -= totalDeduction;
    PlayerInfo[targetPlayerID][pAccount] += amount;
    
    UpdateTransactionData(playerid);
    
    UpdateBankAccountInfo(playerid);
    
    if(PlayerBankData[targetPlayerID][pb_InBank])
    {
        UpdateBankAccountInfo(targetPlayerID);
    }
    
    new string[128];
    new senderName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, senderName, sizeof(senderName));
    GetPlayerName(targetPlayerID, targetName, sizeof(targetName));
    
    format(string, sizeof(string), "{2196F3}[BANK] {FFFFFF}Ban da chuyen $%s cho %s. Phi: $%s", 
           FormatMoney(amount), targetName, FormatMoney(fee));
    SendClientMessage(playerid, -1, string);
    
    format(string, sizeof(string), "{4CAF50}[BANK] {FFFFFF}Ban nhan duoc $%s tu %s", 
           FormatMoney(amount), senderName);
    SendClientMessage(targetPlayerID, -1, string);
    
    return 1;
}

/*================== CALLBACKS ==================*/

hook OnPlayerConnect(playerid)
{
    PlayerBankData[playerid][pb_InBank] = false;
    PlayerBankData[playerid][pb_SelectedOption] = 0; // BANK_OPTION_BALANCE
    PlayerBankData[playerid][pb_TransferTarget] = INVALID_PLAYER_ID;
    PlayerBankData[playerid][pb_TransferAmount] = 0;
    PlayerBankData[playerid][pb_LastTransaction] = 0;
    PlayerBankData[playerid][pb_DailyTransactions] = 0;
    PlayerBankData[playerid][pb_LastTransactionDay] = 0;
    
    for(new i = 0; i < 23; i++)
    {
        BankTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    return 1;
}


hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(!PlayerBankData[playerid][pb_InBank]) return 0;
    
    if(playertextid == BankTD[playerid][14])
    {
        new dialogText[512];
        format(dialogText, sizeof(dialogText), 
               "{FFFFFF}Nhap so tien ban muon gui vao tai khoan:\n\n{FFFF00}Gioi han giao dich: $%s - $%s\n{FFFF00}Gioi han tai khoan: $%s\n{FFFF00}Tien mat hien tai: $%s",
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT),
               FormatMoney(MAX_BANK_LIMIT), FormatMoney(PlayerInfo[playerid][pCash]));
        
        ShowPlayerDialog(playerid, BANK_AMOUNT_DIALOG_ID, DIALOG_STYLE_INPUT, 
                        "{4CAF50}BANK - DEPOSIT", dialogText, "Gui tien", "Huy");
        PlayerBankData[playerid][pb_SelectedOption] = 1; 
        return 1;
    }
    
    if(playertextid == BankTD[playerid][16])
    {
        new dialogText[512];
        format(dialogText, sizeof(dialogText), 
               "{FFFFFF}Nhap so tien ban muon rut tu tai khoan:\n\n{FFFF00}Gioi han giao dich: $%s - $%s\n{FFFF00}Gioi han tien mat: $%s\n{FFFF00}So du hien tai: $%s",
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT),
               FormatMoney(MAX_CASH_LIMIT), FormatMoney(PlayerInfo[playerid][pAccount]));
        
        ShowPlayerDialog(playerid, BANK_AMOUNT_DIALOG_ID, DIALOG_STYLE_INPUT,
                        "{FF5722}BANK - WITHDRAW", dialogText, "Rut tien", "Huy");
        PlayerBankData[playerid][pb_SelectedOption] = 2;
        return 1;
    }
    
    if(playertextid == BankTD[playerid][18])
    {
        new dialogText[512];
        format(dialogText, sizeof(dialogText), 
               "{FFFFFF}Nhap ID nguoi choi ban muon chuyen tien:\n\n{FFFF00}Phi chuyen khoan: 2%% (toi thieu $1)\n{FFFF00}Gioi han: $%s - $%s\n{FFFF00}Giao dich con lai hom nay: %d/%d",
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT),
               MAX_DAILY_TRANSACTIONS - PlayerBankData[playerid][pb_DailyTransactions], MAX_DAILY_TRANSACTIONS);
        
        ShowPlayerDialog(playerid, BANK_TRANSFER_DIALOG_ID, DIALOG_STYLE_INPUT,
                        "{2196F3}BANK - TRANSFER", dialogText, "Tiep tuc", "Huy");
        PlayerBankData[playerid][pb_SelectedOption] = 3; 
        return 1;
    }
    
    if(playertextid == BankTD[playerid][20])
    {
        ExitBank(playerid);
        return 1;
    }
    
    return 0;
}

hook OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(Text:INVALID_TEXT_DRAW == clickedid)
    {
        if(PlayerBankData[playerid][pb_InBank])
        {
            ExitBank(playerid);
        }
    }
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case BANK_AMOUNT_DIALOG_ID:
        {
            if(!response) return 1;
            
            new amount;
            if(!ValidateAmountInput(inputtext, amount))
            {
                new string[128];
                format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! Vui long nhap so tu %s den %s", 
                       FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
                SendClientMessage(playerid, -1, string);
                return 1;
            }
            
            switch(PlayerBankData[playerid][pb_SelectedOption])
            {
                case 1: 
                {
                    DepositMoney(playerid, amount);
                }
                case 2: 
                {
                    WithdrawMoney(playerid, amount);
                }
            }
            return 1;
        }
        
        case BANK_TRANSFER_DIALOG_ID:
        {
            if(!response) return 1;
            
            new targetID = strval(inputtext);
            if(!IsPlayerConnected(targetID))
            {
                SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Nguoi choi khong online!");
                return 1;
            }
            
            PlayerBankData[playerid][pb_TransferTarget] = targetID;
            
            ShowPlayerDialog(playerid, BANK_AMOUNT_DIALOG_ID, DIALOG_STYLE_INPUT,
                            "{2196F3}BANK - TRANSFER AMOUNT",
                            "{FFFFFF}Nhap so tien ban muon chuyen:\n\n{FFFF00}Phi chuyen khoan: 2% so tien chuyen",
                            "Chuyen tien", "Huy");
            PlayerBankData[playerid][pb_SelectedOption] = 3; 
            return 1;
        }
        
    }
    
    if(dialogid == BANK_AMOUNT_DIALOG_ID && PlayerBankData[playerid][pb_SelectedOption] == 3) 
    {
        if(!response) return 1;
        
        new amount;
        if(!ValidateAmountInput(inputtext, amount))
        {
            new string[128];
            format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! Vui long nhap so tu %s den %s", 
                   FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
            SendClientMessage(playerid, -1, string);
            return 1;
        }
        
        TransferMoney(playerid, PlayerBankData[playerid][pb_TransferTarget], amount);
        return 1;
    }
    
    return 0;
}

/*================== COMMANDS ==================*/

CMD:bank(playerid, params[])
{
    if(!IsPlayerInRangeOfPoint(playerid, 5.0, BANK_POS_X, BANK_POS_Y, BANK_POS_Z))
    {
        SendClientMessage(playerid, COLOR_RED, "{FF6B6B}[BANK] {FFFFFF}Ban can o gan ngan hang!");
        return 1;
    }
    
    ShowBankInterface(playerid);
    return 1;
}

/*================== INITIALIZATION ==================*/

hook OnGameModeInit()
{
    CreatePickup(1274, 1, BANK_POS_X, BANK_POS_Y, BANK_POS_Z, 0);
    Create3DTextLabel("{4CAF50}$$ NGAN HANG QUOC GIA $$\n{FFFFFF}Dich Vu Ngan Hang An Toan\n{FFFF00}Su dung /bank de truy cap tai khoan", 
                      -1, BANK_POS_X, BANK_POS_Y, BANK_POS_Z + 1.0, 15.0, 0, true);
    
    printf("[BANK SYSTEM] Bank system initialized successfully");
    return 1;
}
