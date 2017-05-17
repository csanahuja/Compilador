/*************************************************************************** 
Dissassembler 
Author: Jordi Planes
***************************************************************************/ 

#include <stdlib.h>
#include <string.h>

#include "list.h"
#include "SM.h"

struct IntNode* int_add( struct IntNode* int_list, int address ) {
	struct IntNode* node = malloc( sizeof( struct IntNode ) );
	node -> address = address;
	node -> next = int_list;
	return node;
}

struct SymNode* sym_list = NULL;

void sym_add_address( char* name, int address ) {
	struct SymNode* current = sym_list;
	while ( current != NULL &&  strcmp( current -> name, name ) != 0 ) {
		current = current -> next;
	}
	if ( current == NULL ) {
		struct SymNode* node = malloc( sizeof( struct SymNode ) );
		node -> name = name;
		node -> address = address;
		node -> backpatches = NULL;
		node -> next = sym_list;
		sym_list = node;
	} else {
		struct IntNode* backpatches = current -> backpatches;
		current -> address = address;
		while( backpatches != NULL ) {
			code[ backpatches->address ].arg = address;
			backpatches = backpatches->next;
		}
	}
}

void sym_add_backpatch( char* name, int backpatch ) {
	struct SymNode* current = sym_list;

	while ( current != NULL ) {
		if ( strcmp( current -> name, name ) == 0 ) {
                   break;
		}
		current = current -> next;
	}
        if ( current == NULL ) {
	   sym_add_address( name, -1);
           current = sym_list;
        }
	current -> backpatches = int_add( current -> backpatches, backpatch );
}

int sym_get_address( char* name ) {
	struct SymNode* current = sym_list;

	while ( current != NULL ) {
		if ( strcmp( current -> name, name ) == 0 ) {
			return current -> address;
		}
		current = current -> next;
 	}
 	return LABEL_NOT_FOUND;
}

struct IntNode* sym_get_backpatches( char* name ) {
	struct SymNode* current = sym_list;
	struct IntNode* result = NULL;

	while ( current != NULL ) {
		if ( strcmp( current -> name, name ) == 0 ) {
			result = current -> backpatches;
		}
		current = current -> next;
 	}
 	return result;
}
