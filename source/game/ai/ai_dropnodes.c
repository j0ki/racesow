/*
   Copyright (C) 1997-2001 Id Software, Inc.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

   See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
   --------------------------------------------------------------
   The ACE Bot is a product of Steve Yeager, and is available from
   the ACE Bot homepage, at http://www.axionfx.com/ace.

   This program is a modification of the ACE Bot, and is therefore
   in NO WAY supported by Steve Yeager.
 */

#include "../g_local.h"
#include "ai_local.h"


//ACE


typedef struct
{
	edict_t	*ent;

	qboolean was_falling;
	int last_node;

} player_dropping_nodes_t;
player_dropping_nodes_t	player;


//===========================================================
//
//				EDIT NODES
//
//===========================================================

/*
* AI_AddNode
* Add a node of normal navigation types.
* Not valid to add nodes from entities
*/
static int AI_AddNode( vec3_t origin, int flagsmask )
{
	if( nav.num_nodes + 1 > MAX_NODES )
		return -1;

	if( flagsmask & NODEFLAGS_WATER )
		flagsmask |= NODEFLAGS_FLOAT;

	VectorCopy( origin, nodes[nav.num_nodes].origin );
	if( !( flagsmask & NODEFLAGS_FLOAT ) )
		AI_DropNodeOriginToFloor( nodes[nav.num_nodes].origin, player.ent );

	nodes[nav.num_nodes].flags = flagsmask;
	nodes[nav.num_nodes].flags |= AI_FlagsForNode( nodes[nav.num_nodes].origin, player.ent );

	Com_Printf( "Dropped Node\n" );

	nav.num_nodes++;
	return nav.num_nodes-1; // return the node added
}

void AI_DeleteNode( int node )
{
	int i;
	if( !nav.editmode || nav.loaded )
	{
		Com_Printf( "       : Can't delete nodes when not in editing mode.\n" );
		return;
	}

	if( nodes[node].flags & NODE_MASK_SERVERFLAGS )
	{
		Com_Printf( "Can't delete nodes generated by the server\n" );
		return;
	}
	for( i = 0; i < nav.num_goalEnts; i++ )
	{
		if( nav.goalEnts[i].node == node )
		{
			Com_Printf( "Can't delete entity nodes\n" );
			return;
		}
	}
	if( node != NODE_INVALID && node >= 0 && node < nav.num_nodes )
	{
		for( i = node + 1; i < nav.num_nodes; i++ )
		{
			memcpy( &nodes[i - 1], &nodes[i], sizeof( nav_node_t ) );
			memcpy( &pLinks[i - 1], &pLinks[i], sizeof( nav_plink_t ) );
		}
		nav.num_nodes--;
		memset( &nodes[nav.num_nodes], 0, sizeof( nav_node_t ) );
		memset( &pLinks[nav.num_nodes], 0, sizeof( nav_plink_t ) );
	}
}

//==========================================
// AI_UpdateNodeEdge
// Add/Update node connections (paths)
//==========================================
static void AI_UpdateNodeEdge( int from, int to )
{
	int link;

	if( from == -1 || to == -1 || from == to )
		return; // safety


	if( AI_PlinkExists( from, to ) )
	{
		link = AI_PlinkMoveType( from, to );
		Com_Printf( "= Link: %i -> %i. %s\n", from, to, AI_LinkString( link ) );
	}
	else
	{
		link = AI_FindLinkType( from, to );

		Com_Printf( "^2+^7 Link: %i -> %i. %s\n", from, to, AI_LinkString( link ) );
	}
}



//===========================================================
//
//			PLAYER DROPPING NODES
//
//===========================================================


