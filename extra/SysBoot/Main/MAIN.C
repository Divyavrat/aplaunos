#define COLS 80
#define ROWS 24
unsigned short *vidmem;
unsigned short *textmemptr;
int attrib = 0x0F;
int csr_x = 0, csr_y = 0;
unsigned char inportb (unsigned short _port)

{
    unsigned char rv;

    __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    return rv;

}


void outportb (unsigned short _port, unsigned char _data)

{
    __asm__ __volatile__ ("outb %1, %0" : : "dN" (_port), "a" (_data));
}
unsigned char *memcpy(unsigned char *dest, const unsigned char *src, int count)
{
  int i;
  for (i=0; i<count;i++) dest[i]=src[i];
  return dest;
}

unsigned char *memset(unsigned char *dest, unsigned char val, int count)
{
  int i;
  for (i=0; i<count;i++) dest[i]=val;
  return dest;
}

unsigned short *memsetw(unsigned short *dest, unsigned short val, int count)
{
  int i;
  for (i=0; i<count;i++) dest[i]=val;
  return dest;
}
char strcmp(const void *_m1, const void *_m2, unsigned short n)
{
  unsigned char *m1 = (unsigned char *)_m1, *m2 = (unsigned char *)_m2;
  unsigned short i;
  for(i=0; i<n; i++)
  {
    if(m1[i] != m2[i])
    {
      return (m1[i] > m2[i] ? 1 : -1);
    }
  }
  return 0;
}

int strlen(const char *str)
{
  int i;
  for (i=0;;i++) if (str[i] == '\0') return i;
}
static void scroll(void)
{
	unsigned blank, temp;

	blank = 0x20 | (attrib << 8);
/* scroll up */
	if(csr_y >= ROWS)
	{
		temp = csr_y - ROWS + 1;
		memcpy(vidmem, vidmem + temp * COLS,
			(ROWS - temp) * COLS * 2);
/* blank the bottom line of the screen */
		memsetw(vidmem + (ROWS - temp) * COLS,
			blank, COLS);
		csr_y = ROWS - 1;
	}
}
/*void scroll(void)
{
    unsigned blank, temp;
    blank = 0x20 | (attrib << 8);
    if(csr_y >= ROWS)
    {
        temp = csr_y - ROWS + 1;
        memcpy ((unsigned char *)textmemptr, 
		(const unsigned char *)textmemptr + temp * COLS, 
		(ROWS - temp) * COLS * 2);

                memsetw (textmemptr + (ROWS - temp) * COLS, blank, COLS);
        csr_y = ROWS - 1;
    }
}
)*/
void move_csr(void)
{
    unsigned temp;
    temp = csr_y * COLS + csr_x;
    outportb(0x3D4, 14);
    outportb(0x3D5, temp >> 8);
    outportb(0x3D4, 15);
    outportb(0x3D5, temp);
}
void putch(unsigned char c)
{
    unsigned short *where;
    unsigned att = attrib << 8;

  
    if(c == 0x08)
    {
        if(csr_x != 0) csr_x--;
    }
   
    else if(c == 0x09)
    {
        csr_x = (csr_x + 8) & ~(8 - 1);
    }

    else if(c == '\r')
    {
        csr_x = 0;
    }
    else if(c == '\n')
    {
        csr_x = 0;
        csr_y++;
    }
    else if(c >= ' ')
    {
        where = textmemptr + (csr_y * COLS + csr_x);
        *where = c | att;	
        csr_x++;
    }

    if(csr_x >= COLS)
    {
        csr_x = 0;
        csr_y++;
    }
    scroll();
    move_csr();
}

void puts(unsigned char *text)
{
    int i=0;

    for (i = 0; i < strlen((const char*)text); i++)
    {
        putch(text[i]);
    }
}
void cls()
{
    unsigned blank;
    int i;
    blank = 0x20 | (attrib << 8);
    for(i = 0; i < ROWS/*25*/; i++)
        memsetw (textmemptr + i * COLS, blank, COLS);
    csr_x = 0;
    csr_y = 0;
    move_csr();
}
static unsigned _crtc_io_adr;
void init_video(void)
{
if((inportb(0x3CC) & 0x01) != 0)
{textmemptr = (unsigned short *)0xB8000;
_crtc_io_adr = 0x3D4;}
else{textmemptr = (unsigned short *)0xB0000;
_crtc_io_adr = 0x3B4;}
vidmem=textmemptr;
cls();
}
void main()
{init_video();
puts("In an exe .");
puts("Let it go .");
puts("Let it run .");
puts("Let it fly .");
puts("Let it soar .");
*textmemptr=0x0F01;
for(;;){}
}