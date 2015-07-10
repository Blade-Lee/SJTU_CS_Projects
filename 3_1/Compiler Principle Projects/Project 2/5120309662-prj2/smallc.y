/*
This is smallc.y

This source file defines the grammar of SmallC language.

Its structure unit is named token, which comes from the yylex() program in lex.yy.c .

This source file will generates a program called yyparse(), which interacts with yylex(),
and then produce a parsed input for the next stages of compiling.

The procedure is:

1.Construct the symbol table

2.Parse the source file and generate intermediate code.

3.Read from intermediate code and generate MIPS code. 


*/

%{
#include "def.h"	

extern "C"			
{					
	void yyerror(const char *s);
	extern int yylex(void);
}


/***************************************************************************************************

										GLOBAL VARIABLE

****************************************************************************************************/

extern FILE *yyin;
FILE *InterCode;
FILE *MIPSCode;
extern int linecount;
extern int yychar;
extern char* yytext;


//SCOPE is used to record the depth
static int SCOPE = 1;

//only one main function here
static int main_count = 0;

//record the label of main function
static int main_label = -1;

/*-------------------------------------SCOPE VARIABLE AND FUNCTIONS--------------------------------*/

//this stack is used to track parent in ST
static int parent_stack[1000];

// parent_table[x][y] == 1 means that x is the parent of y
static int parent_table[1000][1000];

// initiate the parent table
int initParentTable(){
	for(int i = 0; i<1000;++i){
		for(int k = 0; k<1000; ++k){
			parent_table[i][k]=-1;		
		}
	}
}

// find the parent of current scope x
int findParent(int x){
	for (int i = 0;i<1000;++i){
		if(parent_table[i][x] == 1){
			return i;
		}
			
	}
	return -1;
}

//the top of the parent stack
int parentTop = -1;

//pop from the parent stack
int parent_pop(){
	if (parentTop == -1)
		return -1;
	else {
		parentTop--;
		return 0;
	}
	
}

//push a new scope into parent stack
int parent_push(int a){
	if (parentTop < 999){
		parent_stack[++parentTop] = a;
		if (parentTop > 0){
			parent_table[parent_stack[parentTop-1]][parent_stack[parentTop]] = 1;

		}
		else
			parent_table[0][1] = 1;
	}
	else
		return -1;
	return 0;
}

//get the current scope
int parent_top(){
	if (parentTop == -1)
		return -1;
	else
		return parent_stack[parentTop];
}


/*--------------------------------------GLOBAL COUNTERS--------------------------------------*/
#define INT_SIZE 4

//variable counter
//used to count the names of var, array, and struct
static int VarCounter = 0;

//used to count the names of func
static int LabCounter = 0;

//used to count the temps
static int tempcount = 0;


/*-------------------------------------GLOBAL LINKS------------------------------------------*/
//the link unit of args
typedef struct args_unit_res{
	int place;
	int isLeft;
	struct args_unit_res *next;
	struct args_unit_res *prev;
} *args_unit;

//used to track the args when a function is called
static args_unit args_link = NULL;

//add an arg to the link
void add_args_unit(int place, int isLeft){
	if (args_link == NULL){
		args_link = new struct args_unit_res;
		args_link->place = place;
		args_link->isLeft = isLeft;
		args_link->next = NULL;
		args_link->prev = NULL;
	}

	else {
		args_unit temp = args_link;
		while (temp->next!=NULL){
			temp = temp->next;
		}
		temp->next = new struct args_unit_res;
		temp->next->place = place;
		temp->next->isLeft = isLeft;
		temp->next->next = NULL;
		temp->next->prev = temp;
	}

}

//delete an arg from the link
void delete_args_unit(){
	if (args_link == NULL){
		return;
	}
	else {
		
		if (args_link->next == NULL){
			delete args_link;
			args_link = NULL;
		}
		else {
			args_unit temp = args_link;
			while (temp->next->next != NULL){
				temp = temp->next;
			}
			delete temp->next;
			temp->next = NULL;
		}
	}
}

//the unit of parameter link
typedef struct param_res{
	int VarNum;
	struct param_res *next;
} *param;

//used to link parameters when a function is defined
static param param_link = NULL;

//add a parameter in the link
void add_param(int VarNum){
	if (param_link == NULL){
		param_link = new struct param_res;
		param_link->VarNum = VarNum;
		param_link->next = NULL;
	}

	else {
		param temp = param_link;
		while (temp->next!=NULL){
			temp = temp->next;
		}
		temp->next = new struct param_res;
		temp->next->VarNum = VarNum;
		temp->next->next = NULL;
	}

}

//refresh the parameter link
void renew_param_link(){
	if (param_link != NULL)
		delete param_link;
	param_link = NULL;
}


/***********************FUNCTIONS AND VARIABLES FOR INTERMEDIATE CODE**************************/

//the intermediate code 
static char code[5000][50];

//the next available position of an instrucion
static int nextinstr = 0;

//copy the code to the InterCode file
void copyCode(){
	for (int i = 0;i<nextinstr;++i){
		fprintf(InterCode,"%s\n",code[i]);
	}
}

//make a new backpatch position
BackPatchList makelist(int nextinstr){
	BackPatchList temp = new struct backpatchRec;
	temp->lineNum = nextinstr;
	temp->next = NULL;
	return temp;
}

//backpatch the '_'s
void backpatch(BackPatchList list,int instr){
	BackPatchList temp = list;
	int labelNum = LabCounter++;
	int index;
	sprintf(code[instr],"LABEL label%d :",labelNum);


	while(temp != NULL){
		index = 0;

		while (code[temp->lineNum][index] != '_'){
			index++;
		}
		if (code[temp->lineNum][index] == '_'){
			sprintf(&code[temp->lineNum][index],"%d",labelNum);
		}
		else{
			fprintf(stderr,"Backpatch Error: [Line %d]\n",linecount+1);
			exit(-1);
		}
		temp = temp->next;
	}

	delete list;
}

//merge two lists
BackPatchList merge(BackPatchList list1,BackPatchList list2){

	if (list1 == NULL)
		list1 = list2;
	else{
		BackPatchList temp = list1;

		while (temp->next != NULL){
			temp = temp->next;
		}
		
		temp->next = list2;
	}

	list2 = NULL;
	
	return list1;
}



/***********************************GLOBAL VARIABLE END*********************************************/







/*****************************************************************************************************
	
											RUN TIME DELARATION 

******************************************************************************************************/

//return an integer x: means tx is available.
int newtemp(){
	return tempcount++;
}

// return an integer x: means labelx is available.
int newlabel(){
	return LabCounter++;
}


/**********************************RUN TIME DECLARATION END******************************************/




/**************************************************************************************************

											SYMBOL TABLE

**************************************************************************************************/

/* SIZE is the size of the hash table */
#define SIZE 211

/* SHIFT is the power of two used as multiplier
   in hash function  */
#define SHIFT 4

/* the hash function */
static int hash (string key){
	int temp = 0;
	int i = 0;
	int strleng = key.size();
	while (strleng > 0){ 
		temp = ((temp << SHIFT) + key[i]) % SIZE;
		++i;
		strleng--;
	}
	return temp;
}



//global linelist pointer
static LineList GlobalLineList;


/* The record in the bucket lists for
 * each variable, including name, 
 * and the list of scopes in which
 * it appears in the source code
 */
typedef struct BucketListRec
   { string name;
     LineList lines;
   } * BucketList;

/* the hash table */
static BucketList hashTable[SIZE];


//initiate the hash table
void initialHashTable(){
	for (int i = SIZE-1; i > 0; --i){
		hashTable[i] = NULL;
	}
}

void show_members(StructMember members){
	StructMember temp = members;

	while (temp != NULL){
		printf("name: %s, index: %d\n",temp->name.c_str(),temp->index);
		temp = temp->next;
	}
}

//insert a variable
void var_insert(string name);

//insert a function
//paraNum is the number of parameters
void func_insert( string name, int paraNum);

//insert an array
//dimen: dimension
//members_1: elements in 1st dimension
//members_2: elements in 2nd dimension
void arr_insert( string name, int dimen, int members_1,int members_2);

//insert a definition of struct
void str_def_insert(string name);

//insert an instance of struct
//members: the variable defined inside the struct
void str_build_insert(string name,StructMember members);

//symbol table lookup
//input: 1.name 2.type 3.parameters(when not function lookup,use 0)
LineList st_lookup(string name, recordType type,int paraNum);

//check scope in the symbol table
LineList st_check_scope(string name,recordType type,int paraNum);

/*************************************END OF SYMBOL TABLE******************************************/





/************************************************************************************************

										CODE GENERATION

***********************************************************************************************/

/*--------------------------------------STATIC VARIABLE----------------------------------------*/

//STA means static
typedef struct STA_BLOCK_REC{
	char instruction[50];
	struct STA_BLOCK_REC *next;	
} *staBlock;

//the head of the link of STA blocks
static staBlock sta_block = NULL;

//add an instruction into the STA block link
void add_staBlock(char *instruction){
	if (sta_block == NULL){
		sta_block = new struct STA_BLOCK_REC;
		strcpy(sta_block->instruction,instruction);
		sta_block->next = NULL;
	}
	else{
		staBlock temp = sta_block;
		while (temp->next != NULL)
			temp = temp->next;
		temp->next = new struct STA_BLOCK_REC;
		strcpy(temp->next->instruction,instruction);
		temp->next->next = NULL;		
	}
}

//add an instuction on a line of code
void plusLine(int line,char *instruction){
	if(line > nextinstr){
		fprintf(stderr,"PlusLine error!\n");
		exit(-1);
	}
	else{
		for(int i = nextinstr-1;i>=line;i--){
			for(int j=0;j<50;++j)
				code[i+1][j] = '\0';
			strcpy(code[i+1],code[i]);
		}
		nextinstr++;
	}
	for(int j=0;j<50;++j)
		code[line][j] = '\0';
	strcpy(code[line],instruction);
}

//delete a line from the code
void cleanLine(int line){
	if (line >= nextinstr){
		fprintf(stderr,"CleanLine error!\n");
		exit(-1);
	}
	else{
		for(int i = line;i<nextinstr;++i){
			for(int j=0;j<50;++j)
				code[i][j] = '\0';
			strcpy(code[i],code[i+1]);
		}
		nextinstr--;
	}
}

//start to link sta from line i
void sta_link(int line){
	char *temp = code[line];

	while(temp[0]!='S' && temp[0]!='F' && line != nextinstr){
		add_staBlock(temp);
		cleanLine(line);
	}
}

//store the STA initiation codes and make room for STA variables, structs, arrays
//as well as parameters of functions and local variables
//the goal is to make every variable distinguishing
//and print them at the beginning of main function
void sta_store(){
	char *temp_name;
	char *temp_byte;
	int bytes;
	int i = 0;
	while(i<nextinstr){
		if (code[i][0]=='S'){
			temp_name = strtok(code[i]," ");
			temp_name = strtok(NULL," ");
			fprintf(MIPSCode,"%s:	.word",temp_name);
			temp_byte = strtok(NULL," ");
			bytes = atoi(temp_byte);
			bytes /= 4;
			for(int k=0;k<bytes;++k){
				fprintf(MIPSCode," %d",0);
			}
			fprintf(MIPSCode,"\n");
			cleanLine(i);

			//Stop when FUNC and STA appear
			sta_link(i);
		}
		else if (code[i][0]=='D'){
			temp_name = strtok(code[i]," ");
			temp_name = strtok(NULL," ");
			fprintf(MIPSCode,"%s:	.word",temp_name);
			temp_byte = strtok(NULL," ");
			bytes = atoi(temp_byte);
			bytes /= 4;
			for(int k=0;k<bytes;++k){
				fprintf(MIPSCode," %d",0);
			}
			fprintf(MIPSCode,"\n");
			cleanLine(i);
		}
		else if (code[i][0]=='P'){
			char p[15];
			temp_name = strtok(code[i]," ");
			temp_name = strtok(NULL," ");
			fprintf(MIPSCode,"%s:	.word 0\n",temp_name);
			sprintf(p,"XX %s",temp_name);
			cleanLine(i);
			plusLine(i,p);
		}
		else{
			++i;
		}
	}
}

//make room for temporary variables
void t_store(){
	for (int i = 0;i<tempcount;++i){
		fprintf(MIPSCode,"t%d:	.word 0\n",i);
	}
}

//find the location of main function
//and insert the STA link into the main function
void insert_init(){
	int main_line = 0;
	char main_ch[30];
	sprintf(main_ch,"FUNCTION label%d",main_label);
	for (int i = 0;i<nextinstr;++i){
		if (!strcmp(code[i],main_ch)){
			main_line = i + 1;
			break;
		}
	}

	staBlock temp = sta_block;
	while(temp != NULL){
		plusLine(main_line++,temp->instruction);
		temp = temp->next;
	}

	if (sta_block != NULL)
		delete sta_block;

}


/*-----------------------------------TOOLS FUNCTIONS----------------------------------*/

//find the containing scope of the function
int findSonScope(int func_label){ 
	int i;
	for (i=0;i<SIZE;++i){ 
		if (hashTable[i] != NULL){ 
			BucketList l = hashTable[i];
			LineList t = l->lines;
			while (t != NULL){
				
				if(t->type == FUNC_RECORD && t->LabNum == func_label){
					return t->son_scope;
				}
				t = t->next;
			}
		}
	}
}


//when a function is calling another function
//we need to store all its local variables into stack
int stack_in(int func_label){
	int stack_counter = 0;
	int son_scope = findSonScope(func_label);

	for (int i=0;i<SIZE;++i){ 
		if (hashTable[i] != NULL){ 
			BucketList l = hashTable[i];
			LineList t = l->lines;
			while (t != NULL){
				if(t->scope == son_scope){
					switch (t->type){

						case VAR_RECORD:{

							stack_counter++;
							fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

							fprintf(MIPSCode,"	la $t0,v%d\n",t->VarNum);
							fprintf(MIPSCode,"	lw $t1,0($t0)\n");
				
							fprintf(MIPSCode,"	sw $t1,0($sp)\n");

						break;}
						case ARR_RECORD:{
							int arr_count = 0;

							if (t->dimen == 1){
								arr_count = t->members_1;
							}
							else{
								arr_count = t->members_1 * t->members_2;
							}
								
							if(arr_count != 0)
								fprintf(MIPSCode,"	la $t0,v%d\n",t->VarNum);
							
							for(int s = 0;s<arr_count;++s){

								stack_counter++;
								fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

								fprintf(MIPSCode,"	lw $t1,0($t0)\n");
				
								fprintf(MIPSCode,"	sw $t1,0($sp)\n");

								fprintf(MIPSCode,"	addi $t0,$t0,4\n");
							}

						break;}
						case STR_BUILD_RECORD:{
							int str_count = 0;

							StructMember temp = t->members;
							while(temp != NULL){
								temp = temp->next;
								str_count++;
							}
				
							if(str_count != 0)
								fprintf(MIPSCode,"	la $t0,v%d\n",t->VarNum);

							for(int s = 0;s<str_count;++s){

								stack_counter++;
								fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

								fprintf(MIPSCode,"	lw $t1,0($t0)\n");
				
								fprintf(MIPSCode,"	sw $t1,0($sp)\n");

								fprintf(MIPSCode,"	addi $t0,$t0,4\n");

							}
						break;}
						default:;
					}
				}
				t = t->next;
			}
		}
	}
	return stack_counter;
}


//when a function get the return value from 
//the function it called previously
//it need to get all its local variables back from the stack
void stack_out(int stack_counter,int func_label){
	int stack_temp = stack_counter;

	if (stack_temp == 0) return;

	fprintf(MIPSCode,"	addi $sp,$sp,%d\n",stack_temp*4);

	int son_scope = findSonScope(func_label);

	for (int i=0;i<SIZE;++i){ 
		if (hashTable[i] != NULL){ 
			BucketList l = hashTable[i];
			LineList t = l->lines;
			while (t != NULL){
				if(t->scope == son_scope){
					switch (t->type){

						case VAR_RECORD:{

							fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

							fprintf(MIPSCode,"	la $t0,v%d\n",t->VarNum);
							fprintf(MIPSCode,"	lw $t1,0($sp)\n");
							fprintf(MIPSCode,"	sw $t1,0($t0)\n");

						break;}
						case ARR_RECORD:{
							int arr_count = 0;

							if (t->dimen == 1){
								arr_count = t->members_1;
							}
							else{
								arr_count = t->members_1 * t->members_2;
							}
								
							if(arr_count != 0)
								fprintf(MIPSCode,"	la $t0,v%d\n",t->VarNum);
							
							for(int s = 0;s<arr_count;++s){

								fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

								fprintf(MIPSCode,"	lw $t1,0($sp)\n");
				
								fprintf(MIPSCode,"	sw $t1,0($t0)\n");

								fprintf(MIPSCode,"	addi $t0,$t0,4\n");
							}

						break;}
						case STR_BUILD_RECORD:{
							int str_count = 0;

							StructMember temp = t->members;
							while(temp != NULL){
								temp = temp->next;
								str_count++;
							}
				
							if(str_count != 0)
								fprintf(MIPSCode,"	la $t0,v%d\n",t->VarNum);

							for(int s = 0;s<str_count;++s){

								fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

								fprintf(MIPSCode,"	lw $t1,0($sp)\n");
				
								fprintf(MIPSCode,"	sw $t1,0($t0)\n");

								fprintf(MIPSCode,"	addi $t0,$t0,4\n");

							}
						break;}
						default:;
					}
				}
				t = t->next;
			}
		}
	}

	fprintf(MIPSCode,"	addi $sp,$sp,%d\n",stack_temp*4);
}

/*------------------------------------INTERMEDIATE CODE OPTIMIZATION------------------------------------*/

//Optimize the intermediate code
void codeOptimize(){
	int now = 0;
	for(;now<nextinstr-1;++now){
		if (code[now][0] == 'G' && code[now][1] == 'O' 
			&& code[now+1][0] == 'G' && code[now+1][1] == 'O')
			{cleanLine(now+1);--now;}
		if (code[now][0] == 'R' && code[now][1] == 'E' 
			&& code[now][2] == 'T' && code[now][3] == 'U' 
			&& code[now+1][0] == 'G' && code[now+1][1] == 'O')
			{cleanLine(now+1);--now;}

	}
}


/*------------------------------------GENERATE MIPS CODE------------------------------------*/

//Generate the target MIPS codes
void codeGenerate(){

	MIPSCode = fopen("MIPSCode.s","w");
	if (MIPSCode == 0){
        fprintf(stderr, "failed to open \"InterCode\" for writing\n");
        exit(1);
    }
	
	fprintf(MIPSCode,"	.data\n");
	
	sta_store();	

	t_store();

	insert_init();

	fprintf(MIPSCode,"	.text\n");
	fprintf(MIPSCode,"	.globl main\n");

	//the handling instruction
	int now = 0;

	//to split an instruction into several parts
	char *tokenlist[5];
	char *temp;
	int i;

	//the label of main function
	char maintemp[10];
	sprintf(maintemp,"label%d",main_label);

	//to check whether the $ra is stored in stack
	//when a function is calling another function
	int ra_stored = 0;

	//current function's label
	int func_label;

	//count the number of bytes when 
	//local variables are stored into stack
	int stack_counter = 0;

	for(;now<nextinstr;++now){
		switch (code[now][0]){
			case 'F':{//FUNCTION
				
				temp = strtok(code[now]," ");
				temp = strtok(NULL," ");

				char *label = temp + 5;

				func_label = atoi(label);
				stack_counter = 0;

				if (!strcmp(temp,maintemp))
					fprintf(MIPSCode,"main:\n");
				else
					fprintf(MIPSCode,"%s:\n",temp);
								
				break;} 
			case 'R':{
				temp = strtok(code[now]," ");
				//READ
				if (!strcmp(temp,"READ")){
					
					temp = strtok(NULL," ");

					//only '*tx'

					fprintf(MIPSCode,"	li $v0,5\n");
					fprintf(MIPSCode,"	syscall\n");

					fprintf(MIPSCode,"	la $t0,%s\n",temp+1);
					fprintf(MIPSCode,"	lw $t1,0($t0)\n");

					fprintf(MIPSCode,"	sw $v0,0($t1)\n");
								
					
				}
				//RETURN
				else{
					temp = strtok(NULL," ");

					switch (temp[0]){
						case '*':{
								fprintf(MIPSCode,"	la $t0,%s\n",temp+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								fprintf(MIPSCode,"	lw $v0,0($t1)\n");
								fprintf(MIPSCode,"	jr $ra\n");
								
							break;}
						default:{
								fprintf(MIPSCode,"	la $t0,%s\n",temp);
								fprintf(MIPSCode,"	lw $v0,0($t0)\n");
								fprintf(MIPSCode,"	jr $ra\n");
							break;}
					
					}
					

				}			
				break;} 
			case 'W':{//WRITE
				temp = strtok(code[now]," ");
				temp = strtok(NULL," ");

				switch (temp[0]){
					case '*':{
							fprintf(MIPSCode,"	la $t0,%s\n",temp+1);
							fprintf(MIPSCode,"	lw $t1,0($t0)\n");
							fprintf(MIPSCode,"	lw $a0,0($t1)\n");
							
						break;}
					default:{
							fprintf(MIPSCode,"	la $t0,%s\n",temp);
							fprintf(MIPSCode,"	lw $a0,0($t0)\n");
						break;}
				
				}

				fprintf(MIPSCode,"	li $v0,1\n");
				fprintf(MIPSCode,"	syscall\n");
								
				break;} 
			case 'I':{//IF
				temp = strtok(code[now]," ");
				char *op1 = strtok(NULL," ");
				char *ope = strtok(NULL," ");
				char *op2 = strtok(NULL," ");
				temp = strtok(NULL," ");
				char *label = strtok(NULL," ");

				if (!strcmp(ope,">")){
					if (op1[0] == '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	bgt $t2,$t5,%s\n",label);
					}
					if(op1[0] != '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	bgt $t1,$t5,%s\n",label);

					}
					if(op1[0] == '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	bgt $t2,$t4,%s\n",label);

					}
					if(op1[0] != '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	bgt $t1,$t4,%s\n",label);
					}
				}

				if (!strcmp(ope,"<")){
					if (op1[0] == '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	blt $t2,$t5,%s\n",label);
					}
					if(op1[0] != '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	blt $t1,$t5,%s\n",label);

					}
					if(op1[0] == '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	blt $t2,$t4,%s\n",label);

					}
					if(op1[0] != '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	blt $t1,$t4,%s\n",label);
					}

				}

				if (!strcmp(ope,">=")){
					if (op1[0] == '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	bge $t2,$t5,%s\n",label);
					}
					if(op1[0] != '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	bge $t1,$t5,%s\n",label);

					}
					if(op1[0] == '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	bge $t2,$t4,%s\n",label);

					}
					if(op1[0] != '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	bge $t1,$t4,%s\n",label);
					}

				}

				if (!strcmp(ope,"<=")){
					if (op1[0] == '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	ble $t2,$t5,%s\n",label);
					}
					if(op1[0] != '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	ble $t1,$t5,%s\n",label);

					}
					if(op1[0] == '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	ble $t2,$t4,%s\n",label);

					}
					if(op1[0] != '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	ble $t1,$t4,%s\n",label);
					}

				}

				if (!strcmp(ope,"==")){
					//here,op2 is probably #0
					if (op1[0] == '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	beq $t2,$t5,%s\n",label);
					}
					if(op1[0] != '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	beq $t1,$t5,%s\n",label);

					}
					if(op1[0] == '*' && op2[0] != '*' && op2[0] != '#'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	beq $t2,$t4,%s\n",label);

					}
					if(op1[0] != '*' && op2[0] != '*' && op2[0] != '#'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	beq $t1,$t4,%s\n",label);
					}


					//#0
					if(op1[0] != '*' && op2[0] == '#'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	beqz $t1,%s\n",label);
					}
					if(op1[0] == '*' && op2[0] == '#'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	beqz $t2,%s\n",label);
					}

				}

				if (!strcmp(ope,"!=")){
					if (op1[0] == '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	bne $t2,$t5,%s\n",label);
					}
					if(op1[0] != '*' && op2[0] == '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2+1);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");
						fprintf(MIPSCode,"	lw $t5,0($t4)\n");

						fprintf(MIPSCode,"	bne $t1,$t5,%s\n",label);

					}
					if(op1[0] == '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1+1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");
						fprintf(MIPSCode,"	lw $t2,0($t1)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	bne $t2,$t4,%s\n",label);

					}
					if(op1[0] != '*' && op2[0] != '*'){
						fprintf(MIPSCode,"	la $t0,%s\n",op1);
						fprintf(MIPSCode,"	lw $t1,0($t0)\n");

						fprintf(MIPSCode,"	la $t3,%s\n",op2);
						fprintf(MIPSCode,"	lw $t4,0($t3)\n");

						fprintf(MIPSCode,"	bne $t1,$t4,%s\n",label);
					}

				}
								
				break;} 
			case 'G':{//GOTO
				temp = strtok(code[now]," ");
				temp = strtok(NULL," ");

				fprintf(MIPSCode,"	j %s\n",temp);
		
				break;} 
			case 'L':{//LABEL
				temp = strtok(code[now]," ");
				temp = strtok(NULL," ");

				fprintf(MIPSCode,"%s:\n",temp);

								
				break;} 
			case 'X':{//XX, this is PARAM before, but after sta_store() function
					//I changed the name
				temp = strtok(code[now]," ");
				temp = strtok(NULL," ");
				
				fprintf(MIPSCode,"	la $t0 %s\n",temp);
				fprintf(MIPSCode,"	lw $t1,0($sp)\n");
				fprintf(MIPSCode,"	sw $t1,0($t0)\n");

				fprintf(MIPSCode,"	addi $sp,$sp,4\n");

				break;} 
			case 'A':{//ARG
				temp = strtok(code[now]," ");
				temp = strtok(NULL," ");

				if (ra_stored == 0){

					stack_counter = stack_in(func_label);

					fprintf(MIPSCode,"	addi $sp,$sp,-4\n");
					fprintf(MIPSCode,"	sw $ra,0($sp)\n");
					
					ra_stored = 1;
				}


				fprintf(MIPSCode,"	addi $sp,$sp,-4\n");

				if (temp[0] == '*'){
					fprintf(MIPSCode,"	la $t0 %s\n",temp+1);
					fprintf(MIPSCode,"	lw $t1,0($t0)\n");
					fprintf(MIPSCode,"	lw $t2,0($t1)\n");
					fprintf(MIPSCode,"	sw $t2,0($sp)\n");
				}
				else{
					fprintf(MIPSCode,"	la $t0 %s\n",temp);
					fprintf(MIPSCode,"	lw $t2,0($t0)\n");
					fprintf(MIPSCode,"	sw $t2,0($sp)\n");
				}
				break;} 
			default:{

				temp = strtok(code[now]," ");
				i = 0;
				for (int k = 0;k<5;++k)
					tokenlist[k] = NULL;

				while(temp != NULL){
					tokenlist[i++] = temp;
					temp = strtok(NULL," ");
				}
				
				switch (i){

					case 3:{// x := y

							switch (tokenlist[0][0]){
								case '*':{

									fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
									fprintf(MIPSCode,"	lw $t1,0($t0)\n");

									switch (tokenlist[2][0]){
										case '*':{
										
											fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
											fprintf(MIPSCode,"	lw $t3,0($t2)\n");
											fprintf(MIPSCode,"	lw $t4,0($t3)\n");

											fprintf(MIPSCode,"	sw $t4,0($t1)\n");

											break;}
										case '&':{

											fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);

											fprintf(MIPSCode,"	sw $t2,0($t1)\n");

											break;}
										case '#':{

											fprintf(MIPSCode,"	li $t2,%d\n",atoi(tokenlist[2]+1));

											fprintf(MIPSCode,"	sw $t2,0($t1)\n");

											break;}
										default:{

											fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
											fprintf(MIPSCode,"	lw $t3,0($t2)\n");

											fprintf(MIPSCode,"	sw $t3,0($t1)\n");

											break;}

									}
							
									break;}
								default:{

									fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

									switch (tokenlist[2][0]){
										case '*':{
										
											fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
											fprintf(MIPSCode,"	lw $t3,0($t2)\n");
											fprintf(MIPSCode,"	lw $t4,0($t3)\n");

											fprintf(MIPSCode,"	sw $t4,0($t1)\n");

											break;}
										case '&':{

											fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);

											fprintf(MIPSCode,"	sw $t2,0($t1)\n");

											break;}
										case '#':{

											fprintf(MIPSCode,"	li $t2,%d\n",atoi(tokenlist[2]+1));

											fprintf(MIPSCode,"	sw $t2,0($t1)\n");

											break;}
										default:{

											fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
											fprintf(MIPSCode,"	lw $t3,0($t2)\n");

											fprintf(MIPSCode,"	sw $t3,0($t1)\n");

											break;}

									}								


									break;}
				
							}			

						break;}
					case 4:{
						//CALL 
						if(!strcmp(tokenlist[2],"CALL")){
							//	tx = CALL labelx
							if(ra_stored == 0){
								
								stack_counter = stack_in(func_label);

								fprintf(MIPSCode,"	addi $sp,$sp,-4\n");
								fprintf(MIPSCode,"	sw $ra,0($sp)\n");


							}
							
							fprintf(MIPSCode,"	jal %s\n",tokenlist[3]);

							fprintf(MIPSCode,"	lw $ra,0($sp)\n");
							fprintf(MIPSCode,"	addi $sp,$sp,4\n");

							stack_out(stack_counter,func_label);

							fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]);
							fprintf(MIPSCode,"	sw $v0,0($t0)\n");

							ra_stored = 0;
					
						}
						// x := op y        x: normal  y: *,normal
						else{//-: minus   ~:bitnot

							fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]);

							if(!strcmp(tokenlist[2],"-")){

								if(tokenlist[3][0] == '*'){
									fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[3]+1);
									fprintf(MIPSCode,"	lw $t2,0($t1)\n");
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									fprintf(MIPSCode,"	neg $t4,$t3\n");
									fprintf(MIPSCode,"	sw $t4,0($t0)\n");

								}
								else{
									fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[3]);
									fprintf(MIPSCode,"	lw $t2,0($t1)\n");

									fprintf(MIPSCode,"	neg $t4,$t2\n");
									fprintf(MIPSCode,"	sw $t4,0($t0)\n");
								}
							}

							if(!strcmp(tokenlist[2],"~")){
								if(tokenlist[3][0] == '*'){
									fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[3]+1);
									fprintf(MIPSCode,"	lw $t2,0($t1)\n");
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									fprintf(MIPSCode,"	not $t4,$t3\n");
									fprintf(MIPSCode,"	sw $t4,0($t0)\n");

								}
								else{
									fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[3]);
									fprintf(MIPSCode,"	lw $t2,0($t1)\n");

									fprintf(MIPSCode,"	not $t4,$t2\n");
									fprintf(MIPSCode,"	sw $t4,0($t0)\n");
								}
								
							}
						}

						break;}
					case 5:{// x := y op z   
							// /x: *,normal/  /y: *,&(+),normal/  /z: *,#(+,-,*),normal/

						if (!strcmp(tokenlist[3],"+")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y + *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	add $t7,$t7,$t4\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := *y + #z

										fprintf(MIPSCode,"	addi $t4,$t4,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}
									else{//*x := *y + z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	add $t6,$t6,$t4\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else if (tokenlist[2][0] == '&'){//&y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);

									if (tokenlist[4][0] == '*'){//*x := &y + *z

										fprintf(MIPSCode,"	la $t3,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t4,0($t3)\n");
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	add $t5,$t5,$t2\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := &y + #z

										fprintf(MIPSCode,"	addi $t2,$t2,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t2,0($t1)\n");

									}
									else{//*x := &y + z

										fprintf(MIPSCode,"	la $t3,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t4,0($t3)\n");

										fprintf(MIPSCode,"	add $t4,$t4,$t2\n");

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}

								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y + *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	add $t6,$t6,$t3\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := y + #z

										fprintf(MIPSCode,"	addi $t3,$t3,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t3,0($t1)\n");

									}
									else{//*x := y + z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	add $t5,$t5,$t3\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y + *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	add $t7,$t7,$t4\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := *y + #z

										fprintf(MIPSCode,"	addi $t4,$t4,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}
									else{//x := *y + z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	add $t6,$t6,$t4\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else if (tokenlist[2][0] == '&'){//&y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);

									if (tokenlist[4][0] == '*'){//x := &y + *z

										fprintf(MIPSCode,"	la $t3,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t4,0($t3)\n");
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	add $t5,$t5,$t2\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := &y + #z

										fprintf(MIPSCode,"	addi $t2,$t2,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t2,0($t1)\n");

									}
									else{//x := &y + z

										fprintf(MIPSCode,"	la $t3,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t4,0($t3)\n");

										fprintf(MIPSCode,"	add $t4,$t4,$t2\n");

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}

								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y + *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	add $t6,$t6,$t3\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := y + #z

										fprintf(MIPSCode,"	addi $t3,$t3,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t3,0($t1)\n");

									}
									else{//x := y + z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	add $t5,$t5,$t3\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}
						}

						if (!strcmp(tokenlist[3],"-")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y - *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	sub $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := *y - #z

										fprintf(MIPSCode,"	addi $t4,$t4,-%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}
									else{//*x := *y - z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sub $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y - *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sub $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := y - #z

										fprintf(MIPSCode,"	addi $t3,$t3,-%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t3,0($t1)\n");

									}
									else{//*x := y - z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	sub $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y - *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	sub $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := *y - #z

										fprintf(MIPSCode,"	addi $t4,$t4,-%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}
									else{//x := *y - z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sub $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y - *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sub $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := y - #z

										fprintf(MIPSCode,"	addi $t3,$t3,-%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	sw $t3,0($t1)\n");

									}
									else{//x := y - z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	sub $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

						}
						if (!strcmp(tokenlist[3],"*")){

							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y * *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	mul $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := *y * #z

										fprintf(MIPSCode,"	li $t5,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	mul $t5,$t5,$t4\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");

									}
									else{//*x := *y * z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	mul $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y * *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	mul $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//*x := y * #z

										fprintf(MIPSCode,"	li $t4,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	mul $t4,$t4,$t3\n");

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}
									else{//*x := y * z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	mul $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y * *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	mul $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := *y * #z

										fprintf(MIPSCode,"	li $t5,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	mul $t5,$t5,$t4\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");

									}
									else{//x := *y * z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	mul $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y * *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	mul $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else if(tokenlist[4][0] == '#'){//x := y * #z

										fprintf(MIPSCode,"	li $t4,%s\n",tokenlist[4]+1);

										fprintf(MIPSCode,"	mul $t4,$t4,$t3\n");

										fprintf(MIPSCode,"	sw $t4,0($t1)\n");

									}
									else{//x := y * z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	mul $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}


						}
						if (!strcmp(tokenlist[3],"/")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y / *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	div $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y / z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	div $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y / *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	div $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y / z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	div $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y / *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	div $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y / z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	div $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y / *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	div $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y / z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	div $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}
						}
						if (!strcmp(tokenlist[3],"%")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y % *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	rem $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y % z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	rem $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y % *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	rem $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y % z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	rem $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y % *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	rem $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y % z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	rem $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y % *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	rem $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y % z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	rem $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}
						}
						if (!strcmp(tokenlist[3],"<<")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y << *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	sllv $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y << z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sllv $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y << *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sllv $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y << z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	sllv $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y << *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	sllv $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y << z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sllv $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y << *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	sllv $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y << z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	sllv $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

						}
						if (!strcmp(tokenlist[3],">>")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y >> *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	srlv $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y >> z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	srlv $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y >> *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	srlv $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y >> z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	srlv $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y >> *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	srlv $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y >> z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	srlv $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y >> *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	srlv $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y >> z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	srlv $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

						}
						if (!strcmp(tokenlist[3],"&")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y & *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	and $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y & z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	and $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y & *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	and $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y & z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	and $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y & *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	and $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y & z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	and $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y & *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	and $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y & z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	and $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

						}
						if (!strcmp(tokenlist[3],"^")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y ^ *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	xor $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y ^ z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	xor $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y ^ *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	xor $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y ^ z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	xor $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y ^ *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	xor $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y ^ z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	xor $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y ^ *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	xor $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y ^ z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	xor $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

						}
						if (!strcmp(tokenlist[3],"|")){
							if (tokenlist[0][0] == '*'){//*x

								fprintf(MIPSCode,"	la $t0,%s\n",tokenlist[0]+1);
								fprintf(MIPSCode,"	lw $t1,0($t0)\n");

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//*x := *y | *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	or $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//*x := *y | z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	or $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//*x := y | *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	or $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//*x := y | z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	or $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

							else{//x

								fprintf(MIPSCode,"	la $t1,%s\n",tokenlist[0]);

								if (tokenlist[2][0] == '*'){//*y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]+1);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");
									fprintf(MIPSCode,"	lw $t4,0($t3)\n");

									if (tokenlist[4][0] == '*'){//x := *y | *z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");
										fprintf(MIPSCode,"	lw $t7,0($t6)\n");

										fprintf(MIPSCode,"	or $t7,$t4,$t7\n");

										fprintf(MIPSCode,"	sw $t7,0($t1)\n");

									}
									else{//x := *y | z

										fprintf(MIPSCode,"	la $t5,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	or $t6,$t4,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");
									}
								}
								else{//y

									fprintf(MIPSCode,"	la $t2,%s\n",tokenlist[2]);
									fprintf(MIPSCode,"	lw $t3,0($t2)\n");

									if (tokenlist[4][0] == '*'){//x := y | *z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]+1);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");
										fprintf(MIPSCode,"	lw $t6,0($t5)\n");

										fprintf(MIPSCode,"	or $t6,$t3,$t6\n");

										fprintf(MIPSCode,"	sw $t6,0($t1)\n");

									}
									else{//x := y | z

										fprintf(MIPSCode,"	la $t4,%s\n",tokenlist[4]);
										fprintf(MIPSCode,"	lw $t5,0($t4)\n");

										fprintf(MIPSCode,"	or $t5,$t3,$t5\n");

										fprintf(MIPSCode,"	sw $t5,0($t1)\n");
									}
								}
							}

						}

						break;}
				}
			} 
		}
	}
	fprintf(MIPSCode,"	li $v0,10\n");
	fprintf(MIPSCode,"	syscall\n");
	fclose(MIPSCode);
}


/***********************************CODE GENERATION END****************************************/

%}
%token SEMI COMMA LC RC TYPE STRUCT RETURN IF ELSE BREAK CONT FOR DOT UNKNOWN INT ID READ WRITE

%start PROGRAM

%right SRASSIGN SLASSIGN ORASSIGN NORASSIGN ANDASSIGN DIVISIONASSIGN PRODUCTASSIGN MINUSASSIGN PLUSASSIGN ASSIGN
%left LOGICOR
%left LOGICAND
%left BITOR
%left BITXOR
%left BITAND
%left EQUAL NOTEQUAL
%left GREATERT LESST NOTGREATERT NOTLESST
%left SHIFTLEFT SHIFTRIGHT
%left PLUS MINUS
%left PRODUCT DIVISION MODULUS
%right LOGICNOT PREINCRE PREDEC BITNOT
%left LP RP LB RB

%%
PROGRAM	: EXTDEFS;	
EXTDEFS	: EXTDEF EXTDEFS	
	|	
	;
EXTDEF	: TYPE EXTVARS SEMI {
								if ($2.extvars_type == 0){
									fprintf(stderr,"Wrong definition: [Line %d]\n",linecount+1);
									exit(-1);
								}

							}
	| STSPEC SEXTVARS SEMI	
	| TYPE FUNC STMTBLOCK	{

								if ($3.breaklist != NULL || $3.continuelist != NULL){
									fprintf(stderr,"break(continue) must be in a for statement: [Line %d]\n",linecount+1);
									exit(-1);
								}

								if ($3.has_return == 0){
									fprintf(stderr,"There must be a return in a function: [Line %d]\n",linecount+1);
									exit(-1);
								}

								backpatch($3.nextlist,nextinstr++);

								}
	;
SEXTVARS: ID {

				str_build_insert($1.name, $0.members);

				GlobalLineList = st_lookup($1.name,STR_BUILD_RECORD,0);

				StructMember temp = GlobalLineList->members;

				int count = 0;
			
				while (temp != NULL){
					count+=4;
					temp = temp->next;
				}
				
				if (parent_top() == 1)
					sprintf(code[nextinstr++],"STA v%d %d",GlobalLineList->VarNum,count);	
				else
					sprintf(code[nextinstr++],"DEC v%d %d",GlobalLineList->VarNum,count);

				$$.sextvars_type = 1;

			}
	| ID COMMA SEXTVARS_COMMA SEXTVARS	{
							
								if ($4.sextvars_type == 0){
									fprintf(stderr,"Wrong definition of members: [Line %d]\n",linecount+1);
									exit(-1);
								}

								$$.sextvars_type = 1;

							}
	| {$$.sextvars_type = 0;}
	;
EXTVARS	: VAR EXTVARS_VAR_ALONE {
								$$.extvars_type = 1;
								}
	| VAR EXTVARS_VAR_ALONE ASSIGN INIT	EXTVARS_VAR_INIT {
										$$.extvars_type = 1;
										}
	| VAR EXTVARS_VAR_ALONE COMMA EXTVARS	{

							if($4.extvars_type == 0){
								fprintf(stderr,"nothing after ',': [Line %d]\n",linecount+1);
								exit(-1);
							}	
							$$.extvars_type = 1;
						}
	| VAR EXTVARS_VAR_ALONE ASSIGN INIT	EXTVARS_VAR_INIT COMMA EXTVARS	{	

							if($7.extvars_type == 0){
								fprintf(stderr,"nothing after ',': [Line %d]\n",linecount+1);
								exit(-1);
							}	
							$$.extvars_type = 1;
						}
	| {	
		$$.extvars_type = 0;
		}
	;
STSPEC	: STRUCT ID STRUCT_DEFINE LC STSPEC_SDEFS SDEFS RC 	{

											$$.members = $3.members;
											$$.stspec_type = 1;
											}
	| STRUCT STRUCT_EMPTY LC STSPEC_SDEFS SDEFS RC	{
								
								$$.members = $2.members;
								$$.stspec_type = 1;
								}
	| STRUCT ID	{

				GlobalLineList = st_lookup($2.name,STR_RECORD,0);

				if (GlobalLineList == NULL){
					fprintf(stderr,"No such struct name: %s [Line %d]\n",$2.name.c_str(),linecount+1);
					exit(-1);
				}

				$$.members = GlobalLineList->members;

				$$.stspec_type = 2;
				}
	;
FUNC	: ID FUNC_ID LP M1 PARAS M3 RP {

									if($1.name == "main"){
										if (main_count == 1){
											fprintf(stderr,"Too many main functions: [Line %d]\n",linecount+1);
											exit(-1);
										}
										else {
											main_count++;
										}
									}
								
									if ($5.paras_type == 0){
										func_insert($1.name,0);
										GlobalLineList = st_lookup($1.name,FUNC_RECORD,0);
										if($1.name == "main")main_label = GlobalLineList->LabNum;


										sprintf(code[nextinstr++],"FUNCTION label%d",GlobalLineList->LabNum);
									}
									else{
										func_insert($1.name,$5.commacount+1);

										GlobalLineList = st_lookup($1.name,FUNC_RECORD,$5.commacount+1);
										if($1.name == "main")main_label = GlobalLineList->LabNum;
										sprintf(code[nextinstr++],"FUNCTION label%d",GlobalLineList->LabNum);

										param temp = param_link;

										while(temp != NULL){
											sprintf(code[nextinstr++],"PARAM v%d",temp->VarNum);
											temp = temp->next;
										}
									}
								}
	;
PARAS	: TYPE ID PARAS_ID COMMA PARAS	{
									
									$$.commacount = $5.commacount + 1;

									$$.paras_type = 1;
									if ($5.paras_type == 0){
										fprintf(stderr,"Blank follow ',': [Line %d]\n",linecount+1);
										exit(-1);
									}
								}
	| TYPE ID PARAS_ID {
					$$.paras_type = 1;
					$$.commacount = 0;
				
				}
	|	{
			$$.paras_type = 0;
		}
	;
STMTBLOCK: LC M1 DEFS STMTS RC M2 {

								$$.nextlist = $4.nextlist;
								$$.breaklist = $4.breaklist;
								$$.continuelist = $4.continuelist;

								$$.has_return = $4.has_return;
						
							
								
							}
	;
STMTS	:  STMT STMT_M1 STMTS 	{
									if($1.nextlist == NULL){
										if($3.stmts_type == 1){
											if($3.nextlist == NULL){
												$$.nextlist = NULL;
											}
											else{
												$$.nextlist = $3.nextlist;
											}
										}
										else{
											$$.nextlist = NULL;
										}
									}
									else{
										if($3.stmts_type == 1){
											backpatch($1.nextlist,$2.instr);
											if($3.nextlist == NULL){
												$$.nextlist = NULL;
											}
											else{
												$$.nextlist = $3.nextlist;
											}
										}
										else{
											nextinstr--;
											$$.nextlist = $1.nextlist;
										}
									}	
			

									$$.breaklist = merge($1.breaklist,$3.breaklist);
									$$.continuelist = merge($1.continuelist,$3.continuelist);

									$$.has_return = $1.has_return | $3.has_return;
								
		
					
								$$.stmts_type = 1;
							}
	| {
		$$.nextlist = NULL;
		$$.breaklist = NULL;
		$$.continuelist = NULL;
		$$.stmts_type = 0;
		$$.has_return = 0;
		}
	;

STMT	: IF LP EXPS EXPS_N2 RP STMT_M STMT1 STMT_N ELSE STMT_M STMT STMT_N	{

							if ($3.exps_type == 1){
								backpatch($3.truelist,$6.instr);
								backpatch($3.falselist,$10.instr);
							}
							else{
								backpatch($4.truelist,$6.instr);
								backpatch($4.falselist,$10.instr);

							}
				
							BackPatchList temp = merge($7.nextlist,$8.nextlist);
							temp = merge(temp,$11.nextlist);
							$$.nextlist = merge(temp,$12.nextlist);

							$$.breaklist = merge($7.breaklist,$11.breaklist);
							$$.continuelist = merge($7.continuelist,$11.continuelist);

							$$.has_return = $7.has_return | $11.has_return;

								}
	| IF LP EXPS EXPS_N2 RP STMT_M STMT STMT_N	{

								BackPatchList temp = merge($7.nextlist,$8.nextlist);


								if ($3.exps_type == 1){
									backpatch($3.truelist,$6.instr);
									$$.nextlist = merge($3.falselist,temp);
								}
								else{
									backpatch($4.truelist,$6.instr);
									$$.nextlist = merge($4.falselist,temp);
								}
								

								$$.breaklist = $7.breaklist;
								$$.continuelist = $7.continuelist;

								$$.has_return = $7.has_return;

							}
	| EXPS SEMI	{
					

					$$.nextlist = NULL;
					$$.breaklist = NULL;
					$$.continuelist = NULL;

					$$.has_return = 0;
		
				}
	| STMTBLOCK	{
				

				$$.nextlist = $1.nextlist;

				$$.breaklist = $1.breaklist;
				$$.continuelist = $1.continuelist;

				$$.has_return = $1.has_return;


			}
	| RETURN EXPS SEMI	{
						

						if ($2.isLeft == 1){
							sprintf(code[nextinstr++],"RETURN *t%d",$2.place);
						}
						else{
							sprintf(code[nextinstr++],"RETURN t%d",$2.place);
						}

						$$.nextlist = NULL;

						$$.breaklist = NULL;
						$$.continuelist = NULL;

						$$.has_return = 1;

					}
	| FOR LP EXP SEMI STMT_M EXP EXPS_N2 STMT_N_1 SEMI STMT_M EXP STMT_N_1 RP STMT_M STMT STMT_N {
					
		BackPatchList temp = NULL;

		if ($6.exps_type == 0){
			temp = merge($7.truelist,$8.nextlist);
		}
		else{
			temp = merge($6.truelist,$8.nextlist);
		}

		
		backpatch(temp,$14.instr);

		temp = merge($15.nextlist,$16.nextlist);
		backpatch(temp,$10.instr);

		if ($15.breaklist != NULL){
			if ($6.exps_type == 0){
				$$.nextlist = merge($7.falselist,$15.breaklist);
			}
			else{
				$$.nextlist = merge($6.falselist,$15.breaklist);
			}
			
		}
		else {
			if ($6.exps_type == 0){
				$$.nextlist = $7.falselist;
			}
			else{
				$$.nextlist = $6.falselist;
			}
			
		}

		if ($15.continuelist != NULL){
			temp = merge($15.continuelist,$12.nextlist);
			backpatch(temp,$5.instr);
		}
		else{
			backpatch($12.nextlist,$5.instr);
		}

		$$.breaklist = NULL;
		$$.continuelist = NULL;

		$$.has_return = $15.has_return;

									
		}
	| CONT SEMI	{
				
				$$.continuelist = makelist(nextinstr);
				$$.breaklist = NULL;

				$$.nextlist = NULL;

				$$.has_return = 0;

				sprintf(code[nextinstr++],"GOTO label_");
				
				}
	| BREAK SEMI	{
					
					$$.breaklist = makelist(nextinstr);
					$$.continuelist = NULL;

					$$.nextlist = NULL;

					$$.has_return = 0;

					sprintf(code[nextinstr++],"GOTO label_");
					
					}

	| WRITE LP EXPS RP SEMI {
			if ($3.isLeft == 1){
				sprintf(code[nextinstr++],"WRITE *t%d",$3.place);
			}
			else{
				sprintf(code[nextinstr++],"WRITE t%d",$3.place);
			}

			$$.nextlist = NULL;
			$$.breaklist = NULL;
			$$.continuelist = NULL;

			$$.has_return = 0;
		}
	| READ LP EXPS RP SEMI {
			if ($3.isLeft == 1){
				sprintf(code[nextinstr++],"READ *t%d",$3.place);
			}
			else{
				fprintf(stderr,"Wrong usage of read(): [Line %d]\n",linecount+1);
				exit(-1);
			}

			$$.nextlist = NULL;
			$$.breaklist = NULL;
			$$.continuelist = NULL;

			$$.has_return = 0;
		}
	;
STMT1	: IF LP EXPS EXPS_N2 RP STMT_M STMT1 STMT_N ELSE STMT_M STMT1 STMT_N	{

							if ($3.exps_type == 1){
								backpatch($3.truelist,$6.instr);
								backpatch($3.falselist,$10.instr);
							}
							else{
								backpatch($4.truelist,$6.instr);
								backpatch($4.falselist,$10.instr);

							}

							BackPatchList temp = merge($7.nextlist,$8.nextlist);
							temp = merge(temp,$11.nextlist);
							$$.nextlist = merge(temp,$12.nextlist);

							$$.breaklist = merge($7.breaklist,$11.breaklist);
							$$.continuelist = merge($7.continuelist,$11.continuelist);

							$$.has_return = $7.has_return | $11.has_return;
					}
	| EXPS SEMI	{

					$$.nextlist = NULL;
					$$.breaklist = NULL;
					$$.continuelist = NULL;

					$$.has_return = 0;
			
				}
	| STMTBLOCK	{

				$$.nextlist = $1.nextlist;

				$$.breaklist = $1.breaklist;
				$$.continuelist = $1.continuelist;

				$$.has_return = $1.has_return;
			}
	| RETURN EXPS SEMI	{

						if ($2.isLeft == 1){
							sprintf(code[nextinstr++],"RETURN *t%d",$2.place);
						}
						else{
							sprintf(code[nextinstr++],"RETURN t%d",$2.place);
						}

						$$.nextlist = NULL;

						$$.breaklist = NULL;
						$$.continuelist = NULL;

						$$.has_return = 1;

					}

		
	| FOR LP EXP SEMI STMT_M EXP EXPS_N2 STMT_N_1 SEMI STMT_M EXP STMT_N_1 RP STMT_M STMT1 STMT_N	{
									

		BackPatchList temp = NULL;

		if ($6.exps_type == 0){
			temp = merge($7.truelist,$8.nextlist);
		}
		else{
			temp = merge($6.truelist,$8.nextlist);
		}

		
		backpatch(temp,$14.instr);

		temp = merge($15.nextlist,$16.nextlist);
		backpatch(temp,$10.instr);

		if ($15.breaklist != NULL){
			if ($6.exps_type == 0){
				$$.nextlist = merge($7.falselist,$15.breaklist);
			}
			else{
				$$.nextlist = merge($6.falselist,$15.breaklist);
			}
			
		}
		else {
			if ($6.exps_type == 0){
				$$.nextlist = $7.falselist;
			}
			else{
				$$.nextlist = $6.falselist;
			}
			
		}

		if ($15.continuelist != NULL){
			temp = merge($15.continuelist,$12.nextlist);
			backpatch(temp,$5.instr);
		}
		else{
			backpatch($12.nextlist,$5.instr);
		}

		$$.breaklist = NULL;
		$$.continuelist = NULL;

		$$.has_return = $15.has_return;

				}
	| CONT SEMI	{
				

				
				$$.continuelist = makelist(nextinstr);
				$$.breaklist = NULL;

				$$.nextlist = NULL;

				$$.has_return = 0;

				sprintf(code[nextinstr++],"GOTO label_");

				
				}
	| BREAK SEMI	{
					
					$$.breaklist = makelist(nextinstr);
					$$.continuelist = NULL;

					$$.nextlist = NULL;

					$$.has_return = 0;

					sprintf(code[nextinstr++],"GOTO label_");

				
					}

	| WRITE LP EXPS RP SEMI {
			if ($3.isLeft == 1){
				sprintf(code[nextinstr++],"WRITE *t%d",$3.place);
			}
			else{
				sprintf(code[nextinstr++],"WRITE t%d",$3.place);
			}

			$$.nextlist = NULL;
			$$.breaklist = NULL;
			$$.continuelist = NULL;

			$$.has_return = 0;
		}
	| READ LP EXPS RP SEMI {
			if ($3.isLeft == 1){
				sprintf(code[nextinstr++],"READ *t%d",$3.place);
			}
			else{
				fprintf(stderr,"Wrong usage of read(): [Line %d]\n",linecount+1);
				exit(-1);
			}

			$$.nextlist = NULL;
			$$.breaklist = NULL;
			$$.continuelist = NULL;

			$$.has_return = 0;
		}
	;

DEFS	: TYPE DECS SEMI DEFS
	| STSPEC SEXTVARS CHECK_SEXTVARS SEMI DEFS	
	| 
	;
SDEFS	: TYPE SDEFS_SDECS SDECS SEMI SDEFS_SEMI SDEFS	
	| 
	;
SDECS	: ID SDECS_ID COMMA SDECS_COMMA SDECS	
	| ID SDECS_ID
	;
DECS	: VAR DECS_VAR_ALONE 
	| VAR DECS_VAR_ALONE COMMA DECS	
	| VAR DECS_VAR_ALONE ASSIGN INIT DECS_VAR_INIT COMMA DECS 
	| VAR DECS_VAR_ALONE ASSIGN INIT DECS_VAR_INIT
	;
VAR	: ID	{
				$$.dimen = 0;
				$$.name = $1.name;
				$$.var_type = 1;
			}
	| VAR LB INT RB	{
						$$.name = $1.name;
						$$.dimen = $1.dimen + 1;
						$$.var_type = 2;

						if ($$.dimen > 2){
							fprintf(stderr, "Dimension exceeded: [line %d]\n", linecount+1);
    						exit(-1);
						}

						switch ($$.dimen){
							case 1: $$.members_1 = $3.value;break;
							case 2: $$.members_2 = $3.value;$$.members_1 = $1.members_1;break;
						}			
					}
	;
INIT 	: EXPS	{

					if ($-2.var_type == 2){
						fprintf(stderr, "Wrong initiation of array: %s [line %d]\n",$-2.name.c_str(),linecount+1);
						exit(1);
					}

					$$.place = $1.place;	
					$$.isLeft = $1.isLeft;
				}
	| INIT_ARGS LC ARGS RC	{

						$$.commacount = $3.commacount;
						$$.exp_type = $3.exp_type;
					}
	;
EXP	: EXPS	{
				
				$$.place = $1.place;
				$$.isLeft = $1.isLeft;
				$$.exp_type = 1;

				$$.truelist = $1.truelist;
				$$.falselist = $1.falselist;
				$$.exps_type = $1.exps_type;


			}
	|		{

				$$.truelist = NULL;
				$$.falselist = NULL;

				$$.exp_type = 0;
				$$.exps_type = 2;
			}
	;
EXPS	: MINUS EXPS %prec PRODUCT	{
						

						$$.place = newtemp();

						if ($2.isLeft == 1){
							sprintf(code[nextinstr++],"t%d := - *t%d",$$.place,$2.place);
						}
						else{
							sprintf(code[nextinstr++],"t%d := - t%d",$$.place,$2.place);
						}
						$$.isLeft = 0;
						$$.exps_type = 0;
					}

	| LOGICNOT EXPS	{
						

						BackPatchList temp_true = NULL;
						BackPatchList temp_false = NULL;

						if ($2.exps_type == 0){
							int next = nextinstr;
							temp_false = makelist(next);
							temp_true = makelist(next+1);

							if ($2.isLeft == 1){
								sprintf(code[next],"IF *t%d == #0 GOTO label_",$2.place);
							}
							else{
								sprintf(code[next],"IF t%d == #0 GOTO label_",$2.place);
							}
							sprintf(code[next+1],"GOTO label_");
					
							nextinstr+=2;	
						}

						if ($2.exps_type == 0){
							$$.truelist = temp_false;
							$$.falselist = temp_true;
						}
						else{
							$$.truelist = $2.falselist;
							$$.falselist = $2.truelist;
						}

						
						$$.exps_type = 1;
						
					}
	| PREINCRE EXPS	{

						//++a can be a left value, but a++ can't						

						$$.place = newtemp();

						if ($2.isLeft == 1){
							sprintf(code[nextinstr++],"*t%d := *t%d + #1",$2.place,$2.place);
							sprintf(code[nextinstr++],"t%d := t%d",$$.place,$2.place);
						}
						else{
							fprintf(stderr," lvalue required as increment operand: [line %d]\n",linecount+1);
							exit(1);
						}
						$$.isLeft = 1;
						$$.exps_type = 0;
					}
	| EXPS PREINCRE	{
						

						$$.place = newtemp();

						if ($1.isLeft == 1){
							sprintf(code[nextinstr++],"t%d := *t%d",$$.place,$1.place);
							sprintf(code[nextinstr++],"*t%d := *t%d + #1",$1.place,$1.place);
						}
						else{
							fprintf(stderr," lvalue required as increment operand: [line %d]\n",linecount+1);
							exit(1);
						}
						$$.isLeft = 0;
						$$.exps_type = 0;					

					}
	| PREDEC EXPS	{

						//--a can be a left value, but a-- can't						

						$$.place = newtemp();

						if ($2.isLeft == 1){
							sprintf(code[nextinstr++],"*t%d := *t%d - #1",$2.place,$2.place);
							sprintf(code[nextinstr++],"t%d := t%d",$$.place,$2.place);
						}
						else{
							fprintf(stderr," lvalue required as increment operand: [line %d]\n",linecount+1);
							exit(1);
						}
						$$.isLeft = 1;
						$$.exps_type = 0;
					}
	| EXPS PREDEC	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							sprintf(code[nextinstr++],"t%d := *t%d",$$.place,$1.place);
							sprintf(code[nextinstr++],"*t%d := *t%d - #1",$1.place,$1.place);
						}
						else{
							fprintf(stderr," lvalue required as increment operand: [line %d]\n",linecount+1);
							exit(1);
						}
						$$.isLeft = 0;
					
						$$.exps_type = 0;
					}
	| BITNOT EXPS	{

						$$.place = newtemp();

						if ($2.isLeft == 1){
							sprintf(code[nextinstr++],"t%d := ~ *t%d",$$.place,$2.place);
						}
						else{
							sprintf(code[nextinstr++],"t%d := ~ t%d",$$.place,$2.place);
						}
						$$.isLeft = 0;
						$$.exps_type = 0;					

					}
	| EXPS PRODUCT EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d * *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d * t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d * *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d * t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS DIVISION EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d / *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d / t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d / *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d / t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS MODULUS EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d %% *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d %% t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d %% *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d %% t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS PLUS EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d + *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d + t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d + *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d + t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS MINUS EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d - *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d - t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d - *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d - t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS SHIFTLEFT EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d << *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d << t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d << *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d << t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS SHIFTRIGHT EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d >> *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d >> t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d >> *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d >> t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| EXPS GREATERT EXPS	{
				int next = nextinstr;

				$$.truelist = makelist(next);
				$$.falselist = makelist(next+1);

				if ($1.isLeft == 1){
					if ($3.isLeft == 1){
						sprintf(code[next],"IF *t%d > *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF *t%d > t%d GOTO label_",$1.place,$3.place);
					}
				}
				else{
					if ($3.isLeft == 1){
						sprintf(code[next],"IF t%d > *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF t%d > t%d GOTO label_",$1.place,$3.place);	
					}
				}
				sprintf(code[next+1],"GOTO label_");

				nextinstr+=2;

				$$.exps_type = 1;

						}
	| EXPS LESST EXPS	{
				
				int next = nextinstr;

				$$.truelist = makelist(next);
				$$.falselist = makelist(next+1);

				if ($1.isLeft == 1){
					if ($3.isLeft == 1){
						sprintf(code[next],"IF *t%d < *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF *t%d < t%d GOTO label_",$1.place,$3.place);
					}
				}
				else{
					if ($3.isLeft == 1){
						sprintf(code[next],"IF t%d < *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF t%d < t%d GOTO label_",$1.place,$3.place);	
					}
				}
				sprintf(code[next+1],"GOTO label_");

				nextinstr+=2;

				$$.exps_type = 1;

						}
	| EXPS NOTLESST EXPS	{

				int next = nextinstr;

				$$.truelist = makelist(next);
				$$.falselist = makelist(next+1);

				if ($1.isLeft == 1){
					if ($3.isLeft == 1){
						sprintf(code[next],"IF *t%d >= *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF *t%d >= t%d GOTO label_",$1.place,$3.place);
					}
				}
				else{
					if ($3.isLeft == 1){
						sprintf(code[next],"IF t%d >= *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF t%d >= t%d GOTO label_",$1.place,$3.place);	
					}
				}
				sprintf(code[next+1],"GOTO label_");

				nextinstr+=2;

				$$.exps_type = 1;



						}
	| EXPS NOTGREATERT EXPS	{

				int next = nextinstr;

				$$.truelist = makelist(next);
				$$.falselist = makelist(next+1);

				if ($1.isLeft == 1){
					if ($3.isLeft == 1){
						sprintf(code[next],"IF *t%d <= *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF *t%d <= t%d GOTO label_",$1.place,$3.place);
					}
				}
				else{
					if ($3.isLeft == 1){
						sprintf(code[next],"IF t%d <= *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF t%d <= t%d GOTO label_",$1.place,$3.place);	
					}
				}
				sprintf(code[next+1],"GOTO label_");

				nextinstr+=2;

				$$.exps_type = 1;



						}
	| EXPS EQUAL EXPS	{

				int next = nextinstr;

				$$.truelist = makelist(next);
				$$.falselist = makelist(next+1);

				if ($1.isLeft == 1){
					if ($3.isLeft == 1){
						sprintf(code[next],"IF *t%d == *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF *t%d == t%d GOTO label_",$1.place,$3.place);
					}
				}
				else{
					if ($3.isLeft == 1){
						sprintf(code[next],"IF t%d == *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF t%d == t%d GOTO label_",$1.place,$3.place);	
					}
				}
				sprintf(code[next+1],"GOTO label_");

				nextinstr+=2;

				$$.exps_type = 1;

						}
	| EXPS NOTEQUAL EXPS	{

				int next = nextinstr;

				$$.truelist = makelist(next);
				$$.falselist = makelist(next+1);

				if ($1.isLeft == 1){
					if ($3.isLeft == 1){
						sprintf(code[next],"IF *t%d != *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF *t%d != t%d GOTO label_",$1.place,$3.place);
					}
				}
				else{
					if ($3.isLeft == 1){
						sprintf(code[next],"IF t%d != *t%d GOTO label_",$1.place,$3.place);
					}
					else{
						sprintf(code[next],"IF t%d != t%d GOTO label_",$1.place,$3.place);	
					}
				}
				sprintf(code[next+1],"GOTO label_");

				nextinstr+=2;

				$$.exps_type = 1;



						}
	| EXPS BITAND EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d & *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d & t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d & *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d & t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;


						}
	| EXPS BITXOR EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d ^ *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d ^ t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d ^ *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d ^ t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;


						}
	| EXPS BITOR EXPS	{

						$$.place = newtemp();

						if ($1.isLeft == 1){
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := *t%d | *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := *t%d | t%d",$$.place,$1.place,$3.place);
							}
						}
						else{
							if ($3.isLeft == 1){
								sprintf(code[nextinstr++],"t%d := t%d | *t%d",$$.place,$1.place,$3.place);
							}
							else{
								sprintf(code[nextinstr++],"t%d := t%d | t%d",$$.place,$1.place,$3.place);
							}
						}
						$$.isLeft = 0;

						$$.exps_type = 0;


						}
	|  EXPS LOGICAND EXPS_N STMT_M EXPS	{

							BackPatchList temp_true = NULL;
							BackPatchList temp_false = NULL;

							if ($5.exps_type == 0){
								int next = nextinstr;
								temp_true = makelist(next+1);
								temp_false = makelist(next);

								if ($5.isLeft == 1){
									sprintf(code[next],"IF *t%d == #0 GOTO label_",$5.place);
								}
								else{
									sprintf(code[next],"IF t%d == #0 GOTO label_",$5.place);
								}
								sprintf(code[next+1],"GOTO label_");
						
								nextinstr+=2;	
							}

							if ($1.exps_type == 0){
								backpatch($3.truelist,$4.instr);
								if($5.exps_type == 0){
									$$.truelist = temp_true;
									$$.falselist = merge($3.falselist,temp_false);
								}
								else{
									$$.truelist = $5.truelist;
									$$.falselist = merge($3.falselist,$5.falselist);
								}
							}
							else{
								backpatch($1.truelist,$4.instr);
								if($5.exps_type == 0){
									$$.truelist = temp_true;
									$$.falselist = merge($1.falselist,temp_false);
								}
								else{
									$$.truelist = $5.truelist;
									$$.falselist = merge($1.falselist,$5.falselist);
								}
							}

							$$.exps_type = 1;
			
						}
	|  EXPS LOGICOR EXPS_N STMT_M EXPS	{

							BackPatchList temp_true = NULL;
							BackPatchList temp_false = NULL;

							if ($5.exps_type == 0){
								int next = nextinstr;
								temp_true = makelist(next+1);
								temp_false = makelist(next);

								if ($5.isLeft == 1){
									sprintf(code[next],"IF *t%d == #0 GOTO label_",$5.place);
								}
								else{
									sprintf(code[next],"IF t%d == #0 GOTO label_",$5.place);
								}
								sprintf(code[next+1],"GOTO label_");
						
								nextinstr+=2;	
							}

							if ($1.exps_type == 0){
								backpatch($3.falselist,$4.instr);
								if($5.exps_type == 0){
									$$.falselist = temp_false;
									$$.truelist = merge($3.truelist,temp_true);
								}
								else{
									$$.falselist = $5.falselist;
									$$.truelist = merge($3.truelist,$5.truelist);
								}
							}
							else{
								backpatch($1.falselist,$4.instr);
								if($5.exps_type == 0){
									$$.falselist = temp_false;
									$$.truelist = merge($1.truelist,temp_true);
								}
								else{
									$$.falselist = $5.falselist;
									$$.truelist = merge($1.truelist,$5.truelist);
								}
							}

							$$.exps_type = 1;

					}
	| EXPS ASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d",$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := t%d",$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS PLUSASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d + *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d + t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS MINUSASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d - *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d - t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS PRODUCTASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d * *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d * t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS DIVISIONASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d / *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d / t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS ANDASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d & *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d & t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS NORASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d ^ *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d ^ t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS ORASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d | *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d | t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS SLASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d << *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d << t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| EXPS SRASSIGN EXPS	{

							//left value error
							if($1.isLeft == 0){
								fprintf(stderr,"Left value error: [line %d]\n",linecount+1);
								exit(1);
							}

							
							if ($1.isLeft == 1){
								if ($3.isLeft == 1){
									sprintf(code[nextinstr++],"*t%d := *t%d >> *t%d",$1.place,$1.place,$3.place);
								}
								else{
									sprintf(code[nextinstr++],"*t%d := *t%d >> t%d",$1.place,$1.place,$3.place);
								}
							}

							$$.isLeft = 1;
							$$.place = $1.place;

							$$.exps_type = 0;
						}
	| LP EXPS RP	{
						$$.place = $2.place;
						$$.isLeft = $2.isLeft;

	
						$$.truelist = $2.truelist;
						$$.falselist = $2.falselist;

						$$.exps_type = $2.exps_type;
					}
	| ID EXPS_ARGS LP ARGS RP	{
						//count the paraNum of ARGS here 

						int args_count;
						if ($4.exp_type == 1)
							args_count = $4.commacount+1;
						else
							args_count = 0;
						

						GlobalLineList = st_lookup($1.name,FUNC_RECORD,args_count);

						if (GlobalLineList == NULL){
							fprintf(stderr,"Undefined function: %s [line %d]\n",$1.name.c_str(),linecount+1);
							exit(1);
						}

						
						if (GlobalLineList->LabNum == main_label){
							fprintf(stderr,"Illegal call of main function: [line %d]\n",linecount+1);
							exit(1);

						}

						$$.place = newtemp();

						if ($4.exp_type == 1){

							args_unit temp = args_link;

							while(temp->next != NULL){
								temp = temp->next;
							}

							
							while(args_count != 0){
								if (temp->isLeft == 1){
									sprintf(code[nextinstr++],"ARG *t%d",temp->place);
								}
								else{
									sprintf(code[nextinstr++],"ARG t%d",temp->place);
								}
								temp = temp->prev;
								delete_args_unit();
								args_count--;
							}
						}

						sprintf(code[nextinstr++],"t%d := CALL label%d",$$.place,GlobalLineList->LabNum);
					
						$$.isLeft = 0;

						$$.exps_type = 0;
					}
	| ID ARRS	{
					
					$$.isLeft = 1;

					$$.exps_type = 0;

					//is variable
					if ($2.arrs_type == 1){
						GlobalLineList = st_lookup($1.name, VAR_RECORD,0);

						if (GlobalLineList == NULL){
							fprintf(stderr,"Undefined variable: %s [line %d]\n",$1.name.c_str(),linecount+1);
							exit(1);
						}

						$$.place = newtemp();
						sprintf(code[nextinstr++],"t%d := &v%d",$$.place,GlobalLineList->VarNum);
					}

					//is array
					if ($2.arrs_type == 2){
						
						GlobalLineList = st_lookup($1.name, ARR_RECORD,0);

						//check whether exist
						if (GlobalLineList == NULL){
							fprintf(stderr,"Undefined array: %s [line %d]\n",$1.name.c_str(),linecount+1);
							exit(1);
						}

						//check dimension
						if ($2.dimen > GlobalLineList->dimen){
							fprintf(stderr,"Dimension exceeded: [line %d]\n",linecount+1);
							exit(1);
						}

						//calculate the final memory location, and return it
						
						$$.place = newtemp();
						int temp_1 = newtemp();

						switch ($2.dimen){
							case 1:{
									if ($2.isleft_1 == 1){
										sprintf(code[nextinstr++],"t%d := *t%d * #4",temp_1,$2.place_1);
									}
									else{
										sprintf(code[nextinstr++],"t%d := t%d * #4",temp_1,$2.place_1);
									}

									sprintf(code[nextinstr++],"t%d := &v%d + t%d",$$.place,GlobalLineList->VarNum,temp_1);
									break;}
							case 2:{
									int offset = newtemp();

									if ($2.isleft_1 == 1){
										sprintf(code[nextinstr++],"t%d := *t%d * #%d",offset,$2.place_1,GlobalLineList->members_2);
										sprintf(code[nextinstr++],"t%d := t%d * #4",offset,offset);
										if ($2.isleft_2 == 1){
											sprintf(code[nextinstr++],"t%d := *t%d * #4",temp_1,$2.place_2);
										}
										else{
											sprintf(code[nextinstr++],"t%d := t%d * #4",temp_1,$2.place_2);
										}
									}
									else{
										sprintf(code[nextinstr++],"t%d := t%d * #%d",offset,$2.place_1,GlobalLineList->members_2);
										sprintf(code[nextinstr++],"t%d := t%d * #4",offset,offset);
										if ($2.isleft_2 == 1){
											sprintf(code[nextinstr++],"t%d := *t%d * #4",temp_1,$2.place_2);
										}
										else{
											sprintf(code[nextinstr++],"t%d := t%d * #4",temp_1,$2.place_2);
										}
									}

									sprintf(code[nextinstr++],"t%d := t%d + t%d",offset,offset,temp_1);
									sprintf(code[nextinstr++],"t%d := &v%d + t%d",$$.place,GlobalLineList->VarNum,offset);
									
									break;}
	
						}
					}
				}
	| ID DOT ID	{

					$$.isLeft = 1;
					$$.place = newtemp();

					$$.exps_type = 0;

					GlobalLineList = st_lookup($1.name, STR_BUILD_RECORD,0);

					if (GlobalLineList == NULL){
						fprintf(stderr,"No such struct: %s [line %d]\n",$1.name.c_str(),linecount+1);
						exit(1);
					}
		
					sprintf(code[nextinstr++],"t%d := &v%d",$$.place,GlobalLineList->VarNum);

					StructMember temp = GlobalLineList->members;

					int index = 0;
					while(temp != NULL){
						if (temp->name == $3.name){
							index = temp->index;
							break;
						}
						temp = temp->next;
					}

					if (temp == NULL){
						fprintf(stderr,"No such struct member: %s [line %d]\n",$3.name.c_str(),linecount+1);
						exit(1);
					}

					if (index > 0){
						sprintf(code[nextinstr++],"t%d := t%d + #%d",$$.place,$$.place,index);
					}
					
			}
	| INT 	{
				if ($1.value >= -2147483648 && $1.value < 0){
					fprintf(stderr,"Range Exceeded: [line %d]\n",linecount+1);
					exit(1);
				}
				else{

					$$.isLeft = 0;

					$$.exps_type = 0;
					$$.place = newtemp();
					sprintf(code[nextinstr++],"t%d := #%d",$$.place,$1.value);				
				}
			}
	;
