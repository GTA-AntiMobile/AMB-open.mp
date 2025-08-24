#include <YSI\YSI_Coding\y_hooks>

// Constants - Optimized with better naming
#define MAX_VEHICLE_VIOLATIONS 10
#define VEHICLE_CHECK_UPDATE_INTERVAL 500
#define POLICE_CHECK_DISTANCE 8.0
#define VEHICLE_CHECK_ANIMATION_TIME 200

// Dialog IDs
#define DIALOG_POLICE_VEHICLE_CHECK 9500
#define DIALOG_POLICE_ISSUE_TICKET 9501
#define DIALOG_POLICE_IMPOUND_CONFIRM 9502

// Modern color scheme
#define COLOR_PRIMARY 0x2196F3FF
#define COLOR_SUCCESS 0x4CAF50FF
#define COLOR_WARNING 0xFF9800FF
#define COLOR_DANGER 0xF44336FF
#define COLOR_DARK 0x1A1A1AFF
#define COLOR_LIGHT 0x2A2A2AFF
#define COLOR_TEXT 0xFFFFFFFF

// Textdraw enum - Optimized structure
enum E_VEHICLE_CHECK_TD {
    // Main interface
    VehicleCheck_BG,
    VehicleCheck_Header,
    VehicleCheck_HeaderText,
    VehicleCheck_StatusBG,
    VehicleCheck_StatusText,
    
    // Preview models
    VehicleCheck_PlayerPreviewBG,
    VehicleCheck_PlayerPreview,
    VehicleCheck_VehiclePreviewBG,
    VehicleCheck_VehiclePreview,
    
    // Information panels
    VehicleCheck_VehicleInfoBG,
    VehicleCheck_VehicleInfoHeader,
    VehicleCheck_OwnerInfoBG,
    VehicleCheck_OwnerInfoHeader,
    VehicleCheck_ViolationsBG,
    VehicleCheck_ViolationsHeader,
    
    // Dynamic text elements
    VehicleCheck_VehicleModel,
    VehicleCheck_VehiclePlate,
    VehicleCheck_VehicleOwner,
    VehicleCheck_VehicleHealth,
    VehicleCheck_VehicleFuel,
    VehicleCheck_VehicleEngine,
    VehicleCheck_OwnerLevel,
    VehicleCheck_OwnerLicenses,
    VehicleCheck_OwnerWanted,
    VehicleCheck_OwnerCrimes,
    VehicleCheck_ViolationsList,
    
    // Action buttons
    VehicleCheck_IssueTicketBG,
    VehicleCheck_IssueTicketBtn,
    VehicleCheck_ImpoundBG,
    VehicleCheck_ImpoundBtn,
    VehicleCheck_CloseBG,
    VehicleCheck_CloseBtn
}

// Violation types enum
enum E_VIOLATION_TYPE {
    VIOLATION_NONE,
    VIOLATION_NO_LICENSE,
    VIOLATION_EXPIRED_REGISTRATION,
    VIOLATION_STOLEN_VEHICLE,
    VIOLATION_ILLEGAL_MODIFICATIONS,
    VIOLATION_DAMAGED_VEHICLE,
    VIOLATION_NO_INSURANCE,
    VIOLATION_WANTED_OWNER,
    VIOLATION_ILLEGAL_WEAPONS,
    VIOLATION_DRUGS_FOUND
}

// Vehicle check data structure - Optimized
enum E_VEHICLE_CHECK_DATA {
    bool:vcd_Active,
    vcd_VehicleID,
    vcd_TargetPlayer,
    vcd_ViolationCount,
    vcd_Violations[MAX_VEHICLE_VIOLATIONS],
    vcd_AnimationStep
}

// Global variables - Using modern Open.mp style
static PlayerText:g_VehicleCheckTD[MAX_PLAYERS][E_VEHICLE_CHECK_TD];
static g_VehicleCheckData[MAX_PLAYERS][E_VEHICLE_CHECK_DATA];

