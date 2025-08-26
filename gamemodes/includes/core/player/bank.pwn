#include <YSI\YSI_Coding\y_hooks>

#define MAX_BANK_ACCOUNTS 1000
#define BANK_DIALOG_ID 8000
#define BANK_TRANSFER_DIALOG_ID 8002
#define BANK_AMOUNT_DIALOG_ID 8003
#define BANK_HISTORY_DIALOG_ID 8004
#define BANK_CONFIRM_DIALOG_ID 8005

#define MIN_TRANSACTION_AMOUNT 1
#define MAX_TRANSACTION_AMOUNT 10000000
#define MAX_CASH_LIMIT 50000000
#define MAX_BANK_LIMIT 100000000
#define TRANSACTION_COOLDOWN 2
#define MAX_DAILY_TRANSACTIONS 100

#define BANK_POS_X 1459.0
#define BANK_POS_Y -1010.0
#define BANK_POS_Z 26.8

#define BANK_TD_BASE_X 150.0
#define BANK_TD_BASE_Y 120.0
#define MAX_TRANSACTION_HISTORY 10

#define BANK_FADE_TIME 500
#define BUTTON_HOVER_COLOR 0x66BB6AFF
#define BUTTON_NORMAL_COLOR 0x4CAF50FF

enum E_PLAYER_BANK_DATA
{
    bool:pb_InBank,
    bool:pb_AnimationActive,
    pb_SelectedOption,
    pb_TransferTarget,
    pb_TransferAmount,
    pb_LastTransaction,
    pb_DailyTransactions,
    pb_LastTransactionDay,
    pb_CurrentPage,
    pb_UIMode,
    pb_SecurityLevel,
    pb_LastLoginTime,
    Float:pb_LastBankX,
    Float:pb_LastBankY,
    Float:pb_LastBankZ
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
new PlayerText:BankTD[MAX_PLAYERS][35];
new Timer:BankAnimationTimer[MAX_PLAYERS] = {Timer:-1, ...};
new Timer:BankUpdateTimer[MAX_PLAYERS] = {Timer:-1, ...};

enum E_TRANSACTION_HISTORY
{
    th_Type,
    th_Amount,
    th_Timestamp,
    th_TargetID,
    th_TargetName[MAX_PLAYER_NAME]
}
new PlayerTransactionHistory[MAX_PLAYERS][MAX_TRANSACTION_HISTORY][E_TRANSACTION_HISTORY];
new PlayerTransactionCount[MAX_PLAYERS];

stock CreateBankTextDraws(playerid)
{
    BankTD[playerid][0] = CreatePlayerTextDraw(playerid, 110.0, 90.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][0], 420.0, 340.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][0], 0x000000E6);
    PlayerTextDrawFont(playerid, BankTD[playerid][0], 4);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][0], 2);
    
    BankTD[playerid][1] = CreatePlayerTextDraw(playerid, 115.0, 95.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][1], 410.0, 330.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][1], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][1], 0x1E1E1EFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][1], 4);
    
    // Modern header bar with gradient
    BankTD[playerid][2] = CreatePlayerTextDraw(playerid, 115.0, 95.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][2], 410.0, 45.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][2], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][2], 0x2E7D32FF);
    PlayerTextDrawFont(playerid, BankTD[playerid][2], 4);
    
    // Accent line
    BankTD[playerid][3] = CreatePlayerTextDraw(playerid, 115.0, 135.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][3], 410.0, 3.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][3], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][3], 0x66BB6AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][3], 4);
    
    // Modern bank title with icon
    BankTD[playerid][4] = CreatePlayerTextDraw(playerid, 320.0, 105.0, "~g~$$ ~w~NGAN HANG QUOC GIA ~g~$$");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][4], 0.380, 1.800);
    PlayerTextDrawColor(playerid, BankTD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][4], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][4], 1);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][4], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][4], 2);
    
    // Modern subtitle with better styling
    BankTD[playerid][5] = CreatePlayerTextDraw(playerid, 320.0, 125.0, "~w~• Dich Vu Ngan Hang Hien Dai • Bao Mat Cao •");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][5], 0.220, 1.100);
    PlayerTextDrawColor(playerid, BankTD[playerid][5], 0xE0E0E0FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][5], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][5], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][5], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][5], 1);
    
    // Account info panel with modern design
    BankTD[playerid][6] = CreatePlayerTextDraw(playerid, 125.0, 150.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][6], 390.0, 70.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][6], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][6], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][6], 4);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][6], 1);
    
    // Account info accent line
    BankTD[playerid][7] = CreatePlayerTextDraw(playerid, 125.0, 150.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][7], 390.0, 3.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][7], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][7], 0x66BB6AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][7], 4);
    
    // Account holder label with icon
    BankTD[playerid][8] = CreatePlayerTextDraw(playerid, 135.0, 160.0, "~g~CHU TAI KHOAN:");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][8], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][8], 0x66BB6AFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][8], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][8], 0);
    PlayerTextDrawFont(playerid, BankTD[playerid][8], 2);
    
    // Account holder name display
    BankTD[playerid][9] = CreatePlayerTextDraw(playerid, 135.0, 180.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][9], 0.280, 1.300);
    PlayerTextDrawColor(playerid, BankTD[playerid][9], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][9], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][9], 0);
    PlayerTextDrawFont(playerid, BankTD[playerid][9], 2);
    
    // Balance label with icon
    BankTD[playerid][10] = CreatePlayerTextDraw(playerid, 350.0, 160.0, "~g~SO DU TAI KHOAN:");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][10], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][10], 0x66BB6AFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][10], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][10], 0);
    PlayerTextDrawFont(playerid, BankTD[playerid][10], 2);
    
    // Balance amount display with modern styling
    BankTD[playerid][11] = CreatePlayerTextDraw(playerid, 350.0, 180.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][11], 0.320, 1.500);
    PlayerTextDrawColor(playerid, BankTD[playerid][11], 0x4CAF50FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][11], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][11], 1);
    PlayerTextDrawFont(playerid, BankTD[playerid][11], 2);
    
    // Account number display
    BankTD[playerid][12] = CreatePlayerTextDraw(playerid, 135.0, 200.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][12], 0.200, 1.000);
    PlayerTextDrawColor(playerid, BankTD[playerid][12], 0xBBBBBBFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][12], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][12], 0);
    PlayerTextDrawFont(playerid, BankTD[playerid][12], 1);
    
    // Services panel background
    BankTD[playerid][13] = CreatePlayerTextDraw(playerid, 125.0, 235.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][13], 390.0, 160.0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][13], 1);
    PlayerTextDrawColor(playerid, BankTD[playerid][13], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, BankTD[playerid][13], 4);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][13], 1);
    
    // Services header with modern styling
    BankTD[playerid][14] = CreatePlayerTextDraw(playerid, 320.0, 245.0, "~w~DICH VU NGAN HANG");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][14], 0.280, 1.400);
    PlayerTextDrawColor(playerid, BankTD[playerid][14], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][14], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][14], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][14], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][14], 2);
    
    // Modern button layout with better spacing
    new Float:buttonY = 270.0;
    new Float:buttonSpacing = 30.0;
    new Float:buttonWidth = 120.0;
    new Float:buttonHeight = 25.0;
    
    // Deposit button with modern design
    BankTD[playerid][15] = CreatePlayerTextDraw(playerid, 140.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][15], buttonWidth, buttonHeight);
    PlayerTextDrawColor(playerid, BankTD[playerid][15], 0x4CAF50E6);
    PlayerTextDrawFont(playerid, BankTD[playerid][15], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][15], true);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][15], 1);
    
    BankTD[playerid][16] = CreatePlayerTextDraw(playerid, 200.0, buttonY + 4.0, "~w~GUI TIEN");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][16], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][16], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][16], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][16], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][16], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][16], 2);
    
    // Withdraw button
    buttonY += buttonSpacing;
    BankTD[playerid][17] = CreatePlayerTextDraw(playerid, 140.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][17], buttonWidth, buttonHeight);
    PlayerTextDrawColor(playerid, BankTD[playerid][17], 0xFF5722E6);
    PlayerTextDrawFont(playerid, BankTD[playerid][17], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][17], true);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][17], 1);
    
    BankTD[playerid][18] = CreatePlayerTextDraw(playerid, 200.0, buttonY + 4.0, "~w~RUT TIEN");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][18], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][18], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][18], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][18], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][18], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][18], 2);
    
    // Transfer button
    buttonY += buttonSpacing;
    BankTD[playerid][19] = CreatePlayerTextDraw(playerid, 140.0, buttonY, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][19], buttonWidth, buttonHeight);
    PlayerTextDrawColor(playerid, BankTD[playerid][19], 0x2196F3E6);
    PlayerTextDrawFont(playerid, BankTD[playerid][19], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][19], true);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][19], 1);
    
    BankTD[playerid][20] = CreatePlayerTextDraw(playerid, 200.0, buttonY + 4.0, "~w~CHUYEN TIEN");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][20], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][20], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][20], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][20], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][20], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][20], 2);
    
    // History button (new feature)
    BankTD[playerid][21] = CreatePlayerTextDraw(playerid, 280.0, 270.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][21], buttonWidth, buttonHeight);
    PlayerTextDrawColor(playerid, BankTD[playerid][21], 0x9C27B0E6);
    PlayerTextDrawFont(playerid, BankTD[playerid][21], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][21], true);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][21], 1);
    
    BankTD[playerid][22] = CreatePlayerTextDraw(playerid, 340.0, 274.0, "~w~LICH SU");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][22], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][22], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][22], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][22], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][22], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][22], 2);
    
    // Exit button
    BankTD[playerid][23] = CreatePlayerTextDraw(playerid, 280.0, 330.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, BankTD[playerid][23], buttonWidth, buttonHeight);
    PlayerTextDrawColor(playerid, BankTD[playerid][23], 0x757575E6);
    PlayerTextDrawFont(playerid, BankTD[playerid][23], 4);
    PlayerTextDrawSetSelectable(playerid, BankTD[playerid][23], true);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][23], 1);
    
    BankTD[playerid][24] = CreatePlayerTextDraw(playerid, 340.0, 334.0, "~w~THOAT");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][24], 0.240, 1.200);
    PlayerTextDrawColor(playerid, BankTD[playerid][24], -1);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][24], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][24], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][24], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][24], 2);
    
    // Status indicator
    BankTD[playerid][25] = CreatePlayerTextDraw(playerid, 350.0, 205.0, "");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][25], 0.180, 0.900);
    PlayerTextDrawColor(playerid, BankTD[playerid][25], 0x4CAF50FF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][25], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][25], 0);
    PlayerTextDrawFont(playerid, BankTD[playerid][25], 1);
    
    // Footer with modern styling
    BankTD[playerid][26] = CreatePlayerTextDraw(playerid, 320.0, 405.0, "~g~An Toan - Tin Cay - Hien Dai");
    PlayerTextDrawLetterSize(playerid, BankTD[playerid][26], 0.200, 1.000);
    PlayerTextDrawColor(playerid, BankTD[playerid][26], 0x66BB6AFF);
    PlayerTextDrawSetShadow(playerid, BankTD[playerid][26], 1);
    PlayerTextDrawSetOutline(playerid, BankTD[playerid][26], 0);
    PlayerTextDrawAlignment(playerid, BankTD[playerid][26], 2);
    PlayerTextDrawFont(playerid, BankTD[playerid][26], 1);
    
    // Initialize all textdraws as hidden
    for(new i = 0; i < 35; i++)
    {
        if(BankTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawHide(playerid, BankTD[playerid][i]);
        }
    }
    
    return 1;
}