ARRS	: LB EXPS RB ARRS	{
								
								$$.dimen = $4.dimen + 1;

								if ($$.dimen > 2){
									fprintf(stderr,"Wrong dimension of array: [line %d]\n",linecount+1);
									exit(1);
								}
								
								
								switch ($$.dimen){
									case 1: {
											
											$$.place_1 = $2.place;
											$$.isleft_1 = $2.isLeft;
											break;}
									case 2: {
											$$.place_2 = $4.place_1;
											$$.isleft_2 = $4.isleft_1;
											$$.place_1 = $2.place;
											$$.isleft_1 = $2.isLeft;
											break;}
								}						
								$$.arrs_type = 2;
							}
	|	{
		
			$$.dimen = 0;	
			$$.arrs_type = 1;
		}
	;
ARGS	: EXP ARGS_COMMA COMMA  ARGS	{
										
										$$.commacount = $4.commacount + 1;
										
										if ($1.exp_type == 0 || $4.exp_type == 0){
											fprintf(stderr, "Blank between ','s: [line %d]\n", linecount+1);
											exit(1);
										}
										$$.exp_type = 1;
									}
	| EXP ARGS_COMMA {

				$$.commacount = 0;
				$$.exp_type = $1.exp_type;
			}
	;



EXTVARS_VAR_ALONE :{

					//VAR is variable
					if ($0.var_type == 1){
						var_insert($0.name);
						GlobalLineList = st_lookup($0.name,VAR_RECORD,0);
						sprintf(code[nextinstr++],"STA v%d 4",GlobalLineList->VarNum);
					}
						
					//VAR is array
					if ($0.var_type == 2){
						
						arr_insert($0.name,$0.dimen, $0.members_1, $0.members_2);
						
						GlobalLineList = st_lookup($0.name,ARR_RECORD,0);

						int len;						
						switch ($0.dimen){
							case 1:len = $0.members_1 * INT_SIZE;break;
							case 2:len = $0.members_1 * $0.members_2 * INT_SIZE;break;
						}

						sprintf(code[nextinstr++],"STA v%d %d",GlobalLineList->VarNum,len);
						
						//prepare for initiation
						$$.arraytop = GlobalLineList->VarNum;
						$$.arrayoffset = 0;

						
					}
					
				}
		;

