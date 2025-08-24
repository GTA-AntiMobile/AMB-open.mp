#include <YSI\YSI_Coding\y_hooks>

// ===================== DEFINES =====================
#define MAX_INVENTORY_SLOTS     100
#define INVENTORY_ROWS          6
#define INVENTORY_COLS          5
#define MAX_ITEM_STACK          99
#define INVALID_ITEM_ID         -1

// Item Types - Su dung cau truc define da co
#define INV_ITEM_TYPE_WEAPON        1
#define INV_ITEM_TYPE_FOOD          2
#define INV_ITEM_TYPE_DRINK         3
#define INV_ITEM_TYPE_MEDICAL       4
#define INV_ITEM_TYPE_TOOL          5
#define INV_ITEM_TYPE_MATERIAL      6
#define INV_ITEM_TYPE_OTHER         7

// Dialog IDs cho inventory - su dung range trong defines.pwn
#define DIALOG_INVENTORY_MAIN       (5200)
#define DIALOG_INVENTORY_USE        (5201)
#define DIALOG_INVENTORY_DROP       (5202)
#define DIALOG_INVENTORY_GIVE       (5203)
#define DIALOG_GIVEITEM_MAIN        (5204)
#define DIALOG_GIVEITEM_PLAYER      (5205)
#define DIALOG_GIVEITEM_QUANTITY    (5206)
#define DIALOG_DROP_QUANTITY        (5207)

// Drop system defines
#define MAX_DROPPED_ITEMS           500
#define DROPPED_ITEM_OBJECT         19918

// Pagination defines - Tang them slots (6 hang x 5 cot = 30 slots)
#define SLOTS_PER_PAGE 30
#define MAX_PAGES 4

// ===================== ENUMS =====================
enum E_ITEM_DATA {
    item_id,
    item_name[32],
    item_type,
    item_model,
    item_price,
    bool:item_usable,
    item_description[128]
}

enum E_PLAYER_INVENTORY {
    inv_item_id,
    inv_quantity,
    inv_slot
}

enum E_INVENTORY_TEXTDRAWS {
    PlayerText:inv_bg,
    PlayerText:inv_bg_border,
    PlayerText:inv_title_bg,
    PlayerText:inv_title,
    PlayerText:inv_close_btn,
    PlayerText:inv_close_btn_bg,
    PlayerText:inv_item_info,
    PlayerText:inv_item_info_bg,
    PlayerText:inv_item_name,
    PlayerText:inv_item_desc,
    PlayerText:inv_use_btn,
    PlayerText:inv_use_btn_bg,
    PlayerText:inv_drop_btn,
    PlayerText:inv_drop_btn_bg,
    // Phan trang
    PlayerText:inv_page_bg,
    PlayerText:inv_page_text,
    PlayerText:inv_prev_btn,
    PlayerText:inv_prev_btn_bg,
    PlayerText:inv_next_btn,
    PlayerText:inv_next_btn_bg,
    // Player preview va stats
    PlayerText:inv_player_preview,
    PlayerText:inv_stats_bg,
    PlayerText:inv_health_text,
    PlayerText:inv_armor_text,
    PlayerText:inv_money_text
}

enum E_DROPPED_ITEM {
    drop_item_id,
    drop_quantity,
    drop_object_id,
    Text3D:drop_label,
    Float:drop_x,
    Float:drop_y,
    Float:drop_z,
    drop_world,
    drop_interior,
    drop_time
}

// ===================== VARIABLES =====================
// Items dua tren cau truc gamemode (24/7 store items)
new ItemData[][E_ITEM_DATA] = {
    {ITEM_CELLPHONE, "Dien thoai", INV_ITEM_TYPE_OTHER, 330, 500, true, "Dien thoai di dong"},
    {ITEM_PHONEBOOK, "Danh ba", INV_ITEM_TYPE_OTHER, 2824, 50, true, "Cuon danh ba dien thoai"},
    {ITEM_DICE, "Xuc xac", INV_ITEM_TYPE_OTHER, 1271, 25, true, "Xuc xac choi game"},
    {ITEM_CONDOM, "Bao cao su", INV_ITEM_TYPE_OTHER, 1271, 15, true, "Bao cao su an toan"},
    {ITEM_MUSICPLAYER, "May nghe nhac", INV_ITEM_TYPE_OTHER, 2226, 150, true, "May nghe nhac di dong"},
    {ITEM_ROPE, "Day thung", INV_ITEM_TYPE_OTHER, 18762, 30, true, "Cuon day thung"},
    {ITEM_CIGAR, "Cigar", INV_ITEM_TYPE_OTHER, 1485, 35, true, "Dieu cigar cao cap"},
    {ITEM_SPRUNK, "Nuoc ngot", INV_ITEM_TYPE_DRINK, 1484, 25, true, "Chai nuoc ngot Sprunk"},
    {ITEM_VEHICLELOCK, "Binh son xe", INV_ITEM_TYPE_TOOL, 1650, 200, true, "Binh son xe chong trom"},
    {ITEM_SPRAYCAN, "Binh xit", INV_ITEM_TYPE_TOOL, 365, 50, true, "Binh xit son"},
    {ITEM_RADIO, "Radio lien lac", INV_ITEM_TYPE_OTHER, 330, 300, true, "Radio lien lac"},
    {ITEM_CAMERA, "May anh", INV_ITEM_TYPE_OTHER, 367, 250, true, "May anh chup hinh"},
    {ITEM_LOTTERYTICKET, "Ve so xo", INV_ITEM_TYPE_OTHER, 1581, 100, true, "Ve so xo may man"},
    {ITEM_CHECKBOOK, "Ngan phieu", INV_ITEM_TYPE_OTHER, 2894, 500, true, "Cuon ngan phieu"},
    {ITEM_PAPERS, "Giay trang", INV_ITEM_TYPE_OTHER, 1581, 10, true, "To giay trang"}
};

new PlayerInventory[MAX_PLAYERS][MAX_INVENTORY_SLOTS][E_PLAYER_INVENTORY];
new PlayerInventoryTD[MAX_PLAYERS][E_INVENTORY_TEXTDRAWS];

// Array rieng cho slots, slot backgrounds va quantity textdraws
new PlayerText:PlayerInventorySlots[MAX_PLAYERS][SLOTS_PER_PAGE];
new PlayerText:PlayerInventorySlotBG[MAX_PLAYERS][SLOTS_PER_PAGE];
new PlayerText:PlayerInventorySlotQty[MAX_PLAYERS][SLOTS_PER_PAGE];

new bool:InventoryOpen[MAX_PLAYERS];
new SelectedSlot[MAX_PLAYERS] = {-1, ...};
new CurrentPage[MAX_PLAYERS];
new bool:DragMode[MAX_PLAYERS];
new DragSourceSlot[MAX_PLAYERS] = {-1, ...};

// Bien cho dialog giveitem
new GiveItemTargetID[MAX_PLAYERS] = {-1, ...};
new GiveItemID[MAX_PLAYERS] = {-1, ...};

// Bien cho drop system
new DroppedItems[MAX_DROPPED_ITEMS][E_DROPPED_ITEM];
new DropSlot[MAX_PLAYERS] = {-1, ...};

// Inventory system - no separate timer needed

// ===================== FUNCTIONS =====================

// Ham tim item theo ID
stock GetItemDataByID(itemid) {
    for(new i = 0; i < sizeof(ItemData); i++) {
        if(ItemData[i][item_id] == itemid) {
            return i;
        }
    }
    return -1;
}

// Ham tim slot trong - Optimized
stock GetEmptyInventorySlot(playerid) {
    // Validation check
    if(!IsPlayerConnected(playerid)) return -1;
    
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++) {
        if(PlayerInventory[playerid][i][inv_item_id] == -1) {
            return i;
        }
    }
    return -1;
}

// Ham tim item trong inventory - Optimized
stock FindItemInInventory(playerid, itemid) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || itemid < 0) return -1;
    
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++) {
        if(PlayerInventory[playerid][i][inv_item_id] == itemid) {
            return i;
        }
    }
    return -1;
}

