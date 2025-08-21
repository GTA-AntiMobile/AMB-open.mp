#include <YSI\YSI_Coding\y_hooks>

enum e_VehicleMusic {
    vm_YoutubeID,           // ID của video Youtube đang phát
    vm_PlayingPlayerID,     // ID của player đã bật nhạc
    bool:vm_IsPlaying,      // Trạng thái đang phát nhạc
    vm_Title[128],          // Tên b� i hát
    vm_Duration,            // Thời lượng b� i hát
    vm_StartTime,           // Thời gian bắt đầu phát
    vm_VideoID[16],         // YouTube Video ID cho SAMP_WEB
    bool:vm_UsingSampWeb,   // Có đang dùng SAMP_WEB không
    vm_MP3URL[256],         // MP3 URL từ YouTube converter
    vm_StreamURL[256],      // Direct audio stream URL
    Float:vm_MusicX,        // Vị trí X nơi nhạc được bật
    Float:vm_MusicY,        // Vị trí Y nơi nhạc được bật  
    Float:vm_MusicZ,        // Vị trí Z nơi nhạc được bật
    vm_LastUpdateTime,      // Thời gian cập nhật cuối cùng
    bool:vm_IsMoving,       // Xe có đang di chuyển không
    Float:vm_LastPosX,      // Vị trí X cuối cùng của xe
    Float:vm_LastPosY,      // Vị trí Y cuối cùng của xe
    Float:vm_LastPosZ       // Vị trí Z cuối cùng của xe
}

new VehicleMusic[MAX_VEHICLES][e_VehicleMusic];

enum e_PlayerMusic {
    pm_VehicleID,           // ID xe đang nghe nhạc
    pm_StartTime,           // Thời gian bắt đầu nghe
    bool:pm_IsListening,    // Có đang nghe nhạc không
    Float:pm_LastDistance,  // Khoảng cách cuối cùng đến xe
    pm_StreamType           // Loại stream (0=positional, 1=global)
}

new PlayerMusic[MAX_PLAYERS][e_PlayerMusic];

stock ResetVehicleMusic(vehicleid) {
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return;
    
    VehicleMusic[vehicleid][vm_YoutubeID] = INVALID_YT_ID;
    VehicleMusic[vehicleid][vm_PlayingPlayerID] = INVALID_PLAYER_ID;
    VehicleMusic[vehicleid][vm_IsPlaying] = false;
    VehicleMusic[vehicleid][vm_Title][0] = 0;
    VehicleMusic[vehicleid][vm_Duration] = 0;
    VehicleMusic[vehicleid][vm_StartTime] = 0;
    VehicleMusic[vehicleid][vm_VideoID][0] = 0;
    VehicleMusic[vehicleid][vm_UsingSampWeb] = false;
    VehicleMusic[vehicleid][vm_MP3URL][0] = 0;
    VehicleMusic[vehicleid][vm_StreamURL][0] = 0;
    VehicleMusic[vehicleid][vm_MusicX] = 0.0;
    VehicleMusic[vehicleid][vm_MusicY] = 0.0;
    VehicleMusic[vehicleid][vm_MusicZ] = 0.0;
    VehicleMusic[vehicleid][vm_LastUpdateTime] = 0;
    VehicleMusic[vehicleid][vm_IsMoving] = false;
    VehicleMusic[vehicleid][vm_LastPosX] = 0.0;
    VehicleMusic[vehicleid][vm_LastPosY] = 0.0;
    VehicleMusic[vehicleid][vm_LastPosZ] = 0.0;
}

stock ResetPlayerMusic(playerid) {
    if(playerid < 0 || playerid >= MAX_PLAYERS) return;
    
    PlayerMusic[playerid][pm_VehicleID] = INVALID_VEHICLE_ID;
    PlayerMusic[playerid][pm_StartTime] = 0;
    PlayerMusic[playerid][pm_IsListening] = false;
    PlayerMusic[playerid][pm_LastDistance] = 0.0;
    PlayerMusic[playerid][pm_StreamType] = 0;
}