EXTVARS_VAR_INIT :{
					
					//VAR is variable
					if ($-3.var_type == 1){
		
						GlobalLineList = st_lookup($-3.name,VAR_RECORD,0);
		
						//INIT is rigth value
						if ($0.isLeft == 0){
							sprintf(code[nextinstr++], "v%d := t%d",GlobalLineList->VarNum,$0.place);
						}
						else{
							sprintf(code[nextinstr++], "v%d := *t%d",GlobalLineList->VarNum,$0.place);
						}
		
					}
		
					//VAR is array
					if ($-3.var_type == 2){
						
						//too many elements
						if (($0.commacount + 1) > $-3.members_1){
							fprintf(stderr, "Too many elements of array to initiate: [line %d]\n", linecount+1);
		    						exit(1);
						}

						if ($0.commacount == 0 && $0.exp_type == 0){
							fprintf(stderr, "Too few elements of array to initiate: [line %d]\n", linecount+1);
	    					exit(1);
						}
					}
				}
		;

INIT_ARGS :{

			if ($-2.var_type == 1){
				fprintf(stderr, "Wrong initiation of variable: %s [line %d]\n",$-2.name.c_str(),linecount+1);
				exit(1);
			}

			if ($-2.dimen >= 2){
				fprintf(stderr, "Wrong initiation of array: %s [line %d]\n",$-2.name.c_str(),linecount+1);
				exit(1);
			}
			
			//such as int s[0][2], it's leagal, but can not assign
			if ($-2.dimen == 2 && $-2.members_1 == 0){
				fprintf(stderr, "Too many initializers: [line %d]\n",linecount+1);
				exit(1);
			}
		
			$$.arraytop = $-1.arraytop;
			$$.arrayoffset = $-1.arrayoffset;
			$$.args_type = 0;
		}
	;

