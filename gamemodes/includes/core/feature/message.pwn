#include <YSI\YSI_Coding\y_hooks>
new PlayerText:Message_TD[MAX_PLAYERS][1];
static MessageTimer[MAX_PLAYERS];


hook OnPlayerConnect(playerid)
{
    SCMTextdraw(playerid);
    DeletePVar(playerid, "ClientMessage");
    KillTimer(MessageTimer[playerid]);
    PlayerTextDrawHide(playerid, Message_TD[playerid][0]);
    return 1;
}

hook OnPlayerDisconnect(playerid)
{
    DeletePVar(playerid, "ClientMessage");
    KillTimer(MessageTimer[playerid]);
    PlayerTextDrawDestroy(playerid, Message_TD[playerid][0]);
    return 1;
}

stock SCMTextdraw(playerid) 
{
    Message_TD[playerid][0] = CreatePlayerTextDraw(playerid, 320.0000, 388.0000, "Press_~r~H~w~_go_outside"); // ïóñòî
    PlayerTextDrawLetterSize(playerid, Message_TD[playerid][0], 0.2060, 1.0792);
    PlayerTextDrawTextSize(playerid, Message_TD[playerid][0], 0.0000, 635.0000);
    PlayerTextDrawAlignment(playerid, Message_TD[playerid][0], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, Message_TD[playerid][0], -1);
    PlayerTextDrawSetOutline(playerid, Message_TD[playerid][0], 1);
    PlayerTextDrawBackgroundColour(playerid, Message_TD[playerid][0], 255);
    PlayerTextDrawFont(playerid, Message_TD[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, Message_TD[playerid][0], true);
    PlayerTextDrawSetShadow(playerid, Message_TD[playerid][0], 0);
    return 1;
}

stock ShowClientMessage(playerid,time,const text[]) 
{
	if(GetPVarInt(playerid, "ClientMessage") == 1) 
    {
        DeletePVar(playerid, "ClientMessage");
        KillTimer(MessageTimer[playerid]);
	    PlayerTextDrawHide(playerid, Message_TD[playerid][0]);
	}
    PlayerTextDrawSetString(playerid,  Message_TD[playerid][0], text);
    PlayerTextDrawShow(playerid, Message_TD[playerid][0]);
    MessageTimer[playerid] = SetTimerEx("HideClientMessage", 1000 * time, false, "d", playerid);
    SetPVarInt(playerid, "ClientMessage", 1);
    return 1;
}
forward HideClientMessage(playerid); 
public HideClientMessage(playerid)
{
    DeletePVar(playerid, "ClientMessage");
    KillTimer(MessageTimer[playerid]);
	PlayerTextDrawHide(playerid, Message_TD[playerid][0]);
}

stock SCM(playerid,const string[])
{
    PlayerTextDrawHide(playerid, Message_TD[playerid][0]);
    new gstr[129];
    format(gstr,sizeof(gstr), string);
    ShowClientMessage(playerid, 5, gstr);
    return 1;
}

