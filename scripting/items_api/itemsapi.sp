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
    
    Completed: 8/8/2019
    
    This utility stores all econ data in memory and parses some key information for library use in other plugins.
    As of 2019, valve no longer allows direct access to the complete econ schema flatfile. A cached version of the schema is now required.
    A simple rsync of a constructed schema works fine as a substitute method.
**/

#define PLUGIN_NAME     "TF2 Econ Item API"
#define PLUGIN_AUTHOR   "https://github.com/vmuse"
#define PLUGIN_CONTACT  "https://github.com/vmuse/sourcemod"
#define PLUGIN_DESCRIP  "Econ item information library"
#define PLUGIN_VERSION  "1.2.3"

////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <itemsapi> 

//#define DEBUG

#define ATTRIBUTE_DELIMITER_PAIR_C			' '				// character to delimit name|value*name|value sets, should never exist in the schema file
#define ATTRIBUTE_DELIMITER_PAIR_S			"; "				// string version
#define ATTRIBUTE_DELIMITER_VALUE_C			';'				// character to delimit name|value pairs, should never exist in the schema file, for quick counting
#define ATTRIBUTE_DELIMITER_VALUE_S			";"				// string version for packing

new Handle:OnGetSchema;

new bool:g_bSchema;											// do we have the schema file intact, even if it's stale?

new Handle:g_hItemSlotTrie = INVALID_HANDLE;				// item slots are stored here
new Handle:g_hItemItemclassTrie = INVALID_HANDLE;			// item classes are stored here
new Handle:g_hItemItemmodelTrie = INVALID_HANDLE;			// item models
new Handle:g_hItemStyleTrie = INVALID_HANDLE;				// item styles is here
new Handle:g_hItemNameTrie = INVALID_HANDLE;				// item names are stored here
new Handle:g_hItemCleanNameTrie = INVALID_HANDLE;			// items that have alternate 'clean' names are stored hear

new Handle:g_hItemPaint = INVALID_HANDLE;					// item paintability is stored here
new Handle:g_hItemHat = INVALID_HANDLE;						// item hats
new Handle:g_hItemWearableClass = INVALID_HANDLE;			// hat classes
new Handle:g_hItemWearable = INVALID_HANDLE;				// item wearables

new Handle:g_hItemAttributeTrie = INVALID_HANDLE;			// weapon attributes are stored here
new Handle:g_hItemWeaponClass = INVALID_HANDLE;				// classes
new Handle:g_hItemWeapon = INVALID_HANDLE;					// weapons
new Handle:g_hItemWeaponWearable = INVALID_HANDLE;			// wearable weapons

new Handle:g_hItemAttributeName = INVALID_HANDLE;
new Handle:g_hItemAttributeNum = INVALID_HANDLE;

new Handle:g_hItemActionClass = INVALID_HANDLE;
new Handle:g_hItemAction = INVALID_HANDLE;					// Action

