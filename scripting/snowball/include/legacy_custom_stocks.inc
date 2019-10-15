#if defined _legacycustomstocks_included
#endinput
#endif
#define _legacycustomstocks_included

#include <tf2_stocks>

#if defined _EquipWearable_included
#else
#define _EquipWearable_included
stock TF2_EquipWearable(client, wearable)
{
	static Handle:equipwearable = INVALID_HANDLE;
	if (equipwearable == INVALID_HANDLE)
	{
		new Handle:hGameConfigtemp = LoadGameConfigFile("equipwearable");
		if (hGameConfigtemp == INVALID_HANDLE)
		{
			LogError("Equipwearable Gamedata could not be found");
			return;
		}
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConfigtemp, SDKConf_Virtual, "EquipWearable");
		CloseHandle(hGameConfigtemp);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if ((equipwearable = EndPrepSDKCall()) == INVALID_HANDLE)
		{
			LogError("Couldn't load SDK functions (CTFPlayer::EquipWearable). SDK call failed.");
			return;
		}
	}
	
	SDKCall(equipwearable, client, wearable);
}
#endif

stock bool:GetSmoothVelocity(entity, Float:vec[3])
{
	static Handle:hgetsmoothedvel = INVALID_HANDLE;
	if (hgetsmoothedvel == INVALID_HANDLE)
	{
		new Handle:hConfig = LoadGameConfigFile("smoothedvelocity");
		if (hConfig == INVALID_HANDLE)
		{
			LogError("Couldn't load SDK functions (GetSmoothedVelocity). Make sure smoothedvelocity.txt is in your gamedata folder! Restart server if you want projectile physics.");
			return false;
		}
		
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Virtual, "GetSmoothedVelocity");
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		CloseHandle(hConfig);
		
		if ((hgetsmoothedvel = EndPrepSDKCall()) == INVALID_HANDLE)
		{
			LogError("Couldn't load SDK functions (GetSmoothedVelocity). SDK call failed.");
			return false;
		}
	}
	
	SDKCall(hgetsmoothedvel, entity, vec);
	return true;
}

////////////////////////////////////// TRACE //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define MASK_CUSTOMHULLFILTER_RED MASK_PLAYERSOLID|CONTENTS_TEAM1
#define MASK_CUSTOMHULLFILTER_BLUE MASK_PLAYERSOLID|CONTENTS_TEAM2
#define MASK_CUSTOMHULLFILTERTEAMS MASK_PLAYERSOLID|CONTENTS_TEAM1|CONTENTS_TEAM2
#define PLAYERXY		120																// Distance to move players from origin of other players along the X/Y axis  49
#define PLAYERZ		75																// Height to raise on second iteration set
/**
public bool:TraceEntityFilterPlayer(entity, contentsMask)								// false for clients and entity
public bool:TraceRayDontHitSelf(entity, mask, any:data)									// false for entity
public bool:TraceEntityFilterTeamPlayers(entity, contentsMask, any:team)					// false for clients on team
public bool:TraceRayDontHitClients(entity, contentsMask)									// false for clients
public bool:TraceRayFilterClients(entity, mask, any:data)								// false only for clients not matching entity

stock bool:HullTeleport(client, Float:distance)											// teleport client to view with X distance (0.0 = infinite)
stock bool:HullTeleportOther(client, other, Float:distance)								// teleport other to client's view
stock TeleportToPlayer(client, target)													// teleport client to target player

stock bool:FindEndTeleportPositionEx(client, Float:clientpos[3])                             // also tests if player can stand at location
stock bool:FindEndTeleportPosition(client, Float:clientpos[3])							// returns vecs and true if valid position is found
stock bool:FindEndTeleportPositionVecs(client, Float:clientpos[3])						// returns vecs and true if valid position is found, uses client's bounding box size for tracefilter
stock bool:FindEndTeleportPositionFilter(client, Float:clientpos[3], entity)                // passes an entity to filter out

stock bool:CanFitHere(Float:clientpos[3], clientteam)									// test if a player can fit at a destination
stock bool:CanFitHereVecs(Float:clientpos[3], clientteam, Float:mins[3], Float:maxs[3])		// test if player can fit at a destination, specifying mins/maxs of player size

stock bool:CanSeeHere(Float:clientpos[3], Float:clienteyepos[3])							// test if a client can see from one point to another
stock bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target, clientteam)			// Tests to see if vec1 > vec2 can "see" target player
stock bool:CanSeeEntity(Float:startpos[3], Float:targetpos[3], target)		                  // Tests to see if vec1 > vec2 can "see" target

stock bool:CanStand(Float:pos[3])														// test if player can stand in this position, or if it's too far
stock GetDown(Float:vec[3])															// get the world collision point downward
**/

