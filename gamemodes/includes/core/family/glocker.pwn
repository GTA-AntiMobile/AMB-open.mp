#include <YSI\YSI_Coding\y_hooks>
CMD:glocker(playerid, params[])
{
	if(PlayerInfo[playerid][pFMember] == INVALID_FAMILY_ID)
		return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong o trong family."), 1;

	new fam = PlayerInfo[playerid][pFMember];
	if(!IsPlayerInRangeOfPoint(playerid, 3.0, FamilyInfo[fam][FamilySafe][0], FamilyInfo[fam][FamilySafe][1], FamilyInfo[fam][FamilySafe][2])
		|| GetPlayerVirtualWorld(playerid) != FamilyInfo[fam][FamilySafeVW]
		|| GetPlayerInterior(playerid) != FamilyInfo[fam][FamilySafeInt])
		return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong dung tai safe cua family."), 1;

	new info[256];
	if (PlayerInfo[playerid][pRank] >= 5)
	{
		format(info, sizeof(info), "- Quan ly sung (danh sach)\n- Donate tien vao Family Safe\n- Tu do ca nhan (rank cao)");
	}
	else
	{
		format(info, sizeof(info), "- Quan ly sung (danh sach)\n- Donate tien vao Family Safe");
	}
	Dialog_Show(playerid, GlockerMain,
		DIALOG_STYLE_LIST,
		"Family Glocker",
		info,
		"Chon", "Huy");
	return 1;
}

stock Glocker_GetMaxSlots(fam)
{
	new level = FamilyInfo[fam][FamilyLevel];
	if(level <= 0) level = 1;
	if(level > 5) level = 5; 
	return 10 + (level - 1) * 5;
}

stock Glocker_BuildList(playerid, list[], size, page = 0)
{
	new fam = PlayerInfo[playerid][pFMember];
	new maxSlots = Glocker_GetMaxSlots(fam);
	list[0] = '\0';
	
	new slotsPerPage = 15; 
	new startSlot = page * slotsPerPage;
	new endSlot = startSlot + slotsPerPage;
	if(endSlot > maxSlots) endSlot = maxSlots;
	
	if(page > 0)
	{
		strcat(list, "{FFFF00}« Trang truoc\n", size);
	}
	
	for(new s = startSlot; s < endSlot; s++)
	{
		if(FamilyInfo[fam][FamilyGuns][s] == 0)
		{
			new line[40]; format(line, sizeof(line), "{9E9E9E}Trong{FFFFFF}\n");
			strcat(list, line, size);
		}
		else
		{
			new nm[32]; GetWeaponName(FamilyInfo[fam][FamilyGuns][s], nm, sizeof(nm));
			new line[56]; format(line, sizeof(line), "{BFC0C2}%s{FFFFFF}\n", nm);
			strcat(list, line, size);
		}
	}
	
	if(endSlot < maxSlots)
	{
		strcat(list, "{FFFF00}Trang tiep »\n", size);
	}
	
	SetPVarInt(playerid, "GlockerPage", page);
	SetPVarInt(playerid, "GlockerMaxSlots", maxSlots);
	SetPVarInt(playerid, "GlockerSlotsPerPage", slotsPerPage);
}

stock Glocker_ShowManageList(playerid, page = 0)
{
	new list[1024]; 
	Glocker_BuildList(playerid, list, sizeof(list), page);
	
	new title[64];
	format(title, sizeof(title), "Quan ly sung - Trang %d", page + 1);
	
	Dialog_Show(playerid, GlockerManageList, DIALOG_STYLE_LIST, title, list, "Chon", "Dong");
	return 1;
}

Dialog:GlockerMain(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	switch(listitem)
	{
		case 0:
		{
			return Glocker_ShowManageList(playerid);
		}
		case 1:
		{
			new title[64];
			format(title, sizeof(title), "Donate vao %s Safe", FamilyInfo[PlayerInfo[playerid][pFMember]][FamilyName]);
			Dialog_Show(playerid, GlockerDonate, DIALOG_STYLE_INPUT, title, "Nhap so tien muon donate", "OK", "Huy");
		}
		case 2:
		{
			if(PlayerInfo[playerid][pRank] < 5)
				return 1;
			Dialog_Show(playerid, GlockerPersonal, DIALOG_STYLE_LIST, "Tu do ca nhan", "Luu sung hien tai\nLay sung da luu", "Chon", "Huy");
		}
	}
	return 1;
}

