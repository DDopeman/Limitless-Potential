// Afraid of Monsters: Director's Cut Script
// Misc Script: Pills
// Author: Zorbos

const int AOMPILLS_GIVE = 25;
const int AOMPILLS_GIVE_SURVIVAL = 20;

class item_aompills: ScriptBasePlayerAmmoEntity
{
	private int m_iAmountToGive;
	private bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	
	void Spawn()
	{ 
		Precache();

		if( self.SetupModel() == false )
		{
			g_EntityFuncs.SetModel( self, "models/aomdc/items/w_medkit.mdl" );
		}
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
		
		if(bSurvivalEnabled)
			self.pev.spawnflags = 1280;// +USE only AND Never Respawn
		else
			self.pev.spawnflags = 256; // +USE only
		
		// Makes it slightly easier to pickup
		g_EntityFuncs.SetSize(self.pev, Vector( -4, -4, -1 ), Vector( 4, 4, 1 ));
	}
	
	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel("models/aomdc/items/w_medkit.mdl");
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound("aomdc/items/smallmedkit1.wav");
	}
	
	bool AddAmmo(CBaseEntity@ pOther)
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		
		// Can't take pills if health is already full!
		if(pPlayer.pev.health < 100)
		{
			if(bSurvivalEnabled)
				m_iAmountToGive = AOMPILLS_GIVE_SURVIVAL;
			else
				m_iAmountToGive = AOMPILLS_GIVE;
				
			NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
				message.WriteString("item_healthkit"); // Show the healthkit icon on the HUD
			message.End();
		
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "aomdc/items/smallmedkit1.wav", 1, ATTN_NORM);
			
			// Set a floor on the new health if the amount added goes over the maximum
			if((pPlayer.pev.health + m_iAmountToGive) > 100)
				pPlayer.pev.health = 100;
			else
				pPlayer.pev.health += m_iAmountToGive;
				
			return true;
		}
		
		return false;
	}
}

void RegisterAOMPills()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "item_aompills", "item_aompills");
}