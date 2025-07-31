// Flashlight/Torchlight
// Original Code: Mikk
// Models: Valve Software, Gearbox Software, dydwk747, ruMpel ( Battery model )
// Sprites: Patofan05
// Thanks Mikk for scripting full support
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_flashlight
{
    enum btsflashlight_e
    {
        IDLE = 0,
        DRAW,
        HOLSTER,
        ATTACK1HIT,
        ATTACK1MISS,
        ATTACK2MISS,
        ATTACK2HIT,
        ATTACK3MISS,
        ATTACK3HIT,
        IDLE2,
        IDLE3
    };

    // Weapon info
    int MAX_CARRY = 10;
    int MAX_CLIP = WEAPON_NOCLIP;
    // int DEFAULT_GIVE = 10;
    int AMMO_GIVE = 1;
    int AMMO_DROP = 1;
    int WEIGHT = 10;
    // Weapon HUD
    int SLOT = 4;
    int POSITION = 4;
    // Vars
    float RANGE = 32.0f;
    float DAMAGE = 7.0f;
    float DRAIN_TIME = 0.8f;

    class weapon_bts_flashlight : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon, bts_rc_base_melee
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        private int m_iFlashBattery
        {
            get const {
                if( !m_pPlayer.GetUserData().exists( pev.classname ) ) {
                    m_pPlayer.GetUserData()[ pev.classname ] = Math.RandomLong( 0, 50 );
                }
                return int( m_pPlayer.GetUserData()[ pev.classname ] );
            }
            set { m_pPlayer.GetUserData()[ pev.classname ] = value; }
        }

        private float m_flFlashLightTime;
        private bool m_bWasFlashLightOn;
        private float m_bFlashLightTurnTime;
        private int m_iCurrentBaterry;

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_flashlight.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 0, 2 );
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

        bool CanDeploy()
        {
            return true;
        }

        bool Deploy()
        {
            m_bWasFlashLightOn = false;
            m_iCurrentBaterry = m_iFlashBattery;
            m_pPlayer.pev.effects &= ~EF_DIMLIGHT; // just to be sure
            m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
                msg.WriteByte( 0 );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            return bts_deploy( "models/bts_rc/weapons/v_flashlight.mdl", "models/bts_rc/weapons/p_flashlight.mdl", DRAW, "crowbar", 1 );
        }

        void Holster( int skiplocal = 0 )
        {
            SetThink( null );
            g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            if ( m_pPlayer.FlashlightIsOn() )
                FlashlightTurnOff();

            m_iFlashBattery = m_iCurrentBaterry;
            m_pPlayer.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
            BaseClass.Holster( skiplocal );
        }

        void ItemPostFrame()
        {
            if( m_bWasFlashLightOn && m_bFlashLightTurnTime < g_Engine.time )
            {
                m_pPlayer.pev.effects |= EF_DIMLIGHT;
                m_bWasFlashLightOn = false;
            }

            if( m_flFlashLightTime != 0.0f && m_flFlashLightTime <= g_Engine.time )
            {
                if( m_pPlayer.FlashlightIsOn() )
                {
                    if( m_iCurrentBaterry != 0 )
                    {
                        m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
                        --m_iCurrentBaterry;

                        if( m_iCurrentBaterry == 0 )
                            FlashlightTurnOff();
                    }
                }
                else
                {
                    m_flFlashLightTime = 0.0f;
                }

                NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
                    msg.WriteByte( m_iCurrentBaterry );
                msg.End();
            }
            BaseClass.ItemPostFrame();
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

        void SecondaryAttack()
        {
            if( m_iCurrentBaterry == 0 )
            {
                if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                {
                    self.PlayEmptySound();
                    self.m_flNextSecondaryAttack = g_Engine.time + 0.3f;
                }
                else
                {
                    SetThink( null );
                    m_flFlashLightTime = 0.0f;

                    SetThink( ThinkFunction( BaterryRechargeStart ) );
                    pev.nextthink = g_Engine.time + ( 5.0f / 25.0f );

                    self.SendWeaponAnim( HOLSTER, 0, pev.body );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 20.0f; // just block
                }
            }
            else
            {
                if( m_pPlayer.FlashlightIsOn() )
                    FlashlightTurnOff();
                else
                    FlashlightTurnOn();

                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.3f;
            }
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
            {
                case 0: self.SendWeaponAnim( IDLE3, 0, pev.body ); break; 
                case 1: self.SendWeaponAnim( IDLE2, 0, pev.body ); break; 
                default: self.SendWeaponAnim( IDLE, 0, pev.body ); break;
            }

            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
        }

        private void BaterryRechargeStart()
        {
            SetThink( ThinkFunction( BaterryRechargeEnd ) );
            pev.nextthink = g_Engine.time + 4.0f;

            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        }

        private void BaterryRechargeEnd()
        {
            SetThink( null );

            self.SendWeaponAnim( DRAW, 0, pev.body );
            m_iFlashBattery = m_iCurrentBaterry = 100;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            m_pPlayer.m_flNextAttack = 0.5f;
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 14.0f / 25.0f );
        }

        private void FlashlightTurnOn()
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/flashlight1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
            m_pPlayer.pev.effects |= EF_DIMLIGHT;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
                msg.WriteByte( 1 );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
        }

        private void FlashlightTurnOff()
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/flashlight1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
            m_pPlayer.pev.effects &= ~EF_DIMLIGHT;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
                msg.WriteByte( 0 );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            m_flFlashLightTime = 0.0f;
        }

        private bool Swing( bool fFirst )
        {
            if ( m_pPlayer.FlashlightIsOn() )
            {
                m_bWasFlashLightOn = true;
                m_pPlayer.pev.effects &= ~EF_DIMLIGHT;
            }

            TraceResult tr;
            bool fDidHit = false;

            Math.MakeVectors( m_pPlayer.pev.v_angle );
            Vector vecSrc   = m_pPlayer.GetGunPosition();
            Vector vecEnd   = vecSrc + g_Engine.v_forward * RANGE;

            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

            if( tr.flFraction >= 1.0f )
            {
                g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
                if( tr.flFraction < 1.0f )
                {
                    // Calculate the point of intersection of the line (or hull) and the object we hit
                    // This is and approximation of the "best" intersection
                    CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                    if( pHit is null || pHit.IsBSPModel() )
                        g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                    vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
                }
            }

            if( tr.flFraction >= 1.0f )
            {
                if( fFirst )
                {
                    // miss
                    switch( ( m_iSwing++ ) % 3 )
                    {
                        case 0: self.SendWeaponAnim( ATTACK1MISS, 0, pev.body ); break;
                        case 1: self.SendWeaponAnim( ATTACK2MISS, 0, pev.body ); break;
                        case 2: self.SendWeaponAnim( ATTACK3MISS, 0, pev.body ); break;
                    }
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = m_bFlashLightTurnTime = g_Engine.time + 0.625f;
                    self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                    // play wiff or swish sound
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_miss1.wav", 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

                    // player "shoot" animation
                    m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                }
            }
            else
            {
                // hit
                fDidHit = true;

                CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

                switch( ( ( m_iSwing++ ) % 2 ) + 1 )
                {
                    case 0: self.SendWeaponAnim( ATTACK1HIT, 0, pev.body ); break;
                    case 1: self.SendWeaponAnim( ATTACK2HIT, 0, pev.body ); break;
                    case 2: self.SendWeaponAnim( ATTACK3HIT, 0, pev.body ); break;
                }

                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = m_bFlashLightTurnTime = g_Engine.time + 0.375f;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                // player "shoot" animation
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

                g_WeaponFuncs.ClearMultiDamage();

                if( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time )
                    pEntity.TraceAttack( m_pPlayer.pev, DAMAGE, g_Engine.v_forward, tr, DMG_CLUB ); // first swing does full damage
                else
                    pEntity.TraceAttack( m_pPlayer.pev, DAMAGE * 0.5f, g_Engine.v_forward, tr, DMG_CLUB ); // subsequent swings do 50% (Changed -Sniper) (Half)

                g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

                // play thwack, smack, or dong sound
                float flVol = 1.0f;
                bool fHitWorld = true;

                // for monsters or breakable entity smacking speed function
                if( pEntity !is null )
                {
                    if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
                    {
                        // aone
                        if( pEntity.IsPlayer() ) // lets pull them
                            pEntity.pev.velocity = pEntity.pev.velocity + ( pev.origin - pEntity.pev.origin ).Normalize() * 120.0f;
                        // end aone

                        // play thwack or smack sound
                        switch( Math.RandomLong( 1, 3 ) )
                        {
                            case 3:
                                g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod3.wav", 1.0f, ATTN_NORM );
                            break;
                            case 2:
                                g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod2.wav", 1.0f, ATTN_NORM );
                            break;
                            default:
                                g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod1.wav", 1.0f, ATTN_NORM );
                            break;
                        }

                        m_pPlayer.m_iWeaponVolume = 128;

                        if( !pEntity.IsAlive() )
                            return true;
                        else
                            flVol = 0.1f;

                        fHitWorld = false;
                    }
                }

                // play texture hit sound
                // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

                if( fHitWorld )
                {
                    g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2.0f, BULLET_PLAYER_CROWBAR );

                    // also play crowbar strike
                    switch( Math.RandomLong( 1, 2 ) )
                    {
                        case 2:
                            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hit2.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
                        break;
                        default:
                            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hit1.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
                        break;
                    }
                }

                // delay the decal a bit
                m_trHit = tr;
                bts_post_attack(tr);
                SetThink( ThinkFunction( this.Smack ) );
                pev.nextthink = g_Engine.time + 0.2f;

                m_pPlayer.m_iWeaponVolume = int( flVol * 512 );
            }

            return fDidHit;
        }
    }
}
