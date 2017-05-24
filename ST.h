/*------------------------------------------------------------------------- 
SYMBOL TABLE RECORD 
-------------------------------------------------------------------------*/ 

struct symrec 
{ 
  char *name; /* name of symbol */
  char *scope; /* name of scope => GLOBAL or name of function */
  int length; /* Length of array or Functions number of params */ 
  int offset; /* data offset */ 
  struct symrec *next; /* link field */ 
}; 
typedef struct symrec symrec; 

symrec * getsym (char *sym_name);
symrec * putsym (char *sym_name, int length, char *scope);