// Violation data - Compressed arrays
static const g_ViolationNames[E_VIOLATION_TYPE][32] = {
    "Khong co",
    "Khong co bang lai", 
    "Dang ky het han",
    "Xe bi danh cap",
    "Do choi bat hop phap",
    "Xe hu hong nang", 
    "Khong co bao hiem",
    "Chu xe bi truy na",
    "Vu khi bat hop phap",
    "Tim thay ma tuy"
};

static const g_ViolationFines[E_VIOLATION_TYPE] = {
    0, 50000, 75000, 500000, 100000, 25000, 30000, 0, 200000, 150000
};

/*================== HELPER FUNCTIONS ==================*/

static stock UpdateVehiclePreview(playerid, vehicleid, modelid) {
    PlayerTextDrawSetPreviewModel(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], modelid);
    
    new color1, color2;
    GetVehicleColor(vehicleid, color1, color2);
    PlayerTextDrawSetPreviewVehCol(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], color1, color2);
    
    PlayerTextDrawHide(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview]);
    PlayerTextDrawShow(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview]);
    return 1;
}

static stock UpdateVehicleCheckPlayerPreview(playerid, ownerid) {
    new playerSkin = PlayerInfo[ownerid][pModel];
    PlayerTextDrawSetPreviewModel(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], playerSkin);
    
    PlayerTextDrawHide(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview]);
    PlayerTextDrawShow(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview]);
    return 1;
}

static stock UpdateStatusText(playerid, const text[]) {
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusText], text);
    return 1;
}

static stock AddViolation(playerid, E_VIOLATION_TYPE:violationType) {
    if(g_VehicleCheckData[playerid][vcd_ViolationCount] >= MAX_VEHICLE_VIOLATIONS) return 0;
    
    g_VehicleCheckData[playerid][vcd_Violations][g_VehicleCheckData[playerid][vcd_ViolationCount]] = _:violationType;
    g_VehicleCheckData[playerid][vcd_ViolationCount]++;
    return 1;
}

static stock ProcessTicketIssue(playerid) {
    new totalFine = 0;
    
    for(new i = 0; i < g_VehicleCheckData[playerid][vcd_ViolationCount]; i++) {
        totalFine += g_ViolationFines[E_VIOLATION_TYPE:g_VehicleCheckData[playerid][vcd_Violations][i]];
    }
    
    new targetid = g_VehicleCheckData[playerid][vcd_TargetPlayer];
    
    if(IsPlayerConnected(targetid)) {
        new string[256];
        format(string, sizeof(string), 
            "Canh sat %s da bat phat ban $%s vi vi pham giao thong!", 
            GetPlayerNameEx(playerid), number_format(totalFine));
        SendClientMessage(targetid, 0xFF6B6BFF, string);
        GivePlayerMoney(targetid, -totalFine);
    }
    
    // Log the ticket
    new logString[256];
    format(logString, sizeof(logString), 
        "[VEHICLE CHECK] %s issued ticket $%s to %s (Vehicle: %d)", 
        GetPlayerNameEx(playerid), number_format(totalFine), 
        GetPlayerNameEx(targetid), g_VehicleCheckData[playerid][vcd_VehicleID]);
    Log("logs/police.log", logString);
    
    UpdateStatusText(playerid, "~g~Da bat phat thanh cong!");
    return 1;
}

