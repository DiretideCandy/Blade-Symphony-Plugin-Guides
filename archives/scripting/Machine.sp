/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:kvParticles;
new Handle:kvDamageScale;
new Handle:kvDamageInc;
new Handle:kvNoneScaleInc;
new Handle:kvDamageLimit;

new g_machine_id = 0;
new g_hearts = -1;
new g_hearts_end = -1;
new g_fire = -1;
new g_fire_end = -1;
new Float:g_damage = 1.0;
new g_lastAttacker = -1;

public Plugin:myinfo = 
{
	name = "Machine",
	author = "Gorm",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	kvParticles = CreateConVar("sm_machine_enable_particles", "0", "Should machine get fire sword(0 - no, 1 - yes)", 0, true, 0.0, true, 1.0);
	kvDamageScale = CreateConVar("sm_machine_damagescale", "1.2", "Damage scale modifier", 0, true, 0.0, false);
	kvDamageInc = CreateConVar("sm_machine_damageinc", "0.2", "Damage increment value", 0, true, 0.0, false);
	kvNoneScaleInc = CreateConVar("sm_machine_damagemode", "0", "How machine's damage should be changed(0 - Stay as is, 1 - Scale, 2 - Increment)", 0, true, 0.0, true, 2.0);
	kvDamageLimit = CreateConVar("sm_machine_damagelimit", "2.0", "Damage scale limit", 0, true, 0.0);
	
	HookConVarChange(kvNoneScaleInc, ConVarDmgType);
	HookConVarChange(kvParticles, ConVarParticles);
	HookEvent("player_death", PlayerDeath);
	
	RegAdminCmd("sm_machine_set", SetMachine, ADMFLAG_RCON);
	RegAdminCmd("sm_machine_remove", RemoveMachine, ADMFLAG_RCON);
	RegAdminCmd("sm_machine_start", StartMachine, ADMFLAG_RCON);
	RegAdminCmd("sm_machine_end", EndMachine, ADMFLAG_RCON);
}

public OnMapStart()
{
	PrecacheGeneric("particles/sword_hearts.pcf");
	AddToStringTable( FindStringTable( "ParticleEffectNames" ), "sword_hearts" );
	AddToStringTable( FindStringTable( "ExtraParticleFilesTable" ), "particles/sword_hearts.pcf" );
	AddFileToDownloadsTable( "particles/sword_hearts.pcf" );
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	if (g_machine_id == client)
	{
		g_machine_id = 0;
		g_damage = 1.0;
		g_lastAttacker = -1;
		RemoveParticles();
	}
}

public Action:StartMachine(client, args)
{
	SetHudTextParams(0.3, 0.2, 5.0, 255, 255, 255, 255);
	for(new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			ShowHudText(i, -1, "WELCOME TO THE MACHINE");
		}
	}
	
	return Plugin_Handled;
}

public Action:EndMachine(client, args)
{
	SetHudTextParams(0.4, 0.2, 5.0, 255, 255, 255, 255);
	
	if (g_machine_id != 0)
	{
		new String:cl_name[50];
		GetClientName(g_machine_id, cl_name, 50);
		
		for(new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				ShowHudText(i, -1, "%s wins!", cl_name);
			}
		}
		
		g_machine_id = 0;
		g_lastAttacker = -1;
		RemoveParticles();
		g_damage = 1.0;
	}
	
	return Plugin_Handled;
}

public Action:SetMachine(client, args)
{
	new String:cl_name[50];
	GetCmdArg(1, cl_name, 50);
	
	new matches = 0;
	new cl_id;
	for(new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			new String:t_name[50];
			GetClientName(i, t_name, 50);
			
			if (StrContains(t_name, cl_name, true) != -1)
			{
				++matches;
				cl_id = i;
			}
		}
	}
	
	if (matches == 0)
	{
		PrintToChat(client, "[MACHINE]Wrong name!");
		return Plugin_Handled;
	}
	else if (matches > 1)
	{
		PrintToChat(client, "[MACHINE] >1 matches");
		return Plugin_Handled;
	}
	
	if (g_machine_id != 0)
	{
		RemoveParticles();
		g_machine_id = 0;
	}
	
	if (!IsClientInGame(cl_id))
		return Plugin_Handled;
	
	g_machine_id = cl_id;
	
	MachineHud(cl_id);
	MachineChat(cl_id);
	
	if (GetConVarBool(kvParticles))
	{
		CreateParticles(cl_id);
	}
	
	return Plugin_Handled;
}

public Action:RemoveMachine(client, args)
{
	if (g_machine_id == 0)
	{
		PrintToChat(client, "[MACHINE]There is no machine!");
		return Plugin_Handled;
	}
	
	g_machine_id = 0;
	
	RemoveParticles();
	
	return Plugin_Handled;
}

