/*
game_sprite_text.

This entity creates a sprite message
*/

#include "extra_languages"
#include "game_spritetext_button"
#include "string_escape_sequences"
#include "utils"

namespace GameSpritetext
{
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
	}
	
	class game_spritetext : ScriptBaseEntity, ScriptBaseLanguagesKm
	{
		string spritemodel = "sprites/gst/spritefont1.spr";;
		string extramodel = "sprites/gst/extra.spr";
		string buttonmodel = "sprites/dot.spr";
		array<CSprite@> sprite_array(128);
		array<CSprite@> sprite_array_option1(128);
		array<CSprite@> sprite_array_option2(128);
		array<CSprite@> sprite_array_option3(128);
		array<CSprite@> sprite_array_option4(128);
		CSprite@ extra_sprite;
		CSprite@ button_sprite1;
		CSprite@ button_sprite2;
		CSprite@ button_sprite3;
		CSprite@ button_sprite4;
				
		float sprScale;
		float holdtime;
		int LDistance;
		string optiontarget1 = "";
		string optiontarget2 = "";
		string optiontarget3 = "";
		string optiontarget4 = "";
		string optionmessage1 = "";
		string optionmessage2 = "";
		string optionmessage3 = "";
		string optionmessage4 = "";
		string stext;
		string m_iszMaster;
		bool IsHolding = false;
		uint stext_length = 0;
		uint om1_length;
		uint om2_length;
		uint om3_length;
		uint om4_length;
	
		void Precache() 
		{
			g_Game.PrecacheModel( spritemodel );
			g_Game.PrecacheModel( extramodel );
			g_Game.PrecacheModel( buttonmodel);
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
			self.pev.iuser1 = 1;
			self.pev.iuser2 = 1;
			self.pev.iuser3 = 1;
			self.pev.iuser4 = 1;
			
			if (iLanguage == LANGUAGE_SPANISH) {stext_length = string(message_spanish).Length();}else{stext_length = string(self.pev.message).Length();}
					
			om1_length = optionmessage1.Length();
			om2_length = optionmessage2.Length();
			om3_length = optionmessage3.Length();
			om4_length = optionmessage4.Length();
			
			self.Precache();
			
			self.pev.nextthink = g_Engine.time + self.pev.dmg;
		}
		
		bool KeyValue( const string& in szKey, const string& in szValue )
		{
			if(szKey == "holdtime")
			{
				holdtime = atof(szValue);
				return true;
			}
			else if(szKey == "optiontarget1")
			{
				optiontarget1 = szValue;
				return true;
			}
			else if(szKey == "optiontarget2")
			{
				optiontarget2 = szValue;
				return true;
			}
			else if(szKey == "optiontarget3")
			{
				optiontarget3 = szValue;
				return true;
			}
			else if(szKey == "optiontarget4")
			{
				optiontarget4 = szValue;
				return true;
			}
			else if(szKey == "optionmessage1_spanish")
			{
				if (iLanguage == LANGUAGE_SPANISH) {optionmessage1 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage1_english")
			{
				if (iLanguage == LANGUAGE_ENGLISH) {optionmessage1 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage2_spanish")
			{
				if (iLanguage == LANGUAGE_SPANISH) {optionmessage2 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage2_english")
			{
				if (iLanguage == LANGUAGE_ENGLISH) {optionmessage2 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage3_spanish")
			{
				if (iLanguage == LANGUAGE_SPANISH) {optionmessage3 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage3_english")
			{
				if (iLanguage == LANGUAGE_ENGLISH) {optionmessage3 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage4_spanish")
			{
				if (iLanguage == LANGUAGE_SPANISH) {optionmessage4 = szValue;}
				return true;
			}
			else if(szKey == "optionmessage4_english")
			{
				if (iLanguage == LANGUAGE_ENGLISH) {optionmessage4 = szValue;}
				return true;
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
			Languages( szKey, szValue );
			{
				return BaseClass.KeyValue( szKey, szValue );
			}
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
		
			sprScale = self.pev.scale;
			if (iLanguage == LANGUAGE_SPANISH) {stext = message_spanish;} else {stext = self.pev.message;}	
			if (sprScale == 0) {sprScale = 1;}
			
			//if (stext_length > 128) { stext = stext.SubString(0,127);}
			DisplayText(stext, @pActivator, @pCaller);
			
			//SetThink(ThinkFunction(this.ThinkCopypointer));
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
			
			while (i < stext_length )
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
				
			//g_EngineFuncs.ServerPrint("length: " + string(stext_length) + "\n"); 
			
			ProcessINT(x_width,y_height);
		}
		
		// applies the interation mode related settings 
		void ProcessINT(float x_width, float y_height)
		{
			uint k = 0;
			
			if (int(self.pev.armorvalue) == INT_OPTIONS)
			{
				//CreateOptionSprites(string optionmessage1, om1_length ,x_width, y_height, OP_OPTION1)
				
				if (optionmessage1.Length() > 0)
				{
					CreateSpr(sprite_array,buttonmodel, k, -1, int(y_height+3), x_width+2, y_height+2, SPRITEMODE_OPTION_BUTTON, OP_OPTION1);
					while ( k < om1_length)
					{
						char chara = optionmessage1[k];
						if ( k >= optionmessage1.Length()) chara = " ";
						
						CreateSpr(sprite_array,chara, k, k, int(y_height+3), x_width+2, y_height+2, SPRITEMODE_CHARACTER, OP_OPTION1);
						
						k++;
					}
						
					k = 0;
				}
				
				if (optionmessage2.Length() > 0)
				{
					CreateSpr(sprite_array,buttonmodel, k, optionmessage2.Length(), int(y_height+4), x_width+2, y_height+2, SPRITEMODE_OPTION_BUTTON, OP_OPTION2);
					while ( k < om2_length)
					{
						char chara = optionmessage2[k];
						if ( k >= optionmessage2.Length()) chara = " ";
						
						CreateSpr(sprite_array,chara, k, k, int(y_height+4), x_width+2, y_height+2, SPRITEMODE_CHARACTER, OP_OPTION2);
						k++;
					}
					
					k = 0;
				}
				
				if (optionmessage3.Length() > 0)
				{
					CreateSpr(sprite_array,buttonmodel, k, -1, int(y_height+5), x_width+2, y_height+2, SPRITEMODE_OPTION_BUTTON, OP_OPTION3);
					while ( k < om3_length)
					{
						char chara = optionmessage3[k];
						if ( k >= optionmessage3.Length()) chara = " ";
						
						CreateSpr(sprite_array,chara, k, k, int(y_height+5), x_width+2, y_height+2, SPRITEMODE_CHARACTER, OP_OPTION3);
						k++;
					}
					
					k = 0;
				}
				
				if (optionmessage4.Length() > 0)
				{
					CreateSpr(sprite_array,buttonmodel, k, optionmessage4.Length(), int(y_height+6), x_width+2, y_height+2, SPRITEMODE_OPTION_BUTTON, OP_OPTION4);
					while ( k < om4_length)
					{
						char chara = optionmessage4[k];
						if ( k >= optionmessage4.Length()) chara = " ";
						
						CreateSpr(sprite_array,chara, k, k, int(y_height+6), x_width+2, y_height+2, SPRITEMODE_CHARACTER, OP_OPTION4);
						k++;
					}
					
					k = 0;
				}
				return;
			}
			
			if (int(self.pev.armorvalue) == INT_TRIGGER_BUTTON)
			{
				CreateSpr(sprite_array,"", k, 0, 0, 0, 0, SPRITEMODE_TRIGGER_BUTTON, OP_NONE);
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
			
			/*if (self.pev.armorvalue == INT_OPTIONS)
			{
				if( int(optionmessage1.Length()) > x_width)	{x_width = int(optionmessage1.Length());}
				if( int(optionmessage2.Length()) > x_width)	{x_width = int(optionmessage2.Length());}
				if( int(optionmessage3.Length()) > x_width)	{x_width = int(optionmessage3.Length());}
				if( int(optionmessage4.Length()) > x_width)	{x_width = int(optionmessage4.Length());}
			}*/
			
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
			Vector base_origin = 		self.pev.origin;
			Vector base_origin_offset = self.pev.vuser1;
			Vector sprAngles = 			self.pev.angles; 
			Vector sprAngles_offset = 	self.pev.vuser2;
			
			EHandle pCopypointerEHandle;			
			CBaseEntity@ pCopypointerEntity = null;
			
			if (self.pev.target == "!self")	{@pCopypointerEntity = @self;}
			else 							{@pCopypointerEntity = g_EntityFuncs.FindEntityByTargetname( @pCopypointerEntity, self.pev.target );}
			
			pCopypointerEHandle = pCopypointerEntity;
			
			base_origin = pCopypointerEntity.pev.origin + base_origin_offset;
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
			
			if (spritemode == SPRITEMODE_OPTION_BUTTON) 
			{
				sprite_array[letter_position].SetScale( self.pev.scale/4 );
				SetSprite( @sprite_array[letter_position], 0, x, y, x_width, y_height);
								
				if ((self.pev.iuser1 == 1)|| (self.pev.iuser2 == 1) || (self.pev.iuser3 == 1) || (self.pev.iuser4 == 1))
				{
					CBaseEntity@ spritebutton = g_EntityFuncs.CreateEntity( "game_spritetext_button", null,  false);
					spritebutton.pev.origin = chara_origin;
					string selfname = self.pev.targetname;
					if (optionc == 1) {spritebutton.pev.target = optiontarget1;spritebutton.pev.targetname = selfname + "_button1"; self.pev.iuser1 = 0; @button_sprite1 = g_EntityFuncs.CreateSprite( buttonmodel, chara_origin , false );SetSprite( @button_sprite1, 0, x, y, x_width, y_height);}
					if (optionc == 2) {spritebutton.pev.target = optiontarget2;spritebutton.pev.targetname = selfname + "_button2"; self.pev.iuser1 = 0; @button_sprite2 = g_EntityFuncs.CreateSprite( buttonmodel, chara_origin , false );SetSprite( @button_sprite2, 0, x, y, x_width, y_height);}
					if (optionc == 3) {spritebutton.pev.target = optiontarget3;spritebutton.pev.targetname = selfname + "_button3"; self.pev.iuser1 = 0; @button_sprite3 = g_EntityFuncs.CreateSprite( buttonmodel, chara_origin , false );SetSprite( @button_sprite3, 0, x, y, x_width, y_height);}
					if (optionc == 4) {spritebutton.pev.target = optiontarget4;spritebutton.pev.targetname = selfname + "_button4"; self.pev.iuser1 = 0; @button_sprite4 = g_EntityFuncs.CreateSprite( buttonmodel, chara_origin , false );SetSprite( @button_sprite4, 0, x, y, x_width, y_height);}
					g_EntityFuncs.DispatchSpawn( spritebutton.edict() );
				}
			}
				
			if (spritemode == SPRITEMODE_CHARACTER) 
			{
				if (optionc == OP_NONE)		{ @sprite_array[letter_position]			= @text_array[letter_position];}
				if (optionc == OP_OPTION1)	{ @sprite_array_option1[letter_position] 	= @text_array[letter_position];}
				if (optionc == OP_OPTION2)	{ @sprite_array_option2[letter_position]	= @text_array[letter_position];}
				if (optionc == OP_OPTION3)	{ @sprite_array_option3[letter_position]	= @text_array[letter_position];}
				if (optionc == OP_OPTION4)	{ @sprite_array_option4[letter_position]	= @text_array[letter_position];}
			
				if ((self.pev.iuser1 == 1) && (self.pev.armorvalue == INT_TRIGGER_BUTTON))
				{
					CBaseEntity@ spritebutton = g_EntityFuncs.CreateEntity( "game_spritetext_button", null,  false);
					spritebutton.pev.origin = base_origin;
					string selfname = self.pev.targetname;
					spritebutton.pev.target = optiontarget1;
					spritebutton.pev.targetname = selfname + "_button1"; 
					self.pev.iuser1 = 0;
					g_EntityFuncs.DispatchSpawn( spritebutton.edict() );
				}
			}
			
			/*if (spritemode == SPRITEMODE_EXTRA) needs to be reworked
			{
				if (character == "uppertalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 0, x, y, x_width, y_height);} else
				if (character == "lowertalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 1, x, y, x_width, y_height);} else
				if (character == "lefttalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 2, x, y, x_width, y_height);} else
				if (character == "righttalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 3, x, y, x_width, y_height);} else
				if (character == "leftuppertalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 4, x, y, x_width, y_height);} else
				if (character == "rightuppertalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 5, x, y, x_width, y_height);} else
				if (character == "leftlowertalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 6, x, y, x_width, y_height);} else
				if (character == "rightlowertalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 7, x, y, x_width, y_height);} else
				if (character == "lowerspacetalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 8, x, y, x_width, y_height);} else
				if (character == "signtalkbubble" ) { @extra_sprite = g_EntityFuncs.CreateSprite( extramodel, chara_origin , false ); SetSprite( @extra_sprite, 9, x, y, x_width, y_height);}
			}*/
			
			if (holdtime == -1.0 || int(self.pev.armorvalue) == INT_OPTIONS || int(self.pev.armorvalue) == INT_TRIGGER_BUTTON)
			{
				SetUse(UseFunction(this.TriggerUseStop));
				self.pev.nextthink = g_Engine.time + 99999.0; //  
				//g_Scheduler.SetTimeout( "KillSprite", 0.5, @sprite_array[letter_position]);
				IsHolding = true;
			}	
			else
			{
				g_Scheduler.SetTimeout( "KillSprite", holdtime, @sprite_array[letter_position]);
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
		
		void TriggerUseStop(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
		{
			int i = 0;
			
			//KillSprite (@extra_sprite);
						
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
					if (@sprite_array_option1[i] != null){KillSprite (sprite_array_option1[i]);}
					if (@sprite_array_option2[i] != null){KillSprite (sprite_array_option2[i]);}
					if (@sprite_array_option3[i] != null){KillSprite (sprite_array_option3[i]);}					
					if (@sprite_array_option4[i] != null){KillSprite (sprite_array_option4[i]);}
					
				i++;
				}
				if (@button_sprite1 != null) {KillSprite (@button_sprite1);}
				if (@button_sprite2 != null) {KillSprite (@button_sprite2);}
				if (@button_sprite3 != null) {KillSprite (@button_sprite3);}
				if (@button_sprite4 != null) {KillSprite (@button_sprite4);}
			}
			
			InitializeAllGSSprites();
			
			SetUse(UseFunction(this.TriggerUse));
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
			InitializeGSSprite(sprite_array_option1);
			InitializeGSSprite(sprite_array_option2);
			InitializeGSSprite(sprite_array_option3);
			InitializeGSSprite(sprite_array_option4);
		}
	}
	
	void FadeSprite ( CSprite@ sprite)
	{
		sprite.SUB_StartFadeOut();
	}
	
	void InitializeGSSprite ( array<CSprite@> CSarray )
	{
		for ( uint I = 0; I < 128; I++ ){@CSarray[I] = null;}
	}
	
	void KillSprite ( CSprite@ sprite)
	{
		if (@sprite != null){sprite.SUB_Remove();}
	}
	
	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "GameSpritetext::game_spritetext", "game_spritetext" );
	}
}