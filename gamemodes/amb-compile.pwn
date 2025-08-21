/*==============================================================================================================*

      /$$$$$$  /$$      /$$ /$$$$$$$                                  /$$$$$$$  /$$$$$$$   /$$$$$$     /$$$$$ /$$$$$$$$  /$$$$$$  /$$$$$$$$
     /$$__  $$| $$$    /$$$| $$__  $$                                | $$__  $$| $$__  $$ /$$__  $$   |__  $$| $$_____/ /$$__  $$|__  $$__/
    | $$  \ $$| $$$$  /$$$$| $$  \ $$                                | $$  \ $$| $$  \ $$| $$  \ $$      | $$| $$      | $$  \__/   | $$   
    | $$$$$$$$| $$ $$/$$ $$| $$$$$$$              /$$$$$$            | $$$$$$$/| $$$$$$$/| $$  | $$      | $$| $$$$$   | $$         | $$   
    | $$__  $$| $$  $$$| $$| $$__  $$            |______/            | $$____/ | $$__  $$| $$  | $$ /$$  | $$| $$__/   | $$         | $$   
    | $$  | $$| $$\  $ | $$| $$  \ $$                                | $$      | $$  \ $$| $$  | $$| $$  | $$| $$      | $$    $$   | $$   
    | $$  | $$| $$ \/  | $$| $$$$$$$/                                | $$      | $$  | $$|  $$$$$$/|  $$$$$$/| $$$$$$$$|  $$$$$$/   | $$   
    |__/  |__/|__/     |__/|_______/                                 |__/      |__/  |__/ \______/  \______/ |________/ \______/    |__/   

                                ____________________________________________________________________
                                            *-* Director of LS:RP Development:

                                            Eric            - Founder


                                            *-* Development Staff:

                                            Dylan             - Developer

                                            Sei               - Developer
*===============================================================================================================================================*/

#define SERVER_GM_TEXT "AMB version 1.0.0"

#define NO_TAGS
#pragma option -d3
#pragma compress 1
#pragma dynamic 65536

#define MIXED_SPELLINGS
#define LEGACY_SCRIPTING_API
#define SAMP_COMPAT

#include <open.mp>
#include <crashdetect>
#include <a_mysql>
#include <samp_bcrypt>
#include <streamer>
#include <sscanf2>
#include <strlib>
#include <iZCMD>
#include <colandreas>
#include <yom_buttons>

#define PP_SYNTAX_AWAIT
#define PP_SYNTAX_FOR_LIST
#define PP_SYNTAX_FOR_POOL
#include <PawnPlus>

/*================== YSI Configuration ==================*/
#define DYNAMIC_MEMORY      (65536)
#define CGEN_MEMORY         (65536)

#define YSI_NO_OPTIMISATION_MESSAGE
#define YSI_NO_VERSION_CHECK
#define YSI_NO_CACHE_MESSAGE
#define YSI_NO_HEAP_MALLOC
#define YSI_NO_MODE_CACHE
#define YSI_NO_MASTER_INIT  
#define YSI_NO_SCRIPT_INIT

#include <YSI\YSI_Data\y_bit>
#include <YSI\YSI_Data\y_foreach>
#include <YSI\YSI_Coding\y_timers>
#include <YSI\YSI_Coding\y_va>
#include <YSI\YSI_Core\y_utils>

/*================== Additional Libraries ==================*/
#include <a_pause>
#include <easyDialog>
#include <DialogCenter>
#include <MemoryPluginVersion>


#define MP3_CONVERTER_API "http://26.142.249.17:8081"
#define API_KEY ""
#include <Youtube>

#if defined SOCKET_ENABLED
	#include <socket>
#endif
/*================== Core Game Files ==================*/
#include "./includes/defines.pwn"
#include "./includes/enums.pwn"
#include "./includes/variables.pwn"
#include "./includes/mysql.pwn"
#include "./includes/timers.pwn"
#include "./includes/functions.pwn"
#include "./includes/OnPlayerLoad.pwn"
#include "./includes/callbacks.pwn"
#include "./includes/textdraws.pwn"
#include "./includes/streamer.pwn"
#include "./includes/OnDialogResponse.pwn"
#include "./includes/commands.pwn"