////////////////////////////////////// ENTITY //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
stock TE_Particle(String:Name[], Float:origin[3]=NULL_VECTOR, Float:start[3]=NULL_VECTOR, Float:angles[3]=NULL_VECTOR,
            entindex=-1,										// entity to attach to
            attachtype=-1, 									// start_at_origin(1), start_at_attachment(2), follow_origin(3), follow_attachment(4)
            attachpoint=-1,									// attachment point index on entity
            bool:resetParticles=true,
            customcolors = 0,									// probably 0/1/2
            Float:color1[3] = NULL_VECTOR,						// rgb colors?
            Float:color2[3] = NULL_VECTOR,						// rgb colors?
            controlpoint = -1,								// second entity to attach to
            controlpointattachment = -1,						// attach type
            Float:controlpointoffset[3] = NULL_VECTOR,			// offset to maintain
            Float:delay=0.0)

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0, Float:flSelfDestruct=0.0)

stock FindEntityByClassname2(iStart, const String:strClassname[])							// findentity by classname properly :|
stock RemoveEntityByRef(ref)															// destroys an entity by its reference
public Action:Timer_RemoveEntity(Handle:timer, any:ref)	
stock RemoveWithoutMayhem(entity)																// tries to prevent physics bug (physprops)

public Action:Timer_ExtinguishPlayer(Handle:timer, any:userid)							// stops a player from burning early
public Action:Timer_TransformRagdoll(Handle:timer, any:userid)							// dissolves a player's ragdoll

stock RemovePlayerBacks(client, indices[], len)											// removes weapon wearables from a client
stock SetItemVisibility(client, RENDER_NORMAL)											// sets a client's wearable's rendermode
stock RemovePlayerWearable(client)														// destroys player's wearables
**/

////////////////////////////////////// CLASS|TEAMS ////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define CLASS_SCOUT		(1 << 0)		//1
#define CLASS_SNIPER		(1 << 1)		//2
#define CLASS_SOLDIER		(1 << 2)		//4
#define CLASS_DEMOMAN		(1 << 3)		//8
#define CLASS_MEDIC		(1 << 4)		//16
#define CLASS_HEAVY		(1 << 5)		//32
#define CLASS_PYRO		(1 << 6)		//64
#define CLASS_SPY			(1 << 7)		//128
#define CLASS_ENGINEER	(1 << 8)		//256
#define CLASS_ALL			(0b111111111)

/**
stock GetClientClassBits(client)														// returns bits corresponding to player's class

stock DisableWeapons(client, Float:duration)
**/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

stock bool:HullTeleport(client, Float:distance)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client);
	
	if (TR_DidHit(trace))
	{
		decl Float:vEndPos[3], Float:vBuffer[3];
		
		TR_GetEndPosition(vEndPos, trace);
		
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vEndPos[0] += (vBuffer[0] * -10.0);
		vEndPos[1] += (vBuffer[1] * -10.0);
		vEndPos[2] += (vBuffer[2] * -10.0);
		
		if (distance == 0.0 || GetVectorDistance(vOrigin, vEndPos, false) < distance)
		{
			//check if endpoint is Clear   
			if (FindEndTeleportPosition(client, vEndPos))
			{
				vOrigin[2] -= 20.0;
				HTTeleportEffects(vOrigin);
				vEndPos[2] += 40.0;
				HTTeleportEffects(vEndPos);
				
				CloseHandle(trace);
				return true;
			}
			else
			{
				PrintCenterText(client, "Destination Blocked");
			}
		}
		else
		{
			PrintCenterText(client, "Destination Too Far");
		}
	}
	else
	{
		PrintCenterText(client, "Invalid Teleport Destination");
	}
	
	CloseHandle(trace);
	return false;
}

