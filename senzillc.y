%{
/*************************************************************************
Compiler for the Simple language
Author: Anthony A. Aaby
Modified by: Jordi Planes
Extended by: Cristian Sanahuja
***************************************************************************/
/*=========================================================================
C Libraries, Symbol Table, Code Generator & other C code
=========================================================================*/
#include <stdio.h> /* For I/O */
#include <stdlib.h> /* For malloc here and in symbol table */
#include <string.h> /* For strcmp in symbol table */
#include "ST.h" /* Symbol Table */
#include "SM.h" /* Stack Machine */
#include "CG.h" /* Code Generator */

#define YYDEBUG 1 /* For Debugging */

int yyerror(char *);
int yylex();

int errors; /* Error Count */

/* Functions variables */
int num_params = 0;
int position = 0;
int scope;
char* active_function = NULL;


/*-------------------------------------------------------------------------
The following support backpatching
-------------------------------------------------------------------------*/
struct lbs /* Labels for data, if and while */
{
  int for_goto;
  int for_jmp_false;
};

struct lbs * newlblrec() /* Allocate space for the labels */
{
   return (struct lbs *) malloc(sizeof(struct lbs));
}

/*-------------------------------------------------------------------------
Install identifier & check if previously defined.
-------------------------------------------------------------------------*/
void install ( char *sym_name, int length, int position)
{
  symrec *s = getsymOnCurrentScope (sym_name);
  if (s == 0){
    s = putsym (sym_name, length, position);
  }else {
    char message[ 100 ];
    sprintf( message, "ALREADY DEFINED => Variable: %s in the current Scope", sym_name);
    yyerror( message );
  }
}

/*-------------------------------------------------------------------------
If identifier is defined, generate code
-------------------------------------------------------------------------*/
int context_check( char *sym_name)
{
  symrec *identifier = getsym( sym_name, getCurrentScope(), 0 );
  if (identifier == 0){
    char message[ 100 ];
    if (active_function == 0)
      sprintf( message, "NOT DEFINED => Variable: %s in the GLOBAL Scope", sym_name);
    else
      sprintf( message, "NOT DEFINED => Variable: %s in the %s Scope", sym_name, active_function);
    yyerror( message );
    exit(-1);
  }
  return identifier->offset;
}

int context_check_param()
{
  if (position > num_params){
    char message[ 100 ];
    sprintf( message, "EXCEED ARGUMENTS => Function: %s requires: %i arguments", active_function, num_params);
    yyerror( message );
    exit(-1);
  }
  symrec *identifier = getsymArgument(position, scope);
  if (identifier == 0){
    char message[ 100 ];
    sprintf( message, "CANNOT GET ARGUMENT => Function: %s position: %i", active_function, position);
    yyerror( message );
    exit(-1);
  }
  return identifier->offset;
}

/*-------------------------------------------------------------------------
FUNCTIONS RELATED METHODS
-------------------------------------------------------------------------*/

/* Function to install functions, we install the var and save the address, set
   scope and return where the function stars
*/
int installFunction(char * sym_name){
  int start_function;
  install(sym_name, 1, 0);
  pushScope();
  gen_code( LD_INT, gen_label()+3);
  gen_code( STORE, context_check(sym_name));
  start_function = gen_label();
  gen_code(GOTO, 0);
  return start_function;
}

/* Function to close scope and do a backpath of the goto to where the function
   definition ends
*/
void endFunction(int start_function){
  gen_code( RET, 0);
  back_patch( start_function, GOTO, gen_label());
  popScope();
}

/* Function to save the scope of function, number of params and set position
   back to 0 to the next function
*/
void saveFunctionValues(char *sym_name, int inner_scope){
  symrec *identifier = getsym( sym_name, getCurrentScope(), 0 );
  identifier->length = position;
  identifier->inner_scope = inner_scope;
  position=0;
}

/* Function to load the number of arguments, its scope and set this function to
   the active_function. If function not found the program will exit
*/
void loadFunctionValues(char *sym_name){
  symrec *identifier = getsym( sym_name, getCurrentScope(), 0 );
  if(identifier == 0){
    char message[ 100 ];
    if (active_function == 0)
      sprintf( message, "NOT DEFINED => Variable: %s in the GLOBAL Scope", sym_name);
    else
      sprintf( message, "NOT DEFINED => Variable: %s in the %s Scope", sym_name, active_function);
    yyerror( message );
    exit(1);
  }
  num_params = identifier->length;
  scope = identifier->inner_scope;
  active_function = strdup(sym_name);
}

/* Function to unload the values of the active function */
void unloadFunctionValues(){
  if (position < num_params){
    char message[ 100 ];
    sprintf( message, "NOT ENOUGH ARGUMENTS => Function: %s requires %i arguments", active_function, num_params);
    yyerror( message );
    exit(-1);
  }
  active_function=NULL;
  position=0;
  num_params=0;
}

/* Function to call a function*/
void callFunction(char *sym_name){
  unloadFunctionValues();
  gen_code(LD_VAR, context_check(sym_name));
  gen_code( CALL, 0);
}


/*=========================================================================
SEMANTIC RECORDS
=========================================================================*/
%}

