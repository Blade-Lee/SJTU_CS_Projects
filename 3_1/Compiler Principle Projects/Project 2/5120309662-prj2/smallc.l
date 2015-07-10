/*This is smallc.l
This program will be compiled by lex, 
which then output a file named "lex.yy.c",
lex.yy.c will be linked to y.tab.c in gcc and then produce a new compiler program.

In this program, strings of the input will be analyzed and splitted into tokens, by the yylex() program.

Then when Yacc needs a token, the yylex() will return one, if exists, to Yacc.

*/
%{
#include "def.h"
#include "y.tab.h"
extern "C"				
{						
	int yywrap(void);
	int yylex(void);	
}

/*linecount is used to sum up the total number of lines*/
int linecount = 0;

/*char to Int*/
int charToint(char);

/*iniSize is used to store the size of a integer*/
int intSize = 0;

%}
 
/*Definition of the sets of classes*/
digit		[0-9]
letter		[a-zA-Z]
hexdigit    (0x|0X)({digit}|[a-fA-F])+
octdigit	0([0-7])+
decdigit	({digit})+

%%
";"		{return SEMI;}
","		{return COMMA;}
"("		{return LP;}
")"		{return RP;}
"["		{return LB;}
"]"		{return RB;}
"{"		{return LC;}
"}"		{return RC;}
"."		{return DOT;}
"!"		{return LOGICNOT;}
"++"	{return PREINCRE;}
"--"	{return PREDEC;}
"~"		{return BITNOT;}
"*"		{return PRODUCT;}
"/"		{return DIVISION;}
"%"		{return MODULUS;}
"+"		{return PLUS;}
"-"		{return MINUS;}
"<<"	{return SHIFTLEFT;}
">>"	{return SHIFTRIGHT;}
">"		{return GREATERT;}
"<"		{return LESST;}
">="	{return NOTLESST;}
"<="	{return NOTGREATERT;}
"=="	{return EQUAL;}
"!="	{return NOTEQUAL;}
"&"		{return BITAND;}
"^"		{return BITXOR;}
"|"		{return BITOR;}
"&&"	{return LOGICAND;}
"||"	{return LOGICOR;}
"="		{return ASSIGN;}
"+="	{return PLUSASSIGN;}
"-="	{return MINUSASSIGN;}
"*="	{return PRODUCTASSIGN;}
"/="	{return DIVISIONASSIGN;}
"&="	{return ANDASSIGN;}
"^="	{return NORASSIGN;}
"|="	{return ORASSIGN;}
"<<="	{return SLASSIGN;}
">>="	{return SRASSIGN;}
"read"	{return READ;}
"write"	{return WRITE;}
"int"	{return TYPE;}
"struct"	{return STRUCT;}
"return"	{return RETURN;}
"if"	{return IF;}
"else"	{return ELSE;}
"break"	{return BREAK;}
"continue"	{return CONT;}
"for"	{return FOR;}
\n	{linecount++;}
("_"|{letter})({letter}|{digit}|"_")*	{yylval.name = yytext;return ID;}

{hexdigit}	{						
				int k = 2;
				int sum = 0; 
				while (k < yyleng){
					sum += charToint(yytext[k++])*pow(16,yyleng-k);
													
				}
				yylval.value = sum;
				return INT;
			}

{octdigit}	{
				int k = 1;
				int sum = 0; 	
				while (k < yyleng){
					sum += charToint(yytext[k++])*pow(8,yyleng-k);
													
				}
				yylval.value = sum;
				return INT;
			}

{decdigit}	{
				int k = 0;
				int sum = 0; 	
				while (k < yyleng){
					sum += charToint(yytext[k++])*pow(10,yyleng-k);
													
				}
				yylval.value = sum;
				return INT;
			}

[ \t\r]            /* skip whitespace */
.                    {return UNKNOWN;    }
%%
/*When parsing completes*/
int yywrap(){
	printf("\nParsing complete.\n");
	return 1;
}

/*char to int*/
int charToint(char s){
	switch (s) {
		case '0':return 0;
		case '1':return 1;
		case '2':return 2;
		case '3':return 3;
		case '4':return 4;
		case '5':return 5;
		case '6':return 6;
		case '7':return 7;
		case '8':return 8;
		case '9':return 9;
		case 'a':return 10;
		case 'b':return 11;
		case 'c':return 12;
		case 'd':return 13;
		case 'e':return 14;
		case 'f':return 15;
		case 'A':return 10;
		case 'B':return 11;
		case 'C':return 12;
		case 'D':return 13;
		case 'E':return 14;
		case 'F':return 15;
	}
}

