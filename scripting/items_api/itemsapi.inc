#if defined _itemsapi_included_
  #endinput
#endif
#define _itemsapi_included_
 
#define ITEM_NAME_LEN				64		// max length of item names
#define MAX_ATTRIBUTE_VALUE_LEN		16		// max length of an attribute float
#define MAX_ATTRIBUTE_NAME_LEN		64		// max length of an attribute name
#define MAX_ATTRIBUTE_DELIM_LEN		1300	// max length of delimited pack of item attributes.. will probably never ever ever ever be this big
#define ITEM_CLASS_LEN				64		// max length of an item class name
#define ITEM_DEF_LEN				8		// max length of item definition index. Oh valve, why are robot hats over 4 digits?
#define ITEM_MODEL_LEN PLATFORM_MAX_PATH

#define CLASS_SCOUT				(1 << 0)		//1
#define CLASS_SNIPER			(1 << 1)		//2
#define CLASS_SOLDIER			(1 << 2)		//4
#define CLASS_DEMOMAN			(1 << 3)		//8
#define CLASS_MEDIC				(1 << 4)		//16
#define CLASS_HEAVY				(1 << 5)		//32
#define CLASS_PYRO				(1 << 6)		//64
#define CLASS_SPY				(1 << 7)		//128
#define CLASS_ENGINEER			(1 << 8)		//256
#define CLASS_ALL				(0b111111111)
#define CLASS_RESTRICTED		(1 << 9)		//512
#define CLASS_DISABLED			(1 << 10)		//1024
 
enum TFiaSlotType
{
	TFia_Slot_unknown=0,				// items will never be put in this category, but it may have uses
	TFia_Slot_head,						// this is the most important item class, so it comes first :)
	TFia_Slot_misc,	
	TFia_Slot_action,
	TFia_Slot_primary,
	TFia_Slot_secondary,
	TFia_Slot_melee,
	TFia_Slot_building,
	TFia_Slot_pda,
	TFia_Slot_pda2,
	TFia_Slot_wearable,					// items will never be put in this category, but it may overridden to this category (ItemsApi_GetSlotEx)
	TFia_Slot_taunt
};

/**
 * Returns true if the items schema is cached and available
 *
**/
native bool:ItemsApi_Ready();


/**
 * Returns the item equip slot of an item, unknown on failure
 *
 * @param num1    An Item Definition Index
 * @param num2	player class to get slot from (if there are multiple)
**/
native TFiaSlotType:ItemsApi_GetSlot(defindex, TFClassType:class);


/**
 * Returns the item equip slot of an item, unknown on failure
 * Use this to filter out "tf_wearable" items which may be returned as weapons otherwise (items like the razorback or buff banner)
 *
 * @param num1    An Item Definition Index
 * @param num2    A TFiaSlotType to override the return slot index if it is a "tf_werable" but not a TFia_Slot_head or TFia_Slot_misc type (usually a weapon wearable)
 * @param num3	player class to get slot from (if there are multiple)
**/
native TFiaSlotType:ItemsApi_GetSlotEx(defindex, TFiaSlotType:weapon_wearable = TFia_Slot_wearable, TFClassType:class);


/**
 * Returns true if an item is paintable
 *
 * @param num1    An Item Definition Index
**/
native bool:ItemsApi_Paintable(defindex);

/**
 * Returns true if an item is a Hat
 *
 * @param num1    An Item Definition Index
**/
native bool:ItemsApi_Hat(defindex);

/**
 * Returns number of stuyles on an item
 *
 * @param num1    An Item Definition Index
**/
native ItemsApi_GetStyles(defindex);

/**
 * Returns true if an item is wearable misc (tf_wearable)
 *
 * @param num1    An Item Definition Index
**/
native bool:ItemsApi_Wearable(defindex);

/**
 * Returns class flags for a wearable misc, -1 if does not exist (tf_wearable)
 *
 * @param num1    An Item Definition Index
**/
native ItemsApi_WearableClasses(defindex);

/**
 * Returns a handle to cloned wearable array
 *
 * @param num1    A Handle to the calling plugin
**/
native Handle:ItemsApi_GetWearableArray(Handle:plugin);