stock IsPlayerNearVehicle(playerid, vehicleid, Float:distance = 10.0) {
    if(!IsValidVehicle(vehicleid)) return 0;
    
    new Float:vx, Float:vy, Float:vz;
    new Float:px, Float:py, Float:pz;
    
    GetVehiclePos(vehicleid, vx, vy, vz);
    GetPlayerPos(playerid, px, py, pz);
    
    if(GetPlayerVirtualWorld(playerid) != GetVehicleVirtualWorld(vehicleid)) return 0;
    
    return (GetPlayerDistanceFromPoint(playerid, vx, vy, vz) <= distance);
}

stock CanPlayerStartHearingMusic(playerid, vehicleid) {
    if(!IsValidVehicle(vehicleid)) return 0;
    
    if(GetPlayerVehicleID(playerid) == vehicleid) return 1;
    
    new Float:px, Float:py, Float:pz, Float:vx, Float:vy, Float:vz;
    GetPlayerPos(playerid, px, py, pz);
    GetVehiclePos(vehicleid, vx, vy, vz);
    new Float:distance = floatsqroot(floatpower(px - vx, 2.0) + floatpower(py - vy, 2.0) + floatpower(pz - vz, 2.0));
    
    return (distance <= 10.0);
}

stock CanPlayerContinueHearingMusic(playerid, vehicleid) {
    if(!IsValidVehicle(vehicleid)) return 0;
    
    if(PlayerMusic[playerid][pm_VehicleID] == vehicleid) {
        new Float:px, Float:py, Float:pz, Float:vx, Float:vy, Float:vz;
        GetPlayerPos(playerid, px, py, pz);
        GetVehiclePos(vehicleid, vx, vy, vz);
        new Float:distance = floatsqroot(floatpower(px - vx, 2.0) + floatpower(py - vy, 2.0) + floatpower(pz - vz, 2.0));
        
        return (distance <= 10.0);
    }
    
    if(GetPlayerVehicleID(playerid) == vehicleid) return 1;
    
    return 0;
}

stock PlayMusicForPlayersNearVehicle(vehicleid) {
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    if(!VehicleMusic[vehicleid][vm_IsPlaying]) return 0;
    
    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(vehicleid, vx, vy, vz);
    VehicleMusic[vehicleid][vm_MusicX] = vx;
    VehicleMusic[vehicleid][vm_MusicY] = vy;
    VehicleMusic[vehicleid][vm_MusicZ] = vz;
    VehicleMusic[vehicleid][vm_LastPosX] = vx;
    VehicleMusic[vehicleid][vm_LastPosY] = vy;
    VehicleMusic[vehicleid][vm_LastPosZ] = vz;
    
    if(strlen(VehicleMusic[vehicleid][vm_MP3URL]) > 0) {
        new players_count = 0;
        foreach(new i: Player) {
            if(CanPlayerStartHearingMusic(i, vehicleid)) {
                PlayAudioStreamForPlayer(i, VehicleMusic[vehicleid][vm_MP3URL], vx, vy, vz, 10.0, true);
                
                PlayerMusic[i][pm_VehicleID] = vehicleid;
                PlayerMusic[i][pm_StartTime] = gettime();
                PlayerMusic[i][pm_IsListening] = true;
                PlayerMusic[i][pm_StreamType] = 0; // Positional
                PlayerMusic[i][pm_LastDistance] = GetPlayerDistanceFromPoint(i, vx, vy, vz);
                
                new string[128];
                format(string, sizeof(string), "🎵 Ban da bat dau nghe nhac tu xe %d", vehicleid);
                SendClientMessage(i, COLOR_GREEN, string);
                
                players_count++;
            }
        }
        return players_count;
    }
    
    if(strlen(VehicleMusic[vehicleid][vm_StreamURL]) > 0) {
        new players_count = 0;
        foreach(new i: Player) {
            if(CanPlayerStartHearingMusic(i, vehicleid)) {
                PlayAudioStreamForPlayer(i, VehicleMusic[vehicleid][vm_StreamURL], vx, vy, vz, 10.0, true);
                
                PlayerMusic[i][pm_VehicleID] = vehicleid;
                PlayerMusic[i][pm_StartTime] = gettime();
                PlayerMusic[i][pm_IsListening] = true;
                PlayerMusic[i][pm_StreamType] = 0; // Positional
                PlayerMusic[i][pm_LastDistance] = GetPlayerDistanceFromPoint(i, vx, vy, vz);
                
                new string[128];
                format(string, sizeof(string), "🎵 Ban da bat dau nghe nhac tu xe %d", vehicleid);
                SendClientMessage(i, COLOR_GREEN, string);
                
                players_count++;
            }
        }
        return players_count;
    }
    
    return 0;
}

