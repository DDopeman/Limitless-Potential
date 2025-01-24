/*
* Ammo mod script
* This script wraps the functionality needed to set a custom max ammo setting and optionally set ammo count to max
* It also supports execution through trigger_script: use ApplyActiveAmmoModOnPlayer to do this
* Note that this requires an active ammo mod to be set
* Set AmmoMod::g_ActiveAmmoMod to an instance of the class to do so
*
*	DO NOT ALTER THIS FILE
*/

namespace AmmoMod
{
class AmmoMod
{
	private dictionary m_AmmoCounts;
	
	private bool m_fSetAmmoToMax = false;
	
	dictionary@ AmmoCounts
	{
		get { return @m_AmmoCounts; }
	}
	
	bool SetAmmoToMax
	{
		get const { return m_fSetAmmoToMax; }
		set { m_fSetAmmoToMax = value; }
	}
	
	void ApplyOnPlayer( CBasePlayer@ pPlayer )
	{
		if( pPlayer is null )
			return;
			
		array<string>@ ammoTypes = m_AmmoCounts.getKeys();
		
		const uint uiSize = ammoTypes.length();
		
		for( uint uiIndex = 0; uiIndex < uiSize; ++uiIndex )
		{
			pPlayer.SetMaxAmmo( ammoTypes[ uiIndex ], int( m_AmmoCounts[ ammoTypes[ uiIndex ] ] ) );
		}
		
		if( m_fSetAmmoToMax )
		{
			for( uint uiIndex = 0; uiIndex < uiSize; ++uiIndex )
			{
				pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( ammoTypes[ uiIndex ] ), int( m_AmmoCounts[ ammoTypes[ uiIndex ] ] ) );
			}
		}
	}
}

AmmoMod@ g_ActiveAmmoMod = null;
}

void ApplyActiveAmmoModOnPlayer( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if( AmmoMod::g_ActiveAmmoMod is null || pActivator is null || !pActivator.IsPlayer() )
		return;
		
	AmmoMod::g_ActiveAmmoMod.ApplyOnPlayer( cast<CBasePlayer@>( pActivator ) );
}
