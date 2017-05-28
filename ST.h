/*-------------------------------------------------------------------------
SYMBOL TABLE RECORD
-------------------------------------------------------------------------*/

struct symrec
{
  char *name; /* name of symbol */
  int scope; /* name of scope */
  int length; /* Length of array or Functions number of params */
  int offset; /* data offset */
  /*FUNCTION PARAMS*/
  int position; /* Position of param in function */
  int inner_scope; /*Scope inside this function*/
  struct symrec *next; /* link field */
};
typedef struct symrec symrec;

symrec * getsymOnCurrentScope (char *sym_name);
symrec * getsymArgument (int position, int scope);
symrec * getsym (char *sym_name, int scope, int previous_level);
symrec * putsym (char *sym_name, int length, int position);


/*-------------------------------------------------------------------------
STACK TO STORE SCOPES
-------------------------------------------------------------------------*/

#define STACK_MAX 100

struct scope_stack {
    int      data[STACK_MAX];
    int      size;
    int      num_scopes;
};
typedef struct scope_stack scope_stack;

void initScopeStack();
int getCurrentScope();
int getPreviousScope(int previous_level);
void pushScope();
void popScope();
