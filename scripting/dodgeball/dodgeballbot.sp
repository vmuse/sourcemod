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
    
    Completed: 12/26/2016
**/

#define PLUGIN_NAME     "TF2 Bot Airblast"
#define PLUGIN_AUTHOR   "https://github.com/vmuse"
#define PLUGIN_CONTACT  "https://github.com/vmuse/sourcemod"
#define PLUGIN_DESCRIP  "Allows bots to reflect rocket projectiles and participate in dodgeball game modes"
#define PLUGIN_VERSION  "1.0.0"

////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2items>
#include <tf2_stocks>

#define DUMMYMODEL "models/items/ammopack_small.mdl"
#define SOUND_REFLECT "weapons/flame_thrower_airblast_rocket_redirect.wav"

new Float:gf_skill[3];
new Float:gf_selectedskill;
new Float:gf_defaultskill;

new g_trigger[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
new g_particle[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
new bool:gb_lock;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIP, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_CONTACT
};

public OnPluginStart()
{
	decl Handle:cvar;
	HookConVarChange(cvar = CreateConVar("sm_dbbot_defskill", "0.001", "Default skill level", FCVAR_PLUGIN, true, 0.0), ConVarDefChanged);
	gf_defaultskill = GetConVarFloat(cvar);
	gf_selectedskill = gf_defaultskill;
	HookConVarChange(cvar = CreateConVar("sm_dbbot_lowskill", "0.005", "Easy skill level", FCVAR_PLUGIN, true, 0.0), ConVarLowChanged);
	gf_skill[0] = GetConVarFloat(cvar);
	HookConVarChange(cvar = CreateConVar("sm_dbbot_medskill", "0.001", "Medium skill level", FCVAR_PLUGIN, true, 0.0), ConVarMedChanged);
	gf_skill[1] = GetConVarFloat(cvar);
	HookConVarChange(cvar = CreateConVar("sm_dbbot_hiskill", "0.0001", "Hard skill level", FCVAR_PLUGIN, true, 0.0), ConVarHiChanged);
	gf_skill[2] = GetConVarFloat(cvar);
	
	RegConsoleCmd("sm_votebot", Command_VoteBot);
	HookEvent("post_inventory_application", Event_Resupply);
	
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client))
		{
			CreateTimer(0.0, Timer_CreateDeflectorBot, GetClientUserId(client), TIMER_REPEAT);
		}
	}
	
	CreateTimer(500.0, Timer_Announce);
}

public Action:Timer_Announce(Handle:timer)
{
	PrintToChatAll("[SM]: type /votebot to configure the dodgeball bot\n[SM]: type /ff to configure FFA mode");
}

public ConVarDefChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	gf_selectedskill = StringToFloat(newvalue);
}
public ConVarLowChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	gf_skill[0] = StringToFloat(newvalue);
}
public ConVarMedChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	gf_skill[1] = StringToFloat(newvalue);
}
public ConVarHiChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	gf_skill[2] = StringToFloat(newvalue);
}

