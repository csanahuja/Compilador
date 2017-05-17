/***************************************************************************
Assembler
Author: Jordi Planes
***************************************************************************/

%option nounput
%option noinput

%{
#include <stdio.h>
#include "SM.h"
#include "ST.h"
#include "CG.h"

#include "list.h"

int line_num = 1;

void print_error( char * message ) {
   printf("error %d : %s\n", line_num, message );
}

// Command creation

int command;

void create_command( char * text ) {
   int i;
   for( i = 0; op_name[ i ] != NULL; i++ ) {
      if( strcmp( text, op_name[ i ] ) == 0 ) {
         command = i; return;
      }
   }
   char message[ 50 ];
   sprintf( message, "Command %s not found\n", text );
   print_error( message );
   exit(-1);
}

%}

Identifier [a-zA-Z][a-zA-Z0-9]
Command [a-z_]+
Integer [0-9]+

%x PARAM COMMENT

%%

"#"                   { BEGIN( COMMENT ); }
<COMMENT>\n           { BEGIN(INITIAL); }
<COMMENT>.            {}
{Identifier}":"       { sym_add_address( strndup( yytext, yyleng-1 ), gen_label() ); }
{Command}             { create_command( yytext ); BEGIN( PARAM ); }
<PARAM>{Integer}      { gen_code( command, atoi( yytext ) ); BEGIN( INITIAL ); }
<PARAM>{Identifier}   { int address = sym_get_address( yytext );
                        gen_code( command, address );
                        if ( address == LABEL_NOT_FOUND )
                          sym_add_backpatch( strdup( yytext ), gen_label()-1 );
                        BEGIN( INITIAL );
                      }
<INITIAL,PARAM>[ ]  ;
<INITIAL,PARAM>\n   line_num++;

%%

int yywrap(void){
   return 1;
}

int main( int argc, char *argv[] ) {
   if ( argc > 1 )
      yyin = fopen( argv[1], "r" );
   yylex();
   if ( argc > 2 )
      write_bytecode( argv[2] );
   printf("Finished\n");
   return 0;
}
