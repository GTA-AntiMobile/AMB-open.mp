#include <YSI/YSI_Coding/y_hooks>

new PlayerText: playerhud_PTD[MAX_PLAYERS][5];

hook OnFeatureSystemInit()
{
    print("GPS Location System Loaded.");
    return 1;
}

stock LoadGPSLocation(playerid) {
    playerhud_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 21.000, 303.000, "mdl-2003:Main");
    PlayerTextDrawTextSize(playerid, playerhud_PTD[playerid][0], 97.000, 23.000);
    PlayerTextDrawAlignment(playerid, playerhud_PTD[playerid][0], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, playerhud_PTD[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, playerhud_PTD[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, playerhud_PTD[playerid][0], 0);
    PlayerTextDrawBackgroundColour(playerid, playerhud_PTD[playerid][0], 255);
    PlayerTextDrawFont(playerid, playerhud_PTD[playerid][0], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, playerhud_PTD[playerid][0], true);

    playerhud_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 31.000, 309.000, "SE");
    PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][1], 0.230, 0.999);
    PlayerTextDrawTextSize(playerid, playerhud_PTD[playerid][1], 0.000, 12.000);
    PlayerTextDrawAlignment(playerid, playerhud_PTD[playerid][1], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, playerhud_PTD[playerid][1], -1);
    PlayerTextDrawSetShadow(playerid, playerhud_PTD[playerid][1], 1);
    PlayerTextDrawSetOutline(playerid, playerhud_PTD[playerid][1], 0);
    PlayerTextDrawBackgroundColour(playerid, playerhud_PTD[playerid][1], 150);
    PlayerTextDrawFont(playerid, playerhud_PTD[playerid][1], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, playerhud_PTD[playerid][1], true);

    playerhud_PTD[playerid][2] = CreatePlayerTextDraw(playerid, 43.000, 306.000, "San Andreas");
    PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][2], 0.158, 0.898);
    PlayerTextDrawTextSize(playerid, playerhud_PTD[playerid][2], 96.000, 58.000);
    PlayerTextDrawAlignment(playerid, playerhud_PTD[playerid][2], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, playerhud_PTD[playerid][2], -1);
    PlayerTextDrawSetShadow(playerid, playerhud_PTD[playerid][2], 1);
    PlayerTextDrawSetOutline(playerid, playerhud_PTD[playerid][2], 0);
    PlayerTextDrawBackgroundColour(playerid, playerhud_PTD[playerid][2], 150);
    PlayerTextDrawFont(playerid, playerhud_PTD[playerid][2], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, playerhud_PTD[playerid][2], true);

    playerhud_PTD[playerid][3] = CreatePlayerTextDraw(playerid, 49.000, 312.000, "Grove Street");
    PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][3], 0.158, 0.898);
    PlayerTextDrawTextSize(playerid, playerhud_PTD[playerid][3], 126.000, 54.000);
    PlayerTextDrawAlignment(playerid, playerhud_PTD[playerid][3], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, playerhud_PTD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, playerhud_PTD[playerid][3], 1);
    PlayerTextDrawSetOutline(playerid, playerhud_PTD[playerid][3], 0);
    PlayerTextDrawBackgroundColour(playerid, playerhud_PTD[playerid][3], 150);
    PlayerTextDrawFont(playerid, playerhud_PTD[playerid][3], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, playerhud_PTD[playerid][3], true);

    playerhud_PTD[playerid][4] = CreatePlayerTextDraw(playerid, 106.000, 310.000, "10:10");
    PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][4], 0.159, 0.898);
    PlayerTextDrawTextSize(playerid, playerhud_PTD[playerid][4], 0.000, 13.000);
    PlayerTextDrawAlignment(playerid, playerhud_PTD[playerid][4], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, playerhud_PTD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, playerhud_PTD[playerid][4], 1);
    PlayerTextDrawSetOutline(playerid, playerhud_PTD[playerid][4], 0);
    PlayerTextDrawBackgroundColour(playerid, playerhud_PTD[playerid][4], 150);
    PlayerTextDrawFont(playerid, playerhud_PTD[playerid][4], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, playerhud_PTD[playerid][4], true);
}

hook OnPlayerConnect(playerid)
{
	LoadGPSLocation(playerid);
	return 1;
}

hook OnPlayerDisconnect(playerid)
{
    HidePlayerHUD(playerid);
    return 1;
}

hook OnPlayerUpdate(playerid)
{
	if(gPlayerLogged{playerid} == 1)
	{
	    UpdatePlayerHUD(playerid);
	}
    return 1;
}

stock HidePlayerHUD(playerid)
{
    PlayerTextDrawHide(playerid, playerhud_PTD[playerid][0]);
    PlayerTextDrawHide(playerid, playerhud_PTD[playerid][1]);
    PlayerTextDrawHide(playerid, playerhud_PTD[playerid][2]);
    PlayerTextDrawHide(playerid, playerhud_PTD[playerid][3]);
    PlayerTextDrawHide(playerid, playerhud_PTD[playerid][4]);
    return 1;
}


stock UpdatePlayerHUD(playerid)
{
    new string[128], 
    Float:rz,
    Float: x, 
    Float: y, 
    Float: z,
    location[MAX_ZONE_NAME],
    location2[MAX_ZONE_NAME];


	GetPlayerPos(playerid, x, y, z);
	GetPlayer3DZone(playerid, location2, sizeof(location2));
    GetPlayerStreetZone(x, y, location, location2, sizeof(location));

    if(IsPlayerInAnyVehicle(playerid)) 
    {
        GetVehicleZAngle(GetPlayerVehicleID(playerid), rz);
    }
    else 
    {
        GetPlayerFacingAngle(playerid, rz);
    }
    if(rz >= 348.75 || rz < 11.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "N");
    else if(rz >= 326.25 && rz < 348.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "NE");
    else if(rz >= 303.75 && rz < 326.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "NE");
    else if(rz >= 281.25 && rz < 303.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "NE");
    else if(rz >= 258.75 && rz < 281.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "E");
    else if(rz >= 236.25 && rz < 258.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "SE");
    else if(rz >= 213.75 && rz < 236.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "SE");
    else if(rz >= 191.25 && rz < 213.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "SE");
    else if(rz >= 168.75 && rz < 191.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "S");
    else if(rz >= 146.25 && rz < 168.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "SW");
    else if(rz >= 123.25 && rz < 146.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "SW");
    else if(rz >= 101.25 && rz < 123.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "SW");
    else if(rz >= 78.75 && rz < 101.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "W");
    else if(rz >= 56.25 && rz < 78.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "NW");
    else if(rz >= 33.75 && rz < 56.25) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "NW");
    else if(rz >= 11.5 && rz < 33.75) PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], "NW");

    strcpy(string, location2, sizeof(string));
    PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][2], string);

    strcpy(string, location, sizeof(string));
    PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][3], string);

    PlayerTextDrawShow(playerid, playerhud_PTD[playerid][0]);
    PlayerTextDrawShow(playerid, playerhud_PTD[playerid][1]); // Angle
    PlayerTextDrawShow(playerid, playerhud_PTD[playerid][2]); // City
    PlayerTextDrawShow(playerid, playerhud_PTD[playerid][3]); // Street
    PlayerTextDrawShow(playerid, playerhud_PTD[playerid][4]); // Time

    new hour, minute, second;
    gettime(hour,minute,second);
    format(string, sizeof(string), "%02d:%02d", hour, minute);
    PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][4], string); // Time
    return 1;
}