// ================ MODERN INTERFACE FUNCTIONS ================
stock ShowBankInterface(playerid)
{
    if(PlayerBankData[playerid][pb_InBank]) return ExitBank(playerid);
    
    // Security check - prevent rapid access
    if(gettime() - PlayerBankData[playerid][pb_LastLoginTime] < 2)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Vui long doi 2 giay truoc khi truy cap lai!");
        return 0;
    }
    
    // Store player position for security
    GetPlayerPos(playerid, PlayerBankData[playerid][pb_LastBankX], PlayerBankData[playerid][pb_LastBankY], PlayerBankData[playerid][pb_LastBankZ]);
    
    if(BankTD[playerid][0] == PlayerText:INVALID_TEXT_DRAW)
    {
        CreateBankTextDraws(playerid);
    }
    
    UpdateBankAccountInfo(playerid);
    
    // Show interface with fade-in effect
    PlayerBankData[playerid][pb_AnimationActive] = true;
    
    for(new i = 0; i < 35; i++)
    {
        if(BankTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawShow(playerid, BankTD[playerid][i]);
        }
    }
    
    PlayerBankData[playerid][pb_InBank] = true;
    PlayerBankData[playerid][pb_UIMode] = 0; // Main interface
    PlayerBankData[playerid][pb_LastLoginTime] = gettime();
    
    // Modern textdraw selection with custom color
    SelectTextDraw(playerid, 0x66BB6AFF);
    
    // Start update timer for real-time updates
    if(BankUpdateTimer[playerid] != Timer:-1) {
        stop BankUpdateTimer[playerid];
    }
    BankUpdateTimer[playerid] = repeat UpdateBankDisplay(playerid);
    
    // Play sound effect (Open.mp feature)
    PlayerPlaySound(playerid, 1083, 0.0, 0.0, 0.0);
    
    return 1;
}