Dialog:GlockerDonate(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(PlayerInfo[playerid][pFMember] == INVALID_FAMILY_ID) return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong o trong family."), 1;
	new amount;
	if(sscanf(inputtext, "d", amount) || amount <= 0) return SendClientMessageEx(playerid, COLOR_GREY, "So tien khong hop le."), 1;
	if(GetPlayerCash(playerid) < amount) return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong co du tien."), 1;
	GivePlayerCash(playerid, -amount);
	FamilyInfo[PlayerInfo[playerid][pFMember]][FamilyCash] += amount;
	SaveFamily(PlayerInfo[playerid][pFMember]);
	SendClientMessageEx(playerid, COLOR_WHITE, "Ban da donate thanh cong vao Family Safe.");
	
	// Log money transfer
	LogMoneyTransfer(playerid, INVALID_PLAYER_ID, amount, MONEY_TYPE_BUSINESS, "Donate tien vao family safe");
	return 1;
}

Dialog:GlockerManageList(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	new fam = PlayerInfo[playerid][pFMember];
	if(fam == INVALID_FAMILY_ID) return 1;
	if(!IsPlayerInRangeOfPoint(playerid, 3.0, FamilyInfo[fam][FamilySafe][0], FamilyInfo[fam][FamilySafe][1], FamilyInfo[fam][FamilySafe][2])
		|| GetPlayerVirtualWorld(playerid) != FamilyInfo[fam][FamilySafeVW]
		|| GetPlayerInterior(playerid) != FamilyInfo[fam][FamilySafeInt])
		return SendClientMessageEx(playerid, COLOR_GRAD1, "Ban khong dung tai safe cua family."), 1;
	if(GetPVarInt(playerid, "GiveWeaponTimer") > 0) return SendClientMessageEx(playerid, COLOR_GREY, "Vui long doi truoc khi thuc hien tiep."), 1;

	new page = GetPVarInt(playerid, "GlockerPage");
	new slotsPerPage = GetPVarInt(playerid, "GlockerSlotsPerPage");
	new maxSlots = GetPVarInt(playerid, "GlockerMaxSlots");
	
	if(page > 0 && listitem == 0) 
	{
		return Glocker_ShowManageList(playerid, page - 1);
	}
	
	new lastItemIndex = (page > 0) ? slotsPerPage : (slotsPerPage - 1);
	if((page * slotsPerPage + slotsPerPage) < maxSlots && listitem == lastItemIndex + 1) // Next page
	{
		return Glocker_ShowManageList(playerid, page + 1);
	}
	
	new actualSlot = (page * slotsPerPage) + listitem;
	if(page > 0) actualSlot--;
	
	if(!(0 <= actualSlot < maxSlots)) return SendClientMessageEx(playerid, COLOR_GREY, "Lua chon khong hop le."), 1;
	if(FamilyInfo[fam][FamilyGuns][actualSlot] == 0)
	{
		new weap = GetPlayerWeapon(playerid);
		switch(weap)
		{
			case 23,24,25,27,29,30,31,33,34: {}
			default: return SendClientMessageEx(playerid, COLOR_GREY, "Ban phai cam mot vu khi hop le de cat vao safe."), 1;
		}
		if(FamilyInfo[fam][FamilyGuns][actualSlot] != 0) return SendClientMessageEx(playerid, COLOR_GREY, "Slot nay vua bi chiem, vui long thu lai."), 1;
		FamilyInfo[fam][FamilyGuns][actualSlot] = weap;
		RemovePlayerWeaponEx(playerid, weap);
		SaveFamily(fam);
		SetPVarInt(playerid, "GiveWeaponTimer", 3);
		SetTimerEx("OtherTimerEx", 1000, false, "ii", playerid, TYPE_GIVEWEAPONTIMER);
		new nm[32]; GetWeaponName(weap, nm, sizeof(nm));
		new msg[96]; format(msg, sizeof(msg), "Da cat %s vao slot %d.", nm, actualSlot+1);
		SendClientMessageEx(playerid, COLOR_LIGHTBLUE, msg);
		
		// Log weapon store
		LogWeaponTake(playerid, weap, -60000, WEAPON_TYPE_FAMILY, PlayerInfo[playerid][pFMember], "Cat sung vao family glocker");
	}
	else
	{
		new w = FamilyInfo[fam][FamilyGuns][actualSlot];
		if(w == 0) return SendClientMessageEx(playerid, COLOR_GREY, "Vu khi khong con ton tai."), 1;
		FamilyInfo[fam][FamilyGuns][actualSlot] = 0; 
		SaveFamily(fam);
		GivePlayerValidWeapon(playerid, w, 60000);
		SetPVarInt(playerid, "GiveWeaponTimer", 3);
		SetTimerEx("OtherTimerEx", 1000, false, "ii", playerid, TYPE_GIVEWEAPONTIMER);
		new nm2[32]; GetWeaponName(w, nm2, sizeof(nm2));
		new msg2[96]; format(msg2, sizeof(msg2), "Da nhan %s tu slot %d.", nm2, actualSlot+1);
		SendClientMessageEx(playerid, COLOR_LIGHTBLUE, msg2);
		
		// Log weapon take
		LogWeaponTake(playerid, w, 60000, WEAPON_TYPE_FAMILY, PlayerInfo[playerid][pFMember], "Lay sung tu family glocker");
	}
	return Glocker_ShowManageList(playerid, page);
}