public Plugin:myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIP, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	// general
	CreateNative("ItemsApi_Ready", Native_ItemsApi_Ready); 
	CreateNative("ItemsApi_GetSlot", Native_ItemsApi_GetSlot);
	CreateNative("ItemsApi_GetSlotEx", Native_ItemsApi_GetSlotEx);
	CreateNative("ItemsApi_GetStyles", Native_ItemsApi_GetStyles);
	CreateNative("ItemsApi_GetClassName", Native_ItemsApi_GetClassName);
	CreateNative("ItemsApi_GetName", Native_ItemsApi_GetName);
	CreateNative("ItemsApi_GetModel", Native_ItemsApi_GetModel);

	// wearables
	CreateNative("ItemsApi_Paintable", Native_ItemsApi_Paintable);
	CreateNative("ItemsApi_Hat", Native_ItemsApi_Hat);
	CreateNative("ItemsApi_Wearable", Native_ItemsApi_Wearable);
	CreateNative("ItemsApi_WearableClasses", Native_ItemsApi_WearableClasses);
	CreateNative("ItemsApi_GetWearableArray", Native_ItemsApi_GetWearableArray);

	// weapons
	CreateNative("ItemsApi_GetNumAttributes", Native_ItemsApi_GetNumAttributes);
	CreateNative("ItemsApi_GetAttribute", Native_ItemsApi_GetAttribute);
	CreateNative("ItemsApi_GetAttributes", Native_ItemsApi_GetAttributes);
	CreateNative("ItemsApi_Weapon", Native_ItemsApi_Weapon);
	CreateNative("ItemsApi_WeaponClasses", Native_ItemsApi_WeaponClasses);
	CreateNative("ItemsApi_GetWeaponArray", Native_ItemsApi_GetWeaponArray);
	CreateNative("ItemsApi_WeaponWearable", Native_ItemsApi_WeaponWearable);

	// action
	CreateNative("ItemsApi_Action", Native_ItemsApi_Action);
	CreateNative("ItemsApi_ActionClasses", Native_ItemsApi_ActionClasses);
	CreateNative("ItemsApi_GetActionArray", Native_ItemsApi_GetActionArray);

	OnGetSchema = CreateGlobalForward("OnGetSchema",ET_Hook,Param_Cell);	

	RegPluginLibrary("itemsapi");

	return APLRes_Success;
}

public Native_ItemsApi_Ready(Handle:plugin,numParams)
{
	return g_bSchema;
}

public Native_ItemsApi_GetSlot(Handle:plugin,numParams)
{
	new class = GetNativeCell(2);
	if(class <1 || class > 9)
	{
		LogError("Attempt to call invalid class for GetSlot");
		return _:TFia_Slot_unknown;
	}
	class--;
	new start = class*2;

	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:bitstring[19];

	GetTrieString(g_hItemSlotTrie, sindex, bitstring, sizeof(bitstring));

	bitstring[start + 2] = '\0';
	return _:StringToInt(bitstring[start]);
}

public Native_ItemsApi_GetSlotEx(Handle:plugin,numParams)
{
	new class = GetNativeCell(3);
	if(class <= 0 || class > 9)
	{
		LogError("Attempt to call invalid class for GetSlotEx");
		return _:TFia_Slot_unknown;
	}
	class--;
	new start = class*2;

	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:bitstring[19];

	GetTrieString(g_hItemSlotTrie, sindex, bitstring, sizeof(bitstring));

	bitstring[start + 2] = '\0';

	new TFiaSlotType:itemslot = TFiaSlotType:StringToInt(bitstring[start]);

	if(itemslot != TFia_Slot_head && itemslot != TFia_Slot_misc)
	{
		decl String:itemclass[19];
		GetTrieString(g_hItemItemclassTrie, sindex, itemclass, 19);
		if(StrEqual(itemclass, "tf_wearable"))
		{
			return _:GetNativeCell(2);										// filter out stuff that should not be wearables to provided category
		}
	}

	return _:itemslot;
}

public Native_ItemsApi_Paintable(Handle:plugin,numParams)
{
	if(FindValueInArray(g_hItemPaint, GetNativeCell(1)) == -1)
	{
		return false;
	}
	return true;
}

public Native_ItemsApi_Hat(Handle:plugin,numParams)
{
	if(FindValueInArray(g_hItemHat, GetNativeCell(1)) == -1)
	{
		return false;
	}
	return true;
}

public Native_ItemsApi_Wearable(Handle:plugin,numParams)
{
	if(FindValueInArray(g_hItemWearable, GetNativeCell(1)) == -1)
	{
		return false;
	}
	return true;
}

public Native_ItemsApi_WearableClasses(Handle:plugin,numParams)
{
	new val = FindValueInArray(g_hItemWearable, GetNativeCell(1));
	if( val != -1)
	{
		return GetArrayCell(g_hItemWearableClass, val);
	}
	return -1;
}

public Native_ItemsApi_GetWearableArray(Handle:plugin,numParams)
{
	return _:CloneHandle(g_hItemWearable, GetNativeCell(1));
}

