enum bullettype
{
	BULLET_GLOCK = 0,
	BULLET_M16,
	BULLET_DEAGLE,
	BULLET_SNIPER
};

const array<string> pBPTextures = 
{
	"c2a2_dr",	//Blast Door
	"c2a5_dr"	//Secure Access
};

int DAMAGE_GLOCK	= 12;
int DAMAGE_M16		= 15;
int DAMAGE_DEAGLE	= 44;
int DAMAGE_SNIPER	= 110;

Vector FirePenetratingBullet( Vector vecSrc, Vector vecDirShooting, Vector vecSpread, float flDistance, int iBulletType, entvars_t@ pevAttacker )
{
	TraceResult tr, beam_tr, beam_tr_end;
	float x = 0, y = 0, z = 0;
	int iPiercePower = 0; 
	int iDmgType = 0;
	float iDamage = 0;
	string szTextureName;

	x = Math.RandomFloat(-0.5,0.5) + Math.RandomFloat(-0.5,0.5);
	y = Math.RandomFloat(-0.5,0.5) + Math.RandomFloat(-0.5,0.5);

	Vector vecDir = vecDirShooting + x*vecSpread.x*g_Engine.v_right + y*vecSpread.y*g_Engine.v_up;
	Vector vecEnd = vecSrc + vecDir * flDistance;
	g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pevAttacker.pContainingEntity, tr );

	CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
	szTextureName = g_Utility.TraceTexture( null, vecSrc, vecEnd );

	switch( iBulletType )
	{
		case BULLET_GLOCK:
			iPiercePower = 15;
			iDmgType = DMG_BULLET;
			iDamage = DAMAGE_GLOCK;
		break;

		case BULLET_M16:
			iPiercePower = 25;
			iDmgType = DMG_BULLET;
			iDamage = DAMAGE_M16;
		break;
		
		case BULLET_DEAGLE:
			iPiercePower = 55;
			iDmgType = DMG_BULLET;
			iDamage = DAMAGE_DEAGLE;
		break;
		
		case BULLET_SNIPER:
			iPiercePower = 70;
			iDmgType = DMG_BULLET;
			iDamage = DAMAGE_SNIPER;
		break;
		
		default:
		break;
	}

	if( pBPTextures.find( szTextureName ) != -1 )
			g_Utility.Ricochet( tr.vecEndPos, 1.0 );
	else
		g_WeaponFuncs.DecalGunshot( tr, iBulletType );

	if( pEntity.pev.takedamage != DAMAGE_NO )
	{
		g_WeaponFuncs.ClearMultiDamage();
		pEntity.TraceAttack( pevAttacker, iDamage, vecDir, tr, iDmgType | DMG_NEVERGIB );
		g_WeaponFuncs.ApplyMultiDamage( pevAttacker, pevAttacker );
	}

	g_Utility.TraceLine( tr.vecEndPos + vecDir * 8, vecEnd, dont_ignore_monsters, pevAttacker.pContainingEntity, beam_tr );

	if( beam_tr.fAllSolid == 0)
	{
		if( pBPTextures.find( szTextureName ) != -1 )
			return Vector( x * vecSpread.x, y * vecSpread.y, 0.0 );

		g_Utility.TraceLine( beam_tr.vecEndPos, tr.vecEndPos, dont_ignore_monsters, pevAttacker.pContainingEntity, beam_tr);

		if( (beam_tr.vecEndPos - tr.vecEndPos).Length() > (iPiercePower) )
			return Vector( x * vecSpread.x, y * vecSpread.y, 0.0 );

		g_WeaponFuncs.DecalGunshot( beam_tr, iBulletType );
		g_Utility.TraceLine( beam_tr.vecEndPos, vecEnd, dont_ignore_monsters, pevAttacker.pContainingEntity, beam_tr_end);

		CBaseEntity@ pExitEntity = g_EntityFuncs.Instance( beam_tr_end.pHit );

		g_WeaponFuncs.DecalGunshot( beam_tr_end, iBulletType );

		if( pExitEntity.pev.takedamage != DAMAGE_NO )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pExitEntity.TraceAttack( pevAttacker, iDamage/2, vecDir, beam_tr_end, iDmgType | DMG_NEVERGIB );
			g_WeaponFuncs.ApplyMultiDamage( pevAttacker, pevAttacker);
		} 
	}
	return Vector( x * vecSpread.x, y * vecSpread.y, 0.0 );
}