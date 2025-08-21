#include <YSI\YSI_Coding\y_hooks>
CMD:family(playerid, params[])
{
	if(PlayerInfo[playerid][pFMember] == INVALID_FAMILY_ID)
		return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong o trong family."), 1;
	if(PlayerInfo[playerid][pRank] < 5)
		return SendClientMessageEx(playerid, COLOR_GRAD1, "Chi rank cao (5+) moi su dung he thong quan ly family."), 1;

	new fam = PlayerInfo[playerid][pFMember], info[640], title[64];
	format(title, sizeof(title), "{00BFFF}Quan ly Family{FFFFFF}: {FFDE85}%s", FamilyInfo[fam][FamilyName]);

	format(info, sizeof(info),
		"{9E9E9E}[Thong tin]{FFFFFF} Tong quan\n{9E9E9E}[He thong]{FFFFFF} Doi ten Family\n{9E9E9E}[Safe]{FFFFFF} Xem so du\n{9E9E9E}[Safe]{FFFFFF} Nap tien\n{9E9E9E}[Safe]{FFFFFF} Rut tien\n{9E9E9E}[Thanh vien]{FFFFFF} Moi thanh vien\n{9E9E9E}[Thanh vien]{FFFFFF} Kick thanh vien\n{9E9E9E}[Thanh vien]{FFFFFF} Danh sach thanh vien\n{9E9E9E}[Vi tri]{FFFFFF} Dat Glocker/Safe\n{9E9E9E}[He thong]{FFFFFF} Nang cap Family");

	Dialog_Show(playerid, FamilyMain, DIALOG_STYLE_LIST, title, info, "Chon", "Huy");
	return 1;
}