//==========================================
// AI_DropLadderNodes
// drop nodes all along the ladder
//==========================================
static void AI_DropLadderNodes( edict_t *self )
{
	vec3_t torigin;
	vec3_t borigin;
	vec3_t droporigin;
	int step;
	trace_t trace;

	//find top & bottom of the ladder
	VectorCopy( self->s.origin, torigin );
	VectorCopy( self->s.origin, borigin );

	while( AI_IsLadder( torigin, self->r.client->ps.viewangles, self->r.mins, self->r.maxs, self ) )
	{
		torigin[2]++;
	}
	torigin[2] += ( self->r.mins[2] + 8 );

	//drop node on top
	AI_AddNode( torigin, ( NODEFLAGS_LADDER|NODEFLAGS_FLOAT ) );

	//find bottom. Try simple first
	//trace = gi.trace( borigin, tv(-15,-15,-24), tv(15,15,0), tv(borigin[0], borigin[1], borigin[2] - 2048), self, MASK_NODESOLID );
	G_Trace( &trace, borigin, playerbox_crouch_mins, tv( playerbox_crouch_maxs[0], playerbox_crouch_maxs[1], 0 ), tv( borigin[0], borigin[1], borigin[2] - 2048 ), self, MASK_NODESOLID );
	if( !trace.startsolid && trace.fraction < 1.0
	   && AI_IsLadder( trace.endpos, self->r.client->ps.viewangles, self->r.mins, self->r.maxs, self ) )
	{
		VectorCopy( trace.endpos, borigin );

	}
	else
	{
		//it wasn't so easy

		//trace = gi.trace( borigin, tv(-15,-15,-25), tv(15,15,0), borigin, self, MASK_NODESOLID );
		G_Trace( &trace, borigin, tv( playerbox_crouch_mins[0], playerbox_crouch_mins[1], playerbox_crouch_mins[2]-1 ), tv( playerbox_crouch_maxs[0], playerbox_crouch_maxs[1], 0 ), borigin, self, MASK_NODESOLID );
		while( AI_IsLadder( borigin, self->r.client->ps.viewangles, self->r.mins, self->r.maxs, self )
		       && !trace.startsolid )
		{
			borigin[2]--;
			//trace = gi.trace( borigin, tv(-15,-15,-25), tv(15,15,0), borigin, self, MASK_NODESOLID );
			G_Trace( &trace, borigin, tv( playerbox_crouch_mins[0], playerbox_crouch_mins[1], playerbox_crouch_mins[2]-1 ), tv( playerbox_crouch_maxs[0], playerbox_crouch_maxs[1], 0 ), borigin, self, MASK_NODESOLID );
		}

		//if trace never reached solid, put the node on the ladder
		if( !trace.startsolid )
			borigin[2] -= self->r.mins[2];
	}

	//drop node on bottom
	AI_AddNode( borigin, ( NODEFLAGS_LADDER|NODEFLAGS_FLOAT ) );

	if( torigin[2] - borigin[2] < NODE_DENSITY )
		return;

	//make subdivisions and add nodes in between
	step = NODE_DENSITY*0.8;
	VectorCopy( borigin, droporigin );
	droporigin[2] += step;
	while( droporigin[2] < torigin[2] - 32 )
	{
		AI_AddNode( droporigin, ( NODEFLAGS_LADDER|NODEFLAGS_FLOAT ) );
		droporigin[2] += step;
	}
}


//==========================================
// AI_CheckForLadder
// Check for adding ladder nodes
//==========================================
static qboolean AI_CheckForLadder( edict_t *self )
{
	int closest_node;

	// If there is a ladder and we are moving up, see if we should add a ladder node
	if( self->velocity[2] < 5 )
		return qfalse;

	if( !AI_IsLadder( self->s.origin, self->r.client->ps.viewangles, self->r.mins, self->r.maxs, self ) )
		return qfalse;

	// If there is already a ladder node in here we've already done this ladder
	closest_node = AI_FindClosestReachableNode( self->s.origin, self, NODE_DENSITY, NODEFLAGS_LADDER );
	if( closest_node != -1 )
		return qfalse;

	//proceed:
	AI_DropLadderNodes( self );
	return qtrue;
}


