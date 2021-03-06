const String COMMAND_COLOR_LINE = S_COLOR_BLACK;
const String COMMAND_COLOR_HEAD = S_COLOR_RED;
const String COMMAND_COLOR_LEFT = S_COLOR_ORANGE;
const String COMMAND_COLOR_DEFAULT = S_COLOR_WHITE;
const String COMMAND_COLOR_SPECIAL = S_COLOR_YELLOW;
const String COMMAND_ERROR_PRACTICE = "This Command is only available in practicemode.";
const String COMMAND_ERROR_MYSQL = "Database not connected.";

const String[] DEVS =  { "R2", "Zaran", "Zolex", "Schaaf", "K1ll", "Weqo", "Joki" };

/**
 * Generic command class, all commands inherit from this class
 * and should override the validate and execute function
 */
class Racesow_Command
{
	/**
	 * Pointer to parent command
	 * null, if this is not a subcommand
	 */
	Racesow_Command @baseCommand;

	/**
	 * Command map for subcommands
	 * null, if this command has no subcommands
	 */
	RC_Map @commandMap;

    /**
     * The name of the command.
     * That's what the user will have to type to call the command
     */
    String name;

    /**
     * Description of what the command does.
     * This is displayed in the help
     */
    String description;

    /**
     * Usage of the command. This should document the command syntax.
     * Displayed when you do "help <command>" and also when you make an error
     * with the command syntax (e.g wrong number of arguments).
     * When describing the syntax, put the arguments name into brackets (e.g <mapname>)
     */

    String usage;
	
	/**
	 * Required User Privileges
	 * Currently only checked for admin subcommands!
	 */
	int permissionMask;

    Racesow_Command()
    {
    }

    /**
     * Non-Default constructor to be used with super() in the derived classes
     */
    Racesow_Command( String &in description, String &in usage )
    {
        //this.name = name;
        this.description = description;
        this.usage = usage;
        this.permissionMask = 0;
        @this.baseCommand = null;
        @this.commandMap = null;
    }

    /**
     * This is called before the actual work is done.
     *
     * Here you should only check the number of arguments and that
     * the player has the right to call the command.
     * Error messages should be sent in this function.
     *
     * @param player The player who calls the command
     * @param args The tokenized string of arguments
     * @param argc The number of arguments
     * @return success boolean
     */
    bool validate(Racesow_Player @player, String &args, int argc)
    {
        return true;
    }

    /**
     * This is called after the validate function.
     *
     * Technically no validation should be done here, only the real work.
     * Most probably a call to a player method.
     * @param player The player who calls the command
     * @param args The tokenized string of arguments
     * @param argc The number of arguments
     * @return success boolean
     */
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return true;
    }

    /**
     * Return the command description in a nice way to be printed
     */
    String getDescription()
    {
        return COMMAND_COLOR_LEFT + this.name + ": " + COMMAND_COLOR_DEFAULT + this.description + "\n";
    }

    /**
     * Return command line
     */

    String getCommandLine()
    {
		if( @this.baseCommand != null )
			return this.baseCommand.getCommandLine() + " " + this.name;
		else
			return " " + this.name;
    }

    /**
     * Return the command usage in a nice way to be printed
     */
    String getUsage()
    {
    	return COMMAND_COLOR_DEFAULT + "Type " + COMMAND_COLOR_LEFT + "help" + this.getCommandLine() + COMMAND_COLOR_DEFAULT + " for more information\n";
    }

    /**
     * Return the "command not found"-message in a nice way to be printed
     */
    String commandNotFound( String cmd )
    {
    	return COMMAND_COLOR_DEFAULT + "Command" + COMMAND_COLOR_SPECIAL + this.getCommandLine() + " " + cmd + COMMAND_COLOR_DEFAULT + " not found";
    }
}

/*
 * implements validate() and execute() for commands that have subcommands
 */
class Racesow_BaseCommand : Racesow_Command
{
    Racesow_BaseCommand( String &in description, String &in usage )
    {
        super( description, usage );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if ( argc < 1 )
        {
            player.sendErrorMessage( "No subcommand given." );
            player.sendMessage( this.getUsage() );
            return false;
        }

        Racesow_Command @subCommand = this.commandMap[args.getToken( 0 )];
        if ( @subCommand == null )
        {
            player.sendErrorMessage( this.commandNotFound( args.getToken( 0 ) ) );
            return false;
        }
        String newArgs = shiftArguments( args );
        return subCommand.validate( player, newArgs, argc > 0 ? argc - 1 : 0 );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Command @subCommand = this.commandMap[args.getToken( 0 )];
        String newArgs = shiftArguments( args );
        return subCommand.execute( player, newArgs, argc > 0 ? argc - 1 : 0 );
    }
}

/*
 * implements validate() for commands that have a target
 * expects a playername or playerid as first argument
 */
class Racesow_TargetCommand : Racesow_Command
{
    Racesow_TargetCommand( String &in description, String &in usage )
    {
        super( description, "<playerid/playername>" + ( usage == "" ? "" : " " + usage ) );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( argc < 1 )
        {
            player.sendErrorMessage( "No player given." );
            player.getClient().execGameCommand("cmd players");
            return false;
        }
//      Racesow_Player @targetPlayer = @this.getTargetPlayer( args.getToken( 0 ) );
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null || args.getToken( 0 ).length() == 0 )
        {
            player.sendErrorMessage( "Player " + args.getToken( 0 ) + COMMAND_COLOR_DEFAULT + " not found." );
            player.getClient().execGameCommand("cmd players");
            return false;
        }
        if( targetPlayer.getClient().getEnt().inuse )
            return true;
        player.sendErrorMessage( "Invalid player." );
        return false;
    }
    //why do these functions break subclasses???
//    Racesow_Player@ getTargetPlayer( String str )
//    {
//      return @racesowGametype.getPlayer( @Racesow_GetClientByString( str ) );
//    }
//    cClient@ getTarget( String str )
//    {
//      return @Racesow_GetClientByString( str );
//    }
}

class Command_Admin : Racesow_BaseCommand
{
    Command_Admin() {
        super( "Execute an admin command", "<subcommand> [args...]" );

        @this.commandMap = @RC_Map( 17 );
        @this.commandMap["map"] = @Command_AdminMap( @this );
        @this.commandMap["restart"] = @Command_AdminRestart( @this );
        @this.commandMap["extend_time"] = @Command_AdminExtendtime( @this );
        @this.commandMap["remove"] = @Command_AdminRemove( @this );
        @this.commandMap["kick"] = @Command_AdminKick( @this );
        @this.commandMap["kickban"] = @Command_AdminKickban( @this );
        @this.commandMap["mute"] = @Command_AdminMute( @this );
        @this.commandMap["unmute"] = @Command_AdminUnmute( @this );
        @this.commandMap["vmute"] = @Command_AdminVmute( @this );
        @this.commandMap["vunmute"] = @Command_AdminVunmute( @this );
        @this.commandMap["votemute"] = @Command_AdminVotemute( @this );
        @this.commandMap["unvotemute"] = @Command_AdminUnvotemute( @this );
        @this.commandMap["joinlock"] = @Command_AdminJoinlock( @this );
        @this.commandMap["joinunlock"] = @Command_AdminJoinunlock( @this );
        @this.commandMap["cancelvote"] = @Command_AdminCancelvote( @this );
        @this.commandMap["updateml"] = @Command_AdminUpdateml( @this );
        @this.commandMap["help"] = @Command_Help( @this, @this.commandMap );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( !Racesow_BaseCommand::validate( player, args, argc ) )
            return false;
        Racesow_Command @subCommand = this.commandMap[args.getToken( 0 )];
        if( !player.auth.allow( subCommand.permissionMask ) )
        {
//           G_PrintMsg( null, S_COLOR_WHITE + player.getName() + S_COLOR_RED
//                + " tried to execute an admin command without permission.\n" );
            player.sendErrorMessage( "You don't have permission to execute this command" );
            return false;
        }
        return true;
    }
}