stock ExitBank(playerid)
{
    if(!PlayerBankData[playerid][pb_InBank]) return 0;
    
    // Stop timers
    if(BankUpdateTimer[playerid] != Timer:-1) {
        stop BankUpdateTimer[playerid];
        BankUpdateTimer[playerid] = Timer:-1;
    }
    if(BankAnimationTimer[playerid] != Timer:-1) {
        stop BankAnimationTimer[playerid];
        BankAnimationTimer[playerid] = Timer:-1;
    }
    
    CancelSelectTextDraw(playerid);
    
    // Hide interface with fade-out effect
    for(new i = 0; i < 35; i++)
    {
        if(BankTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawHide(playerid, BankTD[playerid][i]);
        }
    }
    
    PlayerBankData[playerid][pb_InBank] = false;
    PlayerBankData[playerid][pb_AnimationActive] = false;
    
    // Play exit sound
    PlayerPlaySound(playerid, 1084, 0.0, 0.0, 0.0);
    
    return 1;
}

// Real-time update function with Open.mp timer
timer UpdateBankDisplay[1000](playerid)
{
    if(!PlayerBankData[playerid][pb_InBank]) {
        stop BankUpdateTimer[playerid];
        BankUpdateTimer[playerid] = Timer:-1;
        return;
    }
    
    UpdateBankAccountInfo(playerid);
}