%union /* semrec - The Semantic Records */
 {
   int intval; /* Integer values */
   char *strval; /* String values */
   char *id; /* Identifiers */
   struct lbs *lbls; /* For backpatching */
   int start; /* For functions */
};

/*=========================================================================
TOKENS
=========================================================================*/
%start program
%token <intval> NUMBER /* Simple integer */
%token <strval> STR
%token <id> IDENTIFIER /* Simple identifier */
%token <lbls> IF WHILE /* For backpatching labels */
%token MAIN
%token <start> DEF
%token SKIP THEN ELSE FI DO END
%token INTEGER READ WRITE LET IN
%token EQUAL OPEN CLOSE

/*=========================================================================
OPERATOR PRECEDENCE
=========================================================================*/
%left '-' '+'
%left '*' '/'
%right '^'

/*=========================================================================
GRAMMAR RULES for the Simple language
=========================================================================*/

%%

program : /* empty */
        | MAIN OPEN { gen_code( DATA, data_location()-1); initScopeStack();} commands
          CLOSE { back_patch( 0, DATA, data_location()-1) ; gen_code( HALT, 0 ); YYACCEPT; }
;

/*=========================================================================
COMMANDS
=========================================================================*/

commands : /* empty */
    | commands command ';'
;

command : SKIP
   | INTEGER id_seq_int

   | IDENTIFIER '=' exp { gen_code( STORE, context_check($1)); }
   | IDENTIFIER '[' exp ']' '=' exp { gen_code( STORE_SUBS, context_check($1)); }

   | DEF IDENTIFIER { $1 = installFunction($2);}
    '(' parameters ')' {saveFunctionValues($2, getCurrentScope());}
    OPEN commands CLOSE { endFunction($1);}

   | IDENTIFIER {loadFunctionValues($1);}
    '(' values ')' { callFunction($1);}

   | READ IDENTIFIER { gen_code( READ_INT, context_check( $2 ) ); }
   | WRITE exp { gen_code( WRITE_INT, 0 ); }

   | IF bool_exp { $1 = (struct lbs *) newlblrec(); $1->for_jmp_false = reserve_loc(); }
   THEN commands { $1->for_goto = reserve_loc(); } ELSE {
     back_patch( $1->for_jmp_false, JMP_FALSE, gen_label() );
   } commands FI { back_patch( $1->for_goto, GOTO, gen_label() ); }

   | WHILE { $1 = (struct lbs *) newlblrec(); $1->for_goto = gen_label(); }
   bool_exp { $1->for_jmp_false = reserve_loc(); } DO commands END { gen_code( GOTO, $1->for_goto );
   back_patch( $1->for_jmp_false, JMP_FALSE, gen_label() ); }
;

id_seq_int : IDENTIFIER { install( $1, 1, 0 );}
    | IDENTIFIER '[' NUMBER ']' { install( $1, $3, 0); }
    | id_seq_int ',' IDENTIFIER  { install( $3, 1, 0 );}
    | id_seq_int ',' IDENTIFIER '[' NUMBER ']' { install( $3, $5, 0); }
;



bool_exp : exp '<' exp { gen_code( LT, 0 ); }
   | exp EQUAL exp { gen_code( EQ, 0 ); }
   | exp '>' exp { gen_code( GT, 0 ); }
;

exp : NUMBER { gen_code( LD_INT, $1 ); }
   | IDENTIFIER { gen_code( LD_VAR, context_check( $1 ) ); }
   | IDENTIFIER '[' exp ']' { gen_code(LD_SUBS, context_check( $1 )); }
   | exp '+' exp { gen_code( ADD, 0 ); }
   | exp '-' exp { gen_code( SUB, 0 ); }
   | exp '*' exp { gen_code( MULT, 0 ); }
   | exp '/' exp { gen_code( DIV, 0 ); }
   | exp '^' exp { gen_code( PWR, 0 ); }
   | '(' exp ')'
;

parameters : /* empty */
           | param
           | parameters ',' param
;

param : INTEGER IDENTIFIER {position++; install( $2, 1, position );}
;

values : /* empty */
       | value
       | values ',' value

value: exp { position++; gen_code( STORE, context_check_param()); }
;

/*=========================================================================
FUNCTIONS
=========================================================================*/



%%

extern struct instruction code[ MAX_MEMORY ];

/*=========================================================================
MAIN
=========================================================================*/
int main( int argc, char *argv[] )
{
  extern FILE *yyin;
  if ( argc < 3 ) {
    printf("usage <input-file> <output-file>\n");
    return -1;
  }
  yyin = fopen( argv[1], "r" );
  /*yydebug = 1;*/
  errors = 0;
  printf("Starting Compilation\n");
  yyparse ();
  if ( errors == 0 ){
      printf ( "Compilation succeed\n" );
      //print_code ();
      //fetch_execute_cycle();
      write_bytecode( argv[2] );
  } else {
    printf ( "Compilation failed\n" );
  }
  return 0;
}

/*=========================================================================
YYERROR
=========================================================================*/
int yyerror ( char *s ) /* Called by yyparse on error */
{
  errors++;
  printf ("%s\n", s);
  return 0;
}
/**************************** End Grammar File ***************************/