static stock ProcessVehicleImpound(playerid) {
    new ownerid, slot;
    if(GetVehicleOwnerAndSlot(g_VehicleCheckData[playerid][vcd_VehicleID], ownerid, slot)) {
        PlayerVehicleInfo[ownerid][slot][pvImpounded] = 1;
        SetVehicleToRespawn(g_VehicleCheckData[playerid][vcd_VehicleID]);
        
        if(IsPlayerConnected(ownerid)) {
            SendClientMessage(ownerid, 0xFF6B6BFF, 
                "Xe cua ban da bi tam giu boi canh sat vi vi pham giao thong!");
        }
        
        // Log the impound
        new logString[256];
        format(logString, sizeof(logString), 
            "[VEHICLE CHECK] %s impounded vehicle %d owned by %s", 
            GetPlayerNameEx(playerid), g_VehicleCheckData[playerid][vcd_VehicleID], 
            GetPlayerNameEx(ownerid));
        Log("logs/police.log", logString);
        
        UpdateStatusText(playerid, "~y~Xe da duoc tam giu!");
    }
    return 1;
}


/*================== VEHICLE CHECK FUNCTIONS ==================*/

// Modern textdraw creation with optimized functions
static stock CreateVehicleCheckBackground(playerid) {
    g_VehicleCheckTD[playerid][VehicleCheck_BG] = CreatePlayerTextDraw(playerid, 50.0, 75.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_BG], 540.0, 380.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_BG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_BG], COLOR_DARK);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_BG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_BG], COLOR_DARK);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_BG], 4);
    return 1;
}

static stock CreateVehicleCheckHeader(playerid) {
    g_VehicleCheckTD[playerid][VehicleCheck_Header] = CreatePlayerTextDraw(playerid, 60.0, 85.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_Header], 520.0, 40.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_Header], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_Header], COLOR_PRIMARY);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_Header], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_Header], COLOR_PRIMARY);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_Header], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_HeaderText] = CreatePlayerTextDraw(playerid, 320.0, 98.0, "~w~HE THONG KIEM TRA PHUONG TIEN");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_HeaderText], 2);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_HeaderText], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_HeaderText], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_HeaderText], 0.28, 1.3);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_HeaderText], 1);
    PlayerTextDrawSetShadow(playerid, g_VehicleCheckTD[playerid][VehicleCheck_HeaderText], 1);
    return 1;
}

static stock CreateVehicleCheckPreviews(playerid) {
    // Player preview
    g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG] = CreatePlayerTextDraw(playerid, 485.0, 135.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG], 90.0, 110.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG], COLOR_LIGHT);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG], COLOR_LIGHT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreviewBG], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview] = CreatePlayerTextDraw(playerid, 490.0, 140.0, "");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], 80.0, 100.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], 5);
    PlayerTextDrawSetPreviewModel(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], 0);
    PlayerTextDrawSetPreviewRot(playerid, g_VehicleCheckTD[playerid][VehicleCheck_PlayerPreview], -15.0, 0.0, -25.0, 1.0);
    
    // Vehicle preview
    g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG] = CreatePlayerTextDraw(playerid, 485.0, 255.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG], 90.0, 90.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG], COLOR_LIGHT);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG], COLOR_LIGHT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreviewBG], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview] = CreatePlayerTextDraw(playerid, 490.0, 260.0, "");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], 80.0, 80.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], 5);
    PlayerTextDrawSetPreviewModel(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], 411);
    PlayerTextDrawSetPreviewRot(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], -15.0, 0.0, -25.0, 1.0);
    PlayerTextDrawSetPreviewVehCol(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePreview], 1, 1);
    return 1;
}

static stock CreateVehicleCheckInfoPanels(playerid) {
    // Vehicle info panel
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG] = CreatePlayerTextDraw(playerid, 70.0, 135.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG], 200.0, 125.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG], 0x222222DD);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG], 0x222222DD);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoBG], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoHeader] = CreatePlayerTextDraw(playerid, 75.0, 140.0, "~y~THONG TIN XE");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoHeader], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoHeader], 0xFFDC00FF);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoHeader], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoHeader], 0.24, 1.1);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleInfoHeader], 1);
    
    // Owner info panel
    g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG] = CreatePlayerTextDraw(playerid, 280.0, 135.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG], 200.0, 125.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG], 0x222222DD);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG], 0x222222DD);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoBG], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoHeader] = CreatePlayerTextDraw(playerid, 285.0, 140.0, "~y~THONG TIN CHU XE");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoHeader], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoHeader], 0xFFDC00FF);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoHeader], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoHeader], 0.24, 1.1);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerInfoHeader], 1);
    return 1;
}