class Command_AmmoSwitch : Racesow_Command
{
    Command_AmmoSwitch() {
        super( "Switch between weak and strong Ammo", "" );
    }

    bool execute( Racesow_Player @player, String &args, int argc ) {
        return player.ammoSwitch();
    }
}

class Command_Auth : Racesow_Command
{

    Command_Auth() {
        super( "Authenticate with the server (alternatively you can use setu to save your login)", "<authname> <password>" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if ( argc < 2 )
        {
            player.sendErrorMessage("You must provide your name and password");
            return false;
        }

        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return player.getAuth().authenticate(
                args.getToken( 0 ).removeColorTokens(),
                args.getToken( 1 ),
                false );
    }
}

//TODO: split this into subcommands
class Command_Chrono : Racesow_Command
{

    Command_Chrono() {
        super( "Chrono for tricks timing", "<start/reset>" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if ( argc < 1 )
        {
            player.sendErrorMessage( "you must provide a chrono command" );
            return false;
        }

        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        String command = args.getToken( 0 );
        if( command == "start" )
        {
            player.chronoStartTime = levelTime;
            player.isUsingChrono = true;
        }
        else if( command == "reset" )
        {
            player.chronoStartTime = 0;
            player.isUsingChrono = false;
        }
        else
        {
            player.sendErrorMessage( "wrong chrono command");
            return false;
        }

        return true;
    }
}

class Command_CvarInfo : Racesow_Command
{
    Command_CvarInfo() {
        super( "", "" ); //FIXME: Add description and usage
    }

    bool execute( Racesow_Player @player, String &args, int argc ) {
		//token0: Cvar name; token1: Cvar value
		String cvarName = args.getToken( 0 );
		String cvarValue = args.getToken( 1 );

		if( cvarName.substr(0,15) == "storedposition_")
		{
			String positionValues = cvarValue;
			Vec3 origin, angles;
			origin.x = positionValues.getToken( 1 ).toFloat();
			origin.y = positionValues.getToken( 2 ).toFloat();
			origin.z = positionValues.getToken( 3 ).toFloat();
			angles.x = positionValues.getToken( 4 ).toFloat();
			angles.y = positionValues.getToken( 5 ).toFloat();
			player.teleport( origin, angles, false, false );
		}
    return true;
    }
}

class Command_Gametype : Racesow_Command
{

    Command_Gametype() {
        super( "Print info about the game type", "" );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        String response = "";
        Cvar fs_game( "fs_game", "", 0 );
        String manifest = gametype.getManifest();

        response += "\n";
        response += "Gametype " + gametype.getName() + " : " + gametype.getTitle() + "\n";
        response += "----------------\n";
        response += "Version: " + gametype.getVersion() + "\n";
        response += "Author: " + gametype.getAuthor() + "\n";
        response += "Mod: " + fs_game.get_string() + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "") + "\n";
        response += "----------------\n";

        player.sendMessage(response);
        return true;
    }
}

class Command_Help : Racesow_Command
{
    RC_Map @targetCommandMap;

	Command_Help( Racesow_Command @baseCommand, RC_Map @targetCommandMap )
	{
		super( "Print this help, or give help on a specific command", "[command]" );
        @this.targetCommandMap = @targetCommandMap;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
    	Racesow_Command @command = @this.baseCommand;
    	String baseCommandString = "";
    	if( @command != null )
    		baseCommandString = command.getCommandLine();
    	if ( argc >= 1 )
        {
    		String helpItemName = args.getToken( 0 );
            @command = @this.targetCommandMap[helpItemName];
            if( @command != null )
            {
            	Racesow_Command @subHelp = null;
            	if( @command.commandMap != null ) //call specific help, if target command has subcommands
            		@subHelp = @command.commandMap[this.name];
            		@subHelp = null;
        		if( @subHelp != null )
        		{
        	        String newArgs = shiftArguments( args );
        			return subHelp.execute( player, newArgs, argc > 0 ? argc - 1 : 0 );
        		}
            	else // print usage and description
            	{
            		player.sendMessage( COMMAND_COLOR_LEFT + baseCommandString + " " + command.name
                            + ( command.usage == "" ? "" : " " + command.usage ) + ": "
            		        + COMMAND_COLOR_DEFAULT + command.description + "\n" );
            		return true;
            	}
            }
            else
            {
                player.sendErrorMessage( this.commandNotFound( helpItemName ) );
                return true;
            }
        }
        else
        {
            String help;
            help += COMMAND_COLOR_LINE + "--------------------------------------------------------------------------------------------------------------------------\n";
            help += COMMAND_COLOR_HEAD + baseCommandString.toupper() + " " + "HELP for Racesow " + gametype.getVersion() + "\n";
            help += COMMAND_COLOR_LINE + "--------------------------------------------------------------------------------------------------------------------------\n";
            player.sendMessage(help);
            help = "";

            for (uint i = 0; i < this.targetCommandMap.size(); i++)
            {
                @command = @this.targetCommandMap.getCommandAt(i);

                help += COMMAND_COLOR_LEFT + baseCommandString + " " + command.name
                        + ( command.usage == "" ? "" : " " + command.usage ) + ": "
                        + COMMAND_COLOR_DEFAULT + command.description + "\n";
                if ( (i/5)*5 == i ) //to avoid print buffer overflow
                {
                    player.sendMessage(help);
                    help = "";
                }
            }

            player.sendMessage(help);
            player.sendMessage( COMMAND_COLOR_LINE + "--------------------------------------------------------------------------------------------------------------------------\n");
            return true;
        }
    }

    /*
     * Omit the help command, when printing the command line
     */
    String getCommandLine()
    {
		if( @this.baseCommand != null )
			return this.baseCommand.getCommandLine();
		else
			return "";
    }
}

class Command_Join : Racesow_Command
{

    Command_Join() {
        super( "Join the game", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( player.isJoinlocked )
        {
            player.sendErrorMessage( "You can't join: You are join locked");
            return false;
        }

        if( map.inOvertime )
        {
            player.sendErrorMessage( "You can't join during overtime period" );
            return false;
        }
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.getClient().team = TEAM_PLAYERS;
        player.getClient().respawn( false );
        return true;
    }
}

class Command_Machinegun : Racesow_Command
{

    Command_Machinegun() {
        super( "Gives you a machinegun", "" );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
		//give machinegun (this is default behavior in defrag and usefull in some maps to shoot buttons)
		player.getClient().inventoryGiveItem( WEAP_MACHINEGUN );
		return true;
    }
}

class Command_Mapfilter : Racesow_Command
{