// Ham them item vao inventory - Optimized
stock AddItemToInventory(playerid, itemid, quantity = 1) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || itemid < 0 || quantity <= 0) return 0;
    if(quantity > MAX_ITEM_STACK) quantity = MAX_ITEM_STACK;
    
    new slot = FindItemInInventory(playerid, itemid);
    
    if(slot != -1) {
        // Item da ton tai, tang so luong
        new new_quantity = PlayerInventory[playerid][slot][inv_quantity] + quantity;
        if(new_quantity > MAX_ITEM_STACK) {
            PlayerInventory[playerid][slot][inv_quantity] = MAX_ITEM_STACK;
        } else {
            PlayerInventory[playerid][slot][inv_quantity] = new_quantity;
        }
    } else {
        // Tim slot trong de them item moi
        slot = GetEmptyInventorySlot(playerid);
        if(slot != -1) {
            PlayerInventory[playerid][slot][inv_item_id] = itemid;
            PlayerInventory[playerid][slot][inv_quantity] = quantity;
            PlayerInventory[playerid][slot][inv_slot] = slot;
        } else {
            SendClientMessage(playerid, 0xFF0000FF, "Balo cua ban da day!");
            return 0;
        }
    }
    
    // Chi update display neu inventory dang mo
    if(InventoryOpen[playerid]) {
        UpdateInventoryDisplay(playerid);
    }
    return 1;
}

// Ham xoa item khoi inventory - Optimized
stock RemoveItemFromInventory(playerid, itemid, quantity = 1) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || itemid < 0 || quantity <= 0) return 0;
    
    new slot = FindItemInInventory(playerid, itemid);
    if(slot == -1 || slot >= MAX_INVENTORY_SLOTS) return 0;
    
    // Kiem tra so luong hien tai
    if(PlayerInventory[playerid][slot][inv_quantity] < quantity) {
        quantity = PlayerInventory[playerid][slot][inv_quantity];
    }
    
    PlayerInventory[playerid][slot][inv_quantity] -= quantity;
    if(PlayerInventory[playerid][slot][inv_quantity] <= 0) {
        // Reset slot ve trang thai trong
        PlayerInventory[playerid][slot][inv_item_id] = -1;
        PlayerInventory[playerid][slot][inv_quantity] = 0;
        PlayerInventory[playerid][slot][inv_slot] = 0;
        
        // Reset selection neu slot nay dang duoc chon
        if(SelectedSlot[playerid] == slot) {
            SelectedSlot[playerid] = -1;
        }
    }
    
    // Chi update display neu inventory dang mo
    if(InventoryOpen[playerid]) {
        UpdateInventoryDisplay(playerid);
    }
    return 1;
}

// Ham tao textdraw cho inventory - Su dung PlayerTextDraw nhu bank.pwn
stock CreateInventoryTextdraws(playerid) {
    // Background chinh - Outer border (den) - Tang them cho 4 hang
    PlayerInventoryTD[playerid][inv_bg] = CreatePlayerTextDraw(playerid, 100.0, 80.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_bg], 440.0, 450.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_bg], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_bg], 0x000000DD);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_bg], 4);
    
    // Background border - Inner background (xam dam) - Tang them cho 4 hang
    PlayerInventoryTD[playerid][inv_bg_border] = CreatePlayerTextDraw(playerid, 105.0, 85.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_bg_border], 430.0, 440.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_bg_border], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_bg_border], 0x1A1A1AFF);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_bg_border], 4);
    
    // Title background - Thanh tieu de mau xanh - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_title_bg] = CreatePlayerTextDraw(playerid, 105.0, 85.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_title_bg], 430.0, 25.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_title_bg], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_title_bg], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_title_bg], 4);
    
    // Tieu de - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_title] = CreatePlayerTextDraw(playerid, 320.0, 92.0, "~g~BAG ~w~INVENTORY SYSTEM");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_title], 0.350, 1.600);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_title], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_title], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_title], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_title], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_title], 2);
    
    // Nut dong - Background - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_close_btn_bg] = CreatePlayerTextDraw(playerid, 505.0, 88.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg], 25.0, 20.0);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg], 0xF44336DD);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg], 4);
    PlayerTextDrawSetSelectable(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg], true);
    
    // Nut dong - Text - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_close_btn] = CreatePlayerTextDraw(playerid, 517.0, 90.0, "~w~X");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_close_btn], 0.300, 1.200);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_close_btn], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_close_btn], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_close_btn], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_close_btn], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_close_btn], 2);
    
    // Tao cac slot inventory - Chi tao slots hien thi (30 slots - 6 hang x 5 cot) - Cap nhat layout
    new Float:start_x = 115.0, Float:start_y = 125.0;
    new Float:slot_size = 38.0, Float:spacing = 1.5;
    
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        new row = i / INVENTORY_COLS;
        new col = i % INVENTORY_COLS;
        
        new Float:x = start_x + (col * (slot_size + spacing));
        new Float:y = start_y + (row * (slot_size + spacing));
        
        // Background slot - Su dung LD_BUM:blkdot
        PlayerInventorySlotBG[playerid][i] = CreatePlayerTextDraw(playerid, x, y, "LD_BUM:blkdot");
        PlayerTextDrawTextSize(playerid, PlayerInventorySlotBG[playerid][i], slot_size, slot_size);
        PlayerTextDrawAlignment(playerid, PlayerInventorySlotBG[playerid][i], 1);
        PlayerTextDrawColor(playerid, PlayerInventorySlotBG[playerid][i], 0x333333BB);
        PlayerTextDrawFont(playerid, PlayerInventorySlotBG[playerid][i], 4);
        PlayerTextDrawSetSelectable(playerid, PlayerInventorySlotBG[playerid][i], true);
        
        // Item slot - Icon 3D model thay vi text
        PlayerInventorySlots[playerid][i] = CreatePlayerTextDraw(playerid, x + 4.0, y + 4.0, "");
        PlayerTextDrawTextSize(playerid, PlayerInventorySlots[playerid][i], 30.0, 30.0);
        PlayerTextDrawAlignment(playerid, PlayerInventorySlots[playerid][i], 1);
        PlayerTextDrawColor(playerid, PlayerInventorySlots[playerid][i], -1);
        PlayerTextDrawFont(playerid, PlayerInventorySlots[playerid][i], 5);
        PlayerTextDrawBackgroundColor(playerid, PlayerInventorySlots[playerid][i], 0x00000000);
        
        // Quantity text - Goc duoi ben phai cua slot, mau vang de noi bat
        PlayerInventorySlotQty[playerid][i] = CreatePlayerTextDraw(playerid, x + slot_size - 4.0, y + slot_size - 8.0, "");
        PlayerTextDrawLetterSize(playerid, PlayerInventorySlotQty[playerid][i], 0.16, 0.8);
        PlayerTextDrawColor(playerid, PlayerInventorySlotQty[playerid][i], 0xFFFF00FF);
        PlayerTextDrawSetShadow(playerid, PlayerInventorySlotQty[playerid][i], 1);
        PlayerTextDrawSetOutline(playerid, PlayerInventorySlotQty[playerid][i], 1);
        PlayerTextDrawAlignment(playerid, PlayerInventorySlotQty[playerid][i], 3);
        PlayerTextDrawFont(playerid, PlayerInventorySlotQty[playerid][i], 2);
    }
    
    // Panel thong tin item - Background - Cap nhat vi tri va kich thuoc
    PlayerInventoryTD[playerid][inv_item_info_bg] = CreatePlayerTextDraw(playerid, 340.0, 125.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_item_info_bg], 155.0, 120.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_item_info_bg], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_item_info_bg], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_item_info_bg], 4);
    
    // Panel thong tin item - Title bar - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_item_info] = CreatePlayerTextDraw(playerid, 340.0, 125.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_item_info], 155.0, 20.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_item_info], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_item_info], 0x4CAF50FF);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_item_info], 4);
    
    // Ten item - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_item_name] = CreatePlayerTextDraw(playerid, 417.0, 130.0, "~g~ITEM INFO");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_item_name], 0.220, 1.100);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_item_name], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_item_name], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_item_name], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_item_name], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_item_name], 2);
    
    // Mo ta item - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_item_desc] = CreatePlayerTextDraw(playerid, 350.0, 155.0, "Chon mot item~n~de xem thong tin");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_item_desc], 0.180, 0.900);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_item_desc], 0xAAAAAAFF);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_item_desc], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_item_desc], 1);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_item_desc], 1);
    
    // Nut su dung - Background - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_use_btn_bg] = CreatePlayerTextDraw(playerid, 350.0, 205.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg], 65.0, 18.0);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg], 0x4CAF50DD);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg], 4);
    PlayerTextDrawSetSelectable(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg], true);
    
    // Nut su dung - Text - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_use_btn] = CreatePlayerTextDraw(playerid, 382.0, 206.0, "~w~USE");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_use_btn], 0.220, 1.100);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_use_btn], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_use_btn], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_use_btn], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_use_btn], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_use_btn], 2);
    
    // Nut vut bo - Background - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_drop_btn_bg] = CreatePlayerTextDraw(playerid, 425.0, 205.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg], 65.0, 18.0);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg], 0xFF9800DD);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg], 4);
    PlayerTextDrawSetSelectable(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg], true);
    
    // Nut vut bo - Text - Cap nhat vi tri
    PlayerInventoryTD[playerid][inv_drop_btn] = CreatePlayerTextDraw(playerid, 457.0, 206.0, "~w~DROP");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_drop_btn], 0.220, 1.100);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_drop_btn], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_drop_btn], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_drop_btn], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_drop_btn], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_drop_btn], 2);
    
    // Phan trang - Background - Di chuyen xuong duoi hon (sau 6 hang slots)
    PlayerInventoryTD[playerid][inv_page_bg] = CreatePlayerTextDraw(playerid, 115.0, 370.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_page_bg], 220.0, 25.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_page_bg], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_page_bg], 0x2A2A2AFF);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_page_bg], 4);
    
    // Nut Previous - Background (enable neu co trang truoc) - Di chuyen xuong
    PlayerInventoryTD[playerid][inv_prev_btn_bg] = CreatePlayerTextDraw(playerid, 125.0, 373.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], 35.0, 18.0);
    if(CurrentPage[playerid] > 0) {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], 0x4CAF50DD);
    } else {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], 0x757575DD);
    }
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], 4);
    PlayerTextDrawSetSelectable(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], true);
    
    // Nut Previous - Text - Di chuyen xuong
    PlayerInventoryTD[playerid][inv_prev_btn] = CreatePlayerTextDraw(playerid, 142.0, 374.0, "~w~<<");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_prev_btn], 0.220, 1.100);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_prev_btn], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_prev_btn], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_prev_btn], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_prev_btn], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_prev_btn], 2);
    
    // Text phan trang - Di chuyen xuong
    new page_str[32];
    format(page_str, sizeof(page_str), "~w~Trang ~y~%d~w~/~y~%d", CurrentPage[playerid] + 1, MAX_PAGES);
    PlayerInventoryTD[playerid][inv_page_text] = CreatePlayerTextDraw(playerid, 225.0, 376.0, page_str);
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_page_text], 0.200, 1.000);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_page_text], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_page_text], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_page_text], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_page_text], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_page_text], 1);
    
    // Nut Next - Background (enable neu co trang sau) - Di chuyen xuong
    PlayerInventoryTD[playerid][inv_next_btn_bg] = CreatePlayerTextDraw(playerid, 290.0, 373.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], 35.0, 18.0);
    if(CurrentPage[playerid] < MAX_PAGES - 1) {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], 0x4CAF50DD);
    } else {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], 0x757575DD);
    }
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], 4);
    PlayerTextDrawSetSelectable(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], true);
    
    // Nut Next - Text - Di chuyen xuong
    PlayerInventoryTD[playerid][inv_next_btn] = CreatePlayerTextDraw(playerid, 307.0, 374.0, "~w~>>");
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_next_btn], 0.220, 1.100);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_next_btn], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_next_btn], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_next_btn], 1);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_next_btn], 2);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_next_btn], 2);
    
    // Player Preview Model (ben phai, duoi item info) - Cai thien vi tri
    PlayerInventoryTD[playerid][inv_player_preview] = CreatePlayerTextDraw(playerid, 370.0, 250.0, "");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_player_preview], 85.0, 95.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_player_preview], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_player_preview], -1);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_player_preview], 5);
    PlayerTextDrawSetPreviewModel(playerid, PlayerInventoryTD[playerid][inv_player_preview], PlayerInfo[playerid][pModel]);
    PlayerTextDrawSetPreviewRot(playerid, PlayerInventoryTD[playerid][inv_player_preview], -10.0, 0.0, -20.0, 1.0);
    PlayerTextDrawBackgroundColor(playerid, PlayerInventoryTD[playerid][inv_player_preview], 0x1A1A1AFF);
    
    // Stats Background - Ben phai, duoi player preview (gan hon va dep hon)
    PlayerInventoryTD[playerid][inv_stats_bg] = CreatePlayerTextDraw(playerid, 355.0, 350.0, "LD_BUM:blkdot");
    PlayerTextDrawTextSize(playerid, PlayerInventoryTD[playerid][inv_stats_bg], 125.0, 70.0);
    PlayerTextDrawAlignment(playerid, PlayerInventoryTD[playerid][inv_stats_bg], 1);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_stats_bg], 0x1A1A1ACC);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_stats_bg], 4);
    
    // Health Text - Ben phai (gan hon va dep hon)
    new Float:health;
    GetPlayerHealth(playerid, health);
    new health_str[32];
    format(health_str, sizeof(health_str), "~r~Mau: ~w~%.0f", health);
    PlayerInventoryTD[playerid][inv_health_text] = CreatePlayerTextDraw(playerid, 365.0, 358.0, health_str);
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_health_text], 0.170, 0.850);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_health_text], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_health_text], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_health_text], 1);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_health_text], 1);
    
    // Armor Text - Ben phai (gan hon)
    new Float:armor;
    GetPlayerArmour(playerid, armor);
    new armor_str[32];
    format(armor_str, sizeof(armor_str), "~b~Giap: ~w~%.0f", armor);
    PlayerInventoryTD[playerid][inv_armor_text] = CreatePlayerTextDraw(playerid, 365.0, 375.0, armor_str);
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_armor_text], 0.170, 0.850);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_armor_text], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_armor_text], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_armor_text], 1);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_armor_text], 1);
    
    // Money Text - Ben phai (gan hon)
    new money_str[32];
    format(money_str, sizeof(money_str), "~g~Tien: ~y~$%s", FormatInventoryMoney(GetPlayerMoney(playerid)));
    PlayerInventoryTD[playerid][inv_money_text] = CreatePlayerTextDraw(playerid, 365.0, 392.0, money_str);
    PlayerTextDrawLetterSize(playerid, PlayerInventoryTD[playerid][inv_money_text], 0.170, 0.850);
    PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_money_text], -1);
    PlayerTextDrawSetShadow(playerid, PlayerInventoryTD[playerid][inv_money_text], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInventoryTD[playerid][inv_money_text], 1);
    PlayerTextDrawFont(playerid, PlayerInventoryTD[playerid][inv_money_text], 1);
    
    return 1;
}