stock StopMusicForPlayersNearVehicle(vehicleid) {
    new players_stopped = 0;
    foreach(new i: Player) {
        if(PlayerMusic[i][pm_VehicleID] == vehicleid) {
            StopAudioStreamForPlayer(i);
            ResetPlayerMusic(i);
            players_stopped++;
        }
    }
    return players_stopped;
}

stock ExtractYouTubeVideoID(url[], videoid[]) {
    videoid[0] = 0;
    
    if(strfind(url, "youtube.com/watch?v=", true) != -1) {
        new pos = strfind(url, "v=", true) + 2;
        new end_pos = strfind(url[pos], "&", true);
        if(end_pos == -1) end_pos = strlen(url) - pos;
        
        if(end_pos >= 11) { 
            for(new i = 0; i < 11 && i < end_pos; i++) {
                videoid[i] = url[pos + i];
            }
            videoid[11] = 0; 
            return 1;
        }
    }
    
    if(strfind(url, "youtu.be/", true) != -1) {
        new pos = strfind(url, "youtu.be/", true) + 9;
        new end_pos = strfind(url[pos], "?", true);
        if(end_pos == -1) end_pos = strlen(url) - pos;
        
        if(end_pos >= 11) {
            new actual_end = pos + 11;
            if(actual_end > strlen(url)) actual_end = strlen(url);
            strmid(videoid, url, pos, actual_end, 16);
            return 1;
        }
    }
    
    if(strlen(url) == 11) {
        format(videoid, 16, "%s", url);
        return 1;
    }
    
    return 0; 
}

stock PlayMusicViaSampWeb(vehicleid, const videoid[], const title[] = "") {
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    
    new weburl[512];
    new playername[MAX_PLAYER_NAME];
    GetPlayerName(VehicleMusic[vehicleid][vm_PlayingPlayerID], playername, sizeof(playername));
    
    new encoded_title[128];
    format(encoded_title, sizeof(encoded_title), "%s", title);
    for(new i = 0; i < strlen(encoded_title); i++) {
        if(encoded_title[i] == ' ') encoded_title[i] = '+';
    }
    
    format(weburl, sizeof(weburl), 
        "%s/youtube-web.php?action=play&video_id=%s&vehicle_id=%d&player_name=%s&title=%s",
        SAMP_WEB, videoid, vehicleid, playername, encoded_title);
    
    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(vehicleid, vx, vy, vz);
    
    new players_affected = 0;
    new info_msg[200];
    format(info_msg, sizeof(info_msg), "🎵 Vehicle Music: %s", (strlen(title) > 0) ? title : "YouTube Video");
    
    foreach(new i: Player) {
        if(IsPlayerNearVehicle(i, vehicleid, 15.0)) {
            SendClientMessage(i, COLOR_GREEN, info_msg);
            SendClientMessage(i, COLOR_YELLOW, "Mo browser va truy cap:");
            SendClientMessage(i, COLOR_WHITE, weburl);
            players_affected++;
        }
    }
    
    return players_affected;
}