static stock CreateVehicleCheckTextElements(playerid) {
    // Vehicle info text elements
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleModel] = CreatePlayerTextDraw(playerid, 75.0, 160.0, "~w~Model: ~g~Unknown");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleModel], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleModel], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleModel], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleModel], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehiclePlate] = CreatePlayerTextDraw(playerid, 75.0, 175.0, "~w~Bien so: ~g~Unknown");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePlate], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePlate], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePlate], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePlate], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleOwner] = CreatePlayerTextDraw(playerid, 75.0, 190.0, "~w~Chu xe: ~g~Unknown");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleOwner], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleOwner], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleOwner], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleOwner], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleHealth] = CreatePlayerTextDraw(playerid, 75.0, 205.0, "~w~Tinh trang: ~g~100%");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleHealth], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleHealth], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleHealth], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleHealth], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleFuel] = CreatePlayerTextDraw(playerid, 75.0, 220.0, "~w~Nhien lieu: ~g~100%");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleFuel], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleFuel], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleFuel], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleFuel], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_VehicleEngine] = CreatePlayerTextDraw(playerid, 75.0, 235.0, "~w~Dong co: ~g~Level 0");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleEngine], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleEngine], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleEngine], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleEngine], 0.20, 0.9);
    
    // Owner info text elements
    g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel] = CreatePlayerTextDraw(playerid, 285.0, 160.0, "~w~Level: ~g~1");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses] = CreatePlayerTextDraw(playerid, 285.0, 175.0, "~w~Bang lai: ~g~Co");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted] = CreatePlayerTextDraw(playerid, 285.0, 190.0, "~w~Truy na: ~g~Khong");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted], 0.20, 0.9);
    
    g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes] = CreatePlayerTextDraw(playerid, 285.0, 205.0, "~w~Toi pham: ~g~0");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes], 0.20, 0.9);
    return 1;
}

static stock CreateVehicleCheckViolationsPanel(playerid) {
    g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG] = CreatePlayerTextDraw(playerid, 70.0, 270.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG], 410.0, 85.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG], 0x333333DD);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG], 0x333333DD);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsBG], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_ViolationsHeader] = CreatePlayerTextDraw(playerid, 75.0, 275.0, "~r~VI PHAM PHAT HIEN");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsHeader], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsHeader], 0xFF6B6BFF);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsHeader], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsHeader], 0.24, 1.1);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsHeader], 1);
    
    g_VehicleCheckTD[playerid][VehicleCheck_ViolationsList] = CreatePlayerTextDraw(playerid, 75.0, 295.0, "~w~Khong co vi pham nao duoc phat hien.");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsList], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsList], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsList], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsList], 0.20, 0.9);
    return 1;
}

static stock CreateVehicleCheckButtons(playerid) {
    // Issue ticket button
    g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG] = CreatePlayerTextDraw(playerid, 80.0, 365.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], 120.0, 28.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], COLOR_SUCCESS);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], COLOR_SUCCESS);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], 4);
    PlayerTextDrawSetSelectable(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG], 1);
    
    g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn] = CreatePlayerTextDraw(playerid, 140.0, 372.0, "~w~BAT PHAT");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn], 2);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn], 0.24, 1.1);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn], 1);
    PlayerTextDrawSetSelectable(playerid, g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn], 1);
    
    // Impound button
    g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG] = CreatePlayerTextDraw(playerid, 210.0, 365.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], 120.0, 28.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], COLOR_WARNING);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], COLOR_WARNING);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], 4);
    PlayerTextDrawSetSelectable(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG], 1);
    
    g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn] = CreatePlayerTextDraw(playerid, 270.0, 372.0, "~w~TAM GIU XE");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn], 2);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn], 0.24, 1.1);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn], 1);
    PlayerTextDrawSetSelectable(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn], 1);
    
    // Close button
    g_VehicleCheckTD[playerid][VehicleCheck_CloseBG] = CreatePlayerTextDraw(playerid, 340.0, 365.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], 120.0, 28.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], COLOR_DANGER);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], COLOR_DANGER);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], 4);
    PlayerTextDrawSetSelectable(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBG], 1);
    
    g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn] = CreatePlayerTextDraw(playerid, 400.0, 372.0, "~w~DONG");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn], 2);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn], 2);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn], 0.24, 1.1);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn], 1);
    PlayerTextDrawSetSelectable(playerid, g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn], 1);
    return 1;
}

