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
    
    Completed: 10/2/2014
**/

#define PLUGIN_NAME     "TF2 Snowball Fight"
#define PLUGIN_AUTHOR   "https://github.com/vmuse"
#define PLUGIN_CONTACT  "https://github.com/vmuse/sourcemod"
#define PLUGIN_DESCRIP  "Allows players to throw snowballs at eachother"
#define PLUGIN_VERSION  "1.0.0" 

////////////////////////////////////////////////////////////////////////

#include <sourcemod> 
#include <sdkhooks>  
#include <tf2_stocks> 
#include <legacy_custom_stocks>
#include <godmode>

#undef REQUIRE_PLUGIN
#include <tf2attributes>

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIP,
    version = PLUGIN_VERSION,
    url = PLUGIN_CONTACT
};

#define FFADE_OUT	0x0002        // Fade out (not in)

#define TIMERPULSEHUD 1.0
#define HUDX1        -0.2
#define HUDY1        -0.05

#define MODEL_SNOWBALL	"models/weapons/w_models/w_baseball.mdl"
#define SOUND_THROW		"weapons/slam/throw.wav"
#define SNOWBALL_HIT	"player/pl_pain7.wav"

#define MAX_SNOWBALLS		3		// max snowballs a player can have
#define SNOWBALL_GAIN_TIME	1		// # of snowballs to give on timer
#define SNOWBALL_TIME_CD	30		// time between giving snowballs
//#define SNOWBALL_GAIN_KILL	2		// # of snowballs gained on a kill
#define SNOWBALL_START		60		// ticks for freezing players, more is longer
#define SNOWBALL_VISUAL     2000	// length to display fade
#define SNOWBALL_LIFE		1.5

#define THROW_DISTANCE		40.0	// forward offset
#define THROW_FORCE			1400.0	// throw speed

#define MIN_SNOWBALL_SPEED	1000.0	// min speed on hit to freeze
#define KNOCKBACK_RATIO		0.5		// how much force to knock back airborne
#define SNOWBALL_DAMAGE		2.0

#define SNOWBALL_FIGHT		300
#define SNOWBALL_COOLDOWN	1.0		// throw delay

new g_freeze[MAXPLAYERS + 1];
new g_snowballs[MAXPLAYERS + 1];
new g_lastsnowball[MAXPLAYERS+1];
new bool:gb_alert[MAXPLAYERS+1];
new g_fight;

new bool:g_bTF2Atrributes;

new Handle:g_hHUD;

new bool:g_bGodmode = false;

public OnPluginStart()
{
	g_hHUD = CreateHudSynchronizer();
	
	#if defined SNOWBALL_GAIN_KILL
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	#endif

	RegAdminCmd("sm_snowballfight", Command_Fight, ADMFLAG_SLAY, "Start a snowball fight");
	
	AddCommandListener(Listener_Voice, "voicemenu");
	
	CreateTimer(0.1, Timer_Snowball, _, TIMER_REPEAT);
	CreateTimer(0.3, Timer_HUD, _, TIMER_REPEAT);
	
	g_bTF2Atrributes = LibraryExists("tf2attributes");
	
	g_bGodmode = LibraryExists("godmode");
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientConnected(client))
		{
			 OnClientConnected(client);	
		}
	}
}