stock StopMusicViaSampWeb(vehicleid) {
    if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return 0;
    
    foreach(new i: Player) {
        if(IsPlayerNearVehicle(i, vehicleid, 10.0)) {
            SendClientMessage(i, COLOR_YELLOW, "🛑 Vehicle music stopped. Ban co the dong tab browser.");
        }
    }
    
    return 1;
}

CMD:playmusic(playerid, params[]) {
    if(!IsPlayerInAnyVehicle(playerid)) {
        return SendClientMessage(playerid, COLOR_GRAD2, "Ban phai o trong xe de su dung lenh nay!");
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) {
        return SendClientMessage(playerid, COLOR_GRAD2, "Chi tai xe moi co the bat nhac!");
    }
    
    if(strlen(params) == 0) {
        SendClientMessage(playerid, COLOR_RED, "SU DUNG: /playmusic [YouTube URL]");
        return 1;
    }
    
    if(VehicleMusic[vehicleid][vm_IsPlaying]) {
        StopMusicForPlayersNearVehicle(vehicleid);
        if(VehicleMusic[vehicleid][vm_YoutubeID] != INVALID_YT_ID) {
            StopYoutubeVideo(VehicleMusic[vehicleid][vm_YoutubeID]);
        }
    }
    
    ResetVehicleMusic(vehicleid);
    
    if((strfind(params, ".mp3", true) != -1 || strfind(params, ".wav", true) != -1 || 
       strfind(params, ".ogg", true) != -1) && strfind(params, "youtube", true) == -1) {
        
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(vehicleid, vx, vy, vz);
        
        new players_count = 0;
        foreach(new i: Player) {
            if(IsPlayerConnected(i) && IsPlayerNearVehicle(i, vehicleid, 10.0)) {
                PlayAudioStreamForPlayer(i, params, vx, vy, vz, 10.0, true);
                
                PlayerMusic[i][pm_VehicleID] = vehicleid;
                PlayerMusic[i][pm_StartTime] = gettime();
                PlayerMusic[i][pm_IsListening] = true;
                PlayerMusic[i][pm_StreamType] = 0; // Positional
                PlayerMusic[i][pm_LastDistance] = GetPlayerDistanceFromPoint(i, vx, vy, vz);
                
                players_count++;
            }
        }
        
        VehicleMusic[vehicleid][vm_YoutubeID] = vehicleid; // Dùng vehicle ID l� m fake youtube ID
        VehicleMusic[vehicleid][vm_PlayingPlayerID] = playerid;
        VehicleMusic[vehicleid][vm_IsPlaying] = true;
        format(VehicleMusic[vehicleid][vm_StreamURL], 256, "%s", params);
        VehicleMusic[vehicleid][vm_StartTime] = gettime();
        format(VehicleMusic[vehicleid][vm_Title], 128, "Direct Audio Stream");
        VehicleMusic[vehicleid][vm_Duration] = 300; // 5 phút mặc định
        VehicleMusic[vehicleid][vm_MusicX] = vx;
        VehicleMusic[vehicleid][vm_MusicY] = vy;
        VehicleMusic[vehicleid][vm_MusicZ] = vz;
        VehicleMusic[vehicleid][vm_LastPosX] = vx;
        VehicleMusic[vehicleid][vm_LastPosY] = vy;
        VehicleMusic[vehicleid][vm_LastPosZ] = vz;
        
        new string[128];
        format(string, sizeof(string), "* %s bat nhac tu xe. (%d nguoi nghe)", GetPlayerNameEx(playerid), players_count);
        ProxDetector(10.0, playerid, string, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE);
        
        return 1;
    }
    
    new videoid[16];
    new extract_result = ExtractYouTubeVideoID(params, videoid);
    
    if(extract_result) {
        new request_url[256];
        format(request_url, sizeof(request_url), "%s/convert", MP3_CONVERTER_API);
        
        new post_data[256];
        format(post_data, sizeof(post_data), "{\"video_id\":\"%s\"}", videoid);
        
        VehicleMusic[vehicleid][vm_PlayingPlayerID] = playerid;
        VehicleMusic[vehicleid][vm_IsPlaying] = false; // Sẽ set true khi convert xong
        VehicleMusic[vehicleid][vm_StartTime] = gettime();
        VehicleMusic[vehicleid][vm_UsingSampWeb] = false;
        format(VehicleMusic[vehicleid][vm_VideoID], 16, "%s", videoid);
        format(VehicleMusic[vehicleid][vm_Title], 128, "Converting...");
        
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(vehicleid, vx, vy, vz);
        VehicleMusic[vehicleid][vm_MusicX] = vx;
        VehicleMusic[vehicleid][vm_MusicY] = vy;
        VehicleMusic[vehicleid][vm_MusicZ] = vz;
        VehicleMusic[vehicleid][vm_LastPosX] = vx;
        VehicleMusic[vehicleid][vm_LastPosY] = vy;
        VehicleMusic[vehicleid][vm_LastPosZ] = vz;
        
        HTTP(playerid, HTTP_POST, request_url, post_data, "OnYouTubeToMP3Response");
        
        SetPVarInt(playerid, "ConvertingForVehicle", vehicleid);
        
        return 1;
    }
    
    SendClientMessage(playerid, COLOR_RED, "Loi: URL YouTube khong hop le!");
    return 1;
}