stock bool:HullTeleportOther(client, other, Float:distance)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client);
	
	if (TR_DidHit(trace))
	{
		decl Float:vEndPos[3], Float:vBuffer[3];
		
		TR_GetEndPosition(vEndPos, trace);
		
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vEndPos[0] += (vBuffer[0] * -10.0);
		vEndPos[1] += (vBuffer[1] * -10.0);
		vEndPos[2] += (vBuffer[2] * -10.0) + 10.0;
		
		if (distance == 0.0 || GetVectorDistance(vOrigin, vEndPos, false) < distance)
		{
			//check if endpoint is Clear   
			if (FindEndTeleportPosition(other, vEndPos))
			{
				CloseHandle(trace);
				return true;
			}
			else
			{
				PrintCenterText(client, "Destination Blocked");
			}
		}
		else
		{
			PrintCenterText(client, "Destination Too Far");
		}
	}
	else
	{
		PrintCenterText(client, "Invalid Teleport Destination");
	}
	
	CloseHandle(trace);
	return false;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (data != entity);
}

stock bool:FindEndTeleportPosition(client, Float:clientpos[3], bool:team = true)
{
	new Float:clienteyepos[3];
	clienteyepos = clientpos;
	new clientteam = team ? GetClientTeam(client):0;
	
	new Float:scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	
	//new Float:mins[3] = { 24.0, 24.0, 0.0};
	//new Float:maxs[3] = { 24.0,  24.0, 62.0};
	
	decl Float:mins[3];
	decl Float:maxs[3];
	
	mins[0] = maxs[0] = maxs[1] = 24.0 * scale;
	maxs[2] = 62.0 * scale;
	
	mins[0] = -mins[0];
	mins[1] = mins[0];
	mins[2] = 0.0;
	
	SetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
	
	if (CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY * scale; // [80][0]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY * scale; // [80][-80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY * scale; // [0][-80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY * scale; // [-80][-80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY * scale; // [-80][0]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY * scale; // [-80][80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY * scale; // [0][80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY * scale; // [80][80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY * scale; // [80][0]
	clientpos[2] += PLAYERZ * scale;
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY * scale; // [80][-80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY * scale; // [0][-80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY * scale; // [-80][-80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY * scale; // [-80][0]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY * scale; // [-80][80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY * scale; // [0][80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY * scale; // [80][80]
	if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	return false;
}

stock bool:FindEndTeleportPositionFilter(client, Float:clientpos[3], entity)
{
	new Float:clienteyepos[3];
	clienteyepos = clientpos;
	new clientteam = GetClientTeam(client);
	
	SetEntPropVector(client, Prop_Send, "m_vecMaxs", Float: { 24.0, 24.0, 62.0 } );
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
	
	if (CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [80][0]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY; // [80][-80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [0][-80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [-80][-80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][0]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [0][80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [80][80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY; // [80][0]
	clientpos[2] += PLAYERZ;
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY; // [80][-80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [0][-80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [-80][-80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][0]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [0][80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [80][80]
	if (CanSeeHereFilter(clientpos, clienteyepos, entity) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	return false;
}

stock bool:FindEndTeleportPositionEx(client, Float:clientpos[3])
{
	new Float:clienteyepos[3];
	clienteyepos = clientpos;
	new clientteam = GetClientTeam(client);
	
	SetEntPropVector(client, Prop_Send, "m_vecMaxs", Float: { 24.0, 24.0, 62.0 } );
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
	
	if (CanStand(clientpos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [80][0]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY; // [80][-80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [0][-80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [-80][-80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][0]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [0][80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [80][80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY; // [80][0]
	clientpos[2] += PLAYERZ;
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] -= PLAYERXY; // [80][-80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [0][-80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] -= PLAYERXY; // [-80][-80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][0]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[1] += PLAYERXY; // [-80][80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [0][80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	clientpos[0] += PLAYERXY; // [80][80]
	if (CanStand(clientpos) && CanSeeHere(clientpos, clienteyepos) && CanFitHere(clientpos, clientteam))
	{
		TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	
	return false;
}

/**
stock bool:FindEndTeleportPositionVecs(client, Float:clientpos[3])
{
    decl Float:mins[3], Float:maxs[3];
    new Float:clienteyepos[3];
    clienteyepos = clientpos;
    new clientteam = GetClientTeam(client);
    
PrintToConsole(client, "%f %f %f | %f %f %f", mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);

    GetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
    GetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);

    if (CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]+=PLAYERXY;  // [80][0]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]-=PLAYERXY;  // [80][-80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]-=PLAYERXY;  // [0][-80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]-=PLAYERXY;  // [-80][-80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]+=PLAYERXY;  // [-80][0]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]+=PLAYERXY;  // [-80][80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]+=PLAYERXY;  // [0][80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]+=PLAYERXY;  // [80][80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]-=PLAYERXY;  // [80][0]
    clientpos[2]+=PLAYERZ;
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]-=PLAYERXY;  // [80][-80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]-=PLAYERXY;  // [0][-80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]-=PLAYERXY;  // [-80][-80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]+=PLAYERXY;  // [-80][0]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[1]+=PLAYERXY;  // [-80][80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]+=PLAYERXY;  // [0][80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    clientpos[0]+=PLAYERXY;  // [80][80]
    if (CanSeeHere(clientpos, clienteyepos) && CanFitHereVecs(clientpos, clientteam, mins, maxs))
    {
        TeleportEntity(client, clientpos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }

    return false;
}
**/



stock bool:CanFitHere(Float:clientpos[3], clientteam)
{
	if (clientteam == 2)
	{
		TR_TraceHullFilter(clientpos, clientpos, Float: { -24.0, -24.0, 0.0 }, Float: { 24.0, 24.0, 62.0 }, MASK_CUSTOMHULLFILTER_BLUE, TraceEntityFilterTeamPlayers, clientteam);
	}
	else
	{
		TR_TraceHullFilter(clientpos, clientpos, Float: { -24.0, -24.0, 0.0 }, Float: { 24.0, 24.0, 62.0 }, MASK_CUSTOMHULLFILTER_RED, TraceEntityFilterTeamPlayers, clientteam);
	}
	
	return (!TR_DidHit(INVALID_HANDLE));
}

stock bool:CanFitHereVecs(Float:clientpos[3], clientteam, Float:mins[3], Float:maxs[3])
{
	switch (clientteam)
	{
		case 2:TR_TraceHullFilter(clientpos, clientpos, mins, maxs, MASK_CUSTOMHULLFILTER_BLUE, TraceEntityFilterTeamPlayers, clientteam);
		case 3:TR_TraceHullFilter(clientpos, clientpos, mins, maxs, MASK_CUSTOMHULLFILTER_RED, TraceEntityFilterTeamPlayers, clientteam);
		default:TR_TraceHullFilter(clientpos, clientpos, mins, maxs, MASK_PLAYERSOLID, TraceRayDontHitClients);
	}
	
	return (!TR_DidHit(INVALID_HANDLE));
}

stock bool:CanSeeHere(Float:clientpos[3], Float:clienteyepos[3])
{
	TR_TraceRayFilter(clienteyepos, clientpos, MASK_ALL, RayType_EndPoint, TraceRayDontHitClients);
	return !TR_DidHit(INVALID_HANDLE);
}

stock bool:CanSeeHereFilter(Float:clientpos[3], Float:clienteyepos[3], filter)
{
	TR_TraceRayFilter(clienteyepos, clientpos, MASK_ALL, RayType_EndPoint, TraceRayDontHitClientsFilter, filter);
	return !TR_DidHit(INVALID_HANDLE);
}

////////////////////////////////////////////////////

stock HTTeleportEffects(Float:pos[3])
{
	HTShowParticle(pos, "pyro_blast", 1.0);
	HTShowParticle(pos, "pyro_blast_lines", 1.0);
	HTShowParticle(pos, "pyro_blast_warp", 1.0);
	HTShowParticle(pos, "pyro_blast_flash", 1.0);
	//HTShowParticle(pos, "burninggibs", 0.5);
}

stock HTShowParticle(Float:possie[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		TeleportEntity(particle, possie, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, HTDeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:HTDeleteParticles(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

stock TeleportToPlayer(client, target)
{
	static const Float:playermins[3] =  { -24.0, -24.0, 0.0 };
	static const Float:playermaxs[3] =  { 24.0, 24.0, 62.0 };
	
	SetEntPropVector(client, Prop_Send, "m_vecMaxs", playermaxs);
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
	
	new clientteam = GetClientTeam(client);
	if (clientteam == GetClientTeam(target))
	{
		decl Float:TeleportOrigin[3];
		decl Float:TeleportEyes[3];
		
		GetClientAbsOrigin(target, TeleportOrigin);
		GetClientEyeAngles(target, TeleportEyes);
		
		TeleportEntity(client, TeleportOrigin, TeleportEyes, NULL_VECTOR);
	}
	else
	{
		decl Float:targetpos[3];
		decl Float:targetang[3];
		decl Float:fwdvec[3];
		
		GetClientAbsOrigin(target, targetpos);
		GetClientEyeAngles(target, targetang);
		GetAngleVectors(targetang, fwdvec, NULL_VECTOR, NULL_VECTOR);
		
		targetpos[0] += fwdvec[0] * -80.0;
		targetpos[1] += fwdvec[1] * -80.0;
		targetpos[2] += 10.0;
		
		TR_TraceHullFilter(targetpos, targetpos, playermins, playermaxs, MASK_CUSTOMHULLFILTERTEAMS, TraceEntityFilterTeamPlayers, clientteam);
		if (!TR_DidHit(INVALID_HANDLE) && CanStand(targetpos))
		{
			TeleportEntity(client, targetpos, NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			targetpos[0] += fwdvec[0] * 80.0;
			targetpos[1] += fwdvec[1] * 80.0;
			targetpos[2] += 73.0;
			
			TR_TraceHullFilter(targetpos, targetpos, playermins, playermaxs, MASK_CUSTOMHULLFILTERTEAMS, TraceEntityFilterTeamPlayers, clientteam);
			if (!TR_DidHit(INVALID_HANDLE) && CanStand(targetpos))
			{
				TeleportEntity(client, targetpos, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				targetpos[0] += fwdvec[0] * 80.0;
				targetpos[1] += fwdvec[1] * 80.0;
				targetpos[2] -= 73.0;
				
				TR_TraceHullFilter(targetpos, targetpos, playermins, playermaxs, MASK_CUSTOMHULLFILTERTEAMS, TraceEntityFilterTeamPlayers, clientteam);
				if (!TR_DidHit(INVALID_HANDLE) && CanStand(targetpos))
				{
					TeleportEntity(client, targetpos, NULL_VECTOR, NULL_VECTOR);
				}
				else
				{
					GetClientAbsOrigin(target, targetpos);
					
					TeleportEntity(client, targetpos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
}

stock bool:CanStand(Float:pos[3])
{
	static const Float:down[3] =  { 90.0, 0.0, 0.0 };
	new Handle:TraceRay = TR_TraceRayEx(pos, down, MASK_PLAYERSOLID, RayType_Infinite);
	if (TR_DidHit(TraceRay))
	{
		decl Float:end[3];
		TR_GetEndPosition(end, TraceRay);
		
		if (GetVectorDistance(pos, end, true) < 14400)
		{
			CloseHandle(TraceRay);
			return true;
		}
	}
	
	CloseHandle(TraceRay);
	return false;
}

stock GetDown(Float:vec[3])
{
	TR_TraceRayFilter(vec, Float: { 90.0, 0.0, 0.0 }, CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE, RayType_Infinite, TraceEntityFilterWorld);
	if (TR_DidHit())
	{
		TR_GetEndPosition(vec);
	}
}

stock bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target, clientteam) // Tests to see if vec1 > vec2 can "see" target
{
	TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);
	
	if (TR_GetEntityIndex() == target)
	{
		if (TF2_GetPlayerClass(target) == TFClass_Spy) // if they are a spy, do extra tests (coolrocket stuff?)
		{
			if (TF2_IsPlayerInCondition(target, TFCond_Cloaked)) // if they are cloaked
			{
				if (TF2_IsPlayerInCondition(target, TFCond_CloakFlicker) // check if they are partially visible
					 || TF2_IsPlayerInCondition(target, TFCond_OnFire)
					 || TF2_IsPlayerInCondition(target, TFCond_Jarated)
					 || TF2_IsPlayerInCondition(target, TFCond_Milked)
					 || TF2_IsPlayerInCondition(target, TFCond_Bleeding))
				{
					return true;
				}
				
				return false;
			}
			if (TF2_IsPlayerInCondition(target, TFCond_Disguised) && GetEntProp(target, Prop_Send, "m_nDisguiseTeam") == clientteam)
			{
				return false;
			}
			
			return true;
		}
		
		return true;
	}
	
	return false;
}


stock bool:CanSeeEntity(Float:startpos[3], Float:targetpos[3], target) // Tests to see if vec1 > vec2 can "see" target
{
	TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitClients);
	
	return (TR_GetEntityIndex() == target);
}

public bool:TraceEntityFilterWorld(entityhit, mask)
{
	if (entityhit == 0) // I only want it to hit terrain, no models or debris
	{
		return true;
	}
	return false;
}

public bool:TraceEntityFilterTeamPlayers(entity, contentsMask, any:team) // false for blue clients (filter out everything else)
{
	return !(entity > 0 && entity <= MaxClients && GetClientTeam(entity) == team);
}

public bool:TraceRayDontHitClients(entity, contentsMask) // false for clients (filter out everything else)
{
	return !(entity > 0 && entity <= MaxClients);
}

public bool:TraceRayDontHitClientsFilter(entity, contentsMask, any:filter) // false for clients (filter out everything else)
{
	return !(entity == filter || entity > 0 && entity <= MaxClients);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
	if (entity > 0 && entity <= MaxClients) // only hit the client we're aiming at
	{
		if (entity == data)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	return true;
}

////////////////////////////////////// ENTITY //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock TE_Particle(String:Name[], Float:origin[3] = NULL_VECTOR, Float:start[3] = NULL_VECTOR, Float:angles[3] = NULL_VECTOR, 
	entindex = -1,  // entity to attach to
	attachtype = -1,  // start_at_origin(1), start_at_attachment(2), follow_origin(3), follow_attachment(4)
	attachpoint = -1,  // attachment point index on entity
	bool:resetParticles = true, 
	customcolors = 0,  // probably 0/1/2
	Float:color1[3] = NULL_VECTOR,  // rgb colors?
	Float:color2[3] = NULL_VECTOR,  // rgb colors?
	controlpoint = -1,  // second entity to attach to
	controlpointattachment = -1,  // attach type
	Float:controlpointoffset[3] = NULL_VECTOR,  // offset to maintain
	Float:delay = 0.0)
{
	// find string table
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
	
	// find particle index
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	new i;
	for (i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return;
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	if (entindex != -1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype != -1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1:0);
	
	if (customcolors)
	{
		TE_WriteNum("m_bCustomColors", customcolors);
		TE_WriteVector("m_CustomColors.m_vecColor1", color1);
		if (customcolors == 2)
		{
			TE_WriteVector("m_CustomColors.m_vecColor2", color2);
		}
	}
	if (controlpoint != -1)
	{
		TE_WriteNum("m_bControlPoint1", controlpoint);
		if (controlpointattachment != -1)
		{
			TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
		}
	}
	
	TE_SendToAll(delay);
}

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[] = "", Float:flOffsetZ = 0.0, Float:flSelfDestruct = 0.0, bool:attach = true)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if (iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		DispatchKeyValueVector(iParticle, "origin", flPos);
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		if (attach)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity);
		}
		
		ActivateEntity(iParticle);
		
		if (strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		
		if (flSelfDestruct > 0.0)CreateTimer(flSelfDestruct, Timer_RemoveEntity, EntIndexToEntRef(iParticle), TIMER_FLAG_NO_MAPCHANGE);
		
		return iParticle;
	}
	
	return 0;
}

stock RemoveEntityByRef(ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

public Action:Timer_RemoveEntity(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

stock RemoveWithoutMayhem(entity, group = 1)
{
	decl Float:randomvec[3];
	randomvec[0] = GetRandomFloat(-5000.0, 5000.0);
	randomvec[1] = GetRandomFloat(-5000.0, 5000.0);
	randomvec[2] = -5000.0;
	
	TeleportEntity(entity, randomvec, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", group);
	
	AcceptEntityInput(entity, "Break");
}

public Action:Timer_ExtinguishPlayer(Handle:timer, any:userid) // stops a player from burning early
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TF2_RemoveCondition(client, TFCond_OnFire);
	}
}

stock FindEntityByClassname2(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart))iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

stock RemovePlayerBacks(client, indices[], len)
{
	if (len <= 0)return;
	new edict = MaxClients + 1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable*")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
		{
			for (new i = 0; i < len; i++)
			{
				if (idx == indices[i])
				{
					TF2_RemoveWearable(client, edict);
				}
			}
		}
	}
}

stock FindPlayerBack(client, indices[], len)
{
	if (len <= 0)return -1;
	new edict = MaxClients + 1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable*")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
		{
			for (new i = 0; i < len; i++)
			{
				if (idx == indices[i])return edict;
			}
		}
	}
	return -1;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define DISSOLVE_RISE       0
#define DISSOLVE_GROUND     1
#define DISSOLVE_FAST       2
#define DISSOLVE_RANDOM     3

stock RemoveRagdoll(client)
{
	RequestFrame(Frame_RemoveRagdoll, GetClientUserId(client));
}
public Frame_RemoveRagdoll(any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (ragdoll > MaxClients)
		{
			AcceptEntityInput(ragdoll, "Kill");
		}
	}
}

stock DissolveRagdoll(client, type = DISSOLVE_RISE)
{
	new Handle:data = CreateDataPack();
	RequestFrame(Frame_TransformRagdoll, data);
	WritePackCell(data, GetClientUserId(client));
	WritePackCell(data, type);
}
public Frame_TransformRagdoll(any:pack)
{
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	if (client && IsClientInGame(client))
	{
		new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (ragdoll > MaxClients)
		{
			Dissolve(ragdoll, ReadPackCell(pack));
		}
	}
	CloseHandle(pack);
}

stock Dissolve(ent, mode = DISSOLVE_RANDOM)
{
	new dissolver = CreateEntityByName("env_entity_dissolver");
	if (dissolver != -1)
	{
		decl String:dname[12];
		FormatEx(dname, 12, "dis_%d", ent);
		
		DispatchKeyValue(ent, "targetname", dname);
		switch (mode < 0 ? GetRandomInt(0, 3):mode) //"0 ragdoll rises as it dissolves, 1 and 2 dissolve on ground, 3 is fast dissolve"
		{
			case 0:DispatchKeyValue(dissolver, "dissolvetype", "0");
			case 1:DispatchKeyValue(dissolver, "dissolvetype", "1");
			case 2:DispatchKeyValue(dissolver, "dissolvetype", "2");
			default:DispatchKeyValue(dissolver, "dissolvetype", "3");
		}
		DispatchKeyValue(dissolver, "target", dname);
		AcceptEntityInput(dissolver, "Dissolve");
		AcceptEntityInput(dissolver, "kill");
	}
}

stock DissolveEntity(entity, mode = DISSOLVE_RANDOM, Float:delay = 0.0)
{
	if (delay)
	{
		new Handle:data;
		CreateDataTimer(delay, Timer_DissolveEntityInternal, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, EntIndexToEntRef(entity));
		WritePackCell(data, mode);
	}
	else
	{
		Dissolve(entity, mode);
	}
}
public Action:Timer_DissolveEntityInternal(Handle:hTimer, Handle:pack)
{
	ResetPack(pack);
	new ent = EntRefToEntIndex(ReadPackCell(pack));
	if (ent != INVALID_ENT_REFERENCE)
	{
		Dissolve(ent, ReadPackCell(pack));
	}
	
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////



stock SetItemVisibility(client, RenderMode:rmode)
{
	new ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
		{
			SetEntityRenderMode(ent, rmode);
		}
	}
	ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_powerup_bottle")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
		{
			SetEntityRenderMode(ent, rmode);
		}
	}
	ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_weapon_spellbook")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWeapon"))
		{
			new ew = GetEntPropEnt(ent, Prop_Send, "m_hExtraWearable");
			if (IsValidEntity(ew))
			{
				SetEntityRenderMode(ew, rmode);
			}
		}
	}
	ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable"))
		{
			SetEntityRenderMode(ent, rmode);
		}
	}
}

stock RemovePlayerWearable(client)
{
	new ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
		{
			TF2_RemoveWearable(client, ent);
		}
	}
	ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_powerup_bottle")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
		{
			TF2_RemoveWearable(client, ent);
		}
	}
	ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_weapon_spellbook")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWeapon"))
		{
			new ew = GetEntPropEnt(ent, Prop_Send, "m_hExtraWearable");
			if (IsValidEntity(ew))
			{
				TF2_RemoveWearable(client, ent);
			}
		}
	}
	ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable"))
		{
			TF2_RemoveWearable(client, ent);
		}
	}
}

