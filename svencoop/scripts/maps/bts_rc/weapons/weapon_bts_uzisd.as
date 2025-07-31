/*
* Uzi ( Single )
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_uzisd
{
    enum btsuzisd_e
    {
        IDLE1 = 0,
        IDLE2,
        IDLE3,
        RELOAD,
        DRAW,
        SHOOT,
        DRAW2,
        HHHHH,
        AKIMBO_PULL,
        AKIMBO_IDLE,
        AKIMBO_RELOAD_RIGHT,
        AKIMBO_RELOAD_LEFT,
        AKIMBO_RELOAD_BOTH,
        AKIMBO_SHOOT_LEFT,
        AKIMBO_SHOOT_RIGHT,
        AKIMBO_SHOOT_BOTH,
        AKIMBO_DEPLOY
    };

    // Weapon info
    int MAX_CARRY = 120;
    int MAX_CLIP = 20;
    // int DEFAULT_GIVE = Math.RandomLong( 6, 20 );
    int AMMO_GIVE = MAX_CLIP;
    int AMMO_DROP = AMMO_GIVE;
    int WEIGHT = 10;
    // Weapon HUD
    int SLOT = 1;
    int POSITION = 15;
    // Vars
    int DAMAGE = 12;
    Vector SHELL( 32.0f, 6.0f, -12.0f );

    class weapon_bts_uzisd : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_uzisd.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 6, MAX_CLIP );
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
            return bts_deploy( "models/bts_rc/weapons/v_uzisd.mdl", "models/bts_rc/weapons/p_uzisd.mdl", DRAW, "mp5", 2 );
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

        void Reload()
        {
            if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            self.DefaultReload( MAX_CLIP, RELOAD, 2.75f, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
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

            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 7.0f, 9.0f );
        }

        void PrimaryAttack()
        {
            // don't fire underwater
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
                return;
            }

            m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

            --self.m_iClip;

            m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            {
                float x, y;
                g_Utility.GetCircularGaussianSpread( x, y );

                float CONE = Accuracy( 0.015f, 0.0175f, 0.015f, 0.0175f );

                Vector vecDir = vecAiming + x * CONE * g_Engine.v_right + y * CONE * g_Engine.v_up;
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
            }

            self.SendWeaponAnim( SHOOT, 0, pev.body );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/pl_gun2.wav", Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

            if( g_PlayerClass.is_trained_personal(m_pPlayer) )
            {
                m_pPlayer.pev.punchangle.x = -2.25f;
            }
            else
            {
                if( !m_pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
                    m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -5, 3 ));
                else if( m_pPlayer.pev.velocity.Length2D() > 0 )
                    m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -4, 3 ));
                else if( m_pPlayer.pev.FlagBitSet( FL_DUCKING ) )
                    m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -3, 2 ));
                else
                    m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -3, 3 ));
            }

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
            Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, models::shell, TE_BOUNCE_SHELL );

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = g_Engine.time + 0.07f;
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
        }
    }
}