stock UpdateBankAccountInfo(playerid)
{
    if(!PlayerBankData[playerid][pb_InBank]) return 0;
    
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    PlayerTextDrawSetString(playerid, BankTD[playerid][9], playerName);
    
    new balanceStr[64];
    format(balanceStr, sizeof(balanceStr), "~g~$~w~%s", FormatMoney(PlayerInfo[playerid][pAccount]));
    PlayerTextDrawSetString(playerid, BankTD[playerid][11], balanceStr);
    
    new accountStr[80];
    format(accountStr, sizeof(accountStr), "~w~Ma TK: ~y~#%06d ~w~| Cash: ~g~$%s", playerid + 100001, FormatMoney(PlayerInfo[playerid][pCash]));
    PlayerTextDrawSetString(playerid, BankTD[playerid][12], accountStr);
    
    // Update status indicator
    new statusStr[128];
    new currentTime = gettime();
    new timeStr[32];
    format(timeStr, sizeof(timeStr), "%02d:%02d", (currentTime / 3600) % 24, (currentTime / 60) % 60);
    format(statusStr, sizeof(statusStr), "~g~Online | %s | Giao dich: %d/%d", 
           timeStr, PlayerBankData[playerid][pb_DailyTransactions], MAX_DAILY_TRANSACTIONS);
    PlayerTextDrawSetString(playerid, BankTD[playerid][25], statusStr);
    
    return 1;
}

stock bool:IsValidAmount(amount)
{
    return (amount >= MIN_TRANSACTION_AMOUNT && amount <= MAX_TRANSACTION_AMOUNT);
}

// Enhanced security and validation with Open.mp features
stock bool:CanMakeTransaction(playerid)
{
    // Anti-cheat: Check if player moved too far from bank
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new Float:distance = GetPlayerDistanceFromPoint(playerid, PlayerBankData[playerid][pb_LastBankX], PlayerBankData[playerid][pb_LastBankY], PlayerBankData[playerid][pb_LastBankZ]);
    
    if(distance > 10.0) // Player moved too far
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Giao dich bi huy do ban di chuyen qua xa!");
        ExitBank(playerid);
        return false;
    }
    
    new currentTime = gettime();
    if(currentTime - PlayerBankData[playerid][pb_LastTransaction] < TRANSACTION_COOLDOWN)
    {
        new remainingTime = TRANSACTION_COOLDOWN - (currentTime - PlayerBankData[playerid][pb_LastTransaction]);
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}Vui long doi %d giay truoc khi thuc hien giao dich tiep theo!", remainingTime);
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return false;
    }
    
    new currentDay = currentTime / 86400;
    if(PlayerBankData[playerid][pb_LastTransactionDay] != currentDay)
    {
        PlayerBankData[playerid][pb_DailyTransactions] = 0;
        PlayerBankData[playerid][pb_LastTransactionDay] = currentDay;
    }
    
    if(PlayerBankData[playerid][pb_DailyTransactions] >= MAX_DAILY_TRANSACTIONS)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Ban da dat gioi han giao dich trong ngay!");
        return false;
    }
    
    return true;
}

// Enhanced transaction logging with Open.mp features
stock UpdateTransactionData(playerid)
{
    PlayerBankData[playerid][pb_LastTransaction] = gettime();
    PlayerBankData[playerid][pb_DailyTransactions]++;
}

stock AddTransactionHistory(playerid, type, amount, targetid = INVALID_PLAYER_ID, const targetname[] = "")
{
    // Shift existing history down
    for(new i = MAX_TRANSACTION_HISTORY - 1; i > 0; i--)
    {
        PlayerTransactionHistory[playerid][i] = PlayerTransactionHistory[playerid][i-1];
    }
    
    // Add new transaction at top
    PlayerTransactionHistory[playerid][0][th_Type] = type;
    PlayerTransactionHistory[playerid][0][th_Amount] = amount;
    PlayerTransactionHistory[playerid][0][th_Timestamp] = gettime();
    PlayerTransactionHistory[playerid][0][th_TargetID] = targetid;
    
    if(strlen(targetname) > 0) {
        format(PlayerTransactionHistory[playerid][0][th_TargetName], MAX_PLAYER_NAME, "%s", targetname);
    } else {
        PlayerTransactionHistory[playerid][0][th_TargetName][0] = '\0';
    }
    
    if(PlayerTransactionCount[playerid] < MAX_TRANSACTION_HISTORY) {
        PlayerTransactionCount[playerid]++;
    }
}