Dialog:FamilyMain(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	new fam = PlayerInfo[playerid][pFMember];
	if(fam == INVALID_FAMILY_ID) return 1;

	switch(listitem)
	{
		case 0: // Thong tin (overview)
		{
			new msg[768], tmp[128];
			strcat(msg, "{00BFFF}==============================\n");
			strcat(msg, "{00BFFF}       TONG QUAN FAMILY\n");
			strcat(msg, "{00BFFF}=============================={FFFFFF}\n");
			format(tmp, sizeof(tmp), "{00BFFF}Ten:{BFC0C2} %s\n", FamilyInfo[fam][FamilyName]); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}ID:{BFC0C2} %d\n", fam); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}Leader:{BFC0C2} %s\n", FamilyInfo[fam][FamilyLeader]); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}Thanh vien:{BFC0C2} %d / %d\n", FamilyInfo[fam][FamilyMembers], (FamilyInfo[fam][FamilyMaxMembers] > 0 ? FamilyInfo[fam][FamilyMaxMembers] : 10)); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}Cap family:{BFC0C2} %d / 5\n", (FamilyInfo[fam][FamilyLevel] > 0 ? FamilyInfo[fam][FamilyLevel] : 1)); strcat(msg, tmp);
			strcat(msg, "\n{00BFFF}--- Tai nguyen ---{FFFFFF}\n");
			format(tmp, sizeof(tmp), "{00BFFF}Tien:{BFC0C2} $%s\n", number_format(FamilyInfo[fam][FamilyCash])); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}Pot:{BFC0C2} %d    {00BFFF}Crack:{BFC0C2} %d\n", FamilyInfo[fam][FamilyPot], FamilyInfo[fam][FamilyCrack]); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}Vat lieu:{BFC0C2} %d    {00BFFF}Heroin:{BFC0C2} %d\n", FamilyInfo[fam][FamilyMats], FamilyInfo[fam][FamilyHeroin]); strcat(msg, tmp);
			format(tmp, sizeof(tmp), "{00BFFF}Turf Tokens:{BFC0C2} %d\n", FamilyInfo[fam][FamilyTurfTokens]); strcat(msg, tmp);
			Dialog_Show(playerid, FamilyInfoDone, DIALOG_STYLE_MSGBOX, "{00BFFF}Thong tin Family", msg, "Dong", "");
		}
		case 1: Dialog_Show(playerid, FamilyRenameDlg, DIALOG_STYLE_INPUT, "{00BFFF}Doi ten Family", "{9E9E9E}Nhap ten moi cho Family:", "Luu", "Huy");
		case 2: // Safe balance
		{
			new msg[384];
			strcat(msg, "{00BFFF}==============================\n");
			strcat(msg, "{00BFFF}           SAFE FAMILY\n");
			strcat(msg, "{00BFFF}=============================={FFFFFF}\n");
			format(msg, sizeof(msg), "%s{00BFFF}So du:{BFC0C2} $%s\n", msg, number_format(FamilyInfo[fam][FamilyCash]));
			format(msg, sizeof(msg), "%s{00BFFF}Pot:{BFC0C2} %d   {00BFFF}Crack:{BFC0C2} %d\n", msg, FamilyInfo[fam][FamilyPot], FamilyInfo[fam][FamilyCrack]);
			format(msg, sizeof(msg), "%s{00BFFF}Vat lieu:{BFC0C2} %d   {00BFFF}Heroin:{BFC0C2} %d\n", msg, FamilyInfo[fam][FamilyMats], FamilyInfo[fam][FamilyHeroin]);
			Dialog_Show(playerid, FamilyInfoDone, DIALOG_STYLE_MSGBOX, "{00BFFF}Safe Family", msg, "Dong", "");
		}
		case 3: Dialog_Show(playerid, FamilyDepositDlg, DIALOG_STYLE_INPUT, "{00BFFF}Nap tien vao Family Safe", "{9E9E9E}Nhap so tien:", "Nap", "Huy");
		case 4: Dialog_Show(playerid, FamilyWithdrawDlg, DIALOG_STYLE_INPUT, "{00BFFF}Rut tien tu Family Safe", "{9E9E9E}Nhap so tien:", "Rut", "Huy");
		case 5: Dialog_Show(playerid, FamilyInviteDlg, DIALOG_STYLE_INPUT, "{00BFFF}Moi thanh vien", "{9E9E9E}Nhap ten nguoi choi hoac ID:", "Moi", "Huy");
		case 6: Dialog_Show(playerid, FamilyKickDlg, DIALOG_STYLE_INPUT, "{00BFFF}Kick thanh vien", "{9E9E9E}Nhap ten nguoi choi hoac ID:", "Kick", "Huy");
		case 7:
		{
			new query[160];
			format(query, sizeof(query), "SELECT Username, Rank FROM `accounts` WHERE `FMember` = %d ORDER BY Username", fam);
			mysql_pquery(MainPipeline, query, "Family_OnMembersList", "i", playerid);
		}
		case 8: Dialog_Show(playerid, FamilyMoveGlockerConfirm, DIALOG_STYLE_MSGBOX, "{00BFFF}Di chuyen Glocker/Safe", "{9E9E9E}Ban co chac muon dat lai vi tri Glocker/Safe tai vi tri hien tai?", "Xac nhan", "Huy");
		case 9: Dialog_Show(playerid, FamilyUpgradeDlg, DIALOG_STYLE_MSGBOX, "{00BFFF}Nang cap Family", "{9E9E9E}Mo rong slot thanh vien (them 10 slot moi cap).\n{BFC0C2}Chi leader (rank 5+) duoc phep nang cap.", "Nang cap", "Huy");
	}
	return 1;
}
forward Family_OnMembersList(playerid);
public Family_OnMembersList(playerid)
{
	new rows, fields; cache_get_data(rows, fields);
	new fam = PlayerInfo[playerid][pFMember];
	new msg[4096]; msg[0] = '\0';
	strcat(msg, "{00BFFF}==============================\n");
	strcat(msg, "{00BFFF}       DANH SACH THANH VIEN\n");
	strcat(msg, "{00BFFF}=============================={FFFFFF}\n");
	strcat(msg, "{9E9E9E}Ten{FFFFFF} - {9E9E9E}Rank{FFFFFF} - {9E9E9E}Trang thai{FFFFFF}\n");
	new name[MAX_PLAYER_NAME+1], rankStr[8];
	for(new r=0; r<rows && r<300; r++)
	{
		cache_get_value_name(r, "Username", name, MAX_PLAYER_NAME);
		cache_get_value_name(r, "Rank", rankStr, sizeof(rankStr));
		new irank = strval(rankStr);
		new rankName[32];
		if(0 <= irank < MAX_GROUP_RANKS && FamilyRankInfo[fam][irank][0])
			format(rankName, sizeof(rankName), "%s", FamilyRankInfo[fam][irank]);
		else
			format(rankName, sizeof(rankName), "%d", irank);
		new bool:isOnline = false;
		foreach(new i: Player)
		{
			if(strcmp(GetPlayerNameExt(i), name, true) == 0) { isOnline = true; break; }
		}
		if(isOnline)
			format(msg, sizeof(msg), "%s{BFC0C2}%s{FFFFFF} - {BFC0C2}%s{FFFFFF} - {00FF00}ONLINE{FFFFFF}\n", msg, name, rankName);
		else
			format(msg, sizeof(msg), "%s{BFC0C2}%s{FFFFFF} - {BFC0C2}%s{FFFFFF} - {FF0000}OFFLINE{FFFFFF}\n", msg, name, rankName);
	}
	if(rows == 0) strcat(msg, "{9E9E9E}Chua co thanh vien nao trong family nay.\n");
	Dialog_Show(playerid, FamilyInfoDone, DIALOG_STYLE_MSGBOX, "{00BFFF}Danh sach thanh vien", msg, "Dong", "");
	return 1;
}

