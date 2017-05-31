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
extern int num_lines;

/* Functions variables */
int num_params = 0;
int position = 0;
int scope;
char* active_function = NULL;

/* Function to initialize data structures used */
void init(){
  initScopeStack();
  initBPStack();
  initReferenceStack();
}

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
void install ( char *sym_name, int length, int position, Type type)
{
  symrec *s = getsymOnCurrentScope (sym_name);
  if (s == 0){
    s = putsym (sym_name, length, position, type);
  }else {
    char message[ 100 ];
    sprintf( message, "ALREADY DEFINED => Variable: %s in the current Scope", sym_name);
    yyerror( message );
  }
}

/*-------------------------------------------------------------------------
If identifier is defined, generate code
-------------------------------------------------------------------------*/

/* Function to get a variable starting from the current scope */
symrec * getVar(char* sym_name){
  symrec *identifier = getsym( sym_name, getCurrentScope(), 0 );
  if (identifier == 0){
    char message[ 100 ];

    char *name = getScopeName(getCurrentScope());
    if (name == 0)
      sprintf( message, "NOT DEFINED => Variable: %s in the GLOBAL Scope", sym_name);
    else
      sprintf( message, "NOT DEFINED => Variable: %s in the %s Scope", sym_name, name);
    yyerror( message );
    exit(-1);
  }
  return identifier;
}

/* Function to get variable on a given scope, note that the function calls the
   same function as getVar which internally searches in the lower scope and if
   the variable is not found it searches onto higher scope and so on.
   However we call this function on a point of execution where the scopes are
   not anyymore on the stack o it is only intended to get a variable on a scope*/
symrec * getVarOnScope(char* sym_name, int scope){
  symrec *identifier = getsym( sym_name, scope, 0 );
  if (identifier == 0){
    char message[ 100 ];
    if (active_function == 0)
      sprintf( message, "NOT DEFINED => Variable: %s in the GLOBAL Scope", sym_name);
    else
      sprintf( message, "NOT DEFINED => Variable: %s in the %s Scope", sym_name, active_function);
    yyerror( message );
    exit(-1);
  }
  return identifier;
}

/* This function gives the offset of a variable */
int context_check( char *sym_name)
{
  symrec *identifier = getVar(sym_name);
  return identifier->offset;
}

/* This function returns a variable in the active scope and active position.
   Function used to get the diferent arguments of a function
*/
symrec * context_check_param()
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
  return identifier;
}
/*-------------------------------------------------------------------------
FUNCTIONS RELATED METHODS
-------------------------------------------------------------------------*/

/* Function to install functions, we install the var and save the address, set
   scope and return where the function stars
*/
int installFunction(char * sym_name){
  int start_function;
  install(sym_name, 1, 0, FUNCTION);
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

  active_function=NULL;
  position=0;
  num_params=0;
}

/* Checks if enough arguments */
void checkArguments(){
  if (position < num_params){
    char message[ 100 ];
    sprintf( message, "NOT ENOUGH ARGUMENTS => Function: %s requires %i arguments", active_function, num_params);
    yyerror( message );
    exit(-1);
  }
}

/* Function to call a function*/
void callFunction(char *sym_name){
  checkArguments();
  unloadFunctionValues();
  gen_code(LD_VAR, context_check(sym_name));
  gen_code( CALL, 0);
}

/* Function to create a variable on the symbol table without assigning any
   offset nor calling data_location(). Intended to later be a reference to an
   already existing var
*/
void installReference( char *sym_name, int position, Type type)
{
  symrec *s = getsymOnCurrentScope (sym_name);
  if (s == 0){
    s = create_reference (sym_name, position, type);
  }else {
    char message[ 100 ];
    sprintf( message, "ALREADY DEFINED => Variable: %s in the current Scope", sym_name);
    yyerror( message );
  }
}

/* Function to assign int to a variable passed by parameter
*/
void loadInt(){
  symrec * var = context_check_param();
  if (var->type == INT)
    gen_code( STORE, var->offset);
  if (var->type == ARRAY){
    char message[ 100 ];
    sprintf( message, "EXPECTED ARRAY FOUND INT => Argument number: %i", position);
    yyerror( message );
    exit(-1);
  }
}

/* Function to load variable if type of argument is INT we do the same as in
   the function loadInt. If the argument is an array we push a Reference to the
   Stack Reference.
   This function is intended to be able to assign to an array either an array
   or variable (consider a variable as array of 1 position)
*/
void loadVariable(char *sym_name){
  symrec * var = context_check_param();
  if (var->type == INT){
    gen_code( LD_VAR, context_check( sym_name ));
    gen_code( STORE, var->offset);
  }
  if (var->type == ARRAY){
    symrec *argument = getVar(sym_name);
    r_struct* rf = malloc(sizeof(r_struct));
    rf->origin_scope = argument->scope;
    rf->origin_var = argument->name;
    rf->source_var = var->name;
    rf->source_scope = var->scope;
    pushReference(rf);
  }
}

/* We push a backpatch label. We only do that for to operations. STORE_SUBS and
  LD_SUBS. This is because when we call context_check of an array inside a function
  that we pass by parameter we dont have the correct offset untill later and
  we have to do a backpatch once we have it correctly.
  Note all arrays passed by parameter get offset 0 at start
*/
void addBP(char *sym_name, int code){
  bp_struct* bp = malloc(sizeof(bp_struct));
  bp->name = strdup(sym_name);
  bp->operation = code;
  bp->label = gen_label();
  bp->scope = getCurrentScope();
  pushBP(bp);
}