stock ShowTransactionHistory(playerid)
{
    if(PlayerTransactionCount[playerid] == 0)
    {
        ShowPlayerDialog(playerid, BANK_HISTORY_DIALOG_ID, DIALOG_STYLE_MSGBOX,
                        "{9C27B0}LICH SU GIAO DICH", 
                        "{FFFFFF}Ban chua co giao dich nao!\n\n{FFFF00}Thuc hien giao dich de xem lich su tai day.",
                        "Dong", "");
        return 1;
    }
    
    new historyStr[2048], tempStr[256];
    format(historyStr, sizeof(historyStr), "{FFFFFF}Lich su {FFFF00}10 {FFFFFF}giao dich gan nhat:\\n\\n");
    
    for(new i = 0; i < PlayerTransactionCount[playerid] && i < MAX_TRANSACTION_HISTORY; i++)
    {
        new timeStr[32];
        new timestamp = PlayerTransactionHistory[playerid][i][th_Timestamp];
        format(timeStr, sizeof(timeStr), "%02d:%02d", (timestamp / 3600) % 24, (timestamp / 60) % 60);
        
        switch(PlayerTransactionHistory[playerid][i][th_Type])
        {
            case 0: // Deposit
            {
                format(tempStr, sizeof(tempStr), "{4CAF50}[%s] GUI TIEN: +$%s\\n",
                       timeStr, FormatMoney(PlayerTransactionHistory[playerid][i][th_Amount]));
            }
            case 1: // Withdraw
            {
                format(tempStr, sizeof(tempStr), "{FF5722}[%s] RUT TIEN: -$%s\\n",
                       timeStr, FormatMoney(PlayerTransactionHistory[playerid][i][th_Amount]));
            }
            case 2: // Transfer out
            {
                format(tempStr, sizeof(tempStr), "{2196F3}[%s] CHUYEN DEN %s: -$%s\\n",
                       timeStr, PlayerTransactionHistory[playerid][i][th_TargetName], FormatMoney(PlayerTransactionHistory[playerid][i][th_Amount]));
            }
            case 3: // Transfer in
            {
                format(tempStr, sizeof(tempStr), "{4CAF50}[%s] NHAN TU %s: +$%s\\n",
                       timeStr, PlayerTransactionHistory[playerid][i][th_TargetName], FormatMoney(PlayerTransactionHistory[playerid][i][th_Amount]));
            }
        }
        strcat(historyStr, tempStr);
    }
    
    ShowPlayerDialog(playerid, BANK_HISTORY_DIALOG_ID, DIALOG_STYLE_MSGBOX,
                    "{9C27B0}LICH SU GIAO DICH", historyStr, "Dong", "");
    return 1;
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

// Enhanced deposit function with Open.mp features
stock DepositMoney(playerid, amount)
{
    if(!CanMakeTransaction(playerid)) return 0;
    
    if(!IsValidAmount(amount))
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! (Toi thieu: $%s - Toi da: $%s)", 
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 0;
    }
    
    if(PlayerInfo[playerid][pCash] < amount)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Ban khong co du tien mat!");
        return 0;
    }
    
    if(PlayerInfo[playerid][pAccount] + amount > MAX_BANK_LIMIT)
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}Vuot qua gioi han tai khoan! Toi da: $%s", 
               FormatMoney(MAX_BANK_LIMIT));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 0;
    }
    
    PlayerInfo[playerid][pCash] -= amount;
    PlayerInfo[playerid][pAccount] += amount;
    
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
    
    UpdateTransactionData(playerid);
    AddTransactionHistory(playerid, 0, amount); // Type 0 = Deposit
    
    // Log money transfer to history system
    LogMoneyTransfer(playerid, INVALID_PLAYER_ID, amount, MONEY_TYPE_BANK_DEPOSIT, "Gui tien vao ngan hang");
    
    // Play success sound
    PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
    
    new string[128];
    format(string, sizeof(string), "{4CAF50}[BANK] {FFFFFF}Ban da gui $%s vao tai khoan. So du hien tai: $%s", 
           FormatMoney(amount), FormatMoney(PlayerInfo[playerid][pAccount]));
    SendClientMessage(playerid, 0x4CAF50FF, string);
    
    return 1;
}

// Enhanced withdraw function with Open.mp features
stock WithdrawMoney(playerid, amount)
{
    if(!CanMakeTransaction(playerid)) return 0;
    
    if(!IsValidAmount(amount))
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! (Toi thieu: $%s - Toi da: $%s)", 
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 0;
    }
    
    if(PlayerInfo[playerid][pAccount] < amount)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Tai khoan khong co du tien!");
        return 0;
    }
    
    new maxWithdraw = MAX_CASH_LIMIT - PlayerInfo[playerid][pCash];
    if(amount > maxWithdraw)
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}Chi co the rut toi da $%s! (Tien mat hien tai: $%s)", 
               FormatMoney(maxWithdraw), FormatMoney(PlayerInfo[playerid][pCash]));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 0;
    }
    
    PlayerInfo[playerid][pAccount] -= amount;
    PlayerInfo[playerid][pCash] += amount;
    
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
    
    UpdateTransactionData(playerid);
    AddTransactionHistory(playerid, 1, amount); // Type 1 = Withdraw
    
    // Log money transfer to history system
    LogMoneyTransfer(playerid, INVALID_PLAYER_ID, amount, MONEY_TYPE_BANK_WITHDRAW, "Rut tien tu ngan hang");
    
    // Play success sound
    PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
    
    new string[128];
    format(string, sizeof(string), "{FF5722}[BANK] {FFFFFF}Ban da rut $%s tu tai khoan. So du con lai: $%s", 
           FormatMoney(amount), FormatMoney(PlayerInfo[playerid][pAccount]));
    SendClientMessage(playerid, 0xFF5722FF, string);
    
    return 1;
}