ARGS_COMMA:{
				if ($-2.args_type == 1 ){
					if ($0.exp_type == 1)
						add_args_unit($0.place, $0.isLeft);
					$$.args_type = 1;
				}
				else {
					int temp = newtemp();
					sprintf(code[nextinstr++],"t%d := &v%d",temp,$-2.arraytop);
					sprintf(code[nextinstr++],"t%d := t%d + #%d",temp,temp,$-2.arrayoffset);	
				
					if ($0.isLeft == 0){
						sprintf(code[nextinstr++],"*t%d := t%d",temp,$0.place);
					}
					else {
						sprintf(code[nextinstr++],"*t%d := *t%d",temp,$0.place);
					}

					$$.arraytop = $-2.arraytop;
					$$.arrayoffset = $-2.arrayoffset + 4;
				}	
				
			}
	;
	
DECS_VAR_ALONE: {


			//VAR is variable
			if ($0.var_type == 1){
				var_insert($0.name);
				GlobalLineList = st_lookup($0.name,VAR_RECORD,0);
				sprintf(code[nextinstr++],"DEC v%d 4",GlobalLineList->VarNum);
			}
				
			//VAR is array
			if ($0.var_type == 2){
				
				arr_insert($0.name,$0.dimen, $0.members_1, $0.members_2);
				
				GlobalLineList = st_lookup($0.name,ARR_RECORD,0);

				int len;						
				switch ($0.dimen){
					case 1:len = $0.members_1 * INT_SIZE;break;
					case 2:len = $0.members_1 * $0.members_2 * INT_SIZE;break;
				}

				sprintf(code[nextinstr++],"DEC v%d %d",GlobalLineList->VarNum,len);
				
				//prepare for initiation
				$$.arraytop = GlobalLineList->VarNum;
				$$.arrayoffset = 0;
			}
			
	}
	;
