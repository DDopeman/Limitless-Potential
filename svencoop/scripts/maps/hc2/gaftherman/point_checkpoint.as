#include 'pcp_misc/cbasekeepdata'
#include 'pcp_misc/think'
#include 'pcp_misc/misc'

enum PointCheckPointFlags
{
    SF_CHECKPOINT_STARTOFF = 1 << 0,
    SF_CHECKPOINT_USE_ONLY = 1 << 1,
    SF_CHECKPOINT_REUSABLE = 1 << 2,
}

class point_checkpoint : ScriptBaseAnimating  
{
    dictionary dicPlayerSaved, dicNewCheckpoint;
    EHandle hCreatedCheckPoint = null;

    string ActivationMusic = '../media/valve.mp3';
    string PlayerSpawnSound = 'debris/beamstart7.wav';
    string SpawnSprite = 'sprites/exit1.spr';

    float DelayBeforeReactivation = 0.0f;

    bool SpawnEffect = false;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if(szKey == 'minhullsize')
            g_Utility.StringToVector(self.pev.vuser1, szValue);
        else if(szKey == 'maxhullsize')
            g_Utility.StringToVector(self.pev.vuser2, szValue);
        else if(szKey == 'music') 
            ActivationMusic = szValue;
        else if(szKey == 'sprite')
            SpawnSprite = szValue;
        else if(szKey == 'DelayBeforeReactivation' || szKey == 'm_flDelayBeforeStart')
            DelayBeforeReactivation = atof(szValue);
        else if(szKey == 'MaxReactivations')
            self.pev.iuser1 = atoi(szValue); 
        else if( szKey == 'SpawnEffect' || szKey == 'm_fSpawnEffect' )
            SpawnEffect = atoi( szValue ) != 0;
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        Precache();

        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_TRIGGER;

        self.pev.rendermode = kRenderTransTexture;
        self.pev.renderamt = self.pev.SpawnFlagBitSet(SF_CHECKPOINT_STARTOFF) ? 125 : 255;

        self.pev.health = 1.0f;
        self.pev.frags = 0.0f;
        self.pev.speed = 1.0f;
        self.pev.framerate = self.pev.SpawnFlagBitSet(SF_CHECKPOINT_STARTOFF) ? 0.0f : 1.0f;
        self.pev.iuser1 = (self.pev.iuser1 == 0) ? 0 : self.pev.iuser1 + 1;
        self.pev.iuser2 = (self.pev.iuser1 == 0) ? 0 : 1;

        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        g_EntityFuncs.SetModel(self, string( self.pev.model ).IsEmpty() ? string_t( self.pev.model = 'models/common/lambda.mdl') : self.pev.model);
        g_EntityFuncs.SetSize(self.pev, (self.pev.vuser1 != g_vecZero) ? self.pev.vuser1 : Vector(-8,-8,-16), (self.pev.vuser1 != g_vecZero) ? self.pev.vuser2 : Vector(8,-8,-16));
        
        PCP_MISC::SetAnim(self, 0);
        PCP_MISC::SaveCheckPoint(self, dicNewCheckpoint, ActivationMusic, SpawnSprite, DelayBeforeReactivation, self.pev.iuser2);
        PCP_MISC::SetEnabled(self, (g_SurvivalMode.MapSupportEnabled() && !g_SurvivalMode.IsActive()) ? false : true);

        if(PCP_MISC::IsEnabled(self))
        {
            if(!string(self.pev.netname).IsEmpty())
                g_EntityFuncs.FireTargets( self.pev.netname, self, self, USE_TOGGLE);
                
            if(SpawnEffect)
                PCP_MISC::CreateSpawnEffect(self.pev.origin);
        }