// Enhanced transfer function with Open.mp features
stock TransferMoney(playerid, targetPlayerID, amount)
{
    if(!CanMakeTransaction(playerid)) return 0;
    
    if(!IsValidAmount(amount))
    {
        new string[128];
        format(string, sizeof(string), "{FF6B6B}[BANK] {FFFFFF}So tien khong hop le! (Toi thieu: $%s - Toi da: $%s)", 
               FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        SendClientMessage(playerid, 0xFF6B6BFF, string);
        return 0;
    }
    
    // Kiểm tra cơ bản (đã được kiểm tra ở dialog nhưng giữ lại để đảm bảo)
    if(!IsPlayerConnected(targetPlayerID))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Nguoi choi khong online!");
        return 0;
    }
    
    // Dynamic fee calculation based on amount
    new fee = (amount * 2) / 100;
    if(fee < 1) fee = 1;
    if(fee > 50000) fee = 50000; // Maximum fee cap
    new totalDeduction = amount + fee;
    
    if(PlayerInfo[playerid][pAccount] < totalDeduction)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Khong du tien de tra phi chuyen khoan!");
        return 0;
    }
    
    if(PlayerInfo[targetPlayerID][pAccount] + amount > MAX_BANK_LIMIT)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Tai khoan nguoi nhan da dat gioi han!");
        return 0;
    }
    
    PlayerInfo[playerid][pAccount] -= totalDeduction;
    PlayerInfo[targetPlayerID][pAccount] += amount;
    
    UpdateTransactionData(playerid);
    
    new senderName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, senderName, sizeof(senderName));
    GetPlayerName(targetPlayerID, targetName, sizeof(targetName));
    
    // Add to both players' transaction history
    AddTransactionHistory(playerid, 2, amount, targetPlayerID, targetName); // Type 2 = Transfer out
    AddTransactionHistory(targetPlayerID, 3, amount, playerid, senderName); // Type 3 = Transfer in
    
    // Log money transfer to history system for both players
    new reason[128];
    format(reason, sizeof(reason), "Chuyen tien ngan hang cho %s", targetName);
    LogMoneyTransfer(playerid, targetPlayerID, amount, MONEY_TYPE_BANK_DEPOSIT, reason);
    
    format(reason, sizeof(reason), "Nhan tien ngan hang tu %s", senderName);
    LogMoneyTransfer(targetPlayerID, playerid, amount, MONEY_TYPE_BANK_WITHDRAW, reason);
    
    // Update UI if target is in bank
    if(PlayerBankData[targetPlayerID][pb_InBank])
    {
        UpdateBankAccountInfo(targetPlayerID);
        // Notify with sound
        PlayerPlaySound(targetPlayerID, 1054, 0.0, 0.0, 0.0);
    }
    
    // Play success sounds
    PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
    
    new string[128];
    format(string, sizeof(string), "{2196F3}[BANK] {FFFFFF}Ban da chuyen $%s cho %s. Phi: $%s", 
           FormatMoney(amount), targetName, FormatMoney(fee));
    SendClientMessage(playerid, 0x2196F3FF, string);
    
    format(string, sizeof(string), "{4CAF50}[BANK] {FFFFFF}Ban nhan duoc $%s tu %s", 
           FormatMoney(amount), senderName);
    SendClientMessage(targetPlayerID, 0x4CAF50FF, string);
    
    return 1;
}

/*================== CALLBACKS ==================*/

