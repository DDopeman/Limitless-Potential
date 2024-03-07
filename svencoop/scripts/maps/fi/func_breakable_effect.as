// Based on Half-Life Featureful code, ported to AngelScript

const int ENV_BREAKABLE_REPEATABLE = 1;

string DefaultMaterialGibModel( Materials material )
{
	switch( material )
	{
	case matWood:
		return "models/woodgibs.mdl";
	case matFlesh:
		return "models/fleshgibs.mdl";
	case matComputer:
		return "models/computergibs.mdl";
	case matUnbreakableGlass:
	case matGlass:
		return "models/glassgibs.mdl";
	case matMetal:
		return "models/metalplategibs.mdl";
	case matCinderBlock:
		return "models/cindergibs.mdl";
	case matRocks:
		return "models/rockgibs.mdl";
	case matCeilingTile:
		return "models/ceilinggibs.mdl";
	case matNone:
	case matLastMaterial:
		break;
	default:
		break;
	}
	return '';
}

void PrecacheMaterialBustSounds( Materials material )
{
	switch( material )
	{
	case matWood:
		g_SoundSystem.PrecacheSound( "debris/bustcrate1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustcrate2.wav" );
		break;
	case matFlesh:
		g_SoundSystem.PrecacheSound( "debris/bustflesh1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustflesh2.wav" );
		break;
	case matComputer:
		g_SoundSystem.PrecacheSound( "buttons/spark5.wav" );
		g_SoundSystem.PrecacheSound( "buttons/spark6.wav" );

		g_SoundSystem.PrecacheSound( "debris/bustmetal1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustmetal2.wav" );
		break;
	case matUnbreakableGlass:
	case matGlass:
		g_SoundSystem.PrecacheSound( "debris/bustglass1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustglass2.wav" );
		break;
	case matMetal:
		g_SoundSystem.PrecacheSound( "debris/bustmetal1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustmetal2.wav" );
		break;
	case matCinderBlock:
		g_SoundSystem.PrecacheSound( "debris/bustconcrete1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustconcrete2.wav" );
		break;
	case matRocks:
		g_SoundSystem.PrecacheSound( "debris/bustconcrete1.wav" );
		g_SoundSystem.PrecacheSound( "debris/bustconcrete2.wav" );
		break;
	case matCeilingTile:
		g_SoundSystem.PrecacheSound( "debris/bustceiling.wav" );
		break;
	case matNone:
	case matLastMaterial:
		break;
	default:
		break;
	}
}

uint8 PlayBreakableBustSound( CBaseEntity@ pEntity, Materials material, float fvol, int pitch )
{
	switch( material )
	{
	case matGlass:
		switch( Math.RandomLong(0,1) )
		{
		case 0:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustglass1.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustglass2.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		}
		return BREAK_GLASS;
	case matWood:
		switch( Math.RandomLong(0,1) )
		{
		case 0:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustcrate1.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustcrate2.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		}
		return BREAK_WOOD;
	case matComputer:
	case matMetal:
		switch( Math.RandomLong(0,1) )
		{
		case 0:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustmetal1.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustmetal2.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		}
		return BREAK_METAL;
	case matFlesh:
		switch( Math.RandomLong(0,1) )
		{
		case 0:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustflesh1.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustflesh2.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		}
		return BREAK_FLESH;
	case matRocks:
	case matCinderBlock:
		switch( Math.RandomLong(0,1) )
		{
		case 0:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustconcrete1.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustconcrete2.wav", fvol, ATTN_NORM, 0, pitch );
			break;
		}
		return BREAK_CONCRETE;
	case matCeilingTile:
		g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "debris/bustceiling.wav", fvol, ATTN_NORM, 0, pitch );
		break;
	case matNone:
	case matLastMaterial:
	case matUnbreakableGlass:
		break;
	default:
		break;
	}
	return 0;
}

class func_breakable_effect : ScriptBaseEntity
{
	Materials m_Material;
	string m_iszGibModel;
	int m_iGibs;
	int m_idShard;

	void Spawn()
	{
		Precache();
		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;

		g_EntityFuncs.SetModel( self, pev.model );
		pev.effects |= EF_NODRAW;
	}
	void Precache()
	{
		PrecacheMaterialBustSounds(m_Material);
		g_EntityFuncs.PrecacheMaterialSounds(m_Material);

		string pGibName = '';
		if( m_iszGibModel != '' )
			pGibName = m_iszGibModel;
		else
			pGibName = DefaultMaterialGibModel(m_Material);

		m_idShard = g_Game.PrecacheModel( pGibName );
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "material" )
		{
			int i = atoi( szValue );
			if( ( i < 0 ) || ( i >= matLastMaterial ) )
				m_Material = matWood;
			else
				m_Material = Materials(i);

			return true;
		}
		else if( szKey == "gibmodel" )
		{
			m_iszGibModel = szValue;
			return true;
		}
		else if ( szKey == "m_iGibs" )
		{
			m_iGibs = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Use(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float value)
	{
		int pitch = 95 + Math.RandomLong( 0, 29 );

		if( pitch > 97 && pitch < 103 )
			pitch = 100;

		float fvol = Math.RandomFloat( 0.85, 1.0 );

		if( fvol > 1.0 )
			fvol = 1.0;

		uint8 cFlag = PlayBreakableBustSound(self, m_Material, fvol, pitch);

		Vector vecSpot = pev.origin + ( pev.mins + pev.maxs ) * 0.5;
		
		NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpot);
		m.WriteByte(TE_BREAKMODEL);
		m.WriteCoord(vecSpot.x);
		m.WriteCoord(vecSpot.y);
		m.WriteCoord(vecSpot.z);
		m.WriteCoord(pev.size.x);
		m.WriteCoord(pev.size.y);
		m.WriteCoord(pev.size.z);
		m.WriteCoord(0);
		m.WriteCoord(0);
		m.WriteCoord(0);
		m.WriteByte(10);
		m.WriteShort(m_idShard);
		m.WriteByte(m_iGibs);
		m.WriteByte(25);
		m.WriteByte(cFlag);
		m.End();

		if ((pev.spawnflags & ENV_BREAKABLE_REPEATABLE) == 0)
			g_EntityFuncs.Remove(self);
	}
};
