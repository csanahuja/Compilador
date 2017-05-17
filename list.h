/*************************************************************************** 
Dissassembler 
Author: Jordi Planes
***************************************************************************/ 


#define LABEL_NOT_FOUND -1

struct IntNode {
  int address;
  struct IntNode* next;
};

struct SymNode {
  char *name;
  int address;
  struct IntNode* backpatches;
  struct SymNode* next;
};

extern struct SymNode* sym_list;

void sym_add_address( char*, int );
void sym_add_backpatch( char*, int );
int sym_get_address( char* );
struct IntNode* sym_get_backpatches( char* );
