#include <YSI/YSI_Coding/y_hooks>

new PlayerText: playerhud_PTD[MAX_PLAYERS][5];
new gps_last_city[MAX_PLAYERS][MAX_ZONE_NAME];
new gps_last_street[MAX_PLAYERS][MAX_ZONE_NAME];
new gps_last_dir[MAX_PLAYERS][4];
new gps_last_minute[MAX_PLAYERS];
new Float:gps_city_size[MAX_PLAYERS];
new Float:gps_street_size[MAX_PLAYERS];
new gps_last_tick[MAX_PLAYERS];

static stock GPS_GetDirStr(Float:rz, dest[], len)
{
	while(rz < 0.0) rz += 360.0;
	while(rz >= 360.0) rz -= 360.0;
	new idx = floatround((rz + 22.5) / 45.0, floatround_floor) % 8;
	switch(idx)
	{
		case 0: format(dest, len, "N");
		case 1: format(dest, len, "NE");
		case 2: format(dest, len, "E");
		case 3: format(dest, len, "SE");
		case 4: format(dest, len, "S");
		case 5: format(dest, len, "SW");
		case 6: format(dest, len, "W");
		default: format(dest, len, "NW");
	}
	return 1;
}

static stock Float:GPS_ComputeScale(Float:baseSize, maxCharsFit, const text[])
{
	new l = strlen(text);
	if(l <= 0) return baseSize;
	new Float:scale = baseSize;
	if(l > maxCharsFit)
	{
		new Float:f = float(maxCharsFit) / float(l);
		scale = baseSize * f;
		if(scale < 0.08) scale = 0.08; 
	}
	return scale;
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

	playerhud_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 31.000, 309.000, "N");
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

	playerhud_PTD[playerid][4] = CreatePlayerTextDraw(playerid, 106.000, 310.000, "00:00");
	PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][4], 0.159, 0.898);
	PlayerTextDrawTextSize(playerid, playerhud_PTD[playerid][4], 0.000, 13.000);
	PlayerTextDrawAlignment(playerid, playerhud_PTD[playerid][4], TEXT_DRAW_ALIGN_CENTER);
	PlayerTextDrawColour(playerid, playerhud_PTD[playerid][4], -1);
	PlayerTextDrawSetShadow(playerid, playerhud_PTD[playerid][4], 1);
	PlayerTextDrawSetOutline(playerid, playerhud_PTD[playerid][4], 0);
	PlayerTextDrawBackgroundColour(playerid, playerhud_PTD[playerid][4], 150);
	PlayerTextDrawFont(playerid, playerhud_PTD[playerid][4], TEXT_DRAW_FONT_1);
	PlayerTextDrawSetProportional(playerid, playerhud_PTD[playerid][4], true);

	for(new i=0;i<5;i++) PlayerTextDrawShow(playerid, playerhud_PTD[playerid][i]);

	PlayerTextDrawShow(playerid, playerhud_PTD[playerid][0]);
	gps_last_city[playerid][0] = '\0';
	gps_last_street[playerid][0] = '\0';
	gps_last_dir[playerid][0] = '\0';
	gps_last_minute[playerid] = -1;
	gps_city_size[playerid] = 0.158;
	gps_street_size[playerid] = 0.158;
	gps_last_tick[playerid] = 0;
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
	new now = GetTickCount();
	if(now - gps_last_tick[playerid] < 250) return 1;
	gps_last_tick[playerid] = now;

	new string[128], Float:rz, Float:x, Float:y, Float:z, location[MAX_ZONE_NAME], location2[MAX_ZONE_NAME];

	GetPlayerPos(playerid, x, y, z);
	GetPlayer3DZone(playerid, location2, sizeof(location2));
	GetPlayerStreetZone(x, y, location, location2, sizeof(location));

	if(IsPlayerInAnyVehicle(playerid)) GetVehicleZAngle(GetPlayerVehicleID(playerid), rz);
	else GetPlayerFacingAngle(playerid, rz);

	new dir[4];
	GPS_GetDirStr(rz, dir, sizeof(dir));
	if(strcmp(dir, gps_last_dir[playerid], true) != 0)
	{
		PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][1], dir);
		strcpy(gps_last_dir[playerid], dir, sizeof(gps_last_dir[]));
	}

	if(strcmp(location2, gps_last_city[playerid], true) != 0)
	{
		new Float:sizeX = GPS_ComputeScale(0.158, 14, location2);
		if(sizeX != gps_city_size[playerid])
		{
			PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][2], sizeX, 0.898);
			gps_city_size[playerid] = sizeX;
		}
		PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][2], location2);
		strcpy(gps_last_city[playerid], location2, sizeof(gps_last_city[]));
	}

	if(strcmp(location, gps_last_street[playerid], true) != 0)
	{
		new Float:sizeX2 = GPS_ComputeScale(0.158, 18, location); 
		if(sizeX2 != gps_street_size[playerid])
		{
			PlayerTextDrawLetterSize(playerid, playerhud_PTD[playerid][3], sizeX2, 0.898);
			gps_street_size[playerid] = sizeX2;
		}
		PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][3], location);
		strcpy(gps_last_street[playerid], location, sizeof(gps_last_street[]));
	}

	new hour, minute, second;
	gettime(hour,minute,second);
	if(minute != gps_last_minute[playerid])
	{
		format(string, sizeof(string), "%02d:%02d", hour, minute);
		PlayerTextDrawSetString(playerid, playerhud_PTD[playerid][4], string);
		gps_last_minute[playerid] = minute;
	}
	return 1;
}