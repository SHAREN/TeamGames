#include <sourcemod>
#include <cstrike>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID_TEAMGAME	"ReloadBattle-TeamGame"
#define GAME_ID_REDONLY		"ReloadBattle-RedOnly"

new String:g_sWeapon[64];
new EngineVersion:g_iEngVersion;

public Plugin:myinfo =
{
	name = "[TG] ReloadBattle",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.ReloadBattle.phrases");
	g_iEngVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_ID_TEAMGAME);
		TG_RegGame(GAME_ID_REDONLY, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID_TEAMGAME);
	TG_RemoveGame(GAME_ID_REDONLY);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_TEAMGAME)) {
		Format(name, maxSize, "%T", "GameName-TeamGame", client);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], iClient)
{
	if ((StrEqual(sID, GAME_ID_TEAMGAME) || StrEqual(sID, GAME_ID_REDONLY)) && type == TG_Game) {
		strcopy(g_sWeapon, sizeof(g_sWeapon), "");
		SetWeaponMenu(iClient, sID);
	}
}

public TG_OnGameStart(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID_TEAMGAME) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	decl String:sWeapon[64];

	ResetPack(hDataPack);
	ReadPackString(hDataPack, sWeapon, sizeof(sWeapon));

	strcopy(g_sWeapon, sizeof(g_sWeapon), sWeapon);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerWeaponAndAmmo(i, sWeapon, 0, 1);
	}

	HookEvent("weapon_fire", Event_WeaponFire);
}

public Action:Event_WeaponFire(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID_TEAMGAME) && !TG_IsCurrentGameID(GAME_ID_REDONLY))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (TG_IsPlayerRedOrBlue(iClient)) {
		decl String:sWeaponName[64];
		GetEventString(hEvent, "weapon", sWeaponName, sizeof(sWeaponName));

		if (StrContains(g_sWeapon, sWeaponName) != -1) {
			RequestFrame(Frame_SetPlayerAmmo, iClient);
		}
	}

	return Plugin_Continue;
}

public Frame_SetPlayerAmmo(any:iClient)
{
	SetPlayerWeaponAmmo(iClient, Client_GetWeapon(iClient, g_sWeapon), 0, 1);
}

SetWeaponMenu(iClient, const String:sID[])
{
	new Handle:hMenu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(hMenu, "%T", "ChooseWeapon", iClient);

	PushMenuString(hMenu, "_GAME_ID_", sID);

	switch (g_iEngVersion) {
		case Engine_CSS: {
			AddMenuItem(hMenu, "weapon_deagle", "Deagle");
			AddMenuItem(hMenu, "weapon_p228", 	"p228");
			AddMenuItem(hMenu, "weapon_ak47", 	"AK-47");
			AddMenuItem(hMenu, "weapon_m4a1", 	"M4A1");
			AddMenuItem(hMenu, "weapon_scout", 	"Scout");
			AddMenuItem(hMenu, "weapon_m249", 	"Machine gun");
		}
		case Engine_CSGO: {
			AddMenuItem(hMenu, "weapon_deagle", "Deagle");
			AddMenuItem(hMenu, "weapon_p250", 	"p250");
			AddMenuItem(hMenu, "weapon_ak47", 	"AK-47");
			AddMenuItem(hMenu, "weapon_m4a1", 	"M4A4");
			AddMenuItem(hMenu, "weapon_ssg08", 	"Scout");
			AddMenuItem(hMenu, "weapon_negev", 	"Negev");
		}
	}

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public SetWeaponMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		new String:sKey[64], String:sWeaponName[64], String:sID[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey), _, sWeaponName, 64);

		if (!GetMenuString(hMenu, "_GAME_ID_", sID, sizeof(sID))) {
			return;
		}

		new Handle:hDataPack = CreateDataPack();
		WritePackString(hDataPack, sKey);

		if (StrEqual(sID, GAME_ID_TEAMGAME)) {
			TG_StartGame(iClient, GAME_ID_TEAMGAME, sWeaponName, hDataPack, true);
		} else {
			TG_StartGame(iClient, GAME_ID_REDONLY, sWeaponName, hDataPack, true);
		}
	}
}
