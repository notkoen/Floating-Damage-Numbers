#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

// Uncomment to use Vauff's DynamicChannels plugin (https://github.com/Vauff/DynamicChannels)
// #define DYNAMIC_CHANNELS
#if defined DYNAMIC_CHANNELS
#include <DynamicChannels>
#endif

ConVar g_cvChannel;

Cookie g_hCookie;
bool g_bDisplay[MAXPLAYERS+1] = {true, ...};

public Plugin myinfo =
{
	name = "Floating Damage Numbers",
	author = "koen",
	description = "",
	version = "",
	url = "https://github.com/notkoen"
};

public void OnPluginStart()
{
	g_cvChannel = CreateConVar("sm_dmgnumber_channel", "0", "Channel to display floating damage numbers on", _, true, 0.0, true, 5.0);
	AutoExecConfig(true);

	RegConsoleCmd("sm_damagenumbers", Command_Toggle, "Toggle floating damage number display");
	RegConsoleCmd("sm_showdamage", Command_Toggle, "Toggle floating damage number display");

	SetCookieMenuItem(CookieHandler, INVALID_HANDLE, "Damage Numbers");
	g_hCookie = RegClientCookie("floating_damage_numbers", "Floating damage number HUD", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}

	HookEvent("player_hurt", Event_PlayerHurt);
}

//--------------------------------------------------
// Purpose: Reset client settings on disconnect
//--------------------------------------------------
public void OnClientDisconnect(int client)
{
	g_bDisplay[client] = true;
}

//--------------------------------------------------
// Purpose: Cookie menu handler
//--------------------------------------------------
public void CookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			Format(buffer, maxlen, "Damage Numbers: %s", g_bDisplay[client] ? "On" : "Off");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleDisplay(client);
			ShowCookieMenu(client);
		}
	}
}

//--------------------------------------------------
// Purpose: Toggle display command callback
//--------------------------------------------------
public Action Command_Toggle(int client, int args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	ToggleDisplay(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Purpose: Toggle display function
//--------------------------------------------------
public void ToggleDisplay(int client)
{
	g_bDisplay[client] = !g_bDisplay[client];
	PrintToChat(client, " \x04[SM] \x01Floating damage number display is now %s", g_bDisplay[client] ? "\x04enabled" : "\x07disabled");
	SaveClientCookies(client);
}

//--------------------------------------------------
// Purpose: Cookie functions
//--------------------------------------------------
public void OnClientCookiesCached(int client)
{
	char buffer[4];
	GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));

	if (buffer[0] == '\0')
	{
		g_bDisplay[client] = true;
		SaveClientCookies(client);
		return;
	}

	g_bDisplay[client] = StrEqual(buffer, "1");
}

public void SaveClientCookies(int client)
{
	char buffer[4];
	Format(buffer, sizeof(buffer), "%b", g_bDisplay[client]);
	SetClientCookie(client, g_hCookie, buffer);
}

//--------------------------------------------------
// Purpose: Cookie functions
//--------------------------------------------------
public void Event_PlayerHurt(Handle event, const char[] name, bool broadcast)
{
	// This is somewhat of an optimization. Grenades can damage multiple people,
	// so displaying damage for each person hit can cause some performance degradation
	char buffer[32];
	GetEventString(event, "damage", buffer, sizeof(buffer));
	if (StrEqual(buffer, "hegrenade"))
	{
		return;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsClientInGame(attacker))
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(attacker))
	{
		return;
	}

	if (attacker == victim)
	{
		return;
	}

	if (!g_bDisplay[attacker])
	{
		return;
	}

	int hitgroup = GetEventInt(event, "hitbroup");
	int health = GetEventInt(event, "health");
	int damage = GetEventInt(event, "dmg_health");

	float fPos[2];
	fPos[0] += 0.43 + GetRandomFloat(0.00, 0.02);
	fPos[1] += 0.43 + GetRandomFloat(0.00, 0.02);

	if (health == 0)
	{
		SetHudTextParams(fPos[0], fPos[1], 0.1, 255, 0, 0, 255, 1);
		#if defined DYNAMIC_CHANNELS
		ShowHudText(attacker, GetDynamicChannel(g_cvChannel.IntValue), "%d", damage);
		#else
		ShowHudText(attacker, g_cvChannel.IntValue, "%d", damage);
		#endif
		return;
	}

	if (hitgroup == 1)
	{
		SetHudTextParams(fPos[0], fPos[1], 0.1, 255, 255, 0, 255, 1);
		#if defined DYNAMIC_CHANNELS
		ShowHudText(attacker, GetDynamicChannel(g_cvChannel.IntValue), "%d", damage);
		#else
		ShowHudText(attacker, g_cvChannel.IntValue, "%d", damage);
		#endif
		return;
	}

	SetHudTextParams(fPos[0], fPos[1], 0.1, 255, 255, 255, 255, 1);
	#if defined DYNAMIC_CHANNELS
	ShowHudText(attacker, GetDynamicChannel(g_cvChannel.IntValue), "%d", damage);
	#else
	ShowHudText(attacker, g_cvChannel.IntValue, "%d", damage);
	#endif
	return;
}