/*************************************************************************** 
Scanner for the Simple language 
Author: Anthony A. Aaby
Modified by: Jordi Planes
Extended by: Cristian Sanahuja
***************************************************************************/ 

%x incl multiline_comment single_comment
%option nounput
%option noinput

%{ 
/*========================================================================= 
C-libraries and Token definitions 
=========================================================================*/ 
#include <string.h> /* for strdup */ 
#include <stdlib.h> /* for atoi */ 
#include "senzillc.tab.h" /* for token definitions and yylval */ 

/*Include Related Info*/
#define MAX_INCLUDE_DEPTH 10
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ptr = 0;

%} 

/*========================================================================= 
TOKEN Definitions 
=========================================================================*/ 
DIGIT [0-9] 
ID [a-z][a-z0-9]* 

/*========================================================================= 
REGULAR EXPRESSIONS defining the tokens for the Simple language 
=========================================================================*/ 


%%

import                      BEGIN(incl);
<incl>[ \t]*                /* eat the whitespaces */                                       
<incl>[^ \t\n]+             { /* got the include file name */
                            if ( include_stack_ptr >= MAX_INCLUDE_DEPTH ){
                                fprintf( stderr, "Includes nested too deeply \n" );
                                exit( 1 );
                            }
                            include_stack[include_stack_ptr++] =
                            YY_CURRENT_BUFFER;
                            yyin = fopen( yytext, "r" );
                            if ( ! yyin ){
                                printf("File not found\n");
                                exit(1);
                                }
                            }
<incl>\n                   {yy_switch_to_buffer(yy_create_buffer( yyin, YY_BUF_SIZE ) );
                            BEGIN(0);}
<<EOF>>                     {if ( --include_stack_ptr < 0 ){
                                yyterminate();
                            } else{
                                yy_delete_buffer( YY_CURRENT_BUFFER );
                                yy_switch_to_buffer(
                                include_stack[include_stack_ptr] );
                            }}


"/*"                        BEGIN(multiline_comment);
"#"                         BEGIN(single_comment);

<multiline_comment>[^"*/"]* /* eat comment */
<multiline_comment>"*/"     BEGIN(0);
<single_comment>.*$         {BEGIN(0);}


":="                        { return(ASSGNOP); } 
{DIGIT}+                    { yylval.intval = atoi( yytext ); 
                              return(NUMBER); } 
do                          { return(DO); }
else                        { return(ELSE); } 
end                         { return(END); } 
fi                          { return(FI); } 
if                          { return(IF); } 
in                          { return(IN); } 
integer                     { return(INTEGER); } 
let                         { return(LET); } 
read                        { return(READ); } 
skip                        { return(SKIP); } 
then                        { return(THEN); } 
while                       { return(WHILE); } 
write                       { return(WRITE); }
{ID}                        { yylval.id = (char *) strdup(yytext); return(IDENTIFIER); } 
[ \t\n]+                    /* eat up whitespace */ 
.                           { return(yytext[0]);} 

%% 

int yywrap(void){ 
   return 1; 
}

/************************** End Scanner File *****************************/ 