// Ham huy textdraw - Su dung PlayerTextDrawDestroy
stock DestroyInventoryTextdraws(playerid) {
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_bg_border]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_title_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_title]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_close_btn]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_item_info]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_item_info_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_item_name]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_item_desc]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_use_btn]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_drop_btn]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg]);
    // Phan trang
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_page_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_page_text]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_prev_btn]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_next_btn]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg]);
    // Player preview va stats
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_player_preview]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_stats_bg]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_health_text]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_armor_text]);
    PlayerTextDrawDestroy(playerid, PlayerInventoryTD[playerid][inv_money_text]);
    
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        PlayerTextDrawDestroy(playerid, PlayerInventorySlots[playerid][i]);
        PlayerTextDrawDestroy(playerid, PlayerInventorySlotBG[playerid][i]);
        PlayerTextDrawDestroy(playerid, PlayerInventorySlotQty[playerid][i]);
    }
    return 1;
}

// Ham cap nhat player preview model - Optimized
stock UpdatePlayerPreview(playerid) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || !InventoryOpen[playerid]) return 0;
    
    PlayerTextDrawSetPreviewModel(playerid, PlayerInventoryTD[playerid][inv_player_preview], PlayerInfo[playerid][pModel]);
    return 1;
}

// Ham goi khi nguoi choi thay doi skin - Optimized
stock OnPlayerSkinChanged(playerid) {
    if(!IsPlayerConnected(playerid)) return 0;
    UpdatePlayerPreview(playerid);
    return 1;
}

