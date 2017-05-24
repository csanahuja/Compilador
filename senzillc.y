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
int start_function;
char *scope = "GLOBAL";

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
Scope related functions
-------------------------------------------------------------------------*/ 

struct func 
{ 
    char *scope; 
    int start_function;
    int num_params;  
}; 


void installFunction(struct func f; char* scope) {
    f = malloc(sizeof(struct func));
    f->scope = strdup(scope);
    f->start_fuction = 0;
    f->num_params = 0;
}

void openScope ( char *new_scope) {
    scope = strdup(new_scope);
}

void closeScope (){
    scope = strdup("GLOBAL");
}

void installParameter(){

}

/*------------------------------------------------------------------------- 
Install identifier & check if previously defined. 
-------------------------------------------------------------------------*/ 
void install ( char *sym_name, int length) 
{ 
  symrec *s = getsym (sym_name); 
  if (s == 0) 
    s = putsym (sym_name, length, scope); 
  else { 
    char message[ 100 ];
    sprintf( message, "%s is already defined\n", sym_name ); 
    yyerror( message );
  } 
}

/*------------------------------------------------------------------------- 
If identifier is defined, generate code 
-------------------------------------------------------------------------*/ 
int context_check( char *sym_name) 
{ 
  symrec *identifier = getsym( sym_name );
  return identifier->offset;
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
   struct func 
};

/*========================================================================= 
TOKENS 
=========================================================================*/ 
%start program 
%token <intval> NUMBER /* Simple integer */ 
%token <strval> STR
%token <id> IDENTIFIER /* Simple identifier */ 
%token <lbls> IF WHILE /* For backpatching labels */ 
%token MAIN DEF
%token SKIP THEN ELSE FI DO END 
%token INTEGER READ WRITE LET IN 
%token EQUAL OPEN CLOSE

%type <func> def

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
        | MAIN OPEN { gen_code( DATA, data_location()-1);} commands
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

   | DEF IDENTIFIER { installFunction($1, $2); install($2, 1); gen_code( LD_INT, gen_label()+3); gen_code( STORE, context_check($2));
                      $1->start_function = gen_label(); gen_code(GOTO, 0);}
    '(' parameters ')' OPEN commands CLOSE { gen_code( RET, 0); back_patch( $1->start_function, GOTO, gen_label());closeScope();}

   | IDENTIFIER '(' values ')' { gen_code(LD_VAR, context_check($1)); gen_code( CALL, 0);}

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

id_seq_int : IDENTIFIER { install( $1, 1 );}
    | IDENTIFIER '[' NUMBER ']' { install( $1, $3); }
    | id_seq_int ',' IDENTIFIER  { install( $3, 1 );} 
    | id_seq_int ',' IDENTIFIER '[' NUMBER ']' { install( $3, $5); }
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

param : INTEGER IDENTIFIER {install_parameter( $1, 1 );}
;

values : /* empty */
       | value
       | values ',' value

value: exp {gen_code( STORE_SUBS, context_check($1));}
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
  printf("Senzill Compiler\n");
  yyparse (); 
  printf ( "Parse Completed\n" ); 
  if ( errors == 0 ) 
    { 
      //print_code (); 
      //fetch_execute_cycle();
      write_bytecode( argv[2] );
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


