#include<stdio.h>

int main()
{
  int n = 0;
  int i = 0;
  int v = 0;
  char s[80];
  FILE *fp;
  printf("Virtual address of v: %p\n", &v);
  
  while(1){
        fp = fopen("/proc/mtest", "w+");
  	fgets(s, 80, stdin);
  	if(memcmp(s, "exit", 4) == 0) break;
        else if(memcmp(s, "print", 5) == 0) printf("%d\n", v);
  	else if(memcmp(s, "write", 5) == 0){
            sscanf(s, "write %d", &i);
            n = fprintf(fp, "writeval%lx %lx", (unsigned long)(void*)&v, (unsigned long)i);
          }
        fclose(fp);
  }
  return 0;
}