public Native_ItemsApi_GetStyles(Handle:plugin,numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	new styles;															// the item may or may not exist in the trie (depending on if it has "styles")
	
	GetTrieValue(g_hItemStyleTrie, sindex, styles);
	
	return styles;
}



public Native_ItemsApi_GetClassName(Handle:plugin, numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:itemclass[ITEM_CLASS_LEN];

	if(GetTrieString(g_hItemItemclassTrie, sindex, itemclass, ITEM_CLASS_LEN))
	{
		SetNativeString(2, itemclass, ITEM_CLASS_LEN, false);

		return strlen(itemclass);
	}

	return 0; 
}


public Native_ItemsApi_GetModel(Handle:plugin, numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:model[ITEM_MODEL_LEN];

	if(GetTrieString(g_hItemItemmodelTrie, sindex, model, ITEM_MODEL_LEN))
	{
		SetNativeString(2, model, ITEM_CLASS_LEN, false);

		return strlen(model);
	}

	return 0; 
}

public Native_ItemsApi_GetName(Handle:plugin, numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);	
	decl String:name[ITEM_NAME_LEN];
	
	if(GetNativeCell(3) && GetTrieString(g_hItemCleanNameTrie, sindex, name, ITEM_NAME_LEN))
	{
		SetNativeString(2, name, ITEM_NAME_LEN, false);

		return strlen(name);
	}
	
	if(GetTrieString(g_hItemNameTrie, sindex, name, ITEM_NAME_LEN))
	{
		SetNativeString(2, name, ITEM_NAME_LEN, false);

		return strlen(name);
	}

	return 0; 
}

public Native_ItemsApi_GetNumAttributes(Handle:plugin, numParams)		// THIS IS NOT TESTED
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:delimited[MAX_ATTRIBUTE_DELIM_LEN];

	if(GetTrieString(g_hItemAttributeTrie, sindex, delimited, MAX_ATTRIBUTE_DELIM_LEN))
	{
		new attcnt;														// number of attributes will always be equal to number of paired delimiters
		
		for(new i; delimited[i] != '\0'; i++)
		{
			if(delimited[i] == ATTRIBUTE_DELIMITER_VALUE_C)
			{
				attcnt++;
			}
		}
		
		return attcnt/2;
	}
	
	return 0;
}

public Native_ItemsApi_GetAttribute(Handle:plugin, numParams)	// THIS IS NOT TESTED
{   
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:delimited[MAX_ATTRIBUTE_DELIM_LEN];
	
	if(GetTrieString(g_hItemAttributeTrie, sindex, delimited, MAX_ATTRIBUTE_DELIM_LEN))
	{
		new targetatt = GetNativeCell(2) * 2;
		decl String:value[MAX_ATTRIBUTE_VALUE_LEN];
		decl String:name[MAX_ATTRIBUTE_NAME_LEN];
		new start;
		new attcnt;
	
		for(new i; delimited[i] != '\0'; i++)
		{
			if(delimited[i] == ATTRIBUTE_DELIMITER_VALUE_C)				// found a pair of attributes
			{        
				if(attcnt == targetatt)
				{
					strcopy(name, (i-start)+1, delimited[start]);		// copy the start position to the delimited position
					start = i+1;										// set the start position to the character after the delimited position
					
					while(delimited[i] != ATTRIBUTE_DELIMITER_PAIR_C && delimited[i] != '\0')
					{
						i++;
					}
					strcopy(value, i-start, delimited[start]);
					
					SetNativeString(3, name, MAX_ATTRIBUTE_NAME_LEN, false);
					return _:StringToFloat(value); 
				}
				attcnt++;
			}
			else if(delimited[i] == ATTRIBUTE_DELIMITER_PAIR_C)
			{
				start = i+1;
			}		
		}
	}
	return _:0.0;
}

public Native_ItemsApi_GetAttributes(Handle:plugin, numParams)
{   
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:delimited[MAX_ATTRIBUTE_DELIM_LEN];
	
	if(GetTrieString(g_hItemAttributeTrie, sindex, delimited, MAX_ATTRIBUTE_DELIM_LEN))
	{
		SetNativeString(2, delimited, MAX_ATTRIBUTE_DELIM_LEN);

		return 1;
	}
	return 0;
}