public CreateParticles(client)
{
	g_fire = CreateEntityByName("info_particle_system");
	g_fire_end = CreateEntityByName("info_particle_system");
	g_hearts = CreateEntityByName("info_particle_system");
	g_hearts_end = CreateEntityByName("info_particle_system");
	
	DispatchKeyValue(g_fire, "effect_name", "sword_fire");
	DispatchKeyValue(g_hearts, "effect_name", "sword_hearts");
	
	SetVariantString("!activator");
	AcceptEntityInput(g_fire, "SetParent", client, g_fire, 0);
	SetVariantString("anim_attachment_RH");
	AcceptEntityInput(g_fire, "SetParentAttachment");
	
	SetVariantString("!activator");
	AcceptEntityInput(g_fire_end, "SetParent", client, g_fire_end, 0);
	SetVariantString("anim_attachment_E");
	AcceptEntityInput(g_fire_end, "SetParentAttachment");
	
	SetVariantString("!activator");
	AcceptEntityInput(g_hearts, "SetParent", client, g_hearts, 0);
	SetVariantString("anim_attachment_RH");
	AcceptEntityInput(g_hearts, "SetParentAttachment");
	
	SetVariantString("!activator");
	AcceptEntityInput(g_hearts_end, "SetParent", client, g_hearts_end, 0);
	SetVariantString("anim_attachment_E");
	AcceptEntityInput(g_hearts_end, "SetParentAttachment");
	
	DispatchKeyValue(g_fire_end, "targetname", "machine_fire_end");
	DispatchKeyValue(g_fire, "cpoint1", "machine_fire_end");
	
	DispatchKeyValue(g_hearts_end, "targetname", "machine_hearts_end");
	DispatchKeyValue(g_hearts, "cpoint1", "machine_hearts_end");
	
	DispatchSpawn(g_fire);
	ActivateEntity(g_fire);
	AcceptEntityInput(g_fire, "Start");
	
	DispatchSpawn(g_hearts);
	ActivateEntity(g_hearts);
	AcceptEntityInput(g_hearts, "Start");
}

public RemoveParticles()
{
	if (IsValidEdict(g_fire) && IsValidEdict(g_hearts) && IsValidEdict(g_fire_end) && IsValidEdict(g_hearts_end))
	{
		RemoveEdict(g_fire);
		RemoveEdict(g_fire_end);
		RemoveEdict(g_hearts);
		RemoveEdict(g_hearts_end);
		
		g_fire = g_fire_end = g_hearts = g_hearts_end = -1;
	}
}

public ConVarParticles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldVal = StringToInt(oldValue);
	new newVal = StringToInt(newValue);
	
	if (newVal != oldVal)
	{
		if (newVal == 1)
		{
			if (g_machine_id != 0 && IsClientInGame(g_machine_id))
			{
				CreateParticles(g_machine_id);
			}
		}
		else
		{
			if (g_machine_id != 0 && IsClientInGame(g_machine_id))
			{
				RemoveParticles();
			}
		}
	}
}

public ConVarDmgType(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldVal = StringToInt(oldValue);
	new newVal = StringToInt(newValue);
	
	if (newVal == 0)
	{
		g_damage = 1.0;
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim == g_machine_id)
	{
		if (IsClientInGame(killer))
		{
			g_lastAttacker = -1;
			RemoveParticles();
			SetVariantInt(100);
			AcceptEntityInput(killer, "SetHealth");
			g_machine_id = killer;
			MachineHud(killer);
			MachineChat(killer);
			
			if (GetConVarBool(kvParticles))
				CreateParticles(killer);
		}
	}
	else if (killer == g_machine_id)
	{
		if (IsClientInGame(killer))
		{
			SetVariantInt(100);
			AcceptEntityInput(killer, "SetHealth");
		}
		
		g_lastAttacker = -1;
		g_damage = 1.0;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
		Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (damage == 0.0)
	{
		return Plugin_Continue;
	}
	
	if (victim == g_machine_id)
	{
		if (attacker >= 1 && attacker <= MaxClients)
		{
			if (g_lastAttacker == -1 || g_lastAttacker == attacker)
			{
				g_lastAttacker = attacker;
				
				return Plugin_Continue;
			}
			else
			{
				g_lastAttacker = attacker;
				
				new type = GetConVarInt(kvNoneScaleInc);
				if (type == 1)
					g_damage = g_damage * GetConVarFloat(kvDamageScale);
				else if (type == 2)
					g_damage = g_damage + GetConVarFloat(kvDamageInc);
				
				return Plugin_Continue;
			}	
		}
	}
	
	if (attacker == g_machine_id)
	{
		damage = damage * min(g_damage, GetConVarFloat(kvDamageLimit));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public MachineHud(client)
{
	SetHudTextParams(0.5, 0.2, 3.0, 255, 0, 0, 255);
	ShowHudText(client, -1, "You're Machine!");
}

public MachineChat(client)
{
	new String:cl_name[50];
	GetClientName(client, cl_name, 50);
	
	PrintToChatAll("\x01\x04[MACHINE] \x03%s \x01becomes the Machine", cl_name);
}

public Float:min(Float: a, Float: b)
{
	if (a < b)
		return a;
	else
		return b;
}