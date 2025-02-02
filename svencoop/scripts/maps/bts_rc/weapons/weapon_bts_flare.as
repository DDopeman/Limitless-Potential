//Black Mesa Emergency Flare
/* Model Credits
/ Model: Valve
/ Textures: Valve
/ Animations: Valve
/ Sounds: Valve
/ Sprites: Valve
/ Misc: Valve, D.N.I.O. 071 ( Player Model Fix )
/ Script: Solokiller, KernCore, original base from Nero
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_flare
{
    // Animations
    enum btsflare_e
    {
        IDLE = 0,
        PULLPIN,
        THROW,
        DRAW
    };

    // Weapon info
    int MAX_CARRY = 5;
    int MAX_CLIP = WEAPON_NOCLIP;
    int DEFAULT_GIVE = 1;
    int AMMO_GIVE = DEFAULT_GIVE;
    int AMMO_DROP = AMMO_GIVE;
    int WEIGHT = 5;
    // Weapon HUD
    uint SLOT = 4;
    uint POSITION = 5;
    // Vars
    float TIMER = 1.5f;
    float DAMAGE = 1.0f;
    float DURATION = 180.0f;
    Vector OFFSET( 16.0f, 0.0f, 0.0f ); // for projectile

    class weapon_bts_flare : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        private float m_fAttackStart, m_flStartThrow;
        private bool m_bInAttack, m_bThrown;
        private int m_iAmmoSave;

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model(  "models/bts_rc/weapons/w_flare.mdl" ) );
            self.m_iDefaultAmmo = DEFAULT_GIVE;
            self.FallInit(); // get ready to fall
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

        // Better ammo extraction --- Anggara_nothing
        bool CanHaveDuplicates()
        {
            return true;
        }

        bool Deploy()
        {
            m_iAmmoSave = 0; // Zero out the ammo save
            return bts_deploy( "models/bts_rc/weapons/v_flare.mdl", "models/bts_rc/weapons/p_flare.mdl", DRAW, "gren", 0, 0.75f );
        }

        bool CanHolster()
        {
            return m_fAttackStart == 0.0f;
        }

        bool CanDeploy()
        {
            return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0;
        }

        CBasePlayerItem@ DropItem()
        {
            m_iAmmoSave = m_pPlayer.AmmoInventory( self.m_iPrimaryAmmoType ); // Save the player"s ammo pool in case it has any in DropItem
            return self;
        }

        void Holster( int skiplocal = 0 )
        {
            m_bThrown = false;
            m_bInAttack = false;
            m_fAttackStart = 0.0f;
            m_flStartThrow = 0.0f;

            SetThink( null );

            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 ) // Save the player"s ammo pool in case it has any in Holster
            {
                m_iAmmoSave = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
            }

            if( m_iAmmoSave <= 0 )
            {
                SetThink( ThinkFunction( this.DestroyThink ) );
                pev.nextthink = g_Engine.time + 0.1f;
            }

            BaseClass.Holster( skiplocal );
        }

        void PrimaryAttack()
        {
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
                return;

            self.m_flNextPrimaryAttack = g_Engine.time + ( 25.0f / 30.0f );
            self.SendWeaponAnim( PULLPIN, 0, pev.body );

            m_bInAttack = true;
            m_fAttackStart = g_Engine.time + ( 25.0f / 30.0f );

            self.m_flTimeWeaponIdle = g_Engine.time + ( 25.0f / 30.0f ) + ( 23.0f / 30.0f ); // ( 1.0f / 40.0f );
        }

        private void LaunchThink()
        {
            // g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_VOICE, SHOOT_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
            Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

            if( angThrow.x < 0.0f )
                angThrow.x = -10.0f + angThrow.x * ( ( 90.0f - 10.0f ) / 90.0f );
            else
                angThrow.x = -10.0f + angThrow.x * ( ( 90.0f + 10.0f ) / 90.0f );

            float flVel = ( 90.0f - angThrow.x ) * 6.0f;

            if( flVel > 750.0f )
                flVel = 750.0f;

            Math.MakeVectors( angThrow );
            Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
            Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;

            FLARE::Toss( m_pPlayer.pev, vecSrc, vecThrow, DAMAGE, DURATION, TIMER );

            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            m_fAttackStart = 0.0f;
        }

        void ItemPreFrame()
        {
            if( m_fAttackStart == 0 && m_bThrown == true && m_bInAttack == false && self.m_flTimeWeaponIdle - 0.1f < g_Engine.time )
            {
                if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
                {
                    self.Holster();
                }
                else
                {
                    self.Deploy();
                    m_bThrown = false;
                    m_bInAttack = false;
                    m_fAttackStart = 0.0f;
                    m_flStartThrow = 0.0f;
                }
            }

            if( !m_bInAttack || CheckButton() || g_Engine.time < m_fAttackStart )
                return;

            self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 22.0f / 30.0f ); // ( 0.0f / 40.0f );
            self.SendWeaponAnim( THROW, 0, pev.body );
            m_bThrown = true;
            m_bInAttack = false;
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            SetThink( ThinkFunction( this.LaunchThink ) );
            pev.nextthink = g_Engine.time + 0.2f;

            BaseClass.ItemPreFrame();
        }

        void WeaponIdle()
        {
            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            self.SendWeaponAnim( IDLE, 0, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5.0f, 7.0f );
        }

        private bool CheckButton() // returns which key the player is pressing (that might interrupt the reload)
        {
            return m_pPlayer.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) != 0;
        }

        private void DestroyThink() // destroys the item
        {
            SetThink( null );
            self.DestroyItem();
            //g_Game.AlertMessage( at_console, "Item Destroyed.\n" );
        }
    }
}