public Native_ItemsApi_Weapon(Handle:plugin,numParams)
{
	if(FindValueInArray(g_hItemWeapon, GetNativeCell(1)) == -1)
	{
		return false;
	}
	return true;
}

public Native_ItemsApi_WeaponClasses(Handle:plugin,numParams)
{
	new val = FindValueInArray(g_hItemWeapon, GetNativeCell(1));
	if( val != -1)
	{
		return GetArrayCell(g_hItemWeaponClass, val);
	}
	return -1;
}

public Native_ItemsApi_GetWeaponArray(Handle:plugin,numParams)
{
	return _:CloneHandle(g_hItemWeapon, GetNativeCell(1));
}

public Native_ItemsApi_WeaponWearable(Handle:plugin,numParams)
{
	if(FindValueInArray(g_hItemWeaponWearable, GetNativeCell(1)) == -1)
	{
		return false;
	}
	return true;
}

public Native_ItemsApi_Action(Handle:plugin,numParams)
{
	if(FindValueInArray(g_hItemAction, GetNativeCell(1)) == -1)
	{
		return false;
	}
	return true;
}

public Native_ItemsApi_ActionClasses(Handle:plugin,numParams)
{
	new val = FindValueInArray(g_hItemAction, GetNativeCell(1));
	if( val != -1)
	{
		return GetArrayCell(g_hItemActionClass, val);
	}
	return -1;
}
public Native_ItemsApi_GetActionArray(Handle:plugin,numParams)
{
	return _:CloneHandle(g_hItemAction, GetNativeCell(1));
}

public OnPluginStart()
{
	CreateConVar("itemsapi_version", PLUGIN_VERSION, "Items API Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_itemsapi_reload", Command_Reload, ADMFLAG_RCON, "Force manual update of the item schema");
	
	g_hItemSlotTrie = CreateTrie();
	g_hItemItemclassTrie = CreateTrie();
	g_hItemItemmodelTrie = CreateTrie();
	g_hItemStyleTrie = CreateTrie();
	g_hItemNameTrie = CreateTrie();
	g_hItemCleanNameTrie = CreateTrie();

	g_hItemPaint = CreateArray();
	g_hItemHat = CreateArray();
	g_hItemWearableClass = CreateArray();
	g_hItemWearable = CreateArray();

	g_hItemAttributeTrie = CreateTrie();
	g_hItemWeaponClass = CreateArray();
	g_hItemWeapon = CreateArray();
	g_hItemWeaponWearable = CreateArray();

	g_hItemAttributeName = CreateArray(ByteCountToCells(MAX_ATTRIBUTE_NAME_LEN));
	g_hItemAttributeNum = CreateArray();

	g_hItemActionClass = CreateArray();
	g_hItemAction = CreateArray();

	g_bSchema = false;
}

public OnConfigsExecuted() 
{
	GetSchema();													// attempt to fetch fresh schema from the api if stale
}

public Action:Command_Reload(client, args)								// Socket stuff borrowed from McKay's SMDJ plugin :)
{							
	GetSchema();
	ReplyToCommand(client, "[SM] The item Schema will be refreshed.");
	
	return Plugin_Handled;
}