Dialog:FamilyInfoDone(playerid, response, listitem, inputtext[])
{
	return 1;
}

Dialog:FamilyRenameDlg(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(PlayerInfo[playerid][pRank] < 5) return SendClientMessageEx(playerid, COLOR_GRAD1, "Chi leader (rank 5+) moi doi ten."), 1;
	new fam = PlayerInfo[playerid][pFMember];
	if(fam == INVALID_FAMILY_ID) return 1;
	if(isnull(inputtext)) return SendClientMessageEx(playerid, COLOR_GREY, "Ten khong hop le."), 1;
	new len = strlen(inputtext);
	if(!(2 <= len <= 32)) return SendClientMessageEx(playerid, COLOR_GREY, "Do dai ten phai tu 2-32 ky tu."), 1;
	format(FamilyInfo[fam][FamilyName], 42, "%s", inputtext);
	SaveFamily(fam);
	SendClientMessageEx(playerid, COLOR_WHITE, "Da doi ten Family thanh cong.");
	return 1;
}

Dialog:FamilyDepositDlg(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	new amount; if(sscanf(inputtext, "d", amount) || amount <= 0) return SendClientMessageEx(playerid, COLOR_GREY, "So tien khong hop le."), 1;
	new cmd[48]; format(cmd, sizeof(cmd), "%s %d", "/safedeposit", amount);
	return CallLocalFunction("OnPlayerCommandText", "is", playerid, cmd);
}

Dialog:FamilyWithdrawDlg(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(PlayerInfo[playerid][pRank] < 5) return SendClientMessageEx(playerid, COLOR_GRAD1, "Chi leader (rank 5+) moi rut tien."), 1;
	new amount; if(sscanf(inputtext, "d", amount) || amount <= 0) return SendClientMessageEx(playerid, COLOR_GREY, "So tien khong hop le."), 1;
	new cmd[48]; format(cmd, sizeof(cmd), "%s %d", "/safewithdraw", amount);
	return CallLocalFunction("OnPlayerCommandText", "is", playerid, cmd);
}

Dialog:FamilyInviteDlg(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(isnull(inputtext)) return SendClientMessageEx(playerid, COLOR_GREY, "Nhap ten hoac ID hop le."), 1;
	new cmd[80]; format(cmd, sizeof(cmd), "%s %s", "/invite", inputtext);
	return CallLocalFunction("OnPlayerCommandText", "is", playerid, cmd);
}

Dialog:FamilyKickDlg(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(isnull(inputtext)) return SendClientMessageEx(playerid, COLOR_GREY, "Nhap ten hoac ID hop le."), 1;
	new cmd[80]; format(cmd, sizeof(cmd), "%s %s", "/uninvite", inputtext);
	return CallLocalFunction("OnPlayerCommandText", "is", playerid, cmd);
}