CMD:stopmusic(playerid, params[]) {
    if(!IsPlayerInAnyVehicle(playerid)) {
        return SendClientMessage(playerid, COLOR_GRAD2, "Ban phai o trong xe de su dung lenh nay!");
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) {
        return SendClientMessage(playerid, COLOR_GRAD2, "Chi tai xe moi co the tat nhac!");
    }
    
    if(!VehicleMusic[vehicleid][vm_IsPlaying]) {
        return SendClientMessage(playerid, COLOR_GRAD2, "Khong co nhac nao dang phat!");
    }
    
    if(VehicleMusic[vehicleid][vm_UsingSampWeb]) {
        StopMusicViaSampWeb(vehicleid);
    } else {
        StopMusicForPlayersNearVehicle(vehicleid);
        
        if(VehicleMusic[vehicleid][vm_YoutubeID] != INVALID_YT_ID && VehicleMusic[vehicleid][vm_YoutubeID] != vehicleid) {
            StopYoutubeVideo(VehicleMusic[vehicleid][vm_YoutubeID]);
        }
    }
    
    ResetVehicleMusic(vehicleid);
    
    new string[128];
    format(string, sizeof(string), "* %s tat nhac tu xe.", GetPlayerNameEx(playerid));
    ProxDetector(10.0, playerid, string, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE);
    
    SendClientMessage(playerid, COLOR_GREEN, "Da tat nhac.");
    return 1;
}

stock Float:GetPlayerDistanceFromVehicle(playerid, vehicleid) {
    if(!IsValidVehicle(vehicleid)) return 999.0;
    
    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(vehicleid, vx, vy, vz);
    
    return GetPlayerDistanceFromPoint(playerid, vx, vy, vz);
}

hook OnYoutubeVideoStart(youtubeid) {
    for(new v = 1; v < MAX_VEHICLES; v++) {
        if(VehicleMusic[v][vm_YoutubeID] == youtubeid) {
            VehicleMusic[v][vm_IsPlaying] = true;
            VehicleMusic[v][vm_Duration] = GetVideoDuration(youtubeid);
            format(VehicleMusic[v][vm_Title], 128, "%s", GetVideoTitle(youtubeid));
            
            PlayMusicForPlayersNearVehicle(v);
            
            new playerid = VehicleMusic[v][vm_PlayingPlayerID];
            if(IsPlayerConnected(playerid)) {
                new string[180];
                format(string, sizeof(string), "Dang phat: %s (Thoi luong: %d giay)", VehicleMusic[v][vm_Title], VehicleMusic[v][vm_Duration]);
                SendClientMessage(playerid, COLOR_GREEN, string);
            }
            break;
        }
    }
    return 1;
}