    Command_Mapfilter() {
        super( "Search for maps matching a given name", "<filter> <pagenum>" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if (argc < 1)
        {
            player.sendErrorMessage( "You must provide a filter name" );
            return false;
        }

        if (player.isWaitingForCommand)
        {
            player.sendErrorMessage( "Flood protection. Slow down cowboy, wait for the "
                    +"results of your previous command");
            return false;
        }

        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        String filter = args.getToken( 0 );
        int page = 1;
        if ( argc >= 2 )
            page = args.getToken( 1 ).toInt();

        player.isWaitingForCommand = true;
        return RS_MapFilter(player.getClient().playerNum(),filter,page);
    }
}

class Command_Maplist : Racesow_Command
{

    Command_Maplist() {
        super( "Print the maplist", "<pagenum>" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( player.isWaitingForCommand )
        {
            player.sendErrorMessage( "Flood protection. Slow down cowboy, wait for the "
                    +"results of your previous command");
            return false;
        }

        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        int page = 1;
        if (argc >= 1)
            page = args.getToken(0).toInt();

        return RS_Maplist(player.getClient().playerNum(),page);
    }
}

class Command_Mapname : Racesow_Command
{

    Command_Mapname() {
        super( "Print the name of current map", "" );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.sendMessage( map.name + "\n" );
        return true;
    }
}

class Command_LastMap : Racesow_Command
{

    Command_LastMap() {
        super( "Print the name of the previous map on the server, before this one", "" );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.sendMessage( previousMapName + "\n" );
        return true;
    }
}

class Command_NextMap : Racesow_Command
{

    Command_NextMap() {
        super( "Print the name of the next map in map rotation", "" );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.sendMessage( RS_NextMap() + "\n" );
        return true;
    }
}

class Command_Noclip : Racesow_Command
{

    Command_Noclip() {
        super( "Disable your interaction with other players and objects", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( @player.getClient().getEnt() == null || player.getClient().getEnt().team == TEAM_SPECTATOR )
        {
            player.sendErrorMessage( "Noclip is not available in your current state" );
            return false;
        }
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return player.noclip();
    }
}

class Command_Oneliner : Racesow_Command
{

    Command_Oneliner() {
        super( "Set a one-line message that is displayed right next to your top time", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if ( mysqlConnected == 0 )
        {
            player.sendErrorMessage( "" + COMMAND_ERROR_MYSQL );
//            player.sendMessage("This server doesn't store the best times, this command is useless\n" );
            return false;
        }
		
		if ( args.len() > 100 )
        {
            player.sendMessage("Oneliner too long (" + args.len() + " chars), please keep it under 100 characters.\n" );
            return false;
        }
		
		if ( argc < 1 )
        {
			player.sendMessage("If you are #1 on a map, you can enter a one-line message that will be printed in the highscores.\n" );
            return false;
        }
		
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
	    player.isWaitingForCommand = true;
        RS_MysqlSetOneliner(player.getClient().playerNum(), player.getId(), map.getId(), args);
        return true;
    }
}

class Command_Position : Racesow_BaseCommand
{
	Command_Position() {
        super( "Commands to store and load position", "<subcommand> [args...]" );

        @this.commandMap = @RC_Map( 7 );
        @this.commandMap["save"] = @Command_PositionSave( @this );
        @this.commandMap["load"] = @Command_PositionLoad( @this );
        @this.commandMap["set"] = @Command_PositionSet( @this );
        @this.commandMap["store"] = @Command_PositionStore( @this );
        @this.commandMap["restore"] = @Command_PositionRestore( @this );
        @this.commandMap["storedlist"] = @Command_PositionStoredlist( @this );
        @this.commandMap["help"] = @Command_Help( @this, @this.commandMap );
    }
}

//implements validate() for position subcommands
class Racesow_PositionCommand : Racesow_Command
{
	Racesow_PositionCommand( String &in description, String &in usage )
	{
        super( description, usage );
	}
	bool validate(Racesow_Player @player, String &args, int argc)
	{
		if( player.positionLastcmd + 500 > realTime )
		{
            player.sendErrorMessage( "Commands are coming too fast. Please wait " + ( player.positionLastcmd + 500 - realTime ) + "ms." );
			return false;
		}
		return true;
	}
}

class Command_PositionSave : Racesow_PositionCommand
{
	Command_PositionSave( Racesow_Command @baseCommand ) {
        super( "Save position", "" );
        @this.baseCommand = @baseCommand;
    }
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return player.positionSave();
    }
}

class Command_PositionLoad : Racesow_PositionCommand
{
	Command_PositionLoad( Racesow_Command @baseCommand ) {
        super( "Teleport to saved position", "" );
        @this.baseCommand = @baseCommand;
    }
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return player.positionLoad();
    }
}

class Command_PositionSet : Racesow_PositionCommand
{
	Command_PositionSet( Racesow_Command @baseCommand ) {
        super( "Teleport to specified position", "<x> <y> <z> <pitch> <yaw>" );
        @this.baseCommand = @baseCommand;
    }
	bool validate(Racesow_Player @player, String &args, int argc)
	{
		if( !Racesow_PositionCommand::validate( player, args, argc ) )
			return false;
		if( argc >= 5 )
			return true;
		player.sendErrorMessage( "Wrong parameters" );
		player.sendMessage( S_COLOR_WHITE + this.getUsage() );
		return false;

	}
    bool execute(Racesow_Player @player, String &args, int argc)
    {
		Vec3 origin, angles;

		origin.x = args.getToken( 0 ).toFloat();
		origin.y = args.getToken( 1 ).toFloat();
		origin.z = args.getToken( 2 ).toFloat();
		angles.x = args.getToken( 3 ).toFloat();
		angles.y = args.getToken( 4 ).toFloat();

		return player.positionSet( origin, angles );
    }
}

class Command_PositionStore : Racesow_PositionCommand
{
	Command_PositionStore( Racesow_Command @baseCommand ) {
        super( "Store a position for another session", "<id> <name>" );
        @this.baseCommand = @baseCommand;
    }
	bool validate(Racesow_Player @player, String &args, int argc)
	{
		if( !Racesow_PositionCommand::validate( player, args, argc ) )
			return false;
		if( args.getToken( 1 ) != "" )
			return true;
		player.sendErrorMessage( "Wrong parameters" );
		player.sendMessage( S_COLOR_WHITE + this.getUsage() );
		return false;
	}
    bool execute(Racesow_Player @player, String &args, int argc)
    {
		int id = args.getToken( 0 ).toInt();
		String name = args.getToken( 1 );

		return player.positionStore( id, name );
    }
}

class Command_PositionRestore : Racesow_PositionCommand
{
	Command_PositionRestore( Racesow_Command @baseCommand ) {
        super( "Restore a stored position from another session", "<id>" );
        @this.baseCommand = @baseCommand;
    }
	bool validate(Racesow_Player @player, String &args, int argc)
	{
		if( !Racesow_PositionCommand::validate( player, args, argc ) )
			return false;
		if( argc >= 1 )
			return true;
		player.sendErrorMessage( "Wrong parameters" );
		player.sendMessage( S_COLOR_WHITE + this.getUsage() );
		return false;
	}
    bool execute(Racesow_Player @player, String &args, int argc)
    {
		int id = args.getToken( 1 ).toInt();

		return player.positionRestore( id );
    }
}

const int POSITION_STOREDLIST_LIMIT = 50; //FIXME: put this into the position class, when it exists

class Command_PositionStoredlist : Racesow_PositionCommand
{
	Command_PositionStoredlist( Racesow_Command @baseCommand ) {
        super( "Sends you a list of your stored positions", "<limit>" );
        @this.baseCommand = @baseCommand;
    }
	bool validate(Racesow_Player @player, String &args, int argc)
	{
		if( !Racesow_PositionCommand::validate( player, args, argc ) )
			return false;
		if( argc >= 1 )
		{
			if( args.getToken( 1 ).toInt() <= POSITION_STOREDLIST_LIMIT )
				return true;
			else
				player.sendMessage( S_COLOR_WHITE + "You can only list the 50 the most\n" );
		}
		else
		{
			player.sendErrorMessage( "Wrong parameters" );
			player.sendMessage( S_COLOR_WHITE + this.getUsage() );
		}
		return false;
	}
    bool execute(Racesow_Player @player, String &args, int argc)
    {
		int limit = args.getToken( 0 ).toInt();
		return player.positionStoredlist( limit );
    }
}

class Command_Spec : Racesow_Command
{

