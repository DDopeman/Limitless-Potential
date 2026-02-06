/*
game_sprite_text.

This entity creates a sprite message
*/

#include "game_spritetext_button"
#include "string_escape_sequences"
#include "utils"

	enum GS_EXTRA_MODE
	{
		EXTRA_NONE					= 0,
		EXTRA_TALKBUBBLE			,
		EXTRA_ANGERBUBBLE 			,
		EXTRA_THINKBUBBLE			,
		EXTRA_MUTEBUBBLE			,
	}
	
	enum GS_INTERACTION_MODE
	{
		INT_TEXT					= 0,
		INT_OPTIONS					,
		INT_TRIGGER_BUTTON			,
	}
	
	enum GS_SPRITE_MODE
	{
		SPRITEMODE_CHARACTER			= 0,
		SPRITEMODE_OPTION_BUTTON		,
		SPRITEMODE_EXTRA				,
		SPRITEMODE_TRIGGER_BUTTON		,
	}
	
	enum GS_OPTION_TEXT
	{
		OP_NONE					  		= 0,
		OP_OPTION1						,
		OP_OPTION2						,
		OP_OPTION3						,
		OP_OPTION4						,
		OP_OPTION5						,
		OP_OPTION6						,
		OP_OPTION7						,
		OP_OPTION8						,
		OP_OPTION9						,
		OP_OPTION10						,
		OP_OPTION11						,
		OP_OPTION12						,
		OP_OPTION13						,
		OP_OPTION14						,
		OP_OPTION15						,
		OP_OPTION16						,
	}
	
	enum GS_TEXT_ALIGMENT
	{
		ALIG_CENTER				  		= 0,
		ALIG_TOP_LEFT					,
		ALIG_BOTTOM_LEFT				,
		ALIG_TOP_RIGHT					,
		ALIG_BOTTOM_RIGHT				,
	}
	
	class game_spritetext : ScriptBaseEntity
	{
		string_t message_spanish;
		string spritemodel = "sprites/gst/spritefont1.spr";;
		string extramodel = "sprites/gst/extra.spr";
		string buttonmodel = "sprites/dot.spr";
		array<CSprite@> sprite_array(128);
		array<array<CSprite@>> sprite_array_option(17, array<CSprite@>(128));
		CSprite@ extra_sprite;
		array<CSprite@> button_sprite(17);
		float sprScale;
		float holdtime;
		int LDistance;
		array<string> optiontarget(17);
		array<string> optionmessage(17);
		array<Vector> optionpositionoffset(17);
		string afterholdtarget;
		string stext;
		string m_iszMaster;
		bool IsHolding = false;
		Vector align_offset;
		array<int> ibut(17);
		array<EHandle> ButtonEHandlearray(17);
	
		void Precache() 
		{
			g_Game.PrecacheModel( spritemodel );
			g_Game.PrecacheModel( extramodel );
			g_Game.PrecacheModel( buttonmodel);
			g_Game.PrecacheModel("sprites/null.spr");
			BaseClass.Precache();
		}
		
		void Spawn() 
		{
			self.pev.movetype 		= MOVETYPE_NONE;
			self.pev.solid 			= SOLID_NOT;
			self.pev.framerate 		= 0.0f;
			
			InitializeAllGSSprites();
						
			g_EntityFuncs.SetOrigin( self, self.pev.origin );
			//g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
			SetUse(UseFunction(this.TriggerUse));
			
			string smodel = self.pev.model;
			string emodel = self.pev.netname;
			LDistance = int(self.pev.frags);
			if (smodel.Length() != 0) {spritemodel = self.pev.model;}
			if (emodel.Length() != 0) {extramodel = self.pev.netname;}
			for ( uint I = 1; I < 17; I++ ) {ibut[I] = 1;}
			for ( uint I = 1; I < 17; I++ ) {self.GetCustomKeyvalues().SetKeyvalue( "$i_button" + string(I), 1 );}
			self.pev.iuser1 = 1;
					
			self.Precache();
			
			self.pev.nextthink = g_Engine.time + self.pev.dmg;
			
			//self.pev.euser1 = self.edict();
		}
		
		bool KeyValue( const string& in szKey, const string& in szValue )
		{
			if(szKey == "holdtime")
			{
				holdtime = atof(szValue);
				return true;
			}
			else for ( uint I = 1; I < 17; I++ )
			{
				if(szKey == "optiontarget" + string(I))
				{
					optiontarget[I] = szValue;
					return true;
				}
			}
			for ( uint I = 1; I < 17; I++ )
			{
				if(szKey == "optionpositionoffset" + string(I))
				{
					string delimiter = " ";
					array<string> splitAr = {"","",""};
					splitAr = szValue.Split(delimiter);
					array<int>result = {0,0,0};
					result[0] = atoi(splitAr[0]);
					result[1] = atoi(splitAr[1]);
					result[2] = atoi(splitAr[2]);
					optionpositionoffset[I] = Vector(result[0],result[1],result[2]);
					return true;
				}
			}
			if( szKey == "message_spanish" )
			{
				message_spanish = szValue;
			}
			else if (iLanguage == LANGUAGE_SPANISH)
			{
				for ( uint I = 1; I < 17; I++ )
				{
					if(szKey == "optionmessage" + string(I) + "_spanish")
					{
						optionmessage[I] = szValue;
						return true;
					}
				}
			} 
			else if (iLanguage == LANGUAGE_ENGLISH)			
			{
				for ( uint I = 1; I < 17; I++ ) 
				{
					if(szKey == "optionmessage" + string(I) + "_english")
					{
						optionmessage[I] = szValue;
						return true;
					}
				}
			}
			else if(szKey == "offset")
			{
				g_Utility.StringToVector( self.pev.vuser1, szValue);
				return true;
			}
			else if(szKey == "angleoffset")
			{
				g_Utility.StringToVector( self.pev.vuser2, szValue);
				return true;
			}
			else if(szKey == "master")
			{
				m_iszMaster = szValue;
				return true;
			}
			else
			{
			return BaseClass.KeyValue( szKey, szValue );
			}

			return true;
		}
		
		void ThinkCopypointer() //handles entity position refresh
		{
			EHandle pCopypointerEHandle;
			CBaseEntity@ pCopypointerEntity = null;
			string sAngles;
			
			if (self.pev.target == "!self")	{@pCopypointerEntity = @self;}
			else 							{@pCopypointerEntity = g_EntityFuncs.FindEntityByTargetname( @pCopypointerEntity, self.pev.target );}
			
			pCopypointerEHandle = pCopypointerEntity;
			
			Vector vAngles = pCopypointerEntity.pev.angles + Vector (0,0,0);
			sAngles = vAngles.ToString();
			
			if (pCopypointerEHandle)
			{
				int i = 0;
				
				while ( i < 128 )
				{
				sprite_array[i].SetOrigin( pCopypointerEntity.pev.origin );
				sprite_array[i].KeyValue( "angles" , sAngles );
				//string spOrigin = sprite_array[i].GetOrigin().ToString();
				}
			}
			
			if (self.pev.armorvalue == INT_OPTIONS || self.pev.armorvalue == INT_TRIGGER_BUTTON) 
			{
				self.pev.nextthink == g_Engine.time + 0.5;
				if (IsHolding)
				{
					//g_EntityFuncs.FireTargets(self.pev.targetname, null, null, USE_SET, 0.0f, 0.0f);
				}
			} 
			else
			{
				self.pev.nextthink = g_Engine.time + self.pev.dmg;
			}
		}

		void TriggerUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
		{
			if( !m_iszMaster.IsEmpty() && !g_EntityFuncs.IsMasterTriggered( m_iszMaster, self ) )
			{
				return;
			}
			
			if (useType == USE_SET && flValue == 5.0)
			{
				CBaseEntity@ ButtonEnt;
				for( uint I = 1; I < 17; I++ )
				{
					@ButtonEnt = ButtonEHandlearray[I].GetEntity();
					g_EntityFuncs.Remove(@ButtonEnt);
					IsHolding == false;
				}
				return;
			}
			
			if (useType == USE_SET && flValue == 10.0 && IsHolding == false)
			{
				return;
			}
			
			sprScale = self.pev.scale;
			if (iLanguage == LANGUAGE_SPANISH) {stext = message_spanish;} else {stext = self.pev.message;}	
			if (sprScale == 0) {sprScale = 1;}
			
			if (holdtime > 0.0)
			{
				g_Scheduler.SetTimeout( "ResetGS", holdtime, @self );
			}
			else
			{
				//ResetGS(@self );
			}
			
			SetUse(UseFunction(this.TriggerUseStop));			
			IsHolding = true;
			
			DisplayText(stext, @pActivator, @pCaller);
		}
		
		void TriggerUseStop(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
		{
			int i = 0;
			
			while ( i < 128 )
			{
				if (@sprite_array[i] != null)	{KillSprite (@sprite_array[i]);}
			i++;
			}
			
			i = 0;
			if (int(self.pev.armorvalue) == INT_OPTIONS )
			{
				while ( i < 128 )
				{
					for ( uint I = 1; I < 17; I++ ) {if (@sprite_array_option[I][i] != null){KillSprite (sprite_array_option[I][i]);}}
				i++;
				}
				for ( uint I = 1; I < 17; I++ )
				{
					if (@button_sprite[I] != null) {KillSprite (@button_sprite[I]);}
				}				
			}
			
			InitializeAllGSSprites();
			
			CBaseEntity@ AfterHoldEntity = g_EntityFuncs.FindEntityByTargetname( @AfterHoldEntity, string(self.pev.noise) );
			if (@AfterHoldEntity != null) 
			{
			g_EntityFuncs.FireTargets(AfterHoldEntity.pev.targetname, @pActivator, @self, USE_TOGGLE, 0.0f, 0.0f);
			}
			
			IsHolding = false;
			SetUse(UseFunction(this.TriggerUse));
		}
		
		// this is the main fuction that manages the sprite text
		void DisplayText(string stext, CBaseEntity@ pActivator, CBaseEntity@ pCaller)
		{
			array<int> ar_xy(2);
			array<int> ar_xy2;
			float x_width = 0;
			float y_height = 0;
			int x = 0;
			int y = 0;
			
			stext = ProcessTextT(stext, @pActivator, @pCaller);
			for ( uint I = 1; I < 17; I++ ){optionmessage[I] = ProcessTextT(optionmessage[I],@pActivator,@pCaller);}
			for ( uint I = 1; I < 17; I++ ){optiontarget[I] = ProcessTextT(optiontarget[I],@pActivator,@pCaller);}
			
			ar_xy = GetDimentions(stext);
			x_width = ar_xy[0];
			y_height = ar_xy[1];
			
			ar_xy2 = GetCurrentLineDimention(stext);
			
			uint i = 0;
			uint j = 0;
		
			float renderamt_end = Math.Floor((Math.clamp(0.0,255.0,self.pev.renderamt))/5.0)*5;
			float fIntervalTime = holdtime / 100.0f;
			int iRepeats = int(renderamt_end/ 5.0f);
			LDistance = int(self.pev.frags);			
			
			if (self.pev.weapons == ALIG_CENTER) 		{ align_offset.x = 0; align_offset.y = 0; align_offset.z = 0;} else
			if (self.pev.weapons == ALIG_TOP_LEFT)		{ align_offset.x = (x_width * sprScale) * 8; align_offset.y = 0; align_offset.z = (y_height * sprScale) * -8;} else
			if (self.pev.weapons == ALIG_BOTTOM_LEFT) 	{ align_offset.x = (y_height * sprScale) * 8; align_offset.y = 0; align_offset.z = (y_height * sprScale) *  8;} else
			if (self.pev.weapons == ALIG_TOP_RIGHT)		{ align_offset.x = (x_width * sprScale) * -8; align_offset.y = 0; align_offset.z = (y_height * sprScale) * -8;} else
			if (self.pev.weapons == ALIG_BOTTOM_RIGHT) 	{ align_offset.x = (x_width * sprScale) * -8; align_offset.y = 0; align_offset.z = (y_height * sprScale) * 8;} 
			
			while (i < stext.Length() )
			{
				if ( (stext[i] != "/" || stext[i+1] != "n") && (stext[i-1] != "/" || stext[i] != "n"))
				{
					char chara = stext[i];
					if ( i >= stext.Length()) chara = " ";
					
					CreateSpr(sprite_array,chara, i, x, y, x_width, y_height, SPRITEMODE_CHARACTER,OP_NONE);
					if ( x == ar_xy2[j])
					{
						x = -1;
						j++;
						y++;
					}
					x++;
				}
				if ( stext[i] == "/" && stext[i+1] == "n")
				{
					x = 0;
					j++;
					y++;
				}
				
				i++;
			}
			
			for ( uint I = 1; I < 17; I++ ) {optionmessage[I] = ProcessTextT(optionmessage[I],@pActivator,@pCaller);}
			ProcessINT(x_width,y_height);
	
		}
		
		// applies the interaction mode related settings 
		void ProcessINT(float x_width, float y_height)
		{
			uint k = 0;
			
			if (int(self.pev.armorvalue) == INT_OPTIONS)
			{
			
				for ( uint I = 1; I < 17; I++ )
				{
								
					if (optionmessage[I].Length() > 0 && I % 2 == 1)
					{
						CreateSpr(sprite_array,buttonmodel, k, -1, int(y_height+2+I+optionpositionoffset[I].x), x_width+2+optionpositionoffset[I].y, y_height+2, SPRITEMODE_OPTION_BUTTON, I);
						while ( k < optionmessage[I].Length())
						{
							char chara = optionmessage[I][k];
							if ( k >= optionmessage[I].Length()) chara = " ";
						
							CreateSpr(sprite_array,chara, k, k, int(y_height+2+I+optionpositionoffset[I].x), x_width+2+optionpositionoffset[I].y, y_height+2, SPRITEMODE_CHARACTER, I);
						
							k++;
						}						
						k = 0;
					}
				}
				
				for ( uint I = 1; I < 17; I++ )
				{				
					if (optionmessage[I].Length() > 0 && I % 2 == 0)
					{
						CreateSpr(sprite_array,buttonmodel, k, optionmessage[I].Length(), int(y_height+2+I+optionpositionoffset[I].x), x_width+2+optionpositionoffset[I].y, y_height+2, SPRITEMODE_OPTION_BUTTON, I);
						while ( k < optionmessage[I].Length())
						{
							char chara = optionmessage[I][k];
							if ( k >= optionmessage[I].Length()) chara = " ";
							
							CreateSpr(sprite_array,chara, k, k, int(y_height+2+I+optionpositionoffset[I].x), x_width+2+optionpositionoffset[I].y, y_height+2, SPRITEMODE_CHARACTER, I);
							k++;
						}					
						k = 0;
					}
				}
			
			return;
			}
			
			if (int(self.pev.armorvalue) == INT_TRIGGER_BUTTON)
			{
				CreateSpr(sprite_array,"", k, 0, 0, 0, 0, SPRITEMODE_OPTION_BUTTON, OP_OPTION1);
			}
		}
		
		// this processes the text and gets how many lines it has and how long is the longer line
		array <int> GetDimentions(string stext)
		{
			int x_width = 0;
			int y_height = 0;
			int iCurrentxLength = 0;
			uint i = 0;
			uint k = 0;
			while ( i < stext.Length())
			{
				if (stext[i] == "/" && stext[i+1] == "n")
				{
					iCurrentxLength = -1;
					y_height++;
				}
				
				if (iCurrentxLength > x_width) {x_width = iCurrentxLength;}
				iCurrentxLength++;
				i++;
			}
			
			array<int> ar_xy(2);
			ar_xy[0] = x_width;
			ar_xy[1] = y_height; 
					
			return ar_xy;
		}
		
		// this get the length of every line of the text and stores into an array. ar_xy[y_height] is X and the index is Y
		array <int> GetCurrentLineDimention(string stext)
		{
			array<int> ar_xy(128);
			int x_width = 0;
			int y_height = 0;
			int iCurrentxLength = 0;
			uint i = 0;
									
			while ( i < stext.Length())
			{
				if (stext[i] == "/" && stext[i+1] == "n")
				{
					ar_xy[y_height] = iCurrentxLength;
					iCurrentxLength = 0;
					y_height++;
				}
				else
				{
					iCurrentxLength++;
				}
				i++;
				
			}
			ar_xy[y_height] = iCurrentxLength;
			return ar_xy;
		}
		
		// this manages the creation of every individual letter.
		void CreateSpr( array<CSprite@> text_array, string character, uint letter_position, int x, int y, float x_width, float y_height,int spritemode, int optionc )
		{
			if (x > 127)	{return;}
		
			Vector base_origin = 		self.pev.origin;
			Vector base_origin_offset = self.pev.vuser1;
			Vector sprAngles = 			self.pev.angles; 
			Vector sprAngles_offset = 	self.pev.vuser2;
			
			EHandle pCopypointerEHandle;			
			CBaseEntity@ pCopypointerEntity = null;
			
			if (self.pev.target == "!self")	{@pCopypointerEntity = @self;}
			else 							{@pCopypointerEntity = g_EntityFuncs.FindEntityByTargetname( @pCopypointerEntity, self.pev.target );}
			
			pCopypointerEHandle = pCopypointerEntity;
			
			base_origin = pCopypointerEntity.pev.origin + base_origin_offset + align_offset;
			sprAngles = pCopypointerEntity.pev.angles + sprAngles_offset;
									
			float anglesCosX = float(cos(sprAngles.x/180 * Q_PI));
			float anglesSinX = float(sin(sprAngles.x/180 * Q_PI));
			float anglesCosY = float(cos(sprAngles.y/180 * Q_PI));
			float anglesSinY = float(sin(sprAngles.y/180 * Q_PI));
			float anglesCosZ = float(cos(sprAngles.z/180 * Q_PI));
			float anglesSinZ = float(sin(sprAngles.z/180 * Q_PI));
			
			int k = 0;
			
			// this formula manages the position where the letter will appear,
			
			Vector chara_origin = base_origin + Vector ( -anglesSinY * sprScale *  -8 *  (x_width  - 1)  - (anglesSinY) * sprScale    * (x-1) * LDistance + (
														 -anglesSinX * sprScale *  -8 *  (y_height + 1)  - (-anglesSinX)  * sprScale    * (y-1) * LDistance  ),
														 
														 anglesCosY   *  sprScale *  -8 *  (x_width  - 1)  + anglesCosY  	 * sprScale    * (x-1) * LDistance
													 // +((anglesSinZ  * sprScale *  -8 *  (x_width  - 1))  - ( anglesSinZ	 * sprScale  *  (y-1) * LDistance ))
														 ,
														 
														 anglesCosX	 * sprScale *   8 *  (y_height + 1)  - anglesCosX    * sprScale    * (y-1) * LDistance
													//	+(anglesCosZ  * sprScale *  8 *  (y_height + 1) - anglesCosZ   * sprScale    * (x-1)* LDistance )
														);
														
			spritemodel = self.pev.model; 
			if (spritemode == SPRITEMODE_CHARACTER)	
			{	
				if (character == "a" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 0, x, y, x_width, y_height);} else
				if (character == "b" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 1, x, y, x_width, y_height);} else
				if (character == "c" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 2, x, y, x_width, y_height);} else
				if (character == "d" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 3, x, y, x_width, y_height);} else
				if (character == "e" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 4, x, y, x_width, y_height);} else
				if (character == "f" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 5, x, y, x_width, y_height);} else
				if (character == "g" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 6, x, y, x_width, y_height);} else
				if (character == "h" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 7, x, y, x_width, y_height);} else
				if (character == "i" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 8, x, y, x_width, y_height);} else
				if (character == "j" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 9, x, y, x_width, y_height);} else
				if (character == "k" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 10, x, y, x_width, y_height);} else
				if (character == "l" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 11, x, y, x_width, y_height);} else
				if (character == "m" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 12, x, y, x_width, y_height);} else
				if (character == "n" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 13, x, y, x_width, y_height);} else
				if (character == "o" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 14, x, y, x_width, y_height);} else
				if (character == "p" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 15, x, y, x_width, y_height);} else
				if (character == "q" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 16, x, y, x_width, y_height);} else
				if (character == "r" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 17, x, y, x_width, y_height);} else
				if (character == "s" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 18, x, y, x_width, y_height);} else
				if (character == "t" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 19, x, y, x_width, y_height);} else
				if (character == "u" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 20, x, y, x_width, y_height);} else
				if (character == "v" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 21, x, y, x_width, y_height);} else
				if (character == "w" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 22, x, y, x_width, y_height);} else 
				if (character == "x" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 23, x, y, x_width, y_height);} else
				if (character == "y" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 24, x, y, x_width, y_height);} else
				if (character == "z" ) { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 25, x, y, x_width, y_height);} else
				if (character == "A") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 26, x, y, x_width, y_height);} else
				if (character == "B") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 27, x, y, x_width, y_height);} else
				if (character == "C") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 28, x, y, x_width, y_height);} else
				if (character == "D") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 29, x, y, x_width, y_height);} else
				if (character == "E") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 30, x, y, x_width, y_height);} else
				if (character == "F") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 31, x, y, x_width, y_height);} else
				if (character == "G") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 32, x, y, x_width, y_height);} else
				if (character == "H") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 33, x, y, x_width, y_height);} else
				if (character == "I") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 34, x, y, x_width, y_height);} else
				if (character == "J") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 35, x, y, x_width, y_height);} else
				if (character == "K") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 36, x, y, x_width, y_height);} else
				if (character == "L") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 37, x, y, x_width, y_height);} else
				if (character == "M") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 38, x, y, x_width, y_height);} else
				if (character == "N") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 39, x, y, x_width, y_height);} else
				if (character == "O") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 40, x, y, x_width, y_height);} else
				if (character == "P") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 41, x, y, x_width, y_height);} else
				if (character == "Q") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 42, x, y, x_width, y_height);} else
				if (character == "R") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 43, x, y, x_width, y_height);} else
				if (character == "S") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 44, x, y, x_width, y_height);} else
				if (character == "T") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 45, x, y, x_width, y_height);} else
				if (character == "U") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 46, x, y, x_width, y_height);} else
				if (character == "V") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 47, x, y, x_width, y_height);} else
				if (character == "W") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 48, x, y, x_width, y_height);} else 
				if (character == "X") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 49, x, y, x_width, y_height);} else
				if (character == "Y") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 50, x, y, x_width, y_height);} else
				if (character == "Z") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 51, x, y, x_width, y_height);} else
				if (character == "!") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 52, x, y, x_width, y_height);} else
				if (character == """''""") { @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 53, x, y, x_width, y_height);} else
				if (character == "#") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 54, x, y, x_width, y_height);} else
				if (character == "$") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 55, x, y, x_width, y_height);} else
				if (character == "%") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 56, x, y, x_width, y_height);} else
				if (character == "&") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 57, x, y, x_width, y_height);} else
				if (character == "'") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 58, x, y, x_width, y_height);} else
				if (character == "(") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 59, x, y, x_width, y_height);} else
				if (character == ")") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 60, x, y, x_width, y_height);} else
				if (character == "*") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 61, x, y, x_width, y_height);} else
				if (character == "+") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 62, x, y, x_width, y_height);} else
				if (character == ",") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 63, x, y, x_width, y_height);} else
				if (character == "-") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 64, x, y, x_width, y_height);} else
				if (character == ".") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 65, x, y, x_width, y_height);} else
				if (character == "/") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 66, x, y, x_width, y_height);} else
				if (character == "0") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 67, x, y, x_width, y_height);} else
				if (character == "1") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 68, x, y, x_width, y_height);} else
				if (character == "2") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 69, x, y, x_width, y_height);} else
				if (character == "3") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 70, x, y, x_width, y_height);} else
				if (character == "4") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 71, x, y, x_width, y_height);} else 
				if (character == "5") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 72, x, y, x_width, y_height);} else
				if (character == "6") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 73, x, y, x_width, y_height);} else
				if (character == "7") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 74, x, y, x_width, y_height);} else
				if (character == "8") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 75, x, y, x_width, y_height);} else
				if (character == "9") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 76, x, y, x_width, y_height);} else
				if (character == ":") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 77, x, y, x_width, y_height);} else
				if (character == ";") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 78, x, y, x_width, y_height);} else
				if (character == "<") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 79, x, y, x_width, y_height);} else
				if (character == "=") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 80, x, y, x_width, y_height);} else
				if (character == ">") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 81, x, y, x_width, y_height);} else
				if (character == "?") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 82, x, y, x_width, y_height);} else
				if (character == "@") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 83, x, y, x_width, y_height);} else
				if (character == "[") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 84, x, y, x_width, y_height);} else
				//if (character == "\\") {  @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 85, x, y, x_width, y_height);} // having trouble dodging the default escape sequences better leave this disabled
				if (character == "]") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 86, x, y, x_width, y_height);} else
				if (character == "^") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 87, x, y, x_width, y_height);} else
				if (character == "_") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 88, x, y, x_width, y_height);} else
				if (character == "`") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 89, x, y, x_width, y_height);} else
				if (character == "{") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 90, x, y, x_width, y_height);} else
				if (character == "|") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 91, x, y, x_width, y_height);} else
				if (character == "}") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 92, x, y, x_width, y_height);} else
				if (character == "~") {	 @text_array[letter_position] = g_EntityFuncs.CreateSprite( spritemodel, chara_origin , false ); SetSprite( @text_array[letter_position], 93, x, y, x_width, y_height);} else
									  {	@text_array[letter_position] = null; }									  
			}
			
			uint I;
			
			if (spritemode == SPRITEMODE_OPTION_BUTTON) 
			{
				sprite_array[letter_position].SetScale( self.pev.scale/4 );
				SetSprite( @sprite_array[letter_position], 0, x, y, x_width, y_height);
				
				for ( I = 1; I < 17; I++ ) {ibut[I] = self.GetCustomKeyvalues().GetKeyvalue( "$i_button" + string(I) ).GetInteger();}
				
				//g_Game.AlertMessage(at_console, "ibut: " + string(ibut1), g_Engine.time);
								
				if ((ibut[1] == 1)|| (ibut[2] == 1) || (ibut[3] == 1) || (ibut[4] == 1) || (ibut[5] == 1)|| (ibut[6] == 1) || (ibut[7] == 1) || (ibut[8] == 1) || (ibut[9] == 1)|| (ibut[10]== 1) || (ibut[11] == 1) || (ibut[12] == 1) || (ibut[13] == 1)|| (ibut[14] == 1) || (ibut[15] == 1) || (ibut[16] == 1) )
				{
					ButtonEHandlearray[0] = @self;
					CBaseEntity@ spritebutton = g_EntityFuncs.CreateEntity( "game_spritetext_button", null,  false);
					spritebutton.pev.origin = chara_origin;
					string selfname = self.pev.targetname;
					if (self.pev.armorvalue == INT_TRIGGER_BUTTON){buttonmodel = "sprites/null.spr";}
					for ( I = 1; I < 17; I++ )
					{
						if (optionc == I) 
						{
							spritebutton.pev.target = optiontarget[I];spritebutton.pev.targetname = selfname + "_button" + string(I); ibut[I] = 0; 
							self.GetCustomKeyvalues().SetKeyvalue( "$i_button" + string(I), 0 ); @button_sprite[I] = g_EntityFuncs.CreateSprite( buttonmodel, chara_origin , false );
							SetSprite( @button_sprite[I], 0, x, y, x_width, y_height);
							ButtonEHandlearray[I] = @spritebutton;
							@spritebutton.pev.owner = self.edict();
							spritebutton.pev.targetname = string(self.pev.targetname) + "_button" + string(I);
						}
					}
					g_EntityFuncs.DispatchSpawn( spritebutton.edict() );
				}
			}
				
			if (spritemode == SPRITEMODE_CHARACTER) 
			{
				if (optionc == OP_NONE)		{ @sprite_array[letter_position]			= @text_array[letter_position];}
				for ( uint I = 1; I < 17; I++ ) {if (optionc == I)	{ @sprite_array_option[I][letter_position] 	= @text_array[letter_position];}}
			}
		}
				
		// this set some common values of the sprites
		void SetSprite( CSprite@ sprite, float flFrames, int x, int y, float x_width, float y_height)
		{
			if(@sprite != null)
			{
				sprite.SetTransparency( int(self.pev.rendermode), int(self.pev.rendercolor.x), int(self.pev.rendercolor.y), int(self.pev.rendercolor.z), int(self.pev.renderamt), int(self.pev.renderfx));
				sprite.pev.framerate 		= 0.0f;
				sprite.SetScale( sprScale/5 );
				sprite.Animate(flFrames);
			}
		}
		
		void ThinkOn()
		{
			
		}
		
		void ThinkOff()
		{
			
		}
		
		void InitializeAllGSSprites()
		{
			InitializeGSSprite(sprite_array);
			for ( uint I = 1; I < 17; I++ ) {InitializeGSSprite(sprite_array_option[I]);}
		}
	}
	
	void FadeSprite ( CSprite@ sprite )
	{
		sprite.SUB_StartFadeOut();
	}
	
	void ResetGS ( CBaseEntity@ GSEntity )
	{
		GSEntity.Use(null, null, USE_TOGGLE ,10.0);
	}
	
	void InitializeGSSprite ( array<CSprite@> CSarray )
	{
		for ( uint I = 0; I < 128; I++ ){@CSarray[I] = null;}
	}
	
	void KillSprite ( CSprite@ sprite )
	{
		if (@sprite != null){sprite.SUB_Remove();}
	}
	
	void RegisterGameSpriteText()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "game_spritetext", "game_spritetext" );
	}


