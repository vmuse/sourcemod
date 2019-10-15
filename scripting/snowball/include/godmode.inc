/** Double-include prevention */
#if defined _godmode_included_
  #endinput
#endif
#define _godmode_included_
 
/*
 * Checks if somone is invulnerable
 *
 * @param num1    A Client Index.
*/
native IsClientGodmode(client);

/*
 * removes status
 *
 * @param num1    A Client Index.
 * @param num2    recover them / kill them
 * @param num3    regenerate them?.
*/
native DestroyClientGodmode(client, bool:gentile, bool:regen);

public SharedPlugin:__pl_godmode =
{
	name = "godmode",
	file = "godmode.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_godmode_SetNTVOptional()
{
	MarkNativeAsOptional("IsClientGodmode");
	MarkNativeAsOptional("DestroyClientGodmode");
}