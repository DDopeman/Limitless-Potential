// Afraid of Monsters: Director's Cut Script
// Misc Script: Weaponmaker
// Author: Zorbos

class weaponmaker : ScriptBaseEntity
{
	string m_iszWeaponToSpawn = ""; // The weapon to spawn
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "m_iszWeaponToSpawn")
		{
			m_iszWeaponToSpawn = szValue;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void OnCreate()
	{
		self.pev.nextthink = g_Engine.time;
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		string pOrigin = "" + self.pev.origin.x + " " + self.pev.origin.y + " " + self.pev.origin.z;
		string pAngles = "" + self.pev.angles.x + " " + self.pev.angles.y + " " + self.pev.angles.z;
		dictionary@ pValues = {{"origin", pOrigin}, {"angles", pAngles}, {"targetname", "weapon_spawn"}};
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(g_EntityFuncs.CreateEntity(m_iszWeaponToSpawn, @pValues, true));
	}
}