    Command_Spec() {
        super( "Spectate", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.getClient().team = TEAM_SPECTATOR;
        player.getClient().respawn( true ); // true means ghost
        return true;
    }
}

class Command_Practicemode : Racesow_Command
{

    Command_Practicemode() {
        super( "Allows usage of the position and noclip commands", "" );
    }

	bool validate( Racesow_Player @player, String &args, int argc )
	{
		if ( player.getClient().team != TEAM_PLAYERS )
		{
			player.sendErrorMessage( "You must join the game before going into practice mode" );
			return false;
		}
		return true;
	}
	bool execute( Racesow_Player @player, String &args, int argc )
	{
		if ( @player.getClient() != null )
		{
			if ( player.isRacing() )
				player.cancelRace();
				
			if ( player.practicing )
			{
				player.practicing = false;
				player.sendAward( S_COLOR_GREEN + "Leaving practice mode" );
				player.restartRace();
					
				
			} else {
				player.practicing = true;
				player.sendAward( S_COLOR_GREEN + "You have entered practice mode" );
			}
			return true;
		}
		/* something went wrong */
		return false;
		
	}
}

class Command_Privsay : Racesow_TargetCommand
{
    Command_Privsay() {
        super( "Send a private message to a player", "<message>" );
    }
    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( player.getClient().muted == 1 )
        {
            player.sendErrorMessage( "You can't talk, you're muted." );
            return false;
        }
    	if( !Racesow_TargetCommand::validate( player, args, argc ) )
    		return false;
        if( args.getToken( 1 ) == "" )
        {
            player.sendErrorMessage( "You must provide a message." );
            return false;
        }
        return true;
    }
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );

        String message = args.substr(args.getToken( 0 ).length()+1, args.len() );

        player.sendMessage( S_COLOR_RED + "(Private message to " + S_COLOR_WHITE + targetPlayer.getClient().getName()
        		+ S_COLOR_RED + " ) " + S_COLOR_WHITE + ": " + message + "\n");
        targetPlayer.sendMessage( S_COLOR_RED + "(Private message from " + S_COLOR_WHITE + player.getClient().getName()
        		+ S_COLOR_RED + " ) " + S_COLOR_WHITE + ": " + message + "\n" );
        return true;
    }
}

class Command_ProtectedNick : Racesow_Command
{

    Command_ProtectedNick() {
        super( "Show/update your current protected nick", "[newnick]" );
    }

	bool validate(Racesow_Player @player, String &args, int argc)
    {
		bool is_authenticated = player.getAuth().isAuthenticated();
		bool is_nickprotected = player.getAuth().wontGiveUpViolatingNickProtection() == 0;
		bool valid = ( is_authenticated and is_nickprotected );
		
		if (not valid)
		{
			player.sendErrorMessage( "You must be authenticated and not under nick protection.");
			return false;
		}
		
		if( player.isWaitingForCommand )
        {
            player.sendErrorMessage( "Flood protection. Slow down cowboy, wait for the "
                    +"results of your previous command");
            return false;
        }
		
		return true;
	}
	
    bool execute(Racesow_Player @player, String &args, int argc)
    {
		if ( argc < 1 )
		{
			RS_GetPlayerNick( player.getClient().playerNum(), player.getId() );
		}
		else if ( args.getToken(0) == "update" )
		{
			RS_UpdatePlayerNick( player.getName(), player.getClient().playerNum(), player.getId() );
		}
		player.isWaitingForCommand = true;
        return true;
    }
}

class Command_Quad : Racesow_Command
{

    Command_Quad() {
        super( "Activate or desactivate the quad for weapons", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( @player.getClient().getEnt() == null || player.getClient().getEnt().team == TEAM_SPECTATOR )
        {
            player.sendErrorMessage("Quad is not available in your current state");
            return false;
        }
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return player.quad();
    }
}

class Command_RaceRestart : Racesow_Command
{
    Command_RaceRestart() {
        super( "Go back to the start area whenever you want", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( !player.isJoinlocked )
        	return true;
        player.sendErrorMessage( "You can't join, you are join locked" );
        return false;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.restartRace();
		return true;
    }
}

class Command_Ranking : Racesow_Command
{
    int page;
	String order;

    Command_Ranking() {
        super( "Needs description", "" ); //FIXME: <-
    }
	
    bool validate(Racesow_Player @player, String &args, int argc)
    {
        this.page = 1;
		this.order = "points";
		
        if ( mysqlConnected == 0 )
        {
            player.sendMessage("This server doesn't store the best times, this command is useless\n" );
            return false;
        }

        if (player.isWaitingForCommand)
        {
            player.sendErrorMessage( "Flood protection. Slow down cowboy, wait for the "
                    +"results of your previous command");
            return false;
        }

        if ( argc > 0 )
        {
            String firstToken = args.getToken(0);
            if ( firstToken.isNumerical() )
            {
                this.page = firstToken.toInt();
            }
        }
		
		if ( argc > 1 )
		{
			String secondToken = args.getToken(1);
			if ( secondToken == "points" || secondToken == "diff_points" ||
				secondToken == "maps" || secondToken == "races" ||
				secondToken == "playtime" ) {
			
				this.order = secondToken;
				
			} else if ( secondToken != "" ) {
			
				player.sendErrorMessage("invalid order given");
				return false;
			}
		}
		
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.isWaitingForCommand = true;
        RS_MysqlLoadRanking(player.getClient().playerNum(), this.page, this.order);
        return true;
    }

}

class Command_Register : Racesow_Command
{