// Ham cap nhat hien thi inventory
stock UpdateInventoryDisplay(playerid) {
    // Cap nhat phan trang
    new page_str[32];
    format(page_str, sizeof(page_str), "~w~Trang ~y~%d~w~/~y~%d", CurrentPage[playerid] + 1, MAX_PAGES);
    PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_page_text], page_str);
    
    // Cap nhat mau nut Previous
    if(CurrentPage[playerid] > 0) {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], 0x4CAF50DD);
    } else {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg], 0x757575DD);
    }
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg]);
    
    // Cap nhat mau nut Next
    if(CurrentPage[playerid] < MAX_PAGES - 1) {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], 0x4CAF50DD);
    } else {
        PlayerTextDrawColor(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg], 0x757575DD);
    }
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg]);
    
    // Cap nhat stats
    new Float:health, Float:armor;
    GetPlayerHealth(playerid, health);
    GetPlayerArmour(playerid, armor);
    
    new health_str[32], armor_str[32], money_str[32];
    format(health_str, sizeof(health_str), "~r~Mau: ~w~%.0f", health);
    format(armor_str, sizeof(armor_str), "~b~Giap: ~w~%.0f", armor);
    format(money_str, sizeof(money_str), "~g~Tien: ~y~$%s", FormatInventoryMoney(GetPlayerMoney(playerid)));
    
    PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_health_text], health_str);
    PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_armor_text], armor_str);
    PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_money_text], money_str);
    
    // Cap nhat cac slot - Chi hien thi slots cua trang hien tai
    new start_slot = CurrentPage[playerid] * SLOTS_PER_PAGE;
    new end_slot = start_slot + SLOTS_PER_PAGE;
    if(end_slot > MAX_INVENTORY_SLOTS) end_slot = MAX_INVENTORY_SLOTS;
    
    // An tat ca slots hien thi truoc
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        PlayerTextDrawHide(playerid, PlayerInventorySlots[playerid][i]);
        PlayerTextDrawHide(playerid, PlayerInventorySlotBG[playerid][i]);
        PlayerTextDrawHide(playerid, PlayerInventorySlotQty[playerid][i]);
    }
    
    // Hien thi slots cua trang hien tai
    new display_index = 0;
    for(new i = start_slot; i < end_slot; i++) {
        if(display_index >= SLOTS_PER_PAGE) break;
        
        if(PlayerInventory[playerid][i][inv_item_id] != -1) {
            new itemdata = GetItemDataByID(PlayerInventory[playerid][i][inv_item_id]);
            if(itemdata != -1) {
                // Hien thi 3D model icon cua item
                PlayerTextDrawSetPreviewModel(playerid, PlayerInventorySlots[playerid][display_index], ItemData[itemdata][item_model]);
                PlayerTextDrawSetPreviewRot(playerid, PlayerInventorySlots[playerid][display_index], -10.0, 0.0, -20.0, 1.0);
                PlayerTextDrawShow(playerid, PlayerInventorySlots[playerid][display_index]);
                
                // Hien thi quantity cho tat ca items
                new quantity_str[8];
                if(PlayerInventory[playerid][i][inv_quantity] > 1) {
                    format(quantity_str, sizeof(quantity_str), "x%d", PlayerInventory[playerid][i][inv_quantity]);
                } else {
                    format(quantity_str, sizeof(quantity_str), "x1");
                }
                PlayerTextDrawSetString(playerid, PlayerInventorySlotQty[playerid][display_index], quantity_str);
                PlayerTextDrawShow(playerid, PlayerInventorySlotQty[playerid][display_index]);
                
                // Doi mau slot neu co item
                PlayerTextDrawColor(playerid, PlayerInventorySlotBG[playerid][display_index], 0x555555BB);
                PlayerTextDrawShow(playerid, PlayerInventorySlotBG[playerid][display_index]);
            }
        } else {
            // Slot trong - Chi hien thi background, khong co icon va quantity
            PlayerTextDrawHide(playerid, PlayerInventorySlots[playerid][display_index]);
            PlayerTextDrawHide(playerid, PlayerInventorySlotQty[playerid][display_index]);
            PlayerTextDrawColor(playerid, PlayerInventorySlotBG[playerid][display_index], 0x333333BB);
            PlayerTextDrawShow(playerid, PlayerInventorySlotBG[playerid][display_index]);
        }
        display_index++;
    }
    
    // Reset item info neu khong co item nao duoc chon
    if(SelectedSlot[playerid] == -1) {
        PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_item_name], "~g~ITEM INFO");
        PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_item_desc], "Chon mot item~n~de xem thong tin");
    }
    
    return 1;
}

// Ham mo inventory
stock ShowPlayerInventory(playerid) {
    if(InventoryOpen[playerid]) return 0;
    
    CreateInventoryTextdraws(playerid);
    
    // Hien thi tat ca PlayerTextDraw
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_bg_border]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_title_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_title]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_close_btn]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_item_info]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_item_info_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_item_name]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_item_desc]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_use_btn]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_drop_btn]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg]);
    // Phan trang
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_page_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_page_text]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_prev_btn]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_next_btn]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg]);
    // Player preview va stats
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_player_preview]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_stats_bg]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_health_text]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_armor_text]);
    PlayerTextDrawShow(playerid, PlayerInventoryTD[playerid][inv_money_text]);
    
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        PlayerTextDrawShow(playerid, PlayerInventorySlotBG[playerid][i]);
    }
    
    UpdateInventoryDisplay(playerid);
    UpdatePlayerPreview(playerid); // Cap nhat preview model
    
    InventoryOpen[playerid] = true;
    SelectedSlot[playerid] = -1;
    SelectTextDraw(playerid, 0x4CAF50FF);
    
    return 1;
}

// Ham dong inventory  
stock HideInventory(playerid) {
    if(!InventoryOpen[playerid]) return 0;
    
    // An tat ca PlayerTextDraw
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_bg_border]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_title_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_title]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_close_btn]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_close_btn_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_item_info]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_item_info_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_item_name]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_item_desc]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_use_btn]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_use_btn_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_drop_btn]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_drop_btn_bg]);
    // Phan trang
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_page_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_page_text]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_prev_btn]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_prev_btn_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_next_btn]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_next_btn_bg]);
    // Player preview va stats
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_player_preview]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_stats_bg]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_health_text]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_armor_text]);
    PlayerTextDrawHide(playerid, PlayerInventoryTD[playerid][inv_money_text]);
    
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        PlayerTextDrawHide(playerid, PlayerInventorySlots[playerid][i]);
        PlayerTextDrawHide(playerid, PlayerInventorySlotBG[playerid][i]);
        PlayerTextDrawHide(playerid, PlayerInventorySlotQty[playerid][i]);
    }
    
    DestroyInventoryTextdraws(playerid);
    
    InventoryOpen[playerid] = false;
    SelectedSlot[playerid] = -1;
    CancelSelectTextDraw(playerid);
    
    return 1;
}

// Ham xu ly khi chon slot
stock OnInventorySlotClick(playerid, slot) {
    if(slot < 0 || slot >= MAX_INVENTORY_SLOTS) return 0;
    
    // Neu dang trong che do drag
    if(DragMode[playerid]) {
        // Neu click vao slot khac, thuc hien di chuyen
        if(DragSourceSlot[playerid] != slot) {
            if(MoveInventoryItem(playerid, DragSourceSlot[playerid], slot)) {
                UpdateInventoryDisplay(playerid);
            }
        }
        
        // Tat che do drag
        DragMode[playerid] = false;
        DragSourceSlot[playerid] = -1;
        
        // Reset mau tat ca slots ve trang thai binh thuong
        ResetAllSlotColors(playerid);
        
        // Chi highlight slot neu co item trong do
        if(PlayerInventory[playerid][slot][inv_item_id] != -1) {
            SelectedSlot[playerid] = slot;
            HighlightSlot(playerid, slot, 0x4CAF50BB);
        } else {
            SelectedSlot[playerid] = -1;
        }
    } else {
        // Neu co item trong slot, bat dau che do drag
        if(PlayerInventory[playerid][slot][inv_item_id] != -1) {
            DragMode[playerid] = true;
            DragSourceSlot[playerid] = slot;
            
            // Highlight slot nguon bang mau cam
            HighlightSlot(playerid, slot, 0xFF9800BB);
        } else {
            // Slot trong - chi reset selection, khong highlight
            SelectedSlot[playerid] = -1;
            ResetAllSlotColors(playerid);
        }
    }
    
    if(PlayerInventory[playerid][slot][inv_item_id] != -1) {
        new itemdata = GetItemDataByID(PlayerInventory[playerid][slot][inv_item_id]);
        if(itemdata != -1) {
            new info_str[128];
            format(info_str, sizeof(info_str), "~g~%s", ItemData[itemdata][item_name]);
            PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_item_name], info_str);
            
            format(info_str, sizeof(info_str), "%s~n~~w~So luong: ~y~%d", 
                ItemData[itemdata][item_description], PlayerInventory[playerid][slot][inv_quantity]);
            PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_item_desc], info_str);
        }
    } else {
        PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_item_name], "~g~ITEM INFO");
        PlayerTextDrawSetString(playerid, PlayerInventoryTD[playerid][inv_item_desc], "Slot trong~n~Khong co item");
    }
    
    return 1;
}