DECS_VAR_INIT: {
					
					//VAR is variable
					if ($-3.var_type == 1){
		
						GlobalLineList = st_lookup($-3.name,VAR_RECORD,0);
		
						//INIT is rigth value
						if ($0.isLeft == 0){
							sprintf(code[nextinstr++], "v%d := t%d",GlobalLineList->VarNum,$0.place);
						}
						else{
							sprintf(code[nextinstr++], "v%d := *t%d",GlobalLineList->VarNum,$0.place);
						}
		
					}
		
					//VAR is array
					if ($-3.var_type == 2){
						
						//too many elements
						if (($0.commacount + 1) > $-3.members_1){
							fprintf(stderr, "Too many elements of array to initiate: [line %d]\n", linecount+1);
		    						exit(1);
						}

						if ($0.commacount == 0 && $0.exp_type == 0){
							fprintf(stderr, "Too few elements of array to initiate: [line %d]\n", linecount+1);
	    					exit(1);
						}
					}
			
	}
	;

SEXTVARS_COMMA :{

			str_build_insert($-1.name, $-2.members);
			$$.members = $-2.members;

			GlobalLineList = st_lookup($-1.name,STR_BUILD_RECORD,0);

			StructMember temp = GlobalLineList->members;

			int count = 0;
		
			while (temp != NULL){
				count+=4;
				temp = temp->next;
			}

			if (parent_top() == 1)
					sprintf(code[nextinstr++],"STA v%d %d",GlobalLineList->VarNum,count);	
				else
					sprintf(code[nextinstr++],"DEC v%d %d",GlobalLineList->VarNum,count);
		}
	;