static stock CreateVehicleCheckStatusBar(playerid) {
    g_VehicleCheckTD[playerid][VehicleCheck_StatusBG] = CreatePlayerTextDraw(playerid, 60.0, 400.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusBG], 520.0, 28.0);
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusBG], 1);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusBG], COLOR_PRIMARY);
    PlayerTextDrawUseBox(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusBG], 1);
    PlayerTextDrawBoxColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusBG], COLOR_PRIMARY);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusBG], 4);
    
    g_VehicleCheckTD[playerid][VehicleCheck_StatusText] = CreatePlayerTextDraw(playerid, 320.0, 407.0, "~w~San sang kiem tra phuong tien ~y~| ~w~Nhan ~r~ESC ~w~de thoat");
    PlayerTextDrawAlignment(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusText], 2);
    PlayerTextDrawColor(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusText], COLOR_TEXT);
    PlayerTextDrawFont(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusText], 1);
    PlayerTextDrawLetterSize(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusText], 0.21, 0.95);
    PlayerTextDrawSetOutline(playerid, g_VehicleCheckTD[playerid][VehicleCheck_StatusText], 1);
    return 1;
}

stock CreateVehicleCheckTextDraws(playerid)
{
    CreateVehicleCheckBackground(playerid);
    CreateVehicleCheckHeader(playerid);
    CreateVehicleCheckPreviews(playerid);
    CreateVehicleCheckInfoPanels(playerid);
    CreateVehicleCheckTextElements(playerid);
    CreateVehicleCheckViolationsPanel(playerid);
    CreateVehicleCheckButtons(playerid);
    CreateVehicleCheckStatusBar(playerid);
}

// Optimized show/hide functions with animation support
stock ShowVehicleCheckInterface(playerid) {
    if(g_VehicleCheckData[playerid][vcd_Active]) return 0;
    
    g_VehicleCheckData[playerid][vcd_Active] = true;
    g_VehicleCheckData[playerid][vcd_AnimationStep] = 0;
    
    for(new i = 0; i < _:E_VEHICLE_CHECK_TD; i++) {
        PlayerTextDrawShow(playerid, g_VehicleCheckTD[playerid][E_VEHICLE_CHECK_TD:i]);
    }
    
    SelectTextDraw(playerid, COLOR_PRIMARY);
    return 1;
}

stock HideVehicleCheckInterface(playerid) {
    if(!g_VehicleCheckData[playerid][vcd_Active]) return 0;
    
    g_VehicleCheckData[playerid][vcd_Active] = false;
    g_VehicleCheckData[playerid][vcd_VehicleID] = INVALID_VEHICLE_ID;
    g_VehicleCheckData[playerid][vcd_TargetPlayer] = INVALID_PLAYER_ID;
    g_VehicleCheckData[playerid][vcd_ViolationCount] = 0;
    g_VehicleCheckData[playerid][vcd_AnimationStep] = 0;
    
    for(new i = 0; i < _:E_VEHICLE_CHECK_TD; i++) {
        PlayerTextDrawHide(playerid, g_VehicleCheckTD[playerid][E_VEHICLE_CHECK_TD:i]);
    }
    
    CancelSelectTextDraw(playerid);
    return 1;
}