// Ham su dung item
stock UseInventoryItem(playerid, slot) {
    if(slot < 0 || slot >= MAX_INVENTORY_SLOTS) return 0;
    if(PlayerInventory[playerid][slot][inv_item_id] == -1) return 0;
    
    new itemid = PlayerInventory[playerid][slot][inv_item_id];
    new itemdata = GetItemDataByID(itemid);
    if(itemdata == -1) return 0;
    
    if(!ItemData[itemdata][item_usable]) {
        SendClientMessage(playerid, 0xFF0000FF, "Item nay khong the su dung!");
        return 0;
    }
    
    new string[128];
    format(string, sizeof(string), "Ban da su dung %s", ItemData[itemdata][item_name]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    // Xu ly tac dung cua item
    switch(itemid) {
        case 1: { // Nuoc uong
            SetPlayerHealth(playerid, 100.0);
            SendClientMessage(playerid, 0x00AAFFFF, "Ban cam thay khoe khoan hon!");
        }
        case 2: { // Banh mi  
            new Float:health;
            GetPlayerHealth(playerid, health);
            SetPlayerHealth(playerid, health + 25.0);
            SendClientMessage(playerid, 0x00AAFFFF, "Ban cam thay no bung!");
        }
        case 3: { // Bandage
            new Float:health;
            GetPlayerHealth(playerid, health);
            SetPlayerHealth(playerid, health + 50.0);
            SendClientMessage(playerid, 0x00AAFFFF, "Ban da cuon bang va cam thay tot hon!");
        }
        case 4: { // Painkillers
            SetPlayerHealth(playerid, 100.0);
            SendClientMessage(playerid, 0x00AAFFFF, "Thuoc giam dau da phat huy tac dung!");
        }
        case 8: { // Phone
            SendClientMessage(playerid, 0xFFFF00FF, "Ban da mo dien thoai!");
            // Co the them chuc nang dien thoai o day
        }
        case 9: { // Cigarettes
            SendClientMessage(playerid, 0xAAAAAAAA, "Ban da hut thuoc la...");
            // Co the them animation hut thuoc
        }
    }
    
    RemoveItemFromInventory(playerid, itemid, 1);
    OnInventorySlotClick(playerid, slot); // Cap nhat thong tin hien thi
    
    return 1;
}

// Ham vut bo item
stock DropInventoryItem(playerid, slot) {
    if(slot < 0 || slot >= MAX_INVENTORY_SLOTS) return 0;
    if(PlayerInventory[playerid][slot][inv_item_id] == -1) return 0;
    
    new itemid = PlayerInventory[playerid][slot][inv_item_id];
    new itemdata = GetItemDataByID(itemid);
    if(itemdata == -1) return 0;
    
    // Animation drop item
    ApplyAnimation(playerid, "GRENADE", "WEAPON_throwu", 4.0, 0, 0, 0, 0, 0);
    
    // Tao object item tren mat dat (co the them sau)
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    CreateObject(ItemData[itemdata][item_model], x + 1.0, y, z - 0.8, 0.0, 0.0, 0.0);
    
    RemoveItemFromInventory(playerid, itemid, 1);
    OnInventorySlotClick(playerid, slot); // Cap nhat thong tin hien thi
    
    return 1;
}

// Ham format tien te - Su dung ham co san trong gamemode
stock FormatInventoryMoney(money) {
    new str[16];
    format(str, sizeof(str), "%d", money);
    return str;
}

// Ham di chuyen item giua cac slot
stock MoveInventoryItem(playerid, from_slot, to_slot) {
    if(from_slot < 0 || from_slot >= MAX_INVENTORY_SLOTS) return 0;
    if(to_slot < 0 || to_slot >= MAX_INVENTORY_SLOTS) return 0;
    if(from_slot == to_slot) return 0;
    
    // Kiem tra slot nguon co item khong
    if(PlayerInventory[playerid][from_slot][inv_item_id] == -1) return 0;
    
    // Neu slot dich trong, di chuyen truc tiep
    if(PlayerInventory[playerid][to_slot][inv_item_id] == -1) {
        PlayerInventory[playerid][to_slot][inv_item_id] = PlayerInventory[playerid][from_slot][inv_item_id];
        PlayerInventory[playerid][to_slot][inv_quantity] = PlayerInventory[playerid][from_slot][inv_quantity];
        PlayerInventory[playerid][to_slot][inv_slot] = to_slot;
        
        // Xoa slot nguon
        PlayerInventory[playerid][from_slot][inv_item_id] = -1;
        PlayerInventory[playerid][from_slot][inv_quantity] = 0;
        PlayerInventory[playerid][from_slot][inv_slot] = from_slot;
        

        return 1;
    }
    
    // Neu slot dich co item khac, hoan doi vi tri
    if(PlayerInventory[playerid][to_slot][inv_item_id] != PlayerInventory[playerid][from_slot][inv_item_id]) {
        new temp_id = PlayerInventory[playerid][from_slot][inv_item_id];
        new temp_quantity = PlayerInventory[playerid][from_slot][inv_quantity];
        
        // Hoan doi item tu slot nguon sang slot dich
        PlayerInventory[playerid][from_slot][inv_item_id] = PlayerInventory[playerid][to_slot][inv_item_id];
        PlayerInventory[playerid][from_slot][inv_quantity] = PlayerInventory[playerid][to_slot][inv_quantity];
        PlayerInventory[playerid][from_slot][inv_slot] = from_slot;
        
        // Chuyen item tu temp sang slot dich
        PlayerInventory[playerid][to_slot][inv_item_id] = temp_id;
        PlayerInventory[playerid][to_slot][inv_quantity] = temp_quantity;
        PlayerInventory[playerid][to_slot][inv_slot] = to_slot;
        

        

        return 1;
    }
    
    // Neu cung loai item, gop lai (stack)
    if(PlayerInventory[playerid][to_slot][inv_item_id] == PlayerInventory[playerid][from_slot][inv_item_id]) {
        new total_quantity = PlayerInventory[playerid][to_slot][inv_quantity] + PlayerInventory[playerid][from_slot][inv_quantity];
        new itemdata = GetItemDataByID(PlayerInventory[playerid][from_slot][inv_item_id]);
        new item_name_str[32] = "Item";
        
        if(itemdata != -1) {
            format(item_name_str, sizeof(item_name_str), "%s", ItemData[itemdata][item_name]);
        }
        
        if(total_quantity <= MAX_ITEM_STACK) {
            PlayerInventory[playerid][to_slot][inv_quantity] = total_quantity;
            
            // Xoa slot nguon
            PlayerInventory[playerid][from_slot][inv_item_id] = -1;
            PlayerInventory[playerid][from_slot][inv_quantity] = 0;
            PlayerInventory[playerid][from_slot][inv_slot] = from_slot;
            return 1;
        } else {
            // Khong the gop het, chi chuyen mot phan
            PlayerInventory[playerid][to_slot][inv_quantity] = MAX_ITEM_STACK;
            PlayerInventory[playerid][from_slot][inv_quantity] = total_quantity - MAX_ITEM_STACK;
            

            return 1;
        }
    }
    
    return 0;
}

// Ham reset mau tat ca slots - Optimized
stock ResetAllSlotColors(playerid) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || !InventoryOpen[playerid]) return 0;
    
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        new actual_slot = (CurrentPage[playerid] * SLOTS_PER_PAGE) + i;
        if(actual_slot < MAX_INVENTORY_SLOTS) {
            new color = (PlayerInventory[playerid][actual_slot][inv_item_id] != -1) ? 0x555555BB : 0x333333BB;
            PlayerTextDrawColor(playerid, PlayerInventorySlotBG[playerid][i], color);
            PlayerTextDrawShow(playerid, PlayerInventorySlotBG[playerid][i]);
        }
    }
    return 1;
}

// Ham highlight mot slot cu the - Optimized
stock HighlightSlot(playerid, slot, color) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || !InventoryOpen[playerid]) return 0;
    if(slot < 0 || slot >= MAX_INVENTORY_SLOTS) return 0;
    
    new display_slot = slot - (CurrentPage[playerid] * SLOTS_PER_PAGE);
    if(display_slot >= 0 && display_slot < SLOTS_PER_PAGE) {
        PlayerTextDrawColor(playerid, PlayerInventorySlotBG[playerid][display_slot], color);
        PlayerTextDrawShow(playerid, PlayerInventorySlotBG[playerid][display_slot]);
    }
    return 1;
}

// ===================== COMMANDS - Su dung iZCMD =====================
CMD:balo(playerid, params[]) {
    if(InventoryOpen[playerid]) {
        HideInventory(playerid);
        SendClientMessageEx(playerid, COLOR_GREY, "Ban da dong balo.");
    } else {
        ShowPlayerInventory(playerid);
        SendClientMessageEx(playerid, COLOR_GREY, "Ban da mo balo. Su dung chuot de tuong tac.");
    }
    return 1;
}


CMD:giveitem(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] < 2) {
        SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong duoc phep su dung lenh nay.");
        return 1;
    }
    
    // Hien thi dialog chon item
    ShowGiveItemDialog(playerid);
    return 1;
}

