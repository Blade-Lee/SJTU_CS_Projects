#ifndef MAIN_HPP
#define MAIN_HPP

#include <iostream>
#include <string>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

using namespace std;

//the types of elements in symbol table
enum recordType {VAR_RECORD, FUNC_RECORD, ARR_RECORD, STR_RECORD, STR_BUILD_RECORD};

//a member in a struct
typedef struct StructMemberRec{
	string name;
	
	//0,4,8,12...
	int index;

	struct StructMemberRec *next;
} *StructMember;

/* the list of scope of the source 
 * code in which a variable is referenced
 */

typedef struct LineListRec{ 
		int scope;
		int son_scope;
		recordType type;

		//for variable and array to distinguish in intermediate code
		int VarNum;
		int LabNum;
		
		//for array
		int dimen;
		int members_1;
		int members_2;

		//for function
		int paraNum;

		//for struct
		StructMember members;
		
		struct LineListRec * next;
	} * LineList;


typedef struct backpatchRec{
	int lineNum;
	struct backpatchRec *next;
} *BackPatchList;

//inherited attributes and synthesized attributes
struct Type
{
	//1:var 2:array
	int var_type;

	//1:var 2:array
	int arrs_type;

	//0:none 1:EXPS
	int exp_type;

	//0:not bool exps  1: bool exps 2:EXP is empty(used in for statement)
	int exps_type;

	//0:none 1:not-none
	int extvars_type;

	//0:none 1:not-none
	int paras_type;

	//0:not func 1:func
	int args_type;

	//count the args when call func
	int args_count;

	//check_whether return is in STMT
	int has_return;

	//for IDs
	string name;

	//for variables and integer
	int isLeft;
	int value;

	//for arrays
	int place_1;
	int place_2;
	int isleft_1;
	int isleft_2;
	int members_1;
	int members_2;
	int dimen;
	int arraytop;
	int arrayoffset;

	//for struct
	//1: define new 2:build new
	int stspec_type;
	int sextvars_type;
	StructMember members;

	//run-time
	//for right value,tx stores value
	//for left value, tx stores address
	int place;
	//count the comma
	int commacount;

	//flow of control
	BackPatchList truelist;
	BackPatchList falselist;
	BackPatchList nextlist;
	BackPatchList breaklist;
	BackPatchList continuelist;

	//the line number of an instruction
	int instr;

	//0:none 1:not-none
	int stmts_type;

	//0:not 1:break
	int for_break;

	//0:not 1:continue
	int for_continue;
	
};
#define YYSTYPE Type


#endif
