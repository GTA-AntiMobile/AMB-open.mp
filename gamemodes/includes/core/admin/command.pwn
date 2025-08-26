#include <YSI\YSI_Coding\y_hooks>

CMD:adminlist(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 99999) return SendClientMessage(playerid, COLOR_GREY,"Ban khong the su dung lenh nay."); 
	
	new query[256];
	format(query, sizeof(query), "SELECT Username, AdminLevel FROM accounts WHERE AdminLevel >= 1 ORDER BY AdminLevel DESC");
	mysql_function_query(MainPipeline, query, true, "OnAdminListLoad", "i", playerid);
	return 1;
}

forward OnAdminListLoad(playerid, extraid);
public OnAdminListLoad(playerid, extraid)
{
	new string[2048], count = 0;
	format(string, sizeof(string), "STT\tAdmin Level\tTen\tTrang thai\n");
	
	new rows = cache_num_rows();
	if(rows > 0)
	{
		new username[MAX_PLAYER_NAME], adminlevel, adminRank[323], status[166];
		
		for(new i = 0; i < rows; i++)
		{
			cache_get_value_name(i, "Username", username, MAX_PLAYER_NAME);
			cache_get_value_name_int(i, "AdminLevel", adminlevel);
			
			// Kiểm tra admin có online không
			new isOnline = 0;
			foreach(new j: Player)
			{
				if(IsPlayerConnected(j) && PlayerInfo[j][pAdmin] >= 1)
				{
					new playerName[MAX_PLAYER_NAME];
					GetPlayerName(j, playerName, sizeof(playerName));
					if(strcmp(playerName, username, true) == 0)
					{
						isOnline = 1;
						break;
					}
				}
			}
			
			switch(adminlevel)
			{
				case 1: format(adminRank, sizeof(adminRank), "Server Moderator");
				case 2: format(adminRank, sizeof(adminRank), "{00FF00}Junior Administrator{FFFFFF}");
				case 3: format(adminRank, sizeof(adminRank), "{00FF00}General Administrator{FFFFFF}");
				case 4: format(adminRank, sizeof(adminRank), "{F4A460}Senior Administrator{FFFFFF}");
				case 1337: format(adminRank, sizeof(adminRank), "{FF0000}Head Administrator{FFFFFF}");
				case 1338: format(adminRank, sizeof(adminRank), "{298EFF}Lead Head Administrator{FFFFFF}");
				case 99999: format(adminRank, sizeof(adminRank), "{298EFF}Executive Administrator{FFFFFF}");
				default: format(adminRank, sizeof(adminRank), "Undefined Administrator %d", adminlevel);
			}
			
			if(isOnline)
			{
				format(status, sizeof(status), "{00FF00}Online{FFFFFF}");
			}
			else
			{
				format(status, sizeof(status), "{FF0000}Offline{FFFFFF}");
			}
			
			count++;
			format(string, sizeof(string), "%s%d\t%s\t%s\t%s\n", 
				string, count, adminRank, username, status);
		}
	}
	
	if(count == 0)
	{
		format(string, sizeof(string), "Khong co Admin nao trong he thong!");
	}
	
	ShowPlayerDialog(playerid, DIALOG_ADMIN_LIST, DIALOG_STYLE_TABLIST_HEADERS, "> Danh sach Admin | AMB Administrator", string, "Dong", "");
	return 1;
}