    Command_Register() {
        super( "Register a new account on this server", "<authname> <email> <password> <confirmation>" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if ( argc < 4)
        {
            player.sendErrorMessage("You must provide all required information");
            return false;
        }

        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        String authName = args.getToken( 0 ).removeColorTokens();
        String authEmail = args.getToken( 1 );
        String password = args.getToken( 2 );
        String confirmation = args.getToken( 3 );

        return player.getAuth().signUp( authName, authEmail, password, confirmation );
    }
}

class Command_Stats : Racesow_BaseCommand
{
	Command_Stats() {
        super( "Show statistics", "[subcommand] [args...]" );

        @this.commandMap = @RC_Map( 3 );
        @this.commandMap["player"] = @Command_StatsPlayer( @this );
        @this.commandMap["map"] = @Command_StatsMap( @this );
        @this.commandMap["help"] = @Command_Help( @this, @this.commandMap );
    }
    bool validate(Racesow_Player @player, String &args, int argc)
    {
    	if( mysqlConnected == 0 )
    	{
            player.sendErrorMessage( "" + COMMAND_ERROR_MYSQL );
            return false;
    	}
        if( player.isWaitingForCommand )
        {
            player.sendErrorMessage( "Flood protection. Slow down cowboy, wait for the "
                    +"results of your previous command");
            return false;
        }
        if ( argc > 0 )
            return Racesow_BaseCommand::validate( player, args, argc );

        // no subcommand found. return true to get default stats.
        return true;
    }
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        if( argc > 0 )
            return Racesow_BaseCommand::execute( player, args, argc ); // this executes the subcommand
        return RS_LoadStats( player.getClient().playerNum(), "player", player.getName() );
    }
}

class Command_StatsPlayer : Racesow_Command
{
    Command_StatsPlayer( Racesow_Command @baseCommand ) {
        super( "Prints stats for the given player or yourself if no name given", "[name]" );
        @this.baseCommand = @baseCommand;
    }
    bool execute(Racesow_Player @player, String &args, int argc)
    {
    	String target;
        if( args.getToken( 0 ) != "")
        	target = args.getToken( 0 );
        else
        	target = player.getName();

        return RS_LoadStats(player.getClient().playerNum(), this.name, target);
    }
}

class Command_StatsMap : Racesow_Command
{
    Command_StatsMap( Racesow_Command @baseCommand ) {
        super( "Print stats for the given map or the current map is no name given", "<name>" );
        @this.baseCommand = @baseCommand;
    }
    bool execute(Racesow_Player @player, String &args, int argc)
    {
    	String target;
        if( args.getToken( 0 ) != "")
        	target = args.getToken( 0 );
        else
        	target = map.name;

        return RS_LoadStats(player.getClient().playerNum(), this.name, target);
    }
}

class Command_Timeleft : Racesow_Command
{

    Command_Timeleft() {
        super( "Print remaining time before map change", "" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( match.getState() == MATCH_STATE_POSTMATCH )
        {
            player.sendErrorMessage( "The command isn't available in this match state");
            return false;
        }
		
		if ( !g_maprotation.get_boolean() )
		{
			player.sendErrorMessage( "The command isn't available when g_maprotation == 0.");
            return false;
		}
		
        if( g_timelimit.get_integer() <= 0 )
        {
            player.sendErrorMessage( "There is no timelimit set");
            return false;
        }
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        uint timelimit = g_timelimit.get_integer() * 60000;//convert mins to ms
        uint time = levelTime - match.startTime(); //in ms
        uint timeleft = timelimit - time;
        if( timelimit < time )
        {
            player.sendMessage( "We are already in overtime.\n" );
            return true;
        }
        else
        {
            player.sendMessage( "Time left: " + TimeToString( timeleft ) + "\n" );
            return true;
        }
    }
}

class Command_Token : Racesow_Command
{

    Command_Token() {
        super( "When authenticated, shows your unique login token you may setu in your config", "" );
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        return player.getAuth().showToken();
    }
}

class Command_Top : Racesow_Command
{
    int limit;
    String mapname;
    int prejumped;

    Command_Top() {
        super( "Print the best times of a given map (default: current map)", "<pj/nopj> <limit(3-30)> <mapname>" );
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        this.limit = 30;
        this.mapname = "";
        this.prejumped = 2;

        if ( mysqlConnected == 0 )
        {
            player.sendErrorMessage( "" + COMMAND_ERROR_MYSQL );
//            player.sendMessage("This server doesn't store the best times, this command is useless\n" );
            return false;
        }

        if (player.isWaitingForCommand)
        {
            player.sendErrorMessage( "Flood protection. Slow down cowboy, wait for the "
                    +"results of your previous command");
            return false;
        }

        if ( argc > 0 )
        {
            String firstToken = args.getToken(0);
            if ( firstToken.isNumerical() )
            {
                this.limit = firstToken.toInt();
                if ( argc > 1 )
                    mapname = args.getToken(1);
            }
            else
            {
                if (firstToken == "pj")
                    this.prejumped = 0;
                else if (firstToken == "nopj")
                    this.prejumped = 1;
                else
                    return false;
                if ( argc > 1 )
                    this.limit = args.getToken(1).toInt();
                if ( argc > 2 )
                    mapname = args.getToken(2);
            }
            if ( this.limit < 3 || this.limit > 30)
            {
                player.sendErrorMessage("You must use a limit between 3 and 30");
                return false;
            }
        }
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.isWaitingForCommand=true;
        RS_MysqlLoadHighscores(player.getClient().playerNum(), this.limit, map.getId(), this.mapname, this.prejumped);
        return true;
    }

}

/*class Command_Weapondef : Racesow_Command
{
    Command_Weapondef() {
        super( "weapondef", "", "" ) //FIXME: Either fully remove or add description and usage
    }

    bool execute( Racesow_Player @player, String &args, int argc ) {
		return weaponDefCommand( args, @client );
    }
}*/

class Command_WhoIsGod : Racesow_Command
{
    String[] devs;
    Command_WhoIsGod() {
        super( "Which one is yours?", "" );
        this.devs.resize(DEVS.length());
        for( uint i = 0; i < DEVS.length(); i++)
            this.devs[i] = DEVS[i];
    }

    Command_WhoIsGod(String &in extraDevName) {
        super( "Which one is yours?", "" );
        this.devs.resize(DEVS.length()+1);
        for( uint i = 0; i < DEVS.length(); i++)
            this.devs[i] = DEVS[i];
        this.devs[DEVS.length()] = extraDevName;
    }

    Command_WhoIsGod(String[] &in extraDevNames) {
        super( "Which one is yours?", "" );
        this.devs.resize(DEVS.length()+extraDevNames.length());
        for( uint i = 0; i < DEVS.length(); i++)
            this.devs[i] = DEVS[i];
        for( uint i = 0; i < extraDevNames.length(); i++)
            this.devs[i+DEVS.length()] = extraDevNames[i];
    }