STRUCT_DEFINE :{

			str_def_insert($0.name);

			GlobalLineList = st_lookup($0.name,STR_RECORD,0);
			
			$$.members = GlobalLineList->members;

		}
	;

STSPEC_SDEFS :{

			$$.members = $-1.members;

		}
	;
STRUCT_EMPTY:{

			$$.members = new struct StructMemberRec;
			$$.members->next = NULL;
		}
	;

SDEFS_SEMI :{
			$$.members = $-2.members;
		}
	;

SDEFS_SDECS : {
			$$.members = $-1.members;

		}
	;

SDECS_ID: {
			

			StructMember temp = $-1.members;

			if (temp->next == NULL && temp->name.length() == 0){
				temp->name = $0.name;
				temp->index = 0;
			}
			else{
				int index = 4;

				while (temp->next != NULL){
					if (temp->name == $0.name){
						fprintf(stderr,"Multiple define of members: [Line %d]\n",linecount + 1);
						exit(-1);
					}
					temp = temp->next;
					index += 4;
				}

			
				temp->next = new struct StructMemberRec;
				temp->next->name = $0.name;
				temp->next->index = index;
				temp->next->next = NULL;
			}

			$$.members = $-1.members;
		}
	;

SDECS_COMMA: {
			$$.members = $-1.members;
		}
	;

