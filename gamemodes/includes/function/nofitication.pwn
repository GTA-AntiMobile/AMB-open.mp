#include <YSI\YSI_Coding\y_hooks>
#include <open.mp>

new PlayerText: Nofitication_PTD[MAX_PLAYERS][4];

new const WeatherZones[][] = {
    // Los Santos - Tọa độ chính xác
    {44, -2892, 2997, -768, "Los Santos", "Troi nang dep"},
    // San Fierro - Tọa độ chính xác  
    {-2997, -2892, -1213, -768, "San Fierro", "Troi u am, suong mu"},
    // Las Venturas - Tọa độ chính xác
    {869, 596, 2997, 2993, "Las Venturas", "Troi quang, gio nhe"},
    // Countryside - Tọa độ chính xác
    {-2997, -768, 2997, 2993, "Countryside", "Troi mua nhe"},
    // Desert - Tọa độ chính xác
    {869, -768, 2997, 596, "Sahara Desert", "Troi nang gay gat"},
    // Mountains - Tọa độ chính xác
    {-2997, 596, 869, 2993, "Mountains", "Troi lanh, tuyet roi"}
};

new PlayerWeatherData[MAX_PLAYERS][6]; // current_zone, last_zone, last_x, last_y, notification_active, last_check




hook OnGameModeInit() {
    InitializeWeatherSystem();
    return 1;
}

stock GetPlayerWeatherZone(playerid, zone_name[], weather_desc[]) {
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    for(new i = 0; i < sizeof(WeatherZones); i++) {
        if(x >= WeatherZones[i][0] && x <= WeatherZones[i][2] && 
           y >= WeatherZones[i][1] && y <= WeatherZones[i][3]) {
            
            format(zone_name, 32, WeatherZones[i][4]);
            format(weather_desc, 64, WeatherZones[i][5]);
            
            new hour, minute, second;
            gettime(hour, minute, second);
            
            if(hour >= 6 && hour <= 11) {
                format(weather_desc, 64, "Troi nang dep, mat me");
            } else if(hour >= 12 && hour <= 17) {
                format(weather_desc, 64, "Troi nang gay gat");
            } else if(hour >= 18 && hour <= 21) {
                format(weather_desc, 64, "Troi chieu mat");
            } else {
                format(weather_desc, 64, "Troi toi, lanh");
            }
            
            return 1;
        }
    }
    
    format(zone_name, 32, "Khu Vuc Khac");
    format(weather_desc, 64, "Thoi tiet on dinh");
    return 0;
}

stock UpdateWeatherNotification(playerid) {
    new zone_name[32], weather_desc[64];
    new notification_text[128];
    new hour, minute, second;
    
    gettime(hour, minute, second);
    
    if(GetPlayerWeatherZone(playerid, zone_name, weather_desc)) {
        format(notification_text, sizeof(notification_text), 
            "~y~Vi tri: ~w~%s\n~b~Thoi tiet: ~w~%s\nGio: ~w~%02d:%02d", 
            zone_name, weather_desc, hour, minute);
    } else {
        format(notification_text, sizeof(notification_text), 
            "~y~Vi tri: ~w~%s\n~b~Thoi tiet: ~w~%s\nGio: ~w~%02d:%02d", 
            zone_name, weather_desc, hour, minute);
    }
    
    PlayerTextDrawSetString(playerid, Nofitication_PTD[playerid][3], notification_text);
    return 1;
}

stock GetPlayerZoneID(playerid) {
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    for(new i = 0; i < sizeof(WeatherZones); i++) {
        if(x >= WeatherZones[i][0] && x <= WeatherZones[i][2] && 
           y >= WeatherZones[i][1] && y <= WeatherZones[i][3]) {
            return i;
        }
    }
    return -1;
}

stock ShowWeatherNotification(playerid) {
    UpdateWeatherNotification(playerid);
    
    for(new i = 0; i < 4; i++) {
        PlayerTextDrawShow(playerid, Nofitication_PTD[playerid][i]);
    }
    
    PlayerWeatherData[playerid][4] = 1; // notification_active = true
    
    SetTimerEx("HideWeatherNotification", 8000, false, "i", playerid);
    
    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
    
    return 1;
}

stock HideWeatherNotificationFunc(playerid) {
    for(new i = 0; i < 4; i++) {
        PlayerTextDrawHide(playerid, Nofitication_PTD[playerid][i]);
    }
    
    PlayerWeatherData[playerid][4] = 0; // notification_active = false
    return 1;
}

hook OnPlayerSpawn(playerid) {
    PlayerWeatherData[playerid][0] = -1; // current_zone
    PlayerWeatherData[playerid][1] = -1; // last_zone
    PlayerWeatherData[playerid][2] = 0; // last_x
    PlayerWeatherData[playerid][3] = 0; // last_y
    PlayerWeatherData[playerid][4] = 0; // notification_active
    PlayerWeatherData[playerid][5] = 0; // last_check
    
    SetTimerEx("ShowWeatherNotification", 3000, false, "i", playerid);
    return 1;
}

hook OnPlayerDeath(playerid, killerid, reason) {
    HideWeatherNotificationFunc(playerid);
    return 1;
}
forward HideWeatherNotification(playerid);
public HideWeatherNotification(playerid) {
    HideWeatherNotificationFunc(playerid);
    return 1;
}

stock CheckPlayerZoneChange(playerid) {
    new Float:current_x, Float:current_y, Float:current_z;
    GetPlayerPos(playerid, current_x, current_y, current_z);
    
    if(floatabs(current_x - float(PlayerWeatherData[playerid][2])) > 150.0 || 
       floatabs(current_y - float(PlayerWeatherData[playerid][3])) > 150.0) {
        
        new current_zone = GetPlayerZoneID(playerid);
        
        if(current_zone != PlayerWeatherData[playerid][0]) {
            PlayerWeatherData[playerid][1] = PlayerWeatherData[playerid][0]; // last_zone = current_zone
            PlayerWeatherData[playerid][0] = current_zone; // current_zone = new_zone
            
            ShowWeatherNotification(playerid);
        }
        
        PlayerWeatherData[playerid][2] = floatround(current_x); // last_x
        PlayerWeatherData[playerid][3] = floatround(current_y); // last_y
    }
    
    return 1;
}
forward CheckWeatherChanges();
public CheckWeatherChanges() {
    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(IsPlayerConnected(i)) {
            CheckPlayerZoneChange(i);
        }
    }
    return 1;
}

stock InitializeWeatherSystem() {
    SetTimer("CheckWeatherChanges", 10000, true);
    return 1;
}