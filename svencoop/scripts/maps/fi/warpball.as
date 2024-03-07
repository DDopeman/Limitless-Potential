// Warpball based on Half-Life Featureful code, ported to AngelScript.
// "AutoWarpball" function allows automatic warpball configuration based on the spawned monster classname.
// Put it in the "Angelscript function name" property of squadmaker.

class BeamParams
{
	int texture;
	int lifeMin;
	int lifeMax;
	int width;
	int noise;
	int red, green, blue, alpha;
};

int beamTexture;

const string WARPBALL_SPRITE = "sprites/fexplo1.spr";
const string WARPBALL_HUGE_SPRITE = "sprites/b-tele1.spr";
const string WARPBALL_BEAM = "sprites/lgtning.spr";
const string ALIEN_TELEPORT_SOUND = "debris/alien_teleport.wav";
const string WARPBALL_X_SPRITE = "sprites/xflare2.spr";

void PrecacheWarpballResources()
{
	g_Game.PrecacheModel(WARPBALL_SPRITE);
	g_Game.PrecacheModel(WARPBALL_HUGE_SPRITE);
	g_Game.PrecacheModel(WARPBALL_X_SPRITE);
	beamTexture = g_Game.PrecacheModel(WARPBALL_BEAM);
	g_SoundSystem.PrecacheSound(ALIEN_TELEPORT_SOUND);
}

void DrawChaoticBeam(const Vector& in vecOrigin, const Vector& in vecDest, const BeamParams& in params)
{
	NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
	m.WriteByte(TE_BEAMPOINTS);
	m.WriteCoord(vecOrigin.x);
	m.WriteCoord(vecOrigin.y);
	m.WriteCoord(vecOrigin.z);
	m.WriteCoord(vecDest.x);
	m.WriteCoord(vecDest.y);
	m.WriteCoord(vecDest.z);
	m.WriteShort(params.texture);
	m.WriteByte(0);
	m.WriteByte(10);
	m.WriteByte(Math.RandomLong(params.lifeMin, params.lifeMax));
	m.WriteByte(params.width);
	m.WriteByte(params.noise);
	m.WriteByte(params.red);
	m.WriteByte(params.green);
	m.WriteByte(params.blue);
	m.WriteByte(params.alpha);
	m.WriteByte(35);
	m.End();
}

void DrawChaoticBeams(const Vector& in vecOrigin, edict_t@ pentIgnore, int radius, const BeamParams& in params, int iBeams)
{
	int iTimes = 0;
	int iDrawn = 0;
	while( iDrawn < iBeams && iTimes < ( iBeams * 2 ) )
	{
		TraceResult tr;
		Vector vecDest = vecOrigin + radius * ( Vector( Math.RandomFloat(-1,1), Math.RandomFloat(-1,1), Math.RandomFloat(-1,1) ).Normalize() );
		g_Utility.TraceLine( vecOrigin, vecDest, ignore_monsters, pentIgnore, tr );
		if( tr.flFraction != 1.0 )
		{
			// we hit something.
			iDrawn++;
			DrawChaoticBeam(vecOrigin, tr.vecEndPos, params);
		}
		iTimes++;
	}

	// If drew less than half of requested beams, just draw beams without respect to the walls, but with smaller radius.
	if ( iDrawn < iBeams/2 )
	{
		iBeams = Math.min(iBeams-iDrawn, iBeams/2);
		for (int i=0; i<iBeams; ++i)
		{
			Vector vecDest = vecOrigin + radius*0.5f * Vector( Math.RandomFloat(-1,1), Math.RandomFloat(-1,1), Math.RandomFloat(-1,1) );
			DrawChaoticBeam(vecOrigin, vecDest, params);
		}
	}
}

