/*-------------------------------------------------------------------------
SYMBOL TABLE RECORD
-------------------------------------------------------------------------*/
typedef enum {INT, ARRAY, FUNCTION} Type;

struct symrec
{
  char *name; /* name of symbol */
  int scope; /* name of scope */
  int length; /* Length of array or Functions number of params */
  int offset; /* data offset */
  /*FUNCTION PARAMS*/
  int position; /* Position of param in function */
  int inner_scope; /*Scope inside this function*/
  /*TYPE*/
  Type type;
  struct symrec *next; /* link field */
};
typedef struct symrec symrec;

symrec * getsymOnCurrentScope (char *sym_name);
symrec * getsymArgument (int position, int scope);
symrec * getsym (char *sym_name, int scope, int previous_level);
symrec * putsym (char *sym_name, int length, int position, Type type);
symrec * create_reference (char *sym_name, int position, Type type);


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


/*-------------------------------------------------------------------------
REFERENCES OF ARRAYS
-------------------------------------------------------------------------*/

#define STACK_REFERENCES_MAX 100

struct reference_struct {
    char*    origin_var;
    int      origin_scope;
    char*    source_var;
    int      source_scope;
};
typedef struct reference_struct r_struct;

struct reference_stack {
    r_struct * data[STACK_REFERENCES_MAX];
    int size;
};
typedef struct reference_stack r_stack;

void initReferenceStack();
void pushReference(r_struct * r_struck);
r_struct * popReference();
int getReferencesSize();


/*-------------------------------------------------------------------------
STACK TO STORE BACKPATCH OFFSETS (Backpatch = bp)
-------------------------------------------------------------------------*/

#define STACK_BP_MAX 100

struct bp_struct {
    char*    name;        // VAR
    int      operation;  // STORE_SUBS = 0 LD_SUBS = 1
    int      label;
    int      scope;
};
typedef struct bp_struct bp_struct;

struct bp_stack {
    bp_struct * data[STACK_BP_MAX];
    int size;
};
typedef struct bp_stack bp_stack;

void initBPStack();
void pushBP(bp_struct * bp_struck);
bp_struct * popBP();
int getBPSize();
