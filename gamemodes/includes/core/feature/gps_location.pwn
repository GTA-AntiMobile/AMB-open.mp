#include <YSI/YSI_Coding/y_hooks>

new PlayerText:gps_HUD[MAX_PLAYERS][5];
new gps_LastCity[MAX_PLAYERS][MAX_ZONE_NAME];
new gps_LastStreet[MAX_PLAYERS][MAX_ZONE_NAME];
new gps_LastDirection[MAX_PLAYERS][4];
new gps_LastMinute[MAX_PLAYERS];
new Float:gps_CityScale[MAX_PLAYERS];
new Float:gps_StreetScale[MAX_PLAYERS];
new gps_LastUpdate[MAX_PLAYERS];

static const DIRECTION_NAMES[][] = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};

static stock GPS_GetDirectionString(Float:angle, dest[], len)
{
    while(angle < 0.0) angle += 360.0;
    while(angle >= 360.0) angle -= 360.0;
    
    new idx = floatround((angle + 22.5) / 45.0, floatround_floor) % 8;
    return format(dest, len, "%s", DIRECTION_NAMES[idx]);
}

static stock Float:GPS_CalculateScale(Float:baseSize, maxChars, const text[])
{
    new length = strlen(text);
    if(length <= 0) return baseSize;
    
    if(length > maxChars)
    {
        new Float:scale = baseSize * (float(maxChars) / float(length));
        return (scale < 0.08) ? 0.08 : scale;
    }
    
    return baseSize;
}

static stock GPS_TruncateText(dest[], const source[], maxLen)
{
    if(strlen(source) <= maxLen)
    {
        strcpy(dest, source, maxLen);
        return;
    }
    
    strcpy(dest, source, maxLen - 2);
    strcat(dest, "..", maxLen);
}