        SetThink(ThinkFunction(this.IdleThink));
        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void Precache()
    {
        g_Game.PrecacheModel(string(self.pev.model).IsEmpty() ? string_t(self.pev.model = 'models/common/lambda.mdl') : self.pev.model);
        g_Game.PrecacheGeneric(string(self.pev.model).IsEmpty() ? string_t(self.pev.model = 'models/common/lambda.mdl') : self.pev.model);

        g_Game.PrecacheModel(SpawnSprite);
        g_Game.PrecacheGeneric(SpawnSprite);

        g_SoundSystem.PrecacheSound(string(self.pev.message).IsEmpty() ? string_t(self.pev.message = 'debris/beamstart4.wav') : self.pev.message);
        g_Game.PrecacheGeneric(string(self.pev.message).IsEmpty() ?  string_t(self.pev.message = 'sound/debris/beamstart4.wav') : string_t('sound/' + self.pev.message));

        g_SoundSystem.PrecacheSound(ActivationMusic);
        g_Game.PrecacheGeneric('sound/' + ActivationMusic);

        BaseClass.Precache();
    }

    int ObjectCaps()
    {
        return ((!PCP_MISC::IsActivated(self) && !PCP_MISC::IsReenable(self) && self.pev.SpawnFlagBitSet(SF_CHECKPOINT_USE_ONLY))) ? BaseClass.ObjectCaps() | FCAP_IMPULSE_USE : BaseClass.ObjectCaps();
    }