    bool execute( Racesow_Player @player, String &args, int argc ) {
        player.sendMessage( devs[brandom( 0, devs.length())] + "\n");
        return true;
    }
}

//TODO: Can this be removed? -K1ll
/**
 * Find a command by its name
 *
 * @param name The name of the command you are looking for
 * @return Racesow_Command@ handler to the command found or null if not found
 */
/*Racesow_Command@ RS_GetCommandByName(String name)
{
    for (int i = 0; i < commandCount; i++)
    {
        if ( commands[i].name == name )
            return commands[i];
    }

    return null;
}*/

//class Racesow_AdminCommand : Racesow_Command
//{
//    /**
//     * Required User Privileges
//     */
//    int permissionMask;
//
//    /**
//     * Non-Default constructor to be used with super() in the derived classes
//     */
//    Racesow_AdminCommand( String &in description, String &in usage, int auth )
//    {
//        super( description, usage );
//        this.permissionMask = auth;
//    }
//
//    bool validate(Racesow_Player @player, String &args, int argc) { return true; }
//
//    bool execute(Racesow_Player @player, String &args, int argc) { return true; }
//}

class Command_AdminMap : Racesow_Command // (should be subclass of Racesow_AdminCommand )
{
	Command_AdminMap( Racesow_Command @baseCommand )
	{
		super( "change to the given map immediately", "<mapname>" );
        this.permissionMask = RACESOW_AUTH_MAP;
        @this.baseCommand = @baseCommand;
	}

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if ( argc >= 1 )
        {
            String mapName = args.getToken( 0 );
            if ( mapName != "" )
                return true;
        }
        player.sendErrorMessage( "No map name given" );
        player.sendMessage( this.getUsage() );
        return false;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        String mapName = args.getToken( 0 );
        G_CmdExecute( "gamemap " + mapName + "\n" );
        return true;
    }
}

class Command_AdminUpdateml : Racesow_Command // (should be subclass of Racesow_AdminCommand )
{
	Command_AdminUpdateml( Racesow_Command @baseCommand )
	{
		super( "Update the maplist", "" );
        this.permissionMask = RACESOW_AUTH_ADMIN;
        @this.baseCommand = @baseCommand;
	}
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        RS_UpdateMapList( player.client.playerNum() );
        return true;
    }
}

class Command_AdminRestart : Racesow_Command // (should be subclass of Racesow_AdminCommand )
{
	Command_AdminRestart( Racesow_Command @baseCommand )
	{
		super( "restart the match immediately", "" );
        this.permissionMask = RACESOW_AUTH_MAP;
        @this.baseCommand = @baseCommand;
	}
    bool execute(Racesow_Player @player, String &args, int argc)
    {
        G_CmdExecute("match restart\n");
        return true;
    }
}

class Command_AdminExtendtime : Racesow_Command // (should be subclass of Racesow_AdminCommand )
{
	Command_AdminExtendtime( Racesow_Command @baseCommand )
	{
		super( "extend the matchtime immediately", "" );
        this.permissionMask = RACESOW_AUTH_MAP;
        @this.baseCommand = @baseCommand;
	}
    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( g_timelimit.get_integer() <= 0 )
        {
            player.sendErrorMessage( "This command is only available for timelimits.\n");
            return false;
        }
        return true;
    }

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        g_timelimit.set(g_timelimit.get_integer() + g_extendtime.get_integer());

