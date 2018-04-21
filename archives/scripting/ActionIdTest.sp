/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "ActionIDTest",
	author = "Gorm",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public OnPluginStart()
{
	// Add your own code here...
}

public Action:onTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	PrintToChatAll("Lalala-lala-lala!\nAttacker: %d La-le-la!\nVictim: %d La-lo-la!\nDamage: %f Lu-li-la!", attacker, victim, damage);
	if (damage == 0.0)
		return Plugin_Continue;
	else if ((attacker > 0) && (attacker <= 32))
	{
		PrintToChatAll("Action ID: %d", GetEntProp(attacker, Prop_Send, "m_ActionId"));
		PrintToChatAll("Lalala!");
	}
	return Plugin_Continue;		
}