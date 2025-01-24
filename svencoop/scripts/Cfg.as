/*
* Author(s): Sam "Solokiller" Vanheer
* www.svencoop.com
* Configuration file parser
*/

#include "StringUtils"

namespace Cfg
{
class Command
{
	private string m_szName;
	
	private array<string> m_szArguments;
	
	string Name
	{
		get const { return m_szName; }
	}
	
	array<string>@ Arguments
	{
		get { return m_szArguments; }
	}
	
	string get_Argument( const uint uiIndex )
	{
		if( m_szArguments.length() <= uiIndex )
			return "";
			
		return m_szArguments[ uiIndex ];
	}
	
	Command( const string& in szName )
	{
		m_szName = szName;
	}
}

class File
{
	private array<Command@> m_Commands;
	
	const array<Command@>@ Commands
	{
		get const { return @m_Commands; }
	}
	
	File()
	{
	}
	
	void AddCommand( Command@ pCommand )
	{
		m_Commands.insertLast( @pCommand );
	}
	
	void RemoveCommand( Command@ pCommand )
	{
		int iIndex = m_Commands.findByRef( @pCommand );
		
		if( iIndex != -1 )
			m_Commands.removeAt( iIndex );
	}
	
	const Command@ FindCommand( const string& in szName ) const
	{
		for( uint uiIndex = 0; uiIndex < m_Commands.length(); ++uiIndex )
		{
			Command@ pCommand = m_Commands[ uiIndex ];
			
			if( pCommand.Name == szName )
				return pCommand;
		}
		
		return null;
	}
	
	Command@ FindCommand( const string& in szName )
	{
		for( uint uiIndex = 0; uiIndex < m_Commands.length(); ++uiIndex )
		{
			Command@ pCommand = m_Commands[ uiIndex ];
			
			if( pCommand.Name == szName )
				return pCommand;
		}
		
		return null;
	}
	
	/*
	* Helper function to get the first argument of a command, if it exists
	*/
	string GetCommandArgument( const string& in szName, const string& in szDefault = "" ) const
	{
		Command@ pCommand = FindCommand( szName );
		
		if( pCommand !is null )
			return pCommand.Argument[ 0 ];
			
		return szDefault;
	}
}

class Parser
{
	Parser()
	{
	}
	
	File@ Parse( const string& in szFilename )
	{
		return Parse( g_FileSystem.OpenFile( szFilename, OpenFile::READ ) );
	}
	
	File@ Parse( ::File@ pFile )
	{
		Cfg::File@ pCfgFile = null;
		
		if( pFile !is null && pFile.IsOpen() )
		{
			@pCfgFile = Cfg::File();
			
			string szLine;
			
			while( !pFile.EOFReached() )
			{
				pFile.ReadLine( szLine );
				
				szLine.Trim();
				
				if( szLine.IsEmpty() )
					continue;
				
				uint uiIndex = 0;
				
				string szToken = StringUtils::ParseToken( szLine, uiIndex );
				
				//Empty or comment
				if( szToken.IsEmpty() )
					continue;
					
				Command command( szToken );
				
				array<string>@ arguments = @command.Arguments;
				
				const uint uiLength = szLine.Length();
				
				//Parse the rest of the line and add all arguments
				while( uiIndex < uiLength )
				{
					szToken = StringUtils::ParseToken( szLine, uiIndex, uiIndex );
					
					if( szToken.IsEmpty() )
						break;
						
					arguments.insertLast( szToken );
				}
				
				pCfgFile.AddCommand( @command );
			}
		}
		
		return pCfgFile;
	}
}

class Writer
{
	Writer()
	{
	}
	
	private void WriteComments( ::File@ pFile, const string& in szComments ) const
	{
		if( szComments.IsEmpty() )
			return;
			
		array<string>@ lines = szComments.Split( "\n" );
		
		const uint uiLength = lines.length();
		
		for( uint uiIndex = 0; uiIndex < uiLength; ++uiIndex )
		{
			pFile.Write( StringUtils::TOKEN_COMMENT + " " + lines[ uiIndex ] + "\n" );
		}
	}
	
	private void WriteCommand( ::File@ pFile, Command@ pCommand ) const
	{
		pFile.Write( pCommand.Name );
		
		array<string>@ arguments = pCommand.Arguments;
		
		const uint uiLength = arguments.length();
		
		for( uint uiIndex = 0; uiIndex < uiLength; ++uiIndex )
		{
			pFile.Write( " " + arguments[ uiIndex ] );
		}
		
		pFile.Write( "\n" );
	}
	
	bool Write( const string& in szFilename, Cfg::File@ pCfgFile, const string& in szComments = "" )
	{
		if( pCfgFile is null )
			return false;
		
		return Write( g_FileSystem.OpenFile( szFilename, OpenFile::WRITE ), pCfgFile, szComments );
	}
	
	bool Write( ::File@ pFile, Cfg::File@ pCfgFile, const string& in szComments = "" )
	{
		if( pCfgFile is null )
			return false;
			
		bool fSuccess = false;
		
		if( pFile !is null && pFile.IsOpen() )
		{
			fSuccess = true;
			
			WriteComments( pFile, szComments );
			
			const array<Command@>@ commands = pCfgFile.Commands;
			
			const uint uiLength = commands.length();
			
			for( uint uiIndex = 0; uiIndex < uiLength; ++uiIndex )
			{
				WriteCommand( pFile, commands[ uiIndex ] );
			}
		}
		
		return fSuccess;
	}
}
}