// Optimized vehicle info update function with caching
stock UpdateVehicleCheckInfo(playerid, vehicleid) {
    if(!g_VehicleCheckData[playerid][vcd_Active]) return 0;
    
    new ownerid, slot;
    if(!GetVehicleOwnerAndSlot(vehicleid, ownerid, slot)) {
        UpdateStatusText(playerid, "~r~Khong the lay thong tin xe!");
        return 0;
    }
    
    g_VehicleCheckData[playerid][vcd_VehicleID] = vehicleid;
    g_VehicleCheckData[playerid][vcd_TargetPlayer] = ownerid;
    
    // Update vehicle info efficiently
    UpdateVehicleInfoDisplay(playerid, vehicleid, ownerid, slot);
    UpdateOwnerInfoDisplay(playerid, ownerid);
    CheckVehicleViolationsOptimized(playerid, vehicleid, ownerid, slot);
    
    UpdateStatusText(playerid, "~w~Thong tin da duoc cap nhat");
    return 1;
}

// Optimized display update functions
static stock UpdateVehicleInfoDisplay(playerid, vehicleid, ownerid, slot) {
    new modelid = GetVehicleModel(vehicleid);
    new string[128];
    
    // Vehicle model
    format(string, sizeof(string), "~w~Model: ~g~%s (%d)", GetVehicleName(vehicleid), modelid);
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleModel], string);
    
    // License plate
    format(string, sizeof(string), "~w~Bien so: ~g~%s", PlayerVehicleInfo[ownerid][slot][pvPlate]);
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehiclePlate], string);
    
    // Owner name
    format(string, sizeof(string), "~w~Chu xe: ~g~%s", GetPlayerNameEx(ownerid));
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleOwner], string);
    
    // Vehicle health with color coding
    new Float:health;
    GetVehicleHealth(vehicleid, health);
    new healthPercent = floatround((health / 1000.0) * 100.0);
    new healthColor[8];
    
    switch(healthPercent) {
        case 80..100: healthColor = "~g~";
        case 50..79: healthColor = "~y~";
        default: healthColor = "~r~";
    }
    
    format(string, sizeof(string), "~w~Tinh trang: %s%d%%", healthColor, healthPercent);
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleHealth], string);
    
    // Fuel with color coding
    new fuelPercent = floatround((PlayerVehicleInfo[ownerid][slot][pvFuel] / 100.0) * 100.0);
    new fuelColor[8];
    
    switch(fuelPercent) {
        case 50..100: fuelColor = "~g~";
        case 25..49: fuelColor = "~y~";
        default: fuelColor = "~r~";
    }
    
    format(string, sizeof(string), "~w~Nhien lieu: %s%d%%", fuelColor, fuelPercent);
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleFuel], string);
    
    // Engine upgrade
    new engineLevel = PlayerVehicleInfo[ownerid][slot][pvEngineUpgrade];
    format(string, sizeof(string), "~w~Dong co: ~g~Level %d", engineLevel);
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_VehicleEngine], string);
    
    // Update vehicle preview
    UpdateVehiclePreview(playerid, vehicleid, modelid);
    return 1;
}