CHECK_SEXTVARS: {
			if ($0.sextvars_type == 0){
				fprintf(stderr,"wrong definition of struct: [Line %d]\n",linecount+1);
				exit(-1);
			}
		}
	;

FUNC_ID: {
			renew_param_link();
		}
	;

PARAS_ID: {
			var_insert($0.name);

			GlobalLineList = st_lookup($0.name,VAR_RECORD,0);

			add_param(GlobalLineList->VarNum);
		}
	;

EXPS_ARGS :{

			$$.args_type = 1;
		}
	;

STMT_M :{

		$$.instr = nextinstr++;

		}
	;

STMT_M1 :{
		
		if ($0.nextlist != NULL)
			$$.instr = nextinstr++;

		}
	;

STMT_N :{

		if ($0.nextlist == NULL){
			$$.nextlist = makelist(nextinstr);
			sprintf(code[nextinstr++],"GOTO label_");
		}
		else
			$$.nextlist = NULL;
		}
	;

STMT_N_1 :{

		if ($0.truelist == NULL && $0.falselist == NULL){
			$$.nextlist = makelist(nextinstr);
			sprintf(code[nextinstr++],"GOTO label_");
		}
		else
			$$.nextlist = NULL;
		}
	;

EXPS_N:{

		if ($-1.exps_type == 0){
			int next = nextinstr;
			$$.truelist = makelist(next+1);
			$$.falselist = makelist(next);

			if ($-1.isLeft == 1){
				sprintf(code[next],"IF *t%d == #0 GOTO label_",$-1.place);
			}
			else{
				sprintf(code[next],"IF t%d == #0 GOTO label_",$-1.place);
			}
			sprintf(code[next+1],"GOTO label_");
						
			nextinstr+=2;	
		}

		}
	;

