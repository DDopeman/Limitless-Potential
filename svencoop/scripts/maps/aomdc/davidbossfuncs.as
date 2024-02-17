// Afraid of Monsters: Director's Cut Script
// Misc Script: David Boss Functions
// Author: Zorbos

const float DAVIDBAD_MOD_ELECTRIC_RADIUS = 1500.0;
const float DAVIDBAD_MOD_ELECTRIC_DAMAGE = 15.0;

// David's Electric Shock attack. Damages players for 15 health
// if they are on the ground when this function is called.
void ElectricAttack(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{	
	CBaseEntity@ pEntity = null;
	CBaseMonster@ pDavid = FindDavid();
	
	if(pDavid !is null)
	{
		while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, pDavid.pev.origin, DAVIDBAD_MOD_ELECTRIC_RADIUS, "player", "classname")) !is null)
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
			
			if(pPlayer.pev.flags & FL_ONGROUND != 0) // Take damage if the player is on the ground
				pPlayer.TakeDamage(pDavid.pev, pDavid.pev, DAVIDBAD_MOD_ELECTRIC_DAMAGE, DMG_SHOCK);
		}
	}
}

// Returns a handle to the currently spawned David monster if he exists
CBaseMonster@ FindDavid()
{
	edict_t@ pEdict = null;
	CBaseEntity@ pDavid = null;
	
	for(int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex)
	{
		@pEdict = @g_EntityFuncs.IndexEnt(pIndex);
		@pDavid = g_EntityFuncs.Instance(pEdict);

		if(pDavid !is null && (pDavid.pev.targetname == "baddavid3" || pDavid.pev.targetname == "baddavid4" || pDavid.pev.targetname == "baddavid5" || 
		pDavid.pev.targetname == "baddavid6" || pDavid.pev.targetname == "baddavid7")) // Search for the david monster
		{
			return cast<CBaseMonster@>(pDavid);
		}
	}
	
	return null; // David monster not found
}