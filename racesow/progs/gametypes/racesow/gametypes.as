/**
 * Racesow_Gametype
 */
class Racesow_Gametype
{
    Racesow_Player@[] players;

    // commands that are not available to players
    RC_Map @commandMapInternal;

    // commands that can be called by players
    RC_Map @commandMap;

    /*
     *  callvotes ( accessed by "callvotevalidate" and "callvotepassed" commands )
     *  gametype registers these callvotes
     */
    RC_Map @voteMap;

    bool ammoSwitch; // joki: I don't get the purpose of this variable... gametypes could just not register the ammoswitch command
    bool timelimited;
    bool racescore; //FIXME: See player/auth.as

    Racesow_Gametype()
    {
        this.players.resize(maxClients); //Racesow_Player@[](maxClients);

        @this.commandMapInternal = @RC_Map( 3 );
        @this.voteMap = @RC_Map();
        @commandMapInternal["callvotecheckpermission" ] = @Command_CallvoteCheckPermission();
        @commandMapInternal["callvotevalidate" ] = @Command_CallvoteValidate( @this.voteMap );
        @commandMapInternal["callvotepassed"] = @Command_CallvotePassed( @this.voteMap );

        @this.commandMap = @RC_Map();
        insertDefaultCommands(this.commandMap);
        this.ammoSwitch = false;
        this.timelimited = true;
        this.racescore = false;
    }

    void InitGametype() { }

    void LoadMapList()
    {
        // load maps list (basic or mysql)
	    RS_LoadMapList( 0 );
    }
    
    void SpawnGametype() { }
    
    void Shutdown() { }

    bool ammoSwitchAllowed() { return this.ammoSwitch; }
    
    bool MatchStateFinished( int incomingMatchState )
    {
        assert( false, "You have to overwrite 'bool MatchStateFinished( int incomingMatchState )' in your Racesow_Gametype" );
        return false;
    }
    
    void MatchStateStarted() { }
    
    void ThinkRules() { }
    
    void playerRespawn( cEntity @ent, int old_team, int new_team ) { }
    
    void scoreEvent( cClient @client, String &score_event, String &args ) { }
    
    String @ScoreboardMessage( uint maxlen )
    {
        assert( false, "You have to overwrite 'String @ScoreboardMessage( int maxlen )' in your Racesow_Gametype." );
        return "This needs to be overwritten!\n";
    }
    
    cEntity @SelectSpawnPoint( cEntity @self )
    {
        assert( false, "You have to overwrite 'cEntity @SelectSpawnPoint( cEntity @self )' in your Racesow_Gametype." ); 
        return cEntity(); 
    }
    
    bool UpdateBotStatus( cEntity @self ) 
    {
        assert( false, "You have to overwrite 'bool UpdateBotStatus( cEntity @self )' in your Racesow_Gametype." ); 
        return false;
    }

	/**
	 * execute a Racesow_Command
     * @param client Client who wants to execute the command
	 * @param cmdString Name of Command to execute
	 * @param argsString Arguments passed to the command
	 * @param argc Number of arguments
	 * @return Success boolean
	 */
    bool Command( cClient @client, String @cmdString, String @argsString, int argc )
    {
        Racesow_Command @command;
        Racesow_Player @player = racesowGametype.getPlayer( client );


        // check if it was an internal command
        @command = @this.commandMapInternal[cmdString];
        if( @command != null )
        {
            if( command.validate( player, argsString, argc ) )
                return command.execute( player, argsString, argc );
            return false;
        }

        @command = @this.commandMap[cmdString];
        if( @command != null ) {
	        if(command.validate(player, argsString, argc))
	        {
	            if(command.execute(player, argsString, argc))
	                return true;
	            else
	            {
	                player.sendErrorMessage( "Command " + command.name + " failed." );
	                return false;
	            }
	        }
        }
        return false;
    }

    void registerCommands() { this.commandMap.register(); }

    void registerVotes()
    {
        for( uint i = 0; i < this.voteMap.size(); i++ )
        {
            Racesow_Command @cmd = @this.voteMap.getCommandAt( i );
            G_RegisterCallvote( cmd.name, cmd.usage, cmd.description );
        }
    }

    void onConnect( cClient @client )
    {
        @this.players[client.playerNum()] = Racesow_Player( client );
    }

    void onDisconnect( cClient @client )
    {
        @this.players[client.playerNum()] = Racesow_Player();
    }

    /**
     * getPlayer
     * @param int playerNum
     * @return Racesow_Player
     */
    Racesow_Player @getPlayer(int playerNum)
    {
        if ( playerNum < 0 )
            return null;
        return @this.players[ playerNum ];
    }

    /**
     * getPlayer
     * @param cClient @client
     * @return Racesow_Player
     */
    Racesow_Player @getPlayer( cClient @client )
    {
        if ( @client == null || client.playerNum() < 0 )
            return null;

        return @this.players[ client.playerNum() ]; //.setClient( @client ); //FIXME: why set the client HERE??
    }

}
