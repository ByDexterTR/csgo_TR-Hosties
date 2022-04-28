#include <sourcemod>
#include <cstrike>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <basecomm>

#pragma semicolon 1
#pragma newdecls required

int g_CollisionGroup = -1;
bool bBasecomm;
float dcoor[65][3], dangle[65][3];
bool LR = false, NsLR = false;
int g_iBeam = -1;
int LRClient[2] = { 0, ... }; // 0 T | 1 CT
bool S4S[65] = { false, ... };

public Plugin myinfo = 
{
	name = "[JB] TR Hosties", 
	author = "ByDexter", 
	description = "Türkiye için uyarlanmış jailbreak ana eklentisi.", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_lr", Command_LR, "");
	
	RegAdminCmd("sm_lriptal", Command_Cancellr, ADMFLAG_SLAY, "");
	RegAdminCmd("sm_lr0", Command_Cancellr, ADMFLAG_SLAY, "");
	RegAdminCmd("sm_cancellr", Command_Cancellr, ADMFLAG_SLAY, "");
	
	RegAdminCmd("sm_hrespawn", Command_Respawn, ADMFLAG_SLAY, "[SM] Usage: sm_hrespawn <#userid|name>");
	RegAdminCmd("sm_hrev", Command_Respawn, ADMFLAG_SLAY, "[SM] Usage: sm_hrev <#userid|name>");
	RegAdminCmd("sm_1up", Command_Respawn, ADMFLAG_SLAY, "[SM] Usage: sm_1up <#userid|name>");
	
	g_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if (g_CollisionGroup == -1)
	{
		SetFailState("Unable to find offset for collision groups.");
	}
	HookEvent("player_spawn", OnClientSpawn);
	HookEvent("player_death", OnClientDead);
	
	HookEvent("round_end", RoundEnd);
	
	HookEvent("weapon_fire", WeaponFire);
	
	AddCommandListener(OnJoinTeam, "jointeam");
	
	AddCommandListener(StripPlayer, "sm_ban");
	AddCommandListener(StripPlayer, "sm_kick");
}

public Action Command_Cancellr(int client, int args)
{
	if (!LR)
	{
		ReplyToCommand(client, "[SM] Aktif bir LR bulunamadı.");
		return Plugin_Handled;
	}
	
	LR = false;
	PrintToChatAll("[SM] \x10%N\x01 LR'yi iptal etti.", client);
	return Plugin_Handled;
}

public Action Command_LR(int client, int args)
{
	int Num = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
			continue;
		
		Num++;
	}
	if (Num != 1)
	{
		ReplyToCommand(client, "[SM] Birden fazla terörist varken LR atamazsın.");
		return Plugin_Handled;
	}
	
	if (LR)
	{
		ReplyToCommand(client, "[SM] Aktif bir LR bulunmakta. (\x10%N\x01 v \x10%N\x01) \x10!lriptal", LRClient[0], LRClient[1]);
		return Plugin_Handled;
	}
	
	Num = GetClientTeam(client);
	if (Num != 2)
	{
		ReplyToCommand(client, "[SM] Sadece terörist takımı LR isteği yollayabilir.");
		return Plugin_Handled;
	}
	
	Menu menu = new Menu(Menu_callback);
	menu.SetTitle("LR Menüsü - Tür Seç\n ");
	menu.AddItem("0", "Shot4Shot - Deagle\n ");
	menu.AddItem("1", "NoScope - Awp\n ");
	menu.AddItem("2", "Vazgeç");
	menu.ExitBackButton = false;
	menu.ExitButton = false;
	menu.Display(client, 10);
	return Plugin_Handled;
}

public int Menu_callback(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char item[4];
		menu.GetItem(position, item, 4);
		int pos = StringToInt(item);
		if (pos == 0)
		{
			NsLR = false;
			Gardiyansor().Display(client, 10);
		}
		else if (pos == 1)
		{
			NsLR = true;
			Gardiyansor().Display(client, 10);
		}
	}
}