// Ham hien thi dialog chon item
stock ShowGiveItemDialog(playerid) {
    new dialog[2048];
    dialog[0] = EOS;
    
    strcat(dialog, "{FFFF00}=== 24/7 STORE ITEMS ===\n");
    strcat(dialog, "{FFFFFF}Chon item ban muon give:\n\n");
    
    // Tao danh sach items - them debug info
    for(new i = 0; i < sizeof(ItemData); i++) {
        new line[128];
        format(line, sizeof(line), "{00FF00}%s {FFFFFF}- {FFFF00}$%d {CCCCCC}(ID:%d)\n", 
            ItemData[i][item_name], ItemData[i][item_price], ItemData[i][item_id]);
        strcat(dialog, line);
    }
    
    ShowPlayerDialog(playerid, DIALOG_GIVEITEM_MAIN, DIALOG_STYLE_LIST, 
        "{00FF00}Admin - Give Item", dialog, "Chon", "Huy");
    
    return 1;
}

// Ham hien thi dialog chon player
stock ShowGiveItemPlayerDialog(playerid, itemid) {
    GiveItemID[playerid] = itemid;
    
    new dialog[2048];
    dialog[0] = EOS;
    
    new itemdata = GetItemDataByID(itemid);
    if(itemdata == -1) return 0;
    
    format(dialog, sizeof(dialog), "{FFFF00}=== GIVE ITEM: %s ===\n", ItemData[itemdata][item_name]);
    strcat(dialog, "{FFFFFF}Chon nguoi choi de give item:\n\n");
    
    // Danh sach players online - su dung for loop de dam bao thu tu
    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(IsPlayerConnected(i)) {
            new line[64];
            format(line, sizeof(line), "{00FF00}%s {FFFFFF}(ID: %d)\n", GetPlayerNameEx(i), i);
            strcat(dialog, line);
        }
    }
    
    ShowPlayerDialog(playerid, DIALOG_GIVEITEM_PLAYER, DIALOG_STYLE_LIST,
        "{00FF00}Admin - Chon Player", dialog, "Chon", "Quay lai");
    
    return 1;
}

// Ham hien thi dialog nhap so luong
stock ShowGiveItemQuantityDialog(playerid, targetid, itemid) {
    GiveItemTargetID[playerid] = targetid;
    GiveItemID[playerid] = itemid;
    
    new itemdata = GetItemDataByID(itemid);
    if(itemdata == -1) return 0;
    
    new dialog[512];
    format(dialog, sizeof(dialog), 
        "{FFFF00}=== GIVE ITEM ===\n\n" \
        "{FFFFFF}Item: {00FF00}%s\n" \
        "{FFFFFF}Player: {00FF00}%s {FFFFFF}(ID: %d)\n" \
        "{FFFFFF}Gia: {FFFF00}$%d\n\n" \
        "{FFFFFF}Nhap so luong (1-%d):",
        ItemData[itemdata][item_name], GetPlayerNameEx(targetid), targetid, 
        ItemData[itemdata][item_price], MAX_ITEM_STACK);
    
    ShowPlayerDialog(playerid, DIALOG_GIVEITEM_QUANTITY, DIALOG_STYLE_INPUT,
        "{00FF00}Admin - Nhap So Luong", dialog, "Give", "Quay lai");
    
    return 1;
}

CMD:cleandrops(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] < 2) {
        SendClientMessage(playerid, COLOR_GREY, "Ban khong co quyen su dung lenh nay.");
        return 1;
    }
    
    // Xoa tat ca dropped items, khong chi items cu
    new count = 0;
    for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
        if(DroppedItems[i][drop_item_id] != -1) {
            DestroyDroppedItem(i);
            count++;
        }
    }
    
    new string[128];
    format(string, sizeof(string), "Da xoa %d dropped items va reset system.", count);
    SendClientMessage(playerid, COLOR_GREEN, string);
    
    return 1;
}

CMD:dropinfo(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] < 1) {
        SendClientMessage(playerid, COLOR_GREY, "Ban khong co quyen su dung lenh nay.");
        return 1;
    }
    
    new count = 0, oldest_time = gettime();
    for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
        if(DroppedItems[i][drop_item_id] != -1) {
            count++;
            if(DroppedItems[i][drop_time] < oldest_time) {
                oldest_time = DroppedItems[i][drop_time];
            }
        }
    }
    
    new string[256];
    format(string, sizeof(string), 
        "Dropped Items: %d/%d | Item cu nhat: %d giay truoc | Su dung /cleandrops de xoa tat ca", 
        count, MAX_DROPPED_ITEMS, gettime() - oldest_time);
    SendClientMessage(playerid, COLOR_YELLOW, string);
    
    return 1;
}

// Removed saveinventories command - inventory auto saves with gamemode

// ===================== DROP SYSTEM FUNCTIONS =====================

// Ham tim slot trong cho dropped item - Optimized with cleanup
stock GetFreeDropSlot() {
    // Tim slot trong
    for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
        if(DroppedItems[i][drop_item_id] == -1) {
            return i;
        }
    }
    
    // Neu khong co slot trong, tu dong cleanup items cu > 10 phut
    new current_time = gettime();
    new cleaned = 0;
    
    for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
        if(DroppedItems[i][drop_item_id] != -1) {
            // Xoa items sau 10 phut thay vi 30 phut
            if(current_time - DroppedItems[i][drop_time] > 600) {
                DestroyDroppedItem(i);
                cleaned++;
                if(cleaned >= 50) break; // Chi cleanup toi da 50 items moi lan
            }
        }
    }
    
    // Thu lai tim slot trong sau khi cleanup
    if(cleaned > 0) {
        for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
            if(DroppedItems[i][drop_item_id] == -1) {
                return i;
            }
        }
    }
    
    return -1; // Van khong co slot trong
}

// Ham tao dropped item - Optimized
stock CreateDroppedItem(itemid, quantity, Float:x, Float:y, Float:z, worldid = 0, interior = 0) {
    // Validation checks
    if(itemid < 0 || quantity <= 0) return -1;
    
    new slot = GetFreeDropSlot();
    if(slot == -1) return -1; // Khong con slot trong
    
    // Lay thong tin item
    new itemdata = GetItemDataByID(itemid);
    if(itemdata == -1) return -1; // Item khong hop le
    
    // Tao object
    DroppedItems[slot][drop_object_id] = CreateDynamicObject(DROPPED_ITEM_OBJECT, x, y, z - 0.9, 0.0, 0.0, 0.0, worldid, interior);
    
    // Tao 3D text label
    new label_text[128];
    if(quantity > 1) {
        format(label_text, sizeof(label_text), "{FFFF00}%s\n{FFFFFF}So luong: {00FF00}%d\n{CCCCCC}Nhan {FFFF00}Y {CCCCCC}de nhat", 
            ItemData[itemdata][item_name], quantity);
    } else {
        format(label_text, sizeof(label_text), "{FFFF00}%s\n{CCCCCC}Nhan {FFFF00}Y {CCCCCC}de nhat", 
            ItemData[itemdata][item_name]);
    }
    
    DroppedItems[slot][drop_label] = CreateDynamic3DTextLabel(label_text, 0xFFFFFFFF, x, y, z, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, worldid, interior);
    
    // Luu thong tin
    DroppedItems[slot][drop_item_id] = itemid;
    DroppedItems[slot][drop_quantity] = quantity;
    DroppedItems[slot][drop_x] = x;
    DroppedItems[slot][drop_y] = y;
    DroppedItems[slot][drop_z] = z;
    DroppedItems[slot][drop_world] = worldid;
    DroppedItems[slot][drop_interior] = interior;
    DroppedItems[slot][drop_time] = gettime();
    
    return slot;
}

// Ham xoa dropped item - Optimized
stock DestroyDroppedItem(slot) {
    // Validation checks
    if(slot < 0 || slot >= MAX_DROPPED_ITEMS) return 0;
    if(DroppedItems[slot][drop_item_id] == 0) return 0;
    
    // Xoa object va 3D text - Safe destroy
    if(DroppedItems[slot][drop_object_id] != INVALID_OBJECT_ID) {
        DestroyDynamicObject(DroppedItems[slot][drop_object_id]);
    }
    if(DroppedItems[slot][drop_label] != Text3D:INVALID_3DTEXT_ID) {
        DestroyDynamic3DTextLabel(DroppedItems[slot][drop_label]);
    }
    
    // Reset data - Optimized
    DroppedItems[slot][drop_item_id] = -1;
    DroppedItems[slot][drop_quantity] = 0;
    DroppedItems[slot][drop_object_id] = INVALID_OBJECT_ID;
    DroppedItems[slot][drop_label] = Text3D:INVALID_3DTEXT_ID;
    DroppedItems[slot][drop_x] = 0.0;
    DroppedItems[slot][drop_y] = 0.0;
    DroppedItems[slot][drop_z] = 0.0;
    DroppedItems[slot][drop_world] = 0;
    DroppedItems[slot][drop_interior] = 0;
    DroppedItems[slot][drop_time] = 0;
    
    return 1;
}