static stock UpdateOwnerInfoDisplay(playerid, ownerid) {
    new string[128];
    
    if(IsPlayerConnected(ownerid)) {
        // Player level
        format(string, sizeof(string), "~w~Level: ~g~%d", PlayerInfo[ownerid][pLevel]);
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel], string);
        
        // License status
        format(string, sizeof(string), "~w~Bang lai: %s", 
            PlayerInfo[ownerid][pCarLic] ? "~g~Co" : "~r~Khong");
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses], string);
        
        // Wanted level
        if(PlayerInfo[ownerid][pWantedLevel] > 0) {
            format(string, sizeof(string), "~w~Truy na: ~r~Level %d", PlayerInfo[ownerid][pWantedLevel]);
        } else {
            format(string, sizeof(string), "~w~Truy na: ~g~Khong");
        }
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted], string);
        
        // Crime count
        format(string, sizeof(string), "~w~Toi pham: ~g~%d", PlayerInfo[ownerid][pCrimes]);
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes], string);
        
        // Update player preview
        UpdateVehicleCheckPlayerPreview(playerid, ownerid);
    } else {
        // Offline player
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLevel], "~w~Level: ~r~Offline");
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerLicenses], "~w~Bang lai: ~r~Unknown");
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerWanted], "~w~Truy na: ~r~Unknown");
        PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_OwnerCrimes], "~w~Toi pham: ~r~Unknown");
    }
    return 1;
}

// Optimized violation checking with better performance
stock CheckVehicleViolationsOptimized(playerid, vehicleid, ownerid, slot) {
    g_VehicleCheckData[playerid][vcd_ViolationCount] = 0;
    
    // No license check
    if(IsPlayerConnected(ownerid) && !PlayerInfo[ownerid][pCarLic]) {
        AddViolation(playerid, VIOLATION_NO_LICENSE);
    }
    
    // Damaged vehicle check
    new Float:health;
    GetVehicleHealth(vehicleid, health);
    if(health < 500.0) {
        AddViolation(playerid, VIOLATION_DAMAGED_VEHICLE);
    }
    
    // Wanted owner check
    if(IsPlayerConnected(ownerid) && PlayerInfo[ownerid][pWantedLevel] > 0) {
        AddViolation(playerid, VIOLATION_WANTED_OWNER);
    }
    
    // Illegal modifications check
    if(PlayerVehicleInfo[ownerid][slot][pvEngineUpgrade] >= 4) {
        AddViolation(playerid, VIOLATION_ILLEGAL_MODIFICATIONS);
    }
    
    // Illegal weapons check
    for(new i = 0; i < 3; i++) {
        if(PlayerVehicleInfo[ownerid][slot][pvWeapons][i] > 0) {
            AddViolation(playerid, VIOLATION_ILLEGAL_WEAPONS);
            break;
        }
    }
    
    UpdateViolationsDisplay(playerid);
}

stock UpdateViolationsDisplay(playerid) {
    new violationText[512];
    
    if(g_VehicleCheckData[playerid][vcd_ViolationCount] == 0) {
        violationText = "~w~Khong co vi pham nao duoc phat hien.";
    } else {
        strcat(violationText, "~r~Vi pham phat hien:\n");
        
        new displayCount = (g_VehicleCheckData[playerid][vcd_ViolationCount] > 3) ? 3 : g_VehicleCheckData[playerid][vcd_ViolationCount];
        
        for(new i = 0; i < displayCount; i++) {
            new violationType = g_VehicleCheckData[playerid][vcd_Violations][i];
            format(violationText, sizeof(violationText), "%s~w~- %s ($%s)\n", 
                violationText, g_ViolationNames[E_VIOLATION_TYPE:violationType], 
                number_format(g_ViolationFines[E_VIOLATION_TYPE:violationType]));
        }
        
        if(g_VehicleCheckData[playerid][vcd_ViolationCount] > 3) {
            format(violationText, sizeof(violationText), "%s~y~... va %d vi pham khac", 
                violationText, g_VehicleCheckData[playerid][vcd_ViolationCount] - 3);
        }
    }
    
    PlayerTextDrawSetString(playerid, g_VehicleCheckTD[playerid][VehicleCheck_ViolationsList], violationText);
}

// Optimized vehicle search function
stock GetNearestVehicleToPlayerOptimized(playerid, Float:range = 5.0) {
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    new closestVehicle = INVALID_VEHICLE_ID;
    new Float:closestDistance = range;
    
    // Use more efficient vehicle iteration
    foreach(new vehicleid : Vehicle) {
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(vehicleid, vx, vy, vz);
        
        new Float:distance = GetPlayerDistanceFromPoint(playerid, vx, vy, vz);
        if(distance < closestDistance) {
            closestDistance = distance;
            closestVehicle = vehicleid;
        }
    }
    
    return closestVehicle;
}