Menu Gardiyansor()
{
	Menu menu = new Menu(Menu2_callback);
	menu.SetTitle("LR Menüsü - Gardiyan Seç\n ");
	menu.AddItem("0", "Sayfayı Yenile\n ");
	char name[128], userid[16];
	for (int client = 1; client <= MaxClients; client++)if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		if (!IsPlayerAlive(client))
		{
			CS_RespawnPlayer(client);
		}
		GetClientName(client, name, 128);
		FormatEx(userid, 16, "%d", GetClientUserId(client));
		menu.AddItem(userid, name);
	}
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	return menu;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (LR && NsLR && (LRClient[0] || LRClient[1]))
	{
		buttons &= ~IN_ATTACK2;
	}
	return Plugin_Continue;
}

public int Menu2_callback(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char item[4];
		menu.GetItem(position, item, 4);
		int pos = StringToInt(item);
		if (pos == 0)
		{
			Gardiyansor().Display(client, 10);
		}
		else
		{
			LRClient[0] = client;
			LRClient[1] = GetClientOfUserId(pos);
			if (IsValidClient(LRClient[1]) && IsPlayerAlive(LRClient[1]))
			{
				SetEntProp(LRClient[1], Prop_Send, "m_bHasHelmet", 0);
				SetEntProp(LRClient[1], Prop_Send, "m_ArmorValue", 0, 0);
				if (GetEngineVersion() == Engine_CSGO)
				{
					SetEntProp(LRClient[1], Prop_Send, "m_bHasHeavyArmor", 0);
					SetEntProp(LRClient[1], Prop_Send, "m_bWearingSuit", 0);
				}
				SetEntityHealth(LRClient[1], 100);
				SetEntPropFloat(LRClient[1], Prop_Data, "m_flLaggedMovementValue", 1.0);
				int wepIdx = 0;
				for (int i; i < 12; i++)
				{
					while ((wepIdx = GetPlayerWeaponSlot(LRClient[1], i)) != -1)
					{
						RemovePlayerItem(LRClient[1], wepIdx);
						RemoveEntity(wepIdx);
					}
				}
				
				SetEntProp(LRClient[0], Prop_Send, "m_bHasHelmet", 0);
				SetEntProp(LRClient[0], Prop_Send, "m_ArmorValue", 0, 0);
				if (GetEngineVersion() == Engine_CSGO)
				{
					SetEntProp(LRClient[0], Prop_Send, "m_bHasHeavyArmor", 0);
					SetEntProp(LRClient[0], Prop_Send, "m_bWearingSuit", 0);
				}
				SetEntityHealth(LRClient[0], 100);
				SetEntPropFloat(LRClient[0], Prop_Data, "m_flLaggedMovementValue", 1.0);
				wepIdx = 0;
				for (int i; i < 12; i++)
				{
					while ((wepIdx = GetPlayerWeaponSlot(LRClient[0], i)) != -1)
					{
						RemovePlayerItem(LRClient[0], wepIdx);
						RemoveEntity(wepIdx);
					}
				}
				
				SetEntityModel(LRClient[0], "models/player/custom_player/legacy/tm_jungle_raider_variantc.mdl");
				SetEntityModel(LRClient[1], "models/player/custom_player/legacy/ctm_st6_variantk.mdl");
				
				LR = true;
				if (NsLR)
				{
					PrintToChatAll("[SM] \x10%N \x01ve \x10%N\x01, NoScope(\x06Awp\x01) kapışmasına \x0Fbaşladı.", LRClient[0], LRClient[1]);
					int iAwp = GivePlayerItem(LRClient[0], "weapon_awp");
					SetEntProp(iAwp, Prop_Data, "m_iClip1", 313);
					SetEntProp(iAwp, Prop_Send, "m_iPrimaryReserveAmmoCount", 313);
					SetEntProp(iAwp, Prop_Send, "m_iSecondaryReserveAmmoCount", 313);
					iAwp = GivePlayerItem(LRClient[1], "weapon_awp");
					SetEntProp(iAwp, Prop_Data, "m_iClip1", 313);
					SetEntProp(iAwp, Prop_Send, "m_iPrimaryReserveAmmoCount", 313);
					SetEntProp(iAwp, Prop_Send, "m_iSecondaryReserveAmmoCount", 313);
					CreateTimer(1.0, StartNoScope, 4, TIMER_FLAG_NO_MAPCHANGE);
					SetEntProp(LRClient[0], Prop_Data, "m_takedamage", 0, 1);
					SetEntProp(LRClient[1], Prop_Data, "m_takedamage", 0, 1);
				}
				else
				{
					PrintToChatAll("[SM] \x10%N \x01ve \x10%N\x01, Shot4Shot(\x06Deagle\x01) kapışmasına \x0Fbaşladı.", LRClient[0], LRClient[1]);
					int iDeagle = GivePlayerItem(LRClient[0], "weapon_deagle");
					GivePlayerItem(LRClient[0], "weapon_knife");
					SetEntProp(iDeagle, Prop_Data, "m_iClip1", 1);
					SetEntProp(iDeagle, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					SetEntProp(iDeagle, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
					PrintToChatAll("[SM] Atış sırası: \x10%N", LRClient[0]);
					S4S[LRClient[0]] = true;
					S4S[LRClient[1]] = false;
					iDeagle = GivePlayerItem(LRClient[1], "weapon_deagle");
					GivePlayerItem(LRClient[1], "weapon_knife");
					SetEntProp(iDeagle, Prop_Data, "m_iClip1", 0);
					SetEntProp(iDeagle, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					SetEntProp(iDeagle, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
				}
				CreateTimer(0.1, Beamver, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				PrintToChat(client, "[SM] \x07Ufak bir karışıklık oldu. \x10Kapışmak istediğiniz kişiyi tekrar seçin.");
				Gardiyansor().Display(client, 10);
			}
		}
	}
}

public Action Beamver(Handle timer, any data)
{
	if (!LR || !IsValidClient(LRClient[0]) || !IsValidClient(LRClient[1]))
	{
		return Plugin_Stop;
	}
	float aPos[3];
	if (IsValidClient(LRClient[0]))
		GetClientAbsOrigin(LRClient[0], aPos);
	
	aPos[2] += 12.0;
	
	float vPos[3];
	if (IsValidClient(LRClient[1]))
		GetClientAbsOrigin(LRClient[1], vPos);
	
	vPos[2] += 12.0;
	
	TE_SetupBeamPoints(aPos, vPos, g_iBeam, 0, 0, 0, 0.1, 1.0, 1.0, 1, 0.0, { 255, 255, 255, 150 }, 0);
	TE_SendToAll();
	return Plugin_Continue;
}

public Action StartNoScope(Handle timer, int time)
{
	if (!LR)
	{
		return Plugin_Stop;
	}
	if (!IsValidClient(LRClient[0]) || !IsPlayerAlive(LRClient[0]))
	{
		PrintToChatAll("[SM] Terörist bulunamadı ve LR iptal edildi.");
		LR = false;
		return Plugin_Stop;
	}
	else if (!IsValidClient(LRClient[1]) || !IsPlayerAlive(LRClient[1]))
	{
		PrintToChatAll("[SM] Anti-Terörist bulunamadı ve LR iptal edildi.");
		LR = false;
		return Plugin_Stop;
	}
	if (time <= 0)
	{
		SetEntProp(LRClient[0], Prop_Data, "m_takedamage", 2, 1);
		SetEntProp(LRClient[1], Prop_Data, "m_takedamage", 2, 1);
		PrintCenterTextAll("(%N v %N)NoScope LR'si başladı", LRClient[0], LRClient[1]);
		return Plugin_Stop;
	}
	else
	{
		time--;
		PrintCenterTextAll("%d Saniye sonra (%N v %N)NoScope LR'si başlayacak", time, LRClient[0], LRClient[1]);
		CreateTimer(1.0, StartNoScope, time, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
}

public Action WeaponFire(Event event, const char[] name, bool dB)
{
	if (LR && !NsLR)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidClient(client))
		{
			if (!IsValidClient(LRClient[0]) || !IsPlayerAlive(LRClient[0]))
			{
				PrintToChatAll("[SM] Terörist bulunamadı ve LR iptal edildi.");
				LR = false;
			}
			else if (!IsValidClient(LRClient[1]) || !IsPlayerAlive(LRClient[1]))
			{
				PrintToChatAll("[SM] Anti-Terörist bulunamadı ve LR iptal edildi.");
				LR = false;
			}
			else
			{
				if (client == LRClient[0])
				{
					char weapon[16];
					event.GetString("weapon", weapon, 16);
					if (strncmp(weapon, "weapon_deagle", 13, false) == 0)
					{
						if (!S4S[LRClient[0]])
						{
							PrintToChatAll("[SM] \x10%N\x01 hile yaptığı için öldürüldü.", LRClient[0]);
							LR = false;
							ForcePlayerSuicide(LRClient[0]);
						}
						else
						{
							S4S[LRClient[0]] = false;
							S4S[LRClient[1]] = true;
							int deagleindex = GetPlayerWeaponSlot(LRClient[1], CS_SLOT_SECONDARY);
							SetEntProp(deagleindex, Prop_Data, "m_iClip1", 1);
							SetEntProp(deagleindex, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
							SetEntProp(deagleindex, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
							PrintToChatAll("[SM] Atış sırası: \x10%N", LRClient[1]);
							
							CreateTimer(0.4, ResetAmmo, LRClient[0], TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					else if (strncmp(weapon, "weapon_knife", 12, false) != 0)
					{
						PrintToChatAll("[SM] \x10%N\x01 hile yaptığı için öldürüldü.", LRClient[0]);
						LR = false;
						ForcePlayerSuicide(LRClient[0]);
					}
				}
				else if (client == LRClient[1])
				{
					char weapon[16];
					event.GetString("weapon", weapon, 16);
					if (strncmp(weapon, "weapon_deagle", 13, false) == 0)
					{
						if (!S4S[LRClient[1]])
						{
							PrintToChatAll("[SM] \x10%N\x01 hile yaptığı için öldürüldü.", LRClient[1]);
							LR = false;
							ForcePlayerSuicide(LRClient[1]);
						}
						else
						{
							S4S[LRClient[1]] = false;
							S4S[LRClient[0]] = true;
							int deagleindex = GetPlayerWeaponSlot(LRClient[0], CS_SLOT_SECONDARY);
							SetEntProp(deagleindex, Prop_Data, "m_iClip1", 1);
							SetEntProp(deagleindex, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
							SetEntProp(deagleindex, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
							PrintToChatAll("[SM] Atış sırası: \x10%N", LRClient[0]);
							
							CreateTimer(0.4, ResetAmmo, LRClient[1], TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					else if (strncmp(weapon, "weapon_knife", 12, false) != 0)
					{
						PrintToChatAll("[SM] \x10%N\x01 hile yaptığı için öldürüldü.", LRClient[1]);
						LR = false;
						ForcePlayerSuicide(LRClient[1]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action ResetAmmo(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		int deagleindex = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (IsValidEntity(deagleindex))
		{
			SetEntProp(deagleindex, Prop_Data, "m_iClip1", 0);
			SetEntProp(deagleindex, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
			SetEntProp(deagleindex, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
		}
	}
}

public Action StripPlayer(int client, const char[] command, int argc)
{
	if (argc < 1)
	{
		return Plugin_Handled;
	}
	if (strncmp(command, "sm_kick", 7, false) == 0 && !CheckCommandAccess(client, "sm_kick", ADMFLAG_ROOT))
	{
		return Plugin_Handled;
	}
	else if (strncmp(command, "sm_ban", 6, false) == 0 && !CheckCommandAccess(client, "sm_ban", ADMFLAG_ROOT))
	{
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_NO_IMMUNITY, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		int wepIdx;
		for (int a; i < 12; a++)
		{
			while ((wepIdx = GetPlayerWeaponSlot(target_list[i], a)) != -1)
			{
				RemovePlayerItem(target_list[i], wepIdx);
				RemoveEntity(wepIdx);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Command_Respawn(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hrespawn <#userid|name>");
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_DEAD, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		Perform1up(target_list[i]);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t canlandırıldı.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t canlandırıldı.", "_s", target_name);
	}
	
	return Plugin_Handled;
}

void Perform1up(int target)
{
	CS_RespawnPlayer(target);
	if (dcoor[target][0] == 0.0 && dcoor[target][1] == 0.0 && dcoor[target][2] == 0.0)
	{
		LogError("%N: Hrespawn data Unavailable", target);
	}
	else
	{
		TeleportEntity(target, dcoor[target], dangle[target], NULL_VECTOR);
	}
}

public Action OnJoinTeam(int client, const char[] command, int argc)
{
	if (IsValidClient(client))
	{
		char arg[20];
		GetCmdArg(1, arg, 20);
		int number = StringToInt(arg);
		if (number != 2)
		{
			ChangeClientTeam(client, 2);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
	bBasecomm = LibraryExists("basecomm");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "basecomm"))
		bBasecomm = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "basecomm"))
		bBasecomm = true;
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	char Filename[256];
	GetPluginFilename(INVALID_HANDLE, Filename, 256);
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_jail", false) == -1)
			ServerCommand("sm plugins unload %s", Filename);
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_jail", 3, false) != 0)
		ServerCommand("sm plugins unload %s", Filename);
	
	g_iBeam = PrecacheModel("materials/sprites/white.vmt", true);
	PrecacheModel("models/player/custom_player/legacy/tm_jungle_raider_variantc.mdl");
	PrecacheModel("models/player/custom_player/legacy/ctm_st6_variantk.mdl");
}

public void OnClientPostAdminCheck(int client)
{
	FakeClientCommand(client, "jointeam 2");
	SetClientListeningFlags(client, VOICE_MUTED);
	if (bBasecomm)
		BaseComm_SetClientMute(client, true);
}

public Action OnClientSpawn(Event event, const char[] name, bool dB)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int wepIdx;
		for (int i; i < 12; i++)
		{
			while ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, wepIdx);
				RemoveEntity(wepIdx);
			}
		}
		if (GetClientTeam(client) == 3)
		{
			GivePlayerItem(client, "weapon_m4a1");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_knife");
		}
		else if (GetClientTeam(client) == 2)
		{
			GivePlayerItem(client, "weapon_knife");
		}
		SetEntData(client, g_CollisionGroup, 2, 4, true);
	}
}

public Action OnClientDead(Event event, const char[] name, bool dB)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		GetEntPropVector(GetEntPropEnt(client, Prop_Send, "m_hRagdoll"), Prop_Send, "m_vecOrigin", dcoor[client]);
		GetClientAbsAngles(client, dangle[client]);
		if (LR)
		{
			LR = false;
			if (client == LRClient[0] || client == LRClient[1])
			{
				PrintToChatAll("[SM] Kapışma sona erdi, \x10%N\x01 kaybetti.", client);
			}
		}
	}
}

public Action RoundEnd(Event event, const char[] name, bool dB)
{
	int g_WeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
	int maxent = GetMaxEntities();
	char weapon[64];
	for (int i = MaxClients; i < maxent; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, g_WeaponParent) == -1)
				RemoveEntity(i);
		}
	}
	LR = false;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
} 