void AutoWarpball(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster)
{
	int red = 77;
	int green = 210;
	int blue = 130;

	int beamRed = 20;
	int beamGreen = 243;
	int beamBlue = 20;
	string sprite = WARPBALL_SPRITE;

	Vector vecOrigin;
	if (pMonster !is null)
	{
		vecOrigin = pMonster.Center();
	}
	else
	{
		vecOrigin = pSquadmaker.pev.origin;
	}

	const string className = pMonster.GetClassname();

	float scale = 1.0;
	int beamRadius = 192;
	int maxBeamCount = 20;
	float attenuation = 0.6;

	const bool smallMonster = className == "monster_headcrab" || className == "monster_houndeye";
	const bool bigMonster = className == "monster_alien_grunt" || className == "monster_bullchicken" || className == "monster_shocktrooper";
	const bool largeMonster = className == "monster_alien_voltigore" || className == "monster_babygarg";
	const bool hugeMonster = className == "monster_gargantua";
	const bool flyingMonster = className == "monster_alien_controller";
	const bool racex = className == "monster_pitdrone" || className == "monster_shocktrooper" || className == "monster_alien_voltigore" || className == "monster_alien_babyvoltigore";

	if (racex)
	{
		red = 200;
		green = 100;
		blue = 200;

		beamRed = 240;
		beamGreen = 80;
		beamBlue = 160;

		sprite = WARPBALL_X_SPRITE;
	}

	if (smallMonster)
	{
		attenuation = 0.8;
		scale = 0.8;
		maxBeamCount = maxBeamCount * 3 / 4;
	}
	else if (hugeMonster)
	{
		scale = 3.5;
		beamRadius = 1024;
		maxBeamCount = 35;
		attenuation = 0.25;
		if (!racex)
			sprite = WARPBALL_HUGE_SPRITE;
	}
	else if (largeMonster)
	{
		scale = 2.0;
		beamRadius = 512;
	}
	else if (bigMonster)
	{
		scale = 1.2;
		beamRadius = 256;
	}
	else if (flyingMonster)
	{
		beamRadius = 256;
	}

	if (bigMonster || largeMonster)
	{
		g_PlayerFuncs.ScreenShake( vecOrigin, 6, 160, 1, beamRadius );
	}

	g_SoundSystem.EmitSound( pSquadmaker.edict(), CHAN_BODY, ALIEN_TELEPORT_SOUND, 1.0, 0.6 );

	CSprite @pSpr = g_EntityFuncs.CreateSprite(sprite, vecOrigin, true);
	if (pSpr !is null)
	{
		pSpr.AnimateAndDie(12.0);
		pSpr.SetTransparency(kRenderGlow, red, green, blue, 255, kRenderFxNoDissipation);
		pSpr.SetScale(scale);
	}

	NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin);
	m.WriteByte(TE_DLIGHT);
	m.WriteCoord(vecOrigin.x);
	m.WriteCoord(vecOrigin.y);
	m.WriteCoord(vecOrigin.z);
	m.WriteByte(int(20 * scale));
	m.WriteByte(red);
	m.WriteByte(green);
	m.WriteByte(blue);
	m.WriteByte(15);
	m.WriteByte(7);
	m.End();

	const int iBeams = Math.RandomLong( maxBeamCount/2, maxBeamCount );
	BeamParams beamParams;
	beamParams.texture = beamTexture;
	beamParams.lifeMin = 5;
	beamParams.lifeMax = 16;
	beamParams.width = 30;
	beamParams.noise = 65;
	beamParams.red = beamRed;
	beamParams.green = beamGreen;
	beamParams.blue = beamBlue;
	beamParams.alpha = 220;
	DrawChaoticBeams(vecOrigin, pSquadmaker.edict(), beamRadius, beamParams, iBeams);
}

class env_teleport_effect : ScriptBaseEntity
{
	private int beamTexture;
	void Spawn()
	{
		Precache();
	}
	void Precache()
	{
		beamTexture = g_Game.PrecacheModel(WARPBALL_BEAM);
		g_SoundSystem.PrecacheSound("debris/beamstart7.wav");
	}
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value = 0.0f )
	{
		if (pActivator is null)
			return;
		const int iBeams = Math.RandomLong( 6, 12 );
		BeamParams beamParams;
		beamParams.texture = beamTexture;
		beamParams.lifeMin = 5;
		beamParams.lifeMax = 16;
		beamParams.width = 18;
		beamParams.noise = 65;
		beamParams.red = 20;
		beamParams.green = 243;
		beamParams.blue = 20;
		beamParams.alpha = 150;
		DrawChaoticBeams(pActivator.EyePosition(), pActivator.edict(), 256, beamParams, iBeams);

		g_SoundSystem.EmitAmbientSound( self.edict(), pActivator.pev.origin, "debris/beamstart7.wav", 1.0, ATTN_STATIC, 0, 100 );
		if (pActivator.IsPlayer())
		{
			g_PlayerFuncs.ScreenFade(pActivator, Vector(0,255,0), 1, 0, 150, FFADE_IN);
		}
	}
};
