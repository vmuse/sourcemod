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
    
    Completed: 11/16/2013
    
    This utility periodacally dumps all valid edicts to a text file when the edict table is nearly full.
    This provides some very basic information to diagnose trouble plugins / maps.
**/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

new String:logfile[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	RegAdminCmd("sm_dumpedicts", dumpedicts_cmd, ADMFLAG_RCON);
	RegAdminCmd("sm_edicts", edicts_cmd, ADMFLAG_SLAY);
	
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/edicts.log");
}

public OnMapStart()
{
	CreateTimer(10.0, Timer_CheckEdicts, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_CheckEdicts(Handle:timer)
{
	if(GetEntityCount() > 1950)
	{
		dumpedicts();
		SetFailState("Automated dump (too many edicts).");
	}
}

public Action:dumpedicts_cmd(client, args)
{
	dumpedicts();
	ReplyToCommand(client, "Edicts Dumped: %d", GetEntityCount());
	return Plugin_Handled;
}

public Action:edicts_cmd(client, args)
{
	if(client && IsClientInGame(client))
	{
		new count;
		for(new i; i<2048; i++)
		{
			if(IsValidEntity(i))
			{
				count++;
			}
		}
		PrintHintText(client, "Edicts: %d, MaxEdicts: %d", count, GetEntityCount());
	}
	return Plugin_Handled;
}

dumpedicts()
{
	new String:classname[64];
	new count;

	GetCurrentMap(classname, 64);
	LogToFile(logfile,"\n\nEntity Dump for map: %s (%d)", classname, GetEntityCount());

	for(new i; i<2048; i++)
	{
		if(IsValidEntity(i) && GetEntityClassname(i, classname, 64))
		{
			LogToFile(logfile,"%d - %s", i, classname);
			count++;
		}
	}
	LogToFile(logfile,"Active Entities: %d -------------------------------------------------------------", count);
}