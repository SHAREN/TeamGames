#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID_TEAMGAME		"GunFight-TeamGame"
#define GAME_ID_REDONLY			"GunFight-RedOnly"

public Plugin:myinfo =
{
	name = "[TG] GunFight",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

new EngineVersion:g_iEngVersion;

public OnPluginStart()
{
	LoadTranslations("TG.GunFight.phrases");
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

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], iClient)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_TEAMGAME) || StrEqual(id, GAME_ID_REDONLY)) {
		SetWeaponMenu(iClient, id);
	}
}

public TG_OnGameStart(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID_TEAMGAME) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	decl String:sWeapon[64];

	ResetPack(hDataPack);
	ReadPackString(hDataPack, sWeapon, sizeof(sWeapon));

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerItem(i, "weapon_knife");
		GivePlayerWeaponAndAmmo(i, sWeapon);
	}
}

SetWeaponMenu(iClient, const String:sID[])
{
	new Handle:hMenu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(hMenu, "%T", "ChooseWeapon", iClient);
	PushMenuString(hMenu, "_GAME_ID_", sID);

	switch (g_iEngVersion) {
		case Engine_CSS: {
			AddMenuItem(hMenu, "weapon_deagle", "Deagle");
			AddMenuItem(hMenu, "weapon_usp", 	"USP");
			AddMenuItem(hMenu, "weapon_glock", 	"Glock-18");
			AddMenuItem(hMenu, "weapon_ak47", 	"AK-47");
			AddMenuItem(hMenu, "weapon_m4a1", 	"M4A1");
		}
		case Engine_CSGO: {
			AddMenuItem(hMenu, "weapon_deagle", 		"Deagle");
			AddMenuItem(hMenu, "weapon_p250", 			"P250");
			AddMenuItem(hMenu, "weapon_mp7", 			"MP7");
			AddMenuItem(hMenu, "weapon_ak47", 			"AK-47");
			AddMenuItem(hMenu, "weapon_m4a1_silencer", 	"M4A1-S");
			AddMenuItem(hMenu, "weapon_nova", 			"Nova");
			AddMenuItem(hMenu, "weapon_m249", 			"M249 Para");
		}
	}

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public SetWeaponMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select)
	{
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
