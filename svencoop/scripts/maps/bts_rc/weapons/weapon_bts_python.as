/*
* Colt Python 357 Magnum
* Author: Rizulix
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_python
{
    enum python_e
    {
        IDLE1 = 0,
        FIDGET,
        SHOOT,
        RELOAD,
        HOLSTER,
        DRAW,
        IDLE2,
        IDLE3
    };

    // Weapon info
    int MAX_CARRY = 18;
    int MAX_CLIP = 6;
    // int DEFAULT_GIVE = Math.RandomLong( 3, 6 );
    int AMMO_GIVE = MAX_CLIP;
    int AMMO_DROP = AMMO_GIVE;
    int WEIGHT = 10;
    // Weapon HUD
    int SLOT = 1;
    int POSITION = 8;
    // Vars
    int DAMAGE = 66;

    class weapon_bts_python : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/hlclassic/w_357.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 3, MAX_CLIP );
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
            return bts_deploy( "models/bts_rc/weapons/v_357.mdl", "models/bts_rc/weapons/p_357.mdl", DRAW, "python", 3 );
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
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
                return;
            }

            m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

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

                float CONE = Accuracy( 0.01f, 0.1f, 0.01f, 0.05f );
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
            switch ( Math.RandomLong( 0, 1 ) )
            {
                case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_shot1.wav", Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM, 0, PITCH_NORM ); break;
                case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_shot2.wav", Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM, 0, PITCH_NORM ); break;
            }
            m_pPlayer.pev.punchangle.x = g_PlayerClass.is_trained_personal(m_pPlayer) ? -10.0f : -16.0f;

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
        }

        void Reload()
        {
            if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            self.DefaultReload( MAX_CLIP, RELOAD, 2.0f, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
            BaseClass.Reload();
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time || self.m_iClip <= 0 )
                return;

            float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );
            if( flRand <= 0.5f )
            {
                self.SendWeaponAnim( IDLE1, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.33f; // ( 70.0f / 30.0f );
            }
            else if( flRand <= 0.7f )
            {
                self.SendWeaponAnim( IDLE2, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f; // ( 60.0f / 30.0f );
            }
            else if( flRand <= 0.9f )
            {
                self.SendWeaponAnim( IDLE3, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.93f; // ( 88.0f / 30.0f );
            }
            else
            {
                self.SendWeaponAnim( FIDGET, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 5.66f; // ( 170.0f / 30.0f );
            }
        }
    }
}
