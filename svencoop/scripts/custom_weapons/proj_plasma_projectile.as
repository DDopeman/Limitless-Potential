//projectile used for weapon plasma.
//PlasmaProjectile is for primary attack
//PlasmaProjectile2 is for secondary attack

class PlasmaProjectile : ScriptBaseEntity
{
	private CSprite@ cShoot;
	float m_yawCenter;
	float m_pitchCenter;
	void Spawn()
	{
		Precache();
				
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, "models/not_precached2.mdl" );
		self.pev.body = 1;
		self.pev.rendermode = 4;
		self.pev.renderamt = 0;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		@cShoot = g_EntityFuncs.CreateSprite( "sprites/shl/weapons/plasma.spr", self.pev.origin, false ); 
		cShoot.SetTransparency( 5, 0, 0, 0, 255, 1 );
		cShoot.SetAttachment( self.edict(), 0 );
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		cShoot.SetScale( 0.4 );
	}

	void Precache()
	{

	}
	
	void Think()
	{
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
	}

	void Touch( CBaseEntity@ pOther )
	{
		cShoot.SUB_StartFadeOut();
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		TraceResult tr;
		tr = g_Utility.GetGlobalTrace();
		
		entvars_t@ pevOwner = self.pev.owner.vars;
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, plasma_DAMAGE1, plasma_PLASMA_RADIUS_NONE, CLASS_NONE, DMG_ENERGYBEAM | DMG_ALWAYSGIB );
		self.pev.nextthink = g_Engine.time + 0.1f;
		SetTouch( null );
		g_EntityFuncs.Remove( self );
	}
	
}

PlasmaProjectile ShootPlasmaProjectile( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	int r = 250;
	int g = 0;
	int b = 0;
	int br = 250;
	
	CBaseEntity@ cbePlasma = g_EntityFuncs.CreateEntity( "plasma_proj", null,  false);
	PlasmaProjectile@ pPlasma = cast<PlasmaProjectile@>(CastToScriptClass(cbePlasma));
	g_EntityFuncs.SetOrigin( pPlasma.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pPlasma.self.edict() );
	pPlasma.pev.solid = SOLID_BBOX;
	g_EntityFuncs.SetSize( pPlasma.pev, g_vecZero, g_vecZero );
	@pPlasma.pev.owner = pevOwner.pContainingEntity;
	pPlasma.pev.velocity = vecVelocity;
	pPlasma.pev.angles = Math.VecToAngles( pPlasma.pev.velocity );
	const Vector vecAngles = Math.VecToAngles( pPlasma.pev.velocity );
    pPlasma.pev.angles.x = vecAngles.z;
    pPlasma.pev.angles.y = vecAngles.y + 90;
    pPlasma.pev.angles.z = vecAngles.x;
	pPlasma.SetThink( ThinkFunction( pPlasma.Think ) );
	pPlasma.pev.nextthink = g_Engine.time + 0.1f;
	pPlasma.SetTouch( TouchFunction( pPlasma.Touch ) );
	pPlasma.pev.gravity = 0.2f;
	pPlasma.pev.dmg = plasma_DAMAGE1;
	return pPlasma;
}

class PlasmaProjectile2 : ScriptBaseEntity
{
	private CSprite@ cShoot;
	float m_yawCenter;
	float m_pitchCenter;
	void Spawn()
	{
		Precache();
				
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, "models/not_precached2.mdl" );
		self.pev.body = 1;
		self.pev.rendermode = 4;
		self.pev.renderamt = 0;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		@cShoot = g_EntityFuncs.CreateSprite( "sprites/shl/weapons/plasma.spr", self.pev.origin, false ); 
		cShoot.SetTransparency( 5, 0, 0, 0, 255, 1 );
		cShoot.SetAttachment( self.edict(), 0 );
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		cShoot.SetScale( 1.50 );
	}

	void Precache()
	{

	}
	
	void Think()
	{
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
	}

	void Touch( CBaseEntity@ pOther )
	{
		cShoot.SUB_StartFadeOut();
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		TraceResult tr;
		tr = g_Utility.GetGlobalTrace();
		entvars_t@ pevOwner = self.pev.owner.vars;
		self.pev.nextthink = g_Engine.time + 0.1f;
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, plasma_DAMAGE2, plasma_PLASMA_RADIUS_SECONDARY, CLASS_NONE, DMG_ENERGYBEAM | DMG_ALWAYSGIB );
		te_explosionplasma( self.pev.origin, plasma_SPRITE_EXPLODE, int(plasma_DAMAGE2), 15, 4 );
		//ProjectileDynamicLight( self.pev.origin, 8, 255, 255, 255, 1, 150 );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, plasma_SOUND_CHARGE_EXPLODE, 1.0, ATTN_NORM, 0, 97 );
		SetTouch( null );
		g_EntityFuncs.Remove( self );
	}
	
	void te_explosionplasma( Vector origin, string sprite, int scale, int frameRate, int flags )
	{
		NetworkMessage exp1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			exp1.WriteByte( TE_EXPLOSION );
			exp1.WriteCoord( origin.x );
			exp1.WriteCoord( origin.y );
			exp1.WriteCoord( origin.z );
			exp1.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
			exp1.WriteByte( int((scale-50) * .60) );
			exp1.WriteByte( frameRate );
			exp1.WriteByte( flags );
		exp1.End();
	}	
}