    void Touch(CBaseEntity@ pOther)
    {
        if(pOther is null || !pOther.IsPlayer() || self.pev.SpawnFlagBitSet(SF_CHECKPOINT_USE_ONLY))
            return;
        
        self.Use(pOther, self, USE_SET);
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
    {
        if(pActivator !is null && !PCP_MISC::IsActivated(self) && PCP_MISC::IsDrawable(self) && (self.pev.SpawnFlagBitSet(SF_CHECKPOINT_USE_ONLY) || pActivator.IsPlayer() && !self.pev.SpawnFlagBitSet(SF_CHECKPOINT_USE_ONLY)) || pActivator is null && !PCP_MISC::IsActivated(self) && PCP_MISC::IsDrawable(self))
        {
            switch(useType)
            {
                case USE_ON:
                {
                    if(self.pev.SpawnFlagBitSet(SF_CHECKPOINT_STARTOFF))
                    {
                        self.pev.health = 1.0f;
                        self.pev.renderamt = 255;
                        self.pev.framerate = 1.0f;
                        self.pev.spawnflags &= ~SF_CHECKPOINT_STARTOFF;
                    }
                    else 
                    {
                        self.Use(pActivator, pCaller, USE_SET, flValue);
                    }
                    break;
                }

                case USE_OFF:
                {
                    self.pev.health = 0.0f;
                    self.pev.renderamt = 125;
                    self.pev.framerate = 0.0f;
                    self.pev.spawnflags |= SF_CHECKPOINT_STARTOFF;
                    break;
                }
                
                case USE_TOGGLE:
                {	
                    self.Use(pActivator, pCaller, self.pev.SpawnFlagBitSet(SF_CHECKPOINT_STARTOFF) ? USE_ON : USE_OFF, flValue);
                    break;
                }

                case USE_SET:
                {
                    if(!PCP_MISC::IsEnabled(self))
                        return;

                    g_Game.AlertMessage( at_logged, "CHECKPOINT: \"%1\" activated Checkpoint\n", (pActivator is null) ? string_t('\'The world\'') : pActivator.pev.netname );
                    g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "" + ((pActivator is null) ? string_t('\'The world\'') : string_t('\''+pActivator.pev.netname+'\'')) + " just activated a Respawn-Point.\n" );

                    self.pev.frags = 1.0f;

                    g_SoundSystem.EmitSound(self.edict(), CHAN_STATIC, ActivationMusic, 1.0f, ATTN_NONE);

                    for(int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer)
                    {
                        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iPlayer);

                        if(pPlayer is null || !pPlayer.IsConnected())
                            continue;

                        CBaseKeepData@ pData = GetPlayerSpawn(pPlayer);
                        pData.health = pPlayer.pev.health;
                        pData.max_health = pPlayer.pev.max_health;
                        pData.armor = pPlayer.pev.armorvalue;
                        pData.max_armor = pPlayer.pev.armortype;
                        pData.spawn_number = PCP_MISC::SetAndGetData(PCP_MISC::GetSteamID(pPlayer) + '_spawn_number', +1);

                        PCP_MISC::SetCKV( pPlayer, '$i_pcp_spawns', +1 ); 
                    }

                    self.SUB_UseTargets(pActivator, useType, flValue);

                    if(string(self.m_iszKillTarget) != '' && string(self.m_iszKillTarget) != self.GetTargetname())
                    {
                        do g_EntityFuncs.Remove(g_EntityFuncs.FindEntityByTargetname(null, string( self.m_iszKillTarget)));
                        while(g_EntityFuncs.FindEntityByTargetname(null, string(self.m_iszKillTarget)) !is null);
                    }

                    SetThink(ThinkFunction(this.FadeThink));
                    self.pev.nextthink = g_Engine.time + 0.1f;
                    break;
                }
            }
        }
    }

    void IdleThink()
    {
        self.StudioFrameAdvance();
        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void FadeThink()
    {
        self.StudioFrameAdvance();

        if(self.pev.renderamt > 65)
        {			
            self.pev.renderamt -= 10;
            if(self.pev.renderamt < 65)
                self.pev.renderamt = 65;

            self.pev.nextthink = g_Engine.time + 0.1f;
        }
        else
        {
            if(self.pev.SpawnFlagBitSet(SF_CHECKPOINT_REUSABLE))
            {
                SetThink(ThinkFunction(this.ReenableThink));
                self.pev.nextthink = g_Engine.time + DelayBeforeReactivation;
            }
            else
            {
                SetThink(ThinkFunction(this.IdleThink));
                self.pev.nextthink = g_Engine.time + 0.1f;
            }
        }
    }
    
    void ReenableThink()
    {
        if(hCreatedCheckPoint)
        {
            hCreatedCheckPoint.GetEntity().pev.dmg = 1.0f;
            hCreatedCheckPoint.GetEntity().pev.effects |= EF_NODRAW;
            hCreatedCheckPoint.GetEntity().pev.targetname = '';
            hCreatedCheckPoint.GetEntity().pev.netname = '';
        }
        else 
        {
            self.pev.dmg = 1.0f;
            self.pev.effects |= EF_NODRAW;
            self.pev.targetname = '';
            self.pev.netname = '';
        }

        if(self.pev.iuser2 == 0) 
        {
            CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity(self.pev.classname, dicNewCheckpoint, true);
            pEntity.pev.frame = self.pev.frame;
        }
        else
        {
            if(--self.pev.iuser1 > 0)
            {
                CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity(self.pev.classname, dicNewCheckpoint, true);
                pEntity.pev.frame = self.pev.frame;
                hCreatedCheckPoint = EHandle(@pEntity);

                SetThink(ThinkFunction(this.VerifyMaxActivations));
                self.pev.nextthink = g_Engine.time + 0.1f;
            }
        }
    }

    void VerifyMaxActivations()
    {
        if(hCreatedCheckPoint && !PCP_MISC::IsActivated(cast<CBaseAnimating@>(hCreatedCheckPoint.GetEntity())))
        {
            self.pev.nextthink = g_Engine.time + 0.1f;
        }
        else
        {
            SetThink(ThinkFunction(this.ReenableThink));
            self.pev.nextthink = g_Engine.time + DelayBeforeReactivation;
        }
    }

    CBaseKeepData@ GetPlayerSpawn(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected())
            return null;

        string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

        if(SteamID == 'STEAM_ID_LAN' || SteamID == 'STEAM_ID_BOT')
        {
            SteamID = pPlayer.pev.netname;
        }

        if(!dicPlayerSaved.exists(SteamID))
        {
            CBaseKeepData pData;
            dicPlayerSaved[SteamID] = pData;
        }

        return cast<CBaseKeepData@>(dicPlayerSaved[SteamID]);
    }
}

void RegisterPointCheckPointEntity() 
{
    g_CustomEntityFuncs.RegisterCustomEntity( 'point_checkpoint', 'point_checkpoint' );
}