hook OnYoutubeVideoFinished(youtubeid) {
    for(new v = 1; v < MAX_VEHICLES; v++) {
        if(VehicleMusic[v][vm_YoutubeID] == youtubeid) {
            StopMusicForPlayersNearVehicle(v);
            ResetVehicleMusic(v);
            break;
        }
    }
    return 1;
}

hook OnMVYoutubeError(youtubeid, const message[]) {
    for(new v = 1; v < MAX_VEHICLES; v++) {
        if(VehicleMusic[v][vm_YoutubeID] == youtubeid) {
            new playerid = VehicleMusic[v][vm_PlayingPlayerID];
            if(IsPlayerConnected(playerid)) {
                new string[220];
                
                if(strfind(message, "401", true) != -1 || strfind(message, "response code: 401", true) != -1) {
                    format(string, sizeof(string), "Loi: API Youtube khong hop le hoac het han. Vui long lien he admin.");
                }
                else if(strfind(message, "403", true) != -1) {
                    format(string, sizeof(string), "Loi: Video bi chan hoac rieng tu. Thu video khac.");
                }
                else if(strfind(message, "404", true) != -1) {
                    format(string, sizeof(string), "Loi: Khong tim thay video. Kiem tra lai URL.");
                }
                else if(strfind(message, "503", true) != -1 || strfind(message, "500", true) != -1) {
                    format(string, sizeof(string), "Loi: Server Youtube dang ban. Thu lai sau.");
                }
                else if(strfind(message, "DEPLOYMENT_NOT_FOUND", true) != -1) {
                    format(string, sizeof(string), "Loi: API converter khong kha dung. Admin can cap nhat CONVERTER_PATH.");
                }
                else if(strfind(message, "failed to parse response", true) != -1) {
                    format(string, sizeof(string), "Loi: API converter tra ve du lieu khong hop le.");
                }
                else {
                    format(string, sizeof(string), "Loi phat nhac: %s", message);
                }
                
                SendClientMessage(playerid, COLOR_RED, string);
            }
            ResetVehicleMusic(v);
            break;
        }
    }
    return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate) {
    if(oldstate == PLAYER_STATE_PASSENGER || oldstate == PLAYER_STATE_DRIVER) {
        new vehicleid = PlayerMusic[playerid][pm_VehicleID];
        if(vehicleid > 0 && VehicleMusic[vehicleid][vm_IsPlaying]) {
            SendClientMessage(playerid, COLOR_GREEN, "🎵 Ban van co the nghe nhac tu xe nay khi o gan!");
        }
    }
    
    if((newstate == PLAYER_STATE_PASSENGER || newstate == PLAYER_STATE_DRIVER)) {
        new vehicleid = GetPlayerVehicleID(playerid);
        if(VehicleMusic[vehicleid][vm_IsPlaying]) {
            if(PlayerMusic[playerid][pm_VehicleID] != vehicleid) {
                new Float:vx, Float:vy, Float:vz;
                GetVehiclePos(vehicleid, vx, vy, vz);
                
                new music_url[256];
                if(strlen(VehicleMusic[vehicleid][vm_MP3URL]) > 0) {
                    format(music_url, sizeof(music_url), "%s", VehicleMusic[vehicleid][vm_MP3URL]);
                } else {
                    format(music_url, sizeof(music_url), "%s", VehicleMusic[vehicleid][vm_StreamURL]);
                }
                
                PlayAudioStreamForPlayer(playerid, music_url, vx, vy, vz, 10.0, true);
                
                PlayerMusic[playerid][pm_VehicleID] = vehicleid;
                PlayerMusic[playerid][pm_StartTime] = gettime();
                PlayerMusic[playerid][pm_IsListening] = true;
                PlayerMusic[playerid][pm_StreamType] = 0; // Positional
                PlayerMusic[playerid][pm_LastDistance] = GetPlayerDistanceFromPoint(playerid, vx, vy, vz);
                
                SendClientMessage(playerid, COLOR_GREEN, "🎵 Ban da bat dau nghe nhac tu xe nay!");
            }
        }
    }
    
    return 1;
}

