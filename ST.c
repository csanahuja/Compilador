/***************************************************************************
Symbol Table Module
Author: Anthony A. Aaby
Modified by: Jordi Planes
Extended by: Cristian Sanahuja
***************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "CG.h"
#include "ST.h"

/*=========================================================================
DECLARATIONS
=========================================================================*/

/*-------------------------------------------------------------------------
SYMBOL TABLE ENTRY
-------------------------------------------------------------------------*/
symrec *identifier;

/*-------------------------------------------------------------------------
SYMBOL TABLE
Implementation: a chain of records.
------------------------------------------------------------------------*/
symrec *sym_table = (symrec *)0; /* The pointer to the Symbol Table */

/*========================================================================
  Operations: Putsym, Getsym
  ========================================================================*/
symrec * putsym (char *sym_name, int length)
{
  symrec *ptr;
  ptr = (symrec *) malloc (sizeof(symrec));
  ptr->name = strdup(sym_name);

  ptr->scope = strdup(getCurrentScope());
  ptr->offset = data_location();
  ptr->length = length;

  int i;
  for(i = 1; i < length; i++)
    data_location();
  ptr->next = (struct symrec *)sym_table;
  sym_table = ptr;
  return ptr;
}

symrec * getsym (char *sym_name, char* scope, int previous_level)
{
  if (scope==0)
    return NULL;

  symrec *ptr;
  for ( ptr = sym_table;
	ptr != (symrec *) 0;
	ptr = (symrec *)ptr->next )
    if (strcmp (ptr->name,sym_name) == 0)
      if(strcmp (ptr->scope,scope) == 0)
        return ptr;
  return getsym(sym_name, getPreviousScope(previous_level+1), previous_level+1);
}

symrec * getsymOnCurrentScope (char *sym_name)
{
  symrec *ptr;
  for ( ptr = sym_table;
	ptr != (symrec *) 0;
	ptr = (symrec *)ptr->next )
    if (strcmp (ptr->name,sym_name) == 0)
      if(strcmp (ptr->scope,getCurrentScope()) == 0)
        return ptr;
  return NULL;
}

/************************** End Symbol Table **************************/

/*========================================================================
  Scopes
  ========================================================================*/

scope_stack* s_scope;

void initScopeStack(){
    s_scope = (scope_stack *) malloc(sizeof(scope_stack));
    s_scope->size = 0;
}

char* getCurrentScope(){
    if (s_scope->size == 0) {
        return "GLOBAL";
    }

    return s_scope->data[s_scope->size-1];
}

char* getPreviousScope(int previous_level){
  int index = s_scope->size - 1 - previous_level;
  if (index < 0) {
      return "GLOBAL";
  }
  return s_scope->data[index];
}

void pushScope(char* scope){
    if (s_scope->size < STACK_MAX)
        s_scope->data[s_scope->size++] = strdup(scope);
    else
        fprintf(stderr, "Error: stack full\n");
}

void popScope(){
    if (s_scope->size == 0)
        fprintf(stderr, "Error: stack empty\n");
    else
        s_scope->size--;
}
