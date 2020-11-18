#include<stdio.h>
#include<stdlib.h>

#define NT 11 /// number of coeffs
#define NB 9 /// number of bits


const int b[NT] = {-1, -4,	-7, 16, 70, 101, 70, 16, -7	, -4, -1}; /// b array

/// Perform fixed point filtering assming direct form I
///\param x is the new input sample
///\return the new output sample
int myfilter(int x)
{
  static int sx[NT]; /// x shift register
  static int sy[NT-1]; /// y shift register
  static int first_run = 0; /// for cleaning shift registers
  int i; /// index
  int y; /// output sample

  /// clean the buffers
  if (first_run == 0)
  {
    first_run = 1;
    for (i=0; i<NT; i++)
      sx[i] = 0;
    for (i=0; i<NT-1; i++)
      sy[i] = 0;
  }

  /// shift and insert new sample in x shift register
  for (i=NT-1; i>0; i--)
    sx[i] = sx[i-1];
  sx[0] = x>>1 ; /// x is internally represented on 8 bits

  /// make the convolution
  /// Moving average part
  y = 0;
  for (i=0; i<NT; i++)
    y += (sx[i]*(b[i]>>1) >> (NB-2)) ; /// b coefficients are internally represented on 8 bits, and also the products



 /// OVERFLOW detection (same behavior as VHDL model)
 if (y > 127) {
    y = 255;
 } else if (y < -128) {
    y = -256;
 }
   else {
    y = y<<1; } ///y is brought back on 9 bits



  /// update the y shift register
  for (i=NT-2; i>0; i--)
    sy[i] = sy[i-1];
  sy[0] = y;

  return y;
}

int main (int argc, char **argv)
{
  FILE *fp_in;
  FILE *fp_out;

  int x;
  int y;

  /// check the command line
  if (argc != 3)
  {
    printf("Use: %s <input_file> <output_file>\n", argv[0]);
    exit(1);
  }

  /// open files
  fp_in = fopen(argv[1], "r");
  if (fp_in == NULL)
  {
    printf("Error: cannot open s\n");
    exit(2);
  }
  fp_out = fopen(argv[2], "w");

  /// get samples and apply filter
  fscanf(fp_in, "%d", &x);
  do{
    y = myfilter(x);
    fprintf(fp_out,"%d\n", y);
    fscanf(fp_in, "%d", &x);
  } while (!feof(fp_in));

  y = myfilter(x);
  fprintf(fp_out,"%d", y);

  fclose(fp_in);
  fclose(fp_out);

  return 0;

}