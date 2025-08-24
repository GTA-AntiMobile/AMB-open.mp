 //--------------------------------[ FUNCTIONS ]---------------------------
 
PinLogin(playerid)
{
    new string[128];
    format(string, sizeof(string), "SELECT `Pin` FROM `accounts` WHERE `id` = %d", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, string, "OnPinCheck", "i", playerid);
}

Group_DisbandGroup(iGroupID) {

	new
		i = 0,
		szQuery[128];

	arrGroupData[iGroupID][g_iAllegiance] = 0;
	arrGroupData[iGroupID][g_iBugAccess] = INVALID_RANK;
	arrGroupData[iGroupID][g_iRadioAccess] = INVALID_RANK;
	arrGroupData[iGroupID][g_iDeptRadioAccess] = INVALID_RANK;
	arrGroupData[iGroupID][g_iIntRadioAccess] = INVALID_RANK;
	arrGroupData[iGroupID][g_iGovAccess] = INVALID_RANK;
	arrGroupData[iGroupID][g_iFreeNameChange] = INVALID_RANK;
	arrGroupData[iGroupID][g_iSpikeStrips] = INVALID_RANK;
	arrGroupData[iGroupID][g_iBarricades] = INVALID_RANK;
	arrGroupData[iGroupID][g_iCones] = INVALID_RANK;
	arrGroupData[iGroupID][g_iFlares] = INVALID_RANK;
	arrGroupData[iGroupID][g_iBarrels] = INVALID_RANK;
	arrGroupData[iGroupID][g_iBudget] = 0;
	arrGroupData[iGroupID][g_iBudgetPayment] = 0;
	arrGroupData[iGroupID][g_fCratePos][0] = 0;
	arrGroupData[iGroupID][g_fCratePos][1] = 0;
	arrGroupData[iGroupID][g_fCratePos][2] = 0;
	arrGroupData[iGroupID][g_szGroupName][0] = 0;
	arrGroupData[iGroupID][g_szGroupMOTD][0] = 0;

	arrGroupData[iGroupID][g_hDutyColour] = 0xFFFFFF;
	arrGroupData[iGroupID][g_hRadioColour] = 0xFFFFFF;

	DestroyDynamic3DTextLabel(arrGroupData[iGroupID][g_tCrate3DLabel]);

	while(i < MAX_GROUP_DIVS) {
		arrGroupDivisions[iGroupID][i++][0] = 0;
	}
	i = 0;

	while(i < MAX_GROUP_RANKS) {
		arrGroupRanks[iGroupID][i][0] = 0;
		arrGroupData[iGroupID][g_iPaycheck][i++] = 0;
	}
	i = 0;

	while(i < MAX_GROUP_WEAPONS) {
		arrGroupData[iGroupID][g_iLockerGuns][i] = 0;
		arrGroupData[iGroupID][g_iLockerCost][i++] = 0;
	}

	i = 0;
	while(i < MAX_GROUP_LOCKERS) {
		DestroyDynamic3DTextLabel(arrGroupLockers[iGroupID][i][g_tLocker3DLabel]);
		arrGroupLockers[iGroupID][i][g_fLockerPos][0] = 0.0;
		arrGroupLockers[iGroupID][i][g_fLockerPos][1] = 0.0;
		arrGroupLockers[iGroupID][i][g_fLockerPos][2] = 0.0;
		arrGroupData[iGroupID][g_iLockerGuns][i] = 0;
		arrGroupData[iGroupID][g_iLockerCost][i++] = 0;
	}
	SaveGroup(iGroupID);

	foreach(new x: Player)
	{
		if(PlayerInfo[x][pMember] == iGroupID || PlayerInfo[x][pLeader] == iGroupID) {
			SendClientMessageEx(x, COLOR_WHITE, "Nhom cua ban da bi xoa boi Admin, tat ca cac thanh vien se tu dong bi duoi ra khoi nhom.");
			PlayerInfo[x][pLeader] = INVALID_GROUP_ID;
			PlayerInfo[x][pMember] = INVALID_GROUP_ID;
			PlayerInfo[x][pRank] = INVALID_RANK;
			PlayerInfo[x][pDivision] = INVALID_DIVISION;
		}
		if (PlayerInfo[x][pBugged] == iGroupID) PlayerInfo[x][pBugged] = INVALID_GROUP_ID;
	}


	format(szQuery, sizeof szQuery, "DELETE FROM `groupbans` WHERE `GroupBan` = %i", iGroupID);
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, iGroupID+1);

	format(szQuery, sizeof szQuery, "UPDATE `accounts` SET `Member` = "#INVALID_GROUP_ID", `Leader` = "#INVALID_GROUP_ID", `Division` = "#INVALID_DIVISION", `Rank` = "#INVALID_RANK" WHERE `Member` = %i OR `Leader` = %i", iGroupID, iGroupID);
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, iGroupID);
	return 1;
}

SaveGroup(iGroupID) {

	/*
		Internally, every group array/subarray starts from zero (divisions, group ids etc)
		When displaying to the clients or saving to the db, we add 1 to them!
		The only exception is ranks which already start from zero.
	*/

	if(!(0 <= iGroupID < MAX_GROUPS)) // Array bounds check. Use it.
		return 0;

	new
		szQuery[2048],
		i = 0;

	format(szQuery, sizeof szQuery, "UPDATE `groups` SET \
		`Type` = %i, `Name` = '%s', `MOTD` = '%s', `Allegiance` = %i, `Bug` = %i, \
		`Radio` = %i, `DeptRadio` = %i, `IntRadio` = %i, `GovAnnouncement` = %i, `FreeNameChange` = %i, `DutyColour` = %i, `RadioColour` = %i, ",
		arrGroupData[iGroupID][g_iGroupType], g_mysql_ReturnEscaped(arrGroupData[iGroupID][g_szGroupName], MainPipeline), arrGroupData[iGroupID][g_szGroupMOTD], arrGroupData[iGroupID][g_iAllegiance], arrGroupData[iGroupID][g_iBugAccess],
		arrGroupData[iGroupID][g_iRadioAccess], arrGroupData[iGroupID][g_iDeptRadioAccess], arrGroupData[iGroupID][g_iIntRadioAccess], arrGroupData[iGroupID][g_iGovAccess], arrGroupData[iGroupID][g_iFreeNameChange], arrGroupData[iGroupID][g_hDutyColour], arrGroupData[iGroupID][g_hRadioColour]
	);
	format(szQuery, sizeof szQuery, "%s\
		`Stock` = %i, `CrateX` = '%.2f', `CrateY` = '%.2f', `CrateZ` = '%.2f', \
		`SpikeStrips` = %i, `Barricades` = %i, `Cones` = %i, `Flares` = %i, `Barrels` = %i, \
		`Budget` = %i, `BudgetPayment` = %i, LockerCostType = %i, `CratesOrder` = '%d', `CrateIsland` = '%d', \
		`GarageX` = '%.2f', `GarageY` = '%.2f', `GarageZ` = '%.2f'",
		szQuery,
		arrGroupData[iGroupID][g_iLockerStock], arrGroupData[iGroupID][g_fCratePos][0], arrGroupData[iGroupID][g_fCratePos][1], arrGroupData[iGroupID][g_fCratePos][2],
		arrGroupData[iGroupID][g_iSpikeStrips], arrGroupData[iGroupID][g_iBarricades], arrGroupData[iGroupID][g_iCones], arrGroupData[iGroupID][g_iFlares], arrGroupData[iGroupID][g_iBarrels],
		arrGroupData[iGroupID][g_iBudget], arrGroupData[iGroupID][g_iBudgetPayment], arrGroupData[iGroupID][g_iLockerCostType], arrGroupData[iGroupID][g_iCratesOrder], arrGroupData[iGroupID][g_iCrateIsland],
		arrGroupData[iGroupID][g_fGaragePos][0], arrGroupData[iGroupID][g_fGaragePos][1], arrGroupData[iGroupID][g_fGaragePos][2]);

	for(i = 0; i != MAX_GROUP_RANKS; ++i) format(szQuery, sizeof szQuery, "%s, `Rank%i` = '%s'", szQuery, i, arrGroupRanks[iGroupID][i]);
	for(i = 0; i != MAX_GROUP_RANKS; ++i) format(szQuery, sizeof szQuery, "%s, `Rank%iPay` = %i", szQuery, i, arrGroupData[iGroupID][g_iPaycheck][i]);
	for(i = 0; i != MAX_GROUP_DIVS; ++i) format(szQuery, sizeof szQuery, "%s, `Div%i` = '%s'", szQuery, i+1, arrGroupDivisions[iGroupID][i]);
	for(i = 0; i != MAX_GROUP_WEAPONS; ++i) format(szQuery, sizeof szQuery, "%s, `Gun%i` = %i, `Cost%i` = %i", szQuery, i+1, arrGroupData[iGroupID][g_iLockerGuns][i], i+1, arrGroupData[iGroupID][g_iLockerCost][i]);
	format(szQuery, sizeof szQuery, "%s WHERE `id` = %i", szQuery, iGroupID+1);
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);

	for (i = 0; i < MAX_GROUP_LOCKERS; i++)	{
		format(szQuery, sizeof(szQuery), "UPDATE `lockers` SET `LockerX` = '%.2f', `LockerY` = '%.2f', `LockerZ` = '%.2f', `LockerVW` = %d, `LockerShare` = %d WHERE `Id` = %d", arrGroupLockers[iGroupID][i][g_fLockerPos][0], arrGroupLockers[iGroupID][i][g_fLockerPos][1], arrGroupLockers[iGroupID][i][g_fLockerPos][2], arrGroupLockers[iGroupID][i][g_iLockerVW], arrGroupLockers[iGroupID][i][g_iLockerShare], arrGroupLockers[iGroupID][i][g_iLockerSQLId]);
		mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);
	}
	return 1;
}

DynVeh_Save(iDvSlotID) {
	if((iDvSlotID > MAX_DYNAMIC_VEHICLES)) // Array bounds check. Use it.
		return 0;

	new
		szQuery[2248],
		i = 0;

	format(szQuery, sizeof szQuery,
		"UPDATE `groupvehs` SET `SpawnedID`= '%d',`gID`= '%d',`gDivID`= '%d', `fID`='%d', `rID`='%d', `vModel`= '%d', \
		`vPlate` = '%s',`vMaxHealth`= '%.2f',`vType`= '%d',`vLoadMax`= '%d',`vCol1`= '%d',`vCol2`= '%d', \
		`vX`= '%.2f',`vY`= '%.2f',`vZ`= '%.2f',`vRotZ`= '%.2f', `vUpkeep` = '%d', `vVW` = '%d', `vDisabled` = '%d', \
		`vInt` = '%d', `vFuel` = '%.5f'"
		, DynVehicleInfo[iDvSlotID][gv_iSpawnedID], DynVehicleInfo[iDvSlotID][gv_igID], DynVehicleInfo[iDvSlotID][gv_igDivID], DynVehicleInfo[iDvSlotID][gv_ifID], DynVehicleInfo[iDvSlotID][gv_irID], DynVehicleInfo[iDvSlotID][gv_iModel],
		g_mysql_ReturnEscaped(DynVehicleInfo[iDvSlotID][gv_iPlate], MainPipeline), DynVehicleInfo[iDvSlotID][gv_fMaxHealth], DynVehicleInfo[iDvSlotID][gv_iType], DynVehicleInfo[iDvSlotID][gv_iLoadMax], DynVehicleInfo[iDvSlotID][gv_iCol1], DynVehicleInfo[iDvSlotID][gv_iCol2],
		DynVehicleInfo[iDvSlotID][gv_fX], DynVehicleInfo[iDvSlotID][gv_fY], DynVehicleInfo[iDvSlotID][gv_fZ], DynVehicleInfo[iDvSlotID][gv_fRotZ], DynVehicleInfo[iDvSlotID][gv_iUpkeep], DynVehicleInfo[iDvSlotID][gv_iVW], DynVehicleInfo[iDvSlotID][gv_iDisabled],
		DynVehicleInfo[iDvSlotID][gv_iInt], DynVehicleInfo[iDvSlotID][gv_fFuel]);

	for(i = 0; i != MAX_DV_OBJECTS; ++i) {
		format(szQuery, sizeof szQuery, "%s, `vAttachedObjectModel%i` = '%d'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_iAttachedObjectModel][i]);
		format(szQuery, sizeof szQuery, "%s, `vObjectX%i` = '%.2f'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_fObjectX][i]);
		format(szQuery, sizeof szQuery, "%s, `vObjectY%i` = '%.2f'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_fObjectY][i]);
		format(szQuery, sizeof szQuery, "%s, `vObjectZ%i` = '%.2f'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_fObjectZ][i]);
		format(szQuery, sizeof szQuery, "%s, `vObjectRX%i` = '%.2f'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_fObjectRX][i]);
		format(szQuery, sizeof szQuery, "%s, `vObjectRY%i` = '%.2f'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_fObjectRY][i]);
		format(szQuery, sizeof szQuery, "%s, `vObjectRZ%i` = '%.2f'", szQuery, i+1, DynVehicleInfo[iDvSlotID][gv_fObjectRZ][i]);
	}

	for(i = 0; i != MAX_DV_MODS; ++i) format(szQuery, sizeof szQuery, "%s, `vMod%d` = %i", szQuery, i, DynVehicleInfo[iDvSlotID][gv_iMod][i]);

	format(szQuery, sizeof szQuery, "%s WHERE `id` = %i", szQuery, iDvSlotID);
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);
	return 1;
}
 
//--------------------------------[ INITIATE/EXIT ]---------------------------

// g_mysql_Init()
// Description: Called with Gamemode Init.
stock g_mysql_Init()
{
	new SQL_HOST[64], SQL_DB[64], SQL_USER[32], SQL_PASS[128], SQL_DEBUG, SQL_DEBUGLOG;
	new SQL_SHOST[64], SQL_SDB[64], SQL_SUSER[32], SQL_SPASS[128];
	new fileString[128], File: fileHandle = fopen("mysql.cfg", io_read);

	while(fread(fileHandle, fileString, sizeof(fileString))) {
		if(ini_GetValue(fileString, "HOST", SQL_HOST, sizeof(SQL_HOST))) continue;
		if(ini_GetValue(fileString, "DB", SQL_DB, sizeof(SQL_DB))) continue;
		if(ini_GetValue(fileString, "USER", SQL_USER, sizeof(SQL_USER))) continue;
		if(ini_GetValue(fileString, "PASS", SQL_PASS, sizeof(SQL_PASS))) continue;
		if(ini_GetInt(fileString, "SHOPAUTOMATED", ShopToggle)) continue;
		if(ini_GetValue(fileString, "SHOST", SQL_SHOST, sizeof(SQL_SHOST))) continue;
		if(ini_GetValue(fileString, "SDB", SQL_SDB, sizeof(SQL_SDB))) continue;
		if(ini_GetValue(fileString, "SUSER", SQL_SUSER, sizeof(SQL_SUSER))) continue;
		if(ini_GetValue(fileString, "SPASS", SQL_SPASS, sizeof(SQL_SPASS))) continue;
		if(ini_GetInt(fileString, "SERVER", servernumber)) continue;
		if(ini_GetInt(fileString, "DEBUG", SQL_DEBUG)) continue;
		if(ini_GetInt(fileString, "DEBUGLOG", SQL_DEBUGLOG)) continue;
	}
	fclose(fileHandle);

	mysql_global_options(DUPLICATE_CONNECTIONS, true);
	mysql_log(ERROR | WARNING); 
	
	new MySQLOpt:mainOptions = mysql_init_options();
	mysql_set_option(mainOptions, AUTO_RECONNECT, true);
	mysql_set_option(mainOptions, MULTI_STATEMENTS, true);
	
	MainPipeline = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_DB, mainOptions);
	

	printf("[MySQL] (Main Pipeline R41-4) Connecting to %s...", SQL_HOST);
	if(mysql_errno(MainPipeline) != 0)
	{
		printf("[MySQL] (MainPipeline) Fatal Error! Could not connect to MySQL: Host %s - DB: %s - User: %s", SQL_HOST, SQL_DB, SQL_USER);
		print("[MySQL] Note: Make sure that you have provided the correct connection credentials.");
		printf("[MySQL] Error number: %d", mysql_errno(MainPipeline));
		SendRconCommand("exit");
	}
	else print("[MySQL] (MainPipeline) Connection successful toward MySQL Database Server!");

	if(ShopToggle == 1)
	{
		new MySQLOpt:shopOptions = mysql_init_options();
		mysql_set_option(shopOptions, AUTO_RECONNECT, true);
		mysql_set_option(shopOptions, MULTI_STATEMENTS, true);
		ShopPipeline = mysql_connect(SQL_SHOST, SQL_SUSER, SQL_SPASS, SQL_SDB, shopOptions);


		printf("[MySQL] (Shop Pipeline R41-4) Connecting to %s...", SQL_SHOST);
		if(mysql_errno(ShopPipeline) != 0)
		{
			printf("[MySQL] (ShopPipeline) Fatal Error! Could not connect to MySQL: Host %s - DB: %s - User: %s", SQL_SHOST, SQL_SDB, SQL_SUSER);
			print("[MySQL] Note: Make sure that you have provided the correct connection credentials.");
			printf("[MySQL] Error number: %d", mysql_errno(ShopPipeline));
		}
		else print("[MySQL] (ShopPipeline) Connection successful toward MySQL Database Server!");
	}
	
	SetTimer("DelayedInitiateGamemode", 1000, false);

	return 1;
}

forward DelayedInitiateGamemode();
public DelayedInitiateGamemode()
{
	InitiateGamemode(); // Start the server
	return 1;
}

// g_mysql_Exit()
// Description: Called with Gamemode Exit.
stock g_mysql_Exit()
{
	mysql_close(MainPipeline);
	if(ShopToggle == 1) mysql_close(ShopPipeline);
	return 1;
}
 
//--------------------------------[ COMPATIBILITY FUNCTIONS ]--------------------------------

// Backward compatibility functions for MySQL R41-4  
stock mysql_function_query_internal(MySQL:handle, const query[], bool:cache, const callback[], const format[], {Float,_}:...)
{
	if(cache) {
		mysql_pquery(handle, query, callback, format, ___(5));
	} else {
		mysql_query(handle, query, false);
	}
	return 0;
}

// Note: mysql_function_query macro is defined in defines.pwn

stock cache_get_data(&rows, &fields, MySQL:handle = MYSQL_INVALID_HANDLE)
{
	#pragma unused handle
	rows = cache_num_rows();
	fields = cache_num_fields();
	return 1;
}

stock cache_get_field_content(row, const field_name[], destination[], MySQL:handle = MYSQL_INVALID_HANDLE, max_len = 128)
{
	#pragma unused handle
	return cache_get_value_name(row, field_name, destination, max_len);
}

stock mysql_real_escape_string(const source[], destination[], MySQL:handle = MYSQL_INVALID_HANDLE, max_len = 128)
{
	#pragma unused handle
	return mysql_escape_string(source, destination, max_len);
}

stock cache_get_row(dest[], MySQL:handle = MYSQL_INVALID_HANDLE, const delimiter[] = "|", maxlength = sizeof(dest))
{
	#pragma unused handle
	new fields = cache_num_fields();
	dest[0] = EOS;
	
	for(new i = 0; i < fields; i++) {
		new field_content[256];
		cache_get_value_index(0, i, field_content);
		
		if(i > 0) strcat(dest, delimiter, maxlength);
		strcat(dest, field_content, maxlength);
	}
	return 1;
}

stock mysql_insert_id(MySQL:handle = MYSQL_INVALID_HANDLE)
{
	#pragma unused handle
	return cache_insert_id();
}

stock mysql_affected_rows(MySQL:handle = MYSQL_INVALID_HANDLE)
{
	#pragma unused handle
	return cache_affected_rows();
}

stock mysql_free_result(MySQL:handle = MYSQL_INVALID_HANDLE)
{
	#pragma unused handle
	return cache_delete(cache_save());
}

stock cache_get_field_content_int(row, const field_name[], MySQL:handle = MYSQL_INVALID_HANDLE)
{
	#pragma unused handle
	new result[32];
	cache_get_value_name(row, field_name, result);
	return strval(result);
}
 
//--------------------------------[ CALLBACKS ]--------------------------------
 
forward OnQueryFinish(Cache:resultid, extraid, handleid);
// forward OnQueryError - defined in a_mysql.inc

public OnQueryFinish(Cache:resultid, extraid, handleid)
{
    new rows, fields;
	if(_:resultid != _:SENDDATA_THREAD) {
		if(extraid != INVALID_PLAYER_ID) {
			if(g_arrQueryHandle{extraid} != -1 && g_arrQueryHandle{extraid} != handleid) return 0;
		}
		cache_set_active(resultid);
		cache_get_data(rows, fields);
	}
	switch(_:resultid)
	{
	    case LOADSALEDATA_THREAD:
	    {
	        if(rows > 0)
			{
                for(new i;i < rows;i++)
				{
			    	new szResult[32], szField[15];
			    	for(new z = 0; z < MAX_ITEMS; z++)
					{
						format(szField, sizeof(szField), "TotalSold%d", z);
						cache_get_value_name(i, szField, szResult);
                        AmountSold[z] = strval(szResult);
						//ShopItems[z][sSold] = strval(szResult);


						format(szField, sizeof(szField), "AmountMade%d", z);
						cache_get_value_name(i, szField, szResult);
						AmountMade[z] = strval(szResult);
						//ShopItems[z][sMade] = strval(szResult);
						// printf("TotalSold%d: %d | AmountMade%d: %d", z, AmountSold[z], z, AmountMade[z]);
					}
					break;
				}
			}
			else
			{
				mysql_pquery(MainPipeline, "INSERT INTO `sales` (`Month`) VALUES (NOW())", "OnQueryFinish", "i", SENDDATA_THREAD);
				mysql_pquery(MainPipeline, "SELECT * FROM `sales` WHERE `Month` > NOW() - INTERVAL 1 MONTH", "OnQueryFinish", "iii", LOADSALEDATA_THREAD, INVALID_PLAYER_ID, -1);
				print("[LOADSALEDATA] Inserted new row into `sales`");
			}
	    }
	    case LOADSHOPDATA_THREAD:
	    {
	        for(new i;i < rows;i++)
			{
	        	new szResult[32], szField[14];
	        	for(new z = 0; z < MAX_ITEMS; z++)
				{
					format(szField, sizeof(szField), "Price%d", z);
					cache_get_value_name(i,  szField, szResult);
					ShopItems[z][sItemPrice] = strval(szResult);
					Price[z] = strval(szResult);
					if(ShopItems[z][sItemPrice] == 0) ShopItems[z][sItemPrice] = 99999999;
					// printf("Price%d: %d", z, ShopItems[z][sItemPrice]);
				}
                //printf("[LOADSHOPDATA] Price0: %d, Price1: %d, Price2: %d, Price3: %d, Price4: %d, Price5: %d, Price6: %d, Price7: %d, Pricr8: %d, Price9: %d, Price10: %d", Price[0], Price[1], Price[2], Price[3], Price[4], Price[5], Price[6], Price[7], Price[8], Price[9], Price[10]);
				break;
			}
	    }
		case LOADMOTDDATA_THREAD:
		{
   			for(new i;i < rows;i++)
			{
			    new szResult[32];
   				cache_get_value_name(i, "gMOTD", GlobalMOTD, 128);
				cache_get_value_name(i, "aMOTD", AdminMOTD, 128);
				cache_get_value_name(i, "vMOTD", VIPMOTD, 128);
				cache_get_value_name(i, "cMOTD", CAMOTD, 128);
				cache_get_value_name(i, "pMOTD", pMOTD, 128);
				cache_get_value_name(i, "ShopTechPay", szResult); ShopTechPay = floatstr(szResult);
                cache_get_value_name(i, "GiftCode", GiftCode, 32);
                cache_get_value_name(i, "GiftCodeBypass", szResult); GiftCodeBypass = strval(szResult);
                cache_get_value_name(i, "SecurityCode", SecurityCode, 32);
                cache_get_value_name(i, "ShopClosed", szResult); ShopClosed = strval(szResult);
                cache_get_value_name(i, "RimMod", szResult); RimMod = strval(szResult);
                cache_get_value_name(i, "CarVoucher", szResult); CarVoucher = strval(szResult);
				cache_get_value_name(i, "PVIPVoucher", szResult); PVIPVoucher = strval(szResult);
				cache_get_value_name(i, "GarageVW", szResult); GarageVW = strval(szResult);
				cache_get_value_name(i, "PumpkinStock", szResult); PumpkinStock = strval(szResult);
				cache_get_value_name(i, "HalloweenShop", szResult); HalloweenShop = strval(szResult);
				break;
			}
		}
		case LOADUSERDATA_THREAD:
		{
			if(IsPlayerConnected(extraid))
			{
   				new szField[MAX_PLAYER_NAME], szResult[64];

				for(new row;row < rows;row++)
				{
					cache_get_value_name(row, "Username", szField, MAX_PLAYER_NAME);

					if(strcmp(szField, GetPlayerNameExt(extraid), true) != 0)
					{
						return 1;
					}
					cache_get_value_name(row,  "id", szResult); PlayerInfo[extraid][pId] = strval(szResult);
					cache_get_value_name(row,  "Online", szResult); PlayerInfo[extraid][pOnline] = strval(szResult);
					cache_get_value_name(row,  "Email", PlayerInfo[extraid][pEmail], 128);
					cache_get_value_name(row,  "IP", PlayerInfo[extraid][pIP], 16);
					cache_get_value_name(row,  "SecureIP", PlayerInfo[extraid][pSecureIP], 16);
					cache_get_value_name(row,  "ConnectedTime", szResult); PlayerInfo[extraid][pConnectHours] = strval(szResult);
					cache_get_value_name(row,  "BirthDate", PlayerInfo[extraid][pBirthDate], 11);
					cache_get_value_name(row,  "Sex", szResult); PlayerInfo[extraid][pSex] = strval(szResult);
					cache_get_value_name(row,  "Band", szResult); PlayerInfo[extraid][pBanned] = strval(szResult);
					cache_get_value_name(row,  "PermBand", szResult); PlayerInfo[extraid][pPermaBanned] = strval(szResult);
					cache_get_value_name(row,  "Registered", szResult); PlayerInfo[extraid][pReg] = strval(szResult);
					cache_get_value_name(row,  "Warnings", szResult); PlayerInfo[extraid][pWarns] = strval(szResult);
					cache_get_value_name(row,  "Disabled", szResult); PlayerInfo[extraid][pDisabled] = strval(szResult);
					cache_get_value_name(row,  "Level", szResult); PlayerInfo[extraid][pLevel] = strval(szResult);
					cache_get_value_name(row,  "AdminLevel", szResult); PlayerInfo[extraid][pAdmin] = strval(szResult);
					cache_get_value_name(row,  "SeniorModerator", szResult); PlayerInfo[extraid][pSMod] = strval(szResult);
					cache_get_value_name(row,  "DonateRank", szResult); PlayerInfo[extraid][pDonateRank] = strval(szResult);
					cache_get_value_name(row,  "Respect", szResult); PlayerInfo[extraid][pExp] = strval(szResult);
					cache_get_value_name(row,  "XP", szResult); PlayerInfo[extraid][pXP] = strval(szResult);
					cache_get_value_name(row,  "Money", szResult); PlayerInfo[extraid][pCash] = strval(szResult);
					cache_get_value_name(row,  "Bank", szResult); PlayerInfo[extraid][pAccount] = strval(szResult);
					cache_get_value_name(row,  "pHealth", szResult); PlayerInfo[extraid][pHealth] = floatstr(szResult);
					cache_get_value_name(row,  "pArmor", szResult); PlayerInfo[extraid][pArmor] = floatstr(szResult);
					cache_get_value_name(row,  "pSHealth", szResult); PlayerInfo[extraid][pSHealth] = floatstr(szResult);
					cache_get_value_name(row,  "Int", szResult); PlayerInfo[extraid][pInt] = strval(szResult);
					cache_get_value_name(row,  "VirtualWorld", szResult); PlayerInfo[extraid][pVW] = strval(szResult);
					cache_get_value_name(row,  "Model", szResult); PlayerInfo[extraid][pModel] = strval(szResult);
					cache_get_value_name(row,  "SPos_x", szResult); PlayerInfo[extraid][pPos_x] = floatstr(szResult);
					cache_get_value_name(row,  "SPos_y", szResult); PlayerInfo[extraid][pPos_y] = floatstr(szResult);
					cache_get_value_name(row,  "SPos_z", szResult); PlayerInfo[extraid][pPos_z] = floatstr(szResult);
					cache_get_value_name(row,  "SPos_r", szResult); PlayerInfo[extraid][pPos_r] = floatstr(szResult);
					cache_get_value_name(row,  "BanAppealer", szResult); PlayerInfo[extraid][pBanAppealer] = strval(szResult);
					cache_get_value_name(row,  "PR", szResult); PlayerInfo[extraid][pPR] = strval(szResult);
					cache_get_value_name(row,  "HR", szResult); PlayerInfo[extraid][pHR] = strval(szResult);
					cache_get_value_name(row,  "AP", szResult); PlayerInfo[extraid][pAP] = strval(szResult);
					cache_get_value_name(row,  "Security", szResult); PlayerInfo[extraid][pSecurity] = strval(szResult);
					cache_get_value_name(row,  "ShopTech", szResult); PlayerInfo[extraid][pShopTech] = strval(szResult);
					cache_get_value_name(row,  "FactionModerator", szResult); PlayerInfo[extraid][pFactionModerator] = strval(szResult);
					cache_get_value_name(row,  "GangModerator", szResult); PlayerInfo[extraid][pGangModerator] = strval(szResult);
					cache_get_value_name(row,  "Undercover", szResult); PlayerInfo[extraid][pUndercover] = strval(szResult);
					cache_get_value_name(row,  "TogReports", szResult); PlayerInfo[extraid][pTogReports] = strval(szResult);
					cache_get_value_name(row,  "Radio", szResult); PlayerInfo[extraid][pRadio] = strval(szResult);
					cache_get_value_name(row,  "RadioFreq", szResult); PlayerInfo[extraid][pRadioFreq] = strval(szResult);
					cache_get_value_name(row,  "UpgradePoints", szResult); PlayerInfo[extraid][gPupgrade] = strval(szResult);
					cache_get_value_name(row,  "Origin", szResult); PlayerInfo[extraid][pOrigin] = strval(szResult);
					cache_get_value_name(row,  "Muted", szResult); PlayerInfo[extraid][pMuted] = strval(szResult);
					cache_get_value_name(row,  "Crimes", szResult); PlayerInfo[extraid][pCrimes] = strval(szResult);
					cache_get_value_name(row,  "Accent", szResult); PlayerInfo[extraid][pAccent] = strval(szResult);
					cache_get_value_name(row,  "CHits", szResult); PlayerInfo[extraid][pCHits] = strval(szResult);
					cache_get_value_name(row,  "FHits", szResult); PlayerInfo[extraid][pFHits] = strval(szResult);
					cache_get_value_name(row,  "Arrested", szResult); PlayerInfo[extraid][pArrested] = strval(szResult);
					cache_get_value_name(row,  "Phonebook", szResult); PlayerInfo[extraid][pPhoneBook] = strval(szResult);
					cache_get_value_name(row,  "LottoNr", szResult); PlayerInfo[extraid][pLottoNr] = strval(szResult);
					cache_get_value_name(row,  "Fishes", szResult); PlayerInfo[extraid][pFishes] = strval(szResult);
					cache_get_value_name(row,  "BiggestFish", szResult); PlayerInfo[extraid][pBiggestFish] = strval(szResult);
					cache_get_value_name(row,  "Job", szResult); PlayerInfo[extraid][pJob] = strval(szResult);
					cache_get_value_name(row,  "Job2", szResult); PlayerInfo[extraid][pJob2] = strval(szResult);
					cache_get_value_name(row,  "Paycheck", szResult); PlayerInfo[extraid][pPayCheck] = strval(szResult);
					cache_get_value_name(row,  "HeadValue", szResult); PlayerInfo[extraid][pHeadValue] = strval(szResult);
					cache_get_value_name(row,  "JailTime", szResult); PlayerInfo[extraid][pJailTime] = strval(szResult);
					cache_get_value_name(row,  "WRestricted", szResult); PlayerInfo[extraid][pWRestricted] = strval(szResult);
					cache_get_value_name(row,  "Materials", szResult); PlayerInfo[extraid][pMats] = strval(szResult);
					cache_get_value_name(row,  "Crates", szResult); PlayerInfo[extraid][pCrates] = strval(szResult);
					cache_get_value_name(row,  "Pot", szResult); PlayerInfo[extraid][pPot] = strval(szResult);
					cache_get_value_name(row,  "Crack", szResult); PlayerInfo[extraid][pCrack] = strval(szResult);
					cache_get_value_name(row,  "Nation", szResult); PlayerInfo[extraid][pNation] = strval(szResult);
					cache_get_value_name(row,  "Leader", szResult); PlayerInfo[extraid][pLeader] = strval(szResult);
					cache_get_value_name(row,  "Member", szResult); PlayerInfo[extraid][pMember] = strval(szResult);
					cache_get_value_name(row,  "Division", szResult); PlayerInfo[extraid][pDivision] = strval(szResult);
					cache_get_value_name(row,  "FMember", szResult); PlayerInfo[extraid][pFMember] = strval(szResult);
					cache_get_value_name(row,  "Rank", szResult); PlayerInfo[extraid][pRank] = strval(szResult);
					cache_get_value_name(row,  "DetSkill", szResult); PlayerInfo[extraid][pDetSkill] = strval(szResult);
					cache_get_value_name(row,  "SexSkill", szResult); PlayerInfo[extraid][pSexSkill] = strval(szResult);
					cache_get_value_name(row,  "BoxSkill", szResult); PlayerInfo[extraid][pBoxSkill] = strval(szResult);
					cache_get_value_name(row,  "LawSkill", szResult); PlayerInfo[extraid][pLawSkill] = strval(szResult);
					cache_get_value_name(row,  "MechSkill", szResult); PlayerInfo[extraid][pMechSkill] = strval(szResult);
					cache_get_value_name(row,  "TruckSkill", szResult); PlayerInfo[extraid][pTruckSkill] = strval(szResult);
					cache_get_value_name(row,  "DrugsSkill", szResult); PlayerInfo[extraid][pDrugsSkill] = strval(szResult);
					cache_get_value_name(row,  "ArmsSkill", szResult); PlayerInfo[extraid][pArmsSkill] = strval(szResult);
					cache_get_value_name(row,  "SmugglerSkill", szResult); PlayerInfo[extraid][pSmugSkill] = strval(szResult);
					cache_get_value_name(row,  "FishSkill", szResult); PlayerInfo[extraid][pFishSkill] = strval(szResult);
					cache_get_value_name(row,  "FightingStyle", szResult); PlayerInfo[extraid][pFightStyle] = strval(szResult);
					cache_get_value_name(row,  "PhoneNr", szResult); PlayerInfo[extraid][pPnumber] = strval(szResult);
					cache_get_value_name(row,  "Apartment", szResult); PlayerInfo[extraid][pPhousekey] = strval(szResult);
					cache_get_value_name(row,  "Apartment2", szResult); PlayerInfo[extraid][pPhousekey2] = strval(szResult);
					cache_get_value_name(row,  "Renting", szResult); PlayerInfo[extraid][pRenting] = strval(szResult);
					cache_get_value_name(row,  "CarLic", szResult); PlayerInfo[extraid][pCarLic] = strval(szResult);
					cache_get_value_name(row,  "FlyLic", szResult); PlayerInfo[extraid][pFlyLic] = strval(szResult);
					cache_get_value_name(row,  "BoatLic", szResult); PlayerInfo[extraid][pBoatLic] = strval(szResult);
					cache_get_value_name(row,  "FishLic", szResult); PlayerInfo[extraid][pFishLic] = strval(szResult);
					cache_get_value_name(row,  "CheckCash", szResult); PlayerInfo[extraid][pCheckCash] = strval(szResult);
					cache_get_value_name(row,  "Checks", szResult); PlayerInfo[extraid][pChecks] = strval(szResult);
					cache_get_value_name(row,  "GunLic", szResult); PlayerInfo[extraid][pGunLic] = strval(szResult);

					for(new i = 0; i < 12; i++)
					{
						format(szField, sizeof(szField), "Gun%d", i);
						cache_get_value_name(row,  szField, szResult);
						PlayerInfo[extraid][pGuns][i] = strval(szResult);
					}

					cache_get_value_name(row,  "DrugsTime", szResult); PlayerInfo[extraid][pDrugsTime] = strval(szResult);
					cache_get_value_name(row,  "LawyerTime", szResult); PlayerInfo[extraid][pLawyerTime] = strval(szResult);
					cache_get_value_name(row,  "LawyerFreeTime", szResult); PlayerInfo[extraid][pLawyerFreeTime] = strval(szResult);
					cache_get_value_name(row,  "MechTime", szResult); PlayerInfo[extraid][pMechTime] = strval(szResult);
					cache_get_value_name(row,  "SexTime", szResult); PlayerInfo[extraid][pSexTime] = strval(szResult);
					cache_get_value_name(row,  "PayDay", szResult); PlayerInfo[extraid][pConnectSeconds] = strval(szResult);
					cache_get_value_name(row,  "PayDayHad", szResult); PlayerInfo[extraid][pPayDayHad] = strval(szResult);
					cache_get_value_name(row,  "CDPlayer", szResult); PlayerInfo[extraid][pCDPlayer] = strval(szResult);
					cache_get_value_name(row,  "Dice", szResult); PlayerInfo[extraid][pDice] = strval(szResult);
					cache_get_value_name(row,  "Spraycan", szResult); PlayerInfo[extraid][pSpraycan] = strval(szResult);
					cache_get_value_name(row,  "Rope", szResult); PlayerInfo[extraid][pRope] = strval(szResult);
					cache_get_value_name(row,  "Cigars", szResult); PlayerInfo[extraid][pCigar] = strval(szResult);
					cache_get_value_name(row,  "Sprunk", szResult); PlayerInfo[extraid][pSprunk] = strval(szResult);
					cache_get_value_name(row,  "Bombs", szResult); PlayerInfo[extraid][pBombs] = strval(szResult);
					cache_get_value_name(row,  "Wins", szResult); PlayerInfo[extraid][pWins] = strval(szResult);
					cache_get_value_name(row,  "Loses", szResult); PlayerInfo[extraid][pLoses] = strval(szResult);
					cache_get_value_name(row,  "Tutorial", szResult); PlayerInfo[extraid][pTut] = strval(szResult);
					cache_get_value_name(row,  "OnDuty", szResult); PlayerInfo[extraid][pDuty] = strval(szResult);
					cache_get_value_name(row,  "Hospital", szResult); PlayerInfo[extraid][pHospital] = strval(szResult);
					cache_get_value_name(row,  "MarriedID", szResult); PlayerInfo[extraid][pMarriedID] = strval(szResult);
					cache_get_value_name(row,  "ContractBy", PlayerInfo[extraid][pContractBy], MAX_PLAYER_NAME);
					cache_get_value_name(row,  "ContractDetail", PlayerInfo[extraid][pContractDetail], 64);
					cache_get_value_name(row,  "WantedLevel", szResult); PlayerInfo[extraid][pWantedLevel] = strval(szResult);
					cache_get_value_name(row,  "Insurance", szResult); PlayerInfo[extraid][pInsurance] = strval(szResult);
					cache_get_value_name(row,  "911Muted", szResult); PlayerInfo[extraid][p911Muted] = strval(szResult);
					cache_get_value_name(row,  "NewMuted", szResult); PlayerInfo[extraid][pNMute] = strval(szResult);
					cache_get_value_name(row,  "NewMutedTotal", szResult); PlayerInfo[extraid][pNMuteTotal] = strval(szResult);
					cache_get_value_name(row,  "AdMuted", szResult); PlayerInfo[extraid][pADMute] = strval(szResult);
					cache_get_value_name(row,  "AdMutedTotal", szResult); PlayerInfo[extraid][pADMuteTotal] = strval(szResult);
					cache_get_value_name(row,  "HelpMute", szResult); PlayerInfo[extraid][pHelpMute] = strval(szResult);
					cache_get_value_name(row,  "Helper", szResult); PlayerInfo[extraid][pHelper] = strval(szResult);
					cache_get_value_name(row,  "ReportMuted", szResult); PlayerInfo[extraid][pRMuted] = strval(szResult);
					cache_get_value_name(row,  "ReportMutedTotal", szResult); PlayerInfo[extraid][pRMutedTotal] = strval(szResult);
					cache_get_value_name(row,  "ReportMutedTime", szResult); PlayerInfo[extraid][pRMutedTime] = strval(szResult);
					cache_get_value_name(row,  "DMRMuted", szResult); PlayerInfo[extraid][pDMRMuted] = strval(szResult);
					cache_get_value_name(row,  "VIPMuted", szResult); PlayerInfo[extraid][pVMuted] = strval(szResult);
					cache_get_value_name(row,  "VIPMutedTime", szResult); PlayerInfo[extraid][pVMutedTime] = strval(szResult);
					cache_get_value_name(row,  "GiftTime", szResult); PlayerInfo[extraid][pGiftTime] = strval(szResult);
					cache_get_value_name(row,  "AdvisorDutyHours", szResult); PlayerInfo[extraid][pDutyHours] = strval(szResult);
					cache_get_value_name(row,  "AcceptedHelp", szResult); PlayerInfo[extraid][pAcceptedHelp] = strval(szResult);
					cache_get_value_name(row,  "AcceptReport", szResult); PlayerInfo[extraid][pAcceptReport] = strval(szResult);
					cache_get_value_name(row,  "ShopTechOrders", szResult); PlayerInfo[extraid][pShopTechOrders] = strval(szResult);
					cache_get_value_name(row,  "TrashReport", szResult); PlayerInfo[extraid][pTrashReport] = strval(szResult);
					cache_get_value_name(row,  "GangWarn", szResult); PlayerInfo[extraid][pGangWarn] = strval(szResult);
					cache_get_value_name(row,  "CSFBanned", szResult); PlayerInfo[extraid][pCSFBanned] = strval(szResult);
					cache_get_value_name(row,  "VIPInviteDay", szResult); PlayerInfo[extraid][pVIPInviteDay] = strval(szResult);
					cache_get_value_name(row,  "TempVIP", szResult); PlayerInfo[extraid][pTempVIP] = strval(szResult);
					cache_get_value_name(row,  "BuddyInvite", szResult); PlayerInfo[extraid][pBuddyInvited] = strval(szResult);
					cache_get_value_name(row,  "Tokens", szResult); PlayerInfo[extraid][pTokens] = strval(szResult);
					cache_get_value_name(row,  "PTokens", szResult); PlayerInfo[extraid][pPaintTokens] = strval(szResult);
					cache_get_value_name(row,  "TriageTime", szResult); PlayerInfo[extraid][pTriageTime] = strval(szResult);
					cache_get_value_name(row,  "PrisonedBy", PlayerInfo[extraid][pPrisonedBy], MAX_PLAYER_NAME);
					cache_get_value_name(row,  "PrisonReason", PlayerInfo[extraid][pPrisonReason], 128);
					cache_get_value_name(row,  "TaxiLicense", szResult); PlayerInfo[extraid][pTaxiLicense] = strval(szResult);
					cache_get_value_name(row,  "TicketTime", szResult); PlayerInfo[extraid][pTicketTime] = strval(szResult);
					cache_get_value_name(row,  "Screwdriver", szResult); PlayerInfo[extraid][pScrewdriver] = strval(szResult);
					cache_get_value_name(row,  "Smslog", szResult); PlayerInfo[extraid][pSmslog] = strval(szResult);
					cache_get_value_name(row,  "Wristwatch", szResult); PlayerInfo[extraid][pWristwatch] = strval(szResult);
					cache_get_value_name(row,  "Surveillance", szResult); PlayerInfo[extraid][pSurveillance] = strval(szResult);
					cache_get_value_name(row,  "Tire", szResult); PlayerInfo[extraid][pTire] = strval(szResult);
					cache_get_value_name(row,  "Firstaid", szResult); PlayerInfo[extraid][pFirstaid] = strval(szResult);
					cache_get_value_name(row,  "Rccam", szResult); PlayerInfo[extraid][pRccam] = strval(szResult);
					cache_get_value_name(row,  "Receiver", szResult); PlayerInfo[extraid][pReceiver] = strval(szResult);
					cache_get_value_name(row,  "GPS", szResult); PlayerInfo[extraid][pGPS] = strval(szResult);
					cache_get_value_name(row,  "Sweep", szResult); PlayerInfo[extraid][pSweep] = strval(szResult);
					cache_get_value_name(row,  "SweepLeft", szResult); PlayerInfo[extraid][pSweepLeft] = strval(szResult);
					cache_get_value_name(row,  "Bugged", szResult); PlayerInfo[extraid][pBugged] = strval(szResult);
					cache_get_value_name(row,  "pWExists", szResult); PlayerInfo[extraid][pWeedObject] = strval(szResult);
					cache_get_value_name(row,  "pWSeeds", szResult); PlayerInfo[extraid][pWSeeds] = strval(szResult);
					cache_get_value_name(row,  "Warrants", PlayerInfo[extraid][pWarrant], 128);
					cache_get_value_name(row,  "JudgeJailTime", szResult); PlayerInfo[extraid][pJudgeJailTime] = strval(szResult);
					cache_get_value_name(row,  "JudgeJailType", szResult); PlayerInfo[extraid][pJudgeJailType] = strval(szResult);
					cache_get_value_name(row,  "ProbationTime", szResult); PlayerInfo[extraid][pProbationTime] = strval(szResult);
					cache_get_value_name(row,  "DMKills", szResult); PlayerInfo[extraid][pDMKills] = strval(szResult);
					cache_get_value_name(row,  "Order", szResult); PlayerInfo[extraid][pOrder] = strval(szResult);
					cache_get_value_name(row,  "OrderConfirmed", szResult); PlayerInfo[extraid][pOrderConfirmed] = strval(szResult);
					cache_get_value_name(row,  "CallsAccepted", szResult); PlayerInfo[extraid][pCallsAccepted] = strval(szResult);
					cache_get_value_name(row,  "PatientsDelivered", szResult); PlayerInfo[extraid][pPatientsDelivered] = strval(szResult);
					cache_get_value_name(row,  "LiveBanned", szResult); PlayerInfo[extraid][pLiveBanned] = strval(szResult);
					cache_get_value_name(row,  "FreezeBank", szResult); PlayerInfo[extraid][pFreezeBank] = strval(szResult);
					cache_get_value_name(row,  "FreezeHouse", szResult); PlayerInfo[extraid][pFreezeHouse] = strval(szResult);
					cache_get_value_name(row,  "FreezeCar", szResult); PlayerInfo[extraid][pFreezeCar] = strval(szResult);
					cache_get_value_name(row,  "Firework", szResult); PlayerInfo[extraid][pFirework] = strval(szResult);
					cache_get_value_name(row,  "Boombox", szResult); PlayerInfo[extraid][pBoombox] = strval(szResult);
					cache_get_value_name(row,  "Hydration", szResult); PlayerInfo[extraid][pHydration] = strval(szResult);
					cache_get_value_name(row,  "Speedo", szResult); PlayerInfo[extraid][pSpeedo] = strval(szResult);
					cache_get_value_name(row,  "DoubleEXP", szResult); PlayerInfo[extraid][pDoubleEXP] = strval(szResult);
					cache_get_value_name(row,  "EXPToken", szResult); PlayerInfo[extraid][pEXPToken] = strval(szResult);
					cache_get_value_name(row,  "RacePlayerLaps", szResult); PlayerInfo[extraid][pRacePlayerLaps] = strval(szResult);
					cache_get_value_name(row,  "Ringtone", szResult); PlayerInfo[extraid][pRingtone] = strval(szResult);
					cache_get_value_name(row,  "VIPM", szResult); PlayerInfo[extraid][pVIPM] = strval(szResult);
					cache_get_value_name(row,  "VIPMO", szResult); PlayerInfo[extraid][pVIPMO] = strval(szResult);
					cache_get_value_name(row,  "VIPExpire", szResult); PlayerInfo[extraid][pVIPExpire] = strval(szResult);
					cache_get_value_name(row,  "GVip", szResult); PlayerInfo[extraid][pGVip] = strval(szResult);
					cache_get_value_name(row,  "Watchdog", szResult); PlayerInfo[extraid][pWatchdog] = strval(szResult);
					cache_get_value_name(row,  "VIPSold", szResult); PlayerInfo[extraid][pVIPSold] = strval(szResult);
					cache_get_value_name(row,  "GoldBoxTokens", szResult); PlayerInfo[extraid][pGoldBoxTokens] = strval(szResult);
					cache_get_value_name(row,  "DrawChance", szResult); PlayerInfo[extraid][pRewardDrawChance] = strval(szResult);
					cache_get_value_name(row,  "RewardHours", szResult); PlayerInfo[extraid][pRewardHours] = floatstr(szResult);
					cache_get_value_name(row,  "CarsRestricted", szResult); PlayerInfo[extraid][pRVehRestricted] = strval(szResult);
					cache_get_value_name(row,  "LastCarWarning", szResult); PlayerInfo[extraid][pLastRVehWarn] = strval(szResult);
					cache_get_value_name(row,  "CarWarns", szResult); PlayerInfo[extraid][pRVehWarns] = strval(szResult);
					cache_get_value_name(row,  "Flagged", szResult); PlayerInfo[extraid][pFlagged] = strval(szResult);
					cache_get_value_name(row,  "Paper", szResult); PlayerInfo[extraid][pPaper] = strval(szResult);
					cache_get_value_name(row,  "MailEnabled", szResult); PlayerInfo[extraid][pMailEnabled] = strval(szResult);
					cache_get_value_name(row,  "Mailbox", szResult); PlayerInfo[extraid][pMailbox] = strval(szResult);
					cache_get_value_name(row,  "Business", szResult); PlayerInfo[extraid][pBusiness] = strval(szResult);
					cache_get_value_name(row,  "BusinessRank", szResult); PlayerInfo[extraid][pBusinessRank] = strval(szResult);
					cache_get_value_name(row,  "TreasureSkill", szResult); PlayerInfo[extraid][pTreasureSkill] = strval(szResult);
					cache_get_value_name(row,  "MetalDetector", szResult); PlayerInfo[extraid][pMetalDetector] = strval(szResult);
					cache_get_value_name(row,  "HelpedBefore", szResult); PlayerInfo[extraid][pHelpedBefore] = strval(szResult);
					cache_get_value_name(row,  "Trickortreat", szResult); PlayerInfo[extraid][pTrickortreat] = strval(szResult);
					cache_get_value_name(row,  "LastCharmReceived", szResult); PlayerInfo[extraid][pLastCharmReceived] = strval(szResult);
					cache_get_value_name(row,  "RHMutes", szResult); PlayerInfo[extraid][pRHMutes] = strval(szResult);
					cache_get_value_name(row,  "RHMuteTime", szResult); PlayerInfo[extraid][pRHMuteTime] = strval(szResult);
					cache_get_value_name(row,  "GiftCode", szResult); PlayerInfo[extraid][pGiftCode] = strval(szResult);
					cache_get_value_name(row,  "Table", szResult); PlayerInfo[extraid][pTable] = strval(szResult);
					cache_get_value_name(row,  "OpiumSeeds", szResult); PlayerInfo[extraid][pOpiumSeeds] = strval(szResult);
					cache_get_value_name(row,  "RawOpium", szResult); PlayerInfo[extraid][pRawOpium] = strval(szResult);
					cache_get_value_name(row,  "Heroin", szResult); PlayerInfo[extraid][pHeroin] = strval(szResult);
					cache_get_value_name(row,  "Syringe", szResult); PlayerInfo[extraid][pSyringes] = strval(szResult);
					cache_get_value_name(row,  "Skins", szResult); PlayerInfo[extraid][pSkins] = strval(szResult);
					cache_get_value_name(row,  "Hunger", szResult); PlayerInfo[extraid][pHunger] = strval(szResult);
					cache_get_value_name(row,  "HungerTimer", szResult); PlayerInfo[extraid][pHungerTimer] = strval(szResult);
					cache_get_value_name(row,  "HungerDeathTimer", szResult); PlayerInfo[extraid][pHungerDeathTimer] = strval(szResult);
					cache_get_value_name(row,  "Fitness", szResult); PlayerInfo[extraid][pFitness] = strval(szResult);
					cache_get_value_name(row,  "ForcePasswordChange", szResult); PlayerInfo[extraid][pForcePasswordChange] = strval(szResult);
					cache_get_value_name(row,  "Credits", szResult); PlayerInfo[extraid][pCredits] = strval(szResult);
					cache_get_value_name(row,  "HealthCare", szResult); PlayerInfo[extraid][pHealthCare] = strval(szResult);
					cache_get_value_name(row,  "TotalCredits", szResult); PlayerInfo[extraid][pTotalCredits] = strval(szResult);
					cache_get_value_name(row,  "ReceivedCredits", szResult); PlayerInfo[extraid][pReceivedCredits] = strval(szResult);
					cache_get_value_name(row,  "RimMod", szResult); PlayerInfo[extraid][pRimMod] = strval(szResult);
					cache_get_value_name(row,  "Tazer", szResult); PlayerInfo[extraid][pHasTazer] = strval(szResult);
					cache_get_value_name(row,  "Cuff", szResult); PlayerInfo[extraid][pHasCuff] = strval(szResult);
					cache_get_value_name(row,  "CarVoucher", szResult); PlayerInfo[extraid][pCarVoucher] = strval(szResult);
					cache_get_value_name(row,  "ReferredBy", PlayerInfo[extraid][pReferredBy], MAX_PLAYER_NAME);
					cache_get_value_name(row,  "PendingRefReward", szResult); PlayerInfo[extraid][pPendingRefReward] = strval(szResult);
					cache_get_value_name(row,  "Refers", szResult); PlayerInfo[extraid][pRefers] = strval(szResult);
					cache_get_value_name(row,  "Famed", szResult); PlayerInfo[extraid][pFamed] = strval(szResult);
					cache_get_value_name(row,  "FamedMuted", szResult); PlayerInfo[extraid][pFMuted] = strval(szResult);
					cache_get_value_name(row,  "DefendTime", szResult); PlayerInfo[extraid][pDefendTime] = strval(szResult);
					cache_get_value_name(row,  "VehicleSlot", szResult); PlayerInfo[extraid][pVehicleSlot] = strval(szResult);
					cache_get_value_name(row,  "PVIPVoucher", szResult); PlayerInfo[extraid][pPVIPVoucher] = strval(szResult);
					cache_get_value_name(row,  "ToySlot", szResult); PlayerInfo[extraid][pToySlot] = strval(szResult);
					cache_get_value_name(row,  "RFLTeam", szResult); PlayerInfo[extraid][pRFLTeam] = strval(szResult);
					cache_get_value_name(row,  "RFLTeamL", szResult); PlayerInfo[extraid][pRFLTeamL] = strval(szResult);
					cache_get_value_name(row,  "VehVoucher", szResult); PlayerInfo[extraid][pVehVoucher] = strval(szResult);
					cache_get_value_name(row,  "SVIPVoucher", szResult); PlayerInfo[extraid][pSVIPVoucher] = strval(szResult);
					cache_get_value_name(row,  "GVIPVoucher", szResult); PlayerInfo[extraid][pGVIPVoucher] = strval(szResult);
					cache_get_value_name(row,  "GiftVoucher", szResult); PlayerInfo[extraid][pGiftVoucher] = strval(szResult);
					cache_get_value_name(row,  "FallIntoFun", szResult); PlayerInfo[extraid][pFallIntoFun] = strval(szResult);
					cache_get_value_name(row,  "HungerVoucher", szResult); PlayerInfo[extraid][pHungerVoucher] = strval(szResult);
					cache_get_value_name(row,  "BoughtCure", szResult); PlayerInfo[extraid][pBoughtCure] = strval(szResult);
					cache_get_value_name(row,  "Vials", szResult); PlayerInfo[extraid][pVials] = strval(szResult);
					cache_get_value_name(row,  "AdvertVoucher", szResult); PlayerInfo[extraid][pAdvertVoucher] = strval(szResult);
					cache_get_value_name(row,  "ShopCounter", szResult); PlayerInfo[extraid][pShopCounter] = strval(szResult);
					cache_get_value_name(row,  "ShopNotice", szResult); PlayerInfo[extraid][pShopNotice] = strval(szResult);
					cache_get_value_name(row,  "SVIPExVoucher", szResult); PlayerInfo[extraid][pSVIPExVoucher] = strval(szResult);
					cache_get_value_name(row,  "GVIPExVoucher", szResult); PlayerInfo[extraid][pGVIPExVoucher] = strval(szResult);		
					cache_get_value_name(row,  "VIPSellable", szResult); PlayerInfo[extraid][pVIPSellable] = strval(szResult);	
					cache_get_value_name(row,  "ReceivedPrize", szResult); PlayerInfo[extraid][pReceivedPrize] = strval(szResult);
					cache_get_value_name(row,  "InventoryData", PlayerInfo[extraid][pInventoryData]);
					
					GetPartnerName(extraid);
					IsEmailPending(extraid, PlayerInfo[extraid][pId], PlayerInfo[extraid][pEmail]);

					if(PlayerInfo[extraid][pCredits] > 0)
					{
						new szLog[128];
						format(szLog, sizeof(szLog), "[LOGIN] [User: %s(%i)] [IP: %s] [Credits: %s]", GetPlayerNameEx(extraid), PlayerInfo[extraid][pId], GetPlayerIpEx(extraid), number_format(PlayerInfo[extraid][pCredits]));
						Log("logs/logincredits.log", szLog), print(szLog);
					}

					g_mysql_LoadPVehicles(extraid);
					g_mysql_LoadPlayerToys(extraid);
				
					SetPVarInt(extraid, "pSQLID", PlayerInfo[extraid][pId]);

					//g_mysql_LoadPVehiclePositions(extraid);
					OnPlayerLoad(extraid);
                	break;
				}
			}
			return 1;
		}
		case SENDDATA_THREAD:
		{
			if(GetPVarType(extraid, "RestartKick")) {
				gPlayerLogged{extraid} = 0;
				GameTextForPlayer(extraid, "Scheduled Maintenance...", 5000, 5);
				SendClientMessage(extraid, COLOR_LIGHTBLUE, "* The server will be going down for Scheduled Maintenance. A brief period of downtime will follow.");
				SendClientMessage(extraid, COLOR_GRAD2, "We will be going down to do some maintenance on the server/script, we will be back online shortly.");
				SetTimerEx("KickEx", 1000, false, "i", extraid);

				foreach(extraid: Player) if(gPlayerLogged{extraid}) {
					SetPVarInt(extraid, "RestartKick", 1);
					return OnPlayerStatsUpdate(extraid);
				}
				ABroadCast(COLOR_YELLOW, "{AA3333}He thong{FFFF00}: Tai khoan da duoc luu lai thanh cong!", 1);
				//g_mysql_DumpAccounts();

				SetTimer("FinishMaintenance", 1500, false);
			}
			if(GetPVarType(extraid, "AccountSaving") && (GetPVarInt(extraid, "AccountSaved") == 0)) {
				SetPVarInt(extraid, "AccountSaved", 1);
				foreach(extraid: Player)
				{
					if(gPlayerLogged{extraid} && (GetPVarInt(extraid, "AccountSaved") == 0))
					{
						SetPVarInt(extraid, "AccountSaving", 1);
						return OnPlayerStatsUpdate(extraid);
					}
				}
				ABroadCast(COLOR_YELLOW, "{AA3333}He thong{FFFF00}: Tai khoan da duoc luu lai thanh cong!", 1);
				print("Account Saving Complete");
				foreach(new i: Player)
				{
				    DeletePVar(i, "AccountSaved");
				    DeletePVar(i, "AccountSaving");
				}
				//g_mysql_DumpAccounts();
			}
			return 1;
		}
		case AUTH_THREAD:
        {
            new name[24];
            for(new i;i < rows;i++)
            {
                cache_get_value_name(i, "Username", name, MAX_PLAYER_NAME);
                if(strcmp(name, GetPlayerNameExt(extraid), true) == 0)
                {
                    SafeLogin(extraid, 1);
                    return 1;
                }
                else
                {
                    return 1;
                }
            }
            SafeLogin(extraid, 2);
            return 1;
        }

		 case LOGIN_THREAD:
        {
            for(new i;i < rows;i++)
            {
                new
                    szPass[129],
                    szResult[129],
                    szBuffer[129],
                    szEmail[256];
                cache_get_value_name(i, "Username", szResult);

                cache_get_value_name(i, "Email", szEmail);
                cache_get_value_name(i, "Key", szResult);
                GetPVarString(extraid, "PassAuth", szBuffer, sizeof(szBuffer));
                WP_Hash(szPass, sizeof(szPass), szBuffer);

                if(isnull(szEmail)) SetPVarInt(extraid, "NullEmail", 1);

                if((isnull(szPass)) || (isnull(szResult)) || (strcmp(szPass, szResult) != 0))
                {
                    PlayerTextDrawSetString(extraid,Login_Panel_PTD[extraid][3], ".........");
                    return 1;
                }
                DeletePVar(extraid, "PassAuth");
                break;
            }
            if(GetPVarInt(extraid,"TypeShowRegister") == 2) {
                g_mysql_LoadAccount(extraid);
            }
            SetPVarInt(extraid,"IsEnterAccount",1);
            return 1;
        }
		case REGISTER_THREAD:
        {
            if(IsPlayerConnected(extraid))
            {
                g_mysql_AccountLoginCheck(extraid);
                TotalRegister++;
            }
        }
		case LOADPTOYS_THREAD:
		{
			if(IsPlayerConnected(extraid))
			{
				new i = 0;
				while( i < rows)
				{
					if(i >= MAX_PLAYERTOYS)
						break;
					new szResult[32];
					
					cache_get_value_name(i, "id", szResult);
					PlayerToyInfo[extraid][i][ptID] = strval(szResult);
					
					cache_get_value_name(i, "modelid", szResult);
					PlayerToyInfo[extraid][i][ptModelID] = strval(szResult);
					
					if(PlayerToyInfo[extraid][i][ptModelID] != 0)
					{					
						cache_get_value_name(i, "bone", szResult);
						PlayerToyInfo[extraid][i][ptBone] = strval(szResult);
						
						if(PlayerToyInfo[extraid][i][ptBone] > 18 || PlayerToyInfo[extraid][i][ptBone] < 1) PlayerToyInfo[extraid][i][ptBone] = 1;
						
						cache_get_value_name(i, "tradable", szResult);
						PlayerToyInfo[extraid][i][ptTradable] = strval(szResult);
						
						cache_get_value_name(i, "posx", szResult);
						PlayerToyInfo[extraid][i][ptPosX] = floatstr(szResult);
						
						cache_get_value_name(i, "posy", szResult);
						PlayerToyInfo[extraid][i][ptPosY] = floatstr(szResult);
						
						cache_get_value_name(i, "posz", szResult);
						PlayerToyInfo[extraid][i][ptPosZ] = floatstr(szResult);
						
						cache_get_value_name(i, "rotx", szResult);
						PlayerToyInfo[extraid][i][ptRotX] = floatstr(szResult);
						
						cache_get_value_name(i, "roty", szResult);
						PlayerToyInfo[extraid][i][ptRotY] = floatstr(szResult);
						
						cache_get_value_name(i, "rotz", szResult);
						PlayerToyInfo[extraid][i][ptRotZ] = floatstr(szResult);
						
						cache_get_value_name(i, "scalex", szResult);
						PlayerToyInfo[extraid][i][ptScaleX] = floatstr(szResult);
						
						cache_get_value_name(i, "scaley", szResult);
						PlayerToyInfo[extraid][i][ptScaleY] = floatstr(szResult);
						
						cache_get_value_name(i, "scalez", szResult);
						PlayerToyInfo[extraid][i][ptScaleZ] = floatstr(szResult);
						
						cache_get_value_name(i, "special", szResult);
						PlayerToyInfo[extraid][i][ptSpecial] = strval(szResult);
						
						new szLog[128];
						format(szLog, sizeof(szLog), "[TOYSLOAD] [User: %s(%i)] [Toy Model ID: %d] [Toy ID]", GetPlayerNameEx(extraid), PlayerInfo[extraid][pId], PlayerToyInfo[extraid][i][ptModelID]);
						Log("logs/toydebug.log", szLog);
					}
					else
					{
						new szQuery[128];
						format(szQuery, sizeof(szQuery), "DELETE FROM `toys` WHERE `id` = '%d'", PlayerToyInfo[extraid][i][ptID]);
						mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "i", SENDDATA_THREAD);
						printf("Deleting Toy ID %d for Player %s (%i)", PlayerToyInfo[extraid][i][ptID], GetPlayerNameEx(extraid), GetPlayerSQLId(extraid));
					}
					i++;	
				}
			}		
		}			
		case LOADPVEHICLE_THREAD:
		{
			if(IsPlayerConnected(extraid))
			{
			    new i = 0;
				while(i < rows)
				{
				    if(i >= MAX_PLAYERVEHICLES)
						break;

				    new szResult[32];

					cache_get_value_name(i,  "pvModelId", szResult);
					PlayerVehicleInfo[extraid][i][pvModelId] = strval(szResult);
					
					cache_get_value_name(i, "id", szResult);
	    			PlayerVehicleInfo[extraid][i][pvSlotId] = strval(szResult);

					if(PlayerVehicleInfo[extraid][i][pvModelId] != 0)
					{
						cache_get_value_name(i,  "pvPosX", szResult);
						PlayerVehicleInfo[extraid][i][pvPosX] = floatstr(szResult);

						cache_get_value_name(i,  "pvPosY", szResult);
						PlayerVehicleInfo[extraid][i][pvPosY] = floatstr(szResult);

						cache_get_value_name(i,  "pvPosZ", szResult);
						PlayerVehicleInfo[extraid][i][pvPosZ] = floatstr(szResult);

						cache_get_value_name(i,  "pvPosAngle", szResult);
						PlayerVehicleInfo[extraid][i][pvPosAngle] = floatstr(szResult);

						cache_get_value_name(i,  "pvLock", szResult);
						PlayerVehicleInfo[extraid][i][pvLock] = strval(szResult);

						cache_get_value_name(i,  "pvLocked", szResult);
						PlayerVehicleInfo[extraid][i][pvLocked] = strval(szResult);

						cache_get_value_name(i,  "pvPaintJob", szResult);
						PlayerVehicleInfo[extraid][i][pvPaintJob] = strval(szResult);

						cache_get_value_name(i,  "pvColor1", szResult);
						PlayerVehicleInfo[extraid][i][pvColor1] = strval(szResult);

						cache_get_value_name(i,  "pvColor2", szResult);
						PlayerVehicleInfo[extraid][i][pvColor2] = strval(szResult);

						cache_get_value_name(i,  "pvPrice", szResult);
						PlayerVehicleInfo[extraid][i][pvPrice] = strval(szResult);

						cache_get_value_name(i,  "pvTicket", szResult);
						PlayerVehicleInfo[extraid][i][pvTicket] = strval(szResult);

						cache_get_value_name(i,  "pvRestricted", szResult);
						PlayerVehicleInfo[extraid][i][pvRestricted] = strval(szResult);

						cache_get_value_name(i,  "pvWeapon0", szResult);
						PlayerVehicleInfo[extraid][i][pvWeapons][0] = strval(szResult);

						cache_get_value_name(i,  "pvWeapon1", szResult);
						PlayerVehicleInfo[extraid][i][pvWeapons][1] = strval(szResult);

						cache_get_value_name(i,  "pvWeapon2", szResult);
						PlayerVehicleInfo[extraid][i][pvWeapons][2] = strval(szResult);

						cache_get_value_name(i,  "pvWepUpgrade", szResult);
						PlayerVehicleInfo[extraid][i][pvWepUpgrade] = strval(szResult);

						cache_get_value_name(i,  "pvFuel", szResult);
						PlayerVehicleInfo[extraid][i][pvFuel] = floatstr(szResult);

						cache_get_value_name(i,  "pvEngineUpgrade", szResult);
						PlayerVehicleInfo[extraid][i][pvEngineUpgrade] = strval(szResult);

						cache_get_value_name(i,  "pvImpound", szResult);
						PlayerVehicleInfo[extraid][i][pvImpounded] = strval(szResult);

						cache_get_value_name(i,  "pvPlate", szResult, 32);
						strcpy(PlayerVehicleInfo[extraid][i][pvPlate], szResult, 32);

						cache_get_value_name(i,  "pvVW", szResult);
						PlayerVehicleInfo[extraid][i][pvVW] = strval(szResult);

						cache_get_value_name(i,  "pvInt", szResult);
						PlayerVehicleInfo[extraid][i][pvInt] = strval(szResult);

						for(new m = 0; m < MAX_MODS; m++)
						{
		    				new szField[15];
							format(szField, sizeof(szField), "pvMod%d", m);
							cache_get_value_name(i, szField, szResult);
							PlayerVehicleInfo[extraid][i][pvMods][m] = strval(szResult);
						}
						
						cache_get_value_name(i,  "pvCrashFlag", szResult);
						PlayerVehicleInfo[extraid][i][pvCrashFlag] = strval(szResult);
						
						cache_get_value_name(i, "pvCrashVW", szResult);
						PlayerVehicleInfo[extraid][i][pvCrashVW] = strval(szResult);
						
						cache_get_value_name(i,  "pvCrashX", szResult);
						PlayerVehicleInfo[extraid][i][pvCrashX] = floatstr(szResult);
						
						cache_get_value_name(i,  "pvCrashY", szResult);
						PlayerVehicleInfo[extraid][i][pvCrashY] = floatstr(szResult);
						
						cache_get_value_name(i,  "pvCrashZ", szResult);
						PlayerVehicleInfo[extraid][i][pvCrashZ] = floatstr(szResult);
						
						cache_get_value_name(i,  "pvCrashAngle", szResult);
						PlayerVehicleInfo[extraid][i][pvCrashAngle] = floatstr(szResult);
						
						new szLog[128];
						format(szLog, sizeof(szLog), "[VEHICLELOAD] [User: %s(%i)] [Model: %d] [Vehicle ID: %d]", GetPlayerNameEx(extraid), PlayerInfo[extraid][pId], PlayerVehicleInfo[extraid][i][pvModelId], PlayerVehicleInfo[extraid][i][pvSlotId]);
						Log("logs/vehicledebug.log", szLog);
					}
					else
					{
						new query[128];
						format(query, sizeof(query), "DELETE FROM `vehicles` WHERE `id` = '%d'", PlayerVehicleInfo[extraid][i][pvSlotId]);
						mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, extraid);
					}
					i++;
				}
			}
		}
		case LOADPVEHPOS_THREAD:
		{
			if(IsPlayerConnected(extraid))
			{
				new bool:bVehRestore;
				for(new i;i < rows;i++)
				{
					bVehRestore = true;
					for(new v; v < MAX_PLAYERVEHICLES; v++)
					{
						new szResult[32], szPrefix[32], tmpVehModelId, Float:tmpVehArray[4];

						format(szPrefix, sizeof(szPrefix), "pv%dModelId", v);
						cache_get_value_name(i, szPrefix, szResult); tmpVehModelId = strval(szResult);
						format(szPrefix, sizeof(szPrefix), "pv%dPosX", v);
						cache_get_value_name(i, szPrefix, szResult); tmpVehArray[0] = floatstr(szResult);
						format(szPrefix, sizeof(szPrefix), "pv%dPosY", v);
						cache_get_value_name(i, szPrefix, szResult); tmpVehArray[1] = floatstr(szResult);
						format(szPrefix, sizeof(szPrefix), "pv%dPosZ", v);
						cache_get_value_name(i, szPrefix, szResult); tmpVehArray[2] = floatstr(szResult);
						format(szPrefix, sizeof(szPrefix), "pv%dPosAngle", v);
						cache_get_value_name(i, szPrefix, szResult); tmpVehArray[3] = floatstr(szResult);

						if(tmpVehModelId >= 400)
						{
							printf("Stored %d Vehicle Slot", v);

							format(szPrefix, sizeof(szPrefix), "tmpVeh%dModelId", v);
							SetPVarInt(extraid, szPrefix, tmpVehModelId);

							format(szPrefix, sizeof(szPrefix), "tmpVeh%dPosX", v);
							SetPVarFloat(extraid, szPrefix, tmpVehArray[0]);

							format(szPrefix, sizeof(szPrefix), "tmpVeh%dPosY", v);
							SetPVarFloat(extraid, szPrefix, tmpVehArray[1]);

							format(szPrefix, sizeof(szPrefix), "tmpVeh%dPosZ", v);
							SetPVarFloat(extraid, szPrefix, tmpVehArray[2]);

							format(szPrefix, sizeof(szPrefix), "tmpVeh%dAngle", v);
							SetPVarFloat(extraid, szPrefix, tmpVehArray[3]);
						}
					}
					break;
				}

				if(bVehRestore == true) {
					// person Vehicle Position Restore Granted, Now Purge them from the Table.
					new query[128];
					format(query, sizeof(query), "DELETE FROM `pvehpositions` WHERE `id`='%d'", PlayerInfo[extraid][pId]);
					mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, extraid);
				}

				OnPlayerLoad(extraid);
			}
		}
		case IPBAN_THREAD:
		{
		    if(rows > 0)
			{
				SendClientMessage(extraid, COLOR_RED, "IP cua ban bi cam truy cap, de mo khoa vui long truy cap dien dan forum.clbsamp.ga.");
				SetTimerEx("KickEx", 1000, false, "i", extraid);
			}
			else
			{
			    g_mysql_AccountAuthCheck(extraid);
			}
		}
		case LOADCRATE_THREAD:
		{
		    for(new i; i < rows; i++)
		    {
				new crateid, szResult[32], string[128];
				cache_get_value_name(i, "id", szResult); crateid = strval(szResult);
				if(crateid < MAX_CRATES)
		        {
					cache_get_value_name(i, "Active", szResult); CrateInfo[crateid][crActive] = strval(szResult);
					cache_get_value_name(i, "CrateX", szResult); CrateInfo[crateid][crX] = floatstr(szResult);
					cache_get_value_name(i, "CrateY", szResult); CrateInfo[crateid][crY] = floatstr(szResult);
					cache_get_value_name(i, "CrateZ", szResult); CrateInfo[crateid][crZ] = floatstr(szResult);
					cache_get_value_name(i, "Int", szResult); CrateInfo[crateid][crInt] = strval(szResult);
					cache_get_value_name(i, "VW", szResult); CrateInfo[crateid][crVW] = strval(szResult);
					cache_get_value_name(i, "PlacedBy", szResult); format(CrateInfo[crateid][crPlacedBy], MAX_PLAYER_NAME, szResult);
					cache_get_value_name(i, "GunQuantity", szResult); CrateInfo[crateid][GunQuantity] = strval(szResult);
					cache_get_value_name(i, "InVehicle", szResult); CrateInfo[crateid][InVehicle] = strval(szResult);
					if(CrateInfo[crateid][InVehicle] != INVALID_VEHICLE_ID)
					{
					    CrateInfo[crateid][crActive] = 0;
					    CrateInfo[crateid][InVehicle] = INVALID_VEHICLE_ID;
					}
					if(CrateInfo[crateid][crActive])
					{
						CrateInfo[crateid][InVehicle] = INVALID_VEHICLE_ID;
					    CrateInfo[crateid][crObject] = CreateDynamicObject(964,CrateInfo[crateid][crX],CrateInfo[crateid][crY],CrateInfo[crateid][crZ],0.00000000,0.00000000,0.00000000,CrateInfo[i][crVW], CrateInfo[i][crInt]);
					    format(string, sizeof(string), "Serial Number: #%d\n High Grade Materials: %d/50\n (( Dropped by: %s ))", i, CrateInfo[crateid][GunQuantity], CrateInfo[crateid][crPlacedBy]);
						CrateInfo[crateid][crLabel] = CreateDynamic3DTextLabel(string, COLOR_ORANGE, CrateInfo[crateid][crX],CrateInfo[crateid][crY],CrateInfo[crateid][crZ]+1, 10.0, _, _, 1, CrateInfo[crateid][crVW], CrateInfo[crateid][crInt], _, 20.0);

					}
				}
		    }
		    print("[LoadCrates] Loading Crates Finished");
		}
		case MAIN_REFERRAL_THREAD:
		{
		    new newrows, newfields, szString[128], szQuery[128];
		    cache_get_data(newrows, newfields);

		    if(newrows == 0)
		    {
		        format(szString, sizeof(szString), "Nobody");
				strmid(PlayerInfo[extraid][pReferredBy], szString, 0, strlen(szString), MAX_PLAYER_NAME);
		        ShowPlayerDialog(extraid, REGISTERREF, DIALOG_STYLE_INPUT, "{FF0000}Loi - Nguoi choi khong hop le", "Khong co nguoi choi dang ky tai may chu GVN voi ten nhu vay.\nVui long nhap ten day du nguoi choi da gioi thieu ban.\nVi du: Beo_cu, Long_Trieu", "Dong y", "Huy bo");
			}
			else {
			    format(szQuery, sizeof(szQuery), "SELECT `IP` FROM `accounts` WHERE `Username` = '%s'", PlayerInfo[extraid][pReferredBy]);
				mysql_pquery(MainPipeline, szQuery, "ReferralSecurity", "i", extraid);
			}
		}
		case REWARD_REFERRAL_THREAD:
		{
			new newrows, newfields;
			cache_get_data(newrows, newfields);

			if(newrows != 0)
			{
			    SendClientMessageEx(extraid, COLOR_YELLOW, "Nguoi choi da gioi thieu ban tham gia khong ton tai tren he thong GVN, vi vay ho se khong nhan duoc credits gioi thieu");
			}
		}
		case OFFLINE_FAMED_THREAD:
		{
		    new newrows, newfields, szQuery[128], string[128], szName[MAX_PLAYER_NAME];
		    cache_get_data(newrows, newfields);
		    
		    if(newrows == 0)
		    {
		        SendClientMessageEx(extraid, COLOR_RED, "Error - Tai khoan khong ton tai.");
		    }
		    else {
		        new
					ilevel = GetPVarInt(extraid, "Offline_Famed");

				GetPVarString(extraid, "Offline_Name", szName, MAX_PLAYER_NAME);
		        
		        format(szQuery, sizeof(szQuery), "UPDATE `accounts` SET `Famed` = %d WHERE `Username` = '%s'", ilevel, szName);
				mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "i", SENDDATA_THREAD);
				
				format(string, sizeof(string), "AdmCmd: %s has offline set %s to a level %d famed", GetPlayerNameEx(extraid), szName, ilevel);
				SendFamedMessage(COLOR_LIGHTRED, string);
				ABroadCast(COLOR_LIGHTRED, string, 2);
				Log("logs/setfamed.log", string);
				DeletePVar(extraid, "Offline_Famed");
				DeletePVar(extraid, "Offline_Name");
			}
		}
		case BUG_LIST_THREAD:
		{
			if(rows == 0) return 1;
			new szResult[MAX_PLAYER_NAME];
			for(new i; i < rows; i++)
		    {
				cache_get_value_name(i, "Username", szResult); SendClientMessageEx(extraid, COLOR_GRAD2, szResult);
			}
		}
		case LOADGIFTBOX_THREAD:
		{
			for(new i; i < rows; i++)
			{
				new szResult[32], arraystring[128];
				for(new array = 0; array < 4; array++)
				{
					format(arraystring, sizeof(arraystring), "dgMoney%d", array);
					cache_get_value_name(i, arraystring, szResult); dgMoney[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgRimKit%d", array);
					cache_get_value_name(i, arraystring, szResult); dgRimKit[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgFirework%d", array);
					cache_get_value_name(i, arraystring, szResult); dgFirework[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgGVIP%d", array);
					cache_get_value_name(i, arraystring, szResult); dgGVIP[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgSVIP%d", array);
					cache_get_value_name(i, arraystring, szResult); dgSVIP[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgGVIPEx%d", array);
					cache_get_value_name(i, arraystring, szResult); dgGVIPEx[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgSVIPEx%d", array);
					cache_get_value_name(i, arraystring, szResult); dgSVIPEx[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgCarSlot%d", array);
					cache_get_value_name(i, arraystring, szResult); dgCarSlot[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgToySlot%d", array);
					cache_get_value_name(i, arraystring, szResult); dgToySlot[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgArmor%d", array);
					cache_get_value_name(i, arraystring, szResult); dgArmor[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgFirstaid%d", array);
					cache_get_value_name(i, arraystring, szResult); dgFirstaid[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgDDFlag%d", array);
					cache_get_value_name(i, arraystring, szResult); dgDDFlag[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgGateFlage%d", array);
					cache_get_value_name(i, arraystring, szResult); dgGateFlag[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgCredits%d", array);
					cache_get_value_name(i, arraystring, szResult); dgCredits[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgPriorityAd%d", array);
					cache_get_value_name(i, arraystring, szResult); dgPriorityAd[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgHealthNArmor%d", array);
					cache_get_value_name(i, arraystring, szResult); dgHealthNArmor[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgGiftReset%d", array);
					cache_get_value_name(i, arraystring, szResult); dgGiftReset[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgMaterial%d", array);
					cache_get_value_name(i, arraystring, szResult); dgMaterial[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgWarning%d", array);
					cache_get_value_name(i, arraystring, szResult); dgWarning[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgPot%d", array);
					cache_get_value_name(i, arraystring, szResult); dgPot[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgCrack%d", array);
					cache_get_value_name(i, arraystring, szResult); dgCrack[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgPaintballToken%d", array);
					cache_get_value_name(i, arraystring, szResult); dgPaintballToken[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgVIPToken%d", array);
					cache_get_value_name(i, arraystring, szResult); dgVIPToken[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgRespectPoint%d", array);
					cache_get_value_name(i, arraystring, szResult); dgRespectPoint[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgCarVoucher%d", array);
					cache_get_value_name(i, arraystring, szResult); dgCarVoucher[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgBuddyInvite%d", array);
					cache_get_value_name(i, arraystring, szResult); dgBuddyInvite[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgLaser%d", array);
					cache_get_value_name(i, arraystring, szResult); dgLaser[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgCustomToy%d", array);
					cache_get_value_name(i, arraystring, szResult); dgCustomToy[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgAdmuteReset%d", array);
					cache_get_value_name(i, arraystring, szResult); dgAdmuteReset[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgNewbieMuteReset%d", array);
					cache_get_value_name(i, arraystring, szResult); dgNewbieMuteReset[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgRestrictedCarVoucher%d", array);
					cache_get_value_name(i, arraystring, szResult); dgRestrictedCarVoucher[array] = strval(szResult);
					format(arraystring, sizeof(arraystring), "dgPlatinumVIPVoucher%d", array);
					cache_get_value_name(i, arraystring, szResult); dgPlatinumVIPVoucher[array] = strval(szResult);
				}
				break;
			}
			print("[Dynamic Giftbox] da tai thanh cong Dynamic giftbox.");
		}
		case LOADCP_STORE:
		{
			if(IsPlayerConnected(extraid))
			{
				new szResult[32];
				for(new i; i < rows; i++)
				{
					cache_get_value_name(i, "User_Id", szResult);
					
					if(rows > 0)
					{
						cache_get_value_name(i, "id", szResult); CpStore[extraid][cId] = strval(szResult);
						cache_get_value_name(i, "XP", szResult); CpStore[extraid][cXP] = strval(szResult);
						// now lets process the data below to give to the player.
						ClaimShopItems(extraid);
					}
				}
				if(rows == 0)
				{
					SendClientMessageEx(extraid, COLOR_RED, "You have no items pending from the user control panel.");
				}
			}
			return 1;
		}
	}
	return 1;
}

public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle)
{
	printf("[MySQL] Query Error - (ErrorID: %d) (Handle: %d)",  errorid, _:handle);
	print("[MySQL] Check mysql_log.txt to review the query that threw the error.");
	SQL_Log(query, error);

	if(errorid == 2013 || errorid == 2014 || errorid == 2006 || errorid == 2027 || errorid == 2055)
	{
		print("[MySQL] Connection Error Detected in Threaded Query");
		//mysql_query(query, resultid, extraid);
	}
}

//--------------------------------[ CUSTOM STOCK FUNCTIONS ]---------------------------

// g_mysql_Check_Store(playerid)
// Description: Checks if the player has any pending items from the ucp.
stock g_mysql_Check_Store(playerid)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `cp_store` WHERE `User_Id` = %d", GetPlayerSQLId(playerid));
 	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", LOADCP_STORE, playerid, g_arrQueryHandle{playerid});
	return 1;
}

// g_mysql_ReturnEscaped(string unEscapedString)
// Description: Takes a unescaped string and returns an escaped one.
stock g_mysql_ReturnEscaped(const unEscapedString[], MySQL:connectionHandle = MYSQL_INVALID_HANDLE)
{
	new EscapedString[256];
	mysql_real_escape_string(unEscapedString, EscapedString, connectionHandle);
	return EscapedString;
}

// g_mysql_AccountLoginCheck(playerid)
stock g_mysql_AccountLoginCheck(playerid)
{
	new string[128];

	format(string, sizeof(string), "SELECT `Username`,`Key`,`Email` from accounts WHERE Username = '%s'", GetPlayerNameExt(playerid));
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", LOGIN_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}

// g_mysql_AccountAuthCheck(playerid)
g_mysql_AccountAuthCheck(playerid)
{
	new string[128];

	format(string, sizeof(string), "SELECT `Username` FROM `accounts` WHERE `Username` = '%s'", GetPlayerNameExt(playerid));
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", AUTH_THREAD, playerid, g_arrQueryHandle{playerid});

	// Reset the GUI
	SetPlayerJoinCamera(playerid);
	ClearChatbox(playerid);
	SetPlayerVirtualWorld(playerid, 0);


	return 1;
}

// g_mysql_AccountOnline(int playerid, int stateid)
stock g_mysql_AccountOnline(playerid, stateid)
{
	new string[128];
	format(string, sizeof(string), "UPDATE `accounts` SET `Online`=%d, `LastLogin` = NOW() WHERE `id` = %d", stateid, GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);
	return 1;
}

stock g_mysql_AccountOnlineReset()
{
	new string[128];
	print("[MySQL] Resetting online status for server restart...");
	format(string, sizeof(string), "UPDATE `accounts` SET `Online` = 0 WHERE `Online` = %d", servernumber);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

// g_mysql_CreateAccount(int playerid, string accountPassword[])
// Description: Creates a new account in the database.
stock g_mysql_CreateAccount(playerid, const accountPassword[])
{
	new string[256];
	new passbuffer[129];
	WP_Hash(passbuffer, sizeof(passbuffer), accountPassword);

	format(string, sizeof(string), "INSERT INTO `accounts` (`RegiDate`, `LastLogin`, `Username`, `Key`, `InventoryData`) VALUES (NOW(), NOW(), '%s','%s', '')", GetPlayerNameExt(playerid), passbuffer);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", REGISTER_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}

stock g_mysql_LoadPVehicles(playerid)
{
    new string[128];
	format(string, sizeof(string), "SELECT * FROM `vehicles` WHERE `sqlID` = %d", PlayerInfo[playerid][pId]);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", LOADPVEHICLE_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}

// g_mysql_LoadPVehiclePositions(playerid)
// Description: Loads vehicle positions if person has timed out.
stock g_mysql_LoadPVehiclePositions(playerid)
{
	new string[128];

	format(string, sizeof(string), "SELECT * FROM `pvehpositions` WHERE `id` = %d", PlayerInfo[playerid][pId]);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", LOADPVEHPOS_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}

// g_mysql_LoadPlayerToys(playerid)
// Description: Load the player toys
stock g_mysql_LoadPlayerToys(playerid)
{
	new szQuery[128];
	format(szQuery, sizeof(szQuery), "SELECT * FROM `toys` WHERE `player` = %d", PlayerInfo[playerid][pId]);
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "iii", LOADPTOYS_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}	

// g_mysql_LoadAccount(playerid)
// Description: Loads an account from database into memory.
stock g_mysql_LoadAccount(playerid)
{
	new string[164];
	format(string, sizeof(string), "SELECT * FROM `accounts` WHERE `Username` = '%s'", GetPlayerNameExt(playerid));
 	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", LOADUSERDATA_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}

// g_mysql_RemoveDumpFile(sqlid)
// Description: Removes a account's dump file. Helpful upon logoff.
stock g_mysql_RemoveDumpFile(sqlid)
{
	new pwnfile[128];
	format(pwnfile, sizeof(pwnfile), "/accdump/%d.dump", sqlid);

	if(fexist(pwnfile))
	{
		fremove(pwnfile);
		return 1;
	}
	return 0;
}

GivePlayerCredits(Player, Amount, Shop)
{
	new szQuery[128];
	PlayerInfo[Player][pCredits] += Amount;

	format(szQuery, sizeof(szQuery), "UPDATE `accounts` SET `Credits`=%d WHERE `id` = %d", PlayerInfo[Player][pCredits], GetPlayerSQLId(Player));
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, Player);
	print(szQuery);

	if(Shop == 1)
	{
    	if(Amount < 0) Amount = Amount*-1;
		PlayerInfo[Player][pTotalCredits] += Amount;
	}

	format(szQuery, sizeof(szQuery), "UPDATE `accounts` SET `TotalCredits`=%d WHERE `id` = %d", PlayerInfo[Player][pTotalCredits], GetPlayerSQLId(Player));
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, Player);
	print(szQuery);
}

// g_mysql_SaveVehicle(int playerid, int slotid)
// Description: Saves a account's specified vehicle slot.
stock g_mysql_SaveVehicle(playerid, slotid)
{
	new query[2048];
	printf("%s (%i) saving their %d (slot %i) (Model %i) (Engine %d)", GetPlayerNameEx(playerid), playerid, PlayerVehicleInfo[playerid][slotid][pvModelId], slotid, PlayerVehicleInfo[playerid][slotid][pvModelId],PlayerVehicleInfo[playerid][slotid][pvEngineUpgrade]);

	format(query, sizeof(query), "UPDATE `vehicles` SET");
	format(query, sizeof(query), "%s `pvPosX` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvPosX]);
	format(query, sizeof(query), "%s `pvPosY` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvPosY]);
	format(query, sizeof(query), "%s `pvPosZ` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvPosZ]);
	format(query, sizeof(query), "%s `pvPosAngle` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvPosAngle]);
	format(query, sizeof(query), "%s `pvLock` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvLock]);
	format(query, sizeof(query), "%s `pvLocked` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvLocked]);
	format(query, sizeof(query), "%s `pvPaintJob` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvPaintJob]);
	format(query, sizeof(query), "%s `pvColor1` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvColor1]);
	format(query, sizeof(query), "%s `pvColor2` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvColor2]);
	format(query, sizeof(query), "%s `pvPrice` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvPrice]);
	format(query, sizeof(query), "%s `pvWeapon0` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvWeapons][0]);
	format(query, sizeof(query), "%s `pvWeapon1` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvWeapons][1]);
	format(query, sizeof(query), "%s `pvWeapon2` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvWeapons][2]);
	format(query, sizeof(query), "%s `pvLock` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvLock]);
	format(query, sizeof(query), "%s `pvWepUpgrade` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvWepUpgrade]);
	format(query, sizeof(query), "%s `pvFuel` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvFuel]);
	format(query, sizeof(query), "%s `pvEngineUpgrade` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvEngineUpgrade]);
	format(query, sizeof(query), "%s `pvImpound` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvImpounded]);
	format(query, sizeof(query), "%s `pvDisabled` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvDisabled]);
	format(query, sizeof(query), "%s `pvPlate` = '%s',", query, g_mysql_ReturnEscaped(PlayerVehicleInfo[playerid][slotid][pvPlate], MainPipeline));
	format(query, sizeof(query), "%s `pvTicket` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvTicket]);
	format(query, sizeof(query), "%s `pvRestricted` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvRestricted]);
	format(query, sizeof(query), "%s `pvVW` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvVW]);
	format(query, sizeof(query), "%s `pvInt` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvInt]);
	format(query, sizeof(query), "%s `pvCrashFlag` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvCrashFlag]);
	format(query, sizeof(query), "%s `pvCrashVW` = %d,", query, PlayerVehicleInfo[playerid][slotid][pvCrashVW]);
	format(query, sizeof(query), "%s `pvCrashX` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvCrashX]);
	format(query, sizeof(query), "%s `pvCrashY` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvCrashY]);
	format(query, sizeof(query), "%s `pvCrashZ` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvCrashZ]);
	format(query, sizeof(query), "%s `pvCrashAngle` = %0.5f,", query, PlayerVehicleInfo[playerid][slotid][pvCrashAngle]);

	for(new m = 0; m < MAX_MODS; m++)
	{
		if(m == MAX_MODS-1)
		{
			format(query, sizeof(query), "%s `pvMod%d` = %d WHERE `id` = '%d'", query, m, PlayerVehicleInfo[playerid][slotid][pvMods][m], PlayerVehicleInfo[playerid][slotid][pvSlotId]);
		}
		else
		{
			format(query, sizeof(query), "%s `pvMod%d` = %d,", query, m, PlayerVehicleInfo[playerid][slotid][pvMods][m]);
		}
	}
    //print(query);

	new szLog[128];
	format(szLog, sizeof(szLog), "[VEHICLESAVE] [User: %s(%i)] [Model: %d] [Vehicle ID: %d]", GetPlayerNameEx(playerid), PlayerInfo[playerid][pId], PlayerVehicleInfo[playerid][slotid][pvModelId], PlayerVehicleInfo[playerid][slotid][pvSlotId]);
	Log("logs/vehicledebug.log", szLog);
	
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);
}

// native g_mysql_SaveToys(int playerid, int slotid)
stock g_mysql_SaveToys(playerid, slotid)
{
	new szQuery[2048];
	
	if(PlayerToyInfo[playerid][slotid][ptID] >= 1) // Making sure the player actually has a toy so we won't save a empty row
	{		
		format(szQuery, sizeof(szQuery), "UPDATE `toys` SET `modelid` = '%d', `bone` = '%d', `posx` = '%f', `posy` = '%f', `posz` = '%f', `rotx` = '%f', `roty` = '%f', `rotz` = '%f', `scalex` = '%f', `scaley` = '%f', `scalez` = '%f', `tradable` = '%d' WHERE `id` = '%d'",
		PlayerToyInfo[playerid][slotid][ptModelID], 
		PlayerToyInfo[playerid][slotid][ptBone], 
		PlayerToyInfo[playerid][slotid][ptPosX], 
		PlayerToyInfo[playerid][slotid][ptPosY], 
		PlayerToyInfo[playerid][slotid][ptPosZ], 
		PlayerToyInfo[playerid][slotid][ptRotX], 
		PlayerToyInfo[playerid][slotid][ptRotY], 
		PlayerToyInfo[playerid][slotid][ptRotZ], 
		PlayerToyInfo[playerid][slotid][ptScaleX], 
		PlayerToyInfo[playerid][slotid][ptScaleY], 
		PlayerToyInfo[playerid][slotid][ptScaleZ],
		PlayerToyInfo[playerid][slotid][ptTradable],
		PlayerToyInfo[playerid][slotid][ptID]);
		
		mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);
	}	
}

// native g_mysql_NewToy(int playerid, int slotid)
stock g_mysql_NewToy(playerid, slotid)
{
	new szQuery[2048];
	if(PlayerToyInfo[playerid][slotid][ptSpecial] != 1) { PlayerToyInfo[playerid][slotid][ptSpecial] = 0; }
	
	format(szQuery, sizeof(szQuery), "INSERT INTO `toys` (player, modelid, bone, posx, posy, posz, rotx, roty, rotz, scalex, scaley, scalez, tradable, special) VALUES ('%d', '%d', '%d', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%d', '%d')",
	PlayerInfo[playerid][pId],
	PlayerToyInfo[playerid][slotid][ptModelID], 
	PlayerToyInfo[playerid][slotid][ptBone], 
	PlayerToyInfo[playerid][slotid][ptPosX], 
	PlayerToyInfo[playerid][slotid][ptPosY], 
	PlayerToyInfo[playerid][slotid][ptPosZ], 
	PlayerToyInfo[playerid][slotid][ptRotX], 
	PlayerToyInfo[playerid][slotid][ptRotY], 
	PlayerToyInfo[playerid][slotid][ptRotZ], 
	PlayerToyInfo[playerid][slotid][ptScaleX], 
	PlayerToyInfo[playerid][slotid][ptScaleY], 
	PlayerToyInfo[playerid][slotid][ptScaleZ],
	PlayerToyInfo[playerid][slotid][ptTradable],
	PlayerToyInfo[playerid][slotid][ptSpecial]);
		
	mysql_pquery(MainPipeline, szQuery, "OnQueryCreateToy", "ii", playerid, slotid);	
}				

// g_mysql_LoadMOTD()
// Description: Loads the MOTDs from the MySQL Database.
stock g_mysql_LoadMOTD()
{
	print("[MySQL] Loading MOTD data...");
	mysql_pquery(MainPipeline, "SELECT `gMOTD`,`aMOTD`,`vMOTD`,`cMOTD`,`pMOTD`,`ShopTechPay`,`GiftCode`,`GiftCodeBypass`,`TotalCitizens`,`TRCitizens`,`SecurityCode`,`ShopClosed`,`RimMod`,`CarVoucher`,`PVIPVoucher`, `GarageVW`, `PumpkinStock`, `HalloweenShop` FROM `misc` LIMIT 1", "OnQueryFinish", "iii", LOADMOTDDATA_THREAD, INVALID_PLAYER_ID, -1);
}

stock g_mysql_LoadSales()
{
	mysql_pquery(MainPipeline, "SELECT * FROM `sales` WHERE `Month` > NOW() - INTERVAL 1 MONTH", "OnQueryFinish", "iii", LOADSALEDATA_THREAD, INVALID_PLAYER_ID, -1);
	//mysql_pquery(MainPipeline, "SELECT `TotalToySales`,`TotalCarSales`,`GoldVIPSales`,`SilverVIPSales`,`BronzeVIPSales` FROM `sales` WHERE `Month` > NOW() - INTERVAL 1 MONTH", "OnQueryFinish", "iii", LOADSALEDATA_THREAD, INVALID_PLAYER_ID, -1);
}

stock g_mysql_LoadPrices()
{
    mysql_pquery(MainPipeline, "SELECT * FROM `shopprices`", "OnQueryFinish", "iii", LOADSHOPDATA_THREAD, INVALID_PLAYER_ID, -1);
}

g_mysql_SavePrices()
{
	new query[2000];
	format(query, sizeof(query), "UPDATE `shopprices` SET `Price0` = '%d', `Price1` = '%d', `Price2` = '%d', `Price3` = '%d', `Price4` = '%d', `Price5` = '%d', `Price6` = '%d', `Price7` = '%d', `Price8` = '%d', `Price9` = '%d', `Price10` = '%d', \
	`Price11` = '%d', `Price12` = '%d', `Price13` = '%d', `Price14` = '%d', `Price15` = '%d', `Price16` = '%d', `Price17` = '%d',", ShopItems[0][sItemPrice], ShopItems[1][sItemPrice], ShopItems[2][sItemPrice], ShopItems[3][sItemPrice], ShopItems[4][sItemPrice],
	 ShopItems[5][sItemPrice], ShopItems[6][sItemPrice], ShopItems[7][sItemPrice], ShopItems[8][sItemPrice], ShopItems[9][sItemPrice], ShopItems[10][sItemPrice], ShopItems[11][sItemPrice], ShopItems[12][sItemPrice], ShopItems[13][sItemPrice], ShopItems[14][sItemPrice], ShopItems[15][sItemPrice],
  	ShopItems[16][sItemPrice], ShopItems[17][sItemPrice]);
	format(query, sizeof(query), "%s `Price18` = '%d', `Price19` = '%d', `Price20` = '%d', `Price21` = '%d', `Price22` = '%d', `Price23` = '%d', `Price24` = '%d', `Price25` = '%d', `Price26` = '%d', `Price27` = '%d', `Price28` = '%d'", query, ShopItems[18][sItemPrice], ShopItems[19][sItemPrice], ShopItems[20][sItemPrice], ShopItems[21][sItemPrice],
	ShopItems[22][sItemPrice], ShopItems[23][sItemPrice], ShopItems[24][sItemPrice], ShopItems[25][sItemPrice], ShopItems[26][sItemPrice], ShopItems[27][sItemPrice], ShopItems[28][sItemPrice]);
    mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock g_mysql_SaveMOTD()
{
	new query[1024];

	format(query, sizeof(query), "UPDATE `misc` SET ");

	format(query, sizeof(query), "%s `gMOTD` = '%s',", query, g_mysql_ReturnEscaped(GlobalMOTD, MainPipeline));
	format(query, sizeof(query), "%s `aMOTD` = '%s',", query, g_mysql_ReturnEscaped(AdminMOTD, MainPipeline));
	format(query, sizeof(query), "%s `vMOTD` = '%s',", query, g_mysql_ReturnEscaped(VIPMOTD, MainPipeline));
	format(query, sizeof(query), "%s `cMOTD` = '%s',", query, g_mysql_ReturnEscaped(CAMOTD, MainPipeline));
	format(query, sizeof(query), "%s `pMOTD` = '%s',", query, g_mysql_ReturnEscaped(pMOTD, MainPipeline));
	format(query, sizeof(query), "%s `ShopTechPay` = '%.2f',", query, ShopTechPay);
	format(query, sizeof(query), "%s `GiftCode` = '%s',", query, g_mysql_ReturnEscaped(GiftCode, MainPipeline));
	format(query, sizeof(query), "%s `GiftCodeBypass` = '%d',", query, GiftCodeBypass);
	format(query, sizeof(query), "%s `TotalCitizens` = '%d',", query, TotalCitizens);
	format(query, sizeof(query), "%s `TRCitizens` = '%d',", query, TRCitizens);
	format(query, sizeof(query), "%s `ShopClosed` = '%d',", query, ShopClosed);
	format(query, sizeof(query), "%s `RimMod` = '%d',", query, RimMod);
	format(query, sizeof(query), "%s `CarVoucher` = '%d',", query, CarVoucher);
	format(query, sizeof(query), "%s `PVIPVoucher` = '%d',", query, PVIPVoucher);
	format(query, sizeof(query), "%s `GarageVW` = '%d',", query, GarageVW);
	format(query, sizeof(query), "%s `PumpkinStock` = '%d',", query, PumpkinStock);
	format(query, sizeof(query), "%s `HalloweenShop` = '%d'", query, HalloweenShop);

	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
}

// g_mysql_LoadMOTD()
// Description: Loads the Crates from the MySQL Database.
stock mysql_LoadCrates()
{
	mysql_pquery(MainPipeline, "SELECT * FROM `crates`", "OnQueryFinish", "iii", LOADCRATE_THREAD, INVALID_PLAYER_ID, -1);
    print("[LoadCrates] Load Query Sent");
}

stock mysql_SaveCrates()
{
	new query[1024];
	for(new i; i < MAX_CRATES; i++)
	{
		printf("Saving Crate %d", i);
		format(query, sizeof(query), "UPDATE `crates` SET ");

		format(query, sizeof(query), "%s `Active` = '%d',", query, CrateInfo[i][crActive]);
		format(query, sizeof(query), "%s `CrateX` = '%.2f',", query, CrateInfo[i][crX]);
		format(query, sizeof(query), "%s `CrateY` = '%.2f',", query, CrateInfo[i][crY]);
		format(query, sizeof(query), "%s `CrateZ` = '%.2f',", query, CrateInfo[i][crZ]);
		format(query, sizeof(query), "%s `GunQuantity` = '%d',", query, CrateInfo[i][GunQuantity]);
		format(query, sizeof(query), "%s `InVehicle` = '%d',", query, CrateInfo[i][InVehicle]);
		format(query, sizeof(query), "%s `Int` = '%d',", query, CrateInfo[i][crInt]);
		format(query, sizeof(query), "%s `VW` = '%d',", query, CrateInfo[i][crVW]);
		format(query, sizeof(query), "%s `PlacedBy` = '%s'", query, CrateInfo[i][crPlacedBy]);
		format(query, sizeof(query), "%s WHERE id = %d", query, i);

		mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	}
}

stock RemoveBan(Player, Ip[])
{
	new string[128];
	SetPVarString(Player, "UnbanIP", Ip);
	format(string, sizeof(string), "SELECT `ip` FROM `ip_bans` WHERE `ip` = '%s'", Ip);
	mysql_pquery(MainPipeline, string, "AddingBan", "ii", Player, 2);
	return 1;
}

stock CheckBanEx(playerid)
{
	new string[60];
	format(string, sizeof(string), "SELECT `ip` FROM `ip_bans` WHERE `ip` = '%s'", GetPlayerIpEx(playerid));
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", IPBAN_THREAD, playerid, g_arrQueryHandle{playerid});
	return 1;
}

stock AddBan(Admin, Player, const Reason[])
{
    new string[128];
	SetPVarInt(Admin, "BanningPlayer", Player);
	SetPVarString(Admin, "BanningReason", Reason);
	format(string, sizeof(string), "SELECT `ip` FROM `ip_bans` WHERE `ip` = '%s'", GetPlayerIpEx(Player));
	mysql_pquery(MainPipeline, string, "AddingBan", "ii", Admin, 1);
	return 1;
}


stock SystemBan(Player, const Reason[])
{
	new string[150];
    format(string, sizeof(string), "INSERT INTO `ip_bans` (`ip`, `date`, `reason`, `admin`) VALUES ('%s', NOW(), '%s', 'System')", GetPlayerIpEx(Player), Reason);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}


stock MySQLBan(userid, const ip[], const reason[], status, const admin[])
{
	new string[200];
    format(string, sizeof(string), "INSERT INTO `bans` (`user_id`, `ip_address`, `reason`, `date_added`, `status`, `admin`) VALUES ('%d','%s','%s', NOW(), '%d','%s')", userid,ip,reason,status,admin);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock AddCrime(cop, suspect, const crime[])
{
	new query[256];
	format(query, sizeof(query), "INSERT INTO `mdc` (`id` ,`time` ,`issuer` ,`crime`) VALUES ('%d',NOW(),'%s','%s')", GetPlayerSQLId(suspect), g_mysql_ReturnEscaped(GetPlayerNameEx(cop), MainPipeline), g_mysql_ReturnEscaped(crime, MainPipeline));
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	format(query, sizeof(query), "MDC: %s added crime %s to %s.", GetPlayerNameEx(cop), crime, GetPlayerNameEx(suspect));
	Log("logs/crime.log", query);
	return 1;
}

stock ClearCrimes(playerid)
{
	new query[80];
	format(query, sizeof(query), "UPDATE `mdc` SET `active`=0 WHERE `id` = %i AND `active` = 1", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock DisplayCrimes(playerid, suspectid)
{
    new query[128];
    format(query, sizeof(query), "SELECT issuer, crime, active FROM `mdc` WHERE id=%d ORDER BY `time` AND `active` DESC LIMIT 12", GetPlayerSQLId(suspectid));
    mysql_pquery(MainPipeline, query, "MDCQueryFinish", "ii", playerid, suspectid);
	return 1;
}

stock DisplayReports(playerid, suspectid)
{
    new query[812];
    format(query, sizeof(query), "SELECT arrestreports.id, copid, shortreport, datetime, accounts.id, accounts.Username FROM `arrestreports` LEFT JOIN `accounts` ON	arrestreports.copid=accounts.id WHERE arrestreports.suspectid=%d ORDER BY arrestreports.datetime DESC LIMIT 12", GetPlayerSQLId(suspectid));
    mysql_pquery(MainPipeline, query, "MDCReportsQueryFinish", "ii", playerid, suspectid);
	return 1;
}

stock DisplayReport(playerid, reportid)
{
    new query[812];
    format(query, sizeof(query), "SELECT arrestreports.id, copid, shortreport, datetime, accounts.id, accounts.Username FROM `arrestreports` LEFT JOIN `accounts` ON	arrestreports.copid=accounts.id WHERE arrestreports.id=%d ORDER BY arrestreports.datetime DESC LIMIT 12", reportid);
    mysql_pquery(MainPipeline, query, "MDCReportQueryFinish", "ii", playerid, reportid);
	return 1;
}

stock SetUnreadMailsNotification(playerid)
{
    new query[128];
    format(query, sizeof(query), "SELECT COUNT(*) AS Unread_Count FROM letters WHERE Receiver_ID = %d AND `Read` = 0", GetPlayerSQLId(playerid));
    mysql_pquery(MainPipeline, query, "UnreadMailsNotificationQueryFin", "i", playerid);
	return 1;
}

stock DisplayMails(playerid)
{
    new query[150];
    format(query, sizeof(query), "SELECT `Id`, `Message`, `Read` FROM `letters` WHERE `Receiver_Id` = %d AND `Delivery_Min` = 0 ORDER BY `Id` DESC LIMIT 50", GetPlayerSQLId(playerid));
    mysql_pquery(MainPipeline, query, "MailsQueryFinish", "i", playerid);
}

stock DisplayMailDetails(playerid, letterid)
{
    new query[256];
    format(query, sizeof(query), "SELECT `Id`, `Date`, `Sender_Id`, `Read`, `Notify`, `Message`, (SELECT `Username` FROM `accounts` WHERE `id` = letters.Sender_Id) AS `SenderUser` FROM `letters` WHERE id = %d", letterid);
    mysql_pquery(MainPipeline, query, "MailDetailsQueryFinish", "i", playerid);
}

stock CountFlags(playerid)
{
	new query[80];
	format(query, sizeof(query), "SELECT * FROM `flags` WHERE id=%d", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "FlagQueryFinish", "iii", playerid, INVALID_PLAYER_ID, Flag_Query_Count);
	return 1;
}

stock AddFlag(playerid, adminid, const flag[])
{
	new query[300];
	new admin[24];
	if(adminid != INVALID_PLAYER_ID) {
		format(admin, sizeof(admin), "%s", GetPlayerNameEx(adminid));
	}
	else {
		format(admin, sizeof(admin), "Gifted/Script Added");
	}
	PlayerInfo[playerid][pFlagged]++;
	format(query, sizeof(query), "INSERT INTO `flags` (`id` ,`time` ,`issuer` ,`flag`) VALUES ('%d',NOW(),'%s','%s')", GetPlayerSQLId(playerid), g_mysql_ReturnEscaped(admin, MainPipeline), g_mysql_ReturnEscaped(flag, MainPipeline));
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	format(query, sizeof(query), "FLAG: %s added flag %s to %s.", admin, flag, GetPlayerNameEx(playerid));
	Log("logs/flags.log", query);
	return 1;
}

stock AddOFlag(sqlid, adminid, flag[]) // offline add
{
	new query[300];
	new admin[24], name[24];
	if(adminid != INVALID_PLAYER_ID) {
		format(admin, sizeof(admin), "%s", GetPlayerNameEx(adminid));
	}
	else {
		format(admin, sizeof(admin), "Gifted/Script Added");
	}
	GetPVarString(adminid, "OnAddFlag", name, sizeof(name));
	format(query, sizeof(query), "INSERT INTO `flags` (`id` ,`time` ,`issuer` ,`flag`) VALUES ('%d',NOW(),'%s','%s')", sqlid, g_mysql_ReturnEscaped(admin, MainPipeline), g_mysql_ReturnEscaped(flag, MainPipeline));
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	format(query, sizeof(query), "FLAG: %s added flag %s to %s.", admin, flag, name);
	Log("logs/flags.log", query);
	DeletePVar(adminid, "OnAddFlag");
	return 1;
}

stock DeleteFlag(flagid, adminid)
{
	new query[80];
	format(query, sizeof(query), "FLAG: Flag %d was deleted by %s.", flagid, GetPlayerNameEx(adminid));
	Log("logs/flags.log", query);
	format(query, sizeof(query), "DELETE FROM `flags` WHERE `fid` = %i", flagid);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock DisplayFlags(playerid, targetid)
{
    new query[128];
	CountFlags(targetid);
    format(query, sizeof(query), "SELECT fid, issuer, flag, time FROM `flags` WHERE id=%d ORDER BY `time` LIMIT 15", GetPlayerSQLId(targetid));
    mysql_pquery(MainPipeline, query, "FlagQueryFinish", "iii", playerid, targetid, Flag_Query_Display);
	return 1;
}

stock CountSkins(playerid)
{
	new query[80];
	format(query, sizeof(query), "SELECT NULL FROM `house_closet` WHERE playerid = %d", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "SkinQueryFinish", "ii", playerid, Skin_Query_Count);
	return 1;
}

stock AddSkin(playerid, skinid)
{
	new query[300];
	PlayerInfo[playerid][pSkins]++;
	format(query, sizeof(query), "INSERT INTO `house_closet` (`id`, `playerid`, `skinid`) VALUES (NULL, '%d', '%d')", GetPlayerSQLId(playerid), skinid);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock DeleteSkin(skinid)
{
	new query[80];
	format(query, sizeof(query), "DELETE FROM `house_closet` WHERE `id` = %i", skinid);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock DisplaySkins(playerid)
{
    new query[128];
	CountSkins(playerid);
    format(query, sizeof(query), "SELECT `skinid` FROM `house_closet` WHERE playerid = %d ORDER BY `skinid` ASC", GetPlayerSQLId(playerid));
    mysql_pquery(MainPipeline, query, "SkinQueryFinish", "ii", playerid, Skin_Query_Display);
	return 1;
}

stock CountCitizens()
{
	mysql_pquery(MainPipeline, "SELECT NULL FROM `accounts` WHERE `Nation` = 1 && `UpdateDate` > NOW() - INTERVAL 1 WEEK", "CitizenQueryFinish", "i", TR_Citizen_Count);
	mysql_pquery(MainPipeline, "SELECT NULL FROM `accounts` WHERE `UpdateDate` > NOW() - INTERVAL 1 WEEK", "CitizenQueryFinish", "i", Total_Count);
	return 1;
}

stock CheckNationQueue(playerid, nation)
{
	new query[300];
	format(query, sizeof(query), "SELECT NULL FROM `nation_queue` WHERE `playerid` = %d AND `status` = 1", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "NationQueueQueryFinish", "iii", playerid, nation, CheckQueue);
}

stock AddNationQueue(playerid, nation, status)
{
	new query[300];
	if(nation == 0)
	{
		format(query, sizeof(query), "INSERT INTO `nation_queue` (`id`, `playerid`, `name`, `date`, `nation`, `status`) VALUES (NULL, %d, '%s', NOW(), 0, %d)", GetPlayerSQLId(playerid), GetPlayerNameExt(playerid), status);
		mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	}
	if(nation == 1)
	{
		if(status == 1)
		{
			format(query, sizeof(query), "SELECT NULL FROM `nation_queue` WHERE `playerid` = %d AND `nation` = 1", GetPlayerSQLId(playerid));
			mysql_pquery(MainPipeline, query, "NationQueueQueryFinish", "iii", playerid, nation, AddQueue);
		}
		else if(status == 2)
		{
			format(query, sizeof(query), "INSERT INTO `nation_queue` (`id`, `playerid`, `name`, `date`, `nation`, `status`) VALUES (NULL, %d, '%s', NOW(), 1, %d)", GetPlayerSQLId(playerid), GetPlayerNameExt(playerid), status);
			mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
			PlayerInfo[playerid][pNation] = 1;
		}
	}
	return 1;
}

stock UpdateCitizenApp(playerid, nation)
{
	new query[300];
	format(query, sizeof(query), "SELECT NULL FROM `nation_queue` WHERE `playerid` = %d AND `status` = 1", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "NationQueueQueryFinish", "iii", playerid, nation, UpdateQueue);
}

stock AddTicket(playerid, number)
{
	new query[80];
	PlayerInfo[playerid][pLottoNr]++;
	format(query, sizeof(query), "INSERT INTO `lotto` (`id` ,`number`) VALUES ('%d', '%d')", GetPlayerSQLId(playerid), number);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock DeleteTickets(playerid)
{
	new query[80];
	format(query, sizeof(query), "DELETE FROM `lotto` WHERE `id` = %i", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock LoadTickets(playerid)
{
    new query[128];
    format(query, sizeof(query), "SELECT `tid`, `number` FROM `lotto` WHERE `id` = %d LIMIT 5", GetPlayerSQLId(playerid));
    mysql_pquery(MainPipeline, query, "LoadTicket", "i", playerid);
	return 1;
}

stock CountTickets(playerid)
{
	new query[80];
	format(query, sizeof(query), "SELECT * FROM `lotto` WHERE `id` = %i", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "CountAmount", "i", playerid);
	return 1;
}

stock LoadTreasureInventory(playerid)
{
	new query[175];
	format(query, sizeof(query), "SELECT `junkmetal`, `newcoin`, `oldcoin`, `brokenwatch`, `oldkey`, `treasure`, `goldwatch`, `silvernugget`, `goldnugget` FROM `jobstuff` WHERE `pId` = %d", GetPlayerSQLId(playerid));
    mysql_pquery(MainPipeline, query, "LoadTreasureInvent", "i", playerid);
	return 1;
}

stock SaveTreasureInventory(playerid)
{
    new string[220];
	format(string, sizeof(string), "UPDATE `jobstuff` SET `junkmetal` = %d, `newcoin` = %d, `oldcoin` = %d, `brokenwatch` = %d, `oldkey` = %d, \
 	`treasure` = %d, `goldwatch` = %d, `silvernugget` = %d, `goldnugget` =%d  WHERE `pId` = %d", GetPVarInt(playerid, "junkmetal"), GetPVarInt(playerid, "newcoin"), GetPVarInt(playerid, "oldcoin"),
 	GetPVarInt(playerid, "brokenwatch"), GetPVarInt(playerid, "oldkey"), GetPVarInt(playerid, "treasure"), GetPVarInt(playerid, "goldwatch"), GetPVarInt(playerid, "silvernugget"), GetPVarInt(playerid, "goldnugget"), GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock SQL_Log(const szQuery[], const szDesc[] = "none", iExtraID = 0) {
	new i_dateTime[2][3];
	gettime(i_dateTime[0][0], i_dateTime[0][1], i_dateTime[0][2]);
	getdate(i_dateTime[1][0], i_dateTime[1][1], i_dateTime[1][2]);

	printf("Dumping query from %i/%i/%i (%i:%i:%i)\r\nDescription: %s (index %i). Query:\r\n", i_dateTime[1][0], i_dateTime[1][1], i_dateTime[1][2], i_dateTime[0][0], i_dateTime[0][1], i_dateTime[0][2], szDesc, iExtraID);
	if(strlen(szQuery) > 1023)
	{
	    new sz_print[1024];
	    new Float:maxfloat = strlen(szQuery)/1023;
		for(new x;x<=floatround(maxfloat, floatround_ceil);x++)
		{
		    strmid(sz_print, szQuery, 0+(x*1023), 1023+(x*1023));
		    print(sz_print);
		}
	}
	else
	{
		print(szQuery);
	}
	return 1;
}

stock LoadFamilies()
{
	printf("[LoadFamilies] Dang tai du lieu tu database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `families`", "OnLoadFamilies", "");
}

stock FamilyMemberCount(famid)
{
	new query[56];
	format(query, sizeof(query), "SELECT NULL FROM `accounts` WHERE `FMember` = '%d'", famid);
	mysql_pquery(MainPipeline, query, "OnFamilyMemberCount", "i", famid);
	return 1;
}

stock SaveFamily(id) {

	new string[2048];

	format(string, sizeof(string), "UPDATE `families` SET \
		`Taken`=%d, \
		`Name`='%s', \
		`Leader`='%s', \
		`Bank`=%d, \
		`Cash`=%d, \
		`FamilyUSafe`=%d, \
		`FamilySafeX`=%f, \
		`FamilySafeY`=%f, \
		`FamilySafeZ`=%f, \
		`FamilySafeVW`=%d, \
		`FamilySafeInt`=%d, \
		`Pot`=%d, \
		`Crack`=%d, \
		`Mats`=%d, \
		`Heroin`=%d, \
		`Rank0`='%s', \
		`Rank1`='%s', \
		`Rank2`='%s', \
		`Rank3`='%s', \
		`Rank4`='%s', \
		`Rank5`='%s', \
		`Rank6`='%s', \
		`Division0`='%s', \
		`Division1`='%s', \
		`Division2`='%s', \
		`Division3`='%s', \
		`Division4`='%s', ",
		FamilyInfo[id][FamilyTaken],
		g_mysql_ReturnEscaped(FamilyInfo[id][FamilyName], MainPipeline),
		FamilyInfo[id][FamilyLeader],
		FamilyInfo[id][FamilyBank],
		FamilyInfo[id][FamilyCash],
		FamilyInfo[id][FamilyUSafe],
		FamilyInfo[id][FamilySafe][0],
		FamilyInfo[id][FamilySafe][1],
		FamilyInfo[id][FamilySafe][2],
		FamilyInfo[id][FamilySafeVW],
		FamilyInfo[id][FamilySafeInt],
		FamilyInfo[id][FamilyPot],
		FamilyInfo[id][FamilyCrack],
		FamilyInfo[id][FamilyMats],
		FamilyInfo[id][FamilyHeroin],
		g_mysql_ReturnEscaped(FamilyRankInfo[id][0], MainPipeline),
		g_mysql_ReturnEscaped(FamilyRankInfo[id][1], MainPipeline),
		g_mysql_ReturnEscaped(FamilyRankInfo[id][2], MainPipeline),
		g_mysql_ReturnEscaped(FamilyRankInfo[id][3], MainPipeline),
		g_mysql_ReturnEscaped(FamilyRankInfo[id][4], MainPipeline),
		g_mysql_ReturnEscaped(FamilyRankInfo[id][5], MainPipeline),
		g_mysql_ReturnEscaped(FamilyRankInfo[id][6], MainPipeline),
		g_mysql_ReturnEscaped(FamilyDivisionInfo[id][0], MainPipeline),
		g_mysql_ReturnEscaped(FamilyDivisionInfo[id][1], MainPipeline),
		g_mysql_ReturnEscaped(FamilyDivisionInfo[id][2], MainPipeline),
		g_mysql_ReturnEscaped(FamilyDivisionInfo[id][3], MainPipeline),
		g_mysql_ReturnEscaped(FamilyDivisionInfo[id][4], MainPipeline)
	);

	format(string, sizeof(string), "%s\
		`fontface`='%s', \
		`fontsize`=%d, \
		`bold`=%d, \
		`fontcolor`=%d, \
		`gtUsed`=%d, \
		`text`='%s', ",
		string,
		FamilyInfo[id][gt_FontFace],
		FamilyInfo[id][gt_FontSize],
		FamilyInfo[id][gt_Bold],
		FamilyInfo[id][gt_FontColor],
		FamilyInfo[id][gt_SPUsed],
		g_mysql_ReturnEscaped(FamilyInfo[id][gt_Text], MainPipeline)
	);

	format(string, sizeof(string), "%s \
        `MaxSkins`=%d, \
		`Skin1`=%d, \
		`Skin2`=%d, \
		`Skin3`=%d, \
		`Skin4`=%d, \
		`Skin5`=%d, \
		`Skin6`=%d, \
		`Skin7`=%d, \
		`Skin8`=%d, \
		`Color`=%d, \
		`TurfTokens`=%d, \
		`Gun1`=%d, \
		`Gun2`=%d, \
		`Gun3`=%d, \
		`Gun4`=%d, \
		`Gun5`=%d, \
		`Gun6`=%d, \
		`Gun7`=%d, \
		`Gun8`=%d, \
		`Gun9`=%d, \
		`Gun10`=%d, \
		`Gun11`=%d, \
		`Gun12`=%d, \
		`Gun13`=%d, \
		`Gun14`=%d, \
		`Gun15`=%d, \
		`Gun16`=%d, \
		`Gun17`=%d, \
		`Gun18`=%d, \
		`Gun19`=%d, \
		`Gun20`=%d, \
		`Gun21`=%d, \
		`Gun22`=%d, \
		`Gun23`=%d, \
		`Gun24`=%d, \
		`Gun25`=%d, \
		`Gun26`=%d, \
		`Gun27`=%d, \
		`Gun28`=%d, \
		`Gun29`=%d, \
		`Gun30`=%d, \
		`GtObject`=%d, \
		`MOTD1`='%s', \
		`MOTD2`='%s', \
		`MOTD3`='%s', \
		`Level`=%d, \
		`MaxMembers`=%d \
		WHERE `ID` = %d",
		string,
		FamilyInfo[id][FamilyMaxSkins],
		FamilyInfo[id][FamilySkins][0],
		FamilyInfo[id][FamilySkins][1],
		FamilyInfo[id][FamilySkins][2],
		FamilyInfo[id][FamilySkins][3],
		FamilyInfo[id][FamilySkins][4],
		FamilyInfo[id][FamilySkins][5],
		FamilyInfo[id][FamilySkins][6],
		FamilyInfo[id][FamilySkins][7],
		FamilyInfo[id][FamilyColor],
		FamilyInfo[id][FamilyTurfTokens],
		FamilyInfo[id][FamilyGuns][0],
		FamilyInfo[id][FamilyGuns][1],
		FamilyInfo[id][FamilyGuns][2],
		FamilyInfo[id][FamilyGuns][3],
		FamilyInfo[id][FamilyGuns][4],
		FamilyInfo[id][FamilyGuns][5],
		FamilyInfo[id][FamilyGuns][6],
		FamilyInfo[id][FamilyGuns][7],
		FamilyInfo[id][FamilyGuns][8],
		FamilyInfo[id][FamilyGuns][9],
		FamilyInfo[id][FamilyGuns][10],
		FamilyInfo[id][FamilyGuns][11],
		FamilyInfo[id][FamilyGuns][12],
		FamilyInfo[id][FamilyGuns][13],
		FamilyInfo[id][FamilyGuns][14],
		FamilyInfo[id][FamilyGuns][15],
		FamilyInfo[id][FamilyGuns][16],
		FamilyInfo[id][FamilyGuns][17],
		FamilyInfo[id][FamilyGuns][18],
		FamilyInfo[id][FamilyGuns][19],
		FamilyInfo[id][FamilyGuns][20],
		FamilyInfo[id][FamilyGuns][21],
		FamilyInfo[id][FamilyGuns][22],
		FamilyInfo[id][FamilyGuns][23],
		FamilyInfo[id][FamilyGuns][24],
		FamilyInfo[id][FamilyGuns][25],
		FamilyInfo[id][FamilyGuns][26],
		FamilyInfo[id][FamilyGuns][27],
		FamilyInfo[id][FamilyGuns][28],
		FamilyInfo[id][FamilyGuns][29],
		FamilyInfo[id][gtObject],
		g_mysql_ReturnEscaped(FamilyMOTD[id][0], MainPipeline),
		g_mysql_ReturnEscaped(FamilyMOTD[id][1], MainPipeline),
		g_mysql_ReturnEscaped(FamilyMOTD[id][2], MainPipeline),
		FamilyInfo[id][FamilyLevel],
		FamilyInfo[id][FamilyMaxMembers],
		id
	);

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);

	return 1;
}

stock SaveFamiliesHQ(id)
{
	if(!( 1 <= id < MAX_FAMILY))
		return 0;

	new query[300];
	format(query, sizeof(query), "UPDATE `families` SET `ExteriorX` = %f, `ExteriorY` = %f, `ExteriorZ` = %f, `ExteriorA` = %f, `InteriorX` = %f, `InteriorY` = %f, `InteriorZ` = %f, `InteriorA` = %f, \
	`INT` = %d, `VW` = %d, `CustomInterior` = %d WHERE ID = %d", FamilyInfo[id][FamilyEntrance][0], FamilyInfo[id][FamilyEntrance][1], FamilyInfo[id][FamilyEntrance][2], FamilyInfo[id][FamilyEntrance][3],
	FamilyInfo[id][FamilyExit][0], FamilyInfo[id][FamilyExit][1], FamilyInfo[id][FamilyExit][2], FamilyInfo[id][FamilyExit][3], FamilyInfo[id][FamilyInterior], FamilyInfo[id][FamilyVirtualWorld],
	FamilyInfo[id][FamilyCustomMap], id);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);
	return 1;
}

stock LoadGates()
{
	printf("[LoadGates] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `gates`", "OnLoadGates", "");
}

stock SaveDynamicMapIcon(mapiconid)
{
	new string[512];

	format(string, sizeof(string), "UPDATE `dmapicons` SET \
		`MarkerType`=%d, \
		`Color`=%d, \
		`VW`=%d, \
		`Int`=%d, \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f WHERE `id`=%d",
		DMPInfo[mapiconid][dmpMarkerType],
		DMPInfo[mapiconid][dmpColor],
		DMPInfo[mapiconid][dmpVW],
		DMPInfo[mapiconid][dmpInt],
		DMPInfo[mapiconid][dmpPosX],
		DMPInfo[mapiconid][dmpPosY],
		DMPInfo[mapiconid][dmpPosZ],
		mapiconid
	); // Array starts from zero, MySQL starts at 1 (this is why we are adding one).

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock LoadDynamicMapIcon(mapiconid)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `dmapicons` WHERE `id`=%d", mapiconid);
	mysql_pquery(MainPipeline, string, "OnLoadDynamicMapIcon", "i", mapiconid);
}

stock LoadDynamicMapIcons()
{
	printf("[LoadDynamicMapIcons] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `dmapicons`", "OnLoadDynamicMapIcons", "");
}

stock SaveDynamicDoor(doorid)
{
	new string[1024];
	format(string, sizeof(string), "UPDATE `ddoors` SET \
		`Description`='%s', \
		`Owner`=%d, \
		`OwnerName`='%s', \
		`CustomInterior`=%d, \
		`ExteriorVW`=%d, \
		`ExteriorInt`=%d, \
		`InteriorVW`=%d, \
		`InteriorInt`=%d, \
		`ExteriorX`=%f, \
		`ExteriorY`=%f, \
		`ExteriorZ`=%f, \
		`ExteriorA`=%f, \
		`InteriorX`=%f, \
		`InteriorY`=%f, \
		`InteriorZ`=%f, \
		`InteriorA`=%f,",
		g_mysql_ReturnEscaped(DDoorsInfo[doorid][ddDescription], MainPipeline),
		DDoorsInfo[doorid][ddOwner],
		g_mysql_ReturnEscaped(DDoorsInfo[doorid][ddOwnerName], MainPipeline),
		DDoorsInfo[doorid][ddCustomInterior],
		DDoorsInfo[doorid][ddExteriorVW],
		DDoorsInfo[doorid][ddExteriorInt],
		DDoorsInfo[doorid][ddInteriorVW],
		DDoorsInfo[doorid][ddInteriorInt],
		DDoorsInfo[doorid][ddExteriorX],
		DDoorsInfo[doorid][ddExteriorY],
		DDoorsInfo[doorid][ddExteriorZ],
		DDoorsInfo[doorid][ddExteriorA],
		DDoorsInfo[doorid][ddInteriorX],
		DDoorsInfo[doorid][ddInteriorY],
		DDoorsInfo[doorid][ddInteriorZ],
		DDoorsInfo[doorid][ddInteriorA]
	);

	format(string, sizeof(string), "%s \
		`CustomExterior`=%d, \
		`Type`=%d, \
		`Rank`=%d, \
		`VIP`=%d, \
		`Famed`=%d, \
		`DPC`=%d, \
		`Allegiance`=%d, \
		`GroupType`=%d, \
		`Family`=%d, \
		`Faction`=%d, \
		`Admin`=%d, \
		`Wanted`=%d, \
		`VehicleAble`=%d, \
		`Color`=%d, \
		`PickupModel`=%d, \
		`Pass`='%s', \
		`Locked`=%d WHERE `id`=%d",
		string,
		DDoorsInfo[doorid][ddCustomExterior],
		DDoorsInfo[doorid][ddType],
		DDoorsInfo[doorid][ddRank],
		DDoorsInfo[doorid][ddVIP],
		DDoorsInfo[doorid][ddFamed],
		DDoorsInfo[doorid][ddDPC],
		DDoorsInfo[doorid][ddAllegiance],
		DDoorsInfo[doorid][ddGroupType],
		DDoorsInfo[doorid][ddFamily],
		DDoorsInfo[doorid][ddFaction],
		DDoorsInfo[doorid][ddAdmin],
		DDoorsInfo[doorid][ddWanted],
		DDoorsInfo[doorid][ddVehicleAble],
		DDoorsInfo[doorid][ddColor],
		DDoorsInfo[doorid][ddPickupModel],
		g_mysql_ReturnEscaped(DDoorsInfo[doorid][ddPass], MainPipeline),
		DDoorsInfo[doorid][ddLocked],
		doorid+1
	); // Array starts from zero, MySQL starts at 1 (this is why we are adding one).

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock LoadDynamicDoor(doorid)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `ddoors` WHERE `id`=%d", doorid+1); // Array starts at zero, MySQL starts at 1.
	mysql_pquery(MainPipeline, string, "OnLoadDynamicDoor", "i", doorid);
}

stock LoadDynamicDoors()
{
	printf("[LoadDynamicDoors] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `ddoors`", "OnLoadDynamicDoors", "");
}

stock SaveHouse(houseid)
{
	new string[2048];
	printf("Saving House ID %d", houseid);
	format(string, sizeof(string), "UPDATE `houses` SET \
		`Owned`=%d, \
		`Level`=%d, \
		`Description`='%s', \
		`OwnerID`=%d, \
		`ExteriorX`=%f, \
		`ExteriorY`=%f, \
		`ExteriorZ`=%f, \
		`ExteriorR`=%f, \
		`InteriorX`=%f, \
		`InteriorY`=%f, \
		`InteriorZ`=%f, \
		`InteriorR`=%f, \
		`ExtIW`=%d, \
		`ExtVW`=%d, \
		`IntIW`=%d, \
		`IntVW`=%d,",
		HouseInfo[houseid][hOwned],
		HouseInfo[houseid][hLevel],
		g_mysql_ReturnEscaped(HouseInfo[houseid][hDescription], MainPipeline),
		HouseInfo[houseid][hOwnerID],
		HouseInfo[houseid][hExteriorX],
		HouseInfo[houseid][hExteriorY],
		HouseInfo[houseid][hExteriorZ],
		HouseInfo[houseid][hExteriorR],
		HouseInfo[houseid][hInteriorX],
		HouseInfo[houseid][hInteriorY],
		HouseInfo[houseid][hInteriorZ],
		HouseInfo[houseid][hInteriorR],
		HouseInfo[houseid][hExtIW],
		HouseInfo[houseid][hExtVW],
		HouseInfo[houseid][hIntIW],
		HouseInfo[houseid][hIntVW]
	);

	format(string, sizeof(string), "%s \
		`Lock`=%d, \
		`Rentable`=%d, \
		`RentFee`=%d, \
		`Value`=%d, \
		`SafeMoney`=%d, \
		`Pot`=%d, \
		`Crack`=%d, \
		`Materials`=%d, \
		`Heroin`=%d, \
		`Weapons0`=%d, \
		`Weapons1`=%d, \
		`Weapons2`=%d, \
		`Weapons3`=%d, \
		`Weapons4`=%d, \
		`GLUpgrade`=%d, \
		`CustomInterior`=%d, \
		`CustomExterior`=%d, \
		`ExteriorA`=%f, \
		`InteriorA`=%f, \
		`MailX`=%f, \
		`MailY`=%f, \
		`MailZ`=%f, \
		`MailA`=%f, \
		`MailType`=%d, \
		`ClosetX`=%f, \
		`ClosetY`=%f, \
		`ClosetZ`=%f WHERE `id`=%d",
		string,
		HouseInfo[houseid][hLock],
		HouseInfo[houseid][hRentable],
		HouseInfo[houseid][hRentFee],
		HouseInfo[houseid][hValue],
   		HouseInfo[houseid][hSafeMoney],
		HouseInfo[houseid][hPot],
		HouseInfo[houseid][hCrack],
		HouseInfo[houseid][hMaterials],
		HouseInfo[houseid][hHeroin],
		HouseInfo[houseid][hWeapons][0],
		HouseInfo[houseid][hWeapons][1],
		HouseInfo[houseid][hWeapons][2],
		HouseInfo[houseid][hWeapons][3],
		HouseInfo[houseid][hWeapons][4],
		HouseInfo[houseid][hGLUpgrade],
		HouseInfo[houseid][hCustomInterior],
		HouseInfo[houseid][hCustomExterior],
		HouseInfo[houseid][hExteriorA],
		HouseInfo[houseid][hInteriorA],
		HouseInfo[houseid][hMailX],
		HouseInfo[houseid][hMailY],
		HouseInfo[houseid][hMailZ],
		HouseInfo[houseid][hMailA],
		HouseInfo[houseid][hMailType],
		HouseInfo[houseid][hClosetX],
		HouseInfo[houseid][hClosetY],
		HouseInfo[houseid][hClosetZ],
		houseid+1
	); // Array starts from zero, MySQL starts at 1 (this is why we are adding one).

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock LoadHouse(houseid)
{
	new string[128];
	printf("[LoadHouse] Loading HouseID %d's data from database...", houseid);
	format(string, sizeof(string), "SELECT OwnerName.Username, h.* FROM houses h LEFT JOIN accounts OwnerName ON h.OwnerID = OwnerName.id WHERE `id` = %d", houseid+1); // Array starts at zero, MySQL starts at one.
	mysql_pquery(MainPipeline, string, "OnLoadHouse", "i", houseid);
}

stock LoadHouses()
{
	printf("[LoadHouses] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT OwnerName.Username, h.* FROM houses h LEFT JOIN accounts OwnerName ON h.OwnerID = OwnerName.id", "OnLoadHouses", "");
}

stock LoadMailboxes()
{
	printf("[LoadMailboxes] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `mailboxes`", "OnLoadMailboxes", "");
}

stock LoadPoints()
{
	printf("[LoadFamilyPoints] Loading Family Points from the database, please wait...");
	mysql_pquery(MainPipeline, "SELECT * FROM `points`", "OnLoadPoints", "");
}		

stock LoadHGBackpacks()
{
	printf("[Loading Hunger Games] Loading Hunger Games Backpacks from the database, please wait...");
	mysql_pquery(MainPipeline,  "SELECT * FROM `hgbackpacks`", "OnLoadHGBackpacks", "");
}

stock SaveMailbox(id)
{
	new string[512];

	format(string, sizeof(string), "UPDATE `mailboxes` SET \
		`VW`=%d, \
		`Int`=%d, \
		`Model`=%d, \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f, \
		`Angle`=%f WHERE `id`=%d",
		MailBoxes[id][mbVW],
		MailBoxes[id][mbInt],
		MailBoxes[id][mbModel],
		MailBoxes[id][mbPosX],
		MailBoxes[id][mbPosY],
		MailBoxes[id][mbPosZ],
		MailBoxes[id][mbAngle],
		id+1
	); // Array starts from zero, MySQL starts at 1 (this is why we are adding one).

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock SaveSpeedCamera(i)
{
	if (SpeedCameras[i][_scActive] != true)
		return;

	new query[1024];
	format(query, sizeof(query), "UPDATE speed_cameras SET pos_x=%f, pos_y=%f, pos_z=%f, rotation=%f, `range`=%f, speed_limit=%f WHERE id=%i",
		SpeedCameras[i][_scPosX], SpeedCameras[i][_scPosY], SpeedCameras[i][_scPosZ], SpeedCameras[i][_scRotation], SpeedCameras[i][_scRange], SpeedCameras[i][_scLimit],
		SpeedCameras[i][_scDatabase]);

	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock LoadSpeedCameras()
{
	printf("[SpeedCameras] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM speed_cameras", "OnLoadSpeedCameras", "");

	return 1;
}

stock StoreNewSpeedCameraInMySQL(index)
{
	new string[512];
	format(string, sizeof(string), "INSERT INTO speed_cameras (pos_x, pos_y, pos_z, rotation, `range`, speed_limit) VALUES (%f, %f, %f, %f, %f, %f)",
		SpeedCameras[index][_scPosX], SpeedCameras[index][_scPosY], SpeedCameras[index][_scPosZ], SpeedCameras[index][_scRotation], SpeedCameras[index][_scRange], SpeedCameras[index][_scLimit]);

	mysql_pquery(MainPipeline, string, "OnNewSpeedCamera", "i", index);
	return 1;
}

stock SaveTxtLabel(labelid)
{
	new string[1024];
	format(string, sizeof(string), "UPDATE `text_labels` SET \
		`Text`='%s', \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f, \
		`VW`=%d, \
		`Int`=%d, \
		`Color`=%d, \
		`PickupModel`=%d WHERE `id`=%d",
		g_mysql_ReturnEscaped(TxtLabels[labelid][tlText], MainPipeline),
		TxtLabels[labelid][tlPosX],
		TxtLabels[labelid][tlPosY],
		TxtLabels[labelid][tlPosZ],
		TxtLabels[labelid][tlVW],
		TxtLabels[labelid][tlInt],
		TxtLabels[labelid][tlColor],
		TxtLabels[labelid][tlPickupModel],
		labelid+1
	); // Array starts from zero, MySQL starts at 1 (this is why we are adding one).

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock LoadTxtLabel(labelid)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `text_labels` WHERE `id`=%d", labelid+1); // Array starts at zero, MySQL starts at 1.
	mysql_pquery(MainPipeline, string, "OnLoadTxtLabel", "i", labelid);
}

stock LoadTxtLabels()
{
	printf("[LoadTxtLabels] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `text_labels`", "OnLoadTxtLabels", "");
}

stock SavePayNSpray(id)
{
	new string[1024];
	format(string, sizeof(string), "UPDATE `paynsprays` SET \
		`Status`=%d, \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f, \
		`VW`=%d, \
		`Int`=%d, \
		`GroupCost`=%d, \
		`RegCost`=%d WHERE `id`=%d",
		PayNSprays[id][pnsStatus],
		PayNSprays[id][pnsPosX],
		PayNSprays[id][pnsPosY],
		PayNSprays[id][pnsPosZ],
		PayNSprays[id][pnsVW],
		PayNSprays[id][pnsInt],
		PayNSprays[id][pnsGroupCost],
		PayNSprays[id][pnsRegCost],
		id
	);

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock SavePayNSprays()
{
	for(new i = 0; i < MAX_PAYNSPRAYS; i++)
	{
		SavePayNSpray(i);
	}
	return 1;
}

stock RehashPayNSpray(id)
{
	DestroyDynamicPickup(PayNSprays[id][pnsPickupID]);
	DestroyDynamic3DTextLabel(PayNSprays[id][pnsTextID]);
	DestroyDynamicMapIcon(PayNSprays[id][pnsMapIconID]);
	PayNSprays[id][pnsSQLId] = -1;
	PayNSprays[id][pnsStatus] = 0;
	PayNSprays[id][pnsPosX] = 0.0;
	PayNSprays[id][pnsPosY] = 0.0;
	PayNSprays[id][pnsPosZ] = 0.0;
	PayNSprays[id][pnsVW] = 0;
	PayNSprays[id][pnsInt] = 0;
	PayNSprays[id][pnsGroupCost] = 0;
	PayNSprays[id][pnsRegCost] = 0;
	LoadPayNSpray(id);
}

stock RehashPayNSprays()
{
	printf("[RehashPayNSprays] Deleting Pay N' Sprays from server...");
	for(new i = 0; i < MAX_PAYNSPRAYS; i++)
	{
		RehashPayNSpray(i);
	}
	LoadPayNSprays();
}

stock LoadPayNSpray(id)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `paynsprays` WHERE `id`=%d", id);
	mysql_pquery(MainPipeline, string, "OnLoadPayNSprays", "i", id);
}

stock IsAdminSpawnedVehicle(vehicleid)
{
	for(new i = 0; i < sizeof(CreatedCars); ++i) {
		if(CreatedCars[i] == vehicleid) return 1;
	}
	return 0;
}

forward OnLoadPayNSpray(index);
public OnLoadPayNSpray(index)
{
	new rows, fields, tmp[128], string[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp);  PayNSprays[index][pnsSQLId] = strval(tmp);
		cache_get_value_name(row, "Status", tmp); PayNSprays[index][pnsStatus] = strval(tmp);
		cache_get_value_name(row, "PosX", tmp); PayNSprays[index][pnsPosX] = floatstr(tmp);
		cache_get_value_name(row, "PosY", tmp); PayNSprays[index][pnsPosY] = floatstr(tmp);
		cache_get_value_name(row, "PosZ", tmp); PayNSprays[index][pnsPosZ] = floatstr(tmp);
		cache_get_value_name(row, "VW", tmp); PayNSprays[index][pnsVW] = strval(tmp);
		cache_get_value_name(row, "Int", tmp); PayNSprays[index][pnsInt] = strval(tmp);
		cache_get_value_name(row, "GroupCost", tmp); PayNSprays[index][pnsGroupCost] = strval(tmp);
		cache_get_value_name(row, "RegCost", tmp); PayNSprays[index][pnsRegCost] = strval(tmp);
		if(PayNSprays[index][pnsStatus] > 0)
		{
			format(string, sizeof(string), "/repaircar\nRepair Cost -- Regular: $%s | Faction: $%s\nID: %d", number_format(PayNSprays[index][pnsRegCost]), number_format(PayNSprays[index][pnsGroupCost]), index);
			PayNSprays[index][pnsTextID] = CreateDynamic3DTextLabel(string, COLOR_RED, PayNSprays[index][pnsPosX], PayNSprays[index][pnsPosY], PayNSprays[index][pnsPosZ]+0.5,10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, PayNSprays[index][pnsVW], PayNSprays[index][pnsInt], -1);
			PayNSprays[index][pnsPickupID] = CreateDynamicPickup(1239, 23, PayNSprays[index][pnsPosX], PayNSprays[index][pnsPosY], PayNSprays[index][pnsPosZ], PayNSprays[index][pnsVW]);
			PayNSprays[index][pnsMapIconID] = CreateDynamicMapIcon(PayNSprays[index][pnsPosX], PayNSprays[index][pnsPosY], PayNSprays[index][pnsPosZ], 63, 0, PayNSprays[index][pnsVW], PayNSprays[index][pnsInt], -1, 500.0);
		}
	}
	return 1;
}

stock LoadPayNSprays()
{
	printf("[LoadPayNSprays] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `paynsprays`", "OnLoadPayNSprays", "");
}

stock SaveArrestPoint(id)
{
	new string[1024];
	format(string, sizeof(string), "UPDATE `arrestpoints` SET \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f, \
		`VW`=%d, \
		`Int`=%d, \
		`Type`=%d WHERE `id`=%d",
		ArrestPoints[id][arrestPosX],
		ArrestPoints[id][arrestPosY],
		ArrestPoints[id][arrestPosZ],
		ArrestPoints[id][arrestVW],
		ArrestPoints[id][arrestInt],
		ArrestPoints[id][arrestType],
		id
	);

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock SaveArrestPoints()
{
	for(new i = 0; i < MAX_ARRESTPOINTS; i++)
	{
		SaveArrestPoint(i);
	}
	return 1;
}

stock RehashArrestPoint(id)
{
	DestroyDynamic3DTextLabel(ArrestPoints[id][arrestTextID]);
	DestroyDynamicPickup(ArrestPoints[id][arrestPickupID]);
	ArrestPoints[id][arrestSQLId] = -1;
	ArrestPoints[id][arrestPosX] = 0.0;
	ArrestPoints[id][arrestPosY] = 0.0;
	ArrestPoints[id][arrestPosZ] = 0.0;
	ArrestPoints[id][arrestVW] = 0;
	ArrestPoints[id][arrestInt] = 0;
	ArrestPoints[id][arrestType] = 0;
	LoadArrestPoint(id);
}

stock RehashArrestPoints()
{
	printf("[RehashArrestPoints] Deleting Arrest Points from server...");
	for(new i = 0; i < MAX_ARRESTPOINTS; i++)
	{
		RehashArrestPoint(i);
	}
	LoadArrestPoints();
}

stock LoadArrestPoint(id)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `arrestpoints` WHERE `id`=%d", id);
	mysql_pquery(MainPipeline, string, "OnLoadArrestPoints", "i", id);
}

stock LoadArrestPoints()
{
	printf("[LoadArrestPoints] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `arrestpoints`", "OnLoadArrestPoints", "");
}

stock SaveImpoundPoint(id)
{
	new string[1024];
	format(string, sizeof(string), "UPDATE `impoundpoints` SET \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f, \
		`VW`=%d, \
		`Int`=%d WHERE `id`=%d",
		ImpoundPoints[id][impoundPosX],
		ImpoundPoints[id][impoundPosY],
		ImpoundPoints[id][impoundPosZ],
		ImpoundPoints[id][impoundVW],
		ImpoundPoints[id][impoundInt],
		id
	);

	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock SaveImpoundPoints()
{
	for(new i = 0; i < MAX_ImpoundPoints; i++)
	{
		SaveImpoundPoint(i);
	}
	return 1;
}

stock RehashImpoundPoint(id)
{
	DestroyDynamic3DTextLabel(ImpoundPoints[id][impoundTextID]);
	ImpoundPoints[id][impoundSQLId] = -1;
	ImpoundPoints[id][impoundPosX] = 0.0;
	ImpoundPoints[id][impoundPosY] = 0.0;
	ImpoundPoints[id][impoundPosZ] = 0.0;
	ImpoundPoints[id][impoundVW] = 0;
	ImpoundPoints[id][impoundInt] = 0;
	LoadImpoundPoint(id);
}

stock RehashImpoundPoints()
{
	printf("[RehashImpoundPoints] Deleting impound Points from server...");
	for(new i = 0; i < MAX_ImpoundPoints; i++)
	{
		RehashImpoundPoint(i);
	}
	LoadImpoundPoints();
}

stock LoadImpoundPoint(id)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `impoundpoints` WHERE `id`=%d", id);
	mysql_pquery(MainPipeline, string, "OnLoadImpoundPoints", "i", id);
}

stock LoadImpoundPoints()
{
	printf("[LoadImpoundPoints] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `impoundpoints`", "OnLoadImpoundPoints", "");
}

// credits to Luk0r
stock MySQLUpdateBuild(query[], sqlplayerid)
{
	new querylen = strlen(query);
	if (!query[0]) {
		format(query, 2048, "UPDATE `accounts` SET ");
	}
	else if (2048-querylen < 200)
	{
		new whereclause[32];
		format(whereclause, sizeof(whereclause), " WHERE `id`=%d", sqlplayerid);
		strcat(query, whereclause, 2048);
		mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
		format(query, 2048, "UPDATE `accounts` SET ");
	}
	else if (strfind(query, "=", true) != -1) strcat(query, ",", 2048);
	return 1;
}

stock MySQLUpdateFinish(query[], sqlplayerid)
{
	if (strcmp(query, "WHERE id=", false) == 0) mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	else
	{
		new whereclause[32];
		format(whereclause, sizeof(whereclause), " WHERE id=%d", sqlplayerid);
		strcat(query, whereclause, 2048);
		mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
		format(query, 2048, "UPDATE `accounts` SET ");
	}
	return 1;
}

stock SavePlayerInteger(query[], sqlid, const Value[], Integer)
{
	MySQLUpdateBuild(query, sqlid);
	new updval[64];
	format(updval, sizeof(updval), "`%s`=%d", Value, Integer);
	strcat(query, updval, 2048);
	return 1;
}


stock SavePlayerString(query[], sqlid, const Value[], const String[])
{
	MySQLUpdateBuild(query, sqlid);
	new escapedstring[160], string[160];
	mysql_real_escape_string(String, escapedstring);
	format(string, sizeof(string), "`%s`='%s'", Value, escapedstring);
	strcat(query, string, 2048);
	return 1;
}

stock SavePlayerFloat(query[], sqlid, const Value[], Float:Number)
{
	new flotostr[32];
	format(flotostr, sizeof(flotostr), "%0.2f", Number);
	SavePlayerString(query, sqlid, Value, flotostr);
	return 1;
}

stock g_mysql_SaveAccount(playerid)
{
    new query[2048];
	
	format(query, 2048, "UPDATE `accounts` SET `SPos_x` = '%0.2f', `SPos_y` = '%0.2f', `SPos_z` = '%0.2f', `SPos_r` = '%0.2f' WHERE id = '%d'",PlayerInfo[playerid][pPos_x], PlayerInfo[playerid][pPos_y], PlayerInfo[playerid][pPos_z], PlayerInfo[playerid][pPos_r], GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	
    format(query, 2048, "UPDATE `accounts` SET ");
    SavePlayerString(query, GetPlayerSQLId(playerid), "IP", PlayerInfo[playerid][pIP]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Registered", PlayerInfo[playerid][pReg]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ConnectedTime", PlayerInfo[playerid][pConnectHours]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Sex", PlayerInfo[playerid][pSex]);
    SavePlayerString(query, GetPlayerSQLId(playerid), "BirthDate", PlayerInfo[playerid][pBirthDate]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Band", PlayerInfo[playerid][pBanned]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "PermBand", PlayerInfo[playerid][pPermaBanned]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Warnings", PlayerInfo[playerid][pWarns]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Disabled", PlayerInfo[playerid][pDisabled]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Level", PlayerInfo[playerid][pLevel]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "AdminLevel", PlayerInfo[playerid][pAdmin]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "SeniorModerator", PlayerInfo[playerid][pSMod]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Helper", PlayerInfo[playerid][pHelper]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "DonateRank", PlayerInfo[playerid][pDonateRank]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Respect", PlayerInfo[playerid][pExp]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "XP", PlayerInfo[playerid][pXP]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Money", GetPlayerCash(playerid));

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Bank", PlayerInfo[playerid][pAccount]);
    SavePlayerFloat(query, GetPlayerSQLId(playerid), "pHealth", PlayerInfo[playerid][pHealth]);
    SavePlayerFloat(query, GetPlayerSQLId(playerid), "pArmor", PlayerInfo[playerid][pArmor]);
    SavePlayerFloat(query, GetPlayerSQLId(playerid), "pSHealth", PlayerInfo[playerid][pSHealth]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Int", PlayerInfo[playerid][pInt]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "VirtualWorld", PlayerInfo[playerid][pVW]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Model", PlayerInfo[playerid][pModel]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BanAppealer", PlayerInfo[playerid][pBanAppealer]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "PR", PlayerInfo[playerid][pPR]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "HR", PlayerInfo[playerid][pHR]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "AP", PlayerInfo[playerid][pAP]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Security", PlayerInfo[playerid][pSecurity]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ShopTech", PlayerInfo[playerid][pShopTech]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "FactionModerator", PlayerInfo[playerid][pFactionModerator]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "GangModerator", PlayerInfo[playerid][pGangModerator]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Undercover", PlayerInfo[playerid][pUndercover]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TogReports", PlayerInfo[playerid][pTogReports]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Radio", PlayerInfo[playerid][pRadio]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "RadioFreq", PlayerInfo[playerid][pRadioFreq]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "UpgradePoints", PlayerInfo[playerid][gPupgrade]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Origin", PlayerInfo[playerid][pOrigin]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Muted", PlayerInfo[playerid][pMuted]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Crimes", PlayerInfo[playerid][pCrimes]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Accent", PlayerInfo[playerid][pAccent]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "CHits", PlayerInfo[playerid][pCHits]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FHits", PlayerInfo[playerid][pFHits]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Arrested", PlayerInfo[playerid][pArrested]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Phonebook", PlayerInfo[playerid][pPhoneBook]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "LottoNr", PlayerInfo[playerid][pLottoNr]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Fishes", PlayerInfo[playerid][pFishes]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BiggestFish", PlayerInfo[playerid][pBiggestFish]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Job", PlayerInfo[playerid][pJob]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Job2", PlayerInfo[playerid][pJob2]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Paycheck", PlayerInfo[playerid][pPayCheck]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "HeadValue", PlayerInfo[playerid][pHeadValue]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "JailTime", PlayerInfo[playerid][pJailTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "WRestricted", PlayerInfo[playerid][pWRestricted]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Materials", PlayerInfo[playerid][pMats]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Crates", PlayerInfo[playerid][pCrates]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Pot", PlayerInfo[playerid][pPot]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Crack", PlayerInfo[playerid][pCrack]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Nation", PlayerInfo[playerid][pNation]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Leader", PlayerInfo[playerid][pLeader]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Member", PlayerInfo[playerid][pMember]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Division", PlayerInfo[playerid][pDivision]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FMember", PlayerInfo[playerid][pFMember]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Rank", PlayerInfo[playerid][pRank]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "DetSkill", PlayerInfo[playerid][pDetSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "SexSkill", PlayerInfo[playerid][pSexSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BoxSkill", PlayerInfo[playerid][pBoxSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "LawSkill", PlayerInfo[playerid][pLawSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "MechSkill", PlayerInfo[playerid][pMechSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TruckSkill", PlayerInfo[playerid][pTruckSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "DrugsSkill", PlayerInfo[playerid][pDrugsSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ArmsSkill", PlayerInfo[playerid][pArmsSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "SmugglerSkill", PlayerInfo[playerid][pSmugSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FishSkill", PlayerInfo[playerid][pFishSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "CheckCash", PlayerInfo[playerid][pCheckCash]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Checks", PlayerInfo[playerid][pChecks]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BoatLic", PlayerInfo[playerid][pBoatLic]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FlyLic", PlayerInfo[playerid][pFlyLic]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "GunLic", PlayerInfo[playerid][pGunLic]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FishLic", PlayerInfo[playerid][pFishLic]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FishSkill", PlayerInfo[playerid][pFishSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "FightingStyle", PlayerInfo[playerid][pFightStyle]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "PhoneNr", PlayerInfo[playerid][pPnumber]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Apartment", PlayerInfo[playerid][pPhousekey]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Apartment2", PlayerInfo[playerid][pPhousekey2]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Renting", PlayerInfo[playerid][pRenting]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "CarLic", PlayerInfo[playerid][pCarLic]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "DrugsTime", PlayerInfo[playerid][pDrugsTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "LawyerTime", PlayerInfo[playerid][pLawyerTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "LawyerFreeTime", PlayerInfo[playerid][pLawyerFreeTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "MechTime", PlayerInfo[playerid][pMechTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "SexTime", PlayerInfo[playerid][pSexTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "PayDay", PlayerInfo[playerid][pConnectSeconds]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "PayDayHad", PlayerInfo[playerid][pPayDayHad]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "CDPlayer", PlayerInfo[playerid][pCDPlayer]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Dice", PlayerInfo[playerid][pDice]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Spraycan", PlayerInfo[playerid][pSpraycan]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Rope", PlayerInfo[playerid][pRope]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Cigars", PlayerInfo[playerid][pCigar]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Sprunk", PlayerInfo[playerid][pSprunk]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Bombs", PlayerInfo[playerid][pBombs]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Wins", PlayerInfo[playerid][pWins]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun0", PlayerInfo[playerid][pGuns][0]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun1", PlayerInfo[playerid][pGuns][1]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun2", PlayerInfo[playerid][pGuns][2]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun3", PlayerInfo[playerid][pGuns][3]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun4", PlayerInfo[playerid][pGuns][4]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun5", PlayerInfo[playerid][pGuns][5]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun6", PlayerInfo[playerid][pGuns][6]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun7", PlayerInfo[playerid][pGuns][7]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun8", PlayerInfo[playerid][pGuns][8]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun9", PlayerInfo[playerid][pGuns][9]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun10", PlayerInfo[playerid][pGuns][10]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Gun11", PlayerInfo[playerid][pGuns][11]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Loses", PlayerInfo[playerid][pLoses]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Tutorial", PlayerInfo[playerid][pTut]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "OnDuty", PlayerInfo[playerid][pDuty]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Hospital", PlayerInfo[playerid][pHospital]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "MarriedID", PlayerInfo[playerid][pMarriedID]);
    SavePlayerString(query, GetPlayerSQLId(playerid), "ContractBy", PlayerInfo[playerid][pContractBy]);
    SavePlayerString(query, GetPlayerSQLId(playerid), "ContractDetail", PlayerInfo[playerid][pContractDetail]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "WantedLevel", PlayerInfo[playerid][pWantedLevel]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Insurance", PlayerInfo[playerid][pInsurance]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "911Muted", PlayerInfo[playerid][p911Muted]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "NewMuted", PlayerInfo[playerid][pNMute]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "NewMutedTotal", PlayerInfo[playerid][pNMuteTotal]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "AdMuted", PlayerInfo[playerid][pADMute]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "AdMutedTotal", PlayerInfo[playerid][pADMuteTotal]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "HelpMute", PlayerInfo[playerid][pHelpMute]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ReportMuted", PlayerInfo[playerid][pRMuted]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ReportMutedTotal", PlayerInfo[playerid][pRMutedTotal]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ReportMutedTime", PlayerInfo[playerid][pRMutedTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "DMRMuted", PlayerInfo[playerid][pDMRMuted]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPMuted", PlayerInfo[playerid][pVMuted]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPMutedTime", PlayerInfo[playerid][pVMutedTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "GiftTime", PlayerInfo[playerid][pGiftTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "AdvisorDutyHours", PlayerInfo[playerid][pDutyHours]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "AcceptedHelp", PlayerInfo[playerid][pAcceptedHelp]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "AcceptReport", PlayerInfo[playerid][pAcceptReport]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TrashReport", PlayerInfo[playerid][pTrashReport]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "GangWarn", PlayerInfo[playerid][pGangWarn]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "CSFBanned", PlayerInfo[playerid][pCSFBanned]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPInviteDay", PlayerInfo[playerid][pVIPInviteDay]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TempVIP", PlayerInfo[playerid][pTempVIP]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BuddyInvite", PlayerInfo[playerid][pBuddyInvited]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Tokens", PlayerInfo[playerid][pTokens]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "PTokens", PlayerInfo[playerid][pPaintTokens]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TriageTime", PlayerInfo[playerid][pTriageTime]);
    SavePlayerString(query, GetPlayerSQLId(playerid), "PrisonedBy", PlayerInfo[playerid][pPrisonedBy]);
    SavePlayerString(query, GetPlayerSQLId(playerid), "PrisonReason", PlayerInfo[playerid][pPrisonReason]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TaxiLicense", PlayerInfo[playerid][pTaxiLicense]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TicketTime", PlayerInfo[playerid][pTicketTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Screwdriver", PlayerInfo[playerid][pScrewdriver]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Smslog", PlayerInfo[playerid][pSmslog]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Speedo", PlayerInfo[playerid][pSpeedo]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Wristwatch", PlayerInfo[playerid][pWristwatch]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Surveillance", PlayerInfo[playerid][pSurveillance]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Tire", PlayerInfo[playerid][pTire]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Firstaid", PlayerInfo[playerid][pFirstaid]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Rccam", PlayerInfo[playerid][pRccam]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Receiver", PlayerInfo[playerid][pReceiver]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "GPS", PlayerInfo[playerid][pGPS]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Sweep", PlayerInfo[playerid][pSweep]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "SweepLeft", PlayerInfo[playerid][pSweepLeft]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Bugged", PlayerInfo[playerid][pBugged]);

    SavePlayerInteger(query, GetPlayerSQLId(playerid), "pWExists", PlayerInfo[playerid][pWeedObject]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "pWSeeds", PlayerInfo[playerid][pWSeeds]);
    SavePlayerString(query, GetPlayerSQLId(playerid), "Warrants", PlayerInfo[playerid][pWarrant]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "JudgeJailTime", PlayerInfo[playerid][pJudgeJailTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "JudgeJailType", PlayerInfo[playerid][pJudgeJailType]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BeingSentenced", PlayerInfo[playerid][pBeingSentenced]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "ProbationTime", PlayerInfo[playerid][pProbationTime]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "DMKills", PlayerInfo[playerid][pDMKills]);

	SavePlayerInteger(query, GetPlayerSQLId(playerid), "OrderConfirmed", PlayerInfo[playerid][pOrderConfirmed]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "FreezeHouse", PlayerInfo[playerid][pFreezeHouse]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "FreezeCar", PlayerInfo[playerid][pFreezeCar]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Firework", PlayerInfo[playerid][pFirework]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Boombox", PlayerInfo[playerid][pBoombox]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Hydration", PlayerInfo[playerid][pHydration]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "DoubleEXP", PlayerInfo[playerid][pDoubleEXP]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "EXPToken", PlayerInfo[playerid][pEXPToken]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RacePlayerLaps", PlayerInfo[playerid][pRacePlayerLaps]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Ringtone", PlayerInfo[playerid][pRingtone]);

	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Order", PlayerInfo[playerid][pOrder]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "CallsAccepted", PlayerInfo[playerid][pCallsAccepted]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "PatientsDelivered", PlayerInfo[playerid][pPatientsDelivered]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "LiveBanned", PlayerInfo[playerid][pLiveBanned]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "FreezeBank", PlayerInfo[playerid][pFreezeBank]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPM", PlayerInfo[playerid][pVIPM]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPMO", PlayerInfo[playerid][pVIPMO]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPExpire", PlayerInfo[playerid][pVIPExpire]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "GVip", PlayerInfo[playerid][pGVip]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Watchdog", PlayerInfo[playerid][pWatchdog]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPSold", PlayerInfo[playerid][pVIPSold]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "GoldBoxTokens", PlayerInfo[playerid][pGoldBoxTokens]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "DrawChance", PlayerInfo[playerid][pRewardDrawChance]);
	SavePlayerFloat(query, GetPlayerSQLId(playerid), "RewardHours", PlayerInfo[playerid][pRewardHours]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "CarsRestricted", PlayerInfo[playerid][pRVehRestricted]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "LastCarWarning", PlayerInfo[playerid][pLastRVehWarn]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "CarWarns", PlayerInfo[playerid][pRVehWarns]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Flagged", PlayerInfo[playerid][pFlagged]);

	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Paper", PlayerInfo[playerid][pPaper]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "MailEnabled", PlayerInfo[playerid][pMailEnabled]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Mailbox", PlayerInfo[playerid][pMailbox]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Business", PlayerInfo[playerid][pBusiness]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "BusinessRank", PlayerInfo[playerid][pBusinessRank]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "TreasureSkill", PlayerInfo[playerid][pTreasureSkill]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "MetalDetector", PlayerInfo[playerid][pMetalDetector]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "HelpedBefore", PlayerInfo[playerid][pHelpedBefore]);
    SavePlayerInteger(query, GetPlayerSQLId(playerid), "Trickortreat", PlayerInfo[playerid][pTrickortreat]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "LastCharmReceived", PlayerInfo[playerid][pLastCharmReceived]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RHMutes", PlayerInfo[playerid][pRHMutes]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RHMuteTime", PlayerInfo[playerid][pRHMuteTime]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "GiftCode", PlayerInfo[playerid][pGiftCode]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Table", PlayerInfo[playerid][pTable]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "OpiumSeeds", PlayerInfo[playerid][pOpiumSeeds]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RawOpium", PlayerInfo[playerid][pRawOpium]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Heroin", PlayerInfo[playerid][pHeroin]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Syringe", PlayerInfo[playerid][pSyringes]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Skins", PlayerInfo[playerid][pSkins]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Hunger", PlayerInfo[playerid][pHunger]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "HungerTimer", PlayerInfo[playerid][pHungerTimer]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "HungerDeathTimer", PlayerInfo[playerid][pHungerDeathTimer]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Fitness", PlayerInfo[playerid][pFitness]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "HealthCare", PlayerInfo[playerid][pHealthCare]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "ReceivedCredits", PlayerInfo[playerid][pReceivedCredits]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RimMod", PlayerInfo[playerid][pRimMod]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Tazer", PlayerInfo[playerid][pHasTazer]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Cuff", PlayerInfo[playerid][pHasCuff]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "CarVoucher", PlayerInfo[playerid][pCarVoucher]);
	SavePlayerString(query, GetPlayerSQLId(playerid), "ReferredBy", PlayerInfo[playerid][pReferredBy]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "PendingRefReward", PlayerInfo[playerid][pPendingRefReward]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Refers", PlayerInfo[playerid][pRefers]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Famed", PlayerInfo[playerid][pFamed]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "FamedMuted", PlayerInfo[playerid][pFMuted]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "DefendTime", PlayerInfo[playerid][pDefendTime]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "PVIPVoucher", PlayerInfo[playerid][pPVIPVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VehicleSlot", PlayerInfo[playerid][pVehicleSlot]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "ToySlot", PlayerInfo[playerid][pToySlot]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RFLTeam", PlayerInfo[playerid][pRFLTeam]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "RFLTeamL", PlayerInfo[playerid][pRFLTeamL]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VehVoucher", PlayerInfo[playerid][pVehVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "SVIPVoucher", PlayerInfo[playerid][pSVIPVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "GVIPVoucher", PlayerInfo[playerid][pGVIPVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "GiftVoucher", PlayerInfo[playerid][pGiftVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "FallIntoFun", PlayerInfo[playerid][pFallIntoFun]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "HungerVoucher", PlayerInfo[playerid][pHungerVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "BoughtCure", PlayerInfo[playerid][pBoughtCure]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "Vials", PlayerInfo[playerid][pVials]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "AdvertVoucher", PlayerInfo[playerid][pAdvertVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "ShopCounter", PlayerInfo[playerid][pShopCounter]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "ShopNotice", PlayerInfo[playerid][pShopNotice]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "SVIPExVoucher", PlayerInfo[playerid][pSVIPExVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "GVIPExVoucher", PlayerInfo[playerid][pGVIPExVoucher]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "VIPSellable", PlayerInfo[playerid][pVIPSellable]);
	SavePlayerInteger(query, GetPlayerSQLId(playerid), "ReceivedPrize", PlayerInfo[playerid][pReceivedPrize]);
	SavePlayerString(query, GetPlayerSQLId(playerid), "InventoryData", PlayerInfo[playerid][pInventoryData]);
	
	MySQLUpdateFinish(query, GetPlayerSQLId(playerid));
	return 1;
}

stock SaveGate(id) {
	new string[512];
	format(string, sizeof(string), "UPDATE `gates` SET \
		`HID`=%d, \
		`Speed`=%f, \
		`Range`=%f, \
		`Model`=%d, \
		`VW`=%d, \
		`Int`=%d, \
		`Pass`='%s', \
		`PosX`=%f, \
		`PosY`=%f, \
		`PosZ`=%f, \
		`RotX`=%f, \
		`RotY`=%f, \
		`RotZ`=%f, \
		`PosXM`=%f, \
		`PosYM`=%f, \
		`PosZM`=%f, \
		`RotXM`=%f, \
		`RotYM`=%f, \
		`RotZM`=%f, \
		`Allegiance`=%d, \
		`GroupType`=%d, \
		`GroupID`=%d, \
		`FamilyID`=%d, \
		`RenderHQ`=%d, \
		`Timer`=%d, \
		`Automate`=%d, \
		`Locked`=%d \
		WHERE `ID` = %d",
		GateInfo[id][gHID],
		GateInfo[id][gSpeed],
		GateInfo[id][gRange],
		GateInfo[id][gModel],
		GateInfo[id][gVW],
		GateInfo[id][gInt],
		g_mysql_ReturnEscaped(GateInfo[id][gPass], MainPipeline),
		GateInfo[id][gPosX],
		GateInfo[id][gPosY],
		GateInfo[id][gPosZ],
		GateInfo[id][gRotX],
		GateInfo[id][gRotY],
		GateInfo[id][gRotZ],
		GateInfo[id][gPosXM],
		GateInfo[id][gPosYM],
		GateInfo[id][gPosZM],
		GateInfo[id][gRotXM],
		GateInfo[id][gRotYM],
		GateInfo[id][gRotZM],
		GateInfo[id][gAllegiance],
		GateInfo[id][gGroupType],
		GateInfo[id][gGroupID],
		GateInfo[id][gFamilyID],
		GateInfo[id][gRenderHQ],
		GateInfo[id][gTimer],
		GateInfo[id][gAutomate],
		GateInfo[id][gLocked],
		id+1
	);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 0;
}

stock SaveAuction(auction) {
	new query[200];
	format(query, sizeof(query), "UPDATE `auctions` SET");
	format(query, sizeof(query), "%s `BiddingFor` = '%s', `InProgress` = %d, `Bid` = %d, `Bidder` = %d, `Expires` = %d, `Wining` = '%s', `Increment` = %d", query, g_mysql_ReturnEscaped(Auctions[auction][BiddingFor], MainPipeline), Auctions[auction][InProgress], Auctions[auction][Bid], Auctions[auction][Bidder], Auctions[auction][Expires], g_mysql_ReturnEscaped(Auctions[auction][Wining], MainPipeline), Auctions[auction][Increment]);
    format(query, sizeof(query), "%s WHERE `id` = %d", query, auction+1);
    mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);
}

stock SaveDealershipSpawn(businessid) {
	new query[200];
	format(query, sizeof(query), "UPDATE `businesses` SET");
	format(query, sizeof(query), "%s `PurchaseX` = %0.5f, `PurchaseY` = %0.5f, `PurchaseZ` = %0.5f, `PurchaseAngle` = %0.5f", query, Businesses[businessid][bPurchaseX], Businesses[businessid][bPurchaseY], Businesses[businessid][bPurchaseZ], Businesses[businessid][bPurchaseAngle]);
    format(query, sizeof(query), "%s WHERE `Id` = %d", query, businessid+1);
    mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);
}

stock SaveDealershipVehicle(businessid, slotid)
{
	new query[256];
	//slotid++;
	format(query, sizeof(query), "UPDATE `businesses` SET");
	format(query, sizeof(query), "%s `Car%dPosX` = %0.5f,", query, slotid, Businesses[businessid][bParkPosX][slotid]);
	format(query, sizeof(query), "%s `Car%dPosY` = %0.5f,", query, slotid, Businesses[businessid][bParkPosY][slotid]);
	format(query, sizeof(query), "%s `Car%dPosZ` = %0.5f,", query, slotid, Businesses[businessid][bParkPosZ][slotid]);
	format(query, sizeof(query), "%s `Car%dPosAngle` = %0.5f,", query, slotid, Businesses[businessid][bParkAngle][slotid]);
	format(query, sizeof(query), "%s `Car%dModelId` = %d,", query, slotid, Businesses[businessid][bModel][slotid]);
	format(query, sizeof(query), "%s `Car%dPrice` = %d", query, slotid, Businesses[businessid][bPrice][slotid]);
	format(query, sizeof(query), "%s WHERE `Id` = %d", query, businessid+1);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "ii", SENDDATA_THREAD, INVALID_PLAYER_ID);
}

stock GetLatestKills(playerid, giveplayerid)
{
	new query[256];
	format(query, sizeof(query), "SELECT Killer.Username, Killed.Username, k.* FROM kills k LEFT JOIN accounts Killed ON k.killedid = Killed.id LEFT JOIN accounts Killer ON Killer.id = k.killerid WHERE k.killerid = %d OR k.killedid = %d ORDER BY `date` DESC LIMIT 10", GetPlayerSQLId(giveplayerid), GetPlayerSQLId(giveplayerid));
	mysql_pquery(MainPipeline, query, "OnGetLatestKills", "ii", playerid, giveplayerid);
}

stock GetSMSLog(playerid)
{
	new query[256];
	format(query, sizeof(query), "SELECT `sender`, `sendernumber`, `message`, `date` FROM `sms` WHERE `receiverid` = %d ORDER BY `date` DESC LIMIT 10", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, query, "OnGetSMSLog", "i", playerid);
}

stock LoadBusinessSales() {

	print("[LoadBusinessSales] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `businesssales`", "LoadBusinessesSaless", "");
}

stock LoadBusinesses() {
	printf("[LoadBusinesses] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT OwnerName.Username, b.* FROM businesses b LEFT JOIN accounts OwnerName ON b.OwnerID = OwnerName.id", "BusinessesLoadQueryFinish", "");
}

stock LoadAuctions() {
	printf("[LoadAuctions] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `auctions`", "AuctionLoadQuery", "");
}

stock LoadPlants() {
	printf("[LoadPlants] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `plants`", "PlantsLoadQuery", "");
}

stock SaveBusinessSale(id)
{
	new query[200];
	format(query, 200, "UPDATE `businesssales` SET `BusinessID` = '%d', `Text` = '%s', `Price` = '%d', `Available` = '%d', `Purchased` = '%d', `Type` = '%d' WHERE `bID` = '%d'", BusinessSales[id][bBusinessID], BusinessSales[id][bText],
	BusinessSales[id][bPrice], BusinessSales[id][bAvailable], BusinessSales[id][bPurchased], BusinessSales[id][bType], BusinessSales[id][bID]);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	printf("[BusinessSale] saved %i", id);
	return 1;
}

stock SavePlant(plant)
{
	new query[300];
	format(query, sizeof(query), "UPDATE `plants` SET `Owner` = %d, `Object` = %d, `PlantType` = %d, `PositionX` = %f, `PositionY` = %f, `PositionZ` = %f, `Virtual` = %d, \
	`Interior` = %d, `Growth` = %d, `Expires` = %d, `DrugsSkill` = %d WHERE `PlantID` = %d",Plants[plant][pOwner], Plants[plant][pObject], Plants[plant][pPlantType], Plants[plant][pPos][0], Plants[plant][pPos][1], Plants[plant][pPos][2],
	Plants[plant][pVirtual], Plants[plant][pInterior], Plants[plant][pGrowth], Plants[plant][pExpires], Plants[plant][pDrugsSkill], plant+1);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

stock SaveBusiness(id)
{
	new query[4019];

	format(query, sizeof(query), "UPDATE `businesses` SET ");

	format(query, sizeof(query), "%s \
	`Name` = '%s', `Type` = %d, `Value` = %d, `OwnerID` = %d, `Months` = %d, `SafeBalance` = %d, `Inventory` = %d, `InventoryCapacity` = %d, `Status` = %d, `Level` = %d, \
	`LevelProgress` = %d, `AutoSale` = %d, `OrderDate` = '%s', `OrderAmount` = %d, `OrderBy` = '%s', `OrderState` = %d, `TotalSales` = %d, ",
	query,
	g_mysql_ReturnEscaped(Businesses[id][bName], MainPipeline), Businesses[id][bType], Businesses[id][bValue], Businesses[id][bOwner], Businesses[id][bMonths], Businesses[id][bSafeBalance], Businesses[id][bInventory], Businesses[id][bInventoryCapacity], Businesses[id][bStatus], Businesses[id][bLevel],
	Businesses[id][bLevelProgress], Businesses[id][bAutoSale], Businesses[id][bOrderDate], Businesses[id][bOrderAmount], g_mysql_ReturnEscaped(Businesses[id][bOrderBy], MainPipeline), Businesses[id][bOrderState], Businesses[id][bTotalSales]);

	format(query, sizeof(query), "%s \
	`ExteriorX` = %f, `ExteriorY` = %f, `ExteriorZ` = %f, `ExteriorA` = %f, \
	`InteriorX` = %f, `InteriorY` = %f, `InteriorZ` = %f, `InteriorA` = %f, \
	`Interior` = %d, `CustomExterior` = %d, `CustomInterior` = %d, `Grade` = %d, `CustomVW` = %d, `SupplyPointX` = %f, `SupplyPointY` = %f, `SupplyPointZ` = %f, ",
	query,
	Businesses[id][bExtPos][0],	Businesses[id][bExtPos][1],	Businesses[id][bExtPos][2],	Businesses[id][bExtPos][3],
	Businesses[id][bIntPos][0],	Businesses[id][bIntPos][1], Businesses[id][bIntPos][2], Businesses[id][bIntPos][3],
	Businesses[id][bInt], Businesses[id][bCustomExterior], Businesses[id][bCustomInterior], Businesses[id][bGrade], Businesses[id][bVW], Businesses[id][bSupplyPos][0],Businesses[id][bSupplyPos][1], Businesses[id][bSupplyPos][2]);

	for (new i; i < 17; i++) format(query, sizeof(query), "%s`Item%dPrice` = %d, ", query, i+1, Businesses[id][bItemPrices][i]);
	for (new i; i < 5; i++)	format(query, sizeof(query), "%s`Rank%dPay` = %d, ", query, i, Businesses[id][bRankPay][i], id);
	for (new i; i < MAX_BUSINESS_GAS_PUMPS; i++) format(query, sizeof(query), "%s `GasPump%dPosX` = %f, `GasPump%dPosY` = %f, `GasPump%dPosZ` = %f, `GasPump%dAngle` = %f, `GasPump%dModel` = %d, `GasPump%dCapacity` = %f, `GasPump%dGas` = %f, ", query, i+1, Businesses[id][GasPumpPosX][i],	i+1, Businesses[id][GasPumpPosY][i], i+1, Businesses[id][GasPumpPosZ][i], i+1, Businesses[id][GasPumpAngle][i], i+1, 1646,i+1, Businesses[id][GasPumpCapacity],	i+1, Businesses[id][GasPumpGallons]);

	format(query, sizeof(query), "%s \
	`Pay` = %d, `GasPrice` = %f, `MinInviteRank` = %d, `MinSupplyRank` = %d, `MinGiveRankRank` = %d, `MinSafeRank` = %d, `GymEntryFee` = %d, `GymType` = %d, `TotalProfits` = %d WHERE `Id` = %d",
	query,
	Businesses[id][bAutoPay], Businesses[id][bGasPrice], Businesses[id][bMinInviteRank], Businesses[id][bMinSupplyRank], Businesses[id][bMinGiveRankRank], Businesses[id][bMinSafeRank], Businesses[id][bGymEntryFee], Businesses[id][bGymType], Businesses[id][bTotalProfits], id+1);

	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);

 	//printf("Len :%d", strlen(query));
	printf("[business] saved %i", id);

	return 1;
}

//--------------------------------[ CUSTOM PUBLIC FUNCTIONS ]---------------------------

forward OnPhoneNumberCheck(index, extraid);
public OnPhoneNumberCheck(index, extraid)
{
	if(IsPlayerConnected(index))
	{
		new string[128];
		new rows, fields;
		cache_get_data(rows, fields);

		switch(extraid)
		{
			case 1: {
				if(rows)
				{
					SendClientMessageEx(index, COLOR_WHITE, "So dien thoat da duoc lay");
					DeletePVar(index, "PhChangerId");
					DeletePVar(index, "WantedPh");
					DeletePVar(index, "PhChangeCost");
					DeletePVar(index, "CurrentPh");
				}
				else
				{
					format(string,sizeof(string),"Cac so dien thoai yeu cau, %d, se co gia tong cong $%s.\n\nDe xac nhan, bam Dong y.", GetPVarInt(index, "WantedPh"), number_format(GetPVarInt(index, "PhChangeCost")));
					ShowPlayerDialog(index, VIPNUMMENU2, DIALOG_STYLE_MSGBOX, "Xac nhan", string, "Dong y", "Huy bo");
				}
			}
			case 2: {
				if(rows)
				{
					SendClientMessageEx(index, COLOR_WHITE, "Do la so dien thoai da duoc lay.");
				}
				else
				{
					PlayerInfo[index][pPnumber] = GetPVarInt(index, "WantedPh");
					GivePlayerCash(index, -GetPVarInt(index, "PhChangeCost"));
					format(string, sizeof(string), "Mua so dien thoai, so dien thoai moi cua ban la %d.", GetPVarInt(index, "WantedPh"));
					SendClientMessageEx(index, COLOR_GRAD4, string);
					SendClientMessageEx(index, COLOR_GRAD5, "Ban co the kiem tra so dien thoat cua ban bat cu luc nao bang /thongtin.");
					SendClientMessageEx(index, COLOR_WHITE, "HINT: Ban su dung /trogiupdienthoai de xem cac lenh lien quan toi dien thoai.");
					format(string, sizeof(string), "UPDATE `accounts` SET `PhoneNr` = %d WHERE `id` = '%d'", PlayerInfo[index][pPnumber], GetPlayerSQLId(index));
					mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, index);
					DeletePVar(index, "PhChangerId");
					DeletePVar(index, "WantedPh");
					DeletePVar(index, "PhChangeCost");
					DeletePVar(index, "CurrentPh");
				}
			}
			case 3: {
				if(rows && GetPVarInt(index, "WantedPh") != 0)
				{
					SendClientMessageEx(index, COLOR_WHITE, "Do la so dien thoai da duoc lay.");
				}
				else
				{
					PlayerInfo[index][pPnumber] = GetPVarInt(index, "WantedPh");
					format(string, sizeof(string), "   %s's So dien thoai da duoc thiet lap thanh %d.", GetPlayerNameEx(index), GetPVarInt(index, "WantedPh"));

					format(string, sizeof(string), "%s boi %s", string, GetPlayerNameEx(index));
					Log("logs/undercover.log", string);
					SendClientMessageEx(index, COLOR_GRAD1, string);
					format(string, sizeof(string), "UPDATE `accounts` SET `PhoneNr` = %d WHERE `id` = '%d'", PlayerInfo[index][pPnumber], GetPlayerSQLId(index));
					mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, index);
					DeletePVar(index, "PhChangerId");
					DeletePVar(index, "WantedPh");
					DeletePVar(index, "PhChangeCost");
					DeletePVar(index, "CurrentPh");
				}
			}
			case 4: {
				if(IsPlayerConnected(GetPVarInt(index, "PhChangerId")))
				{
					if(rows)
					{
						SendClientMessageEx(GetPVarInt(index, "PhChangerId"), COLOR_WHITE, "Do la so dien thoai da duoc lay.");
					}
					else
					{
						PlayerInfo[index][pPnumber] = GetPVarInt(index, "WantedPh");
						format(string, sizeof(string), "   %s's So dien thoai da duoc thiet lap thanh %d.", GetPlayerNameEx(index), GetPVarInt(index, "WantedPh"));

						format(string, sizeof(string), "%s boi %s", string, GetPlayerNameEx(GetPVarInt(index, "PhChangerId")));
						Log("logs/stats.log", string);
						SendClientMessageEx(GetPVarInt(index, "PhChangerId"), COLOR_GRAD1, string);
						format(string, sizeof(string), "UPDATE `accounts` SET `PhoneNr` = %d WHERE `id` = '%d'", PlayerInfo[index][pPnumber], GetPlayerSQLId(index));
						mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, index);
						DeletePVar(index, "PhChangerId");
						DeletePVar(index, "WantedPh");
						DeletePVar(index, "PhChangeCost");
						DeletePVar(index, "CurrentPh");
					}
				}
			}
		}
	}
	return 1;
}

forward AddingBan(index, type);
public AddingBan(index, type)
{
    if(IsPlayerConnected(index))
	{
	    if(type == 1) // Add Ban
	    {
    		new rows, fields;
    		cache_get_data(rows, fields);
    		if(rows)
    		{
    		    DeletePVar(index, "BanningPlayer");
    		    DeletePVar(index, "BanningReason");
    		    SendClientMessageEx(index, COLOR_GREY, "Nguoi choi da bi cam.");
    		}
    		else
    		{
    		    if(IsPlayerConnected(GetPVarInt(index, "BanningPlayer")))
    		    {
    		    	new string[150], reason[64];
    		    	GetPVarString(index, "BanningReason", reason, sizeof(reason));

		    	    format(string, sizeof(string), "INSERT INTO `ip_bans` (`ip`, `date`, `reason`, `admin`) VALUES ('%s', NOW(), '%s', '%s')", GetPlayerIpEx(GetPVarInt(index, "BanningPlayer")), reason, GetPlayerNameEx(index));
					mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);

					DeletePVar(index, "BanningPlayer");
		    	    DeletePVar(index, "BanningReason");
				}
	    	}
		}
		else if(type == 2) // Unban IP
		{
		    new rows, fields;
		    cache_get_data(rows, fields);
		    if(rows)
		    {
		        new string[128], ip[32];
		        GetPVarString(index, "UnbanIP", ip, sizeof(ip));

		        format(string, sizeof(string), "DELETE FROM `ip_bans` WHERE `ip` = '%s'", ip);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);

				DeletePVar(index, "UnbanIP");
		    }
		    else
		    {
		        SendClientMessageEx(index, COLOR_GREY, "Dia chi IP khong duoc tim thay trong co so du lieu cua ban.");
				DeletePVar(index, "UnbanIP");
			}
		}
		else if(type == 3) // Ban IP
		{
		    new rows, fields;
		    cache_get_data(rows, fields);
		    if(rows)
		    {
		        SendClientMessageEx(index, COLOR_GREY, "Dia chi IP bi cam.");
				DeletePVar(index, "BanIP");
		    }
		    else
		    {
		        new string[128], ip[32];
		        GetPVarString(index, "BanIP", ip, sizeof(ip));
		        format(string, sizeof(string), "INSERT INTO `ip_bans` (`ip`, `date`, `reason`, `admin`) VALUES ('%s', NOW(), '%s', '%s')", ip, "/banip", GetPlayerNameEx(index));
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);

		        SendClientMessageEx(index, COLOR_WHITE, "Dia chi IP da bi cam thanh cong.");
				DeletePVar(index, "BanIP");
			}
		}
	}
	return 1;
}

forward MailsQueryFinish(playerid);
public MailsQueryFinish(playerid)
{

    new rows, fields;
	cache_get_data(rows, fields);

	if (rows == 0) {
		ShowPlayerDialog(playerid, DIALOG_NOTHING, DIALOG_STYLE_MSGBOX, " ", "Hop thu cua ban trong.", "Dong y", "");
		return 1;
	}

    new id, string[2000], message[129], tmp[128], read;
	for(new i; i < rows;i++)
	{
    	cache_get_value_name(i, "Id", tmp);  	id = strval(tmp);
    	cache_get_value_name(i, "Read", tmp); read= strval(tmp);
    	cache_get_value_name(i, "Message", message, 129);
		strmid(message,message,0,30);
		if (strlen(message) > 30) strcat(message,"...");
		strcat(string, (read) ? ("{BBBBBB}") : ("{FFFFFF}"));
		strcat(string, message);
		if (i != rows - 1) strcat(string, "\n");
		ListItemTrackId[playerid][i] = id;
	}

    ShowPlayerDialog(playerid, DIALOG_POMAILS, DIALOG_STYLE_LIST, "Mail cua ban", string, "Doc", "Dong");

	return 1;
}

forward MailDetailsQueryFinish(playerid);
public MailDetailsQueryFinish(playerid)
{
	new string[256];
    new rows, fields;
	cache_get_data(rows, fields);

	new senderid, sender[MAX_PLAYER_NAME], message[131], notify, szTmp[128], Date[32], read, id;
	cache_get_value_name(0, "Id", szTmp);	    	id = strval(szTmp);
	cache_get_value_name(0, "Notify", szTmp);	    notify = strval(szTmp);
	cache_get_value_name(0, "Sender_Id", szTmp);	senderid = strval(szTmp);
	cache_get_value_name(0, "Read", szTmp);		read = strval(szTmp);
	cache_get_value_name(0, "Message", message, 131);
	cache_get_value_name(0, "SenderUser", sender, MAX_PLAYER_NAME);
	cache_get_value_name(0, "Date", Date, 32);

	if (strlen(message) > 80) strins(message, "\n", 70);

	format(string, sizeof(string), "{EEEEEE}%s\n\n{BBBBBB}Nguoi gui: {FFFFFF}%s\n{BBBBBB}Ngay: {EEEEEE}%s", message, sender,Date);
	ShowPlayerDialog(playerid, DIALOG_PODETAIL, DIALOG_STYLE_MSGBOX, "Mail Content", string, "Quay lai", "Thu rac");

	if (notify && !read) {
		foreach(new i: Player)
		{
			if (GetPlayerSQLId(i) == senderid)	{
			    format(string, sizeof(string), "Tin nhan cua ban vua duoc doc boi %s!", GetPlayerNameEx(playerid));
			    SendClientMessageEx(i, COLOR_YELLOW, string);
			    break;
			}
		}
	}

	format(string, sizeof(string), "UPDATE `letters` SET `Read` = 1 WHERE `id` = %d", id);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);

	return 1;
}


forward MailDeliveryQueryFinish();
public MailDeliveryQueryFinish()
{

    new rows, fields, id, tmp[128], i;
	cache_get_data(rows, fields);

	for(; i < rows;i++)
	{
    	cache_get_value_name(i, "Receiver_Id", tmp);
    	id = strval(tmp);
		foreach(new j: Player)
		{
			if (GetPlayerSQLId(j) == id) {
				if (PlayerInfo[j][pDonateRank] >= 4 && HasMailbox(j))	{
					SendClientMessageEx(j, COLOR_YELLOW, "Mot tin nhan vua duoc gui den hop mail cua ban.");
					SetPVarInt(j, "UnreadMails", 1);
					break;
				}

			}
		}
 	}

	return 1;

}


forward MDCQueryFinish(playerid, suspectid);
public MDCQueryFinish(playerid, suspectid)
{
    new rows, fields;
	cache_get_data(rows, fields);
    new resultline[1424];
    new crimes = PlayerInfo[suspectid][pCrimes];
	new arrests = PlayerInfo[suspectid][pArrested];
	format(resultline, sizeof(resultline), "{FF6347}Ten:{BFC0C2} %s\t{FF6347}So dien thoai:{BFC0C2} %d\n{FF6347}Tong so toi ac: {BFC0C2}%d\t {FF6347}Tong lan bat giu: {BFC0C2}%d \n{FF6347}Crime Key: {FF7D7D}Truy na hien tai/{BFC0C2}Toi ac qua khu\n\n", GetPlayerNameEx(suspectid),PlayerInfo[suspectid][pPnumber], crimes, arrests);

	for(new i; i < rows; i++)
	{
	    cache_get_value_name(i, "issuer", MDCInfo[i][mdcIssuer], MAX_PLAYER_NAME);
	    cache_get_value_name(i, "crime", MDCInfo[i][mdcCrime], 64);
	    cache_get_value_name(i, "active", MDCInfo[i][mdcActive], 2);
	    if(strval(MDCInfo[i][mdcActive]) == 1)
	    {
	        format(resultline, sizeof(resultline),"%s{FF6347}Crime: {FF7D7D}%s \t{FF6347}Charged by:{BFC0C2} %s\n",resultline, MDCInfo[i][mdcCrime], MDCInfo[i][mdcIssuer]);
		} else {
			format(resultline, sizeof(resultline),"%s{FF6347}Crime: {BFC0C2}%s \t{FF6347}Charged by:{BFC0C2} %s\n",resultline, MDCInfo[i][mdcCrime], MDCInfo[i][mdcIssuer]);
		}
	}
	ShowPlayerDialog(playerid, MDC_SHOWCRIMES, DIALOG_STYLE_MSGBOX, "SA-MDC - Criminal History", resultline, "Quay lai", "");
	return 1;
}

forward MDCReportsQueryFinish(playerid, suspectid);
public MDCReportsQueryFinish(playerid, suspectid)
{
    new rows, fields;
	cache_get_data(rows, fields);
    new resultline[1424], str[12];
    new copname[MAX_PLAYER_NAME], datetime[64], reportsid;
	for(new i; i < rows; i++)
	{
		cache_get_value_name(i, "id", str, 12); reportsid = strval(str); 
	    cache_get_value_name(i, "Username", copname, MAX_PLAYER_NAME);
	    cache_get_value_name(i, "datetime", datetime, 64);
	    format(resultline, sizeof(resultline),"%s{FF6347}Bao cao (%d) {FF7D7D}Arrested by: %s on %s\n",resultline, reportsid, copname,datetime);
	}
	ShowPlayerDialog(playerid, MDC_SHOWREPORTS, DIALOG_STYLE_LIST, "SA-MDC - Criminal History", resultline, "Quay lai", "");
	return 1;
}

forward MDCReportQueryFinish(playerid, reportid);
public MDCReportQueryFinish(playerid, reportid)
{
    new rows, fields;
	cache_get_data(rows, fields);
    new resultline[1424];
    new copname[MAX_PLAYER_NAME], datetime[64], shortreport[200];
	for(new i; i < rows; i++)
	{
	    cache_get_value_name(i, "Username", copname, MAX_PLAYER_NAME);
	    cache_get_value_name(i, "datetime", datetime, 64);
	    cache_get_value_name(i, "shortreport", shortreport, 200);
	    format(resultline, sizeof(resultline),"{FF6347}Bao cao #%d\n{FF7D7D}Arrested by: %s on %s\n{FF6347}Bao cao:{BFC0C2} %s\n",reportid, copname,datetime, shortreport);
	}
	ShowPlayerDialog(playerid, MDC_SHOWCRIMES, DIALOG_STYLE_MSGBOX, "SA-MDC - Arrest Report", resultline, "Quay lai", "");
	return 1;
}

forward FlagQueryFinish(playerid, suspectid, queryid);
public FlagQueryFinish(playerid, suspectid, queryid)
{
    new rows, fields;
	cache_get_data(rows, fields);
    new resultline[2000];
    new header[64], sResult[64];
    new FlagID, FlagIssuer[MAX_PLAYER_NAME], FlagText[64], FlagDate[24];
	switch(queryid)
	{
	    case Flag_Query_Display:
	    {
			format(header, sizeof(header), "{FF6347}Flag History for{BFC0C2} %s", GetPlayerNameEx(suspectid));

			for(new i; i < rows; i++)
			{
			    cache_get_value_name(i, "fid", sResult); FlagID = strval(sResult);
			    cache_get_value_name(i, "issuer", FlagIssuer, MAX_PLAYER_NAME);
			    cache_get_value_name(i, "flag", FlagText, 64);
			    cache_get_value_name(i, "time", FlagDate, 24);
				format(resultline, sizeof(resultline),"%s{FF6347}Flag (ID: %d): {BFC0C2} %s \t{FF6347}Issued by:{BFC0C2} %s \t{FF6347}Date: {BFC0C2}%s\n",resultline, FlagID, FlagText, FlagIssuer, FlagDate);
			}
			if(rows == 0)
			{
				format(resultline, sizeof(resultline),"{FF6347}No Flags on this account");
			}
			ShowPlayerDialog(playerid, FLAG_LIST, DIALOG_STYLE_MSGBOX, header, resultline, "Delete Flag", "Dong");
		}
		case Flag_Query_Offline:
		{
			new string[128], name[24], reason[64], psqlid[12];
			GetPVarString(playerid, "OnAddFlag", name, 24);
			GetPVarString(playerid, "OnAddFlagReason", reason, 64);
			SendClientMessage(playerid, COLOR_YELLOW, string);
			if(rows > 0) {
				format(string, sizeof(string), "You have appended %s's flag.", name);
				SendClientMessageEx(playerid, COLOR_WHITE, string);

				format(string, sizeof(string), "AdmCmd: %s was offline flagged by %s, reason: %s.", name, GetPlayerNameEx(playerid), reason);
				ABroadCast(COLOR_LIGHTRED, string, 2);

				format(string, sizeof(string), "%s was offline flagged by %s (%s).", name, GetPlayerNameEx(playerid), reason);
				Log("logs/flags.log", string);

				cache_get_value_name(0, "id", psqlid);

				AddOFlag(strval(psqlid), playerid, reason);
			}
			else {
				format(string, sizeof(string), "There was a problem with appending %s's flag.", name);
				SendClientMessageEx(playerid, COLOR_WHITE, string);
			}
			DeletePVar(playerid, "OnAddFlagReason");
		}
		case Flag_Query_Count:
		{
		    PlayerInfo[playerid][pFlagged] = rows;
		}
	}
	return 1;
}

forward SkinQueryFinish(playerid, queryid);
public SkinQueryFinish(playerid, queryid)
{
    new rows, fields;
	cache_get_data(rows, fields);
    new resultline[2000], header[32], sResult[64], skinid;
	switch(queryid)
	{
	    case Skin_Query_Display:
	    {
			if(PlayerInfo[playerid][pDonateRank] <= 0) format(header, sizeof(header), "Closet -- Space: %d/10", PlayerInfo[playerid][pSkins]);
			else if(PlayerInfo[playerid][pDonateRank] > 0) format(header, sizeof(header), "Closet -- Space: %d/25", PlayerInfo[playerid][pSkins]);

			if(rows == 0) return SendClientMessageEx(playerid, COLOR_GREY, "There are no clothes in this closet!");
			for(new i; i < rows; i++)
			{
			    cache_get_value_name(i, "skinid", sResult); skinid = strval(sResult);
				format(resultline, sizeof(resultline),"%sSkin ID: %d\n",resultline, skinid);
			}
			ShowPlayerDialog(playerid, SKIN_LIST, DIALOG_STYLE_LIST, header, resultline, "Select", "Cancel");
		}
		case Skin_Query_Count:
		{
		    PlayerInfo[playerid][pSkins] = rows;
		}
		case Skin_Query_ID:
		{
		    for(new i; i < rows; i++)
			{
			    cache_get_value_name(i, "skinid", sResult); skinid = strval(sResult);
				if(i == GetPVarInt(playerid, "closetchoiceid"))
				{
					SetPVarInt(playerid, "closetskinid", skinid);
					SetPlayerSkin(playerid, skinid);
					ShowPlayerDialog(playerid, SKIN_CONFIRM, DIALOG_STYLE_MSGBOX, "Tu quan ao", "Ban muon thay doi quan ao?", "Dong y", "Quay lai");
				}
			}
		}
		case Skin_Query_Delete:
	    {
			if(PlayerInfo[playerid][pDonateRank] <= 0) format(header, sizeof(header), "Closet -- Space: %d/10", PlayerInfo[playerid][pSkins]);
			else if(PlayerInfo[playerid][pDonateRank] > 0) format(header, sizeof(header), "Closet -- Space: %d/25", PlayerInfo[playerid][pSkins]);

			if(rows == 0) return SendClientMessageEx(playerid, COLOR_GREY, "Khong co quan ao trong tu!");
			for(new i; i < rows; i++)
			{
			    cache_get_value_name(i, "skinid", sResult); skinid = strval(sResult);
				format(resultline, sizeof(resultline),"%sSkin ID: %d\n",resultline, skinid);
			}
			ShowPlayerDialog(playerid, SKIN_DELETE, DIALOG_STYLE_LIST, header, resultline, "Chon", "Huy bo");
		}
		case Skin_Query_Delete_ID:
		{
		    for(new i; i < rows; i++)
			{
			    cache_get_value_name(i, "id", sResult); skinid = strval(sResult);
				if(i == GetPVarInt(playerid, "closetchoiceid"))
				{
					SetPVarInt(playerid, "closetskinid", skinid);
					ShowPlayerDialog(playerid, SKIN_DELETE2, DIALOG_STYLE_MSGBOX, "Closet", "Ban co chac chan muon loai bo quan ao nay?", "Dong y", "Huy bo");
				}
			}
		}
	}
	return 1;
}


forward CitizenQueryFinish(playerid, queryid);
public CitizenQueryFinish(playerid, queryid)
{
    new rows, fields;
	cache_get_data(rows, fields);
	switch(queryid)
	{
	    case TR_Citizen_Count:
	    {
			TRCitizens = rows;
		}
		case Total_Count:
		{
		    TotalCitizens = rows;
		}
	}
	return 1;
}

forward NationQueueQueryFinish(playerid, nation, queryid);
public NationQueueQueryFinish(playerid, nation, queryid)
{
    new query[300], resultline[2000], sResult[64], rows, fields;
	cache_get_data(rows, fields);
	switch(queryid)
	{
		case CheckQueue:
	    {
			if(rows == 0)
			{
				format(query, sizeof(query), "INSERT INTO `nation_queue` (`id`, `playerid`, `name`, `date`, `nation`, `status`) VALUES (NULL, %d, '%s', NOW(), %d, 1)", GetPlayerSQLId(playerid), GetPlayerNameEx(playerid), nation);
				mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
				SendClientMessageEx(playerid, COLOR_GREY, "Ban da duoc them vao danh sach yeu cau vao quoc gia. Bay gio lanh dao cua quoc gia co the chon chap nhan hoac tu choi yeu cau cua ban.");
			}
			else
			{
				SendClientMessageEx(playerid, COLOR_GREY, "Ban da co trong hang doi de tham gia vao mot quoc gia.");
			}
		}
		case UpdateQueue:
	    {
			if(rows > 0)
			{
				format(query, sizeof(query), "UPDATE `nation_queue` SET `name` = '%s' WHERE `playerid` = %d", GetPlayerNameEx(playerid), GetPlayerSQLId(playerid));
				mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
		}
		case AppQueue:
	    {
			new sDate[32];
			if(rows == 0) return SendClientMessageEx(playerid, COLOR_GREY, "Hien tai khong co yeu cau dang cho giai quyet.");
			for(new i; i < rows; i++)
			{
				cache_get_value_name(i, "name", sResult, MAX_PLAYER_NAME);
				cache_get_value_name(i, "date", sDate, 32);
				format(resultline, sizeof(resultline), "%s%s -- Date Submitted: %s\n", resultline, sResult, sDate);
			}
			ShowPlayerDialog(playerid, NATION_APP_LIST, DIALOG_STYLE_LIST, "Yeu cau vao quoc gia", resultline, "Chon", "Huy bo");
		}
	    case AddQueue:
	    {
			if(rows == 0)
			{
				format(query, sizeof(query), "INSERT INTO `nation_queue` (`id`, `playerid`, `name`, `date`, `nation`, `status`) VALUES (NULL, %d, '%s', NOW(), %d, 2)", GetPlayerSQLId(playerid), GetPlayerNameEx(playerid), nation);
				mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
				PlayerInfo[playerid][pNation] = 1;
			}
			else
			{
				format(query, sizeof(query), "INSERT INTO `nation_queue` (`id`, `playerid`, `name`, `date`, `nation`, `status`) VALUES (NULL, %d, NOW(), %d, 1)", GetPlayerSQLId(playerid), GetPlayerNameEx(playerid), nation);
				mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
		}
	}
	return 1;
}

forward NationAppFinish(playerid, queryid);
public NationAppFinish(playerid, queryid)
{
    new query[300], string[128], sResult[64], rows, fields;
	cache_get_data(rows, fields);
	switch(queryid)
	{
		case AcceptApp:
	    {
			for(new i; i < rows; i++)
			{
				cache_get_value_name(i, "id", sResult); new AppID = strval(sResult);
				cache_get_value_name(i, "playerid", sResult); new UserID = strval(sResult);
				cache_get_value_name(i, "name", sResult, MAX_PLAYER_NAME);
				if(GetPVarInt(playerid, "Nation_App_ID") == i)
				{
					format(query, sizeof(query), "UPDATE `nation_queue` SET `status` = 2 WHERE `id` = %d", AppID);
					mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);

					new giveplayerid = ReturnUser(sResult);
					switch(arrGroupData[PlayerInfo[playerid][pMember]][g_iAllegiance])
					{
						case 1:
						{
							if(IsPlayerConnected(giveplayerid))
							{
								PlayerInfo[giveplayerid][pNation] = 0;
								SendClientMessageEx(giveplayerid, COLOR_WHITE, "Yeu cau cua ban vao cong dan San Andreas da duoc phe duyet!");
							}
							else
							{
								format(query, sizeof(query), "UPDATE `accounts` SET `Nation` = 0 WHERE `id` = %d", UserID);
								mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
							}
							format(string, sizeof(string), "%s da phe duyet %s's yeu cau la cong dan San Andreas", GetPlayerNameEx(playerid), sResult);
						}
						case 2:
						{
							if(IsPlayerConnected(giveplayerid))
							{
								PlayerInfo[giveplayerid][pNation] = 1;
								SendClientMessageEx(giveplayerid, COLOR_WHITE, "Yeu cau cua ban la cong dan Tierra Robada da duoc phe duyet!");
							}
							else
							{
								format(query, sizeof(query), "UPDATE `accounts` SET `Nation` = 1 WHERE `id` = %d", UserID);
								mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
							}
							format(string, sizeof(string), "%s da phe duyet %s's yeu cau la cong dan Tierra Robada", GetPlayerNameEx(playerid), sResult);
						}
					}
					Log("logs/gov.log", string);
					format(string, sizeof(string), "Ban da phe duyet thanh cong yeu cau cua %s's.", sResult);
					SendClientMessageEx(playerid, COLOR_WHITE, string);
					DeletePVar(playerid, "Nation_App_ID");
				}
			}
		}
	    case DenyApp:
	    {
			for(new i; i < rows; i++)
			{
				cache_get_value_name(i, "id", sResult, 32); new AppID = strval(sResult);
				cache_get_value_name(i, "name", sResult, MAX_PLAYER_NAME);
				if(GetPVarInt(playerid, "Nation_App_ID") == i)
				{
					format(query, sizeof(query), "UPDATE `nation_queue` SET `status` = 3 WHERE `id` = %d", AppID);
					mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
					new giveplayerid = ReturnUser(sResult);
					switch(arrGroupData[PlayerInfo[playerid][pMember]][g_iAllegiance])
					{
						case 1:
						{
							if(IsPlayerConnected(giveplayerid)) SendClientMessageEx(giveplayerid, COLOR_GREY, "Yeu cau la cong dan San Andreas bi tu choi.");
							format(string, sizeof(string), "%s has denied %s's application for San Andreas citizenship", GetPlayerNameEx(playerid), sResult);
						}
						case 2:
						{
							if(IsPlayerConnected(giveplayerid)) SendClientMessageEx(giveplayerid, COLOR_GREY, "Yeu cau la cong San Andreas cua ban bi tu choi.");
							format(string, sizeof(string), "%s has denied %s's application for Tierra Robada citizenship", GetPlayerNameEx(playerid), sResult);
						}
					}
					Log("logs/gov.log", string);
					format(string, sizeof(string), "Ban da tu choi thanh cong yeu cau %s's.", sResult);
					SendClientMessageEx(playerid, COLOR_WHITE, string);
					DeletePVar(playerid, "Nation_App_ID");
				}
			}
		}
	}
	return 1;
}

forward CountAmount(playerid);
public CountAmount(playerid)
{
    new rows, fields;
	cache_get_data(rows, fields);
	PlayerInfo[playerid][pLottoNr] = rows;
	return 1;
}

forward UnreadMailsNotificationQueryFin(playerid);
public UnreadMailsNotificationQueryFin(playerid)
{
	new szResult[8];
	cache_get_value_name(0, "Unread_Count", szResult);
	if (strval(szResult) > 0) {
		SetPVarInt(playerid, "UnreadMails", 1);
		SendClientMessageEx(playerid, COLOR_YELLOW, "Ban co cac thu chua doc trong hop thu cua minh.");
	}
	return 1;
}


forward RecipientLookupFinish(playerid);
public RecipientLookupFinish(playerid)
{
	new rows,fields,szResult[16], admin, undercover, id;
	cache_get_data(rows, fields);

	if (!rows) return ShowPlayerDialog(playerid, DIALOG_PORECEIVER, DIALOG_STYLE_INPUT, "Nguoi nhan", "{FF3333}Error: {FFFFFF}Nguoi nhan khong hop le - Tai khoan khong ton tai!\n\nVui long nhap ten nguoi nhan (online hoac offline)", "Trang Tiep", "Huy bo");

	cache_get_value_name(0, "AdminLevel", szResult); admin = strval(szResult);
	cache_get_value_name(0, "TogReports", szResult); undercover = strval(szResult);
	cache_get_value_name(0, "id", szResult); id = strval(szResult);

	if (admin >= 2 && undercover == 0) return ShowPlayerDialog(playerid, DIALOG_PORECEIVER, DIALOG_STYLE_INPUT, "Nguoi nhan", "{FF3333}Loi: {FFFFFF}Ban khong the gui thu cho Admin!\n\nVui long nhap ten nguoi nhan (online hoac offline)", "Trang Tiep", "Huy bo");

	SetPVarInt(playerid, "LetterRecipient", id);
	ShowPlayerDialog(playerid, DIALOG_POMESSAGE, DIALOG_STYLE_INPUT, "Gui thu", "{FFFFFF}Vui long nhap noi dung tin nhan.", "Gui Thu", "Huy bo");

	return 1;

}

forward CheckSales(index);
public CheckSales(index)
{
	if(IsPlayerConnected(index))
	{
	    new rows, fields, szDialog[128];
		cache_get_data(rows, fields);
	    if(rows > 0)
		{
  			for(new i;i < rows;i++)
			{
			    new szResult[32], id;
			    cache_get_value_name(i, "id", szResult); id = strval(szResult);
   				cache_get_value_name(i, "Month", szResult, 25);
   				format(szDialog, sizeof(szDialog), "%s\n%s ", szDialog, szResult);
   				Selected[index][i] = id;
			}
			ShowPlayerDialog(index, DIALOG_VIEWSALE, DIALOG_STYLE_LIST, "Chon mot khung thoi gian", szDialog, "Xem", "Huy bo");
		}
		else
		{
		    SendClientMessageEx(index, COLOR_WHITE, "Co loi say ra.");
		}
	}
}

forward CheckSales2(index);
public CheckSales2(index)
{
	if(IsPlayerConnected(index))
	{
        new rows, fields, szDialog[2500];
		cache_get_data(rows, fields);
	    if(rows)
		{
		    new szResult[32], szField[15], Solds[MAX_ITEMS], Amount[MAX_ITEMS];
		    for(new z = 0; z < MAX_ITEMS; z++)
			{
				format(szField, sizeof(szField), "TotalSold%d", z);
				cache_get_value_name(0,  szField, szResult);
				Solds[z] = strval(szResult);

				format(szField, sizeof(szField), "AmountMade%d", z);
				cache_get_value_name(0,  szField, szResult);
				Amount[z] = strval(szResult);
			}

     	    format(szDialog, sizeof(szDialog),"\
		 	Gold VIP Sold: %d | Tong Credits: %s\n\
		 	Gold VIP Renew Sold: %d | Tong Credits: %s\n\
		 	Silver VIP Sold: %d | Tong Credits: %s\n\
		 	Bronze VIP Sold: %d | Tong Credits: %s\n\
		 	Toys Sold: %d | Tong Credits: %s\n\
		 	Cars Sold: %d | Tong Credits: %s\n", Solds[0], number_format(Amount[0]), Solds[1], number_format(Amount[1]), Solds[2], number_format(Amount[2]), Solds[3], number_format(Amount[3]), Solds[4], number_format(Amount[4]),
			 Solds[5], number_format(Amount[5]));

		 	format(szDialog, sizeof(szDialog), "%s\
		 	Pokertables Sold: %d | Tong Credits: %s\n\
		 	Boomboxes Sold: %d | Tong Credits: %s\n\
		 	Paintball Tokens Sold: %d | Tong Credits: %s\n\
		 	EXP Tokens Sold: %d | Tong Credits: %s\n\
		 	Fireworks Sold: %d | Tong Credits: %s\n", szDialog, Solds[6], number_format(Amount[6]), Solds[7], number_format(Amount[7]), Solds[8], number_format(Amount[8]), Solds[9], number_format(Amount[9]), Solds[10], number_format(Amount[10]));

			format(szDialog, sizeof(szDialog), "%sBusiness Renew Regular Sold: %d | Tong Credits: %s\n\
		 	Business Renew Standard Sold: %d | Tong Credits: %s\n\
		 	Business Renew Premium Sold: %d | Tong Credits: %s\n\
		 	Houses Sold: %d | Tong Credits: %s\n", szDialog, Solds[11], number_format(Amount[11]), Solds[12], number_format(Amount[12]), Solds[13], number_format(Amount[13]), Solds[14], number_format(Amount[14]));

		 	format(szDialog, sizeof(szDialog), "%sHouse Moves Sold: %d | Tong Credits: %s\n\
		 	House Interiors Sold: %d | Tong Credits: %s\n\
			Reset Gift Timer Sold: %d | Tong Credits: %s\n\
			Advanced Health Care Sold: %d | Tong Credits: %s\n",szDialog, Solds[15], number_format(Amount[15]), Solds[16], number_format(Amount[16]), Solds[17], number_format(Amount[17]), Solds[18], number_format(Amount[18]));

			format(szDialog, sizeof(szDialog), "%sSuper Health Car Sold: %d | Tong Credits: %s\n\
			Rented Cars Sold: %d | Tong Credits: %s\n\
			Custom License Sold: %d | Tong Credits: %s\n\
			Additional Vehicle Slot Sold: %d | Total Credits: %s\n",szDialog, Solds[19], number_format(Amount[19]), Solds[20], number_format(Amount[20]),Solds[22], number_format(Amount[22]), Solds[23], number_format(Amount[23]));
			
			format(szDialog, sizeof(szDialog), "%sGarage - Small Sold: %d | Tong Credits: %s\n\
			Garage - Medium Sold: %d | Tong Credits: %s\n\
			Garage - Large Sold: %d | Tong Credits: %s\n\
			Garage - Extra Large Sold: %d | Total Credits: %s\n", szDialog, Solds[24], number_format(Amount[24]), Solds[25], number_format(Amount[25]), Solds[26], number_format(Amount[26]), Solds[27], number_format(Amount[27]));
			
			format(szDialog, sizeof(szDialog), "%sAdditional Toy Slot Sold: %d | Tong Credits: %s\n\
			Hunger Voucher: %d | Tong Credits: %s\n\
			Credits Transactions: %d | Tong Credits %s\n", szDialog, Solds[28], number_format(Amount[28]), Solds[29], number_format(Amount[29]), Solds[21], number_format(Amount[21]));
			
            format(szDialog, sizeof(szDialog), "%sTotal Amount of Credits spent: %s", szDialog, 
			number_format(Amount[0]+Amount[1]+Amount[2]+Amount[3]+Amount[4]+Amount[5]+Amount[6]+Amount[7]+Amount[8]+Amount[9]+Amount[10]+Amount[11]+Amount[12]+Amount[13]+Amount[14]+Amount[15]+Amount[16]+Amount[17]+Amount[18]+Amount[19]+Amount[20]+Amount[21]+Amount[22]+Amount[23]
			+Amount[24]+Amount[25]+Amount[26]+Amount[27]+Amount[28]+Amount[29]));
		 	ShowPlayerDialog(index, DIALOG_NOTHING, DIALOG_STYLE_MSGBOX, "Shop Statistics", szDialog, "Thoat", "");
		}
		else
		{
		    SendClientMessageEx(index, COLOR_GREY, "Co van de trong  viec kiem tra ban.");
		}
	}
}

forward LoadRentedCar(index);
public LoadRentedCar(index)
{
	if(IsPlayerConnected(index))
	{
	    new rows, fields;
	    cache_get_data(rows, fields);
		if(rows)
		{
		    //`sqlid`, `modelid`, `posx`, `posy`, `posz`, `posa`, `spawned`, `hours`

            new szResult[32], Info[2], Float: pos[4], string[128];
 	    	cache_get_value_name(0, "modelid", szResult); Info[0] = strval(szResult);
  	    	cache_get_value_name(0, "posx", szResult); pos[0] = strval(szResult);
   	    	cache_get_value_name(0, "posy", szResult); pos[1] = strval(szResult);
    	    cache_get_value_name(0, "posz", szResult); pos[2] = strval(szResult);
    	    cache_get_value_name(0, "posa", szResult); pos[3] = strval(szResult);
    	    cache_get_value_name(0, "hours", szResult); Info[1] = strval(szResult);

			SetPVarInt(index, "RentedHours", Info[1]);
			SetPVarInt(index, "RentedVehicle", CreateVehicle(Info[0],pos[0],pos[1], pos[2], pos[3], random(128), random(128), 2000000));

			format(string, sizeof(string), "Xe thue cua ban da duoc sinh ra, ban co %d phut truoc khi het gio thue.", Info[1]);
			SendClientMessageEx(index, COLOR_CYAN, string);
		}
	}
}

forward LoadTicket(playerid);
public LoadTicket(playerid) {
 	new rows, fields;
	cache_get_data(rows, fields);

	if (rows == 0) {
		return 1;
	}

    new number, result[10];
	for(new i; i < rows; i++)
	{
    	cache_get_value_name(i, "number", result);
    	number = strval(result);
		LottoNumbers[playerid][i] = number;
	}
	return 1;
}

forward LoadTreasureInvent(playerid);
public LoadTreasureInvent(playerid)
{
    new rows, fields, szResult[10];
	cache_get_data(rows, fields);

    if(IsPlayerConnected(playerid))
    {
        if(!rows)
        {
            new query[60];
            format(query, sizeof(query), "INSERT INTO `jobstuff` (`pId`) VALUES ('%d')", GetPlayerSQLId(playerid));
			mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
        }
        else
        {
    		for(new row;row < rows;row++)
			{
				cache_get_value_name(row, "junkmetal", szResult); SetPVarInt(playerid, "JunkMetal", strval(szResult));
				cache_get_value_name(row, "newcoin", szResult); SetPVarInt(playerid, "newcoin", strval(szResult));
				cache_get_value_name(row, "oldcoin", szResult); SetPVarInt(playerid, "oldcoin", strval(szResult));
				cache_get_value_name(row, "brokenwatch", szResult); SetPVarInt(playerid, "brokenwatch", strval(szResult));
				cache_get_value_name(row, "oldkey", szResult); SetPVarInt(playerid, "oldkey", strval(szResult));
				cache_get_value_name(row, "treasure", szResult); SetPVarInt(playerid, "treasure", strval(szResult));
				cache_get_value_name(row, "goldwatch", szResult); SetPVarInt(playerid, "goldwatch", strval(szResult));
				cache_get_value_name(row, "silvernugget", szResult); SetPVarInt(playerid, "silvernugget", strval(szResult));
				cache_get_value_name(row, "goldnugget", szResult); SetPVarInt(playerid, "goldnugget", strval(szResult));
			}
		}
	}
	return 1;
}

forward GetHomeCount(playerid);
public GetHomeCount(playerid)
{
	new string[128];
	format(string, sizeof(string), "SELECT NULL FROM `houses` WHERE `OwnerID` = %d", GetPlayerSQLId(playerid));
	mysql_pquery(MainPipeline, string, "QueryGetCountFinish", "ii", playerid, 2);
	return 1;
}

forward AddReportToken(playerid);
public AddReportToken(playerid)
{
	new
		sz_playerName[MAX_PLAYER_NAME],
		i_timestamp[3],
		tdate[11],
		thour[9],
		query[128];

	GetPlayerName(playerid, sz_playerName, MAX_PLAYER_NAME);
	getdate(i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(tdate, sizeof(tdate), "%d-%02d-%02d", i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(thour, sizeof(thour), "%02d:00:00", vhour);

	format(query, sizeof(query), "SELECT NULL FROM `tokens_report` WHERE `playerid` = %d AND `date` = '%s' AND `hour` = '%s'", GetPlayerSQLId(playerid), tdate, thour);
	mysql_pquery(MainPipeline, query, "QueryTokenFinish", "ii", playerid, 1);
	return 1;
}

forward AddCAReportToken(playerid);
public AddCAReportToken(playerid)
{
	new
		sz_playerName[MAX_PLAYER_NAME],
		i_timestamp[3],
		tdate[11],
		thour[9],
		query[128];

	GetPlayerName(playerid, sz_playerName, MAX_PLAYER_NAME);
	getdate(i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(tdate, sizeof(tdate), "%d-%02d-%02d", i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(thour, sizeof(thour), "%02d:00:00", vhour);

	format(query, sizeof(query), "SELECT NULL FROM `tokens_request` WHERE `playerid` = %d AND `date` = '%s' AND `hour` = '%s'", GetPlayerSQLId(playerid), tdate, thour);
	mysql_pquery(MainPipeline, query, "QueryTokenFinish", "ii", playerid, 2);
	return 1;
}

forward AddCallToken(playerid);
public AddCallToken(playerid)
{
	new
		sz_playerName[MAX_PLAYER_NAME],
		i_timestamp[3],
		tdate[11],
		query[128];

	GetPlayerName(playerid, sz_playerName, MAX_PLAYER_NAME);
	getdate(i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(tdate, sizeof(tdate), "%d-%02d-%02d", i_timestamp[0], i_timestamp[1], i_timestamp[2]);

	format(query, sizeof(query), "SELECT NULL FROM `tokens_call` WHERE `playerid` = %d AND `date` = '%s' AND `hour` = %d", GetPlayerSQLId(playerid), tdate, vhour);
	mysql_pquery(MainPipeline, query, "QueryTokenFinish", "ii", playerid, 3);
	return 1;
}

forward QueryTokenFinish(playerid, type);
public QueryTokenFinish(playerid, type)
{
    new rows, fields, string[128], i_timestamp[3], tdate[11], thour[9];
	cache_get_data(rows, fields);
	getdate(i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(tdate, sizeof(tdate), "%d-%02d-%02d", i_timestamp[0], i_timestamp[1], i_timestamp[2]);
	format(thour, sizeof(thour), "%02d:00:00", vhour);

	switch(type)
	{
		case 1:
		{
			if(rows == 0)
			{
				format(string, sizeof(string), "INSERT INTO `tokens_report` (`id`, `playerid`, `date`, `hour`, `count`) VALUES (NULL, %d, '%s', '%s', 1)", GetPlayerSQLId(playerid), tdate, thour);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
			else
			{
				format(string, sizeof(string), "UPDATE `tokens_report` SET `count` = count+1 WHERE `playerid` = %d AND `date` = '%s' AND `hour` = '%s'", GetPlayerSQLId(playerid), tdate, thour);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
		}
		case 2:
		{
			if(rows == 0)
			{
				format(string, sizeof(string), "INSERT INTO `tokens_request` (`id`, `playerid`, `date`, `hour`, `count`) VALUES (NULL, %d, '%s', '%s', 1)", GetPlayerSQLId(playerid), tdate, thour);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
			else
			{
				format(string, sizeof(string), "UPDATE `tokens_request` SET `count` = count+1 WHERE `playerid` = %d AND `date` = '%s' AND `hour` = '%s'", GetPlayerSQLId(playerid), tdate, thour);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
		}
		case 3:
		{
			if(rows == 0)
			{
				format(string, sizeof(string), "INSERT INTO `tokens_call` (`id`, `playerid`, `date`, `hour`, `count`) VALUES (NULL, %d, '%s', %d, 1)", GetPlayerSQLId(playerid), tdate, vhour);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
			else
			{
				format(string, sizeof(string), "UPDATE `tokens_call` SET `count` = count+1 WHERE `playerid` = %d AND `date` = '%s' AND `hour` = %d", GetPlayerSQLId(playerid), tdate, vhour);
				mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
			}
		}
	}
	return 1;
}

forward GetReportCount(userid, tdate[]);
public GetReportCount(userid, tdate[])
{
	new string[128];
	format(string, sizeof(string), "SELECT SUM(count) FROM `tokens_report` WHERE `playerid` = %d AND `date` = '%s'", GetPlayerSQLId(userid), tdate);
	mysql_pquery(MainPipeline, string, "QueryGetCountFinish", "ii", userid, 0);
	return 1;
}

forward GetHourReportCount(userid, thour[], tdate[]);
public GetHourReportCount(userid, thour[], tdate[])
{
	new string[128];
	format(string, sizeof(string), "SELECT `count` FROM `tokens_report` WHERE `playerid` = %d AND `date` = '%s' AND `hour` = '%s'", GetPlayerSQLId(userid), tdate, thour);
	mysql_pquery(MainPipeline, string, "QueryGetCountFinish", "ii", userid, 1);
	return 1;
}

forward GetRequestCount(userid, tdate[]);
public GetRequestCount(userid, tdate[])
{
	new string[128];
	format(string, sizeof(string), "SELECT SUM(count) FROM `tokens_request` WHERE `playerid` = %d AND `date` = '%s'", GetPlayerSQLId(userid), tdate);
	mysql_pquery(MainPipeline, string, "QueryGetCountFinish", "ii", userid, 0);
	return 1;
}

forward GetHourRequestCount(userid, thour[], tdate[]);
public GetHourRequestCount(userid, thour[], tdate[])
{
	new string[128];
	format(string, sizeof(string), "SELECT `count` FROM `tokens_request` WHERE `playerid` = %d AND `date` = '%s' AND `hour` = '%s'", GetPlayerSQLId(userid), tdate, thour);
	mysql_pquery(MainPipeline, string, "QueryGetCountFinish", "ii", userid, 1);
	return 1;
}

forward QueryGetCountFinish(userid, type);
public QueryGetCountFinish(userid, type)
{
    new rows, fields, sResult[24];
	cache_get_data(rows, fields);

	switch(type)
	{
		case 0:
		{
			if(rows > 0)
			{
				cache_get_value_name(0, "SUM(count)", sResult);
				ReportCount[userid] = strval(sResult);
			}
			else ReportCount[userid] = 0;
		}
		case 1:
		{
			if(rows > 0)
			{
				cache_get_value_name(0, "count", sResult);
				ReportHourCount[userid] = strval(sResult);
			}
			else ReportHourCount[userid] = 0;
		}
		case 2:
		{
			Homes[userid] = rows;
		}
	}
	return 1;
}

forward OnLoadFamilies();
public OnLoadFamilies()
{
	new i, rows, fields, tmp[128], famid;
	cache_get_data(rows, fields);

	new column[32];
	while(i < rows)
	{
	    FamilyMemberCount(i);
	    cache_get_value_name(i, "ID", tmp); famid = strval(tmp);
		cache_get_value_name(i, "Taken", tmp); FamilyInfo[famid][FamilyTaken] = strval(tmp);
		cache_get_value_name(i, "Name", FamilyInfo[famid][FamilyName], 42);
		cache_get_value_name(i, "Leader", FamilyInfo[famid][FamilyLeader], MAX_PLAYER_NAME);
		cache_get_value_name(i, "Bank", tmp); FamilyInfo[famid][FamilyBank] = strval(tmp);
		cache_get_value_name(i, "Cash", tmp); FamilyInfo[famid][FamilyCash] = strval(tmp);
		cache_get_value_name(i, "Level", tmp); 
		FamilyInfo[famid][FamilyLevel] = (strlen(tmp) > 0) ? strval(tmp) : 1;
		cache_get_value_name(i, "MaxMembers", tmp); 
		FamilyInfo[famid][FamilyMaxMembers] = (strlen(tmp) > 0) ? strval(tmp) : 20;
		cache_get_value_name(i, "FamilyUSafe", tmp); FamilyInfo[famid][FamilyUSafe] = strval(tmp);
		cache_get_value_name(i, "FamilySafeX", tmp); FamilyInfo[famid][FamilySafe][0] = floatstr(tmp);
		cache_get_value_name(i, "FamilySafeY", tmp); FamilyInfo[famid][FamilySafe][1] = floatstr(tmp);
		cache_get_value_name(i, "FamilySafeZ", tmp); FamilyInfo[famid][FamilySafe][2] = floatstr(tmp);
		cache_get_value_name(i, "FamilySafeVW", tmp); FamilyInfo[famid][FamilySafeVW] = strval(tmp);
		cache_get_value_name(i, "FamilySafeInt", tmp); FamilyInfo[famid][FamilySafeInt] = strval(tmp);
		cache_get_value_name(i, "Pot", tmp); FamilyInfo[famid][FamilyPot] = strval(tmp);
		cache_get_value_name(i, "Crack", tmp); FamilyInfo[famid][FamilyCrack] = strval(tmp);
		cache_get_value_name(i, "Mats", tmp); FamilyInfo[famid][FamilyMats] = strval(tmp);
		cache_get_value_name(i, "Heroin", tmp); FamilyInfo[famid][FamilyHeroin] = strval(tmp);
		cache_get_value_name(i, "MaxSkins", tmp); FamilyInfo[famid][FamilyMaxSkins] = strval(tmp);
		cache_get_value_name(i, "Color", tmp); FamilyInfo[famid][FamilyColor] = strval(tmp);
		cache_get_value_name(i, "TurfTokens", tmp); FamilyInfo[famid][FamilyTurfTokens] = strval(tmp);
		cache_get_value_name(i, "ExteriorX", tmp); FamilyInfo[famid][FamilyEntrance][0] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorY", tmp); FamilyInfo[famid][FamilyEntrance][1] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorZ", tmp); FamilyInfo[famid][FamilyEntrance][2] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorA", tmp); FamilyInfo[famid][FamilyEntrance][3] = floatstr(tmp);
		cache_get_value_name(i, "InteriorX", tmp); FamilyInfo[famid][FamilyExit][0] = floatstr(tmp);
		cache_get_value_name(i, "InteriorY", tmp); FamilyInfo[famid][FamilyExit][1] = floatstr(tmp);
		cache_get_value_name(i, "InteriorZ", tmp); FamilyInfo[famid][FamilyExit][2] = floatstr(tmp);
		cache_get_value_name(i, "InteriorA", tmp); FamilyInfo[famid][FamilyExit][3] = floatstr(tmp);
		cache_get_value_name(i, "INT", tmp); FamilyInfo[famid][FamilyInterior] = strval(tmp);
		cache_get_value_name(i, "VW", tmp); FamilyInfo[famid][FamilyVirtualWorld] = strval(tmp);
		cache_get_value_name(i, "CustomInterior", tmp); FamilyInfo[famid][FamilyCustomMap] = strval(tmp);
		cache_get_value_name(i, "GtObject", tmp); FamilyInfo[famid][gtObject] = strval(tmp);
		cache_get_value_name(i, "MOTD1", FamilyMOTD[famid][0], 128);
		cache_get_value_name(i, "MOTD2", FamilyMOTD[famid][1], 128);
		cache_get_value_name(i, "MOTD3", FamilyMOTD[famid][2], 128);
		cache_get_value_name(i, "fontface", tmp); format(FamilyInfo[famid][gt_FontFace], 32, "%s", tmp);
		cache_get_value_name(i, "fontsize", tmp); FamilyInfo[famid][gt_FontSize] = strval(tmp);
		cache_get_value_name(i, "bold", tmp); FamilyInfo[famid][gt_Bold] = strval(tmp);
		cache_get_value_name(i, "fontcolor", tmp); FamilyInfo[famid][gt_FontColor] = strval(tmp);
		cache_get_value_name(i, "text", FamilyInfo[famid][gt_Text], 32);		
		cache_get_value_name(i, "gtUsed", tmp); FamilyInfo[famid][gt_SPUsed] = strval(tmp);		
		if(strcmp(FamilyInfo[famid][gt_Text], "Preview", true) == 0)
		{
			FamilyInfo[famid][gtObject] = 1490;
			FamilyInfo[famid][gt_SPUsed] = 1;
		}
	    for (new j; j <= 6; j++) {
	        format(column,sizeof(column), "Rank%d", j);
	        cache_get_value_name(i, column, tmp); format(FamilyRankInfo[famid][j], 20, "%s", tmp);
	    }

		for (new j = 0; j < 5 ;j++) {
	        format(column, sizeof(column), "Division%d", j);
	        cache_get_value_name(i, column, tmp); format(FamilyDivisionInfo[famid][j], 20, "%s", tmp);
	    }
	    for (new j; j < 8; j++) {
	        format(column,sizeof(column), "Skin%d", j+1);
	        cache_get_value_name(i, column, tmp); FamilyInfo[famid][FamilySkins][j] = strval(tmp);
	    }
	    for (new j; j < 30; j++) {
	        format(column,sizeof(column), "Gun%d", j+1);
	        cache_get_value_name(i, column, tmp); FamilyInfo[famid][FamilyGuns][j] = strval(tmp);
	    }
		if(FamilyInfo[famid][FamilyUSafe] > 0)
		{
			FamilyInfo[famid][FamilyPickup] = CreateDynamicPickup(1239, 23, FamilyInfo[famid][FamilySafe][0], FamilyInfo[famid][FamilySafe][1], FamilyInfo[famid][FamilySafe][2], .worldid = FamilyInfo[famid][FamilySafeVW], .interiorid = FamilyInfo[famid][FamilySafeInt]);
			new string[1280];
			format(string, sizeof(string), "%s\n{9E9E9E}Su dung {873D37}/glocker{9E9E9E} de mo", FamilyInfo[famid][FamilyName]);
			FamilyInfo[famid][FamilyTextLabel] = CreateDynamic3DTextLabel(string, COLOR_YELLOW, FamilyInfo[famid][FamilySafe][0], FamilyInfo[famid][FamilySafe][1], FamilyInfo[famid][FamilySafe][2]+0.6, 4.0, .testlos = 1, .worldid = FamilyInfo[famid][FamilySafeVW], .interiorid = FamilyInfo[famid][FamilySafeInt]);
		}
		if(FamilyInfo[famid][FamilyEntrance][0] != 0.0 && FamilyInfo[famid][FamilyEntrance][1] != 0.0)
		{
		    new string[42];
		    FamilyInfo[famid][FamilyEntrancePickup] = CreateDynamicPickup(1318, 23, FamilyInfo[famid][FamilyEntrance][0], FamilyInfo[famid][FamilyEntrance][1], FamilyInfo[famid][FamilyEntrance][2]);
			format(string, sizeof(string), "%s", FamilyInfo[famid][FamilyName]);
			FamilyInfo[famid][FamilyEntranceText] = CreateDynamic3DTextLabel(string,COLOR_YELLOW,FamilyInfo[famid][FamilyEntrance][0], FamilyInfo[famid][FamilyEntrance][1], FamilyInfo[famid][FamilyEntrance][2]+0.6,4.0);
		}
		i++;
	}
	//LoadGangTags();
}

forward OnFamilyMemberCount(famid);
public OnFamilyMemberCount(famid)
{
	new rows, fields;
	cache_get_data(rows, fields);
	FamilyInfo[famid][FamilyMembers] = rows;
}

forward MailDeliveryTimer();
public MailDeliveryTimer()
{
	mysql_pquery(MainPipeline, "UPDATE `letters` SET `Delivery_Min` = `Delivery_Min` - 1 WHERE `Delivery_Min` > 0", "OnQueryFinish", "i", SENDDATA_THREAD);
	mysql_pquery(MainPipeline, "SELECT `Receiver_Id` FROM `letters` WHERE `Delivery_Min` = 1", "MailDeliveryQueryFinish", "");
	return 1;
}

forward OnLoadGates();
public OnLoadGates()
{
	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "HID", tmp);  GateInfo[i][gHID] = strval(tmp);
		cache_get_value_name(i, "Speed", tmp); GateInfo[i][gSpeed] = floatstr(tmp);
		cache_get_value_name(i, "Range", tmp); GateInfo[i][gRange] = floatstr(tmp);
		cache_get_value_name(i, "Model", tmp); GateInfo[i][gModel] = strval(tmp);
		cache_get_value_name(i, "VW", tmp); GateInfo[i][gVW] = strval(tmp);
		cache_get_value_name(i, "Int", tmp); GateInfo[i][gInt] = strval(tmp);
		cache_get_value_name(i, "Pass", GateInfo[i][gPass], 24);
		cache_get_value_name(i, "PosX", tmp); GateInfo[i][gPosX] = floatstr(tmp);
		cache_get_value_name(i, "PosY", tmp); GateInfo[i][gPosY] = floatstr(tmp);
		cache_get_value_name(i, "PosZ", tmp); GateInfo[i][gPosZ] = floatstr(tmp);
		cache_get_value_name(i, "RotX", tmp); GateInfo[i][gRotX] = floatstr(tmp);
		cache_get_value_name(i, "RotY", tmp); GateInfo[i][gRotY] = floatstr(tmp);
		cache_get_value_name(i, "RotZ", tmp); GateInfo[i][gRotZ] = floatstr(tmp);
		cache_get_value_name(i, "PosXM", tmp); GateInfo[i][gPosXM] = floatstr(tmp);
		cache_get_value_name(i, "PosYM", tmp); GateInfo[i][gPosYM] = floatstr(tmp);
		cache_get_value_name(i, "PosZM", tmp); GateInfo[i][gPosZM] = floatstr(tmp);
		cache_get_value_name(i, "RotXM", tmp); GateInfo[i][gRotXM] = floatstr(tmp);
		cache_get_value_name(i, "RotYM", tmp); GateInfo[i][gRotYM] = floatstr(tmp);
		cache_get_value_name(i, "RotZM", tmp); GateInfo[i][gRotZM] = floatstr(tmp);
		cache_get_value_name(i, "Allegiance", tmp); GateInfo[i][gAllegiance] = strval(tmp);
		cache_get_value_name(i, "GroupType", tmp); GateInfo[i][gGroupType] = strval(tmp);
		cache_get_value_name(i, "GroupID", tmp); GateInfo[i][gGroupID] = strval(tmp);
		cache_get_value_name(i, "FamilyID", tmp); GateInfo[i][gFamilyID] = strval(tmp);
		cache_get_value_name(i, "RenderHQ", tmp); GateInfo[i][gRenderHQ] = strval(tmp);
		cache_get_value_name(i, "Timer", tmp); GateInfo[i][gTimer] = strval(tmp);
		cache_get_value_name(i, "Automate", tmp); GateInfo[i][gAutomate] = strval(tmp);
		cache_get_value_name(i, "Locked", tmp); GateInfo[i][gLocked] = strval(tmp);
		CreateGate(i);
		i++;
	}
}

forward OnLoadDynamicMapIcon(index);
public OnLoadDynamicMapIcon(index)
{
	new rows, fields, tmp[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp);  DMPInfo[index][dmpSQLId] = strval(tmp);
		cache_get_value_name(row, "MarkerType", tmp); DMPInfo[index][dmpMarkerType] = strval(tmp);
		cache_get_value_name(row, "Color", tmp); DMPInfo[index][dmpColor] = strval(tmp);
		cache_get_value_name(row, "VW", tmp); DMPInfo[index][dmpVW] = strval(tmp);
		cache_get_value_name(row, "Int", tmp); DMPInfo[index][dmpInt] = strval(tmp);
		cache_get_value_name(row, "PosX", tmp); DMPInfo[index][dmpPosX] = floatstr(tmp);
		cache_get_value_name(row, "PosY", tmp); DMPInfo[index][dmpPosY] = floatstr(tmp);
		cache_get_value_name(row, "PosZ", tmp); DMPInfo[index][dmpPosZ] = floatstr(tmp);
		if(DMPInfo[index][dmpMarkerType] != 0) DMPInfo[index][dmpMapIconID] = CreateDynamicMapIcon(DMPInfo[index][dmpPosX], DMPInfo[index][dmpPosY], DMPInfo[index][dmpPosZ], DMPInfo[index][dmpMarkerType], DMPInfo[index][dmpColor], DMPInfo[index][dmpVW], DMPInfo[index][dmpInt], -1, 500.0);
	}
	return 1;
}

forward OnLoadDynamicMapIcons();
public OnLoadDynamicMapIcons()
{
	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  DMPInfo[i][dmpSQLId] = strval(tmp);
		cache_get_value_name(i, "MarkerType", tmp); DMPInfo[i][dmpMarkerType] = strval(tmp);
		cache_get_value_name(i, "Color", tmp); DMPInfo[i][dmpColor] = strval(tmp);
		cache_get_value_name(i, "VW", tmp); DMPInfo[i][dmpVW] = strval(tmp);
		cache_get_value_name(i, "Int", tmp); DMPInfo[i][dmpInt] = strval(tmp);
		cache_get_value_name(i, "PosX", tmp); DMPInfo[i][dmpPosX] = floatstr(tmp);
		cache_get_value_name(i, "PosY", tmp); DMPInfo[i][dmpPosY] = floatstr(tmp);
		cache_get_value_name(i, "PosZ", tmp); DMPInfo[i][dmpPosZ] = floatstr(tmp);
		if(DMPInfo[i][dmpMarkerType] != 0) DMPInfo[i][dmpMapIconID] = CreateDynamicMapIcon(DMPInfo[i][dmpPosX], DMPInfo[i][dmpPosY], DMPInfo[i][dmpPosZ], DMPInfo[i][dmpMarkerType], DMPInfo[i][dmpColor], DMPInfo[i][dmpVW], DMPInfo[i][dmpInt], -1, 500.0);
		i++;
	}
	if(i > 0) printf("[LoadDynamicMapIcons] %d icons map duoc tai.", i);
	else printf("[LoadDynamicMapIcons] Khong the tai icons map.");
	return 1;
}

forward OnLoadDynamicDoor(index);
public OnLoadDynamicDoor(index)
{
	new rows, fields, tmp[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(rows, "id", tmp);  DDoorsInfo[index][ddSQLId] = strval(tmp);
		cache_get_value_name(rows, "Description", DDoorsInfo[index][ddDescription], 128);
		cache_get_value_name(rows, "Owner", tmp); DDoorsInfo[index][ddOwner] = strval(tmp);
		cache_get_value_name(rows, "OwnerName", DDoorsInfo[index][ddOwnerName], 42);
		cache_get_value_name(rows, "CustomExterior", tmp); DDoorsInfo[index][ddCustomExterior] = strval(tmp);
		cache_get_value_name(rows, "CustomInterior", tmp); DDoorsInfo[index][ddCustomInterior] = strval(tmp);
		cache_get_value_name(rows, "ExteriorVW", tmp); DDoorsInfo[index][ddExteriorVW] = strval(tmp);
		cache_get_value_name(rows, "ExteriorInt", tmp); DDoorsInfo[index][ddExteriorInt] = strval(tmp);
		cache_get_value_name(rows, "InteriorVW", tmp); DDoorsInfo[index][ddInteriorVW] = strval(tmp);
		cache_get_value_name(rows, "InteriorInt", tmp); DDoorsInfo[index][ddInteriorInt] = strval(tmp);
		cache_get_value_name(rows, "ExteriorX", tmp); DDoorsInfo[index][ddExteriorX] = floatstr(tmp);
		cache_get_value_name(rows, "ExteriorY", tmp); DDoorsInfo[index][ddExteriorY] = floatstr(tmp);
		cache_get_value_name(rows, "ExteriorZ", tmp); DDoorsInfo[index][ddExteriorZ] = floatstr(tmp);
		cache_get_value_name(rows, "ExteriorA", tmp); DDoorsInfo[index][ddExteriorA] = floatstr(tmp);
		cache_get_value_name(rows, "InteriorX", tmp); DDoorsInfo[index][ddInteriorX] = floatstr(tmp);
		cache_get_value_name(rows, "InteriorY", tmp); DDoorsInfo[index][ddInteriorY] = floatstr(tmp);
		cache_get_value_name(rows, "InteriorZ", tmp); DDoorsInfo[index][ddInteriorZ] = floatstr(tmp);
		cache_get_value_name(rows, "InteriorA", tmp); DDoorsInfo[index][ddInteriorA] = floatstr(tmp);
		cache_get_value_name(rows, "Type", tmp); DDoorsInfo[index][ddType] = strval(tmp);
		cache_get_value_name(rows, "Rank", tmp); DDoorsInfo[index][ddRank] = strval(tmp);
		cache_get_value_name(rows, "VIP", tmp); DDoorsInfo[index][ddVIP] = strval(tmp);
		cache_get_value_name(rows, "Famed", tmp); DDoorsInfo[index][ddFamed] = strval(tmp);
		cache_get_value_name(rows, "DPC", tmp); DDoorsInfo[index][ddDPC] = strval(tmp);
		cache_get_value_name(rows, "Allegiance", tmp); DDoorsInfo[index][ddAllegiance] = strval(tmp);
		cache_get_value_name(rows, "GroupType", tmp); DDoorsInfo[index][ddGroupType] = strval(tmp);
		cache_get_value_name(rows, "Family", tmp); DDoorsInfo[index][ddFamily] = strval(tmp);
		cache_get_value_name(rows, "Faction", tmp); DDoorsInfo[index][ddFaction] = strval(tmp);
		cache_get_value_name(rows, "Admin", tmp); DDoorsInfo[index][ddAdmin] = strval(tmp);
		cache_get_value_name(rows, "Wanted", tmp); DDoorsInfo[index][ddWanted] = strval(tmp);
		cache_get_value_name(rows, "VehicleAble", tmp); DDoorsInfo[index][ddVehicleAble] = strval(tmp);
		cache_get_value_name(rows, "Color", tmp); DDoorsInfo[index][ddColor] = strval(tmp);
		cache_get_value_name(rows, "PickupModel", tmp); DDoorsInfo[index][ddPickupModel] = strval(tmp);
		cache_get_value_name(rows, "Pass", DDoorsInfo[index][ddPass], 24);
		cache_get_value_name(rows, "Locked", tmp); DDoorsInfo[index][ddLocked] = strval(tmp);
		if(strcmp(DDoorsInfo[index][ddDescription], "None", true) != 0) CreateDynamicDoor(index);
	}
	return 1;
}


forward OnLoadDynamicDoors();
public OnLoadDynamicDoors()
{
	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  DDoorsInfo[i][ddSQLId] = strval(tmp);
		cache_get_value_name(i, "Description", DDoorsInfo[i][ddDescription], 128);
		cache_get_value_name(i, "Owner", tmp); DDoorsInfo[i][ddOwner] = strval(tmp);
		cache_get_value_name(i, "OwnerName", DDoorsInfo[i][ddOwnerName], 42);
		cache_get_value_name(i, "CustomExterior", tmp); DDoorsInfo[i][ddCustomExterior] = strval(tmp);
		cache_get_value_name(i, "CustomInterior", tmp); DDoorsInfo[i][ddCustomInterior] = strval(tmp);
		cache_get_value_name(i, "ExteriorVW", tmp); DDoorsInfo[i][ddExteriorVW] = strval(tmp);
		cache_get_value_name(i, "ExteriorInt", tmp); DDoorsInfo[i][ddExteriorInt] = strval(tmp);
		cache_get_value_name(i, "InteriorVW", tmp); DDoorsInfo[i][ddInteriorVW] = strval(tmp);
		cache_get_value_name(i, "InteriorInt", tmp); DDoorsInfo[i][ddInteriorInt] = strval(tmp);
		cache_get_value_name(i, "ExteriorX", tmp); DDoorsInfo[i][ddExteriorX] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorY", tmp); DDoorsInfo[i][ddExteriorY] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorZ", tmp); DDoorsInfo[i][ddExteriorZ] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorA", tmp); DDoorsInfo[i][ddExteriorA] = floatstr(tmp);
		cache_get_value_name(i, "InteriorX", tmp); DDoorsInfo[i][ddInteriorX] = floatstr(tmp);
		cache_get_value_name(i, "InteriorY", tmp); DDoorsInfo[i][ddInteriorY] = floatstr(tmp);
		cache_get_value_name(i, "InteriorZ", tmp); DDoorsInfo[i][ddInteriorZ] = floatstr(tmp);
		cache_get_value_name(i, "InteriorA", tmp); DDoorsInfo[i][ddInteriorA] = floatstr(tmp);
		cache_get_value_name(i, "Type", tmp); DDoorsInfo[i][ddType] = strval(tmp);
		cache_get_value_name(i, "Rank", tmp); DDoorsInfo[i][ddRank] = strval(tmp);
		cache_get_value_name(i, "VIP", tmp); DDoorsInfo[i][ddVIP] = strval(tmp);
		cache_get_value_name(i, "Famed", tmp); DDoorsInfo[i][ddFamed] = strval(tmp);
		cache_get_value_name(i, "DPC", tmp); DDoorsInfo[i][ddDPC] = strval(tmp);
		cache_get_value_name(i, "Allegiance", tmp); DDoorsInfo[i][ddAllegiance] = strval(tmp);
		cache_get_value_name(i, "GroupType", tmp); DDoorsInfo[i][ddGroupType] = strval(tmp);
		cache_get_value_name(i, "Family", tmp); DDoorsInfo[i][ddFamily] = strval(tmp);
		cache_get_value_name(i, "Faction", tmp); DDoorsInfo[i][ddFaction] = strval(tmp);
		cache_get_value_name(i, "Admin", tmp); DDoorsInfo[i][ddAdmin] = strval(tmp);
		cache_get_value_name(i, "Wanted", tmp); DDoorsInfo[i][ddWanted] = strval(tmp);
		cache_get_value_name(i, "VehicleAble", tmp); DDoorsInfo[i][ddVehicleAble] = strval(tmp);
		cache_get_value_name(i, "Color", tmp); DDoorsInfo[i][ddColor] = strval(tmp);
		cache_get_value_name(i, "PickupModel", tmp); DDoorsInfo[i][ddPickupModel] = strval(tmp);
		cache_get_value_name(i, "Pass", DDoorsInfo[i][ddPass], 24);
		cache_get_value_name(i, "Locked", tmp); DDoorsInfo[i][ddLocked] = strval(tmp);
		if(strcmp(DDoorsInfo[i][ddDescription], "None", true) != 0) CreateDynamicDoor(i);
		i++;
	}
	if(i > 0) printf("[LoadDynamicDoors] %d door duoc tai.", i);
	else printf("[LoadDynamicDoors] Khong the tai door.");
	return 1;
}

forward OnLoadHouse(index);
public OnLoadHouse(index)
{
	new rows, fields, szField[24], tmp[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp); HouseInfo[index][hSQLId] = strval(tmp);
		cache_get_value_name(row, "Owned", tmp); HouseInfo[index][hOwned] = strval(tmp);
		cache_get_value_name(row, "Level", tmp); HouseInfo[index][hLevel] = strval(tmp);
		cache_get_value_name(row, "Description", HouseInfo[index][hDescription], 16);
		cache_get_value_name(row, "OwnerID", tmp); HouseInfo[index][hOwnerID] = strval(tmp);
		cache_get_value_name(row, "Username", HouseInfo[index][hOwnerName], MAX_PLAYER_NAME);
		cache_get_value_name(row, "ExteriorX", tmp); HouseInfo[index][hExteriorX] = floatstr(tmp);
		cache_get_value_name(row, "ExteriorY", tmp); HouseInfo[index][hExteriorY] = floatstr(tmp);
		cache_get_value_name(row, "ExteriorZ", tmp); HouseInfo[index][hExteriorZ] = floatstr(tmp);
		cache_get_value_name(row, "ExteriorR", tmp); HouseInfo[index][hExteriorR] = floatstr(tmp);
		cache_get_value_name(row, "ExteriorA", tmp); HouseInfo[index][hExteriorA] = floatstr(tmp);
		cache_get_value_name(row, "CustomExterior", tmp); HouseInfo[index][hCustomExterior] = strval(tmp);
		cache_get_value_name(row, "InteriorX", tmp); HouseInfo[index][hInteriorX] = floatstr(tmp);
		cache_get_value_name(row, "InteriorY", tmp); HouseInfo[index][hInteriorY] = floatstr(tmp);
		cache_get_value_name(row, "InteriorZ", tmp); HouseInfo[index][hInteriorZ] = floatstr(tmp);
		cache_get_value_name(row, "InteriorR", tmp); HouseInfo[index][hInteriorR] = floatstr(tmp);
		cache_get_value_name(row, "InteriorA", tmp); HouseInfo[index][hInteriorA] = floatstr(tmp);
		cache_get_value_name(row, "CustomInterior", tmp); HouseInfo[index][hCustomInterior] = strval(tmp);
		cache_get_value_name(row, "ExtIW", tmp); HouseInfo[index][hExtIW] = strval(tmp);
		cache_get_value_name(row, "ExtVW", tmp); HouseInfo[index][hExtVW] = strval(tmp);
		cache_get_value_name(row, "IntIW", tmp); HouseInfo[index][hIntIW] = strval(tmp);
		cache_get_value_name(row, "IntVW", tmp); HouseInfo[index][hIntVW] = strval(tmp);
		cache_get_value_name(row, "Lock", tmp); HouseInfo[index][hLock] = strval(tmp);
		cache_get_value_name(row, "Rentable", tmp); HouseInfo[index][hRentable] = strval(tmp);
		cache_get_value_name(row, "RentFee", tmp); HouseInfo[index][hRentFee] = strval(tmp);
		cache_get_value_name(row, "Value", tmp); HouseInfo[index][hValue] = strval(tmp);
		cache_get_value_name(row, "SafeMoney", tmp); HouseInfo[index][hSafeMoney] = strval(tmp);
		cache_get_value_name(row, "Pot", tmp); HouseInfo[index][hPot] = strval(tmp);
		cache_get_value_name(row, "Crack", tmp); HouseInfo[index][hCrack] = strval(tmp);
		cache_get_value_name(row, "Materials", tmp); HouseInfo[index][hMaterials] = strval(tmp);
		cache_get_value_name(row, "Heroin", tmp); HouseInfo[index][hHeroin] = strval(tmp);
		for(new i; i < 5; i++)
		{
			format(szField, sizeof(szField), "Vu khi%d", i);
			cache_get_value_name(row, szField, tmp);
			HouseInfo[index][hWeapons][i] = strval(tmp);
		}
		cache_get_value_name(row, "GLUpgrade", tmp); HouseInfo[index][hGLUpgrade] = strval(tmp);
		cache_get_value_name(row, "PickupID", tmp); HouseInfo[index][hPickupID] = strval(tmp);
		cache_get_value_name(row, "MailX", tmp); HouseInfo[index][hMailX] = floatstr(tmp);
		cache_get_value_name(row, "MailY", tmp); HouseInfo[index][hMailY] = floatstr(tmp);
		cache_get_value_name(row, "MailZ", tmp); HouseInfo[index][hMailZ] = floatstr(tmp);
		cache_get_value_name(row, "MailA", tmp); HouseInfo[index][hMailA] = floatstr(tmp);
		cache_get_value_name(row, "MailType", tmp); HouseInfo[index][hMailType] = strval(tmp);
		cache_get_value_name(row, "ClosetX", tmp); HouseInfo[index][hClosetX] = floatstr(tmp);
		cache_get_value_name(row, "ClosetY", tmp); HouseInfo[index][hClosetY] = floatstr(tmp);
		cache_get_value_name(row, "ClosetZ", tmp); HouseInfo[index][hClosetZ] = floatstr(tmp);

		ReloadHousePickup(index);
		if(HouseInfo[index][hClosetX] != 0.0) HouseInfo[index][hClosetTextID] = CreateDynamic3DTextLabel("Tu quan ao\n/Tu de su dung", 0xFFFFFF88, HouseInfo[index][hClosetX], HouseInfo[index][hClosetY], HouseInfo[index][hClosetZ]+0.5,10.0, .testlos = 1, .worldid = HouseInfo[index][hIntVW], .interiorid = HouseInfo[index][hIntIW], .streamdistance = 10.0);
		if(HouseInfo[index][hMailX] != 0.0) RenderHouseMailbox(index);
	}
	return 1;
}

forward OnLoadHouses();
public OnLoadHouses()
{
	new i, rows, fields, szField[24], tmp[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp); HouseInfo[i][hSQLId] = strval(tmp);
		cache_get_value_name(i, "Owned", tmp); HouseInfo[i][hOwned] = strval(tmp);
		cache_get_value_name(i, "Level", tmp); HouseInfo[i][hLevel] = strval(tmp);
		cache_get_value_name(i, "Description", HouseInfo[i][hDescription], 16);
		cache_get_value_name(i, "OwnerID", tmp); HouseInfo[i][hOwnerID] = strval(tmp);
		cache_get_value_name(i, "Username", HouseInfo[i][hOwnerName], MAX_PLAYER_NAME);
		cache_get_value_name(i, "ExteriorX", tmp); HouseInfo[i][hExteriorX] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorY", tmp); HouseInfo[i][hExteriorY] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorZ", tmp); HouseInfo[i][hExteriorZ] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorR", tmp); HouseInfo[i][hExteriorR] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorA", tmp); HouseInfo[i][hExteriorA] = floatstr(tmp);
		cache_get_value_name(i, "CustomExterior", tmp); HouseInfo[i][hCustomExterior] = strval(tmp);
		cache_get_value_name(i, "InteriorX", tmp); HouseInfo[i][hInteriorX] = floatstr(tmp);
		cache_get_value_name(i, "InteriorY", tmp); HouseInfo[i][hInteriorY] = floatstr(tmp);
		cache_get_value_name(i, "InteriorZ", tmp); HouseInfo[i][hInteriorZ] = floatstr(tmp);
		cache_get_value_name(i, "InteriorR", tmp); HouseInfo[i][hInteriorR] = floatstr(tmp);
		cache_get_value_name(i, "InteriorA", tmp); HouseInfo[i][hInteriorA] = floatstr(tmp);
		cache_get_value_name(i, "CustomInterior", tmp); HouseInfo[i][hCustomInterior] = strval(tmp);
		cache_get_value_name(i, "ExtIW", tmp); HouseInfo[i][hExtIW] = strval(tmp);
		cache_get_value_name(i, "ExtVW", tmp); HouseInfo[i][hExtVW] = strval(tmp);
		cache_get_value_name(i, "IntIW", tmp); HouseInfo[i][hIntIW] = strval(tmp);
		cache_get_value_name(i, "IntVW", tmp); HouseInfo[i][hIntVW] = strval(tmp);
		cache_get_value_name(i, "Lock", tmp); HouseInfo[i][hLock] = strval(tmp);
		cache_get_value_name(i, "Rentable", tmp); HouseInfo[i][hRentable] = strval(tmp);
		cache_get_value_name(i, "RentFee", tmp); HouseInfo[i][hRentFee] = strval(tmp);
		cache_get_value_name(i, "Value", tmp); HouseInfo[i][hValue] = strval(tmp);
		cache_get_value_name(i, "SafeMoney", tmp); HouseInfo[i][hSafeMoney] = strval(tmp);
		cache_get_value_name(i, "Pot", tmp); HouseInfo[i][hPot] = strval(tmp);
		cache_get_value_name(i, "Crack", tmp); HouseInfo[i][hCrack] = strval(tmp);
		cache_get_value_name(i, "Materials", tmp); HouseInfo[i][hMaterials] = strval(tmp);
		cache_get_value_name(i, "Heroin", tmp); HouseInfo[i][hHeroin] = strval(tmp);
		for(new j; j < 5; j++)
		{
			format(szField, sizeof(szField), "Vu khi%d", j);
			cache_get_value_name(i, szField, tmp);
			HouseInfo[i][hWeapons][j] = strval(tmp);
		}
		cache_get_value_name(i, "GLUpgrade", tmp); HouseInfo[i][hGLUpgrade] = strval(tmp);
		cache_get_value_name(i, "PickupID", tmp); HouseInfo[i][hPickupID] = strval(tmp);
		cache_get_value_name(i, "MailX", tmp); HouseInfo[i][hMailX] = floatstr(tmp);
		cache_get_value_name(i, "MailY", tmp); HouseInfo[i][hMailY] = floatstr(tmp);
		cache_get_value_name(i, "MailZ", tmp); HouseInfo[i][hMailZ] = floatstr(tmp);
		cache_get_value_name(i, "MailA", tmp); HouseInfo[i][hMailA] = floatstr(tmp);
		cache_get_value_name(i, "MailType", tmp); HouseInfo[i][hMailType] = strval(tmp);
		cache_get_value_name(i, "ClosetX", tmp); HouseInfo[i][hClosetX] = floatstr(tmp);
		cache_get_value_name(i, "ClosetY", tmp); HouseInfo[i][hClosetY] = floatstr(tmp);
		cache_get_value_name(i, "ClosetZ", tmp); HouseInfo[i][hClosetZ] = floatstr(tmp);

		ReloadHousePickup(i);
		if(HouseInfo[i][hClosetX] != 0.0) HouseInfo[i][hClosetTextID] = CreateDynamic3DTextLabel("Tu quan ao\n/tu de su dung", 0xFFFFFF88, HouseInfo[i][hClosetX], HouseInfo[i][hClosetY], HouseInfo[i][hClosetZ]+0.5,10.0, .testlos = 1, .worldid = HouseInfo[i][hIntVW], .interiorid = HouseInfo[i][hIntIW], .streamdistance = 10.0);
		if(HouseInfo[i][hMailX] != 0.0) RenderHouseMailbox(i);
		i++;
	}
	if(i > 0) printf("[LoadHouses] %d ngoi nha duoc tai.", i);
	else printf("[LoadHouses] Khong the tai vi tri ngoi nha.");
}

forward OnLoadMailboxes();
public OnLoadMailboxes()
{
	new string[512], i;
	new rows, fields;
	cache_get_data(rows, fields);
	while(i<rows)
	{
	    for(new field;field<fields;field++)
	    {
 		    cache_get_row(string, MainPipeline);
			switch(field)
			{
			    case 1: MailBoxes[i][mbVW] = strval(string);
				case 2: MailBoxes[i][mbInt] = strval(string);
				case 3: MailBoxes[i][mbModel] = strval(string);
				case 4: MailBoxes[i][mbPosX] = floatstr(string);
				case 5: MailBoxes[i][mbPosY] = floatstr(string);
				case 6: MailBoxes[i][mbPosZ] = floatstr(string);
				case 7: MailBoxes[i][mbAngle] = floatstr(string);
			}
		}
		RenderStreetMailbox(i);
  		i++;
 	}
	if(i > 0) printf("[LoadMailboxes] %d mailboxes duoc tai.", i);
	else printf("[LoadMailboxes] Khong the tai mailboxes.");
	return 1;
}	

forward OnLoadSpeedCameras();
public OnLoadSpeedCameras()
{
	new fields, rows, index, result[128];
	cache_get_data(rows, fields);

	while ((index < rows))
	{
		cache_get_value_name(index, "id", result); SpeedCameras[index][_scDatabase] = strval(result);
		cache_get_value_name(index, "pos_x", result); SpeedCameras[index][_scPosX] = floatstr(result);
		cache_get_value_name(index, "pos_y", result); SpeedCameras[index][_scPosY] = floatstr(result);
		cache_get_value_name(index, "pos_z", result); SpeedCameras[index][_scPosZ] = floatstr(result);
		cache_get_value_name(index, "rotation", result); SpeedCameras[index][_scRotation] = floatstr(result);
		cache_get_value_name(index, "range", result); SpeedCameras[index][_scRange] = floatstr(result);
		cache_get_value_name(index, "speed_limit", result); SpeedCameras[index][_scLimit] = floatstr(result);

		SpeedCameras[index][_scActive] = true;
		SpeedCameras[index][_scObjectId] = -1;
		SpawnSpeedCamera(index);

		index++;
	}

	if (index == 0)
		printf("[SpeedCameras] Khong the tai cac may ban toc do.");
	else
		printf("[SpeedCameras] Tai %i May ban toc do.", index);

	return 1;
}

forward OnNewSpeedCamera(index);
public OnNewSpeedCamera(index)
{
	new db = mysql_insert_id(MainPipeline);
	SpeedCameras[index][_scDatabase] = db;
}

// @returns
//  ID of new speed cam on success, or -1 on failure

forward OnLoadTxtLabel(index);
public OnLoadTxtLabel(index)
{
	new rows, fields, tmp[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp);  TxtLabels[index][tlSQLId] = strval(tmp);
		cache_get_value_name(row, "Text", TxtLabels[index][tlText], 128);
		cache_get_value_name(row, "PosX", tmp); TxtLabels[index][tlPosX] = floatstr(tmp);
		cache_get_value_name(row, "PosY", tmp); TxtLabels[index][tlPosY] = floatstr(tmp);
		cache_get_value_name(row, "PosZ", tmp); TxtLabels[index][tlPosZ] = floatstr(tmp);
		cache_get_value_name(row, "VW", tmp); TxtLabels[index][tlVW] = strval(tmp);
		cache_get_value_name(row, "Int", tmp); TxtLabels[index][tlInt] = strval(tmp);
		cache_get_value_name(row, "Color", tmp); TxtLabels[index][tlColor] = strval(tmp);
		cache_get_value_name(row, "PickupModel", tmp); TxtLabels[index][tlPickupModel] = strval(tmp);
		if(strcmp(TxtLabels[index][tlText], "None", true) != 0) CreateTxtLabel(index);
	}
	return 1;
}

forward OnLoadTxtLabels();
public OnLoadTxtLabels()
{
	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  TxtLabels[i][tlSQLId] = strval(tmp);
		cache_get_value_name(i, "Text", TxtLabels[i][tlText], 128);
		cache_get_value_name(i, "PosX", tmp); TxtLabels[i][tlPosX] = floatstr(tmp);
		cache_get_value_name(i, "PosY", tmp); TxtLabels[i][tlPosY] = floatstr(tmp);
		cache_get_value_name(i, "PosZ", tmp); TxtLabels[i][tlPosZ] = floatstr(tmp);
		cache_get_value_name(i, "VW", tmp); TxtLabels[i][tlVW] = strval(tmp);
		cache_get_value_name(i, "Int", tmp); TxtLabels[i][tlInt] = strval(tmp);
		cache_get_value_name(i, "Color", tmp); TxtLabels[i][tlColor] = strval(tmp);
		cache_get_value_name(i, "PickupModel", tmp); TxtLabels[i][tlPickupModel] = strval(tmp);
		if(strcmp(TxtLabels[i][tlText], "None", true) != 0) CreateTxtLabel(i);
		i++;
	}
}

forward OnLoadPayNSprays();
public OnLoadPayNSprays()
{
	new i, rows, fields, tmp[128], string[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  PayNSprays[i][pnsSQLId] = strval(tmp);
		cache_get_value_name(i, "Status", tmp); PayNSprays[i][pnsStatus] = strval(tmp);
		cache_get_value_name(i, "PosX", tmp); PayNSprays[i][pnsPosX] = floatstr(tmp);
		cache_get_value_name(i, "PosY", tmp); PayNSprays[i][pnsPosY] = floatstr(tmp);
		cache_get_value_name(i, "PosZ", tmp); PayNSprays[i][pnsPosZ] = floatstr(tmp);
		cache_get_value_name(i, "VW", tmp); PayNSprays[i][pnsVW] = strval(tmp);
		cache_get_value_name(i, "Int", tmp); PayNSprays[i][pnsInt] = strval(tmp);
		cache_get_value_name(i, "GroupCost", tmp); PayNSprays[i][pnsGroupCost] = strval(tmp);
		cache_get_value_name(i, "RegCost", tmp); PayNSprays[i][pnsRegCost] = strval(tmp);
		if(PayNSprays[i][pnsStatus] > 0)
		{
			format(string, sizeof(string), "/repaircar\nRepair Cost -- Regular: $%s | Faction: $%s\nID: %d", number_format(PayNSprays[i][pnsRegCost]), number_format(PayNSprays[i][pnsGroupCost]), i);
			PayNSprays[i][pnsTextID] = CreateDynamic3DTextLabel(string, COLOR_RED, PayNSprays[i][pnsPosX], PayNSprays[i][pnsPosY], PayNSprays[i][pnsPosZ]+0.5,10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, PayNSprays[i][pnsVW], PayNSprays[i][pnsInt], -1);
			PayNSprays[i][pnsPickupID] = CreateDynamicPickup(1239, 23, PayNSprays[i][pnsPosX], PayNSprays[i][pnsPosY], PayNSprays[i][pnsPosZ], PayNSprays[i][pnsVW]);
			PayNSprays[i][pnsMapIconID] = CreateDynamicMapIcon(PayNSprays[i][pnsPosX], PayNSprays[i][pnsPosY], PayNSprays[i][pnsPosZ], 63, 0, PayNSprays[i][pnsVW], PayNSprays[i][pnsInt], -1, 500.0);
		}
		i++;
	}
}

forward OnLoadArrestPoint(index);
public OnLoadArrestPoint(index)
{
	new rows, fields, tmp[128], string[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp);  ArrestPoints[index][arrestSQLId] = strval(tmp);
		cache_get_value_name(row, "PosX", tmp); ArrestPoints[index][arrestPosX] = floatstr(tmp);
		cache_get_value_name(row, "PosY", tmp); ArrestPoints[index][arrestPosY] = floatstr(tmp);
		cache_get_value_name(row, "PosZ", tmp); ArrestPoints[index][arrestPosZ] = floatstr(tmp);
		cache_get_value_name(row, "VW", tmp); ArrestPoints[index][arrestVW] = strval(tmp);
		cache_get_value_name(row, "Int", tmp); ArrestPoints[index][arrestInt] = strval(tmp);
		cache_get_value_name(row, "Type", tmp); ArrestPoints[index][arrestType] = strval(tmp);
		if(ArrestPoints[index][arrestPosX] != 0)
		{
			switch(ArrestPoints[index][arrestType])
			{
				case 0:
				{
					format(string, sizeof(string), "/arrest\nArrest Point #%d", index);
					ArrestPoints[index][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[index][arrestVW], ArrestPoints[index][arrestInt], -1);
					ArrestPoints[index][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ], ArrestPoints[index][arrestVW]);
				}
				case 2:
				{
					format(string, sizeof(string), "/docarrest\nArrest Point #%d", index);
					ArrestPoints[index][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[index][arrestVW], ArrestPoints[index][arrestInt], -1);
					ArrestPoints[index][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ], ArrestPoints[index][arrestVW]);
				}
				case 3:
				{
					format(string, sizeof(string), "/warrantarrest\nArrest Point #%d", index);
					ArrestPoints[index][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[index][arrestVW], ArrestPoints[index][arrestInt], -1);
					ArrestPoints[index][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ], ArrestPoints[index][arrestVW]);
				}
				case 4:
				{
					format(string, sizeof(string), "/jarrest\nArrest Point #%d", index);
					ArrestPoints[index][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[index][arrestVW], ArrestPoints[index][arrestInt], -1);
					ArrestPoints[index][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[index][arrestPosX], ArrestPoints[index][arrestPosY], ArrestPoints[index][arrestPosZ], ArrestPoints[index][arrestVW]);
				}
			}
		}
	}
	return 1;
}

forward OnLoadArrestPoints();
public OnLoadArrestPoints()
{
	new i, rows, fields, tmp[128], string[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  ArrestPoints[i][arrestSQLId] = strval(tmp);
		cache_get_value_name(i, "PosX", tmp); ArrestPoints[i][arrestPosX] = floatstr(tmp);
		cache_get_value_name(i, "PosY", tmp); ArrestPoints[i][arrestPosY] = floatstr(tmp);
		cache_get_value_name(i, "PosZ", tmp); ArrestPoints[i][arrestPosZ] = floatstr(tmp);
		cache_get_value_name(i, "VW", tmp); ArrestPoints[i][arrestVW] = strval(tmp);
		cache_get_value_name(i, "Int", tmp); ArrestPoints[i][arrestInt] = strval(tmp);
		cache_get_value_name(i, "Type", tmp); ArrestPoints[i][arrestType] = strval(tmp);
		if(ArrestPoints[i][arrestPosX] != 0)
		{
			switch(ArrestPoints[i][arrestType])
			{
				case 0:
				{
					format(string, sizeof(string), "/arrest\nArrest Point #%d", i);
					ArrestPoints[i][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[i][arrestVW], ArrestPoints[i][arrestInt], -1);
					ArrestPoints[i][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ], ArrestPoints[i][arrestVW]);
				}
				case 2:
				{
					format(string, sizeof(string), "/docarrest\nArrest Point #%d", i);
					ArrestPoints[i][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[i][arrestVW], ArrestPoints[i][arrestInt], -1);
					ArrestPoints[i][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ], ArrestPoints[i][arrestVW]);
				}
				case 3:
				{
					format(string, sizeof(string), "/warrantarrest\nArrest Point #%d", i);
					ArrestPoints[i][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[i][arrestVW], ArrestPoints[i][arrestInt], -1);
					ArrestPoints[i][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ], ArrestPoints[i][arrestVW]);
				}
				case 4:
				{
					format(string, sizeof(string), "/jarrest\nArrest Point #%d", i);
					ArrestPoints[i][arrestTextID] = CreateDynamic3DTextLabel(string, COLOR_DBLUE, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ]+0.6, 4.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ArrestPoints[i][arrestVW], ArrestPoints[i][arrestInt], -1);
					ArrestPoints[i][arrestPickupID] = CreateDynamicPickup(1247, 23, ArrestPoints[i][arrestPosX], ArrestPoints[i][arrestPosY], ArrestPoints[i][arrestPosZ], ArrestPoints[i][arrestVW]);
				}
			}
		}
		i++;
	}
}

forward OnLoadImpoundPoint(index);
public OnLoadImpoundPoint(index)
{
	new rows, fields, tmp[128], string[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp);  ImpoundPoints[index][impoundSQLId] = strval(tmp);
		cache_get_value_name(row, "PosX", tmp); ImpoundPoints[index][impoundPosX] = floatstr(tmp);
		cache_get_value_name(row, "PosY", tmp); ImpoundPoints[index][impoundPosY] = floatstr(tmp);
		cache_get_value_name(row, "PosZ", tmp); ImpoundPoints[index][impoundPosZ] = floatstr(tmp);
		cache_get_value_name(row, "VW", tmp); ImpoundPoints[index][impoundVW] = strval(tmp);
		cache_get_value_name(row, "Int", tmp); ImpoundPoints[index][impoundInt] = strval(tmp);
		if(ImpoundPoints[index][impoundPosX] != 0)
		{
			format(string, sizeof(string), "Impound Yard #%d\nType /impound to impound a vehicle", index);
			ImpoundPoints[index][impoundTextID] = CreateDynamic3DTextLabel(string, COLOR_YELLOW, ImpoundPoints[index][impoundPosX], ImpoundPoints[index][impoundPosY], ImpoundPoints[index][impoundPosZ]+0.6, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ImpoundPoints[index][impoundVW], ImpoundPoints[index][impoundInt], -1);
		}
	}
	return 1;
}

forward OnLoadImpoundPoints();
public OnLoadImpoundPoints()
{
	new i, rows, fields, tmp[128], string[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  ImpoundPoints[i][impoundSQLId] = strval(tmp);
		cache_get_value_name(i, "PosX", tmp); ImpoundPoints[i][impoundPosX] = floatstr(tmp);
		cache_get_value_name(i, "PosY", tmp); ImpoundPoints[i][impoundPosY] = floatstr(tmp);
		cache_get_value_name(i, "PosZ", tmp); ImpoundPoints[i][impoundPosZ] = floatstr(tmp);
		cache_get_value_name(i, "VW", tmp); ImpoundPoints[i][impoundVW] = strval(tmp);
		cache_get_value_name(i, "Int", tmp); ImpoundPoints[i][impoundInt] = strval(tmp);
		if(ImpoundPoints[i][impoundPosX] != 0)
		{
			format(string, sizeof(string), "Impound Yard #%d\nType /impound to impound a vehicle", i);
			ImpoundPoints[i][impoundTextID] = CreateDynamic3DTextLabel(string, COLOR_YELLOW, ImpoundPoints[i][impoundPosX], ImpoundPoints[i][impoundPosY], ImpoundPoints[i][impoundPosZ]+0.6, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, ImpoundPoints[i][impoundVW], ImpoundPoints[i][impoundInt], -1);
		}
		i++;
	}
}

forward LoadDynamicGroups();
public LoadDynamicGroups()
{
    mysql_pquery(MainPipeline, "SELECT * FROM `groups`", "Group_QueryFinish", "ii", GROUP_QUERY_LOAD, 0);
	mysql_pquery(MainPipeline, "SELECT * FROM `lockers`", "Group_QueryFinish", "ii", GROUP_QUERY_LOCKERS, 0);
	mysql_pquery(MainPipeline, "SELECT * FROM `jurisdictions`", "Group_QueryFinish", "ii", GROUP_QUERY_JURISDICTIONS, 0);
	return ;
}

forward LoadDynamicGroupVehicles();
public LoadDynamicGroupVehicles()
{
    mysql_pquery(MainPipeline, "SELECT * FROM `groupvehs`", "DynVeh_QueryFinish", "ii", GV_QUERY_LOAD, 0);
    return 1;
}

forward ParkRentedVehicle(playerid, vehicleid, modelid, Float:X, Float:Y, Float:Z);
public ParkRentedVehicle(playerid, vehicleid, modelid, Float:X, Float:Y, Float:Z)
{
	if(IsPlayerInRangeOfPoint(playerid, 1.0, X, Y, Z))
	{
	    new Float:x, Float:y, Float:z, Float:angle, Float:health, string[180], Float: oldfuel, arrDamage[4];
	    GetVehicleHealth(vehicleid, health);
     	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessageEx(playerid, COLOR_GREY, "Ban phai o ghe lai xe.");
     	if(health < 800) return SendClientMessageEx(playerid, COLOR_GREY, " Khong the dau xe khi xe cua ban hu hong qua nang.");

		GetVehiclePos(vehicleid, x, y, z);
		GetVehicleZAngle(vehicleid, angle);
		SurfingCheck(vehicleid);
		oldfuel = VehicleFuel[vehicleid];

		GetVehicleDamageStatus(vehicleid, arrDamage[0], arrDamage[1], arrDamage[2], arrDamage[3]);
		
		// Get current vehicle colors before destroying
		new color1, color2;
		GetVehicleColor(vehicleid, color1, color2);
		
		DestroyVehicle(GetPVarInt(playerid, "RentedVehicle"));
        SetPVarInt(playerid, "RentedVehicle", CreateVehicle(modelid, x, y, z, angle, color1, color2, 2000000));
		Vehicle_ResetData(GetPVarInt(playerid, "RentedVehicle"));
		VehicleFuel[GetPVarInt(playerid, "RentedVehicle")] = oldfuel;
		SetVehicleHealth(GetPVarInt(playerid, "RentedVehicle"), health);
		UpdateVehicleDamageStatus(vehicleid, arrDamage[0], arrDamage[1], arrDamage[2], arrDamage[3]);

		format(string, sizeof(string), "UPDATE `rentedcars` SET `posx` = '%f', `posy` = '%f', `posz` = '%f', `posa` = '%f' WHERE `sqlid` = '%d'", x, y, z, angle, GetPlayerSQLId(playerid));
        mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);

		IsPlayerEntering{playerid} = true;
		PutPlayerInVehicle(playerid, vehicleid, 0);
		SetPlayerArmedWeapon(playerid, 0);
		format(string, sizeof(string), "* %s has parked their vehicle.", GetPlayerNameEx(playerid));
		ProxDetector(30.0, playerid, string, COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE);

	}
	else
	{
	    SendClientMessage(playerid, COLOR_WHITE, "Xe khong the dau khi ban di chuyen xe!");
	}
	return 1;
}

forward OnPlayerChangePass(index);
public OnPlayerChangePass(index)
{
	if(mysql_affected_rows(MainPipeline)) {

		new
			szBuffer[129],
			szMessage[103];

		GetPVarString(index, "PassChange", szBuffer, sizeof(szBuffer));
		format(szMessage, sizeof(szMessage), "Ban da thay doi mat khau cua ban thanh '%s'.", szBuffer);
		SendClientMessageEx(index, COLOR_YELLOW, szMessage);

		format(szMessage, sizeof(szMessage), "%s (IP: %s) da thay doi mat khau cua ho.", GetPlayerNameEx(index), PlayerInfo[index][pIP]);
		Log("logs/password.log", szMessage);
		DeletePVar(index, "PassChange");

		if(PlayerInfo[index][pForcePasswordChange] == 1)
		{
		    PlayerInfo[index][pForcePasswordChange] = 0;
		    format(szMessage, sizeof(szMessage), "UPDATE `accounts` SET `ForcePasswordChange` = '0' WHERE `id` = '%i'", PlayerInfo[index][pId]);
			mysql_pquery(MainPipeline, szMessage, "OnQueryFinish", "ii", SENDDATA_THREAD, index);
		}
	}
	else SendClientMessageEx(index, COLOR_RED, "Co mot loi su ly say ra, mat khau cua ban van duoc giu nguyen.");
	return 1;
}

forward OnChangeUserPassword(index);
public OnChangeUserPassword(index)
{
	if(GetPVarType(index, "ChangePin"))
	{
	    new string[128], name[24];
		GetPVarString(index, "OnChangeUserPassword", name, 24);

		if(mysql_affected_rows(MainPipeline)) {
			format(string, sizeof(string), "Ban da thay doi thanh cong ma PIN %s's.", name);
			SendClientMessageEx(index, COLOR_WHITE, string);
		}
		else {
			format(string, sizeof(string), "Da co van de say ra cho viec thay doi PIN %s's.", name);
			SendClientMessageEx(index, COLOR_WHITE, string);
		}
		DeletePVar(index, "ChangePin");
		DeletePVar(index, "OnChangeUserPassword");
	}
	else
	{
		new string[128], name[24];
		GetPVarString(index, "OnChangeUserPassword", name, 24);

		if(mysql_affected_rows(MainPipeline)) {
			format(string, sizeof(string), "Ban da thay doi thanh cong mat khau %s's.", name);
			SendClientMessageEx(index, COLOR_WHITE, string);
		}
		else {
			format(string, sizeof(string), "Da co van de say ra cho viec thay doi mat khau %s's.", name);
			SendClientMessageEx(index, COLOR_WHITE, string);
		}
		DeletePVar(index, "OnChangeUserPassword");
	}
	return 1;
}

forward QueryCheckCountFinish(playerid, giveplayername[], tdate[], type);
public QueryCheckCountFinish(playerid, giveplayername[], tdate[], type)
{
    new string[128], rows, fields, sResult[24], tcount, hhour[9], chour;
	cache_get_data(rows, fields);

	switch(type)
	{
		case 0:
		{
			cache_get_value_name(0, "SUM(count)", sResult); tcount = strval(sResult);
			if(tcount > 0)
			{
				format(string, sizeof(string), "%s duoc chap nhan {%06x}%d {%06x}bao cao ve %s.", giveplayername, COLOR_GREEN >>> 8, tcount, COLOR_WHITE >>> 8, tdate);
				SendClientMessageEx(playerid, COLOR_WHITE, string);
			}
			else
			{
				format(string, sizeof(string), "%s khong chap nhan bao cao %s.", giveplayername, tdate);
				return SendClientMessageEx(playerid, COLOR_GRAD1, string);
			}
		}
		case 1:
		{
			if(rows > 0)
			{
				SendClientMessageEx(playerid, COLOR_GRAD1, "By hour:");
				for(new i; i < rows; i++)
				{
					cache_get_value_name(i, "count", sResult); new hcount = strval(sResult);
					cache_get_value_name(i, "hour", hhour, sizeof(hhour));
					format(hhour, sizeof(hhour), "%s", _str_replace(":00:00", "", hhour));
					chour = strval(hhour);
					format(string, sizeof(string), "%s: {%06x}%d", ConvertToTwelveHour(chour), COLOR_GREEN >>> 8, hcount);
					SendClientMessageEx(playerid, COLOR_WHITE, string);
				}
			}
		}
		case 2:
		{
			cache_get_value_name(0, "SUM(count)", sResult); tcount = strval(sResult);
			if(tcount > 0)
			{
				format(string, sizeof(string), "%s chap nhan {%06x}%d {%06x}yeu cau giup do %s.", giveplayername, COLOR_GREEN >>> 8, tcount, COLOR_WHITE >>> 8, tdate);
				SendClientMessageEx(playerid, COLOR_WHITE, string);
			}
			else
			{
				format(string, sizeof(string), "%s khong chap nhan yeu cau giup do %s.", giveplayername, tdate);
				return SendClientMessageEx(playerid, COLOR_GRAD1, string);
			}
		}
		case 3:
		{
			if(rows > 0)
			{
				SendClientMessageEx(playerid, COLOR_GRAD1, "By hour:");
				for(new i; i < rows; i++)
				{
					cache_get_value_name(i, "count", sResult); new hcount = strval(sResult);
					cache_get_value_name(i, "hour", hhour, sizeof(hhour));
					format(hhour, sizeof(hhour), "%s", _str_replace(":00:00", "", hhour));
					chour = strval(hhour);
					format(string, sizeof(string), "%s: {%06x}%d", ConvertToTwelveHour(chour), COLOR_GREEN >>> 8, hcount);
					SendClientMessageEx(playerid, COLOR_WHITE, string);
				}
			}
		}
	}
	return 1;
}

forward QueryUsernameCheck(playerid, tdate[], type);
public QueryUsernameCheck(playerid, tdate[], type)
{
    new string[128], rows, fields, giveplayerid, sResult[MAX_PLAYER_NAME];
	cache_get_data(rows, fields);

	if(rows > 0)
	{
		switch(type)
		{
			case 0:
			{
				cache_get_value_name(0, "id", sResult); giveplayerid = strval(sResult);
				cache_get_value_name(0, "Username", sResult, sizeof(sResult));
				format(string, sizeof(string), "SELECT SUM(count) FROM `tokens_report` WHERE `playerid` = %d AND `date` = '%s'", giveplayerid, tdate);
				mysql_pquery(MainPipeline, string, "QueryCheckCountFinish", "issi", playerid, sResult, tdate, 0);
				format(string, sizeof(string), "SELECT `count`, `hour` FROM `tokens_report` WHERE `playerid` = %d AND `date` = '%s' ORDER BY `hour` ASC", giveplayerid, tdate);
				mysql_pquery(MainPipeline, string, "QueryCheckCountFinish", "issi", playerid, sResult, tdate, 1);
			}
			case 1:
			{
				cache_get_value_name(0, "id", sResult); giveplayerid = strval(sResult);
				cache_get_value_name(0, "Username", sResult, sizeof(sResult));
				format(string, sizeof(string), "SELECT SUM(count) FROM `tokens_request` WHERE `playerid` = %d AND `date` = '%s'", giveplayerid, tdate);
				mysql_pquery(MainPipeline, string, "QueryCheckCountFinish", "issi", playerid, sResult, tdate, 2);
				format(string, sizeof(string), "SELECT `count`, `hour` FROM `tokens_request` WHERE `playerid` = %d AND `date` = '%s' ORDER BY `hour` ASC", giveplayerid, tdate);
				mysql_pquery(MainPipeline, string, "QueryCheckCountFinish", "issi", playerid, sResult, tdate, 3);
			}
		}
	}
	else return SendClientMessageEx(playerid, COLOR_GRAD1, "That account doesn't exist!");
	return 1;
}

forward OnBanPlayer(index);
public OnBanPlayer(index)
{
	new string[128], name[24], reason[64];
	GetPVarString(index, "OnBanPlayer", name, 24);
	GetPVarString(index, "OnBanPlayerReason", reason, 64);

	if(IsPlayerConnected(index))
	{
		if(mysql_affected_rows(MainPipeline)) {
			format(string, sizeof(string), "Ban da cam tai khoan %s's .", name);
			SendClientMessageEx(index, COLOR_WHITE, string);

			format(string, sizeof(string), "AdmCmd: %s da cam tai khoan %s offline, ly do: %s", name, GetPlayerNameEx(index), reason);
			Log("logs/ban.log", string);
			format(string, 128, "AdmCmd: %s da cam tai khoan %s offline, ly do: %s", name, GetPlayerNameEx(index), reason);
			ABroadCast(COLOR_LIGHTRED,string,2);
			print(string);
		}
		else {
			format(string, sizeof(string), "Da co van de say ra voi cam tai khoan %s's.", name);
			SendClientMessageEx(index, COLOR_WHITE, string);
		}
  		DeletePVar(index, "OnBanPlayer");
		DeletePVar(index, "OnBanPlayerReason");
	}
	return 1;
}

forward OnBanIP(index);
public OnBanIP(index)
{
	if(IsPlayerConnected(index))
	{
	    new rows, fields;
	    new string[128], ip[32], sqlid[5], id;
    	cache_get_data(rows, fields);

    	if(rows)
    	{
			cache_get_value_name(0, "id", sqlid); id = strval(sqlid);
			cache_get_value_name(0, "IP", ip, 16);

			MySQLBan(id, ip, "Offline Banned (/banaccount)", 1, GetPlayerNameEx(index));

			format(string, sizeof(string), "INSERT INTO `ip_bans` (`ip`, `date`, `reason`, `admin`) VALUES ('%s', NOW(), '%s', '%s')", ip, "Offline Banned", GetPlayerNameEx(index));
			mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
		}
	}
	return 1;
}

forward OnUnbanPlayer(index);
public OnUnbanPlayer(index)
{
	new string[128], name[24];
	GetPVarString(index, "OnUnbanPlayer", name, 24);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "Da bo cam tai khoan %s's thanh cong.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);

		format(string, 128, "AdmCmd: %s da duoc bo cam boi %s.", name, GetPlayerNameEx(index));
		ABroadCast(COLOR_LIGHTRED,string,2);
		format(string, sizeof(string), "AdmCmd: %s da duoc bo cam boi %s.", name, GetPlayerNameEx(index));
		Log("logs/ban.log", string);
		print(string);
	}
	else {
		format(string, sizeof(string), "Da co van de say ra trong qua trinh bo cam tai khoan %s's .", name);
		SendClientMessageEx(index, COLOR_WHITE, string);
	}
	DeletePVar(index, "OnUnbanPlayer");

	return 1;
}

forward OnUnbanIP(index);
public OnUnbanIP(index)
{
	if(IsPlayerConnected(index))
	{
	    new string[128], ip[16];
        new rows, fields;
		cache_get_data(rows, fields);
		if(rows) {
			cache_get_value_name(0, "IP", ip, 16);
			RemoveBan(index, ip);

			format(string, sizeof(string), "UPDATE `bans` SET `status` = 4, `date_unban` = NOW() WHERE `ip_address` = '%s'", ip);
			mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
		}
	}
	return 1;
}

// Use this for generic "You have successfully altered X's account" messages... no need for 578947 public functions!
forward Query_OnExecution(iTargetID);
public Query_OnExecution(iTargetID) {

	new
		szName[MAX_PLAYER_NAME],
		szMessage[64];

	GetPVarString(iTargetID, "QueryEx_Name", szName, sizeof szName);
	if(mysql_affected_rows(MainPipeline)) {
		format(szMessage, sizeof szMessage, "The query on %s's account was successful.", szName);
		SendClientMessageEx(iTargetID, COLOR_WHITE, szMessage);
	}
	else {
		format(szMessage, sizeof szMessage, "The query on %s's account was unsuccessful.", szName);
		SendClientMessageEx(iTargetID, COLOR_WHITE, szMessage);
	}
	return DeletePVar(iTargetID, "QueryEx_Name");
}

forward OnSetSuspended(index, value);
public OnSetSuspended(index, value)
{
	new string[128], name[24];
	GetPVarString(index, "OnSetSuspended", name, 24);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "You have successfully %s %s's account.", ((value) ? ("suspended") : ("unsuspended")), name);
		SendClientMessageEx(index, COLOR_WHITE, string);

		format(string, sizeof(string), "AdmCmd: %s was offline %s boi %s.", name, ((value) ? ("suspended") : ("unsuspended")), GetPlayerNameEx(index));
		Log("logs/admin.log", string);
	}
	else {
		format(string, sizeof(string), "Co mot van de say ra voi tai khoan %s %s's .", ((value) ? ("suspending") : ("unsuspending")), name);
		SendClientMessageEx(index, COLOR_WHITE, string);
	}
	DeletePVar(index, "OnSetSuspended");

	return 1;
}
/*#if defined SHOPAUTOMATED
forward OnShopOrder(index);
public OnShopOrder(index)
{
	if(IsPlayerConnected(index))
	{
	    HideNoticeGUIFrame(index);
		new rows, fields;
		cache_get_data(rows, fields, ShopPipeline);
		if(rows > 0)
		{
		    new string[512];
		    new ipsql[16], ip[16];
	    	GetPlayerIp(index, ip, sizeof(ip));
		    mysql_fetch_field_row(ipsql, "ip");
		    cache_get_value_name(0, "ip", ipsql, ShopPipeline);
		    if(!isnull(ipsql) && strcmp(ipsql, ip, true) == 0)
			{
			    new status[2], name[64], quantity[8], delivered[8], product_id[8];
			    for(new i;i<rows;i++)
			    {
	   				cache_get_value_name(i, "order_status_id", status, ShopPipeline);
			    	if(strval(status) == 2)
				    {
	    			 	cache_get_value_name(i, "name", name, ShopPipeline);
			  			cache_get_value_name(i, "quantity", quantity, ShopPipeline);
			  		    cache_get_value_name(i, "delivered", delivered, ShopPipeline);
			  			cache_get_value_name(i, "order_product_id", product_id, ShopPipeline);
				    	if(strval(quantity)-strval(delivered) <= 0)
					    {
	        				if(i<rows) format(string, sizeof(string), "%s%s (Delivered)\n", string, name);
					        else format(string, sizeof(string), "%s%s (Delivered)", string, name);
						}
						else
						{
		    				if(i<rows) format(string, sizeof(string), "%s%s (%d)\n", string, name, strval(quantity)-strval(delivered));
					    	else format(string, sizeof(string), "%s%s (%d)", string, name, strval(quantity)-strval(delivered));
						}
					}
					else
					{
					    new reason[27];
						switch(strval(status))
						{
						    case 0: format(reason, sizeof(reason), "{FF0000}No Payment");
						    case 1: format(reason, sizeof(reason), "{FF0000}Pending");
						    case 3: format(reason, sizeof(reason), "{00FF00}Shipped");
						    case 5:
							{
								ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", "This order has already been delivered", "OK", "");
								return 1;
							}
			    			case 7: format(reason, sizeof(reason), "{FF0000}Cancelled");
					    	case 8: format(reason, sizeof(reason), "{FF0000}Denied");
				   			case 9: format(reason, sizeof(reason), "{FF0000}Cancelled Reversal");
					    	case 10: format(reason, sizeof(reason), "{FF0000}Failed");
						    case 11: format(reason, sizeof(reason), "{00FF00}Refundend");
						    case 12: format(reason, sizeof(reason), "{FF0000}Reversed");
						    case 13: format(reason, sizeof(reason), "{FF0000}Chargeback");
				   			default: format(reason, sizeof(reason), "{FF0000}Unknown");
						}
						format(string, sizeof(string), "We are unable to process that order at this time,\nbecause the payment is currently marked as: %s", reason);
						ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", string, "OK", "");
	  					return 1;
					}
				}
			}
			else
			{
			    new email[256];
			    cache_get_value_name(0, "email", email, ShopPipeline);
			    SetPVarString(index, "ShopEmailVerify", email);
			    ShowPlayerDialog(index, DIALOG_SHOPORDEREMAIL, DIALOG_STYLE_INPUT, "Shop Order Error", "We were unable to link your order to your IP,\nfor further verification of your identity please input your shop e-mail address:", "Submit", "Cancel");
			    return 1;
			}
			ShowPlayerDialog(index, DIALOG_SHOPORDER2, DIALOG_STYLE_LIST, "Shop Order List", string, "Select", "Cancel");
		}
		else
		{
		    ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", "Error: No orders were found by that Order ID\nIf you are sure that is the correct Order ID, please try again or input '1' for your order ID.", "OK", "");
		}
	}
	return 1;
}

forward OnShopOrderEmailVer(index);
public OnShopOrderEmailVer(index)
{
	if(IsPlayerConnected(index))
	{
	    HideNoticeGUIFrame(index);
		new rows, fields;
		cache_get_data(rows, fields, ShopPipeline);
		if(rows > 0)
		{
		    new string[512];
		   	new status[2], name[64], quantity[8], delivered[8], product_id[8];
		    for(new i;i<rows;i++)
		    {
			    cache_get_value_name(i, "order_status_id", status, ShopPipeline);
				if(strval(status) == 2)
	   			{
					cache_get_value_name(i, "name", name, ShopPipeline);
	 				cache_get_value_name(i, "quantity", quantity, ShopPipeline);
		    		cache_get_value_name(i, "delivered", delivered, ShopPipeline);
	  				cache_get_value_name(i, "order_product_id", product_id, ShopPipeline);
		   			if(strval(quantity)-strval(delivered) <= 0)
				    {
	   					if(i<rows) format(string, sizeof(string), "%s%s (Delivered)\n", string, name);
	       				else format(string, sizeof(string), "%s%s (Delivered)", string, name);
					}
					else
					{
					    if(i<rows) format(string, sizeof(string), "%s%s (%d)\n", string, name, strval(quantity)-strval(delivered));
					    else format(string, sizeof(string), "%s%s (%d)", string, name, strval(quantity)-strval(delivered));
					}
				}
				else
				{
	    			new reason[27];
					switch(strval(status))
					{
	    				case 0: format(reason, sizeof(reason), "{FF0000}No Payment");
		   				case 1: format(reason, sizeof(reason), "{FF0000}Pending");
					    case 3: format(reason, sizeof(reason), "{00FF00}Shipped");
					    case 5:
						{
							ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", "This order has already been delivered", "OK", "");
							return 1;
						}
			   			case 7: format(reason, sizeof(reason), "{FF0000}Cancelled");
					    case 8: format(reason, sizeof(reason), "{FF0000}Denied");
					    case 9: format(reason, sizeof(reason), "{FF0000}Cancelled Reversal");
					    case 10: format(reason, sizeof(reason), "{FF0000}Failed");
			   			case 11: format(reason, sizeof(reason), "{00FF00}Refundend");
					    case 12: format(reason, sizeof(reason), "{FF0000}Reversed");
					    case 13: format(reason, sizeof(reason), "{FF0000}Chargeback");
					    default: format(reason, sizeof(reason), "{FF0000}Unknown");
					}
					format(string, sizeof(string), "We are unable to process that order at this time,\nbecause the payment is currently marked as: %s", reason);
					ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", string, "OK", "");
	 				return 1;
				}
			}
			ShowPlayerDialog(index, DIALOG_SHOPORDER2, DIALOG_STYLE_LIST, "Shop Order List", string, "Select", "Cancel");
		}
		else
		{
		    ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", "Error: No orders were found by that Order ID\nIf you are sure that is the correct Order ID, please try again or input '1' for your order ID.", "OK", "");
		}
	}
	return 1;
}

forward OnShopOrder2(index, extraid);
public OnShopOrder2(index, extraid)
{
	if(IsPlayerConnected(index))
	{
	    HideNoticeGUIFrame(index);
		new string[256];
		new rows, fields;
		cache_get_data(rows, fields, ShopPipeline);
		if(rows > 0)
		{
		    for(new i;i<rows;i++)
		    {
	  			if(i == extraid)
		    	{
	      			new status[2];
		        	cache_get_value_name(i, "status", status, ShopPipeline);
			        if(strval(status) == 2)
		        	{
			    		new order_id[8], order_product_id[8], product_id[8], name[64], price[8], user[32], quantity[8], delivered[8];
				    	cache_get_value_name(i, "order_id", order_id, ShopPipeline);
						cache_get_value_name(i, "order_product_id", order_product_id, ShopPipeline);
						cache_get_value_name(i, "product_id", product_id, ShopPipeline);
						cache_get_value_name(i, "name", name, ShopPipeline);
		  				cache_get_value_name(i, "price", price, ShopPipeline);
			  			cache_get_value_name(i, "deliveruser", user, ShopPipeline);
			  			cache_get_value_name(i, "quantity", quantity, ShopPipeline);
			  			cache_get_value_name(i, "delivered", delivered, ShopPipeline);

						format(string, sizeof(string), "Order ID: %d\nProduct ID: %d\nProduct: %s\nPrice: %s\nName: %s\nQuantity: %d", \
						strval(order_id), strval(order_product_id), name, price, user, strval(quantity)-strval(delivered));

						SetPVarInt(index, "DShop_order_id", strval(order_id));
						SetPVarInt(index, "DShop_product_id", strval(product_id));
						SetPVarString(index, "DShop_name", name);
						SetPVarInt(index, "DShop_quantity", strval(quantity)-strval(delivered));

						ShowPlayerDialog(index, DIALOG_SHOPDELIVER, DIALOG_STYLE_LIST, "Shop Order Info", string, "Deliver", "Cancel");
						return 1;
					}
					else
					{
						new reason[27];
						switch(strval(status))
						{
						    case 0: format(reason, sizeof(reason), "{FF0000}No Payment");
						    case 1: format(reason, sizeof(reason), "{FF0000}Pending");
						    case 3: format(reason, sizeof(reason), "{00FF00}Shipped");
						    case 5:
							{
								ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", "This order has already been delivered", "OK", "");
								return 1;
							}
			   				case 7: format(reason, sizeof(reason), "{FF0000}Cancelled");
						    case 8: format(reason, sizeof(reason), "{FF0000}Denied");
						    case 9: format(reason, sizeof(reason), "{FF0000}Cancelled Reversal");
						    case 10: format(reason, sizeof(reason), "{FF0000}Failed");
						    case 11: format(reason, sizeof(reason), "{00FF00}Refundend");
						    case 12: format(reason, sizeof(reason), "{FF0000}Reversed");
						    case 13: format(reason, sizeof(reason), "{FF0000}Chargeback");
						    default: format(reason, sizeof(reason), "{FF0000}Unknown");
						}
						format(string, sizeof(string), "We are unable to process that order at this time,\nbecause the payment is currently marked as: %s", reason);
						ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", string, "OK", "");
	  					return 1;
					}
				}
			}
		}
		else
		{
		    ShowPlayerDialog(index, 0, DIALOG_STYLE_MSGBOX, "Shop Order Error", "Error: No orders were found by that Order ID\nIf you are sure that is the correct Order ID, please try again or input '1' for your order ID.", "OK", "");
		}
	}
	return 1;
}
#endif*/

forward OnSetMyName(index);
public OnSetMyName(index)
{
	if(IsPlayerConnected(index))
	{
		new rows, fields;
		cache_get_data(rows, fields);
		if(!rows)
		{
			new string[128], tmpName[24];
			GetPVarString(index, "OnSetMyName", tmpName, 24);

			new name[MAX_PLAYER_NAME];
			GetPlayerName(index, name, sizeof(name));
			SetPVarString(index, "TempNameName", name);
			if(strlen(tmpName) > 0)
			{
				SetPlayerName(index, tmpName);
				format(string, sizeof(string), "%s da thay doi ten cua ho thanh %s.", name, tmpName);
				Log("logs/undercover.log", string);
				DeletePVar(index, "OnSetMyName");

				format(string, sizeof(string), "Ban tam thoi doi ten cua ban thanh %s.", tmpName);
				SendClientMessageEx(index, COLOR_YELLOW, string);
				SendClientMessageEx(index, COLOR_GRAD2, "NOTE: None of your stats will save until you type this command again.");
				SetPVarInt(index, "TempName", 1);
			}
		}
		else
		{
			SendClientMessageEx(index, COLOR_WHITE, "Ten nay da duoc dang ky.");
		}
	}
	else
	{
		DeletePVar(index, "OnSetMyName");
	}
	return 1;
}

forward OnSetName(index, extraid);
public OnSetName(index, extraid)
{
	if(IsPlayerConnected(index))
	{
		if(IsPlayerConnected(extraid))
		{
		    new rows, fields;
			cache_get_data(rows, fields);
			if(rows < 1)
			{
				new string[128], tmpName[24], playername[24];
				GetPVarString(index, "OnSetName", tmpName, 24);

				GetPlayerName(extraid, playername, sizeof(playername));

				UpdateCitizenApp(extraid, PlayerInfo[extraid][pNation]);
				
				if(PlayerInfo[extraid][pMarriedID] != -1)
				{
					foreach(new i: Player)
					{
						if(PlayerInfo[extraid][pMarriedID] == GetPlayerSQLId(i)) format(PlayerInfo[i][pMarriedName], MAX_PLAYER_NAME, "%s", tmpName);
					}
				}

				for(new i; i < MAX_DDOORS; i++)
				{
					if(DDoorsInfo[i][ddType] == 1 && DDoorsInfo[i][ddOwner] == GetPlayerSQLId(extraid))
					{
						strcat((DDoorsInfo[i][ddOwnerName][0] = 0, DDoorsInfo[i][ddOwnerName]), tmpName, 42);
						DestroyDynamicPickup(DDoorsInfo[i][ddPickupID]);
						if(IsValidDynamic3DTextLabel(DDoorsInfo[i][ddTextID])) DestroyDynamic3DTextLabel(DDoorsInfo[i][ddTextID]);
						CreateDynamicDoor(i);
						SaveDynamicDoor(i);
					}
				}

				if(Homes[extraid] > 0)
				{
					for(new i; i < MAX_HOUSES; i++)
					{
						if(GetPlayerSQLId(extraid) == HouseInfo[i][hOwnerID])
						{
							format(HouseInfo[i][hOwnerName], MAX_PLAYER_NAME, "%s", tmpName);
							SaveHouse(i);
							ReloadHouseText(i);
						}
					}
				}

				if(PlayerInfo[extraid][pDonateRank] >= 1)
				{
					new string2[128];
					format(string2, sizeof(string2), "[VIP NAMECHANGES] %s da thay doi ten cua ho thanh %s.", GetPlayerNameEx(extraid), tmpName);
					Log("logs/vipnamechanges.log", string2);
				}

				if(strlen(tmpName) > 0)
				{
					format(string, sizeof(string), " Ten cua ban da duoc thay doi tu %s thanh %s.", GetPlayerNameEx(extraid), tmpName);
					SendClientMessageEx(extraid,COLOR_YELLOW,string);
					format(string, sizeof(string), " Ban da thay doi ten %s's thanh %s.", GetPlayerNameEx(extraid), tmpName);
					SendClientMessageEx(index,COLOR_YELLOW,string);
					format(string, sizeof(string), "%s changed %s's name to %s",GetPlayerNameEx(index),GetPlayerNameExt(extraid),tmpName);
					Log("logs/stats.log", string);
					if(SetPlayerName(extraid, tmpName) == 1)
					{
    					format(string, sizeof(string), "UPDATE `accounts` SET `Username`='%s' WHERE `Username`='%s'", tmpName, playername);
						mysql_pquery(MainPipeline, string, "OnSetNameTwo", "ii", index, extraid);
					}
					else
					{
					    SendClientMessage(extraid, COLOR_REALRED, "Da co loi say ra cho viec doi ten cua ban.");
					    format(string, sizeof(string), "%s's Thay doi ten that bai do ten khong hop le.", GetPlayerNameExt(extraid));
					    SendClientMessage(extraid, COLOR_REALRED, string);
					    format(string, sizeof(string), "Loi thay doi ten %s's thanh %s", GetPlayerNameExt(extraid), tmpName);
					    Log("logs/stats.log", string);
					    return 1;
					}
					OnPlayerStatsUpdate(extraid);
				}
			}
		}
	}
	DeletePVar(index, "OnSetName");
	return 1;
}

forward OnSetNameTwo(index, extraid);
public OnSetNameTwo(index, extraid)
{
	return 1;
}

forward OnApproveName(index, extraid);
public OnApproveName(index, extraid)
{
	if(IsPlayerConnected(extraid))
	{
		new string[128];
		new rows, fields;
		cache_get_data(rows, fields);
		if(rows < 1)
		{
			new newname[24], oldname[24];
			GetPVarString(extraid, "NewNameRequest", newname, 24);
			GetPlayerName(extraid, oldname, sizeof(oldname));

			UpdateCitizenApp(extraid, PlayerInfo[extraid][pNation]);

			if(PlayerInfo[extraid][pMarriedID] != -1)
			{
				foreach(new i: Player)
				{
					if(PlayerInfo[extraid][pMarriedID] == GetPlayerSQLId(i)) format(PlayerInfo[i][pMarriedName], MAX_PLAYER_NAME, "%s", newname);
				}
			}
			
			for(new i; i < MAX_DDOORS; i++)
			{
				if(DDoorsInfo[i][ddType] == 1 && DDoorsInfo[i][ddOwner] == GetPlayerSQLId(extraid))
				{
					strcat((DDoorsInfo[i][ddOwnerName][0] = 0, DDoorsInfo[i][ddOwnerName]), newname, 42);
					DestroyDynamicPickup(DDoorsInfo[i][ddPickupID]);
					if(IsValidDynamic3DTextLabel(DDoorsInfo[i][ddTextID])) DestroyDynamic3DTextLabel(DDoorsInfo[i][ddTextID]);
					CreateDynamicDoor(i);
					SaveDynamicDoor(i);
				}
			}

			if(Homes[extraid] > 0)
			{
				for(new i; i < MAX_HOUSES; i++)
				{
					if(GetPlayerSQLId(extraid) == HouseInfo[i][hOwnerID])
					{
						format(HouseInfo[i][hOwnerName], MAX_PLAYER_NAME, "%s", newname);
						SaveHouse(i);
						ReloadHouseText(i);
					}
				}
			}

			if(PlayerInfo[extraid][pBusiness] != INVALID_BUSINESS_ID && Businesses[PlayerInfo[extraid][pBusiness]][bOwner] == GetPlayerSQLId(extraid))
			{
			    strcpy(Businesses[PlayerInfo[extraid][pBusiness]][bOwnerName], newname, MAX_PLAYER_NAME);
			    SaveBusiness(PlayerInfo[extraid][pBusiness]);
				RefreshBusinessPickup(PlayerInfo[extraid][pBusiness]);
			}

			if(PlayerInfo[extraid][pDonateRank] >= 1)
			{
				format(string, sizeof(string), "[VIP NAMECHANGES] %s da thay doi ten cua ho thanh %s.", GetPlayerNameEx(extraid), newname);
				Log("logs/vipnamechanges.log", string);
			}

			if((0 <= PlayerInfo[extraid][pMember] < MAX_GROUPS) && PlayerInfo[extraid][pRank] >= arrGroupData[PlayerInfo[extraid][pMember]][g_iFreeNameChange])
			{
				if(strlen(newname) > 0)
				{
					format(string, sizeof(string), " Ten cua ban da duoc thay doi tu %s thanh %s for free.", GetPlayerNameEx(extraid), newname);
					SendClientMessageEx(extraid,COLOR_YELLOW,string);
					format(string, sizeof(string), " Ban da thay doi ten %s's thanh %s at no cost.", GetPlayerNameEx(extraid), newname);
					SendClientMessageEx(index,COLOR_YELLOW,string);
					format(string, sizeof(string), "%s thay doi ten \"%s\"s thanh \"%s\" (id: %i)  for free.",GetPlayerNameEx(index),GetPlayerNameEx(extraid),newname, GetPlayerSQLId(extraid));
					Log("logs/stats.log", string);
					format(string, sizeof(string), "%s da chap nhan thay doi ten %s's thanh %s at no cost.",GetPlayerNameEx(index),GetPlayerNameEx(extraid), newname);
					ABroadCast(COLOR_YELLOW, string, 3);


					if(SetPlayerName(extraid, newname) == 1)
					{
    					format(string, sizeof(string), "UPDATE `accounts` SET `Username`='%s' WHERE `Username`='%s'", newname, oldname);
						mysql_pquery(MainPipeline, string, "OnApproveSetName", "ii", index, extraid);
					}
					else
					{
					    SendClientMessage(extraid, COLOR_REALRED, "Da co loi say ra cho viec doi ten cua ban.");
					    format(string, sizeof(string), "%s's Thay doi ten that bai do ten khong hop le.", GetPlayerNameExt(extraid));
					    SendClientMessage(index, COLOR_REALRED, string);
					    format(string, sizeof(string), "Loi thay doi ten %s's thanh %s", GetPlayerNameExt(extraid), newname);
					    Log("logs/stats.log", string);
					    return 1;
					}
					DeletePVar(extraid, "RequestingNameChange");
				}
			}

			else if(PlayerInfo[extraid][pAdmin] == 1 && PlayerInfo[extraid][pSMod] > 0)
			{
				if(strlen(newname) > 0)
				{
					format(string, sizeof(string), " Ten cua ban da duoc thay doi tu %s thanh %s mien phi (Senior Mod).", GetPlayerNameEx(extraid), newname);
					SendClientMessageEx(extraid,COLOR_YELLOW,string);
					format(string, sizeof(string), " Ban da thay doi ten %s's thanh %s mien phi.", GetPlayerNameEx(extraid), newname);
					SendClientMessageEx(index,COLOR_YELLOW,string);
					format(string, sizeof(string), "%s thay doi ten \"%s\"s thanh \"%s\" (id: %i) mien phi (Senior Mod).",GetPlayerNameEx(index),GetPlayerNameEx(extraid),newname, GetPlayerSQLId(extraid));
					Log("logs/stats.log", string);
					format(string, sizeof(string), "%s da chap nhan thay doi ten %s's thanh %s mien phi (Senior Mod).",GetPlayerNameEx(index),GetPlayerNameEx(extraid), newname);
					ABroadCast(COLOR_YELLOW, string, 3);

					if(SetPlayerName(extraid, newname) == 1)
					{
    					format(string, sizeof(string), "UPDATE `accounts` SET `Username`='%s' WHERE `Username`='%s'", newname, oldname);
						mysql_pquery(MainPipeline, string, "OnApproveSetName", "ii", index, extraid);
					}
					else
					{
					    SendClientMessage(extraid, COLOR_REALRED, "Da co loi say ra cho viec doi ten cua ban.");
					    format(string, sizeof(string), "%s's Thay doi ten that bai do ten khong hop le.", GetPlayerNameExt(extraid));
					    SendClientMessage(index, COLOR_REALRED, string);
					    format(string, sizeof(string), "Loi thay doi ten %s's thanh %s", GetPlayerNameExt(extraid), newname);
					    Log("logs/stats.log", string);
					    return 1;
					}
					DeletePVar(extraid, "RequestingNameChange");
				}
			}

			else
			{
				if(GetPVarInt(extraid, "NameChangeCost") == 0)
				{
					if(strlen(newname) > 0)
					{
						format(string, sizeof(string), " Ten cua ban da duoc thay doi tu %s thanh %s mien phi (non-RP name).", GetPlayerNameEx(extraid), newname);
						SendClientMessageEx(extraid,COLOR_YELLOW,string);
						format(string, sizeof(string), " Ban da thay doi ten %s's thanh %s mien phi (non-RP name).", GetPlayerNameEx(extraid), newname);
						SendClientMessageEx(index,COLOR_YELLOW,string);
						format(string, sizeof(string), "%s thay doi ten \"%s\"s thanh \"%s\" (id: %i) mien phi (non-RP name).",GetPlayerNameEx(index),GetPlayerNameEx(extraid),newname, GetPlayerSQLId(extraid));
						Log("logs/stats.log", string);
						format(string, sizeof(string), "%s da phe duyet doi ten %s's thanh %s mien phi (non-RP name).",GetPlayerNameEx(index),GetPlayerNameEx(extraid), newname);
						ABroadCast(COLOR_YELLOW, string, 3);

						if(SetPlayerName(extraid, newname) == 1)
						{
	    					format(string, sizeof(string), "UPDATE `accounts` SET `Username`='%s' WHERE `Username`='%s'", newname, oldname);
							mysql_pquery(MainPipeline, string, "OnApproveSetName", "ii", index, extraid);
						}
						else
						{
						    SendClientMessage(extraid, COLOR_REALRED, "Da co loi say ra cho viec doi ten cua ban.");
						    format(string, sizeof(string), "%s's thay doi ten that bai do ten khong hop le.", GetPlayerNameExt(extraid));
						    SendClientMessage(index, COLOR_REALRED, string);
						    format(string, sizeof(string), "Loi thay doi ten %s'sthanh %s", GetPlayerNameExt(extraid), newname);
						    Log("logs/stats.log", string);
						    return 1;
						}
						DeletePVar(extraid, "RequestingNameChange");
					}
				}
				else
				{
					if(strlen(newname) > 0)
					{
						GivePlayerCash(extraid, -GetPVarInt(extraid, "NameChangeCost"));
						format(string, sizeof(string), " Ten cua ban da duoc thay doi %s thanh %s voi gia $%d.", GetPlayerNameEx(extraid), newname, GetPVarInt(extraid, "NameChangeCost"));
						SendClientMessageEx(extraid,COLOR_YELLOW,string);
						format(string, sizeof(string), " Ban da thay doi ten %s's thanh %s voi gia $%d.", GetPlayerNameEx(extraid), newname, GetPVarInt(extraid, "NameChangeCost"));
						SendClientMessageEx(index,COLOR_YELLOW,string);
						format(string, sizeof(string), "%s thay doi ten \"%s\"s thanh \"%s\" (id: %i) voi gia $%d",GetPlayerNameEx(index),GetPlayerNameEx(extraid),newname, GetPlayerSQLId(extraid), GetPVarInt(extraid, "NameChangeCost"));
						Log("logs/stats.log", string);
						format(string, sizeof(string), "%s da phe duyet doi ten %s's thanh %s voi gia $%d",GetPlayerNameEx(index),GetPlayerNameEx(extraid), newname, GetPVarInt(extraid, "NameChangeCost"));
						ABroadCast(COLOR_YELLOW, string, 3);

						if(SetPlayerName(extraid, newname) == 1)
						{
	    					format(string, sizeof(string), "UPDATE `accounts` SET `Username`='%s' WHERE `Username`='%s'", newname, oldname);
							mysql_pquery(MainPipeline, string, "OnApproveSetName", "ii", index, extraid);
						}
						else
						{
						    SendClientMessage(extraid, COLOR_REALRED, "Da co loi say ra cho viec doi ten cua ban.");
						    format(string, sizeof(string), "%s's thay doi ten that bai do ten khong hop le.", GetPlayerNameExt(extraid));
						    SendClientMessage(index, COLOR_REALRED, string);
						    format(string, sizeof(string), "Loi thay doi ten %s's thanh %s", GetPlayerNameExt(extraid), newname);
						    Log("logs/stats.log", string);
						    return 1;
						}

						DeletePVar(extraid, "RequestingNameChange");
					}
				}
			}
		}
		else
		{
			SendClientMessageEx(extraid, COLOR_GRAD2, "Ten do da ton tai, vui long dat ten khac.");
			SendClientMessageEx(index, COLOR_GRAD2, "Ten do da ton tai.");
			DeletePVar(extraid, "RequestingNameChange");
			return 1;
		}
	}
	return 1;
}

forward OnIPWhitelist(index);
public OnIPWhitelist(index)
{
	new string[128], name[24];
	GetPVarString(index, "OnIPWhitelist", name, 24);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "You have successfully whitelisted %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);
		format(string, sizeof(string), "%s has IP Whitelisted %s", GetPlayerNameEx(index), name);
		Log("logs/whitelist.log", string);
	}
	else {
		format(string, sizeof(string), "There was a issue with whitelisting %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);
	}
	DeletePVar(index, "OnIPWhitelist");

	return 1;
}

forward OnIPCheck(index);
public OnIPCheck(index)
{
	if(IsPlayerConnected(index))
	{
		new string[128], ip[16], name[24];
		new rows, fields;
		cache_get_data(rows, fields);
		if(rows)
		{
   			cache_get_value_name(0, "IP", ip, 16);
   			cache_get_value_name(0, "Username", name, MAX_PLAYER_NAME);
			format(string, sizeof(string), "%s's IP: %s", name, ip);
			SendClientMessageEx(index, COLOR_WHITE, string);
			format(string, sizeof(string), "%s has IP Checked %s", GetPlayerNameEx(index), name);
			Log("logs/ipcheck.log", string);
		}
		else
		{
			SendClientMessageEx(index, COLOR_WHITE, "There was an issue with checking the account's IP.");
		}
	}
	return 1;
}

forward OnProcessOrderCheck(index, extraid);
public OnProcessOrderCheck(index, extraid)
{
	if(IsPlayerConnected(index))
	{
		new string[164],playerip[32], giveplayerip[32];
		GetPlayerIp(index, playerip, sizeof(playerip));
		GetPlayerIp(extraid, giveplayerip, sizeof(giveplayerip));

		new rows, fields;
		cache_get_data(rows, fields);
		if(rows)
		{
			SendClientMessageEx(index, COLOR_WHITE, "This order has previously been processed, therefore it did not count toward your pay.");
			format(string, sizeof(string), "%s(IP: %s) has processed shop order ID %d from %s(IP: %s).", GetPlayerNameEx(index), playerip, GetPVarInt(index, "processorder"), GetPlayerNameEx(extraid), giveplayerip);
			Log("logs/shoporders.log", string);
		}
		else
		{
			format(string, sizeof(string), "%s(IP: %s) has processed shop order ID %d from %s(IP: %s).", GetPlayerNameEx(index), playerip, GetPVarInt(index, "processorder"), GetPlayerNameEx(extraid), giveplayerip);
			Log("logs/shopconfirmedorders.log", string);
			PlayerInfo[index][pShopTechOrders]++;

			format(string, sizeof(string), "INSERT INTO shoptech (id,total,dtotal) VALUES (%d,1,%f) ON DUPLICATE KEY UPDATE total = total + 1, dtotal = dtotal + %f", GetPlayerSQLId(index), ShopTechPay, ShopTechPay);
			mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, index);

			format(string, sizeof(string), "INSERT INTO `orders` (`id`) VALUES ('%d')", GetPVarInt(index, "processorder"));
			mysql_pquery(MainPipeline, string, "OnQueryFinish", "ii", SENDDATA_THREAD, index);
		}
		DeletePVar(index, "processorder");
	}
	return 1;
}

forward OnFine(index);
public OnFine(index)
{
	new string[128], name[24], amount, reason[64];
	GetPVarString(index, "OnFine", name, 24);
	amount = GetPVarInt(index, "OnFineAmount");
	GetPVarString(index, "OnFineReason", reason, 64);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "You have successfully fined %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);

		format(string, sizeof(string), "AdmCmd: %s was offline fined $%d by %s, reason: %s", name, amount, GetPlayerNameEx(index), reason);
		Log("logs/admin.log", string);
	}
	else {
		format(string, sizeof(string), "There was an issue with fining %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);
	}
	DeletePVar(index, "OnFine");
	DeletePVar(index, "OnFineAmount");
	DeletePVar(index, "OnFineReason");

	return 1;
}

forward OnSetDDOwner(playerid, doorid);
public OnSetDDOwner(playerid, doorid)
{
	if(IsPlayerConnected(playerid))
	{
	    new rows, fields;
	    new string[128], sqlid[5], playername[MAX_PLAYER_NAME], id;
    	cache_get_data(rows, fields);

    	if(rows)
    	{
			cache_get_value_name(0, "id", sqlid); id = strval(sqlid);
			cache_get_value_name(0, "Username", playername, MAX_PLAYER_NAME);
			strcat((DDoorsInfo[doorid][ddOwnerName][0] = 0, DDoorsInfo[doorid][ddOwnerName]), playername, MAX_PLAYER_NAME);
			DDoorsInfo[doorid][ddOwner] = id;

			format(string, sizeof(string), "Successfully set the owner to %s.", playername);
			SendClientMessageEx(playerid, COLOR_WHITE, string);

			DestroyDynamicPickup(DDoorsInfo[doorid][ddPickupID]);
			if(IsValidDynamic3DTextLabel(DDoorsInfo[doorid][ddTextID])) DestroyDynamic3DTextLabel(DDoorsInfo[doorid][ddTextID]);
			CreateDynamicDoor(doorid);
			SaveDynamicDoor(doorid);
			format(string, sizeof(string), "%s da chinh sua door ID %d's owner to %s (SQL ID: %d).", GetPlayerNameEx(playerid), doorid, playername, id);
			Log("logs/ddedit.log", string);
		}
		else SendClientMessageEx(playerid, COLOR_GREY, "Tai khoan do khong ton tai.");
	}
	return 1;
}

forward OnPrisonAccount(index);
public OnPrisonAccount(index)
{
	new string[128], name[24], reason[64];
	GetPVarString(index, "OnPrisonAccount", name, 24);
	GetPVarString(index, "OnPrisonAccountReason", reason, 64);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "You have successfully prisoned %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);

		format(string, sizeof(string), "AdmCmd: %s da bi giam giu offline boi %s, ly do: %s ", name, GetPlayerNameEx(index), reason);
		Log("logs/admin.log", string);
	}
	else {
		format(string, sizeof(string), "Da co mot van de say ra voi bo tu %s's.");
		SendClientMessageEx(index, COLOR_WHITE, string);
	}
	DeletePVar(index, "OnPrisonAccount");
	DeletePVar(index, "OnPrisonAccountReason");

	return 1;
}

forward OnJailAccount(index);
public OnJailAccount(index)
{
	new string[128], name[24], reason[64];
	GetPVarString(index, "OnJailAccount", name, 24);
	GetPVarString(index, "OnJailAccountReason", reason, 64);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "Ban da bo tu thanh cong nguoi choi %s's .", name);
		SendClientMessageEx(index, COLOR_WHITE, string);

		format(string, sizeof(string), "AdmCmd: %s da bi bo tu offline boi %s, ly do: %s", name, GetPlayerNameEx(index), reason);
		Log("logs/admin.log", string);
	}
	else {
		format(string, sizeof(string), "Da co mot van de say ra khi bo tu %s's.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);
	}

	DeletePVar(index, "OnJailAccount");
	DeletePVar(index, "OnJailAccountReason");

	return 1;
}

forward OnGetLatestKills(playerid, giveplayerid);
public OnGetLatestKills(playerid, giveplayerid)
{
    new string[128], killername[MAX_PLAYER_NAME], killedname[MAX_PLAYER_NAME], kDate[20], weapon[56], rows, fields;
	cache_get_data(rows, fields);
	if(rows)
	{
		for(new i; i < rows; i++)
		{
			cache_get_value_index(i, 0, killername, MAX_PLAYER_NAME);
			cache_get_value_index(i, 1, killedname, MAX_PLAYER_NAME);
			cache_get_value_name(i, "killerid", string); new killer = strval(string);
			cache_get_value_name(i, "killedid", string); new killed = strval(string);
			cache_get_value_name(i, "date", kDate, sizeof(kDate));
			cache_get_value_name(i, "weapon", weapon, sizeof(weapon));
			if(GetPlayerSQLId(giveplayerid) == killer && GetPlayerSQLId(giveplayerid) == killed) format(string, sizeof(string), "[%s] %s killed themselves (%s)", kDate, StripUnderscore(killedname), weapon);
			else if(GetPlayerSQLId(giveplayerid) == killer && GetPlayerSQLId(giveplayerid) != killed) format(string, sizeof(string), "[%s] %s killed %s with %s", kDate, StripUnderscore(killername), StripUnderscore(killedname), weapon);
			else if(GetPlayerSQLId(giveplayerid) != killer && GetPlayerSQLId(giveplayerid) == killed) format(string, sizeof(string), "[%s] %s was killed by %s with %s", kDate, StripUnderscore(killedname), StripUnderscore(killername), weapon);
			SendClientMessageEx(playerid, COLOR_YELLOW, string);
		}
	}
	else SendClientMessageEx(playerid, COLOR_YELLOW, "No kills recorded on this player.");
	return 1;
}

forward OnGetOKills(playerid);
public OnGetOKills(playerid)
{
	if(IsPlayerConnected(playerid))
	{
		new string[256], giveplayername[MAX_PLAYER_NAME], giveplayerid;

		new rows, fields;
		cache_get_data(rows, fields);

		if(rows)
		{
			cache_get_value_name(0, "id", string); giveplayerid = strval(string);
			cache_get_value_name(0, "Username", giveplayername, MAX_PLAYER_NAME);
			format(string, sizeof(string), "SELECT Killer.Username, Killed.Username, k.* FROM Kills k LEFT JOIN accounts Killed ON k.killedid = Killed.id LEFT JOIN accounts Killer ON Killer.id = k.killerid WHERE k.killerid = %d OR k.killedid = %d ORDER BY `date` DESC LIMIT 10", giveplayerid, giveplayerid);
			mysql_pquery(MainPipeline, string, "OnGetLatestOKills", "iis", playerid, giveplayerid, giveplayername);
		}
		else return SendClientMessageEx(playerid, COLOR_GREY, "This account does not exist.");
	}
	return 1;
}

forward OnGetLatestOKills(playerid, giveplayerid, giveplayername[]);
public OnGetLatestOKills(playerid, giveplayerid, giveplayername[])
{
    new string[128], killername[MAX_PLAYER_NAME], killedname[MAX_PLAYER_NAME], kDate[20], weapon[56], rows, fields;
	cache_get_data(rows, fields);
	if(rows)
	{
		SendClientMessageEx(playerid, COLOR_GREEN, "________________________________________________");
		format(string, sizeof(string), "<< Last 10 Kills/Deaths of %s >>", StripUnderscore(giveplayername));
		SendClientMessageEx(playerid, COLOR_YELLOW, string);
		for(new i; i < rows; i++)
		{
			cache_get_value_index(i, 0, killername, MAX_PLAYER_NAME);
			cache_get_value_index(i, 1, killedname, MAX_PLAYER_NAME);
			cache_get_value_name(i, "killerid", string); new killer = strval(string);
			cache_get_value_name(i, "killedid", string); new killed = strval(string);
			cache_get_value_name(i, "date", kDate, sizeof(kDate));
			cache_get_value_name(i, "weapon", weapon, sizeof(weapon));
			if(giveplayerid == killer && giveplayerid == killed) format(string, sizeof(string), "[%s] %s killed themselves (%s)", kDate, StripUnderscore(killedname), weapon);
			else if(giveplayerid == killer && giveplayerid != killed) format(string, sizeof(string), "[%s] %s killed %s with %s", kDate, StripUnderscore(killername), StripUnderscore(killedname), weapon);
			else if(giveplayerid != killer && giveplayerid == killed) format(string, sizeof(string), "[%s] %s was killed by %s with %s", kDate, StripUnderscore(killedname), StripUnderscore(killername), weapon);
			SendClientMessageEx(playerid, COLOR_YELLOW, string);
		}
	}
	else return SendClientMessageEx(playerid, COLOR_YELLOW, "No kills recorded on this player.");
	return 1;
}

forward OnDMStrikeReset(playerid, giveplayerid);
public OnDMStrikeReset(playerid, giveplayerid)
{
	new string[128];
	format(string, sizeof(string), "Deleted %d strikes against %s", mysql_affected_rows(MainPipeline), GetPlayerNameEx(giveplayerid));
	SendClientMessage(playerid, COLOR_WHITE, string);
	return 1;
}

forward OnDMRLookup(playerid, giveplayerid);
public OnDMRLookup(playerid, giveplayerid)
{
	new string[128], rows, fields;
	cache_get_data(rows, fields);
	format(string, sizeof(string), "Hien thi cuoi cung %d /dmreports boi %s", rows, GetPlayerNameEx(giveplayerid));
	SendClientMessage(playerid, COLOR_WHITE, string);
	SendClientMessage(playerid, COLOR_WHITE, "| Reported | Time |");
	for(new i;i < rows;i++)
	{
 		new szResult[32], name[MAX_PLAYER_NAME], timestamp;
		cache_get_value_index(i, 0, szResult); timestamp = strval(szResult);
		cache_get_value_index(i, 1, name, MAX_PLAYER_NAME);
		format(string, sizeof(string), "%s - %s", name, date(timestamp, 1));
		SendClientMessage(playerid, COLOR_WHITE, string);
	}
	return 1;
}

forward OnDMTokenLookup(playerid, giveplayerid);
public OnDMTokenLookup(playerid, giveplayerid)
{
	new string[128], rows, fields;
	cache_get_data(rows, fields);
	format(string, sizeof(string), "Hien thi %d hoat dong /dmreports tren %s", rows, GetPlayerNameEx(giveplayerid));
	SendClientMessage(playerid, COLOR_WHITE, string);
	SendClientMessage(playerid, COLOR_WHITE, "| Reporter | Time |");
	for(new i;i < rows;i++)
	{
 		new szResult[32], name[MAX_PLAYER_NAME], timestamp;
		cache_get_value_index(i, 0, szResult); timestamp = strval(szResult);
		cache_get_value_index(i, 1, name);
		format(string, sizeof(string), "%s - %s", name, date(timestamp, 1));
		SendClientMessage(playerid, COLOR_WHITE, string);
	}
	return 1;
}

forward OnDMWatchListLookup(playerid);
public OnDMWatchListLookup(playerid)
{
	new string[128], rows, fields;
	cache_get_data(rows, fields);
	format(string, sizeof(string), "Hien thi %d nguoi hoat dong de xem", rows);
	SendClientMessage(playerid, COLOR_WHITE, string);
	for(new i;i < rows;i++)
	{
 		new name[MAX_PLAYER_NAME], watchid;
		cache_get_value_index(i, 0, name);
		sscanf(name, "u", watchid);
		format(string, sizeof(string), "(ID: %d) %s", watchid, name);
		SendClientMessage(playerid, COLOR_WHITE, string);
	}
	return 1;
}

forward OnDMWatch(playerid);
public OnDMWatch(playerid)
{
	new rows, fields;
    cache_get_data(rows, fields);
    if(rows)
    {
		new string[128], namesql[MAX_PLAYER_NAME], name[MAX_PLAYER_NAME];
		cache_get_value_index(0, 0, namesql);
		foreach(new i: Player)
		{
			if(!PlayerInfo[i][pJailTime])
			{
			    GetPlayerName(i, name, sizeof(name));
				if(strcmp(name, namesql, true) == 0)
				{
				    foreach(new x: Player)
				    {
				        if(GetPVarInt(x, "pWatchdogWatching") == i)
				        {
				            return SendClientMessage(playerid, COLOR_WHITE, "Nguoi ngau nhien do ban chon da bi theo doi, vui long thu lai!");
				        }
				    }
				    format(string, sizeof(string), "Bay gio ban co the /spec %s (ID: %i). Su dung /dmalert neu nguoi nay deathmatches.", name, i);
				    SendClientMessage(playerid, COLOR_WHITE, string);
				    return SetPVarInt(playerid, "pWatchdogWatching", i);
				}
			}
		}
	}
	return SendClientMessageEx(playerid, COLOR_WHITE, "There is no one online to DM Watch!");
}

forward OnWarnPlayer(index);
public OnWarnPlayer(index)
{
	new string[128], name[24], reason[64];
	GetPVarString(index, "OnWarnPlayer", name, 24);
	GetPVarString(index, "OnWarnPlayerReason", reason, 64);

	if(mysql_affected_rows(MainPipeline)) {
		format(string, sizeof(string), "You have successfully warned %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);

		format(string, sizeof(string), "AdmCmd: %s was offline warned by %s, reason: %s", name, GetPlayerNameEx(index), reason);
		Log("logs/admin.log", string);
	}
	else {
		format(string, sizeof(string), "There was an issue with warning %s's account.", name);
		SendClientMessageEx(index, COLOR_WHITE, string);
	}
	DeletePVar(index, "OnWarnPlayer");
	DeletePVar(index, "OnWarnPlayerReason");

	return 1;
}

forward OnPinCheck2(index);
public OnPinCheck2(index)
{
	if(IsPlayerConnected(index))
	{
		new rows, fields;
		cache_get_data(rows, fields);
		if(rows)
		{
		    new Pin[256];
   			cache_get_value_name(0, "Pin", Pin, 256);
   			if(isnull(Pin)) {
   			    ShowPlayerDialog(index, DIALOG_CREATEPIN, DIALOG_STYLE_INPUT, "Mat khau cap 2", "Tao mat khau cap 2 de bao ve Credits cua ban.", "Khoi tao", "Thoat");
   			}
   			else
   			{
   			    new passbuffer[256], passbuffer2[64];
            	GetPVarString(index, "PinNumber", passbuffer2, sizeof(passbuffer2));
				WP_Hash(passbuffer, sizeof(passbuffer), passbuffer2);
				if (strcmp(passbuffer, Pin) == 0)
				{
				    SetPVarInt(index, "PinConfirmed", 1);
					SendClientMessageEx(index, COLOR_CYAN, "Mat khau cap 2 xac nhan, bay gio ban co the su dung Credits.");
					switch(GetPVarInt(index, "OpenShop"))
					{
	    				case 1:
						{
							new szDialog[512];
						 	format(szDialog, sizeof(szDialog), "Poker Table (Credits: {FFD700}%s{A9C4E4})\nBoombox (Credits: {FFD700}%s{A9C4E4})\n100 Paintball Tokens (Credits: {FFD700}%s{A9C4E4})\nEXP Token (Credits: {FFD700}%s{A9C4E4})\nFireworks x5 (Credits: {FFD700}%s{A9C4E4})\nBien so xe (Credits: {FFD700}%s{A9C4E4})" \
							"\nHunger Games Voucher(Credits: {FFD700}%s{A9C4E4})",
							number_format(ShopItems[6][sItemPrice]), number_format(ShopItems[7][sItemPrice]), number_format(ShopItems[8][sItemPrice]), number_format(ShopItems[9][sItemPrice]), 
							number_format(ShopItems[10][sItemPrice]), number_format(ShopItems[22][sItemPrice]), number_format(ShopItems[29][sItemPrice]));
							ShowPlayerDialog(index, DIALOG_MISCSHOP, DIALOG_STYLE_LIST, "Misc Shop", szDialog, "Select", "Cancel");
						}
						case 2: SetPVarInt(index, "RentaCar", 1), ShowModelSelectionMenu(index, CarList2, "Rent a Car!");
						case 3: ShowModelSelectionMenu(index, CarList2, "Car Shop");
						case 4: ShowPlayerDialog( index, DIALOG_HOUSESHOP, DIALOG_STYLE_LIST, "House Shop", "Mua nha\nThay doi noi that\nDi chuyen nha\nGarage - Nho\nGarage - Trung binh\nGarage - To\nGarage - Cuc to","Lua chon", "Thoat" );
						case 5: ShowPlayerDialog( index, DIALOG_VIPSHOP, DIALOG_STYLE_LIST, "VIP Shop", "Mua VIP\nGia han Gold VIP","Tiep tuc", "Thoat" );
						case 6: ShowPlayerDialog(index, DIALOG_SHOPBUSINESS, DIALOG_STYLE_LIST, "Businesses Shop", "Mua cua hang\nGian han cua hang", "Lua chon", "Thoat");
						case 7: ShowModelSelectionMenu(index, PlaneList, "Shop may bay");
						case 8: ShowModelSelectionMenu(index, BoatList, "Shop thuyen");
						case 9: ShowModelSelectionMenu(index, CarList3, "Restricted Car Shop");
					}
					DeletePVar(index, "OpenShop");
				}
				else
				{
    				ShowPlayerDialog(index, DIALOG_ENTERPIN, DIALOG_STYLE_INPUT, "Mat khau cap 2", "(INVALID PIN)\n\nNhap mat khau cap 2 cua ban de vao cua hang Credits.", "Xac nhan", "Huy bo");
				}
				DeletePVar(index, "PinNumber");
  			}
		}
		else
		{
			SendClientMessageEx(index, COLOR_WHITE, "Co mot van de say ra, vui long thu lai.");
		}
	}
	return 1;
}

forward OnPinCheck(index);
public OnPinCheck(index)
{
	if(IsPlayerConnected(index))
	{
		new rows, fields;
		cache_get_data(rows, fields);
		if(rows)
		{
		    new Pin[128];
   			cache_get_value_name(0, "Pin", Pin, 128);
   			if(isnull(Pin)) {
   			    ShowPlayerDialog(index, DIALOG_CREATEPIN, DIALOG_STYLE_INPUT, "Mat khau cap 2", "Tao mat khau cap 2 de bao ve Credits cua ban.", "Khoi tao", "Huy bo");
   			}
   			else
   			{
   			    ShowPlayerDialog(index, DIALOG_ENTERPIN, DIALOG_STYLE_INPUT, "Mat khau cap 2", "Nhap mat khau cap 2 cua ban de vao cua hang Credits.", "Xac nhan", "Huy bo");
   			}
		}
		else
		{
			SendClientMessageEx(index, COLOR_WHITE, "Co mot van de say ra, vui long thu lai.");
		}
	}
	return 1;
}

forward OnGetSMSLog(playerid);
public OnGetSMSLog(playerid)
{
    new string[128], sender[MAX_PLAYER_NAME], message[256], sDate[20], rows, fields;
	cache_get_data(rows, fields);
	if(rows)
	{
		SendClientMessageEx(playerid, COLOR_GREEN, "________________________________________________");
		SendClientMessageEx(playerid, COLOR_YELLOW, "<< 10 tin nhan SMS da nhan >>");
		for(new i; i < rows; i++)
		{
			cache_get_value_name(i, "sender", sender, MAX_PLAYER_NAME);
			cache_get_value_name(i, "sendernumber", string); new sendernumber = strval(string);
			cache_get_value_name(i, "message", message, sizeof(message));
			cache_get_value_name(i, "date", sDate, sizeof(sDate));
			if(sendernumber != 0) format(string, sizeof(string), "[%s] SMS: %s, Nguoi gui: %s (%d)", sDate, message, StripUnderscore(sender), sendernumber);
			else format(string, sizeof(string), "[%s] SMS: %s, Nguoi gui: Khong biet", sDate, message);
			SendClientMessageEx(playerid, COLOR_YELLOW, string);
		}
	}
	else SendClientMessageEx(playerid, COLOR_GREY, "Ban chua nhan bat ki tin nhan SMS nao.");
	return 1;
}

forward Group_QueryFinish(iType, iExtraID);
public Group_QueryFinish(iType, iExtraID) {

	/*
		Internally, every group array/subarray starts from zero (divisions, group ids etc)
		When displaying to the clients or saving to the db, we add 1 to them!
		The only exception is ranks which already start from zero.
	*/

	new
		iFields,
		iRows,
		iIndex,
		i = 0,
		szResult[128];

	cache_get_data(iRows, iFields);

	switch(iType) {
		case GROUP_QUERY_JURISDICTIONS:
  		{
  		    for(new iG = 0; iG < MAX_GROUPS; iG++)
  		    {
  		        arrGroupData[iG][g_iJCount] = 0;
  		    }
			while(iIndex < iRows) {

				cache_get_value_name(iIndex, "GroupID", szResult, 24);
				new iGroup = strval(szResult);

				if(arrGroupData[iGroup][g_iJCount] > MAX_GROUP_JURISDICTIONS) arrGroupData[iGroup][g_iJCount] = MAX_GROUP_JURISDICTIONS;
				if (!(0 <= iGroup < MAX_GROUPS)) break;
				cache_get_value_name(iIndex, "id", szResult, 24);
				arrGroupJurisdictions[iGroup][arrGroupData[iGroup][g_iJCount]][g_iJurisdictionSQLId] = strval(szResult);
				cache_get_value_name(iIndex, "AreaName", arrGroupJurisdictions[iGroup][arrGroupData[iGroup][g_iJCount]][g_iAreaName], 64);
				arrGroupData[iGroup][g_iJCount]++;
				iIndex++;
			}
		}
		case GROUP_QUERY_LOCKERS: while(iIndex < iRows) {

			cache_get_value_name(iIndex, "Group_ID", szResult);
			new iGroup = strval(szResult)-1;

			cache_get_value_name(iIndex, "Locker_ID", szResult);
			new iLocker = strval(szResult)-1;

			if (!(0 <= iGroup < MAX_GROUPS)) break;
			if (!(0 <= iLocker < MAX_GROUP_LOCKERS)) break;

			cache_get_value_name(iIndex, "Id", szResult);
			arrGroupLockers[iGroup][iLocker][g_iLockerSQLId] = strval(szResult);

			cache_get_value_name(iIndex, "LockerX", szResult);
			arrGroupLockers[iGroup][iLocker][g_fLockerPos][0] = floatstr(szResult);

			cache_get_value_name(iIndex, "LockerY", szResult);
			arrGroupLockers[iGroup][iLocker][g_fLockerPos][1] = floatstr(szResult);

			cache_get_value_name(iIndex, "LockerZ", szResult);
			arrGroupLockers[iGroup][iLocker][g_fLockerPos][2] = floatstr(szResult);

			cache_get_value_name(iIndex, "LockerVW", szResult);
			arrGroupLockers[iGroup][iLocker][g_iLockerVW] = strval(szResult);

			cache_get_value_name(iIndex, "LockerShare", szResult);
			arrGroupLockers[iGroup][iLocker][g_iLockerShare] = strval(szResult);

			format(szResult, sizeof szResult, "Tu do %s \n{1FBDFF}/tudo{FFFF00} de su dung\n ID: %i", arrGroupData[iGroup][g_szGroupName], arrGroupLockers[iGroup][iLocker]);
			arrGroupLockers[iGroup][iLocker][g_tLocker3DLabel] = CreateDynamic3DTextLabel(szResult, arrGroupData[iGroup][g_hDutyColour] * 256 + 0xFF, arrGroupLockers[iGroup][iLocker][g_fLockerPos][0], arrGroupLockers[iGroup][iLocker][g_fLockerPos][1], arrGroupLockers[iGroup][iLocker][g_fLockerPos][2], 15.0, .testlos = 1, .worldid = arrGroupLockers[iGroup][iLocker][g_iLockerVW]);
			iIndex++;

		}
		case GROUP_QUERY_LOAD: while(iIndex < iRows) {
			cache_get_value_name(iIndex, "Name", arrGroupData[iIndex][g_szGroupName], GROUP_MAX_NAME_LEN);

			cache_get_value_name(iIndex, "MOTD", arrGroupData[iIndex][g_szGroupMOTD], GROUP_MAX_MOTD_LEN);

			cache_get_value_name(iIndex, "Type", szResult);
			arrGroupData[iIndex][g_iGroupType] = strval(szResult);

			cache_get_value_name(iIndex, "Allegiance", szResult);
			arrGroupData[iIndex][g_iAllegiance] = strval(szResult);

			cache_get_value_name(iIndex, "Bug", szResult);
			arrGroupData[iIndex][g_iBugAccess] = strval(szResult);

			cache_get_value_name(iIndex, "RadioColour", szResult);
			arrGroupData[iIndex][g_hRadioColour] = strval(szResult);

			cache_get_value_name(iIndex, "Radio", szResult);
			arrGroupData[iIndex][g_iRadioAccess] = strval(szResult);

			cache_get_value_name(iIndex, "DeptRadio", szResult);
			arrGroupData[iIndex][g_iDeptRadioAccess] = strval(szResult);

			cache_get_value_name(iIndex, "IntRadio", szResult);
			arrGroupData[iIndex][g_iIntRadioAccess] = strval(szResult);

			cache_get_value_name(iIndex, "GovAnnouncement", szResult);
			arrGroupData[iIndex][g_iGovAccess] = strval(szResult);

			cache_get_value_name(iIndex, "FreeNameChange", szResult);
			arrGroupData[iIndex][g_iFreeNameChange] = strval(szResult);

			cache_get_value_name(iIndex, "Budget", szResult);
			arrGroupData[iIndex][g_iBudget] = strval(szResult);

			cache_get_value_name(iIndex, "BudgetPayment", szResult);
			arrGroupData[iIndex][g_iBudgetPayment] = strval(szResult);

			cache_get_value_name(iIndex, "SpikeStrips", szResult);
			arrGroupData[iIndex][g_iSpikeStrips] = strval(szResult);

			cache_get_value_name(iIndex, "Barricades", szResult);
			arrGroupData[iIndex][g_iBarricades] = strval(szResult);

			cache_get_value_name(iIndex, "Cones", szResult);
			arrGroupData[iIndex][g_iCones] = strval(szResult);

			cache_get_value_name(iIndex, "Flares", szResult);
			arrGroupData[iIndex][g_iFlares] = strval(szResult);

			cache_get_value_name(iIndex, "Barrels", szResult);
			arrGroupData[iIndex][g_iBarrels] = strval(szResult);

			cache_get_value_name(iIndex, "DutyColour", szResult);
			arrGroupData[iIndex][g_hDutyColour] = strval(szResult);

			cache_get_value_name(iIndex, "Stock", szResult);
			arrGroupData[iIndex][g_iLockerStock] = strval(szResult);

			cache_get_value_name(iIndex, "CrateX", szResult);
			arrGroupData[iIndex][g_fCratePos][0] = floatstr(szResult);

			cache_get_value_name(iIndex, "CrateY", szResult);
			arrGroupData[iIndex][g_fCratePos][1] = floatstr(szResult);

			cache_get_value_name(iIndex, "CrateZ", szResult);
			arrGroupData[iIndex][g_fCratePos][2] = floatstr(szResult);

			cache_get_value_name(iIndex, "LockerCostType", szResult);
			arrGroupData[iIndex][g_iLockerCostType] = strval(szResult);

			cache_get_value_name(iIndex, "CratesOrder", szResult);
			arrGroupData[iIndex][g_iCratesOrder] = strval(szResult);

			cache_get_value_name(iIndex, "CrateIsland", szResult);
			arrGroupData[iIndex][g_iCrateIsland] = strval(szResult);
			
			cache_get_value_name(iIndex, "GarageX", szResult);
			arrGroupData[iIndex][g_fGaragePos][0] = floatstr(szResult);

			cache_get_value_name(iIndex, "GarageY", szResult);
			arrGroupData[iIndex][g_fGaragePos][1] = floatstr(szResult);

			cache_get_value_name(iIndex, "GarageZ", szResult);
			arrGroupData[iIndex][g_fGaragePos][2] = floatstr(szResult);

			while(i < MAX_GROUP_RANKS) {
				format(szResult, sizeof szResult, "Rank%i", i);
				cache_get_value_name(iIndex, szResult, arrGroupRanks[iIndex][i], GROUP_MAX_RANK_LEN);
				format(szResult, sizeof szResult, "Rank%iPay", i);
				cache_get_value_name(iIndex, szResult, szResult);
				arrGroupData[iIndex][g_iPaycheck][i] = strval(szResult);
				i++;
			}
			i = 0;

			while(i < MAX_GROUP_DIVS) {
				format(szResult, sizeof szResult, "Div%i", i + 1);
				cache_get_value_name(iIndex, szResult, arrGroupDivisions[iIndex][i], GROUP_MAX_DIV_LEN);
				i++;
			}
			i = 0;

			while(i < MAX_GROUP_WEAPONS) {
				format(szResult, sizeof szResult, "Gun%i", i + 1);
				cache_get_value_name(iIndex, szResult, szResult);
				arrGroupData[iIndex][g_iLockerGuns][i] = strval(szResult);
				format(szResult, sizeof szResult, "Cost%i", i + 1);
				cache_get_value_name(iIndex, szResult, szResult);
				arrGroupData[iIndex][g_iLockerCost][i] = strval(szResult);
				i++;
			}
			i = 0;

			if (arrGroupData[iIndex][g_szGroupName][0] && arrGroupData[iIndex][g_fCratePos][0] != 0.0)
			{
				format(szResult, sizeof szResult, "%s Crate Delivery Point\n{1FBDFF}/delivercrate", arrGroupData[iIndex][g_szGroupName]);
				arrGroupData[iIndex][g_tCrate3DLabel] = CreateDynamic3DTextLabel(szResult, arrGroupData[iIndex][g_hDutyColour] * 256 + 0xFF, arrGroupData[iIndex][g_fCratePos][0], arrGroupData[iIndex][g_fCratePos][1], arrGroupData[iIndex][g_fCratePos][2], 10.0, .testlos = 1, .streamdistance = 20.0);
			}
			iIndex++;
		}

		case GROUP_QUERY_INVITE: if(GetPVarType(iExtraID, "Group_Invited")) {
			if(!iRows) {

				i = GetPVarInt(iExtraID, "Group_Invited");
				iIndex = PlayerInfo[iExtraID][pMember];

				format(szResult, sizeof szResult, "%s %s da yeu cau mot loi moi tham gia nhom %s (su dung /chapnhan group de tham gia).", arrGroupRanks[iIndex][PlayerInfo[iExtraID][pRank]], GetPlayerNameEx(iExtraID), arrGroupData[iIndex][g_szGroupName]);
				SendClientMessageEx(i, COLOR_LIGHTBLUE, szResult);

				format(szResult, sizeof szResult, "Ban da yeu cau %s tham gia %s.", GetPlayerNameEx(i), arrGroupData[iIndex][g_szGroupName]);
				SendClientMessageEx(iExtraID, COLOR_LIGHTBLUE, szResult);
				SetPVarInt(i, "Group_Inviter", iExtraID);
			}
			else {
				SendClientMessage(iExtraID, COLOR_GREY, "Nguoi nay bi cam tham gia nhom.");
				DeletePVar(iExtraID, "Group_Invited");
			}
		}
		case GROUP_QUERY_ADDBAN: {
		    new string[128];
		    new otherplayer = GetPVarInt(iExtraID, "GroupBanningPlayer");
		    new group = GetPVarInt(iExtraID, "GroupBanningGroup");
			format(string, sizeof(string), "Ban da group-banned %s tu nhom %d.", GetPlayerNameEx(otherplayer), group);
			SendClientMessageEx(iExtraID, COLOR_WHITE, string);
			format(string, sizeof(string), "Ban da group-banned, boi %s.", GetPlayerNameEx(iExtraID));
			SendClientMessageEx(otherplayer, COLOR_LIGHTBLUE, string);
			format(string, sizeof(string), "Administrator %s da group-banned %s tu %s (%d)", GetPlayerNameEx(iExtraID), GetPlayerNameEx(otherplayer), arrGroupData[PlayerInfo[otherplayer][pMember]][g_szGroupName], PlayerInfo[otherplayer][pMember]);
			Log("logs/group.log", string);
			PlayerInfo[otherplayer][pMember] = INVALID_GROUP_ID;
			PlayerInfo[otherplayer][pLeader] = INVALID_GROUP_ID;
			PlayerInfo[otherplayer][pRank] = INVALID_RANK;
			PlayerInfo[otherplayer][pDuty] = 0;
			PlayerInfo[otherplayer][pDivision] = INVALID_DIVISION;
			new rand = random(sizeof(CIV));
			PlayerInfo[otherplayer][pModel] = CIV[rand];
			SetPlayerToTeamColor(otherplayer);
			SetPlayerSkin(otherplayer, CIV[rand]);
			OnPlayerStatsUpdate(otherplayer);
			DeletePVar(iExtraID, "GroupBanningPlayer");
			DeletePVar(iExtraID, "GroupBanningGroup");
		}

		case GROUP_QUERY_UNBAN: {
			new string[128];
			new otherplayer = GetPVarInt(iExtraID, "GroupUnBanningPlayer");
			new group = GetPVarInt(iExtraID, "GroupUnBanningGroup");
			if(mysql_affected_rows(MainPipeline))
			{
				format(string, sizeof(string), "Ban da group-unbanned %s tu nhom %s (%d).", GetPlayerNameEx(otherplayer), arrGroupData[group][g_szGroupName], group);
				SendClientMessageEx(iExtraID, COLOR_WHITE, string);
				format(string, sizeof(string), "Ban da group-unbanned %s, boi %s.", arrGroupData[group][g_szGroupName], GetPlayerNameEx(iExtraID));
				SendClientMessageEx(otherplayer, COLOR_LIGHTBLUE, string);
				format(string, sizeof(string), "Administrator %s da group-unbanned %s tu %s (%d)", GetPlayerNameEx(iExtraID), GetPlayerNameEx(otherplayer), arrGroupData[group][g_szGroupName], group);
				Log("logs/group.log", string);
			}
			else
			{
				format(string, sizeof(string), "da co van de say ra voi group-unbanning %s tu %s (%d)", GetPlayerNameEx(otherplayer), arrGroupData[group][g_szGroupName], group);
				SendClientMessageEx(iExtraID, COLOR_WHITE, string);
			}
			DeletePVar(iExtraID, "GroupUnBanningPlayer");
			DeletePVar(iExtraID, "GroupUnBanningGroup");
		}
		case GROUP_QUERY_UNCHECK: if(GetPVarType(iExtraID, "Group_Uninv")) {
			if(iRows) {
				cache_get_value_name(0, "Member", szResult, MAX_PLAYER_NAME);
				if(strval(szResult) == PlayerInfo[iExtraID][pMember]) {
					cache_get_value_name(0, "Rank", szResult);
					if(PlayerInfo[iExtraID][pRank] > strval(szResult) || PlayerInfo[iExtraID][pRank] >= Group_GetMaxRank(PlayerInfo[iExtraID][pMember])) {
						cache_get_value_name(0, "ID", szResult);
						format(szResult, sizeof szResult, "UPDATE `accounts` SET `Model` = "#NOOB_SKIN", `Member` = "#INVALID_GROUP_ID", `Rank` = "#INVALID_RANK", `Leader` = "#INVALID_GROUP_ID", `Division` = -1 WHERE `id` = %i", strval(szResult));
						mysql_pquery(MainPipeline, szResult, "Group_QueryFinish", "ii", GROUP_QUERY_UNINVITE, iExtraID);
					}
					else SendClientMessage(iExtraID, COLOR_GREY, "Ban khong the lam dieu nay voi nguoi co cap bac cao hon hoac tuong duong.");
				}
				else SendClientMessage(iExtraID, COLOR_GREY, "Nguoi do khong trong nhom cua ban.");

			}
			else {
				SendClientMessage(iExtraID, COLOR_GREY, "Tai khoan khong ton tai.");
				DeletePVar(iExtraID, "Group_Uninv");
			}
		}
		case GROUP_QUERY_UNINVITE: if(GetPVarType(iExtraID, "Group_Uninv")) {

			new
				szName[MAX_PLAYER_NAME],
				iGroupID = PlayerInfo[iExtraID][pMember];

			GetPVarString(iExtraID, "Group_Uninv", szName, sizeof szName);
			if(mysql_affected_rows(MainPipeline)) {

				i = PlayerInfo[iExtraID][pRank];
				format(szResult, sizeof szResult, "Ban da loai bo thanh cong %s ra khoi nhom cua ban", szName);
				SendClientMessage(iExtraID, COLOR_GREY, szResult);

				format(szResult, sizeof szResult, "%s %s (rank %i) da huy moi offline %s tu %s (%i).", arrGroupRanks[iGroupID][i], GetPlayerNameEx(iExtraID), i + 1, szName, arrGroupData[iGroupID][g_szGroupName], iGroupID + 1);
				Log("logs/group.log", szResult);
			}
			else {
				format(szResult, sizeof szResult, "Co mot loi da say ra khi co gang loai bo %s ra khoi nhom cua ban.", szName);
				SendClientMessage(iExtraID, COLOR_GREY, szResult);
			}
			DeletePVar(iExtraID, "Group_Uninv");
		}
	}
}

forward Jurisdiction_RehashFinish(iGroup);
public Jurisdiction_RehashFinish(iGroup) {

	new
		iFields,
		iRows,
		iIndex,
		szResult[128];

	cache_get_data(iRows, iFields);

	while(iIndex < iRows)
	{
	    new iGroupID;
		arrGroupData[iGroup][g_iJCount] = iRows;
		if(arrGroupData[iGroup][g_iJCount] > MAX_GROUP_JURISDICTIONS) {
			arrGroupData[iGroup][g_iJCount] = MAX_GROUP_JURISDICTIONS;
		}
		cache_get_value_name(iIndex, "GroupID", szResult, 24);
		iGroupID = strval(szResult);
		if(iGroupID == iGroup)
		{
			cache_get_value_name(iIndex, "id", szResult, 64);
			arrGroupJurisdictions[iGroup][iIndex][g_iJurisdictionSQLId] = strval(szResult);
			cache_get_value_name(iIndex, "AreaName", arrGroupJurisdictions[iGroup][iIndex][g_iAreaName], 64);
		}
		iIndex++;
	}
}

forward DynVeh_QueryFinish(iType, iExtraID);
public DynVeh_QueryFinish(iType, iExtraID) {

	new
		iFields,
		iRows,
		iIndex,
		i = 0,
		sqlid,
		szResult[128];

	cache_get_data(iRows, iFields);
	switch(iType) {
		case GV_QUERY_LOAD:
		{
		    format(szResult, sizeof(szResult), "UPDATE `groupvehs` SET `SpawnedID` = %d", INVALID_VEHICLE_ID);
			mysql_pquery(MainPipeline, szResult, "OnQueryFinish", "i", SENDDATA_THREAD);
			while((iIndex < iRows) && (iIndex < MAX_DYNAMIC_VEHICLES)) {
			    cache_get_value_name(iIndex, "id", szResult); sqlid = strval(szResult);
				if((sqlid >= MAX_DYNAMIC_VEHICLES)) {// Array bounds check. Use it.
					format(szResult, sizeof(szResult), "DELETE FROM `groupvehs` WHERE `id` = %d", sqlid);
					mysql_pquery(MainPipeline, szResult, "OnQueryFinish", "i", SENDDATA_THREAD);
					return printf("SQL ID %d exceeds Max Dynamic Vehicles", sqlid);
				}
				cache_get_value_name(iIndex, "gID", szResult); DynVehicleInfo[sqlid][gv_igID] = strval(szResult);
				cache_get_value_name(iIndex, "gDivID", szResult); DynVehicleInfo[sqlid][gv_igDivID] = strval(szResult);
				cache_get_value_name(iIndex, "fID", szResult); DynVehicleInfo[sqlid][gv_ifID] = strval(szResult);
				cache_get_value_name(iIndex, "rID", szResult); DynVehicleInfo[sqlid][gv_irID] = strval(szResult);
				cache_get_value_name(iIndex, "vModel", szResult); DynVehicleInfo[sqlid][gv_iModel] = strval(szResult);
                switch(DynVehicleInfo[sqlid][gv_iModel]) {
					case 538, 537, 449, 590, 569, 570: {
					    DynVehicleInfo[sqlid][gv_iModel] = 0;
					}
				}
				cache_get_value_name(iIndex, "vPlate", DynVehicleInfo[sqlid][gv_iPlate], 32);
				cache_get_value_name(iIndex, "vMaxHealth", szResult); DynVehicleInfo[sqlid][gv_fMaxHealth] = floatstr(szResult);
				cache_get_value_name(iIndex, "vType", szResult); DynVehicleInfo[sqlid][gv_iType] = strval(szResult);
				cache_get_value_name(iIndex, "vLoadMax", szResult); DynVehicleInfo[sqlid][gv_iLoadMax] = strval(szResult);
				if(DynVehicleInfo[sqlid][gv_iLoadMax] > 6) {
                    DynVehicleInfo[sqlid][gv_iLoadMax] = 6;
				}
				cache_get_value_name(iIndex, "vCol1", szResult); DynVehicleInfo[sqlid][gv_iCol1] = strval(szResult);
				cache_get_value_name(iIndex, "vCol2", szResult); DynVehicleInfo[sqlid][gv_iCol2] = strval(szResult);
				cache_get_value_name(iIndex, "vX", szResult); DynVehicleInfo[sqlid][gv_fX] = floatstr(szResult);
				cache_get_value_name(iIndex, "vY", szResult); DynVehicleInfo[sqlid][gv_fY] = floatstr(szResult);
				cache_get_value_name(iIndex, "vZ", szResult); DynVehicleInfo[sqlid][gv_fZ] = floatstr(szResult);
				cache_get_value_name(iIndex, "vVW", szResult); DynVehicleInfo[sqlid][gv_iVW] = strval(szResult);
				cache_get_value_name(iIndex, "vInt", szResult); DynVehicleInfo[sqlid][gv_iInt] = strval(szResult);
				cache_get_value_name(iIndex, "vDisabled", szResult); DynVehicleInfo[sqlid][gv_iDisabled] = strval(szResult);
				cache_get_value_name(iIndex, "vRotZ", szResult); DynVehicleInfo[sqlid][gv_fRotZ] = floatstr(szResult);
				cache_get_value_name(iIndex, "vUpkeep", szResult); DynVehicleInfo[sqlid][gv_iUpkeep] = strval(szResult);
				i = 1;
				while(i <= MAX_DV_OBJECTS) {
					format(szResult, sizeof szResult, "vAttachedObjectModel%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_iAttachedObjectModel][i-1] = strval(szResult);
					format(szResult, sizeof szResult, "vObjectX%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_fObjectX][i-1] = floatstr(szResult);
					format(szResult, sizeof szResult, "vObjectY%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_fObjectY][i-1] = floatstr(szResult);
					format(szResult, sizeof szResult, "vObjectZ%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_fObjectZ][i-1] = floatstr(szResult);
					format(szResult, sizeof szResult, "vObjectRX%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_fObjectRX][i-1] = floatstr(szResult);
					format(szResult, sizeof szResult, "vObjectRY%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_fObjectRY][i-1] = floatstr(szResult);
					format(szResult, sizeof szResult, "vObjectRZ%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_fObjectRZ][i-1] = floatstr(szResult);
					i++;
				}
				i = 0;
				while(i < MAX_DV_MODS) {
					format(szResult, sizeof szResult, "vMod%i", i);
					cache_get_value_name(iIndex, szResult, szResult); DynVehicleInfo[sqlid][gv_iMod][i++] = strval(szResult);
				}
				
				if(400 < DynVehicleInfo[sqlid][gv_iModel] < 612) {
					if(!IsWeaponizedVehicle(DynVehicleInfo[sqlid][gv_iModel])) {
						DynVeh_Spawn(iIndex);
						//printf("[DynVeh] Loaded Dynamic Vehicle %i.", iIndex);
						for(i = 0; i != MAX_DV_OBJECTS; i++)
						{
							if(DynVehicleInfo[sqlid][gv_iAttachedObjectModel][i] == 0 || DynVehicleInfo[sqlid][gv_iAttachedObjectModel][i] == INVALID_OBJECT_ID) {
								DynVehicleInfo[sqlid][gv_iAttachedObjectID][i] = INVALID_OBJECT_ID;
								DynVehicleInfo[sqlid][gv_iAttachedObjectModel][i] = INVALID_OBJECT_ID;
							}
						}
					} else {
						DynVehicleInfo[sqlid][gv_iSpawnedID] = INVALID_VEHICLE_ID;
					}	
				}
				iIndex++;
			}
		}
	}
	return 1;
}

forward LoadBusinessesSaless();
public LoadBusinessesSaless() {

	new
		iFields,
		iRows,
		iIndex,
		szResult[128];

	cache_get_data(iRows, iFields);

	while((iIndex < iRows)) {
		cache_get_value_name(iIndex, "bID", szResult); BusinessSales[iIndex][bID] = strval(szResult);
		cache_get_value_name(iIndex, "BusinessID", szResult); BusinessSales[iIndex][bBusinessID] = strval(szResult);
		cache_get_value_name(iIndex, "Text", BusinessSales[iIndex][bText], 128);
		cache_get_value_name(iIndex, "Price", szResult); BusinessSales[iIndex][bPrice] = strval(szResult);
		cache_get_value_name(iIndex, "Available", szResult); BusinessSales[iIndex][bAvailable] = strval(szResult);
		cache_get_value_name(iIndex, "Purchased", szResult); BusinessSales[iIndex][bPurchased] = strval(szResult);
		cache_get_value_name(iIndex, "Type", szResult); BusinessSales[iIndex][bType] = strval(szResult);
		iIndex++;
	}
	return 1;
}

forward AuctionLoadQuery();
public AuctionLoadQuery() {

	new
		iFields,
		iRows,
		iIndex,
		szResult[128];

	cache_get_data(iRows, iFields);

	while((iIndex < iRows)) {
		cache_get_value_name(iIndex, "BiddingFor", Auctions[iIndex][BiddingFor], 64);
		cache_get_value_name(iIndex, "InProgress", szResult); Auctions[iIndex][InProgress] = strval(szResult);
		cache_get_value_name(iIndex, "Bid", szResult); Auctions[iIndex][Bid] = strval(szResult);
		cache_get_value_name(iIndex, "Bidder", szResult); Auctions[iIndex][Bidder] = strval(szResult);
		cache_get_value_name(iIndex, "Expires", szResult); Auctions[iIndex][Expires] = strval(szResult);
		cache_get_value_name(iIndex, "Wining", Auctions[iIndex][Wining], MAX_PLAYER_NAME);
		cache_get_value_name(iIndex, "Increment", szResult); Auctions[iIndex][Increment] = strval(szResult);
		if(Auctions[iIndex][InProgress] == 1 && Auctions[iIndex][Expires] != 0)
		{
		    Auctions[iIndex][Timer] = SetTimerEx("EndAuction", 60000, true, "i", iIndex);
		    printf("[auction - %i - started] %s, %d, %d, %d, %d, %s, %d",iIndex, Auctions[iIndex][BiddingFor],Auctions[iIndex][InProgress],Auctions[iIndex][Bid],Auctions[iIndex][Bidder],Auctions[iIndex][Expires],Auctions[iIndex][Wining],Auctions[iIndex][Increment]);
		}
		iIndex++;
	}
	return 1;
}

forward PlantsLoadQuery();
public PlantsLoadQuery() {

	new
		iFields,
		iRows,
		iIndex,
		szResult[128];

	cache_get_data(iRows, iFields);

	while((iIndex < iRows)) {
		cache_get_value_name(iIndex, "Owner", szResult); Plants[iIndex][pOwner] = strval(szResult);
		cache_get_value_name(iIndex, "Object", szResult); Plants[iIndex][pObject] = strval(szResult);
		cache_get_value_name(iIndex, "PlantType", szResult); Plants[iIndex][pPlantType] = strval(szResult);
		cache_get_value_name(iIndex, "PositionX", szResult); Plants[iIndex][pPos][0] = floatstr(szResult);
		cache_get_value_name(iIndex, "PositionY", szResult); Plants[iIndex][pPos][1] = floatstr(szResult);
		cache_get_value_name(iIndex, "PositionZ", szResult); Plants[iIndex][pPos][2] = floatstr(szResult);
		cache_get_value_name(iIndex, "Virtual", szResult); Plants[iIndex][pVirtual] = strval(szResult);
		cache_get_value_name(iIndex, "Interior", szResult); Plants[iIndex][pInterior] = strval(szResult);
		cache_get_value_name(iIndex, "Growth", szResult); Plants[iIndex][pGrowth] = strval(szResult);
		cache_get_value_name(iIndex, "Expires", szResult); Plants[iIndex][pExpires] = strval(szResult);
		cache_get_value_name(iIndex, "DrugsSkill", szResult); Plants[iIndex][pDrugsSkill] = strval(szResult);

		if(Plants[iIndex][pOwner] != 0) {
		    Plants[iIndex][pObjectSpawned] = CreateDynamicObject(Plants[iIndex][pObject], Plants[iIndex][pPos][0], Plants[iIndex][pPos][1], Plants[iIndex][pPos][2], 0.0, 0.0, 0.0, Plants[iIndex][pVirtual], Plants[iIndex][pInterior]);
		}
		iIndex++;
	}
	if(iIndex > 0) printf("[LoadPlants] Successfully loaded %d plants", iIndex);
	else printf("[LoadPlants] Error: Failed to load any plants!");
	return 1;
}

forward BusinessesLoadQueryFinish();
public BusinessesLoadQueryFinish()
{

	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);
	while(i < rows)
	{
		cache_get_value_name(i, "Name", Businesses[i][bName], MAX_BUSINESS_NAME);
		cache_get_value_name(i, "OwnerID", tmp); Businesses[i][bOwner] = strval(tmp);
		cache_get_value_name(i, "Username", Businesses[i][bOwnerName], MAX_PLAYER_NAME);
		cache_get_value_name(i, "Type", tmp); Businesses[i][bType] = strval(tmp);
		cache_get_value_name(i, "Value", tmp); Businesses[i][bValue] = strval(tmp);
		cache_get_value_name(i, "Status", tmp); Businesses[i][bStatus] = strval(tmp);
		cache_get_value_name(i, "Level", tmp); Businesses[i][bLevel] = strval(tmp);
		cache_get_value_name(i, "LevelProgress", tmp); Businesses[i][bLevelProgress] = strval(tmp);
		cache_get_value_name(i, "SafeBalance", tmp); Businesses[i][bSafeBalance] = strval(tmp);
		cache_get_value_name(i, "Inventory", tmp); Businesses[i][bInventory] = strval(tmp);
		cache_get_value_name(i, "InventoryCapacity", tmp); Businesses[i][bInventoryCapacity] = strval(tmp);
		cache_get_value_name(i, "AutoSale", tmp); Businesses[i][bAutoSale] = strval(tmp);
		cache_get_value_name(i, "TotalSales", tmp); Businesses[i][bTotalSales] = strval(tmp);
		cache_get_value_name(i, "ExteriorX", tmp); Businesses[i][bExtPos][0] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorY", tmp); Businesses[i][bExtPos][1] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorZ", tmp); Businesses[i][bExtPos][2] = floatstr(tmp);
		cache_get_value_name(i, "ExteriorA", tmp); Businesses[i][bExtPos][3] = floatstr(tmp);
		cache_get_value_name(i, "InteriorX", tmp); Businesses[i][bIntPos][0] = floatstr(tmp);
		cache_get_value_name(i, "InteriorY", tmp); Businesses[i][bIntPos][1] = floatstr(tmp);
		cache_get_value_name(i, "InteriorZ", tmp); Businesses[i][bIntPos][2] = floatstr(tmp);
		cache_get_value_name(i, "InteriorA", tmp); Businesses[i][bIntPos][3] = floatstr(tmp);
		cache_get_value_name(i, "Interior", tmp); Businesses[i][bInt] = strval(tmp);
		cache_get_value_name(i, "SupplyPointX", tmp); Businesses[i][bSupplyPos][0] = floatstr(tmp);
		cache_get_value_name(i, "SupplyPointY", tmp); Businesses[i][bSupplyPos][1] = floatstr(tmp);
		cache_get_value_name(i, "SupplyPointZ", tmp); Businesses[i][bSupplyPos][2] = floatstr(tmp);
		cache_get_value_name(i, "GasPrice", tmp); Businesses[i][bGasPrice] = floatstr(tmp);
		cache_get_value_name(i, "OrderBy", Businesses[i][bOrderBy], MAX_PLAYER_NAME);
		cache_get_value_name(i, "OrderState", tmp); Businesses[i][bOrderState] = strval(tmp);
		cache_get_value_name(i, "OrderAmount", tmp); Businesses[i][bOrderAmount] = strval(tmp);
		cache_get_value_name(i, "OrderDate", Businesses[i][bOrderDate], 30);
		cache_get_value_name(i, "CustomExterior", tmp); Businesses[i][bCustomExterior] = strval(tmp);
		cache_get_value_name(i, "CustomInterior", tmp); Businesses[i][bCustomInterior] = strval(tmp);
		cache_get_value_name(i, "Grade", tmp); Businesses[i][bGrade] = strval(tmp);
		cache_get_value_name(i, "CustomVW", tmp); Businesses[i][bVW] = strval(tmp);
		cache_get_value_name(i, "Pay", tmp); Businesses[i][bAutoPay] = strval(tmp);
		cache_get_value_name(i, "MinInviteRank", tmp); Businesses[i][bMinInviteRank] = strval(tmp);
		cache_get_value_name(i, "MinSupplyRank", tmp); Businesses[i][bMinSupplyRank] = strval(tmp);
		cache_get_value_name(i, "MinGiveRankRank", tmp); Businesses[i][bMinGiveRankRank] = strval(tmp);
		cache_get_value_name(i, "MinSafeRank", tmp); Businesses[i][bMinSafeRank] = strval(tmp);
		cache_get_value_name(i, "Months", tmp); Businesses[i][bMonths] = strval(tmp);
		cache_get_value_name(i, "GymEntryFee", tmp); Businesses[i][bGymEntryFee] = strval(tmp);
		cache_get_value_name(i, "GymType", tmp); Businesses[i][bGymType] = strval(tmp);

		if (Businesses[i][bOrderState] == 2) {
		    Businesses[i][bOrderState] = 1;
		}

		RefreshBusinessPickup(i);

		for (new j; j <= 5; j++)
		{
		    new col[9];
			format(col, sizeof(col), "Rank%dPay", j);
			cache_get_value_name(i, col, tmp);
			Businesses[i][bRankPay][j] = strval(tmp);
		}

		if (Businesses[i][bType] == BUSINESS_TYPE_GASSTATION)
		{
			for (new j, column[17]; j < MAX_BUSINESS_GAS_PUMPS; j++)
			{
			    format(column, sizeof(column), "GasPump%dPosX", j + 1);
				cache_get_value_name(i, column, tmp); Businesses[i][GasPumpPosX][j] = floatstr(tmp);
			    format(column, sizeof(column), "GasPump%dPosY", j + 1);
				cache_get_value_name(i, column, tmp); Businesses[i][GasPumpPosY][j] = floatstr(tmp);
			    format(column, sizeof(column), "GasPump%dPosZ", j + 1);
				cache_get_value_name(i, column, tmp); Businesses[i][GasPumpPosZ][j] = floatstr(tmp);
			    format(column, sizeof(column), "GasPump%dAngle", j + 1);
				cache_get_value_name(i, column, tmp); Businesses[i][GasPumpAngle][j] = floatstr(tmp);
			    format(column, sizeof(column), "GasPump%dCapacity", j + 1);
				cache_get_value_name(i, column, tmp); Businesses[i][GasPumpCapacity][j] = floatstr(tmp);
			    format(column, sizeof(column), "GasPump%dGas", j + 1);
				cache_get_value_name(i, column, tmp); Businesses[i][GasPumpGallons][j] = floatstr(tmp);
				CreateDynamicGasPump(_, i, j);

				for (new z; z <= 17; z++)
				{
			    	new col[12];
					format(col, sizeof(col), "Item%dPrice", z + 1);
					cache_get_value_name(i, col, tmp);
					Businesses[i][bItemPrices][z] = strval(tmp);
				}
			}
		}
		else if (Businesses[i][bType] == BUSINESS_TYPE_NEWCARDEALERSHIP || Businesses[i][bType] == BUSINESS_TYPE_OLDCARDEALERSHIP)
		{
			for (new j, column[16], label[50]; j < MAX_BUSINESS_DEALERSHIP_VEHICLES; j++)
			{

			    format(column, sizeof(column), "Car%dModelId", j);
				cache_get_value_name(i, column, tmp); Businesses[i][bModel][j] = strval(tmp);
			    format(column, sizeof(column), "Car%dPosX", j);
				cache_get_value_name(i, column, tmp); Businesses[i][bParkPosX][j] = floatstr(tmp);
			    format(column, sizeof(column), "Car%dPosY", j);
				cache_get_value_name(i, column, tmp); Businesses[i][bParkPosY][j] = floatstr(tmp);
			    format(column, sizeof(column), "Car%dPosZ", j);
				cache_get_value_name(i, column, tmp); Businesses[i][bParkPosZ][j] = floatstr(tmp);
			    format(column, sizeof(column), "Car%dPosAngle", j);
				cache_get_value_name(i, column, tmp); Businesses[i][bParkAngle][j] = floatstr(tmp);
			    format(column, sizeof(column), "Car%dPrice", j);
				cache_get_value_name(i, column, tmp); Businesses[i][bPrice][j] = strval(tmp);

				cache_get_value_name(i, "PurchaseX", tmp); Businesses[i][bPurchaseX][j] = strval(tmp);
				cache_get_value_name(i, "PurchaseY", tmp); Businesses[i][bPurchaseY][j] = strval(tmp);
				cache_get_value_name(i, "PurchaseZ", tmp); Businesses[i][bPurchaseZ][j] = strval(tmp);
				cache_get_value_name(i, "PurchaseAngle", tmp); Businesses[i][bPurchaseAngle][j] = strval(tmp);

                if(400 < Businesses[i][bModel][j] < 612) {
			 		Businesses[i][bVehID][j] = CreateVehicle(Businesses[i][bModel][j], Businesses[i][bParkPosX][j], Businesses[i][bParkPosY][j], Businesses[i][bParkPosZ][j], Businesses[i][bParkAngle][j], Businesses[i][bColor1][j], Businesses[i][bColor2][j], 10);
     				format(label, sizeof(label), "%s Dang ban | Gia ban: $%s", GetVehicleName(Businesses[i][bVehID][j]), number_format(Businesses[i][bPrice][j]));
					Businesses[i][bVehicleLabel][j] = CreateDynamic3DTextLabel(label,COLOR_LIGHTBLUE,Businesses[i][bParkPosX][j], Businesses[i][bParkPosY][j], Businesses[i][bParkPosZ][j],8.0,INVALID_PLAYER_ID, Businesses[i][bVehID][j]);
				}
			}
		}
		else
		{
			for (new j; j <= 17; j++)
			{
			    new col[12];
				format(col, sizeof(col), "Item%dPrice", j + 1);
				cache_get_value_name(i, col, tmp);
				Businesses[i][bItemPrices][j] = strval(tmp);
			}
		}

		Businesses[i][bGymBoxingArena1][0] = INVALID_PLAYER_ID;
		Businesses[i][bGymBoxingArena1][1] = INVALID_PLAYER_ID;
		Businesses[i][bGymBoxingArena2][0] = INVALID_PLAYER_ID;
		Businesses[i][bGymBoxingArena2][1] = INVALID_PLAYER_ID;

		for (new it = 0; it < 10; ++it)
		{
			Businesses[i][bGymBikePlayers][it] = INVALID_PLAYER_ID;
			Businesses[i][bGymBikeVehicles][it] = INVALID_VEHICLE_ID;
		}

		i++;
	}
	if(i > 0) printf("[LoadBusinesses] %d businesses rehashed/loaded.", i);
	else printf("[LoadBusinesses] Failed to load any businesses.");
}

forward ReturnMoney(index);
public ReturnMoney(index)
{
	if(IsPlayerConnected(index))
	{
	    new
    		AuctionItem = GetPVarInt(index, "AuctionItem");

		new money[15], money2, string[128];
		new rows, fields;
		cache_get_data(rows, fields);
		if(rows)
		{
   			cache_get_value_name(0, "Money", money); money2 = strval(money);

   			format(string, sizeof(string), "UPDATE `accounts` SET `Money` = %d WHERE `id` = '%d'", money2+Auctions[AuctionItem][Bid], Auctions[AuctionItem][Bidder]);
			mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);

			format(string, sizeof(string), "So tien $%d (Truoc: %i | Sau: %i) da duoc tra lai (id: %i) de duoc tra gia cao hon", Auctions[AuctionItem][Bid], money2,Auctions[AuctionItem][Bid]+money2,  Auctions[AuctionItem][Bidder]);
			Log("logs/auction.log", string);

            GivePlayerCash(index, -GetPVarInt(index, "BidPlaced"));
			Auctions[AuctionItem][Bid] = GetPVarInt(index, "BidPlaced");
			Auctions[AuctionItem][Bidder] = GetPlayerSQLId(index);
			strcpy(Auctions[AuctionItem][Wining], GetPlayerNameExt(index), MAX_PLAYER_NAME);

			format(string, sizeof(string), "Ban da dat mot gia thau %i tren %s.", GetPVarInt(index, "BidPlaced"), Auctions[AuctionItem][BiddingFor]);
			SendClientMessageEx(index, COLOR_WHITE, string);

			format(string, sizeof(string), "%s (IP:%s) da dat mot gia thau %i tren %s(%i)", GetPlayerNameEx(index), GetPlayerIpEx(index), GetPVarInt(index, "BidPlaced"), Auctions[AuctionItem][BiddingFor], AuctionItem);
			Log("logs/auction.log", string);

			SaveAuction(AuctionItem);

			DeletePVar(index, "BidPlaced");
			DeletePVar(index, "AuctionItem");
		}
		else
		{
			printf("[AuctionError] id: %i | money %i", Auctions[AuctionItem][Bidder],  Auctions[AuctionItem][Bid]);
		}
	}
	return 1;
}

forward OnQueryCreateVehicle(playerid, playervehicleid);
public OnQueryCreateVehicle(playerid, playervehicleid)
{
	PlayerVehicleInfo[playerid][playervehicleid][pvSlotId] = mysql_insert_id(MainPipeline);
	printf("VNumber: %d", PlayerVehicleInfo[playerid][playervehicleid][pvSlotId]);

	new string[128];
    format(string, sizeof(string), "UPDATE `vehicles` SET `pvModelId` = %d WHERE `id` = %d", PlayerVehicleInfo[playerid][playervehicleid][pvModelId], PlayerVehicleInfo[playerid][playervehicleid][pvSlotId]);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
	
	g_mysql_SaveVehicle(playerid, playervehicleid);
}

forward CheckAccounts(playerid);
public CheckAccounts(playerid)
{
	if(IsPlayerConnected(playerid))
	{
		new szString[128];
		new rows, fields;
		cache_get_data(rows, fields);
		if(rows)
		{
		    format(szString, sizeof(szString), "{AA3333}AdmWarning{FFFF00}: Moderator %s da dang nhap vao may chu khi su dung tool hack s0beit.", GetPlayerNameEx(playerid));
   			ABroadCast(COLOR_YELLOW, szString, 2);

    		format(szString, sizeof(szString), "Admin %s (IP: %s) da dang nhap vao may chu khi su dung tool hack s0beit.", GetPlayerNameEx(playerid), GetPlayerIpEx(playerid));
     		Log("logs/sobeit.log", szString);
       		sobeitCheckvar[playerid] = 1;
     		sobeitCheckIsDone[playerid] = 1;
     		IsPlayerFrozen[playerid] = 0;
		}
		else
		{
		    format(szString, sizeof(szString), "INSERT INTO `sobeitkicks` (sqlID, Kicks) VALUES (%d, 1) ON DUPLICATE KEY UPDATE Kicks = Kicks + 1", GetPlayerSQLId(playerid));
			mysql_pquery(MainPipeline, szString, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);

		    SendClientMessageEx(playerid, COLOR_RED, "Tool hack 's0beit' khong duoc phep su  dung, vui long go bo no ra khoi game");
   			format(szString, sizeof(szString), "%s (IP: %s) da dang nhap vao may chu khi su dung tool hack s0beit.", GetPlayerNameEx(playerid), GetPlayerIpEx(playerid));
   			Log("logs/sobeit.log", szString);
            sobeitCheckvar[playerid] = 1;
     		sobeitCheckIsDone[playerid] = 1;
     		IsPlayerFrozen[playerid] = 0;
    		SetTimerEx("KickEx", 1000, false, "i", playerid);
		}
	}
	return 1;
}

forward ReferralSecurity(playerid);
public ReferralSecurity(playerid)
{
    new newrows, newfields, newresult[16], currentIP[16], szString[128];
	GetPlayerIp(playerid, currentIP, sizeof(currentIP));
	cache_get_data(newrows, newfields);

	if(newrows > 0)
	{
 		cache_get_value_name(0, "IP", newresult);

   		if(!strcmp(newresult, currentIP, true))
	    {
	        format(szString, sizeof(szString), "Nobody");
			strmid(PlayerInfo[playerid][pReferredBy], szString, 0, strlen(szString), MAX_PLAYER_NAME);
            ShowPlayerDialog(playerid, REGISTERREF, DIALOG_STYLE_INPUT, "{FF0000}Error", "This person has the same IP as you.\nPlease choose another player that is not on your network.\n\nIf you haven't been referred, press 'Skip'.\n\nExample: FirstName_LastName (20 Characters Max)", "Enter", "Skip");
    	}
    	else {
    	    format(szString, sizeof(szString), "[Referral] (New Account: %s (IP:%s)) has been referred by (Referred Account: %s (IP:%s))", GetPlayerNameEx(playerid), currentIP, PlayerInfo[playerid][pReferredBy], newresult);
    	    Log("logs/referral.log", szString);
            mysql_free_result(MainPipeline);
			RegistrationStep[playerid] = 3;
			SetPlayerVirtualWorld(playerid, 0);
			ClearChatbox(playerid);
			TutStep[playerid] = 24;
			TextDrawShowForPlayer(playerid, txtNationSelHelper);
			TextDrawShowForPlayer(playerid, txtNationSelMain);
			PlayerNationSelection[playerid] = -1;
			SetPlayerVirtualWorld(playerid, 0);
			SetPlayerInterior(playerid, 0);
			Streamer_UpdateEx(playerid,1716.1129,-1880.0715,22.0264);
			SetPlayerPos(playerid,1716.1129,-1880.0715,-10.0);
			SetPlayerCameraPos(playerid,1755.0413,-1824.8710,20.2100);
			SetPlayerCameraLookAt(playerid,1716.1129,-1880.0715,22.0264);

			//Streamer_UpdateEx(playerid, 1607.0160,-1510.8218,207.4438);
			//SetPlayerPos(playerid, 1607.0160,-1510.8218,-10.0);
			//SetPlayerCameraPos(playerid, 1850.1813,-1765.7552,81.9271);
			//SetPlayerCameraLookAt(playerid, 1607.0160,-1510.8218,207.4438);
		}
	}
	return 1;
}

forward OnStaffAccountCheck(playerid);
public OnStaffAccountCheck(playerid)
{
	new string[156], rows, fields;
	cache_get_data(rows, fields);
	if(rows > 0)
	{
		format(string, sizeof(string), "{AA3333}AdmWarning{FFFF00}: %s (ID: %d) was punished and has a staff account associated with their IP address.", GetPlayerNameEx(playerid), playerid);
		ABroadCast(COLOR_YELLOW, string, 2);
	}
	return 1;
}

// Relay For Life

stock LoadRelayForLifeTeam(teamid)
{
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `rflteams` WHERE `id`=%d", teamid);
	mysql_pquery(MainPipeline, string, "OnLoadRFLTeam", "i", mapiconid);
}

stock LoadRelayForLifeTeams()
{
	printf("[LoadRelayForLifeTeams] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `rflteams`", "OnLoadRFLTeams", "");
}

forward OnLoadRFLTeams();
public OnLoadRFLTeams()
{
	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);

	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp);  RFLInfo[i][RFLsqlid] = strval(tmp);
		cache_get_value_name(i, "name", RFLInfo[i][RFLname]);
		cache_get_value_name(i, "leader", RFLInfo[i][RFLleader]);
		cache_get_value_name(i, "used", tmp); RFLInfo[i][RFLused] = strval(tmp);
		cache_get_value_name(i, "members", tmp); RFLInfo[i][RFLmembers] = strval(tmp);
		cache_get_value_name(i, "laps", tmp); RFLInfo[i][RFLlaps] = strval(tmp);
		i++;
	}
	if(i > 0) printf("[LoadRelayForLifeTeams] %d teams loaded.", i);
	else printf("[LoadRelayForLifeTeams] Failed to load any teams.");
	return 1;
}

forward OnLoadRFLTeam(index);
public OnLoadRFLTeam(index)
{
	new rows, fields, tmp[128];
	cache_get_data(rows, fields);

	for(new row; row < rows; row++)
	{
		cache_get_value_name(row, "id", tmp);  RFLInfo[index][RFLsqlid] = strval(tmp);
		cache_get_value_name(row, "name", RFLInfo[index][RFLname]);
		cache_get_value_name(row, "leader", RFLInfo[index][RFLleader]);
		cache_get_value_name(row, "used", tmp); RFLInfo[index][RFLused] = strval(tmp);
		cache_get_value_name(row, "members", tmp); RFLInfo[index][RFLmembers] = strval(tmp);
		cache_get_value_name(row, "laps", tmp); RFLInfo[index][RFLlaps] = strval(tmp);
	}
}

stock SaveRelayForLifeTeam(teamid)
{
	new string[248];
	format(string, sizeof(string), "UPDATE `rflteams` SET `name`='%s', `leader`='%s', `used`=%d, `members`=%d, `laps`=%d WHERE id=%d",
		RFLInfo[teamid][RFLname],
		RFLInfo[teamid][RFLleader],
		RFLInfo[teamid][RFLused],
		RFLInfo[teamid][RFLmembers],
		RFLInfo[teamid][RFLlaps],
		RFLInfo[teamid][RFLsqlid]
	);
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}

stock SaveRelayForLifeTeams()
{
	for(new i = 0; i < MAX_RFLTEAMS; i++)
	{
		SaveRelayForLifeTeam(i);
	}
}

forward OnRFLPScore(index, id);
public OnRFLPScore(index, id)
{
	new i, rows, fields, string[1500], tmp[7], name[25], leader[25], laps;
	cache_get_data(rows, fields);
	switch(id) {
		case 1: {
			while(i < rows)
			{
				cache_get_value_name(i, "name", name);
				cache_get_value_name(i, "leader", leader);
				cache_get_value_name(i, "laps", tmp); laps = strval(tmp);
				format(string, sizeof(string), "%s\nTeam: %s | Leader: %s | Laps: %d",string, name, leader, laps);
				i++;
			}
			if(i < 1) {
				DeletePVar(index, "rflTemp");
				SendClientMessageEx(index, COLOR_GREY, "Khong tim thay team.");
				return 1;
			}
			if(i >= 15) {
				SetPVarInt(index, "rflTemp", GetPVarInt(index, "rflTemp") + i);
				ShowPlayerDialog(index, DIALOG_RFL_TEAMS, DIALOG_STYLE_LIST, "Relay For Life Teams", string, "Tiep", "Dong");
				return 1;
			}
			else
			{
				DeletePVar(index, "rflTemp");
				ShowPlayerDialog(index, DIALOG_RFL_TEAMS, DIALOG_STYLE_LIST, "Relay For Life Teams", string, "Dong", "");
				return 1;
			}
		}
		case 2: {
			while(i < rows)
			{
				cache_get_value_name(i, "Username", name);
				cache_get_value_name(i, "RacePlayerLaps", tmp); laps = strval(tmp);
				format(string, sizeof(string), "%s\n%s | Laps: %d",string, name, laps);
				i++;
			}
			if(i > 0) {
				ShowPlayerDialog(index, DIALOG_RFL_PLAYERS, DIALOG_STYLE_LIST, "Relay For Life Player Top 25", string, "Dong", "");
			}
			else {
				SendClientMessageEx(index, COLOR_GREY, "No player has run any laps yet.");
			}
		}
	}
	return 1;
}

forward OnCheckRFLName(playerid, Player);
public OnCheckRFLName(playerid, Player)
{
	if(IsPlayerConnected(Player))
	{
		if(mysql_affected_rows(MainPipeline))
		{
			SendClientMessageEx(Player, COLOR_YELLOW, "Ten team da duoc thay doi.");
			SendClientMessageEx(playerid, COLOR_YELLOW, "Ten team da duoc thay doi.");
		}
		else
		{
			new newname[25], string[128];
			GetPVarString(Player, "NewRFLName", newname, sizeof(newname));
			format(RFLInfo[PlayerInfo[Player][pRFLTeam]][RFLname], 25, "%s", newname);
			format(string, sizeof(string), "* Ten team cua ban da duoc thay doi thanh %s.", newname);
			SendClientMessageEx(Player, COLOR_YELLOW, string);
			format(string, sizeof(string), "* Ban da thay doi %s's ten team thanh %s.", GetPlayerNameEx(playerid), newname);
			SendClientMessageEx(playerid, COLOR_YELLOW, string);
			format(string, sizeof(string), "%s da chap nhan %s's yeu cau doi ten team",GetPlayerNameEx(playerid),GetPlayerNameEx(Player));
			ABroadCast(COLOR_YELLOW, string, 3);			
			SaveRelayForLifeTeam(PlayerInfo[Player][pRFLTeam]);
			foreach(new i: Player) {
				if( GetPVarInt( i, "EventToken" ) == 1 ) {
					if( EventKernel[ EventStatus ] == 1 || EventKernel[ EventStatus ] == 2 ) {
						if(EventKernel[EventType] == 3) {
							if(PlayerInfo[i][pRFLTeam] == PlayerInfo[Player][pRFLTeam]) {
								format(string, sizeof(string), "Team: %s", newname);
								UpdateDynamic3DTextLabelText(RFLTeamN3D[i], 0x008080FF, string);
							}		
						}
					}
				}
			}	
		}	
	}
	else
	{
		SendClientMessageEx(playerid, COLOR_GREY, "Thanh vien nay da dang suat.");
	}
	DeletePVar(Player, "RFLNameRequest");
	DeletePVar(playerid, "RFLNameChange");
	DeletePVar(Player, "NewRFLName");	
	return 1;
}

stock SavePoint(pid)
{
	new szQuery[2048];
	
	format(szQuery, sizeof(szQuery), "UPDATE `points` SET \
		`posx` = '%f', \
		`posy` = '%f', \
 		`posz` = '%f', \
		`vw` = '%d', \
		`type` = '%d', \
		`vulnerable` = '%d', \
		`matpoint` = '%d', \
		`owner` = '%s', \
		`cappername` = '%s', \
		`name` = '%s' WHERE `id` = %d",
		Points[pid][Pointx],
		Points[pid][Pointy],
		Points[pid][Pointz],
		Points[pid][pointVW],
		Points[pid][Type],
		Points[pid][Vulnerable],
		Points[pid][MatPoint],
		g_mysql_ReturnEscaped(Points[pid][Owner], MainPipeline),
		g_mysql_ReturnEscaped(Points[pid][CapperName], MainPipeline),
		g_mysql_ReturnEscaped(Points[pid][Name], MainPipeline),
		pid+1
	);	
		
	mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "i", SENDDATA_THREAD);	
}		

forward OnLoadPoints();
public OnLoadPoints()
{
	new fields, rows, index, result[128];
	cache_get_data(rows, fields);

	while((index < rows))
	{
		cache_get_value_name(index, "id", result); Points[index][pointID] = strval(result);
		cache_get_value_name(index, "posx", result); Points[index][Pointx] = floatstr(result);
		cache_get_value_name(index, "posy", result); Points[index][Pointy] = floatstr(result);
		cache_get_value_name(index, "posz", result); Points[index][Pointz] = floatstr(result);
		cache_get_value_name(index, "vw", result); Points[index][pointVW] = strval(result);
		cache_get_value_name(index, "type", result); Points[index][Type] = strval(result);
		cache_get_value_name(index, "vulnerable", result); Points[index][Vulnerable] = strval(result);
		cache_get_value_name(index, "matpoint", result); Points[index][MatPoint] = strval(result);
		cache_get_value_name(index, "owner", Points[index][Owner], 128);
		cache_get_value_name(index, "cappername", Points[index][CapperName], MAX_PLAYER_NAME);
		cache_get_value_name(index, "name", Points[index][Name], 128);
		cache_get_value_name(index, "captime", result); Points[index][CapTime] = strval(result);
		cache_get_value_name(index, "capfam", result); Points[index][CapFam] = strval(result);
		cache_get_value_name(index, "capname", Points[index][CapName], MAX_PLAYER_NAME);
		
		Points[index][CaptureTimerEx2] = -1;
		Points[index][ClaimerId] = INVALID_PLAYER_ID;
		Points[index][PointPickupID] = CreateDynamicPickup(1239, 23, Points[index][Pointx], Points[index][Pointy], Points[index][Pointz], Points[index][pointVW]);
		
		if(Points[index][CapFam] != INVALID_FAMILY_ID)
		{
			Points[index][CapCrash] = 1;
			Points[index][TakeOverTimerStarted] = 1;
			Points[index][ClaimerTeam] = Points[index][CapFam];
			Points[index][TakeOverTimer] = Points[index][CapTime];
			format(Points[index][PlayerNameCapping], MAX_PLAYER_NAME, "%s", Points[index][CapName]);
			ReadyToCapture(index);
			Points[index][CaptureTimerEx2] = SetTimerEx("CaptureTimerEx", 60000, true, "d", index);	
		}
		
		index++;
	}
	if(index == 0) print("[Family Points] No family points has been loaded.");
	if(index != 0) printf("[Family Points] %d family points has been loaded.", index);
	return 1;
}

stock GetPartnerName(playerid)
{
	if(PlayerInfo[playerid][pMarriedID] == -1) format(PlayerInfo[playerid][pMarriedName], MAX_PLAYER_NAME, "Nobody");
	else
	{
		new query[128];
		format(query, sizeof(query), "SELECT `Username` FROM `accounts` WHERE `id` = %d", PlayerInfo[playerid][pMarriedID]);	
		mysql_pquery(MainPipeline, query, "OnGetPartnerName", "i", playerid);
	}
}

forward OnGetPartnerName(playerid);
public OnGetPartnerName(playerid)
{
	new fields, rows, index;
	cache_get_data(rows, fields);
	
	cache_get_value_name(index, "Username", PlayerInfo[playerid][pMarriedName], MAX_PLAYER_NAME);
	return 1;
}

forward OnStaffPrize(playerid);
public OnStaffPrize(playerid)
{
	if(mysql_affected_rows(MainPipeline))
	{
		new type[32], name[MAX_PLAYER_NAME], amount, string[128];
		GetPVarString(playerid, "OnSPrizeType", type, 16);
		GetPVarString(playerid, "OnSPrizeName", name, 24);
		amount = GetPVarInt(playerid, "OnSPrizeAmount");
		format(string, sizeof(string), "AdmCmd: %s has offline-given %s %d free %s.", GetPlayerNameEx(playerid), name, amount, type);
		ABroadCast(COLOR_LIGHTRED, string, 2);
		format(string, sizeof(string), "You have given %s %d %s.", name, amount, type);
		SendClientMessageEx(playerid, COLOR_LIGHTBLUE, string);
		format(string, sizeof(string), "[Admin] %s(IP:%s) has offline-given %s %d free %s.", GetPlayerNameEx(playerid), GetPlayerIpEx(playerid), name, amount, type);
		Log("logs/adminrewards.log", string);
	}
	else
	{
		SendClientMessageEx(playerid, COLOR_RED, "Failed to give the prize..");
	}
	DeletePVar(playerid, "OnSPrizeType");
	DeletePVar(playerid, "OnSPrizeName");
	DeletePVar(playerid, "OnSPrizeAmount");
	return 1;
}

stock AddNewBackpack(id)
{
	new string[1024];
	format(string, sizeof(string), "INSERT into `hgbackpacks` (type, posx, posy, posz) VALUES ('%d', '%f', '%f', '%f')",
	HungerBackpackInfo[id][hgBackpackType],
	HungerBackpackInfo[id][hgBackpackPos][0],
	HungerBackpackInfo[id][hgBackpackPos][1],
	HungerBackpackInfo[id][hgBackpackPos][2]);
	
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "i", SENDDATA_THREAD);
}
	
stock SaveHGBackpack(id)
{
	new string[1024];
	format(string, sizeof(string), "UPDATE `hgbackpacks` SET \
		`type` = %d,
		`posx` = %f,
		`posy` = %f,
		`posz` = %f WHERE `id` = %d",
		HungerBackpackInfo[id][hgBackpackType],
		HungerBackpackInfo[id][hgBackpackPos][0],
		HungerBackpackInfo[id][hgBackpackPos][1],
		HungerBackpackInfo[id][hgBackpackPos][2],
		id
	);
		
	mysql_pquery(MainPipeline, string, false "OnQueryFinish", "i", SENDDATA_THREAD);
}

forward OnLoadHGBackpacks();
public OnLoadHGBackpacks()
{
	new fields, rows, index, result[128], string[128];
	cache_get_data(rows, fields);
	
	while((index < rows))
	{
		cache_get_value_name(index, "id", result); HungerBackpackInfo[index][hgBackpackId] = strval(result);
		cache_get_value_name(index, "type", result); HungerBackpackInfo[index][hgBackpackType] = strval(result);
		cache_get_value_name(index, "posx", result); HungerBackpackInfo[index][hgBackpackPos][0] = floatstr(result);
		cache_get_value_name(index, "posy", result); HungerBackpackInfo[index][hgBackpackPos][1] = floatstr(result);
		cache_get_value_name(index, "posz", result); HungerBackpackInfo[index][hgBackpackPos][2] = floatstr(result);
		
		HungerBackpackInfo[index][hgActiveEx] = 1;
		
		HungerBackpackInfo[index][hgBackpackPickupId] = CreateDynamicPickup(371, 23, HungerBackpackInfo[index][hgBackpackPos][0], HungerBackpackInfo[index][hgBackpackPos][1], HungerBackpackInfo[index][hgBackpackPos][2], 2039);
		format(string, sizeof(string), "Hunger Games Backpack\nType: %s\n{FF0000}(ID: %d){FFFFFF}", GetBackpackName(index), index);
		HungerBackpackInfo[index][hgBackpack3DText] = CreateDynamic3DTextLabel(string, COLOR_ORANGE, HungerBackpackInfo[index][hgBackpackPos][0], HungerBackpackInfo[index][hgBackpackPos][1], HungerBackpackInfo[index][hgBackpackPos][2]+1, 20.0, .worldid = 2039, .interiorid = 0);
		
		index++;
	}
	
	hgBackpackCount = index;
	
	if(index == 0) print("[Hunger Games] No Backpack has been loaded.");
	if(index != 0) printf("[Hunger Games] %d Backpacks has been loaded.", index);
	return true;
}	

forward ExecuteShopQueue(playerid, id);
public ExecuteShopQueue(playerid, id)
{
	new rows, fields, index, result[128], string[128], query[128], tmp[8];
	switch(id)
	{
		case 0:
		{
			cache_get_data(rows, fields);
			if(IsPlayerConnected(playerid))
			{
				if(rows)
				{
					cache_get_value_name(index, "id", result); tmp[0] = strval(result);
					cache_get_value_name(index, "GiftVoucher", result); tmp[1] = strval(result);
					cache_get_value_name(index, "CarVoucher", result); tmp[2] = strval(result);
					cache_get_value_name(index, "VehVoucher", result); tmp[3] = strval(result);
					cache_get_value_name(index, "SVIPVoucher", result); tmp[4] = strval(result);
					cache_get_value_name(index, "GVIPVoucher", result); tmp[5] = strval(result);
					cache_get_value_name(index, "PVIPVoucher", result); tmp[6] = strval(result);
					cache_get_value_name(index, "credits_spent", result); tmp[7] = strval(result);
					
					if(tmp[1] > 0)
					{
						PlayerInfo[playerid][pGiftVoucher] += tmp[1];
						format(string, sizeof(string), "Ban da tu dong duoc cap %d gift reset voucher(s).", tmp[1]);
						SendClientMessageEx(playerid, COLOR_WHITE, string);
						format(string, sizeof(string), "[ID: %d] %s da tu dong duoc cap %d gift reset voucher(s)", tmp[0], GetPlayerNameEx(playerid), tmp[1]);
						Log("logs/shoplog.log", string);
					}
					if(tmp[2] > 0)
					{
						PlayerInfo[playerid][pCarVoucher] += tmp[2];
						format(string, sizeof(string), "Ban da tu dong duoc cap %d restricted car voucher(s).", tmp[2]);
						SendClientMessageEx(playerid, COLOR_WHITE, string);
						format(string, sizeof(string), "[ID: %d] %s da tu dong duoc cap %d restricted car voucher(s)", tmp[0], GetPlayerNameEx(playerid), tmp[2]);
						Log("logs/shoplog.log", string);
					}
					if(tmp[3] > 0)
					{
						PlayerInfo[playerid][pVehVoucher] += tmp[3];
						format(string, sizeof(string), "Ban da tu dong duoc cap %d car voucher(s).", tmp[3]);
						SendClientMessageEx(playerid, COLOR_WHITE, string);
						format(string, sizeof(string), "[ID: %d] %s da tu dong duoc cap %d car voucher(s)", tmp[0], GetPlayerNameEx(playerid), tmp[3]);
						Log("logs/shoplog.log", string);
					}
					if(tmp[4] > 0)
					{
						PlayerInfo[playerid][pSVIPVoucher] += tmp[4];
						format(string, sizeof(string), "Ban da tu dong duoc cap %d Silver VIP voucher(s).", tmp[4]);
						SendClientMessageEx(playerid, COLOR_WHITE, string);
						format(string, sizeof(string), "[ID: %d] %s da tu dong duoc cap %d Silver VIP voucher(s)", tmp[0], GetPlayerNameEx(playerid), tmp[4]);
						Log("logs/shoplog.log", string);
					}
					if(tmp[5] > 0)
					{
						PlayerInfo[playerid][pGVIPVoucher] += tmp[5];
						format(string, sizeof(string), "Ban da tu dong duoc cap %d Gold VIP voucher(s).", tmp[5]);
						SendClientMessageEx(playerid, COLOR_WHITE, string);
						format(string, sizeof(string), "[ID: %d] %s da tu dong duoc cap %d Gold VIP voucher(s)", tmp[0], GetPlayerNameEx(playerid), tmp[5]);
						Log("logs/shoplog.log", string);
					}
					if(tmp[6] > 0)
					{
						PlayerInfo[playerid][pPVIPVoucher] += tmp[6];
						format(string, sizeof(string), "Ban da tu dong duoc cap %d Platinum VIP voucher(s).", tmp[6]);
						SendClientMessageEx(playerid, COLOR_WHITE, string);
						format(string, sizeof(string), "[ID: %d] %s da tu dong duoc cap %d Platinum VIP voucher(s)", tmp[0], GetPlayerNameEx(playerid), tmp[6]);
						Log("logs/shoplog.log", string);
					}

					PlayerInfo[playerid][pCredits] -= tmp[7];
					format(query, sizeof(query), "UPDATE `shop_orders` SET `status` = 1 WHERE `id` = %d", tmp[0]);
					mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
					OnPlayerStatsUpdate(playerid);
					return SendClientMessageEx(playerid, COLOR_CYAN, "* Su dung /myvouchers de kiem tra va su dung vouchers cua ban bat cu luc nap!");
				}
			}
		}
		case 1:
		{
			cache_get_data(rows, fields);
			if(IsPlayerConnected(playerid))
			{
				if(rows)
				{
					cache_get_value_name(index, "order_id", result); tmp[0] = strval(result);
					cache_get_value_name(index, "credit_amount", result); tmp[1] = strval(result);
					
					PlayerInfo[playerid][pCredits] += tmp[1];
					format(string, sizeof(string), "Ban da tu dong duoc cap %s credit(s).", number_format(tmp[1]));
					SendClientMessageEx(playerid, COLOR_WHITE, string);
					format(string, sizeof(string), "[ID: %d] %s da duoc tu dong cap %s credit(s)", tmp[0], GetPlayerNameEx(playerid), number_format(tmp[1]));
					Log("logs/shoplog.log", string);
					format(query, sizeof(query), "UPDATE `order_delivery_status` SET `status` = 1 WHERE `order_id` = %d", tmp[0]);
					mysql_pquery(ShopPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
					OnPlayerStatsUpdate(playerid);
					return 1;
				}
			}
		}
	}
	return 1;
}

stock CheckAdminWhitelist(playerid)
{
	new string[128];
	format(string, sizeof(string), "SELECT `AdminLevel`, `SecureIP` FROM `accounts` WHERE `Username` = '%s'", GetPlayerNameExt(playerid));
	mysql_pquery(MainPipeline, string, "OnQueryFinish", "iii", ADMINWHITELIST_THREAD, playerid, g_arrQueryHandle{playerid});
	return true;
}

stock GivePlayerCashEx(playerid, type, amount)
{
	if(IsPlayerConnected(playerid) && gPlayerLogged{playerid})
	{
		new szQuery[128];
		switch(type)
		{
			case TYPE_BANK:
			{
				PlayerInfo[playerid][pAccount] += amount;
				format(szQuery, sizeof(szQuery), "UPDATE `accounts` SET `Bank`=%d WHERE `id` = %d", PlayerInfo[playerid][pAccount], GetPlayerSQLId(playerid));
				mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);
			}
			case TYPE_ONHAND:
			{
				PlayerInfo[playerid][pCash] += amount;
				format(szQuery, sizeof(szQuery), "UPDATE `accounts` SET `Money`=%d WHERE `id` = %d", PlayerInfo[playerid][pCash], GetPlayerSQLId(playerid));
				mysql_pquery(MainPipeline, szQuery, "OnQueryFinish", "ii", SENDDATA_THREAD, playerid);		
			}
		}
	}	
	return 1;
}

stock PointCrashProtection(point)
{
	new query[128], temp;
	temp = Points[point][ClaimerTeam];
	if(temp == INVALID_PLAYER_ID)
	{
		temp = INVALID_FAMILY_ID;
	}
	format(query, sizeof(query), "UPDATE `points` SET `captime` = %d, `capfam` = %d, `capname` = '%s' WHERE `id` = %d",Points[point][TakeOverTimer], temp, Points[point][PlayerNameCapping], Points[point][pointID]);
	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
	return 1;
}

/*stock LoadHelp()
{
	printf("[LoadHelp] Loading data from database...");
	mysql_pquery(MainPipeline, "SELECT * FROM `help`", "OnLoadHelp", "");
}

forward OnLoadHelp();
public OnLoadHelp()
{
	new i, rows, fields, tmp[128];
	cache_get_data(rows, fields);

	TOTAL_COMMANDS = rows;
	while(i < rows)
	{
		cache_get_value_name(i, "id", tmp); HelpInfo[i][id] = strval(tmp);
		cache_get_value_name(i, "name", HelpInfo[i][name], 255);
		cache_get_value_name(i, "params", HelpInfo[i][params], 255);
		cache_get_value_name(i, "description", HelpInfo[i][description], 255);
		cache_get_value_name(i, "type", tmp); HelpInfo[i][type] = strval(tmp);
		cache_get_value_name(i, "subtype", tmp); HelpInfo[i][subtype] = strval(tmp);
		cache_get_value_name(i, "perms", tmp); HelpInfo[i][perms] = strval(tmp);
		i++;
	}
}*/

stock LoadGangTags()
{
	new query[128];
	format(query, sizeof(query), "SELECT * FROM `gangtags` LIMIT %d", MAX_GANGTAGS);
	mysql_pquery(MainPipeline, query, "OnGangTagQueryFinish", "ii", LOAD_GANGTAGS, -1);
}

stock SaveGangTag(gangtag)
{
	new query[256];
	format(query, sizeof(query), "UPDATE `gangtags` SET \
		`posx` = %f, \
		`posy` = %f, \
		`posz` = %f, \
		`posrx` = %f, \
		`posry` = %f, \
		`posrz` = %f, \
		`objectid` = %d, \
		`vw` = %d, \
		`interior` = %d, \
		`family` = %d, \
		`time` = %d, \
		`used` = %d WHERE `id` = %d",
		GangTags[gangtag][gt_PosX],
		GangTags[gangtag][gt_PosY],
		GangTags[gangtag][gt_PosZ],
		GangTags[gangtag][gt_PosRX],
		GangTags[gangtag][gt_PosRY],
		GangTags[gangtag][gt_PosRZ],
		GangTags[gangtag][gt_ObjectID],
		GangTags[gangtag][gt_VW],
		GangTags[gangtag][gt_Int],
		GangTags[gangtag][gt_Family],
		GangTags[gangtag][gt_Time],
		GangTags[gangtag][gt_Used],
		GangTags[gangtag][gt_SQLID]
	);
	mysql_pquery(MainPipeline, query, "OnGangTagQueryFinish", "ii", SAVE_GANGTAG, gangtag);
}

forward OnGangTagQueryFinish(threadid, extraid);
public OnGangTagQueryFinish(threadid, extraid)
{
	new fields, rows;
	cache_get_data(rows, fields);
	switch(threadid)
	{
		case LOAD_GANGTAGS:
		{
			new row, result[64];
			while(row < rows)
			{
				cache_get_value_name(row, "id", result); GangTags[row][gt_SQLID] = strval(result);
				cache_get_value_name(row, "posx", result); GangTags[row][gt_PosX] = floatstr(result);
				cache_get_value_name(row, "posy", result); GangTags[row][gt_PosY] = floatstr(result);
				cache_get_value_name(row, "posz", result); GangTags[row][gt_PosZ] = floatstr(result);
				cache_get_value_name(row, "posrx", result); GangTags[row][gt_PosRX] = floatstr(result);
				cache_get_value_name(row, "posry", result); GangTags[row][gt_PosRY] = floatstr(result);
				cache_get_value_name(row, "posrz", result); GangTags[row][gt_PosRZ] = floatstr(result);
				cache_get_value_name(row, "objectid", result); GangTags[row][gt_ObjectID] = strval(result);
				cache_get_value_name(row, "vw", result); GangTags[row][gt_VW] = strval(result);
				cache_get_value_name(row, "interior", result); GangTags[row][gt_Int] = strval(result);
				cache_get_value_name(row, "family", result); GangTags[row][gt_Family] = strval(result);
				cache_get_value_name(row, "used", result); GangTags[row][gt_Used] = strval(result);
				cache_get_value_name(row, "time", result); GangTags[row][gt_Time] = strval(result);
				CreateGangTag(row);
				row++;
			}
			if(row > 0)
			{
				printf("[MYSQL] Successfully loaded %d gang tags.", row);
			}
			else
			{
				print("[MYSQL] Failed loading any gang tags.");
			}
		}
		case SAVE_GANGTAG:
		{
			if(mysql_affected_rows(MainPipeline))
			{
				printf("[MYSQL] Successfully saved gang tag %d (SQLID: %d).", extraid, GangTags[extraid][gt_SQLID]);
			}
			else
			{
				printf("[MYSQL] Failed saving gang tag %d (SQLID: %d).", extraid, GangTags[extraid][gt_SQLID]);
			}
		}
	}
	return 1;
}

// g_mysql_LoadGiftBox()
// Description: Loads the data of the dynamic giftbox from the SQL Database.
stock g_mysql_LoadGiftBox()
{
	print("[Dynamic Giftbox] Loading the Dynamic Giftbox...");
	// Limit query to prevent excessive data loading
	mysql_pquery(MainPipeline, "SELECT * FROM `giftbox` LIMIT 50", "OnQueryFinish", "iii", LOADGIFTBOX_THREAD, INVALID_PLAYER_ID, -1);
}

stock SaveDynamicGiftBox()
{
	new query[4096];
	for(new i = 0; i < 4; i++)
	{
		if(i == 0)
			format(query, sizeof(query), "UPDATE `giftbox` SET `dgMoney%d` = '%d',", i, dgMoney[i]);
		else
			format(query, sizeof(query), "%s `dgMoney%d` = '%d',", query, i, dgMoney[i]);
			
		format(query, sizeof(query), "%s `dgRimKit%d` = '%d',", query, i, dgRimKit[i]);
		format(query, sizeof(query), "%s `dgFirework%d` = '%d',", query, i, dgFirework[i]);
		format(query, sizeof(query), "%s `dgGVIP%d` = '%d',", query, i, dgGVIP[i]);
		format(query, sizeof(query), "%s `dgSVIP%d` = '%d',", query, i, dgSVIP[i]);
		format(query, sizeof(query), "%s `dgGVIPEx%d` = '%d',", query, i, dgGVIPEx[i]);
		format(query, sizeof(query), "%s `dgSVIPEx%d` = '%d',", query, i, dgSVIPEx[i]);
		format(query, sizeof(query), "%s `dgCarSlot%d` = '%d',", query, i, dgCarSlot[i]);
		format(query, sizeof(query), "%s `dgToySlot%d` = '%d',", query, i, dgToySlot[i]);
		format(query, sizeof(query), "%s `dgArmor%d` = '%d',", query, i, dgArmor[i]);
		format(query, sizeof(query), "%s `dgFirstaid%d` = '%d',", query, i, dgFirstaid[i]);
		format(query, sizeof(query), "%s `dgDDFlag%d` = '%d',", query, i, dgDDFlag[i]);
		format(query, sizeof(query), "%s `dgGateFlag%d` = '%d',", query, i, dgGateFlag[i]);
		format(query, sizeof(query), "%s `dgCredits%d` = '%d',", query, i, dgCredits[i]);
		format(query, sizeof(query), "%s `dgPriorityAd%d` = '%d',", query, i, dgPriorityAd[i]);
		format(query, sizeof(query), "%s `dgHealthNArmor%d` = '%d',", query, i, dgHealthNArmor[i]);
		format(query, sizeof(query), "%s `dgGiftReset%d` = '%d',", query, i, dgGiftReset[i]);
		format(query, sizeof(query), "%s `dgMaterial%d` = '%d',", query, i, dgMaterial[i]);
		format(query, sizeof(query), "%s `dgWarning%d` = '%d',", query, i, dgWarning[i]);
		format(query, sizeof(query), "%s `dgPot%d` = '%d',", query, i, dgPot[i]);
		format(query, sizeof(query), "%s `dgCrack%d` = '%d',", query, i, dgCrack[i]);
		format(query, sizeof(query), "%s `dgPaintballToken%d` = '%d',", query, i, dgPaintballToken[i]);
		format(query, sizeof(query), "%s `dgVIPToken%d` = '%d',", query, i, dgVIPToken[i]);
		format(query, sizeof(query), "%s `dgRespectPoint%d` = '%d',", query, i, dgRespectPoint[i]);
		format(query, sizeof(query), "%s `dgCarVoucher%d` = '%d',", query, i, dgCarVoucher[i]);
		format(query, sizeof(query), "%s `dgBuddyInvite%d` = '%d',", query, i, dgBuddyInvite[i]);
		format(query, sizeof(query), "%s `dgLaser%d` = '%d',", query, i, dgLaser[i]);
		format(query, sizeof(query), "%s `dgCustomToy%d` = '%d',", query, i, dgCustomToy[i]);
		format(query, sizeof(query), "%s `dgAdmuteReset%d` = '%d',", query, i, dgAdmuteReset[i]);
		format(query, sizeof(query), "%s `dgNewbieMuteReset%d` = '%d',", query, i, dgNewbieMuteReset[i]);
		
		if(i == 3)
			format(query, sizeof(query), "%s `dgRestrictedCarVoucher%d` = '%d'", query, i, dgRestrictedCarVoucher[i]);
		else
			format(query, sizeof(query), "%s `dgPlatinumVIPVoucher%d` = '%d',", query, i, dgPlatinumVIPVoucher[i]);
	}

	mysql_pquery(MainPipeline, query, "OnQueryFinish", "i", SENDDATA_THREAD);
}