public Event_Resupply(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (IsFakeClient(client))
	{
		CreateTimer(0.2, Timer_CreateDeflectorBot, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnMapStart()
{
	gf_selectedskill = gf_defaultskill;
	
	PrecacheModel(DUMMYMODEL, true);
	PrecacheSound(SOUND_REFLECT, true);
}

public OnClientDisconnect(client) // should not be needed, since it's all parented, but just in case we'll clean up stray edicts.
{
	if (IsFakeClient(client))
	{
		new ent = EntRefToEntIndex(g_trigger[client]);
		if (ent != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(ent, "Kill");
		}
		ent = EntRefToEntIndex(g_particle[client]);
		if (ent != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}

public Action:Timer_CreateDeflectorBot(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
		new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
		if (hWeapon != INVALID_HANDLE)		 // create a basic stat weapon with viable attributes
		{
			TF2Items_SetClassname(hWeapon, "tf_weapon_flamethrower");
			TF2Items_SetItemIndex(hWeapon, 659);
			TF2Items_SetLevel(hWeapon, 100);
			TF2Items_SetQuality(hWeapon, 5);
			
			TF2Items_SetAttribute(hWeapon, 0, 181, 2.0);
			TF2Items_SetAttribute(hWeapon, 1, 1, 0.0);
			TF2Items_SetAttribute(hWeapon, 2, 60, 0.0);
			TF2Items_SetAttribute(hWeapon, 3, 76, 2.0);
			TF2Items_SetAttribute(hWeapon, 4, 112, 20.0);
			TF2Items_SetAttribute(hWeapon, 5, 254, 4.0);
			
			TF2Items_SetAttribute(hWeapon, 6, 26, 100.0);	// healh
			TF2Items_SetAttribute(hWeapon, 7, 57, 10.0);	// hp regen
			
			TF2Items_SetNumAttributes(hWeapon, 8);
			
			new weapon = TF2Items_GiveNamedItem(client, hWeapon);
			CloseHandle(hWeapon);
			
			if (IsValidEntity(weapon))
			{
				EquipPlayerWeapon(client, weapon);
			}
		}
		
		SetClientInfo(client, "name", "Pyro Bot"); // the bot's name
		
		new trigger = EntRefToEntIndex(g_trigger[client]);
		if (trigger != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(trigger, "kill");
		}
		new particle = EntRefToEntIndex(g_particle[client]);
		if (particle != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(particle, "Kill");
		}
		
		trigger = CreateEntityByName("trigger_multiple");
		if (trigger != -1)
		{
			decl Float:origin[3];
			GetClientAbsOrigin(client, origin);
			
			DispatchKeyValueVector(trigger, "origin", origin);
			DispatchKeyValue(trigger, "spawnflags", "9"); // 1103 is all the things!
			DispatchSpawn(trigger);
			ActivateEntity(trigger);
			
			AcceptEntityInput(trigger, "Enable");
			
			SetEntityModel(trigger, DUMMYMODEL);
			
			SetEntPropVector(trigger, Prop_Send, "m_vecMins", Float: { -100.0, -100.0, -100.0 } );	// 100 unit bounding box for detection range
			SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", Float: { 100.0, 100.0, 100.0 } );
			
			SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
			SetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity", client);
			
			SetVariantString("!activator");
			AcceptEntityInput(trigger, "SetParent", client);
			
			SetVariantString("flag");
			AcceptEntityInput(trigger, "SetParentAttachment", client);
			
			SDKHook(trigger, SDKHook_StartTouch, OnTouchRocket);
			
			g_trigger[client] = EntIndexToEntRef(trigger);
			
			particle = CreateEntityByName("info_particle_system");
			if (particle != -1)
			{
				DispatchKeyValue(particle, "effect_name", "pyro_blast");
				
				DispatchSpawn(particle);
				ActivateEntity(particle);
				
				g_particle[client] = EntIndexToEntRef(particle);
			}
		}
	}
}

public Action:OnTouchRocket(brush, entity)
{
	if (entity > MaxClients)
	{
		decl String:classname[21]; // it's either this or use entrefs + adt + onentitycreated
		if (GetEntityClassname(entity, classname, 21) && StrEqual(classname, "tf_projectile_rocket"))
		{
			new client = GetEntPropEnt(brush, Prop_Send, "m_hOwnerEntity"); // this should always always always be valid, because it's a bot, and it's parented to the bot, but I'll check it anyways.
			if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) // this will make sure they're not dead too
			{
				new clientteam = GetClientTeam(client);
				if (GetEntProp(entity, Prop_Send, "m_iTeamNum") != clientteam)
				{
					if (gf_selectedskill)
					{
						decl Float:velocity[3];
						GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", velocity);
						new deflections = GetEntProp(entity, Prop_Send, "m_iDeflected");
						if (!deflections || (GetVectorLength(velocity) * deflections * gf_selectedskill) >= 1.0)	// increase velocity based on how many times it has been passed
						{
							DeflectRocket(client, entity, clientteam, deflections);
						}
					}
					else
					{
						DeflectRocket(client, entity, clientteam, GetEntProp(entity, Prop_Send, "m_iDeflected"));
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_StopParticle(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Stop");
	}
}

DeflectRocket(client, rocket, clientteam, deflections)
{
	decl Float:velocity[3];
	GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", velocity);
	new Float:speed = GetVectorLength(velocity);
	
	decl Float:origin[3], Float:angles[3], Float:fwd[3];
	
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(rocket, Prop_Send, "m_iTeamNum", clientteam);
	SetEntProp(rocket, Prop_Send, "m_iDeflected", deflections + 1);
	GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", origin);
	
	new target = FindBestTarget(rocket, origin, clientteam);
	if (target)
	{
		decl Float:targetpos[3];
		GetClientAbsOrigin(target, targetpos);
		
		SubtractVectors(targetpos, origin, targetpos);
		NormalizeVector(targetpos, targetpos);
		
		GetVectorAngles(targetpos, angles);
	}
	else
	{
		GetClientEyeAngles(client, angles); // shoot in the dark
		angles[0] += GetRandomFloat(0.0, 25.0);
		angles[1] += GetRandomFloat(-45.0, 45.0);
	}
	
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	velocity[0] = fwd[0] * speed;
	velocity[1] = fwd[1] * speed;
	velocity[2] = fwd[2] * speed;
	
	TeleportEntity(rocket, NULL_VECTOR, angles, velocity);
	
	new Handle:event = CreateEvent("object_deflected");
	if (event != INVALID_HANDLE)
	{
		SetEventInt(Handle:event, "userid", GetClientUserId(client));
		SetEventInt(Handle:event, "object_entindex", rocket);
		FireEvent(event);
	}
	
	new ent = EntRefToEntIndex(g_particle[client]);
	if (ent != INVALID_ENT_REFERENCE)
	{
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll(SOUND_REFLECT, ent);
		
		AcceptEntityInput(ent, "start");
		CreateTimer(0.3, Timer_StopParticle, g_particle[client], TIMER_FLAG_NO_MAPCHANGE);
	}
}

FindBestTarget(rocket, Float:origin[3], clientteam) // homing somewhat borrowed from RTDv.4
{
	decl Float:clientpos[3];
	decl Float:distance;
	
	new target;
	new Float:best = 99999.9;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidTarget(i, rocket, origin, clientteam))
		{
			GetClientEyePosition(i, clientpos);
			distance = GetVectorDistance(origin, clientpos);
			
			if (distance < best)
			{
				target = i;
				best = distance;
			}
		}
	}
	
	return target;
}

bool:IsValidTarget(client, rocket, Float:origin[3], clientteam)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != clientteam)
	{
		decl Float:clientpos[3];
		GetClientEyePosition(client, clientpos);
		
		new Handle:hTrace = TR_TraceRayFilterEx(clientpos, origin, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, rocket);
		if (hTrace != INVALID_HANDLE)
		{
			if (TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
				return false;
			}
			
			CloseHandle(hTrace);
			return true;
		}
	}
	
	return false;
}

public bool:TraceFilterHoming(entity, contentsMask, any:rocket) // we want to hit everything except clients and the missile itself
{
	if (entity == rocket || (entity >= 1 && entity <= MaxClients))
	{
		return false;
	}
	
	return true;
}

public OnMapEnd()
{
	RemoveBots();
}

public OnPluginEnd()
{
	RemoveBots();
}

public Action:Command_VoteBot(client, args)
{
	if (IsVoteInProgress())
	{
		return Plugin_Handled;
	}
	if (gb_lock)
	{
		ReplyToCommand(client, "[SM]: Please wait before starting another vote.");
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(Handle_VoteBot);
	SetMenuTitle(menu, "Dodgeball Bot?");
	AddMenuItem(menu, "Easy", "Easy");
	AddMenuItem(menu, "Medium", "Medium");
	AddMenuItem(menu, "Hard", "Hard");
	AddMenuItem(menu, "Insane", "Insane");
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "Disabled", "Disable");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
	
	gb_lock = true;
	CreateTimer(120.0, Timer_Unlock);
	
	return Plugin_Handled;
}

public Action:Timer_Unlock(Handle:timer)
{
	gb_lock = false;
}

public Handle_VoteBot(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_VoteEnd)
	{
		decl String:selection[10];
		GetMenuItem(menu, param1, selection, 10);
		
		if (StrEqual(selection, "Easy"))
		{
			gf_selectedskill = gf_skill[0];
			SpawnBots(1);
		}
		else if (StrEqual(selection, "Medium"))
		{
			gf_selectedskill = gf_skill[1];
			SpawnBots(2);
		}
		else if (StrEqual(selection, "Hard"))
		{
			gf_selectedskill = gf_skill[2];
			SpawnBots(2);
		}
		else if (StrEqual(selection, "Insane"))
		{
			gf_selectedskill = 0.0;
			SpawnBots(1);
		}
		else
		{
			strcopy(selection, 10, "Disabled");
			RemoveBots();
		}
		PrintToChatAll("Dodgeball bot set to: %s", selection);
	}
}

SpawnBots(count)
{
	SetConVarInt(FindConVar("tf_bot_quota"), count); // assuming tf_bot_quota_mode "normal"
	SetConVarString(FindConVar("tf_bot_quota_mode"), "normal");
	SetConVarString(FindConVar("mp_humans_must_join_team"), "blue");
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0); // without this, humans won't get pushed to the same team, and they'll have to sit out, you'll probably want this disabled anyways.
	SetConVarBool(FindConVar("mp_scrambleteams_auto"), false); // we don't want the teams to scramble while vs bot is active
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i))
		{
			if (!IsFakeClient(i))
			{
				ChangeClientTeam(i, 3);
			}
			else
			{
				ChangeClientTeam(i, 2);
			}
		}
	}
}

RemoveBots()
{
	SetConVarInt(FindConVar("tf_bot_quota"), 0);
	SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
	SetConVarBool(FindConVar("mp_scrambleteams_auto"), true);
} 