// ================ ENHANCED CALLBACKS WITH OPEN.MP ================
hook OnPlayerConnect(playerid)
{
    // Initialize player bank data
    PlayerBankData[playerid][pb_InBank] = false;
    PlayerBankData[playerid][pb_AnimationActive] = false;
    PlayerBankData[playerid][pb_SelectedOption] = 0;
    PlayerBankData[playerid][pb_TransferTarget] = INVALID_PLAYER_ID;
    PlayerBankData[playerid][pb_TransferAmount] = 0;
    PlayerBankData[playerid][pb_LastTransaction] = 0;
    PlayerBankData[playerid][pb_DailyTransactions] = 0;
    PlayerBankData[playerid][pb_LastTransactionDay] = 0;
    PlayerBankData[playerid][pb_CurrentPage] = 0;
    PlayerBankData[playerid][pb_UIMode] = 0;
    PlayerBankData[playerid][pb_SecurityLevel] = 1;
    PlayerBankData[playerid][pb_LastLoginTime] = 0;
    PlayerBankData[playerid][pb_LastBankX] = 0.0;
    PlayerBankData[playerid][pb_LastBankY] = 0.0;
    PlayerBankData[playerid][pb_LastBankZ] = 0.0;
    
    // Initialize timers
    BankAnimationTimer[playerid] = Timer:-1;
    BankUpdateTimer[playerid] = Timer:-1;
    
    // Initialize transaction history
    PlayerTransactionCount[playerid] = 0;
    for(new i = 0; i < MAX_TRANSACTION_HISTORY; i++)
    {
        PlayerTransactionHistory[playerid][i][th_Type] = 0;
        PlayerTransactionHistory[playerid][i][th_Amount] = 0;
        PlayerTransactionHistory[playerid][i][th_Timestamp] = 0;
        PlayerTransactionHistory[playerid][i][th_TargetID] = INVALID_PLAYER_ID;
        PlayerTransactionHistory[playerid][i][th_TargetName][0] = '\0';
    }
    
    // Initialize textdraws
    for(new i = 0; i < 35; i++)
    {
        BankTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    return 1;
}


hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(!PlayerBankData[playerid][pb_InBank]) return 0;
    
    // Play click sound
    PlayerPlaySound(playerid, 1083, 0.0, 0.0, 0.0);
    
    // Deposit button
    if(playertextid == BankTD[playerid][15])
    {
        new dialogText[512];
        format(dialogText, sizeof(dialogText), "{FFFFFF}Nhap so tien gui vao ngan hang:");
        new tempStr[128];
        format(tempStr, sizeof(tempStr), "\n{4CAF50}Tien mat: {FFFF00}$%s", FormatMoney(PlayerInfo[playerid][pCash]));
        strcat(dialogText, tempStr, sizeof(dialogText));
        format(tempStr, sizeof(tempStr), "\n{4CAF50}Gioi han: {FFFF00}$%s - $%s", FormatMoney(MIN_TRANSACTION_AMOUNT), FormatMoney(MAX_TRANSACTION_AMOUNT));
        strcat(dialogText, tempStr, sizeof(dialogText));
        
        ShowPlayerDialog(playerid, BANK_AMOUNT_DIALOG_ID, DIALOG_STYLE_INPUT, 
                        "{4CAF50}NGAN HANG - GUI TIEN", dialogText, "Gui tien", "Huy");
        PlayerBankData[playerid][pb_SelectedOption] = 1;
        return 1;
    }
    
    // Withdraw button
    if(playertextid == BankTD[playerid][17])
    {
        new dialogText[512];
        new maxWithdraw = MAX_CASH_LIMIT - PlayerInfo[playerid][pCash];
        if(maxWithdraw > PlayerInfo[playerid][pAccount]) maxWithdraw = PlayerInfo[playerid][pAccount];
        
        format(dialogText, sizeof(dialogText), "{FFFFFF}Nhap so tien rut tu ngan hang:");
        new tempStr[128];
        format(tempStr, sizeof(tempStr), "\n{FF5722}So du: {FFFF00}$%s", FormatMoney(PlayerInfo[playerid][pAccount]));
        strcat(dialogText, tempStr, sizeof(dialogText));
        format(tempStr, sizeof(tempStr), "\n{FF5722}Co the rut toi da: {FFFF00}$%s", FormatMoney(maxWithdraw));
        strcat(dialogText, tempStr, sizeof(dialogText));
        
        ShowPlayerDialog(playerid, BANK_AMOUNT_DIALOG_ID, DIALOG_STYLE_INPUT,
                        "{FF5722}NGAN HANG - RUT TIEN", dialogText, "Rut tien", "Huy");
        PlayerBankData[playerid][pb_SelectedOption] = 2;
        return 1;
    }
    
    // Transfer button
    if(playertextid == BankTD[playerid][19])
    {
        new dialogText[512];
        format(dialogText, sizeof(dialogText), "{FFFFFF}Nhap ID nguoi nhan:");
        new tempStr[128];
        format(tempStr, sizeof(tempStr), "\n{2196F3}Phi: {FFFF00}2%%%% {2196F3}| Con lai: {FFFF00}%d/%d giao dich", MAX_DAILY_TRANSACTIONS - PlayerBankData[playerid][pb_DailyTransactions], MAX_DAILY_TRANSACTIONS);
        strcat(dialogText, tempStr, sizeof(dialogText));
        strcat(dialogText, "\n{FF6B6B}Luu y: Kiem tra ky ID!", sizeof(dialogText));
        
        ShowPlayerDialog(playerid, BANK_TRANSFER_DIALOG_ID, DIALOG_STYLE_INPUT,
                        "{2196F3}NGAN HANG - CHUYEN TIEN", dialogText, "Tiep tuc", "Huy");
        PlayerBankData[playerid][pb_SelectedOption] = 3;
        return 1;
    }
    
    // History button
    if(playertextid == BankTD[playerid][21])
    {
        ShowTransactionHistory(playerid);
        return 1;
    }
    
    // Exit button
    if(playertextid == BankTD[playerid][23])
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
            
            // Kiểm tra người chơi có online không
            if(!IsPlayerConnected(targetID))
            {
                SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Nguoi choi khong online!");
                return 1;
            }
            
            // Kiểm tra không cho chuyển tiền cho chính mình
            if(playerid == targetID)
            {
                SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Ban khong the chuyen tien cho chinh minh!");
                return 1;
            }
            
            PlayerBankData[playerid][pb_TransferTarget] = targetID;
            
            new targetName[MAX_PLAYER_NAME];
            GetPlayerName(targetID, targetName, sizeof(targetName));
            
            new dialogText[256];
            format(dialogText, sizeof(dialogText), "{FFFFFF}Nhap so tien chuyen cho {FFFF00}%s:", targetName);
            new tempStr[128];
            format(tempStr, sizeof(tempStr), "\n{4CAF50}So du: {FFFF00}$%s {FF5722}| Phi: 2%%%%", FormatMoney(PlayerInfo[playerid][pAccount]));
            strcat(dialogText, tempStr, sizeof(dialogText));
            
            ShowPlayerDialog(playerid, BANK_AMOUNT_DIALOG_ID, DIALOG_STYLE_INPUT,
                            "{2196F3}NGAN HANG - NHAP SO TIEN", dialogText, "Tiep tuc", "Huy");
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
            SendClientMessage(playerid, 0xFF6B6BFF, string);
            return 1;
        }
        
        PlayerBankData[playerid][pb_TransferAmount] = amount;
        
        new targetName[MAX_PLAYER_NAME];
        GetPlayerName(PlayerBankData[playerid][pb_TransferTarget], targetName, sizeof(targetName));
        
        new fee = (amount * 2) / 100;
        if(fee < 1) fee = 1;
        if(fee > 50000) fee = 50000;
        new totalDeduction = amount + fee;
        
        new senderName[MAX_PLAYER_NAME];
        GetPlayerName(playerid, senderName, sizeof(senderName));
        
        new confirmText[256];
        format(confirmText, sizeof(confirmText), "{FFFFFF}XAC NHAN CHUYEN TIEN:");
        
        new tempStr[128];
        format(tempStr, sizeof(tempStr), "\n\n{FFFF00}Cho: {FFFFFF}%s (ID:%d)", targetName, PlayerBankData[playerid][pb_TransferTarget]);
        strcat(confirmText, tempStr, sizeof(confirmText));
        
        format(tempStr, sizeof(tempStr), "\n{FFFF00}So tien: {4CAF50}$%s {FF5722}+ $%s phi", FormatMoney(amount), FormatMoney(fee));
        strcat(confirmText, tempStr, sizeof(confirmText));
        
        format(tempStr, sizeof(tempStr), "\n{FFFF00}Tong tru: {FF6B6B}$%s", FormatMoney(totalDeduction));
        strcat(confirmText, tempStr, sizeof(confirmText));
        
        format(tempStr, sizeof(tempStr), "\n{FFFF00}So du sau: {FFFFFF}$%s", FormatMoney(PlayerInfo[playerid][pAccount] - totalDeduction));
        strcat(confirmText, tempStr, sizeof(confirmText));
        
        strcat(confirmText, "\n\n{FF6B6B}Xac nhan chuyen tien?", sizeof(confirmText));
        
        ShowPlayerDialog(playerid, BANK_CONFIRM_DIALOG_ID, DIALOG_STYLE_MSGBOX,
                        "{2196F3}XAC NHAN CHUYEN TIEN", confirmText, "Xac nhan", "Huy");
        return 1;
    }
    
    if(dialogid == BANK_CONFIRM_DIALOG_ID)
    {
        if(!response) 
        {
            SendClientMessage(playerid, 0xFFFF00FF, "{FFFF00}[BANK] {FFFFFF}Giao dich chuyen tien da bi huy!");
            return 1;
        }
        
        TransferMoney(playerid, PlayerBankData[playerid][pb_TransferTarget], PlayerBankData[playerid][pb_TransferAmount]);
        return 1;
    }
    
    return 0;
}