EXPS_N2:{

		if ($0.exps_type == 0){
			int next = nextinstr;
			$$.truelist = makelist(next+1);
			$$.falselist = makelist(next);

			if ($0.isLeft == 1){
				sprintf(code[next],"IF *t%d == #0 GOTO label_",$0.place);
			}
			else{
				sprintf(code[next],"IF t%d == #0 GOTO label_",$0.place);
			}
			sprintf(code[next+1],"GOTO label_");
						
			nextinstr+=2;	
		}

	}
	;


M1 : {parent_push(++SCOPE);}
	;
M2 : {parent_pop();}
	;
M3 : {SCOPE--;parent_pop();}
	;
	
%%    

/***********************************************************************************************

										MAIN FUNCTION

***********************************************************************************************/
int main(int argc, char *argv[]){

	yyin = fopen(argv[1], "r");
    if (yyin == 0){
        fprintf(stderr, "failed to open %s for reading", argv[1]);
        exit(1);
    }

	InterCode = fopen("InterCode","w");
	if (InterCode == 0){
        fprintf(stderr, "failed to open \"InterCode\" for writing\n");
        exit(1);
    }

	initialHashTable();
	initParentTable();
	parent_push(SCOPE);

	yyparse();

	if (main_count == 0){
		fprintf(stderr, "You need a main funciton!\n");
        exit(1);
	}

	codeOptimize();

	copyCode();

	fclose(yyin);
	fclose(InterCode);
	
	codeGenerate();

	return 0;
}

/*Print the error*/
static void print_tok(){
	if(yychar<255){
		fprintf(stderr, "%c", yychar);
	}
	else{
		fprintf(stderr," %s",yytext);
	}
}

/*Error handling*/
void yyerror(const char* s){
	fprintf(stderr,"[line %d]:%s",linecount+1,s);
	print_tok();
}




/**************************************MAIN FUNCTION END*******************************************/



/**************************************************************************************************

											SYMBOL TABLE

**************************************************************************************************/

void var_insert(string name){ 

	if (st_check_scope(name,VAR_RECORD,0)!= NULL){
		fprintf(stderr, "Multiple define: [line %d]\n", linecount+1);
		exit(1);
	}
	else {
		int h = hash(name);
		BucketList l =  hashTable[h]; 
		int k = h;
		while ((l != NULL) && (name != l->name)){
			k++;
			if ((k%SIZE) == h){
				cout<<"Can not insert var symbol "<<name<<"in line ["<<linecount<<"]\n"<<endl;
				return;		
			}		
			l = hashTable[k%SIZE];
		}

		/* variable not yet in table */
		if (l == NULL){ 
			l = new struct BucketListRec;
			l->name = name;
			l->lines = new struct LineListRec;
			l->lines->scope = parent_top();
			l->lines->VarNum = VarCounter++;
			l->lines->type = VAR_RECORD;
			l->lines->next = NULL;

			hashTable[k%SIZE] = l;
		}

		/* found in table, so just add scope */
		else{
			LineList temp = new struct LineListRec;
			temp->scope = parent_top();
			temp->VarNum = VarCounter++;
			temp->type = VAR_RECORD;
			temp->next = l->lines;
			l->lines = temp;
		}
	}
} /* var_insert */

void func_insert( string name,int paraNum){ 

	if (st_check_scope(name,FUNC_RECORD,paraNum)!= NULL){
		fprintf(stderr, "Multiple define: [line %d]\n", linecount+1);
		exit(1);
	}
	else {
		int h = hash(name);
		BucketList l =  hashTable[h]; 
		int k = h;
		while ((l != NULL) && (name != l->name)){
			k++;
			if ((k%SIZE) == h){
				cout<<"Can not insert func symbol "<<name<<"in line ["<<linecount<<"]\n"<<endl;
				return;		
			}		
			l = hashTable[k%SIZE];
		}
		/* variable not yet in table */
		if (l == NULL){ 
			l = new struct BucketListRec;
			l->name = name;
			l->lines = new struct LineListRec;
			l->lines->scope = parent_top();
			l->lines->son_scope = SCOPE + 1;
			l->lines->LabNum = LabCounter++;
			l->lines->paraNum = paraNum;
			l->lines->type = FUNC_RECORD;
			l->lines->next = NULL;
		
			hashTable[k%SIZE] = l;
		}

		/* found in table, so just add scope */
		else{ 
			LineList temp = new struct LineListRec;
			temp->scope = parent_top();
			temp->son_scope = SCOPE + 1;
			temp->LabNum = LabCounter++;
			temp->paraNum = paraNum;
			temp->type = FUNC_RECORD;
			temp->next = l->lines;
			l->lines = temp;
		}
	}
} /* func_insert */

void arr_insert( string name, int dimen, int members_1,int members_2){ 

	if (st_check_scope(name,ARR_RECORD,0) != NULL){
		fprintf(stderr, "Multiple define: [line %d]\n", linecount+1);
		exit(1);
	}
	else {
		int h = hash(name);
		BucketList l =  hashTable[h]; 
		int k = h;
		while ((l != NULL) && (name != l->name)){
			k++;
			if ((k%SIZE) == h){
				cout<<"Can not insert arr symbol "<<name<<"in line ["<<linecount<<"]\n"<<endl;
				return;		
			}		
			l = hashTable[k%SIZE];
		}
		/* variable not yet in table */
		if (l == NULL){ 
			l = new struct BucketListRec;
			l->name = name;
			l->lines = new struct LineListRec;
			l->lines->scope = parent_top();
			l->lines->VarNum = VarCounter++;
			l->lines->dimen = dimen;
			l->lines->members_1 = members_1;
			l->lines->members_2 = members_2;
			l->lines->type = ARR_RECORD;
			l->lines->next = NULL;
		
			hashTable[k%SIZE] = l;
		}

		/* found in table, so just add scope */
		else{
			LineList temp = new struct LineListRec;
			temp->scope = parent_top();
			temp->VarNum = VarCounter++;
			temp->dimen = dimen;
			temp->members_1 = members_1;
			temp->members_2 = members_2;
			temp->type = ARR_RECORD;
			temp->next = l->lines;
			l->lines = temp;
		}
	}
} /* arr_insert */


void str_def_insert(string name){ 
	
	if (st_check_scope(name,STR_RECORD,0) != NULL){
		fprintf(stderr, "Multiple define: [line %d]\n", linecount+1);
		exit(1);
	}
	else {	
	
		int h = hash(name);
		BucketList l =  hashTable[h]; 
		int k = h;
		while ((l != NULL) && (name != l->name)){
			k++;
			if ((k%SIZE) == h){
				cout<<"Can not insert str symbol "<<name<<"in line ["<<linecount<<"]\n"<<endl;
				return;		
			}		
			l = hashTable[k%SIZE];
		}
		/* variable not yet in table */
		if (l == NULL){ 
			l = new struct BucketListRec;
			l->name = name;
			l->lines = new struct LineListRec;
			l->lines->scope = parent_top();
			l->lines->VarNum = VarCounter++;
			l->lines->type = STR_RECORD;
			l->lines->members = new struct StructMemberRec;
			l->lines->members->next = NULL;
			l->lines->next = NULL;
		
			hashTable[k%SIZE] = l;
		}

		/* found in table, so just add scope */
		else{
			LineList temp = new struct LineListRec;
			temp->scope = parent_top();
			temp->VarNum = VarCounter++;
			temp->type = STR_RECORD;
			temp->members = new struct StructMemberRec;
			temp->members->next = NULL;
			temp->next = l->lines;
			l->lines = temp;
		}
	}
} /* str_insert */


void str_build_insert(string name,StructMember members){
	if (st_check_scope(name,STR_BUILD_RECORD,0) != NULL){
		fprintf(stderr, "Multiple define: [line %d]\n", linecount+1);
		exit(1);
	}
	else {	
	
		int h = hash(name);
		BucketList l =  hashTable[h]; 
		int k = h;
		while ((l != NULL) && (name != l->name)){
			k++;
			if ((k%SIZE) == h){
				cout<<"Can not insert str symbol "<<name<<"in line ["<<linecount<<"]\n"<<endl;
				return;		
			}		
			l = hashTable[k%SIZE];
		}
		/* variable not yet in table */
		if (l == NULL){ 
			l = new struct BucketListRec;
			l->name = name;
			l->lines = new struct LineListRec;
			l->lines->scope = parent_top();
			l->lines->VarNum = VarCounter++;
			l->lines->type = STR_BUILD_RECORD;
			l->lines->members = members;
			l->lines->next = NULL;
		
			hashTable[k%SIZE] = l;
		}

		/* found in table, so just add scope */
		else{
			LineList temp = new struct LineListRec;
			temp->scope = parent_top();
			temp->VarNum = VarCounter++;
			temp->type = STR_BUILD_RECORD;
			temp->members = members;
			temp->next = l->lines;
			l->lines = temp;
		}
	}
}

/* Function st_lookup returns the memory 
 * location of a variable or -1 if not found
 */
LineList st_lookup( string name, recordType type, int paraNum){ 
	int h = hash(name);
	BucketList l =  hashTable[h]; 
	int k = h;

	//Find the bucket
	while ((l != NULL) && (name != l->name)){
		k++;
		if ((k%SIZE) == h){
			return NULL;		
		}		
		l = hashTable[k%SIZE];
	}
	//No bucket
	if (l == NULL) {return NULL;}
	//Get bucket	
	else {
		
		//Find the line
		LineList t = l->lines;
		
		int presentScope = parent_top();

		//find corresponding type
		while (t != NULL){
			if (type == t->type){
				
				//got one type match, check the scope
				while (presentScope > 0){
					//when scope and type are match
					if (presentScope == t->scope){

						//check the paraNum for FUNC_RECORD
						if (type == FUNC_RECORD){
							if (paraNum == t->paraNum)
								return t;
							else
								break;
						}
						else{
							return t;
						}
					}
					else{
						presentScope = findParent(presentScope);
					}
						
				}
				
				//not this, find next
				t = t->next;
				
				presentScope = parent_top();
			}
			else
				t = t->next;
		}
		//no such line

		return NULL;
	
	}
}


LineList st_check_scope(string name,recordType type,int paraNum){
	int h = hash(name);
	BucketList l =  hashTable[h]; 
	int k = h;

	//Find the bucket
	while ((l != NULL) && (name != l->name)){
		k++;
		if ((k%SIZE) == h){
			return NULL;		
		}		
		l = hashTable[k%SIZE];
	}
	//No bucket
	if (l == NULL) {return NULL;}
	//Get bucket	
	else {

		//Find the line
		LineList t = l->lines;

		//find corresponding type
		while (t != NULL){
			if (type == t->type){

				
				//when scope and type are match
				if (parent_top() == t->scope){

					//check the paraNum for FUNC_RECORD
					if (type == FUNC_RECORD){
						if (paraNum == t->paraNum)
							return t;
						else
							t = t->next;
					}
					else{
						return t;
					}
				}
				else{
					//not this, find next
					t = t->next;
				}
			}
			else
				t = t->next;
		}
		//no such line

		return NULL;
	
	}

}

/*************************************END OF SYMBOL TABLE******************************************/