stock RemovePlayerTarge(client)
{
	new ent = MaxClients + 1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable"))
		{
			TF2_RemoveWearable(client, ent);
		}
	}
}

////////////////////////////////////// CLASS|TEAMS ////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock GetClientClassBits(client)
{
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_DemoMan:return CLASS_DEMOMAN;
		case TFClass_Engineer:return CLASS_ENGINEER;
		case TFClass_Heavy:return CLASS_HEAVY;
		case TFClass_Medic:return CLASS_MEDIC;
		case TFClass_Pyro:return CLASS_PYRO;
		case TFClass_Scout:return CLASS_SCOUT;
		case TFClass_Sniper:return CLASS_SNIPER;
		case TFClass_Soldier:return CLASS_SOLDIER;
		case TFClass_Spy:return CLASS_SPY;
	}
	return 0;
}

stock DisableWeapons(client, Float:duration)
{
	decl weapon;
	new Float:time = GetGameTime() + duration;
	for (new i; i < 3; i++)
	{
		weapon = GetPlayerWeaponSlot(client, i);
		if (weapon != -1)
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", time);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", time);
		}
	}
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", time);
}

stock TF2_SwitchToBestWeapon(client, String:classname[64])
{
	// Let's find their best-weapon
	new TFClassType:playerclass = TF2_GetPlayerClass(client);
	new weapon = GetPlayerWeaponSlot(client, playerclass != TFClass_Medic ? TFWeaponSlot_Primary:TFWeaponSlot_Secondary);
	if (weapon != -1 && GetEntityClassname(weapon, classname, 64))
	{
		ClientCommand(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		return weapon;
	}
	weapon = GetPlayerWeaponSlot(client, playerclass != TFClass_Medic ? TFWeaponSlot_Secondary:TFWeaponSlot_Primary);
	if (weapon != -1 && GetEntityClassname(weapon, classname, 64))
	{
		ClientCommand(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		return weapon;
	}
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (weapon != -1 && GetEntityClassname(weapon, classname, 64))
	{
		ClientCommand(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		return weapon;
	}
	return -1;
}

stock PrintTFCustomHudAll(const String:format[], any:...)
{
	decl String:buffer[128];
	VFormat(buffer, 128, format, 2);
	
	static UserMsg:HudNotifyCustom = INVALID_MESSAGE_ID;
	if (HudNotifyCustom == INVALID_MESSAGE_ID)
	{
		HudNotifyCustom = GetUserMessageId("HudNotifyCustom");
	}
	
	new count;
	decl targets[MaxClients];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			targets[count] = client;
			count++;
		}
	}
	
	new Handle:bf = StartMessageEx(HudNotifyCustom, targets, count);
	BfWriteString(bf, buffer);
	BfWriteString(bf, "voice_self");
	BfWriteByte(bf, 0);
	EndMessage();
}

stock PrintTFCustomHud(client, const String:format[], any:...)
{
	decl String:buffer[128];
	VFormat(buffer, 128, format, 3);
	
	static UserMsg:HudNotifyCustom = INVALID_MESSAGE_ID;
	if (HudNotifyCustom == INVALID_MESSAGE_ID)
	{
		HudNotifyCustom = GetUserMessageId("HudNotifyCustom");
	}
	
	decl targets[1];
	targets[0] = client;
	new Handle:bf = StartMessageEx(HudNotifyCustom, targets, 1);
	BfWriteString(bf, buffer);
	BfWriteString(bf, "voice_self");
	switch (GetClientTeam(client))
	{
		case 2:BfWriteByte(bf, 2);
		case 3:BfWriteByte(bf, 3);
		default:BfWriteByte(bf, 0);
	}
	EndMessage();
}

stock PlayInGameSoundAll(String:soundfile[], bool:loud)
{
	if (loud)
	{
		EmitSoundToAll(soundfile);
	}
	
	EmitSoundToAll(soundfile);
}

stock PlayGameSoundAll(String:soundfile[], bool:loud)
{
	decl String:path[512];
	
	FormatEx(path, 512, "playgamesound \"%s\"", soundfile);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			ClientCommand(client, path);
		}
	}
}