//==========================================
// AI_TouchWater
// Capture when players touches water for mapping purposes.
//==========================================
static void AI_WaterJumpNode( void )
{
	int closest_node;
	vec3_t waterorigin;
	trace_t	trace;
	edict_t	ent;

	//don't drop if player is riding elevator or climbing a ladder
	if( player.ent->groundentity && player.ent->groundentity != world )
	{
		if( player.ent->groundentity->classname )
		{
			if( !strcmp( player.ent->groundentity->classname, "func_plat" )
			   || !strcmp( player.ent->groundentity->classname, "trigger_push" )
			   || !strcmp( player.ent->groundentity->classname, "func_train" )
			   || !strcmp( player.ent->groundentity->classname, "func_rotate" )
			   || !strcmp( player.ent->groundentity->classname, "func_bob" )
			   || !strcmp( player.ent->groundentity->classname, "func_door" ) )
				return;
		}
	}
	if( AI_IsLadder( player.ent->s.origin, player.ent->r.client->ps.viewangles, player.ent->r.mins, player.ent->r.maxs, player.ent ) )
		return;

	VectorCopy( player.ent->s.origin, waterorigin );

	//move the origin to water limit
	if( G_PointContents( waterorigin ) & MASK_WATER )
	{
		//reverse
		G_Trace( &trace, waterorigin,
		         //trace = gi.trace( waterorigin,
		         vec3_origin,
		         vec3_origin,
		         tv( waterorigin[0], waterorigin[1], waterorigin[2] + NODE_DENSITY*2 ),
		         player.ent,
		         MASK_ALL );

		VectorCopy( trace.endpos, waterorigin );
		if( trace.contents & MASK_WATER )
			return;
	}

	//find water limit
	G_Trace( &trace, waterorigin,
	         //trace = gi.trace( waterorigin,
	         vec3_origin,
	         vec3_origin,
	         tv( waterorigin[0], waterorigin[1], waterorigin[2] - NODE_DENSITY*2 ),
	         player.ent,
	         MASK_WATER );

	if( trace.fraction == 1.0 )
		return;
	else
		VectorCopy( trace.endpos, waterorigin );

	//tmp test (should just move 1 downwards)
	if( !( G_PointContents( waterorigin ) & MASK_WATER ) )
	{
		int k = 0;
		do
		{
			waterorigin[2]--;
			k++;
		}
		while( !( G_PointContents( waterorigin ) & MASK_WATER ) );
	}

	ent = *player.ent;
	VectorCopy( waterorigin, ent.s.origin );

	// Look for the closest node of type water
	closest_node = AI_FindClosestReachableNode( ent.s.origin, &ent, 32, NODEFLAGS_WATER );
	if( closest_node == -1 ) // we need to drop a node
	{
		closest_node = AI_AddNode( waterorigin, ( NODEFLAGS_WATER|NODEFLAGS_FLOAT ) );

		// Add an edge
		AI_UpdateNodeEdge( player.last_node, closest_node );
		player.last_node = closest_node;

	}
	else
	{

		AI_UpdateNodeEdge( player.last_node, closest_node );
		player.last_node = closest_node; // zero out so other nodes will not be linked
	}
}


//==========================================
// AI_PathMap
// This routine is called to hook in the pathing code and sets
// the current node if valid.
//==========================================

#define NODE_UPDATE_DELAY   100;
static void AI_PathMap( void )
{
	static unsigned int last_update = 0;
	int closest_node;

	//DROP WATER JUMP NODE (not limited by delayed updates)
	if( !player.ent->is_swim && player.last_node != -1
	    && player.ent->is_swim != player.ent->was_swim )
	{
		AI_WaterJumpNode();
		last_update = level.time + NODE_UPDATE_DELAY; // slow down updates a bit
		return;
	}

	if( level.time < last_update )
		return;

	last_update = level.time + NODE_UPDATE_DELAY; // slow down updates a bit

	//don't drop nodes when riding movers
	if( player.ent->groundentity && player.ent->groundentity != world )
	{
		if( player.ent->groundentity->classname )
		{
			if( !strcmp( player.ent->groundentity->classname, "func_plat" )
			   || !strcmp( player.ent->groundentity->classname, "trigger_push" )
			   || !strcmp( player.ent->groundentity->classname, "func_train" )
			   || !strcmp( player.ent->groundentity->classname, "func_rotate" )
			   || !strcmp( player.ent->groundentity->classname, "func_bob" )
			   || !strcmp( player.ent->groundentity->classname, "func_door" ) )
				return;
		}
	}

	// Special check for ladder nodes
	if( AI_CheckForLadder( player.ent ) )
		return;

	// Not on ground, and not in the water, so bail (deeper check by using a splitmodels function)
	if( !player.ent->is_step )
	{
		if( !player.ent->is_swim )
		{
			player.was_falling = qtrue;
			return;
		}
		else if( player.ent->is_swim )
			player.was_falling = qfalse;
	}

	//player just touched the ground
	if( player.was_falling == qtrue )
	{
		if( !player.ent->groundentity )  //not until it REALLY touches ground
			return;

		//normal nodes

		//check for duplicates (prevent adding too many)
		closest_node = AI_FindClosestReachableNode( player.ent->s.origin, player.ent, 64, NODE_ALL );

		//otherwise, add a new node
		if( closest_node == NODE_INVALID )
			closest_node = AI_AddNode( player.ent->s.origin, 0 ); //no flags = normal movement node

		// Now add link
		if( player.last_node != -1 && closest_node != -1 )
			AI_UpdateNodeEdge( player.last_node, closest_node );

		if( closest_node != -1 )
			player.last_node = closest_node; // set visited to last

		player.was_falling = qfalse;
		return;
	}


	//jal: I'm not sure of not having nodes in lava/slime
	//being actually a good idea. When the bots incidentally
	//fall inside it they don't know how to get out
	// Lava/Slime


	// Iterate through all nodes to make sure far enough apart
	closest_node = AI_FindClosestReachableNode( player.ent->s.origin, player.ent, NODE_DENSITY, NODE_ALL );

	// Add Nodes as needed
	if( closest_node == NODE_INVALID )
	{
		// Add nodes in the water as needed
		if( player.ent->is_swim )
			closest_node = AI_AddNode( player.ent->s.origin, ( NODEFLAGS_WATER|NODEFLAGS_FLOAT ) );
		else
			closest_node = AI_AddNode( player.ent->s.origin, 0 );

		// Now add link
		if( player.last_node != -1 )
			AI_UpdateNodeEdge( player.last_node, closest_node );
	}
	else if( closest_node != player.last_node && player.last_node != NODE_INVALID )
		AI_UpdateNodeEdge( player.last_node, closest_node );

	if( closest_node != -1 )
		player.last_node = closest_node; // set visited to last
}


