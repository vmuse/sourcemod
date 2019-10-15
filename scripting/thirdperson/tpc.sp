/**
	Now on GitHub
	https://github.com/vmuse/sourcemod
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Completed: 1/2/2015
**/

#define PLUGIN_NAME     "TF2 Third Person"
#define PLUGIN_AUTHOR   "https://github.com/vmuse"
#define PLUGIN_CONTACT  "https://github.com/vmuse/sourcemod"
#define PLUGIN_DESCRIP  "Allows players to permanently enable third person"
#define PLUGIN_VERSION  "1.3.5" 

////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <tf2>

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIP,
    version = PLUGIN_VERSION,
    url = PLUGIN_CONTACT
};

new Handle:clientcookie = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:thirdperson[MAXPLAYERS + 1];
new bool:storecookies[MAXPLAYERS + 1];                              // Saving flag.
new bool:hooked;

public OnPluginStart()
{
	CreateConVar("sm_tpcookie_version", PLUGIN_VERSION, "TF2 Thirdperson Cookies Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	new Handle:hCvarEnabled;
	HookConVarChange(hCvarEnabled = CreateConVar("sm_tpcookie_enabled", "1.0", "Enable/Disable Plugin [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(hCvarEnabled);
	
	RegConsoleCmd("sm_thirdperson", Command_TpOn, "Usage: sm_thirdperson");
	RegConsoleCmd("tp", Command_TpOn, "Usage: sm_thirdperson");

	RegConsoleCmd("sm_firstperson", Command_TpOff, "Usage: sm_firstperson");
	RegConsoleCmd("fp", Command_TpOff, "Usage: sm_firstperson");

	clientcookie = RegClientCookie("tp_cookie", "", CookieAccess_Private);

	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && AreClientCookiesCached(client))
		{
			retrieveClientCookies(client);
			SetEntProp(client, Prop_Send, "m_nForceTauntCam", thirdperson[client]);
		}
	}
}

public OnMapStart()
{
	if (g_bEnabled && !hooked)
	{
		HookEvent("player_spawn", player_spawn);
		HookEvent("player_class", player_spawn);
		hooked = true;
	}
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = bool:StringToInt(newvalue);
	
	if (g_bEnabled && !hooked)
	{
		HookEvent("player_spawn", player_spawn);
		HookEvent("player_class", player_spawn);
		hooked = true;
	}
	else if (!g_bEnabled && hooked)
	{
		UnhookEvent("player_spawn", player_spawn);
		UnhookEvent("player_class", player_spawn);
		hooked = false;

		for (new client=1; client<=MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
			}  
		}
	}
}

public OnPluginEnd()                                                      // End everyone's third person
{
	for (new client=1; client<=MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
		}
	}
}

public OnClientCookiesCached(client)
{
	if (!IsFakeClient(client))
	{
		retrieveClientCookies(client);
	}
}

retrieveClientCookies(client)                                       // gets the client's cookie, or creates a new one
{
	decl String:cookie[2];

	GetClientCookie(client, clientcookie, cookie, sizeof(cookie));

	if (cookie[0] == '\0')                                        // They're new, fix them
	{
		SetClientCookie(client, clientcookie, "0");
		thirdperson[client] = false;
	}
	else
	{
		thirdperson[client] = bool:StringToInt(cookie);
	}
}

public OnClientConnected(client)
{
	storecookies[client] = false;
	thirdperson[client] = false;
}

public OnClientDisconnect(client)
{
	storeClientCookies(client);
}

storeClientCookies(client)                                                               // stores client's cookie
{
	if(storecookies[client] && AreClientCookiesCached(client))                                               // make sure DB isn't being slow
	{
		decl String:cookie[2];

		IntToString(thirdperson[client], cookie, 2);
		SetClientCookie(client, clientcookie, cookie);

		storecookies[client] = false;
	}
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if(!IsFakeClient(client))												// ignore bots, they don't need client pref entries
	{
		storeClientCookies(client);

		if (thirdperson[client])
		{
			SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
			RequestFrame(Frame_SetThirdPerson, userid);
		}
	}
}

public Frame_SetThirdPerson(any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_nForceTauntCam", 1);
	}
}

public Action:Command_TpOn(client, args)
{
	if (IsClientInGame(client))
	{
		if (!CheckCommandAccess(client,"sm_thirdperson",0))
		{
			PrintToChat(client, "[SM] No Access");
			
			return Plugin_Handled;
		}
		if (!g_bEnabled)
		{
			PrintToChat(client, "[SM] Third Person is not Enabled at this Time.");

			return Plugin_Handled;
		}

		thirdperson[client] = true;
		storecookies[client] = true;
		SetEntProp(client, Prop_Send, "m_nForceTauntCam", 1);
	}

	return Plugin_Handled;
}

public Action:Command_TpOff(client, args)
{
	if (IsClientInGame(client))
	{
		if (!CheckCommandAccess(client,"sm_thirdperson",0))
		{
			PrintToChat(client, "[SM] No Access");

			return Plugin_Handled;
		}
		if (!g_bEnabled)
		{
			PrintToChat(client, "[SM] Third Person is not Enabled at this Time.");

			return Plugin_Handled;
		}

		thirdperson[client] = false;
		storecookies[client] = true;

		SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
	}

	return Plugin_Handled;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(thirdperson[client] && condition == TFCond_Zoomed)
	{
		SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(thirdperson[client] && condition == TFCond_Zoomed)
	{
		SetEntProp(client, Prop_Send, "m_nForceTauntCam", 1);
	}
}