Dialog:GlockerPersonal(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(PlayerInfo[playerid][pRank] < 5) return SendClientMessageEx(playerid, COLOR_GRAD1, "Chi rank 5+ moi su dung!"), 1;
	new fam = PlayerInfo[playerid][pFMember];
	if(fam == INVALID_FAMILY_ID) return 1;
	
	new personalSlot = 29;
	
	if(listitem == 0)
	{
		if(FamilyInfo[fam][FamilyGuns][personalSlot] != 0) return SendClientMessageEx(playerid, COLOR_GREY, "Slot ca nhan dang bi chiem."), 1;
		new w = 0;
		for(new i=2;i<=7;i++) if(PlayerInfo[playerid][pGuns][i] != 0 && PlayerInfo[playerid][pAGuns][i] == 0) { w = PlayerInfo[playerid][pGuns][i]; break; }
		if(w == 0) return SendClientMessageEx(playerid, COLOR_GREY, "Ban khong co sung hop le de luu."), 1;
		FamilyInfo[fam][FamilyGuns][personalSlot] = w;
		RemovePlayerWeaponEx(playerid, w);
		SaveFamily(fam);
		SendClientMessageEx(playerid, COLOR_WHITE, "Da luu sung vao slot ca nhan (#30).");
		
		// Log weapon store
		LogWeaponTake(playerid, w, -60000, WEAPON_TYPE_FAMILY, PlayerInfo[playerid][pFMember], "Cat sung vao slot ca nhan family");
	}
	else if(listitem == 1)
	{
		if(FamilyInfo[fam][FamilyGuns][personalSlot] == 0) return SendClientMessageEx(playerid, COLOR_GREY, "Slot ca nhan trong."), 1;
		new weapon = FamilyInfo[fam][FamilyGuns][personalSlot];
		GivePlayerValidWeapon(playerid, weapon, 60000);
		FamilyInfo[fam][FamilyGuns][personalSlot] = 0;
		SaveFamily(fam);
		SendClientMessageEx(playerid, COLOR_WHITE, "Da nhan sung tu slot ca nhan (#30).");
		
		// Log weapon take
		LogWeaponTake(playerid, weapon, 60000, WEAPON_TYPE_FAMILY, PlayerInfo[playerid][pFMember], "Lay sung tu slot ca nhan family");
	}
	return 1;
}