        map.cancelOvertime(); //FIXME: merge player.cancelOvertime and map.cancelOvertime into a gametype function?
        for ( int i = 0; i < maxClients; i++ )
        {
            racesowGametype.players[i].cancelOvertime();
        }
        return true;
    }
}

class Command_AdminCancelvote : Racesow_Command // (should be subclass of Racesow_AdminCommand )
{
	Command_AdminCancelvote( Racesow_Command @baseCommand )
	{
		super( "cancel the currently active vote", "" );
        this.permissionMask = RACESOW_AUTH_MAP;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        RS_cancelvote();
        return true;
    }
}

class Command_AdminMute : Racesow_TargetCommand
{
	Command_AdminMute( Racesow_Command @baseCommand )
	{
		super( "mute the given player immediately", "" );
        this.permissionMask = RACESOW_AUTH_MUTE;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        cClient @target = @Racesow_GetClientByString( args.getToken( 0 ) );
        if( @target == null )
            return false;
        target.muted |= 1;
        player.sendMessage( "Muted player " + target.getName() + COMMAND_COLOR_DEFAULT + ".\n" ); // send these messages to all players?
        return true;
    }
}

class Command_AdminUnmute : Racesow_TargetCommand
{
	Command_AdminUnmute( Racesow_Command @baseCommand )
	{
		super( "unmute the given player immediately", "" );
        this.permissionMask = RACESOW_AUTH_MUTE;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        cClient @target = @Racesow_GetClientByString( args.getToken( 0 ) );
        if( @target == null )
            return false;
        target.muted &= ~1;
        player.sendMessage( "Unmuted player " + target.getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminVmute : Racesow_TargetCommand
{
	Command_AdminVmute( Racesow_Command @baseCommand )
	{
		super( "vmute the given player immediately", "" );
        this.permissionMask = RACESOW_AUTH_MUTE;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        cClient @target = @Racesow_GetClientByString( args.getToken( 0 ) );
        if( @target == null )
            return false;
        target.muted |= 2;
        player.sendMessage( "Vmuted player " + target.getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminVunmute : Racesow_TargetCommand
{
	Command_AdminVunmute( Racesow_Command @baseCommand )
	{
		super( "vunmute the given player immediately", "" );
		this.permissionMask = RACESOW_AUTH_MUTE;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        cClient @target = @Racesow_GetClientByString( args.getToken( 0 ) );
        if( @target == null )
            return false;
        target.muted &= ~2;
        player.sendMessage( "Vunmuted player " + target.getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminVotemute : Racesow_TargetCommand
{
	Command_AdminVotemute( Racesow_Command @baseCommand )
	{
		super( "disable voting for the given player", "" );
		this.permissionMask = RACESOW_AUTH_MUTE;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null )
            return false;
        targetPlayer.isVotemuted = true;
        player.sendMessage( "Votemuted player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminUnvotemute : Racesow_TargetCommand
{
	Command_AdminUnvotemute( Racesow_Command @baseCommand )
	{
		super( "enable voting for the given player", "" );
		this.permissionMask = RACESOW_AUTH_MUTE;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null )
            return false;
        targetPlayer.isVotemuted = false;
        player.sendMessage( "Unvotemuted player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminRemove : Racesow_TargetCommand
{
	Command_AdminRemove( Racesow_Command @baseCommand )
	{
		super( "remove the given player immediately", "" );
		this.permissionMask = RACESOW_AUTH_KICK;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null )
            return false;
        targetPlayer.remove("");
        player.sendMessage( "Removed player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminKick : Racesow_TargetCommand
{
	Command_AdminKick( Racesow_Command @baseCommand )
	{
		super( "kick the given player immediately", "" );
		this.permissionMask = RACESOW_AUTH_KICK;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null )
            return false;
        targetPlayer.kick("");
        player.sendMessage( "Kicked player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminJoinlock : Racesow_TargetCommand
{
	Command_AdminJoinlock( Racesow_Command @baseCommand )
	{
		super( "prevent the given player from joining", "" );
		this.permissionMask = RACESOW_AUTH_KICK;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null )
            return false;
        targetPlayer.isJoinlocked = true;
        player.sendMessage( "Joinlocked player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminJoinunlock : Racesow_TargetCommand
{
	Command_AdminJoinunlock( Racesow_Command @baseCommand )
	{
		super( "allow the given player to join", "" );
		this.permissionMask = RACESOW_AUTH_KICK;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        if( @targetPlayer == null )
            return false;
        targetPlayer.isJoinlocked = false;
        player.sendMessage( "Joinunlocked player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}

class Command_AdminKickban : Racesow_TargetCommand
{
	Command_AdminKickban( Racesow_Command @baseCommand )
	{
		super( "kickban the given player immediately", "" );
		this.permissionMask = RACESOW_AUTH_ADMIN;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( @Racesow_GetClientByString( args.getToken( 0 ) ) );
        targetPlayer.kickban("");
        player.sendMessage( "Kickbanned player " + targetPlayer.getClient().getName() + COMMAND_COLOR_DEFAULT + ".\n" );
        return true;
    }
}






//Commented out for release - Per server admin/authmasks will be finished when the new http DB-Interaction is done
// add command - adds a new admin (sets all permissions except RACESOW_AUTH_SETPERMISSION)
// delete command - deletes admin rights for the given player
/*
class Command_AdminAdd : Racesow_TargetCommand
{
	Command_AdminAdd( Racesow_Command @baseCommand )
	{
		super( "add", "add", "<playerid>" );
		this.permissionMask = RACESOW_AUTH_ADMIN | RACESOW_AUTH_SETPERMISSION;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.sendErrorMessage("added");
        //player.setAuthmask( RACESOW_AUTH_ADMIN );
        return true;
    }
}

class Command_AdminDelete : Racesow_TargetCommand
{
	Command_AdminDelete( Racesow_Command @baseCommand )
	{
		super( "delete", "delete", "<playerid>" );
		this.permissionMask = RACESOW_AUTH_ADMIN | RACESOW_AUTH_SETPERMISSION;
        @this.baseCommand = @baseCommand;
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
        player.sendErrorMessage("deleted");
        //player.setAuthmask( RACESOW_AUTH_REGISTERED );
        return true;
    }
}


class Command_AdminSetpermission : Racesow_TargetCommand
{
	Command_AdminSetpermission( Racesow_Command @baseCommand )
    {
        super( "setpermission", "setpermission", "<playerid> <permission> <value>" );
		this.permissionMask = RACESOW_AUTH_ADMIN | RACESOW_AUTH_SETPERMISSION;
        @this.baseCommand = @baseCommand;
    }

	bool validate( Racesow_Player @player, String &args, int argc )
	{
		if( Racesow_TargetCommand::validate( player, args, argc ) ) //FIXME: does this work?
		{

	        if( args.getToken( 1 ) == "" )
	        {
	            //show list of permissions: map, mute, kick, timelimit, restart, setpermission
	            player.sendErrorMessage( "No permission specified. Available permissions:\n map, mute, kick, timelimit, restart, setpermission" );
	            return false;
	        }

	        if( args.getToken( 2 ) == "" || args.getToken( 2 ).toInt() > 1 )
	        {
	            //show: 1 to enable 0 to disable current: <enabled/disabled>
	            player.sendErrorMessage( "1 to enable permission 0 to disable permission" );
	            return false;
	        }
			return true;
		}
	}

    bool execute(Racesow_Player @player, String &args, int argc)
    {
    	uint permission;

        if( args.getToken( 2 ) == "map" )
            permission = RACESOW_AUTH_MAP;
        else if( args.getToken( 2 ) == "mute" )
            permission = RACESOW_AUTH_MUTE;
        else if( args.getToken( 2 ) == "kick" )
            permission = RACESOW_AUTH_KICK;
        else if( args.getToken( 2 ) == "timelimit" )
            permission = RACESOW_AUTH_TIMELIMIT;
        else if( args.getToken( 2 ) == "restart" )
            permission = RACESOW_AUTH_RESTART;
        else if( args.getToken( 2 ) == "setpermission" )
            permission = RACESOW_AUTH_SETPERMISSION;
        else
            return false;

        Racesow_Player @targetPlayer = @racesowGametype.getPlayer( args.getToken( 1 ).toInt() );

        if( args.getToken( 3 ).toInt() == 1 )
            player.sendErrorMessage( args.getToken( 2 ) + "enabled" );
            //targetPlayer.setAuthmask( player.authmask | permission );
        else
            player.sendErrorMessage( args.getToken( 2 ) + "disabled" );
            //targetPlayer.setAuthmask( player.authmask & ~permission );
    }
}
*/




/*
 * Internal Commands
 */

/*
 * Command_CallvoteCheckPermission is like Command_CallvoteValidate,
 * but it's called at EVERY callvote
 * even if the callvote was not registered by the gametype script
 */
class Command_CallvoteCheckPermission : Racesow_Command {

    bool execute( Racesow_Player @player, String &args, int argc ) {
        if ( player.isVotemuted )
        {
            player.sendErrorMessage( "You are votemuted" );
            return false;
        }
        else
        {
            String vote = args.getToken( 0 );
            if( vote == "mute" || vote == "vmute" ||
                vote == "kickban" || vote == "kick" || vote == "remove" ||
                vote == "joinlock" || vote == "joinunlock" )
            {
                Racesow_Player @victimPlayer;
                String victim = args.getToken( 1 );

                if ( Racesow_GetClientNumber( victim ) != -1 )
                    @victimPlayer = racesowGametype.players[ Racesow_GetClientNumber( victim ) ];
                else if( victim.isNumerical() )
                {
                    if ( victim.toInt() > maxClients )
                        return true;
                    else
                        @victimPlayer = racesowGametype.players[ victim.toInt() ];
                }
                else
                    return true;

                if( victimPlayer.auth.allow(RACESOW_AUTH_ADMIN) )
                {
                    G_PrintMsg( null, S_COLOR_WHITE + player.getName()
                                + S_COLOR_RED + " tried to "
                                + args.getToken( 0 ) + " an admin.\n" );
                    return false;
                }
                else
                {
                    return true;
                }
            }
            else
            {
                return true;
            }
        }
    }
}

/*
 * Command_CallvoteValidate and Command_CallvotePassed are only called
 * at callvotes that were registered by the gametype script
 */
class Command_CallvoteValidate : Racesow_BaseCommand
{

    Command_CallvoteValidate( RC_Map @commandMap ) {
        super( "", "" );
        @this.commandMap = @commandMap;
    }

    // don't execute here
    bool execute( Racesow_Player @player, String &args, int argc ) { return true; }

//    bool execute( Racesow_Player @player, String &args, int argc ) {
//        String vote = args.getToken( 0 );
//
//        if( this.gametypeVotes(player, args, argc) )
//            return true;
//
//        if ( vote == "extend_time" )
//        {
//            if( g_timelimit.get_integer() <= 0 )
//            {
//                player.getClient().printMessage( "This vote is only available for timelimits.\n");
//                return false;
//            }
//            uint timelimit = g_timelimit.get_integer() * 60000;//convert mins to ms
//            uint extendtimeperiod = rs_extendtimeperiod.get_integer() * 60000;//convert mins to ms
//            uint time = levelTime - match.startTime(); //in ms
//            uint remainingtime = timelimit - time;
//            bool isNegative = (timelimit < time ) ? true : false;
//            if( remainingtime > extendtimeperiod && !isNegative )
//            {
//                player.getClient().printMessage( "This vote is only in the last " + rs_extendtimeperiod.get_string() + " minutes available.\n" );
//                return false;
//            }
//            return true;
//        }
//        if ( vote == "timelimit" )
//        {
//            int new_timelimit = args.getToken( 1 ).toInt();
//
//            if ( new_timelimit < 0 )
//            {
//                player.getClient().printMessage( "Can't set negative timelimit\n");
//                return false;
//            }
//
//            if ( new_timelimit == g_timelimit.get_integer() )
//            {
//                player.getClient().printMessage( S_COLOR_RED + "Timelimit is already set to " + new_timelimit + "\n" );
//                return false;
//            }
//
//            return true;
//        }
//
//        if ( vote == "spec" )
//        {
//            if ( ! map.inOvertime )
//            {
//                player.getClient().printMessage( S_COLOR_RED + "Callvote spec is only valid during overtime\n");
//                return false;
//            }
//
//            return true;
//        }
//
//        if ( vote == "joinlock" || vote == "joinunlock" )
//    {
//      if( argc != 2 )
//        {
//        player.getClient().printMessage( "Usage: callvote " + vote + " <id or name>\n" );
//            player.getClient().printMessage( "- List of current players:\n" );
//
//            for ( int i = 0; i < maxClients; i++ )
//            {
//              if ( @racesowGametype.players[i].getClient() != null )
//            player.getClient().printMessage( "  " + racesowGametype.players[i].getClient().playerNum() + ": " + racesowGametype.players[i].getClient().getName() + "\n");
//        }
//
//        return false;
//        }
//      else
//        {
//          cClient@ target = null;
//
//        if ( args.getToken( 1 ).isNumerical() && args.getToken( 1 ).toInt() <= maxClients )
//            @target = @G_GetClient( args.getToken( 1 ).toInt() );
//        else if ( Racesow_GetClientNumber( args.getToken( 1 ) ) != -1 )
//            @target = @G_GetClient( Racesow_GetClientNumber( args.getToken( 1 ) ) );
//
//        if ( @target == null || !target.getEnt().inuse )
//        {
//            player.getClient().printMessage( S_COLOR_RED + "Invalid player\n" );
//            return false;
//        }
//      }
//
//            return true;
//        }
//
//        player.getClient().printMessage( "Unknown callvote " + vote + "\n" );
//        return false;
//    }
}

class Command_CallvotePassed : Racesow_BaseCommand
{

    Command_CallvotePassed( RC_Map @commandMap ) {
        super( "", "" );
        @this.commandMap = @commandMap;

    }

    // don't validate here
    bool validate( Racesow_Player @player, String &args, int argc ) { return true; }

//    bool execute( Racesow_Player @player, String &args, int argc ) {
//        String vote = args.getToken( 0 );
//
//        if( this.gametypeVotes(player, args, argc) )
//            return true;
//
//        if ( vote == "extend_time" )
//        {
//            g_timelimit.set(g_timelimit.get_integer() + g_extendtime.get_integer());
//            map.cancelOvertime();
//            for ( int i = 0; i < maxClients; i++ )
//            {
//                racesowGametype.players[i].cancelOvertime();
//            }
//        }
//
//        if ( vote == "timelimit" )
//        {
//            int new_timelimit = args.getToken( 1 ).toInt();
//            g_timelimit.set(new_timelimit);
//
//            // g_timelimit_reset == 1: this timelimit value is not kept after current map
//            // g_timelimit_reset == 0: current value is permanently stored in g_timelimit as long as the server runs
//            if (g_timelimit_reset.get_boolean() == false)
//            {
//                oldTimelimit = g_timelimit.get_integer();
//            }
//        }
//
//        if ( vote == "spec" )
//        {
//            for ( int i = 0; i < maxClients; i++ )
//            {
//                if ( @racesowGametype.players[i].getClient() != null )
//                {
//                    racesowGametype.players[i].moveToSpec( S_COLOR_RED + "You have been moved to spec cause you were playing in overtime.\n");
//                }
//            }
//
//        }
//
//        if ( vote == "joinlock" || vote == "joinunlock" )
//        {
//            Racesow_Player@ target = null;
//
//            if ( args.getToken( 1 ).isNumerical() && args.getToken( 1 ).toInt() <= maxClients )
//                @target = @racesowGametype.getPlayer( args.getToken( 1 ).toInt() );
//            else if ( Racesow_GetClientNumber( args.getToken( 1 ) ) != -1 )
//                @target = @racesowGametype.getPlayer( Racesow_GetClientNumber( args.getToken( 1 ) ) );
//
//            if ( vote == "joinlock" )
//                target.isJoinlocked = true;
//            else
//                target.isJoinlocked = false;
//
//            return true;
//        }
//
//        return true;
//    }

}




/*
 * Callvotes
 */

class Command_CallvoteJoinlock : Command_AdminJoinlock // recycle some code from admin commands
{
    Command_CallvoteJoinlock()
    {
        super( null ); // don't need a working command chain. there is no help available for these commands.
        this.permissionMask = 0;
    }
}

class Command_CallvoteJoinunlock : Command_AdminJoinunlock
{
    Command_CallvoteJoinunlock()
    {
        super( null );
        this.permissionMask = 0;
    }
}

class Command_CallvoteExtend_time : Command_AdminExtendtime
{
    Command_CallvoteExtend_time()
    {
        super( null );
        this.permissionMask = 0;
    }

    bool validate(Racesow_Player @player, String &args, int argc)
    {
        if( !Command_AdminExtendtime::validate( player, args, argc ) )
            return false;

        uint timelimit = g_timelimit.get_integer() * 60000;//convert mins to ms
        uint extendtimeperiod = rs_extendtimeperiod.get_integer() * 60000;//convert mins to ms
        uint time = levelTime - match.startTime(); //in ms
        uint remainingtime = timelimit - time;
        bool isNegative = (timelimit < time ) ? true : false;
        if( remainingtime > extendtimeperiod && !isNegative )
        {
            player.getClient().printMessage( "This vote is only in the last " + rs_extendtimeperiod.get_string() + " minutes available.\n" );
            return false;
        }
        return true;
    }
}

class Command_CallvoteTimelimit : Racesow_Command
{
    Command_CallvoteTimelimit()
    {
        super( "Set match timelimit.", "<minutes>" );
    }

    bool validate( Racesow_Player @player, String &args, int argc )
    {
        // TODO: check if arg is numerical
        int new_timelimit = args.getToken( 0 ).toInt();

        if( new_timelimit < 0 )
        {
            player.getClient().printMessage( "Can't set negative timelimit\n" );
            return false;
        }

        if( new_timelimit == g_timelimit.get_integer() )
        {
            player.getClient().printMessage( S_COLOR_RED + "Timelimit is already set to " + new_timelimit + "\n" );
            return false;
        }

        return true;
    }

    bool execute( Racesow_Player @player, String &args, int argc )
    {
        int new_timelimit = args.getToken( 0 ).toInt();
        g_timelimit.set(new_timelimit);

        // g_timelimit_reset == 1: this timelimit value is not kept after current map
        // g_timelimit_reset == 0: current value is permanently stored in g_timelimit as long as the server runs
        if (g_timelimit_reset.get_boolean() == false)
        {
            oldTimelimit = g_timelimit.get_integer();
        }
        return true;
    }
}

class Command_CallvoteSpec : Racesow_Command
{
    Command_CallvoteSpec()
    {
        super( "During overtime, move all players to spectators.", "" );
    }

    bool validate( Racesow_Player @player, String &args, int argc )
    {
        if( !map.inOvertime )
        {
            player.getClient().printMessage( S_COLOR_RED + "Callvote spec is only valid during overtime\n" );
            return false;
        }
        return true;
    }

    bool execute( Racesow_Player @player, String &args, int argc )
    {
        for( int i = 0; i < maxClients; i++ )
            if( @racesowGametype.players[ i ].getClient() != null )
                racesowGametype.players[ i ].moveToSpec( S_COLOR_RED + "You have been moved to spec cause you were playing in overtime.\n" );
        return true;
    }
}