stock GPS_CreateHUD(playerid)
{
    gps_HUD[playerid][0] = CreatePlayerTextDraw(playerid, 21.0, 303.0, "mdl-2003:Main");
    PlayerTextDrawTextSize(playerid, gps_HUD[playerid][0], 97.0, 23.0);
    PlayerTextDrawAlignment(playerid, gps_HUD[playerid][0], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, gps_HUD[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, gps_HUD[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, gps_HUD[playerid][0], 0);
    PlayerTextDrawBackgroundColour(playerid, gps_HUD[playerid][0], 255);
    PlayerTextDrawFont(playerid, gps_HUD[playerid][0], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, gps_HUD[playerid][0], true);

    gps_HUD[playerid][1] = CreatePlayerTextDraw(playerid, 31.0, 309.0, "N");
    PlayerTextDrawLetterSize(playerid, gps_HUD[playerid][1], 0.230, 0.999);
    PlayerTextDrawTextSize(playerid, gps_HUD[playerid][1], 0.0, 12.0);
    PlayerTextDrawAlignment(playerid, gps_HUD[playerid][1], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, gps_HUD[playerid][1], -1);
    PlayerTextDrawSetShadow(playerid, gps_HUD[playerid][1], 1);
    PlayerTextDrawSetOutline(playerid, gps_HUD[playerid][1], 0);
    PlayerTextDrawBackgroundColour(playerid, gps_HUD[playerid][1], 150);
    PlayerTextDrawFont(playerid, gps_HUD[playerid][1], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, gps_HUD[playerid][1], true);

    gps_HUD[playerid][2] = CreatePlayerTextDraw(playerid, 43.0, 306.0, "San Andreas");
    PlayerTextDrawLetterSize(playerid, gps_HUD[playerid][2], 0.158, 0.898);
    PlayerTextDrawTextSize(playerid, gps_HUD[playerid][2], 96.0, 58.0);
    PlayerTextDrawAlignment(playerid, gps_HUD[playerid][2], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, gps_HUD[playerid][2], -1);
    PlayerTextDrawSetShadow(playerid, gps_HUD[playerid][2], 1);
    PlayerTextDrawSetOutline(playerid, gps_HUD[playerid][2], 0);
    PlayerTextDrawBackgroundColour(playerid, gps_HUD[playerid][2], 150);
    PlayerTextDrawFont(playerid, gps_HUD[playerid][2], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, gps_HUD[playerid][2], true);

    gps_HUD[playerid][3] = CreatePlayerTextDraw(playerid, 49.0, 312.0, "Grove Street");
    PlayerTextDrawLetterSize(playerid, gps_HUD[playerid][3], 0.158, 0.898);
    PlayerTextDrawTextSize(playerid, gps_HUD[playerid][3], 126.0, 54.0);
    PlayerTextDrawAlignment(playerid, gps_HUD[playerid][3], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, gps_HUD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, gps_HUD[playerid][3], 1);
    PlayerTextDrawSetOutline(playerid, gps_HUD[playerid][3], 0);
    PlayerTextDrawBackgroundColour(playerid, gps_HUD[playerid][3], 150);
    PlayerTextDrawFont(playerid, gps_HUD[playerid][3], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, gps_HUD[playerid][3], true);

    gps_HUD[playerid][4] = CreatePlayerTextDraw(playerid, 106.0, 310.0, "00:00");
    PlayerTextDrawLetterSize(playerid, gps_HUD[playerid][4], 0.159, 0.898);
    PlayerTextDrawTextSize(playerid, gps_HUD[playerid][4], 0.0, 13.0);
    PlayerTextDrawAlignment(playerid, gps_HUD[playerid][4], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, gps_HUD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, gps_HUD[playerid][4], 1);
    PlayerTextDrawSetOutline(playerid, gps_HUD[playerid][4], 0);
    PlayerTextDrawBackgroundColour(playerid, gps_HUD[playerid][4], 150);
    PlayerTextDrawFont(playerid, gps_HUD[playerid][4], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, gps_HUD[playerid][4], true);

    for(new i = 0; i < 5; i++)
    {
        PlayerTextDrawShow(playerid, gps_HUD[playerid][i]);
    }

    gps_LastCity[playerid][0] = '\0';
    gps_LastStreet[playerid][0] = '\0';
    gps_LastDirection[playerid][0] = '\0';
    gps_LastMinute[playerid] = -1;
    gps_CityScale[playerid] = 0.158;
    gps_StreetScale[playerid] = 0.158;
    gps_LastUpdate[playerid] = 0;
    
    return 1;
}

stock GPS_HideHUD(playerid)
{
    for(new i = 0; i < 5; i++)
    {
        PlayerTextDrawHide(playerid, gps_HUD[playerid][i]);
    }
    return 1;
}

stock GPS_UpdateHUD(playerid)
{
    new currentTick = GetTickCount();
    if(currentTick - gps_LastUpdate[playerid] < 250) return 1;
    gps_LastUpdate[playerid] = currentTick;

    new Float:x, Float:y, Float:z, Float:angle;
    new city[MAX_ZONE_NAME], street[MAX_ZONE_NAME];
    new direction[4], timeString[8];
    new truncatedCity[16], truncatedStreet[20];
    
    GetPlayerPos(playerid, x, y, z);
    GetPlayer3DZone(playerid, city, sizeof(city));
    GetPlayerStreetZone(x, y, street, city, sizeof(street));
    
    if(IsPlayerInAnyVehicle(playerid))
    {
        GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
    }
    else
    {
        GetPlayerFacingAngle(playerid, angle);
    }
    
    GPS_GetDirectionString(angle, direction, sizeof(direction));
    if(strcmp(direction, gps_LastDirection[playerid], true) != 0)
    {
        PlayerTextDrawSetString(playerid, gps_HUD[playerid][1], direction);
        strcpy(gps_LastDirection[playerid], direction, sizeof(gps_LastDirection[]));
    }

    GPS_TruncateText(truncatedCity, city, 15);
    if(strcmp(truncatedCity, gps_LastCity[playerid], true) != 0)
    {
        new Float:newScale = GPS_CalculateScale(0.158, 12, truncatedCity);
        if(newScale != gps_CityScale[playerid])
        {
            PlayerTextDrawLetterSize(playerid, gps_HUD[playerid][2], newScale, 0.898);
            gps_CityScale[playerid] = newScale;
        }
        PlayerTextDrawSetString(playerid, gps_HUD[playerid][2], truncatedCity);
        strcpy(gps_LastCity[playerid], truncatedCity, sizeof(gps_LastCity[]));
    }

    GPS_TruncateText(truncatedStreet, street, 19);
    if(strcmp(truncatedStreet, gps_LastStreet[playerid], true) != 0)
    {
        new Float:newScale = GPS_CalculateScale(0.158, 16, truncatedStreet);
        if(newScale != gps_StreetScale[playerid])
        {
            PlayerTextDrawLetterSize(playerid, gps_HUD[playerid][3], newScale, 0.898);
            gps_StreetScale[playerid] = newScale;
        }
        PlayerTextDrawSetString(playerid, gps_HUD[playerid][3], truncatedStreet);
        strcpy(gps_LastStreet[playerid], truncatedStreet, sizeof(gps_LastStreet[]));
    }

    new hour, minute, second;
    gettime(hour, minute, second);
    if(minute != gps_LastMinute[playerid])
    {
        format(timeString, sizeof(timeString), "%02d:%02d", hour, minute);
        PlayerTextDrawSetString(playerid, gps_HUD[playerid][4], timeString);
        gps_LastMinute[playerid] = minute;
    }
    
    return 1;
}

hook OnPlayerConnect(playerid)
{
    GPS_CreateHUD(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid)
{
    GPS_HideHUD(playerid);
    return 1;
}

hook OnPlayerUpdate(playerid)
{
    if(gPlayerLogged{playerid} == 1)
    {
        GPS_UpdateHUD(playerid);
    }
    return 1;
}