public OnLibraryAdded(const String:name[])
{
    if(StrEqual(name, "godmode"))
    {
        g_bGodmode = true;
    }
    else if (StrEqual(name, "tf2attributes"))
	{
		g_bTF2Atrributes = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
    if(StrEqual(name, "godmode"))
    {
        g_bGodmode = false;
    }
	else if (StrEqual(name, "tf2attributes"))
	{
		g_bTF2Atrributes = false;
	}
}

public Action:Command_Fight(client, args)
{
	g_fight = GetTime() + SNOWBALL_FIGHT;
	
	PrintToChatAll("\x04%[Snowballs]\x01: A \x073677A9snowball \x01fight has begun!");	
	
	return Plugin_Handled;
}

public OnMapStart()
{
	PrecacheModel(MODEL_SNOWBALL);
	PrecacheSound(SOUND_THROW);
	PrecacheSound(SNOWBALL_HIT);
}

public OnClientConnected(client)
{
	g_snowballs[client] = 0;
	g_freeze[client] = 0;
	g_lastsnowball[client] = GetTime() + SNOWBALL_TIME_CD;
	gb_alert[client] = false;
}

ShowAlert(client)
{
	if(!gb_alert[client])
	{
		gb_alert[client] = true;
		PrintToChat(client, "\x04%[Snowballs]\x01: Call for medic to throw your \x073677A9snowballs");	
	}
}

public OnClientDisconnect(client)
{
	g_snowballs[client] = 0;
	g_freeze[client] = 0;
}

public Action:Timer_HUD(Handle:timer)
{
	static time;
	static timeleft;
	
	time = GetTime();
	
	timeleft = g_fight - time;
	if(timeleft > 0)
	{
		SetHudTextParams(HUDX1, HUDY1, TIMERPULSEHUD, 0, 255, 0, 255);
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client))
			{
				g_snowballs[client] = MAX_SNOWBALLS;
				
				if (g_snowballs[client] > MAX_SNOWBALLS)
				{
					g_snowballs[client] = MAX_SNOWBALLS;
				}
					
				ShowAlert(client);
				
				ShowSyncHudText(client, g_hHUD, "Snowball Fight: %d", timeleft);
			}
		}
	}
	else
	{
		SetHudTextParams(HUDX1, HUDY1, TIMERPULSEHUD, 0, 255, 0, 255);
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client))
			{
				if(g_lastsnowball[client] < time)
				{
					g_lastsnowball[client] = time + SNOWBALL_TIME_CD
					g_snowballs[client] += SNOWBALL_GAIN_TIME;
					
					if (g_snowballs[client] > MAX_SNOWBALLS)
					{
						g_snowballs[client] = MAX_SNOWBALLS;
					}
					
					ShowAlert(client);
				}

				ShowSyncHudText(client, g_hHUD, "Snowballs: %d/%d", g_snowballs[client], MAX_SNOWBALLS);	
			}
		}
	}
}

#if defined SNOWBALL_GAIN_KILL
public Action:Event_Death(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (attacker > 0 && IsClientInGame(attacker))
	{
		new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (client && IsClientInGame(client))
		{
			g_snowballs[client] = 0;
			
			g_snowballs[attacker] += SNOWBALL_GAIN_KILL;
			
			ShowAlert(attacker)

			if (g_snowballs[attacker] > MAX_SNOWBALLS)
			{
				g_snowballs[attacker] = MAX_SNOWBALLS;
			}
		}
	}
	
	return Plugin_Continue;
}
#endif

