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
#include <Pawn.RakNet>                            


/*================== YSI Configuration ==================*/
#define DYNAMIC_MEMORY      (65536) 
#define CGEN_MEMORY         (65536) 

#define YSI_NO_OPTIMISATION_MESSAGE
#define YSI_NO_VERSION_CHECK
#define YSI_NO_CACHE_MESSAGE
#define YSI_NO_HEAP_MALLOC
#define YSI_NO_MODE_CACHE

#include <YSI\YSI_Data\y_bit>
#include <YSI\YSI_Data\y_foreach>
#include <YSI\YSI_Coding\y_timers>
#include <YSI\YSI_Coding\y_va>
#include <YSI\YSI_Core\y_utils>

/*================== Additional Libraries ==================*/
#include <sync_time>
#include <a_pause>
#include <easyDialog>
#include <DialogCenter>
#include <MemoryPluginVersion>

#if defined SOCKET_ENABLED
	#include <socket>
#endif

/*================== Core Game Files ==================*/
#include "./includes/defines.pwn"
#include "./includes/enums.pwn"
#include "./includes/variables.pwn"
#include "./includes/timers.pwn"
#include "./includes/functions.pwn"
#include "./includes/mysql.pwn"
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
/*================== Job Systems ==================*/
#include "./includes/core/Jobs/TruckerDelivery/CompanyTrucker.pwn"

/*================== Game Systems ==================*/
/*================== Administration ==================*/
#include "./includes/core/admin/players.pwn"
#include "./includes/core/admin/faction.pwn"
/*================== Police Systems ==================*/
/*================== Vehicle Systems ==================*/
#include "./includes/core/vehicle/engine_upgrade.pwn"
#include "./includes/core/vehicle/dealership.pwn"
main() {}

public OnGameModeInit()
{
    print("______________________________________________");
    print("|                                            |");
    print("|          Desma City Vietnamese             |");
    print("|                                            |");
    print("|       Copyright  2024 AMB Team             |");
    print("|____________________________________________|");
    
    SetCrashDetectLongCallTime(10000000);
    
    AddSimpleModel(-1, 19379, -2001, "/Server/object.dff", "/Server/LoginPanel.txd");
    AddSimpleModel(-1, 19379, -2003, "/Server/object.dff", "/Server/GPS.txd");

    AddCharModel(2, 20001, "/skin/dylan.dff", "/skin/dylan.txd");
    AddCharModel(155, 20002, "/skin/brian.dff", "/skin/brian.txd");
    g_mysql_Init();
    return 1;
}

public OnGameModeExit() 
{
    g_mysql_Exit();
    return 1;
}
