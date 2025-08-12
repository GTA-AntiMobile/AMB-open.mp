#include <YSI\YSI_Coding\y_hooks>

stock LoadLoginPanelTD(playerid) {
    Login_Panel_PTD[playerid][0] = CreatePlayerTextDraw(playerid, -1.000, -1.000, "mdl-2001:bg");
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][0], 642.000, 450.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][0], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][0], 0);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][0], 255);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][0], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][0], true);

    Login_Panel_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 202.000, 137.000, "mdl-2001:Main");
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][1], 223.000, 183.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][1], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][1], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][1], 0);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][1], 255);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][1], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][1], true);

    Login_Panel_PTD[playerid][2] = CreatePlayerTextDraw(playerid, 315.000, 221.000, "Lil_Dylan");
    PlayerTextDrawLetterSize(playerid, Login_Panel_PTD[playerid][2], 0.179, 0.998);
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][2], 6.000, 87.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][2], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][2], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][2], 1);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][2], 1);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][2], 150);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][2], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][2], true);

    Login_Panel_PTD[playerid][3] = CreatePlayerTextDraw(playerid, 315.000, 254.000, "password");
    PlayerTextDrawLetterSize(playerid, Login_Panel_PTD[playerid][3], 0.230, 1.299);
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][3], 6.000, 87.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][3], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][3], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][3], 1);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][3], 1);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][3], 150);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][3], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][3], true);
    PlayerTextDrawSetSelectable(playerid, Login_Panel_PTD[playerid][3], true);

    Login_Panel_PTD[playerid][4] = CreatePlayerTextDraw(playerid, 277.000, 283.000, "mdl-2001:Login");
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][4], 76.000, 26.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][4], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][4], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][4], 0);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][4], 255);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][4], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][4], true);

    Login_Panel_PTD[playerid][5] = CreatePlayerTextDraw(playerid, 315.000, 289.000, "Login");
    PlayerTextDrawLetterSize(playerid, Login_Panel_PTD[playerid][5], 0.230, 1.299);
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][5], 6.000, 87.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][5], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][5], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][5], 1);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][5], 1);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][5], 150);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][5], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][5], true);
    PlayerTextDrawSetSelectable(playerid, Login_Panel_PTD[playerid][5], true);

    Login_Panel_PTD[playerid][6] = CreatePlayerTextDraw(playerid, 277.000, 283.000, "mdl-2001:Register");
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][6], 76.000, 26.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][6], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][6], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][6], 0);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][6], 0);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][6], 255);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][6], TEXT_DRAW_FONT_SPRITE_DRAW);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][6], true);

    Login_Panel_PTD[playerid][7] = CreatePlayerTextDraw(playerid, 315.000, 289.000, "Register");
    PlayerTextDrawLetterSize(playerid, Login_Panel_PTD[playerid][7], 0.230, 1.299);
    PlayerTextDrawTextSize(playerid, Login_Panel_PTD[playerid][7], 6.000, 87.000);
    PlayerTextDrawAlignment(playerid, Login_Panel_PTD[playerid][7], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, Login_Panel_PTD[playerid][7], -1);
    PlayerTextDrawSetShadow(playerid, Login_Panel_PTD[playerid][7], 1);
    PlayerTextDrawSetOutline(playerid, Login_Panel_PTD[playerid][7], 1);
    PlayerTextDrawBackgroundColour(playerid, Login_Panel_PTD[playerid][7], 150);
    PlayerTextDrawFont(playerid, Login_Panel_PTD[playerid][7], TEXT_DRAW_FONT_2);
    PlayerTextDrawSetProportional(playerid, Login_Panel_PTD[playerid][7], true);
    PlayerTextDrawSetSelectable(playerid, Login_Panel_PTD[playerid][7], true);
}


stock ShowRegisterPanel(playerid) 
{
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][0]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][1]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][2]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][3]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][6]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][7]);
    PlayerTextDrawSetString(playerid, Login_Panel_PTD[playerid][2], GetPlayerNameEx(playerid));
    SelectTextDraw(playerid, COLOR_YELLOW);
    SetPVarInt(playerid, "TypeShowRegister", 2);
    return 1;
}

stock ShowLoginPanel(playerid) {
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][0]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][1]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][2]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][3]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][4]);
    PlayerTextDrawShow(playerid, Login_Panel_PTD[playerid][5]);
    PlayerTextDrawSetString(playerid, Login_Panel_PTD[playerid][2], GetPlayerNameEx(playerid));
    SelectTextDraw(playerid, COLOR_YELLOW);
    SetPVarInt(playerid, "TypeShowRegister", 1);
    return 1;
}

stock HideLoginPanel(playerid) {
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][0]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][1]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][2]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][3]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][4]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][5]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][6]);
    PlayerTextDrawHide(playerid, Login_Panel_PTD[playerid][7]);
    DeletePVar(playerid, "IsEnterAccount");
    DeletePVar(playerid, "IsEnterPassword");
    return 1;
}