forward VehicleMusicUpdate();
public VehicleMusicUpdate() {
    for(new v = 1; v < MAX_VEHICLES; v++) {
        if(!VehicleMusic[v][vm_IsPlaying]) continue;
        
        if(strlen(VehicleMusic[v][vm_MP3URL]) == 0 && strlen(VehicleMusic[v][vm_StreamURL]) == 0) {
            continue;
        }
        
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(v, vx, vy, vz);
        
        VehicleMusic[v][vm_MusicX] = vx;
        VehicleMusic[v][vm_MusicY] = vy;
        VehicleMusic[v][vm_MusicZ] = vz;
        
        if(strlen(VehicleMusic[v][vm_StreamURL]) > 0 || strlen(VehicleMusic[v][vm_MP3URL]) > 0) {
            new music_url[256];
            if(strlen(VehicleMusic[v][vm_MP3URL]) > 0) {
                format(music_url, sizeof(music_url), "%s", VehicleMusic[v][vm_MP3URL]);
            } else {
                format(music_url, sizeof(music_url), "%s", VehicleMusic[v][vm_StreamURL]);
            }
            
            foreach(new i: Player) {
                new bool:wasHearing = (PlayerMusic[i][pm_VehicleID] == v);
                new bool:canStartHearing = CanPlayerStartHearingMusic(i, v);
                new bool:canContinueHearing = CanPlayerContinueHearingMusic(i, v);
                
                if(canStartHearing && !wasHearing) {
                    PlayAudioStreamForPlayer(i, music_url, vx, vy, vz, 30.0, true);
                    
                    PlayerMusic[i][pm_VehicleID] = v;
                    PlayerMusic[i][pm_StartTime] = gettime();
                    PlayerMusic[i][pm_IsListening] = true;
                    PlayerMusic[i][pm_StreamType] = 0; // Positional
                    PlayerMusic[i][pm_LastDistance] = GetPlayerDistanceFromPoint(i, vx, vy, vz);
                    
                    new string[128];
                    format(string, sizeof(string), "🎵 Ban da bat dau nghe nhac tu xe %d", v);
                    SendClientMessage(i, COLOR_GREEN, string);
                }
                else if(wasHearing && !canContinueHearing) {
                    StopAudioStreamForPlayer(i);
                    ResetPlayerMusic(i);
                    
                    SendClientMessage(i, COLOR_YELLOW, "Ban da ra khoi vung nghe nhac (10m)");
                }
                else if(wasHearing && canContinueHearing) {
                    new Float:px, Float:py, Float:pz;
                    GetPlayerPos(i, px, py, pz);
                    new Float:currentDistance = floatsqroot(floatpower(px - vx, 2.0) + floatpower(py - vy, 2.0) + floatpower(pz - vz, 2.0));
                    
                    new Float:lastDistance = PlayerMusic[i][pm_LastDistance];
                    new Float:distanceChange = floatsqroot(floatpower(currentDistance - lastDistance, 2.0));
                    
                    if(distanceChange > 5.0) {
                        PlayAudioStreamForPlayer(i, music_url, vx, vy, vz, 10.0, true);
                    }
                    
                    PlayerMusic[i][pm_LastDistance] = currentDistance;
                }
            }
        }
    }
    return 1;
}

hook OnGameModeInit() {
    for(new v = 1; v < MAX_VEHICLES; v++) {
        ResetVehicleMusic(v);
    }
    
    for(new p = 0; p < MAX_PLAYERS; p++) {
        ResetPlayerMusic(p);
    }
    
    SetTimer("VehicleMusicUpdate", 3000, true);
    
    return 1;
}