GetSchema()
{
	new Handle:hKvItems = CreateKeyValues("itemsapi");

	if (!FileToKeyValues(hKvItems, "scripts/items.txt"))
	{
		LogError("Could not open the item schema, even though it should be there!");
		
		g_bSchema = false;
		
		Call_StartForward(OnGetSchema);
		Call_PushCell(false);
		Call_Finish();

		return;
	}

	ClearTrie(g_hItemSlotTrie);
	ClearTrie(g_hItemItemclassTrie);
	ClearTrie(g_hItemItemmodelTrie);
	ClearTrie(g_hItemStyleTrie);
	ClearTrie(g_hItemNameTrie);
	ClearTrie(g_hItemCleanNameTrie);

	ClearArray(g_hItemPaint);
	ClearArray(g_hItemHat);
	ClearArray(g_hItemWearableClass);
	ClearArray(g_hItemWearable);

	ClearTrie(g_hItemAttributeTrie);
	ClearArray(g_hItemWeaponClass);
	ClearArray(g_hItemWeapon);
	ClearArray(g_hItemWeaponWearable);

	ClearArray(g_hItemAttributeName);
	ClearArray(g_hItemAttributeNum);

	ClearArray(g_hItemActionClass);
	ClearArray(g_hItemAction);

	decl String:name[ITEM_NAME_LEN];
	decl String:cleanname[ITEM_NAME_LEN];
	decl String:slot[10];
	decl defindex;
	decl String:sindex[ITEM_DEF_LEN];
	decl String:itemclass[ITEM_CLASS_LEN];
	decl String:delimitedattributes[MAX_ATTRIBUTE_DELIM_LEN];
	decl String:attributename[MAX_ATTRIBUTE_NAME_LEN];
	decl String:attributevalue[MAX_ATTRIBUTE_VALUE_LEN];
	decl String:buffer[64];
	decl flags;
	decl String:classcount[3];
	decl String:model[ITEM_MODEL_LEN];

	if(KvJumpToKey(hKvItems, "attributes", false))
	{
		KvGotoFirstSubKey(hKvItems, false);
		do
		{
			KvGetString(hKvItems, "name", buffer, sizeof(buffer));
			if(!StrEqual(buffer, "custom projectile model"))				// ban this string attribute, it will cause crashes
			{
				PushArrayString(g_hItemAttributeName, buffer);
				PushArrayCell(g_hItemAttributeNum, KvGetNum(hKvItems, "defindex"));
			}
		}while (KvGotoNextKey(hKvItems, false));
		
		KvGoBack(hKvItems);
	}

	KvRewind(hKvItems);
	if(KvJumpToKey(hKvItems, "items"))														// it begins
	{
		KvGotoFirstSubKey(hKvItems, false);
		do
		{
			defindex = KvGetNum(hKvItems, "defindex", -1);
			if(defindex != -1)																// it's a valid-ish item
			{
				flags = 0;

				IntToString(defindex, sindex, ITEM_DEF_LEN);
				KvGetString(hKvItems, "item_slot", slot, 10, "");
				KvGetString(hKvItems, "name", name, ITEM_NAME_LEN, "UNKNOWN_TF_ITEM");		// this 'should' never happen
				KvGetString(hKvItems, "item_class", itemclass, ITEM_CLASS_LEN, "");
				KvGetString(hKvItems, "model_player", model, ITEM_MODEL_LEN, "");

				if(model[0] != '\0')
				{
					SetTrieString(g_hItemItemmodelTrie, sindex, model);
				}

				if(StrEqual(slot, "misc"))
				{
					KvGetString(hKvItems, "item_type_name", buffer, ITEM_CLASS_LEN, "");
					if(StrEqual("#TF_Wearable_Hat", buffer))
					{
						GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_head);
						PushArrayCell(g_hItemHat, defindex);
					}
					else
					{
						GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_misc);
					}

					if(!StrEqual("#TF_Wearable_TournamentMedal", buffer) && !StrEqual("#TF_Wearable_Badge", buffer))
					{
						switch(defindex)
						{
							case	125, 138, 134, 136, 260, 332, 333, 334, 408, 409, 410, 470, 471, 640, 667, 711, 712, 713, 717, 1899:												// achivement grants
										flags |= CLASS_RESTRICTED;								// blacklist
							case	30153, 30154, 30157, 30158, 30151, 30152, 30143, 30144, 30161, 30147, 30148, 30145, 30146, 30149, 30150, 30155, 30156, 30159, 30160,	// romevision
									5616, 5617, 5618, 5619, 5620, 5621, 5622, 5623, 5624, 5625,																				// zombies
									122, 123, 124,																															// cheat detectors
									5606, 8938:																																// valve fuckups
										flags |= CLASS_RESTRICTED | CLASS_DISABLED;				// blacklist and don't show
						}

						GetClasses(hKvItems, flags, classcount, buffer);							// get the classes for this item
						GetPaintable(hKvItems, defindex);
						GetStyles(hKvItems, sindex);

						PushArrayCell(g_hItemWearableClass, flags);								// set it's wearable flags
						PushArrayCell(g_hItemWearable, defindex);									// mark it as wearable
					}
				}

				else if(StrEqual(slot, "action"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_action);
					GetClasses(hKvItems, flags, classcount, buffer);
	
					PushArrayCell(g_hItemActionClass, flags);
					PushArrayCell(g_hItemAction, defindex);
				}
				else if(StrEqual(slot, "taunt"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_taunt);
					GetClasses(hKvItems, flags, classcount, buffer);
	
					PushArrayCell(g_hItemActionClass, flags);
					PushArrayCell(g_hItemAction, defindex);
				}
				else if(StrEqual(slot, "primary"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_primary);
					GetClasses(hKvItems, flags, classcount, buffer);
					GetAttributes(hKvItems, sindex, attributename, attributevalue, delimitedattributes);
					GetCleanName(sindex, name, cleanname);
					GetStyles(hKvItems, sindex);
					GetWeaponWearable(itemclass, defindex);

					PushArrayCell(g_hItemWeaponClass, flags);
					PushArrayCell(g_hItemWeapon, defindex);
				}
				else if(StrEqual(slot, "secondary"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_secondary);
					GetClasses(hKvItems, flags, classcount, buffer);
					GetAttributes(hKvItems, sindex, attributename, attributevalue, delimitedattributes);
					GetCleanName(sindex, name, cleanname);
					GetStyles(hKvItems, sindex);
					GetWeaponWearable(itemclass, defindex);

					PushArrayCell(g_hItemWeaponClass, flags);
					PushArrayCell(g_hItemWeapon, defindex);
				}
				else if(StrEqual(slot, "melee"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_melee);
					GetClasses(hKvItems, flags, classcount, buffer);
					GetAttributes(hKvItems, sindex, attributename, attributevalue, delimitedattributes);
					GetCleanName(sindex, name, cleanname);
					GetStyles(hKvItems, sindex);
					GetWeaponWearable(itemclass, defindex);

					PushArrayCell(g_hItemWeaponClass, flags);
					PushArrayCell(g_hItemWeapon, defindex);
				}
				else if(StrEqual(slot, "building"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_building);
					GetClasses(hKvItems, flags, classcount, buffer);
					GetAttributes(hKvItems, sindex, attributename, attributevalue, delimitedattributes);
					GetCleanName(sindex, name, cleanname);
					GetStyles(hKvItems, sindex);

					PushArrayCell(g_hItemWeaponClass, flags);
					PushArrayCell(g_hItemWeapon, defindex);
				}
				else if(StrEqual(slot, "pda"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_pda);
					GetClasses(hKvItems, flags, classcount, buffer);
					GetAttributes(hKvItems, sindex, attributename, attributevalue, delimitedattributes);
					GetCleanName(sindex, name, cleanname);
					GetStyles(hKvItems, sindex);

					PushArrayCell(g_hItemWeaponClass, flags);
					PushArrayCell(g_hItemWeapon, defindex);
				}
				else if(StrEqual(slot, "pda2"))
				{
					GetLoadoutSlots(hKvItems, sindex, itemclass, TFia_Slot_pda2);
					GetClasses(hKvItems, flags, classcount, buffer);
					GetAttributes(hKvItems, sindex, attributename, attributevalue, delimitedattributes);
					GetCleanName(sindex, name, cleanname);
					GetStyles(hKvItems, sindex);

					PushArrayCell(g_hItemWeaponClass, flags);
					PushArrayCell(g_hItemWeapon, defindex);
				}

				SetTrieString(g_hItemNameTrie, sindex, name);
				SetTrieString(g_hItemItemclassTrie, sindex, itemclass);
			}
		}
		while (KvGotoNextKey(hKvItems, false));
	}

	CloseHandle(hKvItems);

	g_bSchema = true;
	
	Call_StartForward(OnGetSchema);
	Call_PushCell(true);
	Call_Finish();
}