/**
 * Returns length of string written to buffer, 0 on failure.
 *
 * @param num1    An Item Definition Index
 * @param num2    buffer to write class name of size ITEM_CLASS_LEN
**/
native ItemsApi_GetClassName(defindex, String:name[]);

/**
 * Returns length of string written to buffer, 0 on failure.
 *
 * @param num1    An Item Definition Index
 * @param num2    buffer to write item name of size ITEM_MODEL_LEN
**/
native ItemsApi_GetModel(defindex, String:name[]); 

/**
 * Returns length of string written to buffer, 0 on failure.
 *
 * @param num1    An Item Definition Index
 * @param num2    buffer to write item name of size ITEM_NAME_LEN
 * @param num3    if true, default item names will be processed to make them more readable
**/
native ItemsApi_GetName(defindex, String:name[], bool:rename = false); 


/**
 * Returns the actual number of attributes an item has, 0 on failure or no attributes.
 *
 * @param num1    An Item Definition Index
**/
native ItemsApi_GetNumAttributes(defindex);


/**
 * Returns the value of the requested attribute, and writes its name to the buffer, 0.0 on failure.
 *
 * @param num1    An Item Definition Index
 * @param num2    An attribute id 0 +
 * @param num3    buffer to write item name of size MAX_ATTRIBUTE_NAME_LEN
**/
native Float:ItemsApi_GetAttribute(defindex, attribid, String:attribname[]);


/**
 * Returns the value of the requested attributes, and writes its name to the buffer, false on failure.
 *
 * @param num1    An Item Definition Index
 * @param num2    buffer to write item delimited attribute string to sized MAX_ATTRIBUTE_NAME_LEN
**/
native bool:ItemsApi_GetAttributes(defindex, String:attribname[]);


/**
 * Returns class flags for a weapon, -1 if does not exist
 *
 * @param num1    An Item Definition Index
**/
native ItemsApi_WeaponClasses(defindex);

/**
 * Returns a handle to cloned weapons array
 *
 * @param num1    A Handle to the calling plugin
**/
native Handle:ItemsApi_GetWeaponArray(Handle:plugin);

/**
 * Returns true if an item is weapon wearable (tf_wearable)
 *
 * @param num1    An Item Definition Index
**/
native bool:ItemsApi_WeaponWearable(defindex);


/**
 * Returns true if an item is an action/taunt slot item
 *
 * @param num1    An Item Definition Index
**/
native bool:ItemsApi_Action(defindex);

/**
 * Returns class flags for an action/taunt, -1 if does not exist
 *
 * @param num1    An Item Definition Index
**/
native ItemsApi_ActionClasses(defindex);

/**
 * Returns a handle to cloned action/taunt array
 *
 * @param num1    A Handle to the calling plugin
**/
native Handle:ItemsApi_GetActionArray(Handle:plugin);


public SharedPlugin:__pl_itemsapi =
{
	name = "itemsapi",
	file = "itemsapi.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_itemsapi_SetNTVOptional()
{
	MarkNativeAsOptional("ItemsApi_Ready");
	MarkNativeAsOptional("ItemsApi_GetSlot");
	MarkNativeAsOptional("ItemsApi_GetSlotEx");
	MarkNativeAsOptional("ItemsApi_GetClassName");
	MarkNativeAsOptional("ItemsApi_GetName");
	MarkNativeAsOptional("ItemsApi_GetStyles");
	MarkNativeAsOptional("ItemsApi_GetModel");

	MarkNativeAsOptional("ItemsApi_Paintable");
	MarkNativeAsOptional("ItemsApi_Hat");
	MarkNativeAsOptional("ItemsApi_Wearable");
	MarkNativeAsOptional("ItemsApi_WearableClasses");
	MarkNativeAsOptional("ItemsApi_GetWearableArray");

	MarkNativeAsOptional("ItemsApi_GetNumAttributes");
	MarkNativeAsOptional("ItemsApi_GetAttribute");
	MarkNativeAsOptional("ItemsApi_GetAttributes");
	MarkNativeAsOptional("ItemsApi_WeaponClasses");
	MarkNativeAsOptional("ItemsApi_GetWeaponArray");
	MarkNativeAsOptional("ItemsApi_WeaponWearable");
}