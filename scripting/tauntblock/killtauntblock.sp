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
    
    Completed: 8/7/2013
**/

#define PLUGIN_NAME     "TF2 Kill Taunt Block"
#define PLUGIN_AUTHOR   "https://github.com/vmuse"
#define PLUGIN_CONTACT  "https://github.com/vmuse/sourcemod"
#define PLUGIN_DESCRIP  "Prevents players from taunting in the replay kill camera"
#define PLUGIN_VERSION  "1.0.4" 

////////////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1

new bool:g_bEnabled;
new Float:g_SpecFreezeTime;
new Float:lastkill[MAXPLAYERS+1];
new bool:hooked;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_NAME,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public OnPluginStart()
{
	CreateConVar("sm_tauntblock_version", PLUGIN_VERSION, "Killcam Taunt Block version.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	decl Handle:cvar;
	HookConVarChange(cvar = CreateConVar("sm_tauntblock_enable", "1", "Prevent Players from Taunting After Kills", FCVAR_PLUGIN), ConVarEnableChanged);
	g_bEnabled = GetConVarBool(cvar);
	
	HookConVarChange(cvar = FindConVar("spec_freeze_time"), ConVarSpecTimeChanged);
	g_SpecFreezeTime = GetConVarFloat(cvar) + 2.0;

	RegConsoleCmd("sm_thriller", Command_Thriller);
	RegAdminCmd("sm_dancefool", Command_ForceTaunt, ADMFLAG_SLAY);
	
	LoadTranslations("common.phrases");
}

public OnMapStart()
{
	for(new i=1; i<=MaxClients; i++)
	{
		lastkill[i] = 0.0;
	}
}

public OnConfigsExecuted()
{
	if (g_bEnabled && !hooked)
	{
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		hooked = true;

		AddCommandListener(Taunt, "+taunt");
		AddCommandListener(Taunt, "taunt");
	}
}

public ConVarEnableChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);

	if (g_bEnabled && !hooked)
	{
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		hooked = true;

		AddCommandListener(Taunt, "+taunt");
		AddCommandListener(Taunt, "taunt");
	}
	else if (!g_bEnabled && hooked)
	{
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		hooked = false;

		RemoveCommandListener(Taunt, "+taunt");
		RemoveCommandListener(Taunt, "taunt");
	}
}

public ConVarSpecTimeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_SpecFreezeTime = StringToFloat(newvalue) + 2.0;
}

public Action:Command_Thriller(client, iAction)
{
	if(g_bEnabled && (lastkill[client] > GetEngineTime()))
	{
		switch(GetRandomInt(0,2))
		{
			case 0: FakeClientCommand(client,"voicemenu 2 2");
			case 1: FakeClientCommand(client,"voicemenu 2 3");
			case 2: FakeClientCommand(client,"voicemenu 0 6");
		}
		return Plugin_Handled;
	}
	if (client && IsPlayerAlive(client) && (GetEntityFlags(client) & FL_ONGROUND) && !TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		TF2_AddCondition(client, TFCond:54, 3.0);
		FakeClientCommand(client, "taunt");
	}
	return Plugin_Handled;
}

public Action:Command_ForceTaunt(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This Command Can Only Be Used From In-Game");
		return Plugin_Handled;
	}
	new String:arg1[32];

	GetCmdArg(1, arg1, sizeof(arg1));

	if (args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dancefool <target> ");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (!TF2_IsPlayerInCondition(target_list[i], TFCond_Taunting))
		{
			Command_Thriller(target_list[i], 0);
			PrintToChat(target_list[i],"[SM]: Dance Fool!");
		}
	}

	return Plugin_Handled;
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_KILLERREVENGE)
	{
		return Plugin_Continue;
	}

	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if(!((StrContains(weapon, "taunt") != -1) ||
				StrEqual(weapon, "armageddon") ||
				StrEqual(weapon, "robot_arm_blender_kill") ||
				StrEqual(weapon, "taunt_guitar_kill") ||
				StrEqual(weapon, "ubersaw")))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		lastkill[attacker] = GetEngineTime() + g_SpecFreezeTime;  // record their last kill
	}
	return Plugin_Continue;
}

public Action:Taunt(client, const String:command[], args)
{
	if(lastkill[client] > GetEngineTime())             // Stop them from taunting
	{
		switch(GetRandomInt(0,2))
		{
			case 0: FakeClientCommand(client,"voicemenu 2 2");
			case 1: FakeClientCommand(client,"voicemenu 2 3");
			case 2: FakeClientCommand(client,"voicemenu 0 6");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}