// Suppressed Glock 17
// Models: Valve Software, Gearbox Software
// Scripts: Giegue, Rizulix, Valve Software
// Sound: Valve Software
// Sprites: Valve Software, TurtleRock Studios, SV BOY
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_glocksd
{
    enum hlglocksd_e
    {
        IDLE1 = 0,
        IDLE2,
        IDLE3,
        SHOOT,
        SHOOT_EMPTY,
        RELOAD_EMPTY,
        RELOAD,
        DRAW,
        HOLSTER,
        ADD_SILENCER
    };

    // Weapon info
    int MAX_CARRY = 120;
    int MAX_CLIP = 17;
    // int DEFAULT_GIVE = Math.RandomLong( 8, 17 );
    int AMMO_GIVE = MAX_CLIP;
    int AMMO_DROP = AMMO_GIVE;
    int WEIGHT = 10;
    // Weapon HUD
    int SLOT = 1;
    int POSITION = 5;
    // Vars
    int DAMAGE = 12;
    Vector SHELL( 32.0f, 6.0f, -12.0f );

    class weapon_bts_glocksd : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_9mmhandgunsd.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 8, MAX_CLIP );
            self.FallInit();
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = AMMO_DROP;
            info.iMaxAmmo2 = -1;
            info.iAmmo2Drop = -1;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName( pev.classname );
            info.iFlags = m_flags;
            info.iWeight = WEIGHT;
            return true;
        }

        bool Deploy()
        {
            return bts_deploy( "models/bts_rc/weapons/v_9mmhandgunsd.mdl", "models/bts_rc/weapons/p_9mmhandgunsd.mdl", DRAW, "onehanded", 2 );
        }

        void Holster( int skiplocal = 0 )
        {
            BaseClass.Holster( skiplocal );
        }

        bool PlayEmptySound()
        {
            if( self.m_bPlayEmptySound )
            {
                self.m_bPlayEmptySound = false;
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
            }
            return false;
        }

        void PrimaryAttack()
        {
            Fire( Accuracy( 0.01f, 0.02f, 0.005f, 0.01f ), 0.3f );
        }

        void SecondaryAttack()
        {
            Fire( Accuracy( 0.1f, 0.2f, 0.01f, 0.02f ), 0.2f);
        }

        void Reload()
        {
            if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            self.DefaultReload( MAX_CLIP, self.m_iClip != 0 ? RELOAD : RELOAD_EMPTY, 1.5f, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
            BaseClass.Reload();
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
            {
                case 0: self.SendWeaponAnim( IDLE1, 0, pev.body ); break; 
                case 1: self.SendWeaponAnim( IDLE2, 0, pev.body ); break; 
                default: self.SendWeaponAnim( IDLE3, 0, pev.body ); break;
            }

            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
        }

        private void Fire( const float& in flSpread, float flCycleTime )
        {
            if( self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
                return;
            }

            m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

            --self.m_iClip;

            m_pPlayer.pev.effects &= ~EF_MUZZLEFLASH;
            pev.effects &= ~EF_MUZZLEFLASH;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

            float x, y;
            g_Utility.GetCircularGaussianSpread( x, y );

            Vector vecDir = vecAiming + x * flSpread * g_Engine.v_right + y * flSpread * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            bts_post_attack(tr);

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }

            self.SendWeaponAnim( self.m_iClip != 0 ? SHOOT : SHOOT_EMPTY, 0, pev.body );
            switch( Math.RandomLong( 0, 1 ) )
            {
                case 0: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/glocksd_fire1.wav", Math.RandomFloat( 0.9f, 1.0f ), ATTN_NORM ); break;
                case 1: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/glocksd_fire2.wav", Math.RandomFloat( 0.9f, 1.0f ), ATTN_NORM ); break;
            }
            m_pPlayer.pev.punchangle.x = is_trained_personal ? -2.0f : -2.65f;

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
            Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, models::shell, TE_BOUNCE_SHELL );

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;
            self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        }
    }
}