// Ham tim dropped item gan player
stock GetNearestDroppedItem(playerid, Float:range = 2.0) {
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new world = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);
    
    for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
        if(DroppedItems[i][drop_item_id] == -1) continue;
        if(DroppedItems[i][drop_world] != world) continue;
        if(DroppedItems[i][drop_interior] != interior) continue;
        
        new Float:distance = GetPlayerDistanceFromPoint(playerid, DroppedItems[i][drop_x], DroppedItems[i][drop_y], DroppedItems[i][drop_z]);
        if(distance <= range) {
            return i;
        }
    }
    return -1;
}

// Ham show dialog drop quantity
stock ShowDropQuantityDialog(playerid, slot) {
    if(slot < 0 || slot >= MAX_INVENTORY_SLOTS) return 0;
    if(PlayerInventory[playerid][slot][inv_item_id] == -1) return 0;
    
    DropSlot[playerid] = slot;
    
    new itemdata = GetItemDataByID(PlayerInventory[playerid][slot][inv_item_id]);
    if(itemdata == -1) return 0;
    
    new dialog[512];
    format(dialog, sizeof(dialog), 
        "{FFFF00}=== VUT BO ITEM ===\n\n" \
        "{FFFFFF}Item: {00FF00}%s\n" \
        "{FFFFFF}So luong hien tai: {FFFF00}%d\n" \
        "{FFFFFF}Gia: {FFFF00}$%d\n\n" \
        "{FFFFFF}Nhap so luong muon vut (1-%d):",
        ItemData[itemdata][item_name], PlayerInventory[playerid][slot][inv_quantity],
        ItemData[itemdata][item_price], PlayerInventory[playerid][slot][inv_quantity]);
    
    ShowPlayerDialog(playerid, DIALOG_DROP_QUANTITY, DIALOG_STYLE_INPUT,
        "{FF9800}Drop Item", dialog, "Drop", "Huy");
    
    return 1;
}

// Ham cleanup dropped items cu - Da duoc tich hop vao GetFreeDropSlot()

// Ham init drop system
stock InitDropSystem() {
    // Reset tat ca dropped items
    for(new i = 0; i < MAX_DROPPED_ITEMS; i++) {
        DroppedItems[i][drop_item_id] = -1;
        DroppedItems[i][drop_quantity] = 0;
        DroppedItems[i][drop_object_id] = INVALID_OBJECT_ID;
        DroppedItems[i][drop_label] = Text3D:INVALID_3DTEXT_ID;
        DroppedItems[i][drop_x] = 0.0;
        DroppedItems[i][drop_y] = 0.0;
        DroppedItems[i][drop_z] = 0.0;
        DroppedItems[i][drop_world] = 0;
        DroppedItems[i][drop_interior] = 0;
        DroppedItems[i][drop_time] = 0;
    }
    
    // Drop system initialized
    return 1;
}

// Ham luu inventory cua nguoi choi vao PlayerInfo
stock SavePlayerInventory(playerid) {
    if(!IsPlayerConnected(playerid)) return 0;
    
    // Format: "slot:itemid:quantity|slot:itemid:quantity|..."
    new inv_string[1024];
    inv_string[0] = '\0';
    
    new bool:first = true;
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++) {
        if(PlayerInventory[playerid][i][inv_item_id] != -1) {
            new item_data[32];
            format(item_data, sizeof(item_data), "%s%d:%d:%d", 
                first ? "" : "|", 
                i, 
                PlayerInventory[playerid][i][inv_item_id], 
                PlayerInventory[playerid][i][inv_quantity]
            );
            strcat(inv_string, item_data, sizeof(inv_string));
            first = false;
        }
    }
    
    // Luu vao PlayerInfo
    strcpy(PlayerInfo[playerid][pInventoryData], inv_string, 1024);
    return 1;
}

// Ham tai inventory cua nguoi choi tu PlayerInfo
stock LoadPlayerInventory(playerid) {
    if(!IsPlayerConnected(playerid)) return 0;
    
    // Reset inventory truoc khi load
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++) {
        PlayerInventory[playerid][i][inv_item_id] = -1;
        PlayerInventory[playerid][i][inv_quantity] = 0;
    }
    
    // Neu khong co du lieu inventory, return
    if(strlen(PlayerInfo[playerid][pInventoryData]) == 0) {
        // Khong co du lieu inventory, tao moi
        return 1;
    }
    
    // Parse string format: "slot:itemid:quantity|slot:itemid:quantity|..."
    new inv_data[1024];
    strcpy(inv_data, PlayerInfo[playerid][pInventoryData], sizeof(inv_data));
    
    new items_loaded = 0;
    new item_part[64];
    new pos = 0;
    
    // Split by "|"
    while(pos < strlen(inv_data)) {
        new next_pos = strfind(inv_data[pos], "|", false);
        if(next_pos == -1) next_pos = strlen(inv_data) - pos;
        
        strmid(item_part, inv_data[pos], 0, next_pos, sizeof(item_part));
        
        // Parse "slot:itemid:quantity"
        new slot, itemid, quantity;
        if(sscanf(item_part, "p<:>ddd", slot, itemid, quantity) == 0) {
            if(slot >= 0 && slot < MAX_INVENTORY_SLOTS && itemid != -1 && quantity > 0) {
                PlayerInventory[playerid][slot][inv_item_id] = itemid;
                PlayerInventory[playerid][slot][inv_quantity] = quantity;
                items_loaded++;
            }
        }
        
        pos += next_pos + 1;
        if(inv_data[pos-1] != '|') break;
    }
    
    // Da tai inventory thanh cong
    return 1;
}

// Ham luu inventory khi player disconnect hoac save
stock SavePlayerInventoryOnDisconnect(playerid) {
    SavePlayerInventory(playerid); // Luu vao PlayerInfo
    return 1;
}

