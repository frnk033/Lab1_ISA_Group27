#include<stdio.h>
#include<stdlib.h>

int main (int argc, char **argv)
{
  FILE *fp_in1; /// VHDL output samples
  FILE *fp_in2; /// C model results

  int  position;
  int  y1;
  int  y2;

  /// check the command line
  if (argc != 3)
  {
    printf("Use: %s <input_file1> <input_file2>\n", argv[0]);
    exit(1);
  }

  /// open files
  fp_in1 = fopen(argv[1], "r");
  if (fp_in1 == NULL)
  {
    printf("Error: cannot open VHDL results\n");
    exit(2);
  }

  fp_in2 = fopen(argv[2], "r");
  if (fp_in2 == NULL)
  {
    printf("Error: cannot open C model results\n");
    exit(3);
  }

  position=1;
  /// get output samples of VHDL implementation
  do{
    fscanf(fp_in1, "%d", &y1);
    fscanf(fp_in2, "%d", &y2);
    if (y1!=y2)
        printf("Different result in line %d: %d != %d\n", position,y1,y2);
    position ++;
  } while (!feof(fp_in1) && (!feof(fp_in2)));


  printf("number of lines = %d", position-1); // in order to check if the files have the same number of lines
  fclose(fp_in1);
  fclose(fp_in2);

  return 0;

}