GetWeaponWearable(String:classname[], defindex)		// wearable items and demoshields, etc
{
	if(strncmp(classname, "tf_wearable", 11) == 0)
	{
		PushArrayCell(g_hItemWeaponWearable, defindex);
	}
}

GetLoadoutSlots(Handle:hKvItems, String:sindex[], String:classname[], TFiaSlotType:slot)
{
	static const String:sClasskey[][] = {"unknown", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

	new String:buffer[19];

	switch(slot)
	{
		case TFia_Slot_primary, TFia_Slot_secondary, TFia_Slot_melee:
		{
			if(KvJumpToKey(hKvItems, "per_class_loadout_slots"))		// at this time valve only uses primary/secondary/melee for a few classes
			{
				new TFiaSlotType:classes[10] = {TFia_Slot_unknown, ...};

				for(new i=1; i<10; i++)
				{
					KvGetString(hKvItems, sClasskey[i], buffer, sizeof(buffer));

					if(StrEqual(buffer, "primary"))			classes[i] = TFia_Slot_primary;
					else if(StrEqual(buffer, "secondary"))		classes[i] = TFia_Slot_secondary;
					else if(StrEqual(buffer, "melee"))			classes[i] = TFia_Slot_melee;
				}

				KvGoBack(hKvItems);

				FormatEx(buffer, sizeof(buffer), "%2d%2d%2d%2d%2d%2d%2d%2d%2d",
					classes[1], classes[2], classes[3], classes[4], classes[5], classes[6], classes[7], classes[8], classes[9]);

#if defined DEBUG
LogMessage("defindex:%s, slot:%d, MULTIPLE classes:%s", sindex, slot, buffer);
#endif

				SetTrieString(g_hItemSlotTrie, sindex, buffer);

				return;
			}
		}
	}

	if(slot == TFia_Slot_secondary && StrEqual(classname, "tf_weapon_revolver"))
	{
#if defined DEBUG
LogMessage("Reassigning defindex:%s, slot:%d, to slot:%d", sindex, TFia_Slot_secondary, TFia_Slot_primary);
#endif
		slot = TFia_Slot_primary;
	}

	FormatEx(buffer, sizeof(buffer), "%2d%2d%2d%2d%2d%2d%2d%2d%2d", slot, slot, slot, slot, slot, slot, slot, slot, slot);

#if defined DEBUG
LogMessage("defindex:%s, slot:%d, classes:%s", sindex, slot, buffer);
#endif

	SetTrieString(g_hItemSlotTrie, sindex, buffer);
}

GetStyles(Handle:hKvItems, String:sindex[])
{
	new styles = 0;
	if(KvJumpToKey(hKvItems, "styles"))
	{
		if(KvGotoFirstSubKey(hKvItems))
		{
			do
			{
				styles++;
			}
			while(KvGotoNextKey(hKvItems, false));

			KvGoBack(hKvItems);
		}
		
		KvGoBack(hKvItems);
	}
	SetTrieValue(g_hItemStyleTrie, sindex, styles);
}

GetCleanName(String:sindex[], String:name[], String:cleanname[])
{
	new tolower = StrContains(name, "TF_WEAPON_");
	if(tolower != -1)									// This will clean up the names for display.... There's not many like this
	{
		strcopy(cleanname, ITEM_NAME_LEN, name);
		tolower += 11;															// I want the first letter to be Caps
		while( cleanname[tolower] != '\0')
		{																		// Just parse between delimiter
			cleanname[tolower] = CharToLower(cleanname[tolower]);
			tolower++;
		}
		
		// Prefix (caps)
		ReplaceString(cleanname, ITEM_NAME_LEN, "TF_WEAPON_", "");
		ReplaceString(cleanname, ITEM_NAME_LEN, "Upgradeable ", "");
		
		// Suffix (lower)
		if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_hwg", ""))								// and... weeee
			if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_soldier", ""))
				if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_pyro", ""))
					if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_medic", ""))
						if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_scout", ""))
							if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_spy", ""))
								ReplaceString(cleanname, ITEM_NAME_LEN, "_engineer", "");		// Will still say Pda build or Pda destroy
		
		ReplaceString(cleanname, ITEM_NAME_LEN, "_primary", "");			
		ReplaceString(cleanname, ITEM_NAME_LEN, "_", " ");						// is this still needed?
		
		SetTrieString(g_hItemCleanNameTrie, sindex, cleanname);					// store the alternative name
	}
}

GetPaintable(Handle:hKvItems, defindex)
{
	if(KvJumpToKey(hKvItems, "capabilities"))									// test if paint cans can be applied
	{
		if(KvGetNum(hKvItems, "paintable", 0))
		{
			PushArrayCell(g_hItemPaint, defindex);
		}
		KvGoBack(hKvItems);
	}
}

GetAttributes(Handle:hKvItems, String:sindex[], String:attributename[], String:attributevalue[], String:delimitedattributes[])
{
	if(KvJumpToKey(hKvItems, "attributes"))									// prepare attributes
	{
		delimitedattributes[0] = '\0';										// reset the buffer
		new bool:deliminate;													// don't deliminate the first item
		decl id;

		if(KvGotoFirstSubKey(hKvItems, false))								// some have attributes but are empty
		{
			do
			{
				KvGetString(hKvItems, "name", attributename, MAX_ATTRIBUTE_NAME_LEN, "INVALID_ATTRIBUTE");

				id = FindStringInArray(g_hItemAttributeName, attributename);
				if(id != -1)
				{
					KvGetString(hKvItems, "value", attributevalue, MAX_ATTRIBUTE_VALUE_LEN);
					
					if(!deliminate)
					{
						deliminate = true;	
					}
					else
					{
						StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, ATTRIBUTE_DELIMITER_PAIR_S);
					}
					IntToString(GetArrayCell(g_hItemAttributeNum, id), attributename, MAX_ATTRIBUTE_NAME_LEN);
					StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, attributename);
					StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, ATTRIBUTE_DELIMITER_VALUE_S);
					StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, attributevalue);
				}
#if defined DEBUG
				else
				{
					LogError("Could not find attribute [%s] for item: %s", attributename,  sindex);
				}
#endif
			}
			while(KvGotoNextKey(hKvItems, false));
		
			KvGoBack(hKvItems);
		}

		SetTrieString(g_hItemAttributeTrie, sindex, delimitedattributes);

		KvGoBack(hKvItems);
	}
}