// ===================== DIALOG RESPONSES =====================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    switch(dialogid) {
        case DIALOG_GIVEITEM_MAIN: {
            if(!response) return 1;
            
            if(listitem < 0 || listitem >= sizeof(ItemData)) return 1;
            
            // Lay item ID dung theo vi tri trong ItemData array
            new itemid = ItemData[listitem][item_id];
            ShowGiveItemPlayerDialog(playerid, itemid);
            return 1;
        }
        
        case DIALOG_GIVEITEM_PLAYER: {
            if(!response) {
                ShowGiveItemDialog(playerid);
                return 1;
            }
            
            // Tim player theo listitem - khop voi for loop trong ShowGiveItemPlayerDialog
            new count = 0;
            new targetid = -1;
            for(new i = 0; i < MAX_PLAYERS; i++) {
                if(IsPlayerConnected(i)) {
                    if(count == listitem) {
                        targetid = i;
                        break;
                    }
                    count++;
                }
            }
            
            if(targetid == -1 || !IsPlayerConnected(targetid)) {
                SendClientMessage(playerid, COLOR_RED, "Player khong hop le!");
                ShowGiveItemPlayerDialog(playerid, GiveItemID[playerid]);
                return 1;
            }
            
            ShowGiveItemQuantityDialog(playerid, targetid, GiveItemID[playerid]);
            return 1;
        }
        
        case DIALOG_GIVEITEM_QUANTITY: {
            if(!response) {
                ShowGiveItemPlayerDialog(playerid, GiveItemID[playerid]);
                return 1;
            }
            
            new quantity = strval(inputtext);
            if(quantity < 1 || quantity > MAX_ITEM_STACK) {
                SendClientMessage(playerid, COLOR_RED, "So luong phai tu 1 den 99!");
                ShowGiveItemQuantityDialog(playerid, GiveItemTargetID[playerid], GiveItemID[playerid]);
                return 1;
            }
            
            new targetid = GiveItemTargetID[playerid];
            new itemid = GiveItemID[playerid];
            
            if(!IsPlayerConnected(targetid)) {
                SendClientMessage(playerid, COLOR_RED, "Player khong online!");
                return 1;
            }
            
            // Give item
            if(AddItemToInventory(targetid, itemid, quantity)) {
                new itemdata = GetItemDataByID(itemid);
                if(itemdata != -1) {
                    new string[128];
                    format(string, sizeof(string), "Admin %s da give cho ban %dx %s", 
                        GetPlayerNameEx(playerid), quantity, ItemData[itemdata][item_name]);
                    SendClientMessageEx(targetid, COLOR_LIGHTBLUE, string);
                    
                    format(string, sizeof(string), "Ban da give %dx %s cho %s", 
                        quantity, ItemData[itemdata][item_name], GetPlayerNameEx(targetid));
                    SendClientMessageEx(playerid, COLOR_LIGHTBLUE, string);
                }
            } else {
                SendClientMessage(playerid, COLOR_RED, "Khong the give item (balo day hoac loi)!");
            }
            
            // Reset variables
            GiveItemTargetID[playerid] = -1;
            GiveItemID[playerid] = -1;
            return 1;
        }
        
        case DIALOG_DROP_QUANTITY: {
            if(!response) {
                DropSlot[playerid] = -1;
                return 1;
            }
            
            new quantity = strval(inputtext);
            new slot = DropSlot[playerid];
            
            if(slot == -1 || PlayerInventory[playerid][slot][inv_item_id] == -1) {
                SendClientMessage(playerid, COLOR_RED, "Loi: Slot khong hop le!");
                DropSlot[playerid] = -1;
                return 1;
            }
            
            if(quantity < 1 || quantity > PlayerInventory[playerid][slot][inv_quantity]) {
                SendClientMessage(playerid, COLOR_RED, "So luong khong hop le!");
                ShowDropQuantityDialog(playerid, slot);
                return 1;
            }
            
            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            
            x += (random(200) - 100) / 100.0; // -1.0 den 1.0
            y += (random(200) - 100) / 100.0;
            
            new world = GetPlayerVirtualWorld(playerid);
            new interior = GetPlayerInterior(playerid);
            
            ApplyAnimation(playerid, "GRENADE", "WEAPON_throwu", 4.0, 0, 0, 0, 0, 0);
            
            new drop_slot = CreateDroppedItem(PlayerInventory[playerid][slot][inv_item_id], quantity, x, y, z, world, interior);
            if(drop_slot != -1) {
                PlayerInventory[playerid][slot][inv_quantity] -= quantity;
                if(PlayerInventory[playerid][slot][inv_quantity] <= 0) {
                    PlayerInventory[playerid][slot][inv_item_id] = -1;
                    PlayerInventory[playerid][slot][inv_quantity] = 0;
                }
                
                UpdateInventoryDisplay(playerid);
                

            } else {
                SendClientMessage(playerid, COLOR_RED, "Khong the tao dropped item (server day)!");
            }
            
            DropSlot[playerid] = -1;
            return 1;
        }
    }
    return 0;
}

// ===================== YSI HOOKS =====================

hook OnGameModeInit() {
    // Defer drop system initialization to prevent blocking
    SetTimer("DeferredBaloInit", 300, false);
    printf("[BALO] Inventory system initialization deferred");
    return 1;
}

// Deferred initialization to prevent blocking OnGameModeInit
forward DeferredBaloInit();
public DeferredBaloInit()
{
    InitDropSystem();
    printf("[BALO] Drop system initialized");
    return 1;
}

hook OnPlayerConnect(playerid) {
    if(!IsPlayerConnected(playerid)) return 0;
    
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++) {
        PlayerInventory[playerid][i][inv_item_id] = -1;
        PlayerInventory[playerid][i][inv_quantity] = 0;
        PlayerInventory[playerid][i][inv_slot] = 0;
    }
    
    InventoryOpen[playerid] = false;
    SelectedSlot[playerid] = -1;
    CurrentPage[playerid] = 0;
    DragMode[playerid] = false;
    DragSourceSlot[playerid] = -1;
    
    GiveItemTargetID[playerid] = -1;
    GiveItemID[playerid] = -1;
    DropSlot[playerid] = -1;
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason) {
    if(!IsPlayerConnected(playerid)) return 0;
    
    SavePlayerInventoryOnDisconnect(playerid);
    
    if(InventoryOpen[playerid]) {
        HideInventory(playerid);
    }
    
    DragMode[playerid] = false;
    DragSourceSlot[playerid] = -1;
    SelectedSlot[playerid] = -1;
    CurrentPage[playerid] = 0;
    
    return 1;
}

hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid) {
    // Validation checks
    if(!IsPlayerConnected(playerid) || !InventoryOpen[playerid]) {
        return 1;
    }
    
    // Nut dong inventory
    if(playertextid == PlayerInventoryTD[playerid][inv_close_btn_bg]) {
        HideInventory(playerid);
        return 1;
    }
    
    // Nut su dung item
    if(playertextid == PlayerInventoryTD[playerid][inv_use_btn_bg]) {
        if(SelectedSlot[playerid] != -1) {
            UseInventoryItem(playerid, SelectedSlot[playerid]);
        }
        return 1;
    }
    
    // Nut vut bo item - Sua de su dung dialog
    if(playertextid == PlayerInventoryTD[playerid][inv_drop_btn_bg]) {
        if(SelectedSlot[playerid] != -1) {
            ShowDropQuantityDialog(playerid, SelectedSlot[playerid]);
        } else {
            SendClientMessage(playerid, COLOR_GREY, "Chon mot item truoc khi drop!");
        }
        return 1;
    }
    
    // Nut Previous Page
    if(playertextid == PlayerInventoryTD[playerid][inv_prev_btn_bg]) {
        if(CurrentPage[playerid] > 0) {
            CurrentPage[playerid]--;
            
            // Chi reset selection neu selected slot khong thuoc trang moi
            if(SelectedSlot[playerid] != -1) {
                new selected_page = SelectedSlot[playerid] / SLOTS_PER_PAGE;
                if(selected_page != CurrentPage[playerid]) {
                    SelectedSlot[playerid] = -1;
                    DragMode[playerid] = false;
                    DragSourceSlot[playerid] = -1;
                }
            }
            
            ResetAllSlotColors(playerid);
            UpdateInventoryDisplay(playerid);
            
            // Neu van co selected slot tren trang moi, highlight lai
            if(SelectedSlot[playerid] != -1) {
                HighlightSlot(playerid, SelectedSlot[playerid], 0x4CAF50BB);
            }
        }
        return 1;
    }
    
    // Nut Next Page
    if(playertextid == PlayerInventoryTD[playerid][inv_next_btn_bg]) {
        if(CurrentPage[playerid] < MAX_PAGES - 1) {
            CurrentPage[playerid]++;
            
            // Chi reset selection neu selected slot khong thuoc trang moi
            if(SelectedSlot[playerid] != -1) {
                new selected_page = SelectedSlot[playerid] / SLOTS_PER_PAGE;
                if(selected_page != CurrentPage[playerid]) {
                    SelectedSlot[playerid] = -1;
                    DragMode[playerid] = false;
                    DragSourceSlot[playerid] = -1;
                }
            }
            
            ResetAllSlotColors(playerid);
            UpdateInventoryDisplay(playerid);
            
            // Neu van co selected slot tren trang moi, highlight lai
            if(SelectedSlot[playerid] != -1) {
                HighlightSlot(playerid, SelectedSlot[playerid], 0x4CAF50BB);
            }
        }
        return 1;
    }
    
    // Check cac slot inventory - Mapping tu display index ve actual slot
    for(new i = 0; i < SLOTS_PER_PAGE; i++) {
        if(playertextid == PlayerInventorySlotBG[playerid][i]) {
            new actual_slot = (CurrentPage[playerid] * SLOTS_PER_PAGE) + i;
            if(actual_slot < MAX_INVENTORY_SLOTS) {
                OnInventorySlotClick(playerid, actual_slot);
            }
            return 1;
        }
    }
    
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if(!IsPlayerConnected(playerid)) return 1;
    
    if((newkeys & KEY_YES) && !InventoryOpen[playerid]) {
        new drop_slot = GetNearestDroppedItem(playerid);
        if(drop_slot != -1) {
            new itemid = DroppedItems[drop_slot][drop_item_id];
            new quantity = DroppedItems[drop_slot][drop_quantity];
            
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant_2Idle", 4.0, 0, 0, 0, 0, 0);
            
            if(AddItemToInventory(playerid, itemid, quantity)) {
                DestroyDroppedItem(drop_slot);
            } else {
                SendClientMessage(playerid, COLOR_RED, "Balo day! Khong the nhat item.");
            }
            return 1; 
        }
    }
    
    if((newkeys & KEY_NO) && InventoryOpen[playerid] && DragMode[playerid]) {
        DragMode[playerid] = false;
        DragSourceSlot[playerid] = -1;
        ResetAllSlotColors(playerid);
        if(SelectedSlot[playerid] != -1) {
            HighlightSlot(playerid, SelectedSlot[playerid], 0x4CAF50BB);
        }
    }
    
    return 1;
}
