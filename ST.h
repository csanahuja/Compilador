/*-------------------------------------------------------------------------
SYMBOL TABLE RECORD
-------------------------------------------------------------------------*/

struct symrec
{
  char *name; /* name of symbol */
  char *scope; /* name of scope */
  int length; /* Length of array or Functions number of params */
  int offset; /* data offset */
  struct symrec *next; /* link field */
};
typedef struct symrec symrec;

symrec * getsymOnCurrentScope (char *sym_name);
symrec * getsym (char *sym_name, char* score, int previous_level);
symrec * putsym (char *sym_name, int length);


/*-------------------------------------------------------------------------
STACK TO STORE SCOPES
-------------------------------------------------------------------------*/

#define STACK_MAX 100

struct scope_stack {
    char*     data[STACK_MAX];
    int     size;
};
typedef struct scope_stack scope_stack;

void initScopeStack();
char* getCurrentScope();
char* getPreviousScope(int previous_level);
void pushScope(char* scope);
void popScope();