/*================== Core Modules ==================*/
#include "./includes/core/server/Main.pwn"

/*================== Features ==================*/
#include "./includes/core/feature/message.pwn"
#include "./includes/core/feature/gps_location.pwn"
#include "./includes/core/feature/planted.pwn"
#include "./includes/core/feature/flymode.pwn"
/*================== Job Systems ==================*/
#include "./includes/core/jobs/TruckerDelivery/CompanyTrucker.pwn"
/*================== Game Systems ==================*/
/*================== Family Systems ==================*/
#include "./includes/core/family/main.pwn"
#include "./includes/core/family/glocker.pwn"
/*================== Player Systems ==================*/
#include "./includes/core/player/bank.pwn"
#include "./includes/core/player/animlist.pwn"
#include "./includes/core/player/hitmarker.pwn"
#include "./includes/core/player/phone.pwn"
#include "./includes/core/player/balo.pwn"
/*================== Administration ==================*/
#include "./includes/core/admin/players.pwn"
#include "./includes/core/admin/faction.pwn"
#include "./includes/core/admin/panelhistory.pwn"
/*================== Police Systems ==================*/
#include "./includes/core/police/checkvehicle.pwn"
/*================== Vehicle Systems ==================*/
#include "./includes/core/vehicle/engine_upgrade.pwn"
#include "./includes/core/vehicle/dealership.pwn"
#include "./includes/core/vehicle/speedo.pwn"
#include "./includes/core/vehicle/caraccident.pwn"
#include "./includes/core/vehicle/music.pwn"
/*================== Mapping Systems ==================*/
#include "./includes/core/mapping/interior/dealership.pwn"
main() {}

public OnGameModeInit()
{
    print("______________________________________________");
    print("|                                            |");
    print("|          AMB Team Vietnamese             	|");
    print("|        Copyright 2024 AMB Team             |");
    print("|____________________________________________|");
    
    SetCrashDetectLongCallTime(120000000); // T?ng th?i gian long call l?n 2 ph?t
    
    SetTimer("LoadCustomModels", 100, false);
    
    g_mysql_Init();
    return 1;
}

forward LoadCustomModels();
public LoadCustomModels()
{
    AddSimpleModel(-1, 19379, -2001, "/Server/object.dff", "/Server/LoginPanel.txd");
    AddSimpleModel(-1, 19379, -2003, "/Server/object.dff", "/Server/GPS.txd");
	AddSimpleModel(-1, 19379, -2004, "/Server/object.dff", "/Server/speedo.txd");

    AddCharModel(2, 20001, "/skin/dylan.dff", "/skin/dylan.txd");
    AddCharModel(155, 20002, "/skin/brian.dff", "/skin/brian.txd");
	AddCharModel(280, 20003, "/skin/lapd1.dff", "/skin/lapd1.txd");
	AddCharModel(280, 20004, "/skin/mafia.dff", "/skin/mafia.txd");
	
	AddCharModel(287, 20005, "/skin/army/army.dff", "/skin/army/army.txd");
    AddCharModel(286, 20006, "/skin/army/fbi.dff", "/skin/army/fbi.txd");
    AddCharModel(280, 20008, "/skin/army/lapd1.dff", "/skin/army/lapd1.txd");
    AddCharModel(284, 20009, "/skin/army/lapdm1.dff", "/skin/army/lapdm1.txd");
    AddCharModel(278, 20010, "/skin/army/lvfd1.dff", "/skin/army/lvfd1.txd");
    AddCharModel(282, 20011, "/skin/army/lvpd1.dff", "/skin/army/lvpd1.txd");
    AddCharModel(281, 20013, "/skin/army/sfpd1.dff", "/skin/army/sfpd1.txd");
    AddCharModel(285, 20014, "/skin/army/swat.dff", "/skin/army/swat.txd");
	AddCharModel(21, 20015, "/skin/army/conmemay.dff", "/skin/army/conmemay.txd");
	
    print("[Models] Custom models loaded successfully!");
    return 1;
}

public OnGameModeExit() 
{
    g_mysql_Exit();
    return 1;
}