/*================== ENHANCED CALLBACKS ==================*/

hook OnPlayerDisconnect(playerid, reason)
{
    // Clean up bank interface
    if(PlayerBankData[playerid][pb_InBank])
    {
        ExitBank(playerid);
    }
    
    // Stop all timers
    if(BankUpdateTimer[playerid] != Timer:-1) {
        stop BankUpdateTimer[playerid];
        BankUpdateTimer[playerid] = Timer:-1;
    }
    if(BankAnimationTimer[playerid] != Timer:-1) {
        stop BankAnimationTimer[playerid];
        BankAnimationTimer[playerid] = Timer:-1;
    }
    
    for(new i = 0; i < 35; i++)
    {
        if(BankTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, BankTD[playerid][i]);
            BankTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    
    return 1;
}

/*================== ENHANCED COMMANDS ==================*/

CMD:bank(playerid, params[])
{
    if(!IsPlayerInRangeOfPoint(playerid, 8.0, BANK_POS_X, BANK_POS_Y, BANK_POS_Z))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Ban can o gan ngan hang de su dung dich vu!");
        new Float:distance = GetPlayerDistanceFromPoint(playerid, BANK_POS_X, BANK_POS_Y, BANK_POS_Z);
        new string[128];
        format(string, sizeof(string), "{FFFF00}[GPS] {FFFFFF}Khoang cach den ngan hang: %.1fm", distance);
        SendClientMessage(playerid, 0xFFFF00FF, string);
        return 1;
    }
    
    if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER || GetPlayerState(playerid) == PLAYER_STATE_PASSENGER)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "{FF6B6B}[BANK] {FFFFFF}Ban can xuong xe de su dung dich vu ngan hang!");
        return 1;
    }
    
    ShowBankInterface(playerid);
    return 1;
}


/*================== ENHANCED INITIALIZATION ==================*/

hook OnGameModeInit()
{
    CreatePickup(1274, 1, BANK_POS_X, BANK_POS_Y, BANK_POS_Z, 0);
    
    Create3DTextLabel(
        "{66BB6A}$$ NGAN HANG QUOC GIA $$\\n{FFFFFF}Dich Vu Ngan Hang Hien Dai & An Toan\\n{4CAF50}Su dung {FFFF00}/bank {4CAF50}de truy cap tai khoan\\n{2196F3}Bao mat cao - Giao dich nhanh chong\\n{9C27B0}Lich su giao dich chi tiet",
        -1, BANK_POS_X, BANK_POS_Y, BANK_POS_Z + 1.5, 20.0, 0, true
    );
    
    CreatePickup(1318, 1, BANK_POS_X + 2.0, BANK_POS_Y, BANK_POS_Z, 0); // Security camera
    CreatePickup(1318, 1, BANK_POS_X - 2.0, BANK_POS_Y, BANK_POS_Z, 0);
    return 1;
}