hook OnVehicleSpawn(vehicleid) {
    ResetVehicleMusic(vehicleid);
    return 1;
}



forward OnYouTubeToMP3Response(playerid, response_code, data[]);
public OnYouTubeToMP3Response(playerid, response_code, data[]) {
    new vehicleid = GetPVarInt(playerid, "ConvertingForVehicle");
    DeletePVar(playerid, "ConvertingForVehicle");
    
    if(response_code != 200) {
        SendClientMessage(playerid, COLOR_RED, "Loi: Khong the ket noi den MP3 converter!");
        ResetVehicleMusic(vehicleid);
        return 1;
    }
    
    if(strfind(data, "\"success\":true", true) == -1) {
        SendClientMessage(playerid, COLOR_RED, "Loi: Khong the convert video nay thanh MP3!");
        ResetVehicleMusic(vehicleid);
        return 1;
    }
    
    new mp3_url[256];
    new url_start = strfind(data, "\"mp3_url\":\"", true);
    if(url_start == -1) {
        SendClientMessage(playerid, COLOR_RED, "Loi: Khong tim thay MP3 URL trong response!");
        ResetVehicleMusic(vehicleid);
        return 1;
    }
    
    new start_pos = url_start + 11; // Length of "\"mp3_url\":\""
    new end_pos = strfind(data[start_pos], "\"", true);
    if(end_pos == -1) {
        SendClientMessage(playerid, COLOR_RED, "Loi: MP3 URL format khong hop le!");
        ResetVehicleMusic(vehicleid);
        return 1;
    }
    
    strmid(mp3_url, data, start_pos, start_pos + end_pos, sizeof(mp3_url));
    
    new title[128] = "YouTube Music";
    new title_start = strfind(data, "\"title\":\"", true);
    if(title_start != -1) {
        new title_start_pos = title_start + 9; // Length of "\"title\":\""
        new title_end_pos = strfind(data[title_start_pos], "\"", true);
        if(title_end_pos != -1 && title_end_pos < 120) {
            strmid(title, data, title_start_pos, title_start_pos + title_end_pos, sizeof(title));
        }
    }
    
    VehicleMusic[vehicleid][vm_IsPlaying] = true;
    format(VehicleMusic[vehicleid][vm_Title], 128, "%s", title);
    format(VehicleMusic[vehicleid][vm_MP3URL], 256, "%s", mp3_url);
    VehicleMusic[vehicleid][vm_Duration] = 300; // Default 5 minutes
    
    new players_count = PlayMusicForPlayersNearVehicle(vehicleid);
    
    new string[128];
    format(string, sizeof(string), "* %s bat nhac: %s (%d nguoi nghe)", GetPlayerNameEx(playerid), title, players_count);
    ProxDetector(30.0, playerid, string, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE, COLOR_PURPLE);
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason) {
    ResetPlayerMusic(playerid);
    DeletePVar(playerid, "ConvertingForVehicle");
    return 1;
}

hook OnVehicleUpdate(vehicleid) {
    if(VehicleMusic[vehicleid][vm_IsPlaying]) {
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(vehicleid, vx, vy, vz);
        
        VehicleMusic[vehicleid][vm_MusicX] = vx;
        VehicleMusic[vehicleid][vm_MusicY] = vy;
        VehicleMusic[vehicleid][vm_MusicZ] = vz;
    }
    return 1;
}

hook OnPlayerUpdate(playerid) {
    if(PlayerMusic[playerid][pm_IsListening]) {
        new vehicleid = PlayerMusic[playerid][pm_VehicleID];
        if(VehicleMusic[vehicleid][vm_IsPlaying]) {
            new Float:vx, Float:vy, Float:vz;
            GetVehiclePos(vehicleid, vx, vy, vz);
            
            VehicleMusic[vehicleid][vm_MusicX] = vx;
            VehicleMusic[vehicleid][vm_MusicY] = vy;
            VehicleMusic[vehicleid][vm_MusicZ] = vz;
        }
    }
    return 1;
}

