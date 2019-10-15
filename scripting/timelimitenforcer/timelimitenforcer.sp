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
    
    Completed: 9/24/2014
**/

#define PLUGIN_NAME     "TF2 Time Limit Enforcer"
#define PLUGIN_AUTHOR   "https://github.com/vmuse"
#define PLUGIN_CONTACT  "https://github.com/vmuse/sourcemod"
#define PLUGIN_DESCRIP  "Forces map change regardless of hybernation or external events"
#define PLUGIN_VERSION  "1.0.0" 

////////////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

new Handle:gcvar_TimeLimit;
new Handle:gh_timer;
new g_starttime;

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
	HookConVarChange(gcvar_TimeLimit = FindConVar("mp_timelimit"), TimeLimitChanged);
}

StartTimer()
{
	if(gh_timer != INVALID_HANDLE)
	{
		KillTimer(gh_timer);
	}
	new Float:end = GetConVarFloat(gcvar_TimeLimit);
	if(end != 0.0)																// infinite time
	{
		decl String:mapname[64];
		GetCurrentMap(mapname, 64);
		
		end = ((end * 60.0) - (GetTime() - g_starttime)) + 30.0;
		if(end <= 0)
		{
			PrintToChatAll("[%s] is ending now!", mapname);
			gh_timer = CreateTimer(0.0, Timer_ForceGameEnd, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			PrintToChatAll("[%s] will end in %d minutes", mapname, RoundToNearest(end/60.0));
			gh_timer = CreateTimer(end, Timer_ForceGameEnd, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnMapStart()
{
	gh_timer = INVALID_HANDLE;
}
public OnMapEnd()
{
	gh_timer = INVALID_HANDLE;
}

public TF2_OnWaitingForPlayersEnd()
{
	g_starttime = GetTime();
	StartTimer();
}

public TimeLimitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	if(gh_timer != INVALID_HANDLE)				// don't start a new timer if there isn't one already going.
	{
		StartTimer();
	}
}

public Action:Timer_ForceGameEnd(Handle:timer)
{
	new ent  = FindEntityByClassname(-1, "game_end");
	if (ent == -1)
	{
		ent = CreateEntityByName("game_end")
		if(ent == -1)
		{
			LogError("Could not find and create game_end");
			return Plugin_Continue;
		}
	}

	AcceptEntityInput(ent, "EndGame");										// Game over man, game over
	return Plugin_Continue;
}