stock VerifySoundFile(String:soundfile[])
{
	if (!FileExists(soundfile, true)) // file does not exist
	{
		if (StrContains(soundfile, ".wav", false) != -1)
		{
			new len = strlen(soundfile) + 1;
			decl String:buffer[len];
			strcopy(buffer, len, soundfile);
			ReplaceString(buffer, len, ".wav", ".mp3", false);
			if (FileExists(buffer, true))
			{
				strcopy(soundfile, len, buffer);
				LogError("invalid wav, valid mp3: %s", soundfile);
				return;
			}
			
			LogError("sound file does not exist: %s", soundfile);
		}
	}
}

stock PlayInGameSound(client, String:soundfile[], bool:loud)
{
	if (loud)
	{
		EmitSoundToClient(client, soundfile);
	}
	EmitSoundToClient(client, soundfile);
}

stock PlayGameSound(client, String:soundfile[], bool:loud)
{
	/**
	decl String:path[512];

	VerifySoundFile(soundfile);

	if(loud)
	{
		FormatEx(path, 512, "playgamesound \"%s\";playgamesound \"%s\"", soundfile, soundfile);
	}
	else
	{
		FormatEx(path, 512, "playgamesound \"%s\"",soundfile);
	}
	
	ClientCommand(client, path);
	**/
	
	ClientCommand(client, "playgamesound \"%s\"", soundfile);
} 