/* Once we end the program we are ready to redefine the offsets and lengths of
   arrays references. These are the arrays passed by parameter which refer to
   other arrays with some values. We copy from original to source the offset so
   they become a pointer to the same var
*/
void setReferences(){
  r_struct* rf = malloc(sizeof(r_struct));
  int i;
  for(i = getReferencesSize(); i > 0; i--){
    rf = popReference();
    symrec *origin = getVarOnScope(rf->origin_var,rf->origin_scope);
    symrec *source = getVarOnScope(rf->source_var,rf->source_scope);
    source->offset = origin->offset;
    source->length = origin->length;
  }
}

/* Once we set the correct offset to the array references we are ready to do
  all backpatches to the STORE_SUBS and LD_SUBS so we have correct instructions
*/
void makeBackpatch(){
  bp_struct* bp = malloc(sizeof(bp_struct));
  int i;
  for (i = getBPSize(); i > 0;i--){
    bp = popBP();
    symrec *var = getVarOnScope(bp->name,bp->scope);
    if (bp->operation == 0)
      back_patch( bp->label, STORE_SUBS, var->offset);
    if (bp->operation == 1)
      back_patch( bp->label, LD_SUBS, var->offset);
  }
}

/* Function to make references work! */
void enableReferences(){
  setReferences();
  makeBackpatch();
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
        | MAIN OPEN { gen_code( DATA, data_location()-1); init();} commands
          CLOSE { back_patch( 0, DATA, data_location()-1) ; gen_code( HALT, 0 );
                  enableReferences(); YYACCEPT; }
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
   | IDENTIFIER '[' exp ']' '=' exp { addBP($1, 0);gen_code( STORE_SUBS, context_check($1));}

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

id_seq_int : IDENTIFIER { install( $1, 1, 0, INT );}
    | IDENTIFIER '[' NUMBER ']' { install( $1, $3, 0, ARRAY); }
    | id_seq_int ',' IDENTIFIER  { install( $3, 1, 0, INT );}
    | id_seq_int ',' IDENTIFIER '[' NUMBER ']' { install( $3, $5, 0, ARRAY); }
;



bool_exp : exp '<' exp { gen_code( LT, 0 ); }
   | exp EQUAL exp { gen_code( EQ, 0 ); }
   | exp '>' exp { gen_code( GT, 0 ); }
;

exp : NUMBER { gen_code( LD_INT, $1 ); }
   | IDENTIFIER { gen_code( LD_VAR, context_check( $1 ) );}
   | IDENTIFIER '[' exp ']' { addBP($1, 1); gen_code(LD_SUBS, context_check( $1 )); }
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

param : INTEGER IDENTIFIER {position++; install( $2, 1, position, INT);}
      | INTEGER '[' ']' IDENTIFIER {position++; installReference($4, position, ARRAY);}
;

values : /* empty */
       | value
       | values ',' value

value: exp_args { position++; loadInt(); }
     | IDENTIFIER { position++; loadVariable($1);}
;

exp_args : NUMBER { gen_code( LD_INT, $1 ); }
   | IDENTIFIER '[' exp_args ']' { gen_code(LD_SUBS, context_check( $1 )); }
   | exp_args '+' exp_args { gen_code( ADD, 0 ); }
   | exp_args '-' exp_args { gen_code( SUB, 0 ); }
   | exp_args '*' exp_args { gen_code( MULT, 0 ); }
   | exp_args '/' exp_args { gen_code( DIV, 0 ); }
   | exp_args '^' exp_args { gen_code( PWR, 0 ); }
   | '(' exp_args ')'
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
  printf("*** STARTING COMPILATION\n");
  yyparse ();
  if ( errors == 0 ){
      printf ( "*** COMPILATION SUCCEED\n" );
      printf ( "==> Gimeno Exception triggered => Compilation is not enough!\n");
      printf ( "==> Refactor immediately the code! \n");
      //print_code ();
      //fetch_execute_cycle();
      write_bytecode( argv[2] );
  } else {
    printf ( "*** COMPILATION FAILED!\n" );
    printf ( "==> StackOverFlow Exception triggered => Visit it! \n");
    printf ( "==> Or give yourself a break! \n");
  }
  return 0;
}

/*=========================================================================
YYERROR
=========================================================================*/
int yyerror ( char *s ) /* Called by yyparse on error */
{
  errors++;
  printf ("*** %s >>> AT LINE %i\n", s, num_lines);
  if (strstr(s,"NOT ENOUGH ARGUMENTS"))
    printf ("==> Starvation Exception trigger => The functions needs to be feed!\n");
  if (strstr(s,"EXCEED ARGUMENTS"))
    printf ("==> Indigestion Exception triggered => The functions its overbooked!\n");
  if (strstr(s,"NOT DEFINED")){
    printf ("==> Random Generation Exception triggered => No this program is not \n");
    printf ("==> generating random things. Instead define them! \n");
  }
  if (strstr(s,"ALREADY DEFINED"))
    printf ("==> Deja Vu Exception triggered => That have been defined before!  \n");
  if (strstr(s,"EXPECTED ARRAY FOUND INT"))
    printf ("==> T.Alzinet Exception triggered => El casament de paràmetres!  \n");
  return 0;
}
/**************************** End Grammar File ***************************/