//==========================================
// AITools_AddBotRoamNode_Cmd
// Drop a bot roam node by user console
//==========================================
void AITools_AddBotRoamNode_Cmd( void )
{
//	int node;

	if( !nav.editmode || nav.loaded )
	{
		Com_Printf( "       : Can't Create bot roam nodes when not in editing mode.\n" );
		return;
	}
/*
	node = AI_AddNode( player.ent->s.origin, ( AI_FlagsForNode( player.ent->s.origin, player.ent ) | NODEFLAGS_BOTROAM ) );

	nodes[node].flags |= NODEFLAGS_BOTROAM;
	nav.broams[nav.num_broams].weight = 0.3f;
	nav.broams[nav.num_broams].node = node;
	nav.num_broams++;
*/
}

//==========================================
// AITools_AddNode_Cmd
// Drop a node by user console
//==========================================
void AITools_AddNode_Cmd( void )
{
	if( !nav.editmode || nav.loaded )
	{
		Com_Printf( "       : Can't Add nodes when not being in editing mode.\n" );
		return;
	}

	AI_AddNode( player.ent->s.origin, AI_FlagsForNode( player.ent->s.origin, player.ent ) );
}

//==========================================
// AITools_DropNodes
// Clients try to create new nodes while walking the map
//==========================================
void AITools_DropNodes( edict_t *ent )
{
	if( nav.loaded || !nav.editmode )
		return;

	AI_CategorizePosition( ent );
	player.ent = ent;
	AI_PathMap();
}


//==========================================
//
//==========================================


void AITools_InitEditnodes( void )
{
	if( nav.editmode )
	{
		Com_Printf( "       : You are already in editing mode.\n" );
		return;
	}

	if( nav.loaded )
	{
		AI_InitNavigationData( qtrue );

		nav.serverNodesStart = 0;

		// clear up the plinks
		memset( pLinks, 0, sizeof( nav_plink_t ) * MAX_NODES );
	}

	Com_Printf( "       : EDIT MODE: ON\n" );
	nav.editmode = qtrue;
}

void AITools_InitMakenodes( void )
{
	if( nav.editmode )
	{
		Com_Printf( "       : Your are already in editing mode.\n" );
		return;
	}

	if( nav.loaded ) 
	{
		AI_InitNavigationData( qtrue );

		// clear up nodes and plinks
		nav.num_nodes = nav.serverNodesStart = 0;
		memset( nodes, 0, sizeof( nav_node_t ) * MAX_NODES );
		memset( pLinks, 0, sizeof( nav_plink_t ) * MAX_NODES );
	}

	Com_Printf( "       : EDIT MODE: ON\n" );
	nav.editmode = qtrue;
}