Dialog:FamilyMoveGlockerConfirm(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(PlayerInfo[playerid][pRank] < 5) return SendClientMessageEx(playerid, COLOR_GRAD1, "Chi leader (rank 5+) moi doi vi tri glocker/safe."), 1;
	new fam = PlayerInfo[playerid][pFMember];
	if(fam == INVALID_FAMILY_ID) return 1;
	
	if(FamilyInfo[fam][FamilyUSafe] > 0 && FamilyInfo[fam][FamilyPickup] != INVALID_STREAMER_ID)
	{
		DestroyDynamicPickup(FamilyInfo[fam][FamilyPickup]);
		FamilyInfo[fam][FamilyPickup] = INVALID_STREAMER_ID;
	}
	
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	FamilyInfo[fam][FamilySafe][0] = x;
	FamilyInfo[fam][FamilySafe][1] = y;
	FamilyInfo[fam][FamilySafe][2] = z;
	FamilyInfo[fam][FamilySafeVW] = GetPlayerVirtualWorld(playerid);
	FamilyInfo[fam][FamilySafeInt] = GetPlayerInterior(playerid);
	FamilyInfo[fam][FamilyUSafe] = 1;
	
	FamilyInfo[fam][FamilyPickup] = CreateDynamicPickup(1239, 23, x, y, z, .worldid = FamilyInfo[fam][FamilySafeVW], .interiorid = FamilyInfo[fam][FamilySafeInt]);
	new string[1280];
	format(string, sizeof(string), "%s\n{9E9E9E}Su dung {873D37}/glocker{9E9E9E} de mo", FamilyInfo[fam][FamilyName]);
	FamilyInfo[fam][FamilyTextLabel] = CreateDynamic3DTextLabel(string, COLOR_YELLOW, FamilyInfo[fam][FamilySafe][0], FamilyInfo[fam][FamilySafe][1], FamilyInfo[fam][FamilySafe][2]+0.6, 4.0, .testlos = 1, .worldid = FamilyInfo[fam][FamilySafeVW], .interiorid = FamilyInfo[fam][FamilySafeInt]);
	SaveFamily(fam);
	SendClientMessageEx(playerid, COLOR_WHITE, "Da cap nhat vi tri Glocker/Safe cho Family va pickup da duoc di chuyen.");
	return 1;
}

Dialog:FamilyUpgradeDlg(playerid, response, listitem, inputtext[])
{
    if(!response) return 1;
    if(PlayerInfo[playerid][pRank] < 5) return SendClientMessageEx(playerid, COLOR_GRAD1, "Chi leader (rank 5+) moi duoc phep nang cap."), 1;
    new fam = PlayerInfo[playerid][pFMember];
    if(fam == INVALID_FAMILY_ID) return 1;

    if(FamilyInfo[fam][FamilyLevel] <= 0) FamilyInfo[fam][FamilyLevel] = 1;
    if(FamilyInfo[fam][FamilyMaxMembers] <= 0) FamilyInfo[fam][FamilyMaxMembers] = 10;

    if(FamilyInfo[fam][FamilyLevel] >= 5)
        return SendClientMessageEx(playerid, COLOR_GREY, "Family da dat cap toi da (5)."), 1;

    new level = FamilyInfo[fam][FamilyLevel];
    new cost = level * 250000; // 1:250k, 2:500k, 3:750k, 4:1M

    if(FamilyInfo[fam][FamilyCash] < cost)
    {
        new msg[96]; format(msg, sizeof(msg), "Khong du tien trong Family Safe. Can $%s.", number_format(cost));
        return SendClientMessageEx(playerid, COLOR_GREY, msg), 1;
    }

    FamilyInfo[fam][FamilyCash] -= cost;
    FamilyInfo[fam][FamilyLevel] += 1;
    FamilyInfo[fam][FamilyMaxMembers] += 10;
    SaveFamily(fam);

    new msg[144];
    format(msg, sizeof(msg), "Da nang cap thanh cong len cap %d. Slot toi da: %d. Da tru $%s tu Family Safe.", FamilyInfo[fam][FamilyLevel], FamilyInfo[fam][FamilyMaxMembers], number_format(cost));
    SendClientMessageEx(playerid, COLOR_WHITE, msg);
    return 1;
}