GetClasses(Handle:hKvItems, &flags, String:classcount[], String:buffer[])
{
	if(KvJumpToKey(hKvItems, "used_by_classes"))																				// Set wearable's class bits
	{
		for(new i;; i++)
		{
			IntToString(i, classcount, 3);
			KvGetString(hKvItems, classcount, buffer, 10); 
			if(buffer[0] == '\0')
			{
				break;
			}

			if(StrEqual(buffer, "Scout"))
			{
				flags |= CLASS_SCOUT;
			}
			else if(StrEqual(buffer, "Sniper"))
			{
				flags |= CLASS_SNIPER;
			}
			else if(StrEqual(buffer, "Soldier"))
			{
				flags |= CLASS_SOLDIER;
			}
			else if(StrEqual(buffer, "Demoman"))
			{
				flags |= CLASS_DEMOMAN;
			}
			else if(StrEqual(buffer, "Medic"))
			{
				flags |= CLASS_MEDIC;
			}
			else if(StrEqual(buffer, "Heavy"))
			{
				flags |= CLASS_HEAVY;
			}
			else if(StrEqual(buffer, "Pyro"))
			{
				flags |= CLASS_PYRO;
			}
			else if(StrEqual(buffer, "Spy"))
			{
				flags |= CLASS_SPY;
			}
			else if(StrEqual(buffer, "Engineer"))
			{
				flags |= CLASS_ENGINEER;
			}
		}
		KvGoBack(hKvItems);
	}
	else
	{
		flags |= CLASS_ALL;
	}
}