PlasmaProjectile2 ShootPlasmaProjectile2( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	int r = 250;
	int g = 0;
	int b = 0;
	int br = 250;
	
	CBaseEntity@ cbePlasma2 = g_EntityFuncs.CreateEntity( "plasma_proj2", null,  false);
	PlasmaProjectile2@ pPlasma2 = cast<PlasmaProjectile2@>(CastToScriptClass(cbePlasma2));
	g_EntityFuncs.SetOrigin( pPlasma2.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pPlasma2.self.edict() );
	pPlasma2.pev.solid = SOLID_BBOX;
	g_EntityFuncs.SetSize( pPlasma2.pev, g_vecZero, g_vecZero );
	@pPlasma2.pev.owner = pevOwner.pContainingEntity;
	pPlasma2.pev.velocity = vecVelocity;
	pPlasma2.pev.angles = Math.VecToAngles( pPlasma2.pev.velocity );
	const Vector vecAngles = Math.VecToAngles( pPlasma2.pev.velocity );
    pPlasma2.pev.angles.x = vecAngles.z;
    pPlasma2.pev.angles.y = vecAngles.y + 90;
    pPlasma2.pev.angles.z = vecAngles.x;
	pPlasma2.SetThink( ThinkFunction( pPlasma2.Think ) );
	pPlasma2.pev.nextthink = g_Engine.time + 0.1f;
	pPlasma2.SetTouch( TouchFunction( pPlasma2.Touch ) );
	pPlasma2.pev.gravity = 0.3f;
	pPlasma2.pev.dmg = plasma_DAMAGE2;
	return pPlasma2;
}

class PlasmaProjectileSmall : ScriptBaseEntity
{
	private CSprite@ cShoot;
	float m_yawCenter;
	float m_pitchCenter;
	void Spawn()
	{
		Precache();
				
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, "models/not_precached2.mdl" );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		@cShoot = g_EntityFuncs.CreateSprite( "sprites/shl/weapons/plasmasmall.spr", self.pev.origin, false ); 
		cShoot.SetTransparency( 5, 0, 0, 0, 255, 1 );
		cShoot.SetAttachment( self.edict(), 0 );
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		cShoot.SetScale( 1.50 );
	}

	void Precache()
	{

	}
	
	void Think()
	{
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
	}

	void Touch( CBaseEntity@ pOther )
	{
		cShoot.SUB_StartFadeOut();
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		TraceResult tr;
		tr = g_Utility.GetGlobalTrace();
		entvars_t@ pevOwner = self.pev.owner.vars;
		self.pev.nextthink = g_Engine.time + 0.1f;
		SetThink( ThinkFunction( this.ImpactSprite ) );
	}
	
	void ImpactSprite()
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		SetThink( null );
		te_explosionplasma( self.pev.origin, plasma_SPRITE_EXPLODE, int(plasma_DAMAGE2), 15, 4 );
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.nextthink = g_Engine.time + 0.1f;
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, plasma_SOUND_CHARGE_EXPLODE, 1.0, ATTN_NORM, 0, 97 );
		g_EntityFuncs.Remove( self );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		g_EntityFuncs.Remove( self );
	}
	
	void te_explosionplasma( Vector origin, string sprite, int scale, int frameRate, int flags )
	{
		NetworkMessage exp1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
		exp1.WriteByte( TE_EXPLOSION );
		exp1.WriteCoord( origin.x );
		exp1.WriteCoord( origin.y );
		exp1.WriteCoord( origin.z );
		exp1.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
		exp1.WriteByte( int((scale-50) * .60) );
		exp1.WriteByte( frameRate );
		exp1.WriteByte( flags );
		exp1.End();
	}	
}

void RegisterPlasmaProjectile()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "PlasmaProjectile", "plasma_proj" );
}

void RegisterPlasmaProjectile2()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "PlasmaProjectile2", "plasma_proj2" );
}