/*================== HOOKS ==================*/

hook OnPlayerConnect(playerid) {
    // Initialize player data
    g_VehicleCheckData[playerid][vcd_Active] = false;
    g_VehicleCheckData[playerid][vcd_VehicleID] = INVALID_VEHICLE_ID;
    g_VehicleCheckData[playerid][vcd_TargetPlayer] = INVALID_PLAYER_ID;
    g_VehicleCheckData[playerid][vcd_ViolationCount] = 0;
    g_VehicleCheckData[playerid][vcd_AnimationStep] = 0;
    
    CreateVehicleCheckTextDraws(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason) {
    if(g_VehicleCheckData[playerid][vcd_Active]) {
        HideVehicleCheckInterface(playerid);
    }
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if(g_VehicleCheckData[playerid][vcd_Active] && (newkeys & KEY_NO)) {
        HideVehicleCheckInterface(playerid);
        return 1;
    }
    return 1;
}

hook OnPlayerClickTextDraw(playerid, Text:clickedid) {
    if(g_VehicleCheckData[playerid][vcd_Active]) {
        HideVehicleCheckInterface(playerid);
        return 1;
    }
    return 1;
}

hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid) {
    if(!g_VehicleCheckData[playerid][vcd_Active]) return 1;
    
    // Issue ticket button
    if(playertextid == g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBG] || 
       playertextid == g_VehicleCheckTD[playerid][VehicleCheck_IssueTicketBtn]) {
        
        if(g_VehicleCheckData[playerid][vcd_ViolationCount] == 0) {
            UpdateStatusText(playerid, "~r~Khong co vi pham de bat phat!");
            return 1;
        }
        
        ProcessTicketIssue(playerid);
        return 1;
    }
    
    // Impound button
    if(playertextid == g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBG] || 
       playertextid == g_VehicleCheckTD[playerid][VehicleCheck_ImpoundBtn]) {
        
        if(g_VehicleCheckData[playerid][vcd_ViolationCount] < 2) {
            UpdateStatusText(playerid, "~r~Can it nhat 2 vi pham de tam giu xe!");
            return 1;
        }
        
        ProcessVehicleImpound(playerid);
        return 1;
    }
    
    // Close button
    if(playertextid == g_VehicleCheckTD[playerid][VehicleCheck_CloseBG] || 
       playertextid == g_VehicleCheckTD[playerid][VehicleCheck_CloseBtn]) {
        
        HideVehicleCheckInterface(playerid);
        return 1;
    }
    
    return 1;
}

/*================== COMMANDS ==================*/

CMD:checkxe(playerid, params[]) {
    if(!IsACop(playerid)) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Ban khong phai la canh sat!");
        return 1;
    }
    
    new vehicleid = GetNearestVehicleToPlayerOptimized(playerid, POLICE_CHECK_DISTANCE);
    if(vehicleid == INVALID_VEHICLE_ID) {
        SendClientMessage(playerid, 0xFF6B6BFF, "Khong co xe nao gan ban!");
        return 1;
    }
    
    ShowVehicleCheckInterface(playerid);
    UpdateVehicleCheckInfo(playerid, vehicleid);
    
    new string[128];
    format(string, sizeof(string), "* Canh sat %s bat dau kiem tra phuong tien.", GetPlayerNameEx(playerid));
    ProxDetector(30.0, playerid, string, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE);
    
    return 1;
}

CMD:kiemtraxe(playerid, params[]) {
    return cmd_checkxe(playerid, params);
}

CMD:vehiclecheck(playerid, params[]) {
    return cmd_checkxe(playerid, params);
}