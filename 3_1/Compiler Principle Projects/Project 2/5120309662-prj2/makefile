LEX=flex

YACC=yacc

CC=g++

scc: lex.yy.o y.tab.o
	$(CC) lex.yy.o y.tab.o -ly -ll -o scc

lex.yy.o:lex.yy.c y.tab.h def.h
	$(CC) -c lex.yy.c

y.tab.o: y.tab.c def.h
	$(CC) -c y.tab.c

y.tab.c y.tab.h:smallc.y lex.yy.c
	$(YACC) -v -d smallc.y

lex.yy.c:smallc.l
	$(LEX) smallc.l

clean:
	rm -f *.o *.c *.h 