public Action:Listener_Voice(client, const String:command[], argc)
{
	static Float:lastthrow[MAXPLAYERS+1];

	if (g_snowballs[client])
	{
		if(g_bGodmode && IsClientGodmode(client))
		{
			PrintToChat(client, "Invulnerable players can not throw snowballs!");
		
			return Plugin_Continue;
		}

		new String:szBuffer[16];
		GetCmdArg(1, szBuffer, sizeof(szBuffer));
		if (StringToInt(szBuffer) == 0)
		{
			GetCmdArg(2, szBuffer, sizeof(szBuffer));
			if (StringToInt(szBuffer) == 0)
			{
				if (IsPlayerAlive(client) &&
					!TF2_IsPlayerInCondition(client, TFCond_Dazed) &&
					!TF2_IsPlayerInCondition(client, TFCond_Cloaked) &&
					!TF2_IsPlayerInCondition(client, TFCond_Taunting))
				{
					new Float:time = GetEngineTime();
					if(lastthrow[client] < time)
					{
						lastthrow[client] = time + SNOWBALL_COOLDOWN;
						
						g_snowballs[client]--;
						
						TF2_RemoveCondition(client, TFCond_Disguised);
						
						ThrowSnowBall(client)
					}
					
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Snowball(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (g_freeze[client] > 0)
		{
			g_freeze[client]--;
			
			if (IsClientInGame(client))
			{
				if (!g_freeze[client])
				{
					SetEntityRenderColor(client, 255, 255, 255, 255);
				
					if (g_bTF2Atrributes)
					{
						TF2Attrib_RemoveByName(client, "move speed penalty");
						
						if(IsPlayerAlive(client))
						{
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
						}
					}
				}
				else
				{
					if (IsPlayerAlive(client))
					{
						new Float:ratio = 1 - (g_freeze[client] / SNOWBALL_START.0);
						new fade = RoundToNearest(255 * ratio);
						SetEntityRenderColor(client, fade, fade, 255, 255);
						
						if (g_bTF2Atrributes)
						{
							TF2Attrib_SetByName(client, "move speed penalty", ratio);
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
						}
					}
					else
					{
						g_freeze[client] = 1;
					}
				}
			}
		}
	}
}

ThrowSnowBall(client)
{
	new entity = CreateEntityByName("prop_physics_multiplayer"); // i don't know where this arc vector code is from...
	if (entity != -1)
	{
		decl Float:pos[3], Float:angs[3], Float:vecs[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, angs);
		angs[0] -= 10.0;	// elevate
		GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
		pos[0] += vecs[0] * 32.0 ;
		pos[1] += vecs[1] * 32.0 ;
		pos[2] += vecs[2] * 32.0 ;
		ScaleVector(vecs, THROW_FORCE);

		DispatchKeyValueVector(entity, "origin", pos);
		DispatchKeyValueVector(entity, "angles", Float:{0.0,0.0,0.0});
		DispatchKeyValue(entity, "model", MODEL_SNOWBALL);
		DispatchKeyValue(entity, "massScale", "1.0");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "spawnflags", "12288");
		
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 144, 144, 255, 180);
		
		DispatchSpawn(entity);
		ActivateEntity(entity);
		
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vecs);
		
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8); // Fire trigger even if not solid (8)
		
		SDKHook(entity, SDKHook_StartTouch, ProjectileTouchHook); // force projectile to deal damage on touch

		CreateTimer(SNOWBALL_LIFE, Timer_DestroySnowball, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		
		EmitSoundToAll(SOUND_THROW, client);
	}
}

public Action:Timer_DestroySnowball(Handle:timer, any:ref)
{
	static Float:snowballpos[3];
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", snowballpos);

		EmitAmbientSound(SNOWBALL_HIT, snowballpos);

		TE_Particle("xms_snowburst_child02", snowballpos);
		TE_Particle("spell_batball_impact_blue", snowballpos);
				
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:ProjectileTouchHook(entity, other)
{
	static Float:clientpos[3]
	static Float:snowballpos[3];

	if (other > 0 && other <= MaxClients)
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (client && IsClientInGame(client))
		{
			if (other == client || GetClientTeam(other) == GetClientTeam(client))
			{
				return Plugin_Handled; // skip friendly
			}
			
			decl Float:vel[3];
			if(!GetSmoothVelocity(entity, vel))
			{
				GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vel);
			}

			new Float:speed = GetVectorLength(vel);
			if (speed > MIN_SNOWBALL_SPEED)
			{
				if (IsClientInGame(other) && IsPlayerAlive(other))
				{
					g_freeze[other] = SNOWBALL_START;

					GetClientAbsOrigin(other, clientpos);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", snowballpos);
					
					EmitAmbientSound(SNOWBALL_HIT, snowballpos);

					TE_Particle("xms_snowburst_child02", snowballpos);
					TE_Particle("spell_batball_impact_blue", snowballpos);
					
					if(!(GetEntityFlags(other) & FL_ONGROUND))
					{
						//snowballpos[2] = clientpos[2] - 5.0;
						
						MakeVectorFromPoints(snowballpos, clientpos, clientpos);
						NormalizeVector(clientpos, clientpos);
						
						ScaleVector(clientpos, speed * KNOCKBACK_RATIO);
						
						SetEntPropEnt(other, Prop_Send, "m_hGroundEntity", -1);
						TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, clientpos);
					}
					
					SDKHooks_TakeDamage(other, client, client, SNOWBALL_DAMAGE);
		
					sendfade(other); // fade
					
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
	}

	return Plugin_Continue;
} 

stock sendfade(client)
{
	new Handle:fademsg;
	
	if (client == 0)
		fademsg = StartMessageAll("Fade");
	else
		fademsg = StartMessageOne("Fade", client);
	
	BfWriteShort(fademsg, SNOWBALL_VISUAL/3);
	BfWriteShort(fademsg, SNOWBALL_VISUAL);
	BfWriteShort(fademsg, 0x0001);
	BfWriteByte(fademsg, 70);
	BfWriteByte(fademsg, 175);
	BfWriteByte(fademsg, 210);
	BfWriteByte(fademsg, 100);
	EndMessage();
}