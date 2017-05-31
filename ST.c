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
symrec * putsym (char *sym_name, int length, int position, Type type)
{
  symrec *ptr;
  ptr = (symrec *) malloc (sizeof(symrec));
  ptr->name = strdup(sym_name);

  ptr->scope = getCurrentScope();
  ptr->offset = data_location();
  ptr->length = length;
  ptr->position = position;
  ptr->type = type;

  int i;
  for(i = 1; i < length; i++)
    data_location();
  ptr->next = (struct symrec *)sym_table;
  sym_table = ptr;
  return ptr;
}

symrec * create_reference (char *sym_name, int position, Type type)
{
  symrec *ptr;
  ptr = (symrec *) malloc (sizeof(symrec));
  ptr->name = strdup(sym_name);

  ptr->scope = getCurrentScope();
  ptr->offset = 0;  //To be updated
  ptr->length = 0;  //To be updated
  ptr->position = position;
  ptr->type = type;

  ptr->next = (struct symrec *)sym_table;
  sym_table = ptr;
  return ptr;
}

symrec * getsym (char *sym_name, int scope, int previous_level)
{
  symrec *ptr;
  for ( ptr = sym_table;
	ptr != (symrec *) 0;
	ptr = (symrec *)ptr->next )
    if (strcmp (ptr->name,sym_name) == 0)
      if(ptr->scope == scope)
        return ptr;
  if (scope==0)
    return NULL;
  return getsym(sym_name, getPreviousScope(previous_level+1), previous_level+1);
}

symrec * getsymOnCurrentScope (char *sym_name)
{
  symrec *ptr;
  for ( ptr = sym_table;
	ptr != (symrec *) 0;
	ptr = (symrec *)ptr->next )
    if (strcmp (ptr->name,sym_name) == 0)
      if(ptr->scope == getCurrentScope())
        return ptr;
  return NULL;
}

symrec * getsymArgument (int position, int scope)
{
  symrec *ptr;
  for ( ptr = sym_table;
	ptr != (symrec *) 0;
	ptr = (symrec *)ptr->next )
    if (ptr->position == position)
      if(ptr->scope == scope)
        return ptr;
  return NULL;
}

char * getScopeName(int scope){
  symrec *ptr;
  for ( ptr = sym_table;
  ptr != (symrec *) 0;
  ptr = (symrec *)ptr->next )
    if (ptr->type == FUNCTION)
      if(ptr->inner_scope == scope)
        return ptr->name;
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
    s_scope->num_scopes = 0;
}

int getCurrentScope(){
    if (s_scope->size == 0) {
        return 0;
    }

    return s_scope->data[s_scope->size-1];
}

int getPreviousScope(int previous_level){
  int index = s_scope->size - 1 - previous_level;
  if (index < 0) {
      return 0;
  }
  return s_scope->data[index];
}

void pushScope(){
    if (s_scope->size < STACK_MAX){
        s_scope->num_scopes++;
        s_scope->data[s_scope->size++] = s_scope->num_scopes;
    }
    else
        fprintf(stderr, "Error: stack of scopes full\n");
}

void popScope(){
    if (s_scope->size == 0)
        fprintf(stderr, "Error: stack of scopes empty\n");
    else
        s_scope->size--;
}

/*========================================================================
References
  ========================================================================*/

r_stack* refes;

void initReferenceStack(){
  refes = (r_stack *) malloc(sizeof(r_stack));
  refes->size = 0;
}

int getReferencesSize(){
  return refes->size;
}

void pushReference(r_struct * rf){
  if (refes->size < STACK_REFERENCES_MAX){
      refes->data[refes->size] = malloc(sizeof(r_struct));
      refes->data[refes->size] = rf;
      refes->size++;
  }
  else
      fprintf(stderr, "Error: stack of references full\n");
}

r_struct * popReference(){
  if (refes->size == 0){
      fprintf(stderr, "Error: stack of references empty\n");
      exit(-1);
  }
  refes->size--;
  return refes->data[refes->size];
}


/*========================================================================
  Backpatch
  ========================================================================*/

bp_stack* bps;

void initBPStack(){
  bps = (bp_stack *) malloc(sizeof(bp_stack));
  bps->size = 0;
}

int getBPSize(){
  return bps->size;
}

void pushBP(bp_struct * bp){
  if (bps->size < STACK_BP_MAX){
      bps->data[bps->size] = malloc(sizeof(bp_struct));
      bps->data[bps->size] = bp;
      bps->size++;
  }
  else
      fprintf(stderr, "Error: stack of backpaths full\n");
}

bp_struct * popBP(){
  if (bps->size == 0){
      fprintf(stderr, "Error: stack of backpaths empty\n");
      exit(-1);
  }
  bps->size--;
  return bps->data[bps->size];
}
