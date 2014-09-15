								/* pm12c.c
******************************************************************************
	pm12c.c - protected-mode demo code
	Christopher Giese <geezer[AT]execpc.com>

	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
	Assemble pm12a.asm with NASM:
				nasm -f aout -o pm12a.o pm12a.asm
	Compile pm12c.c with DJGPP:
				gcc -c -O2 -o pm12c.o pm12c.c
	Link with DJGPP ld, using pm12.scr script:
				ld -o pm12.com -Tpm12.scr pm12a.o pm12c.o
	or just type:
				make -f pm12.mak

Demonstrates:
	- Interface and linking to C-language code.
	- The beginnings of a libc (standard C library).
	- More elaborate syscalls and error-handling.
	- Scrolling video; moving cursor in putch().
*****************************************************************************/
/*////////////////////////////////////////////////////////////////////////////
	x86.h, x86.c
////////////////////////////////////////////////////////////////////////////*/
/* Portions copyright (C) 1995 DJ Delorie, see COPYING.DJ for details */
/*****************************************************************************
	name:	outb
	action:	writes 8-bit Data to Port
*****************************************************************************/
__inline__ void outb(unsigned short Port, unsigned char Data)
{	__asm__ __volatile__ ("outb %1, %0"
		:
		: "d" (Port), "a" (Data)); }
/*****************************************************************************
	name:	disable
	action:	disables all interrupts at the CPU
	returns:old value of EFLAGS
*****************************************************************************/
__inline__ void disable(void)
{	__asm__ __volatile__ (
		"cli\n"
		:
		: ); }
/*****************************************************************************
	name:	enable
	action:	enables interrupts at CPU
*****************************************************************************/
__inline__ void enable(void)
{	__asm__ __volatile__ (
		"sti\n"
		:
		: ); }
/*****************************************************************************
	name:	peekb
	action:	reads 8-bit data from far address Seg:Off
	returns:value read
*****************************************************************************/
__inline__ unsigned char peekb(unsigned short Seg, unsigned long Off)
{	unsigned char RetVal;

	__asm__ __volatile__ ("movw %w1, %%fs \n.byte 0x64 \nmovb (%k2),%w0"
		: "=r" (RetVal)
		: "rm" (Seg), "r" (Off));
	return(RetVal); }
/*****************************************************************************
	name:	peekw
	action:	reads 16-bit data from far address Seg:Off
	returns:value read
*****************************************************************************/
__inline__ unsigned short peekw(unsigned short Seg, unsigned long Off)
{	unsigned short RetVal;

	__asm__ __volatile__ ("movw %w1, %%fs \n.byte 0x64 \nmovw (%k2),%w0"
		: "=r" (RetVal)
		: "rm" (Seg), "r" (Off));
	return(RetVal); }
/*****************************************************************************
	name:	pokeb
	action:	writes 8-bit Data to far address Seg:Off
*****************************************************************************/
__inline__ void pokeb(unsigned short Seg, unsigned long Off, unsigned char Data)
{	__asm__ __volatile__ ("movw %w0,%%fs \n.byte 0x64 \nmovb %w1,(%k2)"
		:
		: "rm" (Seg), "ri" (Data), "r" (Off)); }
/*****************************************************************************
	name:	pokew
	action:	writes 16-bit Data to far address Seg:Off
*****************************************************************************/
__inline__ void pokew(unsigned short Seg, unsigned long Off, unsigned short Data)
{	__asm__ __volatile__ ("movw %w0,%%fs \n.byte 0x64 \nmovw %w1,(%k2)"
		:
		: "rm" (Seg), "ri" (Data), "r" (Off)); }
/*****************************************************************************
	name:	farmemmove
	action:	moves Count bytes from far address SrcSeg:SrcOff to
		far address DstSeg:DstOff
	XXX - convert to assembly, handle overlapping Src and Dst
*****************************************************************************/
void farmemmove(unsigned short DstSeg, unsigned long DstOff, unsigned short SrcSeg, unsigned long SrcOff,
	unsigned Count)
{
	for(; Count; Count--)
		pokeb(DstSeg, DstOff++, peekb(SrcSeg, SrcOff++)); }
/*****************************************************************************
	name:	farmemsetw
	action:	writes 16-bit Data to far address DstSeg:DstOff
		Count times
	XXX - convert to assembly
*****************************************************************************/
void farmemsetw(unsigned short DstSeg, unsigned long DstOff, unsigned short Data, unsigned Count)
{	for(; Count; Count--)
	{	pokew(DstSeg, DstOff, Data);
		DstOff += 2; }}
/*////////////////////////////////////////////////////////////////////////////
	stdarg.h
////////////////////////////////////////////////////////////////////////////*/
/* round up width of objects pushed on stack. The expression before the
& ensures that we get 0 for objects of size 0. */
#define	VA_SIZE(TYPE)		\
	((sizeof(TYPE) + sizeof(_stackitem) - 1) & ~(sizeof(_stackitem) - 1))

/* &(LASTARG) points to the LEFTMOST argument of the function call */
#define	va_start(AP, LASTARG)	\
	(AP=((va_list)&(LASTARG) + VA_SIZE(LASTARG)))

#define va_end(AP)	/* nothing */

#define va_arg(AP, TYPE)	\
	(AP += VA_SIZE(TYPE), *((TYPE *)(AP - VA_SIZE(TYPE))))

typedef char *va_list;
typedef int _stackitem;	/* stack holds nothing narrower than this type */
/*////////////////////////////////////////////////////////////////////////////
	stdio.h
////////////////////////////////////////////////////////////////////////////*/
#define		EOF		(-1l)
#define		NULL		(0ul)

typedef int (*fnptr)(char *Str, char Char);
/*****************************************************************************
	name:	myPrintf
	action:	minimal subfunction for ?printf, calls function
		Fn with arg Ptr for each character to be output
	returns:total number of characters output

	%[flag][width][.prec][mod][conv]
	flag:	-	left justify, pad right w/ blanks	DONE
		0	pad left w/ 0 for numerics
		+	always print sign, + or -
		' '	(blank)
		#	(???)
	width:		(field width)				DONE
	prec:		(precision)
	conv:	d,i	decimal int				DONE
		o	octal					DONE
		x,X	hex					DONE
		f,e,g,E,G float
		c	char					DONE
		s	string					DONE
		p	ptr					DONE
	mod:	N	near ptr
		u	decimal unsigned			DONE
		F	far ptr
		h	short int				DONE
		l	long int				DONE
		L	long double
*****************************************************************************/
/* flags used in processing format string */
#define		VPR_LJ	0x01	/* left justify */
#define		VPR_CA	0x02	/* use A-F instead of a-f for hex */
#define		VPR_SG	0x04	/* signed numeric conversion (%d vs. %u) */
#define		VPR_32	0x08	/* long (32-bit) numeric conversion */
#define		VPR_16	0x10	/* short (16-bit) numeric conversion */
#define		VPR_WS	0x20	/* VPR_SG set and Num was < 0 */

/* largest number handled is 2^32-1, lowest radix handled is 8.
2^32-1 in base 8 has 11 digits (add one for trailing NUL) */
#define		VPR_BUFLEN	12

int myPrintf(fnptr Fn, char *Ptr, const char *Fmt, va_list Args)
{	char *Where, Buf[VPR_BUFLEN], State, Flags;
	unsigned short Count, GivenWd;
	unsigned long Num, Temp;
/* cheap compilers for 8-bit CPUs don't optimize well (if at all), so
we do poor-man's live-range optimization: */
#define	Radix		State
#define	ActualWd	State

	State=Flags=Count=GivenWd=0;
/* begin scanning format specifier list */
	for(; *Fmt; Fmt++)
	{	switch(State)
		{case 0:	/* AWAITING % */
			if(*Fmt != '%')			/* not %... */
			{	Fn(Ptr++, *Fmt);	/* ...just echo it */
				Count++;
				break; }
/* found %, get next char and advance state to check if next char is a flag */
			else
			{	State++;
				Fmt++; }/* FALL THROUGH */
		case 1:		/* AWAITING FLAGS (-) */
			if(*Fmt == '-')
			{	if(Flags & VPR_LJ)	/* %-- is illegal */
					State=Flags=GivenWd=0;
				else Flags |= VPR_LJ;
				break; }
/* not a flag char: advance state to check if it's field width */
			else State++;	/* FALL THROUGH */
		case 2:		/* AWAITING FIELD WIDTH (<number>) */
			if(*Fmt >= '0' && *Fmt <= '9')
			{	GivenWd=10 * GivenWd + (*Fmt - '0');
				break; }
/* not field width: advance state to check if it's a modifier */
			else State++;	/* FALL THROUGH */
		case 3:		/* AWAITING MODIFIER CHARS (lh) */
			if(*Fmt == 'l')
			{	Flags |= VPR_32;
				break; }
			if(*Fmt == 'h')
			{	Flags |= VPR_16;
				break; }
/* not modifier: advance state to check if it's a conversion char */
			else State++;	/* FALL THROUGH */
		case 4:		/* AWAITING CONVERSION CHARS (Xxpndiuocs) */
			Where=Buf + VPR_BUFLEN;
			*--Where=0;
			switch(*Fmt)
			{case 'X':
				Flags |= VPR_CA;/* FALL THROUGH */
			case 'x':
			case 'p':
			case 'n':
				Radix=16;
				goto DO_NUM;
			case 'd':
			case 'i':
				Flags |= VPR_SG;/* FALL THROUGH */
			case 'u':
				Radix=10;
				goto DO_NUM;
			case 'o':
				Radix=8;
/* load the value to be printed. 32 bits: */
DO_NUM:				if(Flags & VPR_32)
					Num=va_arg(Args, unsigned long);
/* 16 bits (signed or unsigned) */
				else if(Flags & VPR_16)
				{	if(Flags & VPR_SG)
						Num=va_arg(Args, short);
					else Num=va_arg(Args, unsigned short); }
/* sizeof(int) bits (signed or unsigned) */
				else
				{	if(Flags & VPR_SG)
						Num=va_arg(Args, int);
					else Num=va_arg(Args, unsigned int); }
/* take care of sign */
				if(Flags & VPR_SG)
				{	if((long)Num < 0)
					{	Flags |= VPR_WS;
						Num=-Num; }}
/* convert binary to octal/decimal/hex ASCII */
				do
				{	Temp=Num % Radix;
					if(Temp < 10) *--Where=Temp + '0';
					else if(Flags & VPR_CA)
						*--Where=Temp - 10 + 'A';
					else *--Where=Temp - 10 + 'a';
					Num /= Radix; }
				while(Num);
/* sign, again */
				if(Flags & VPR_WS) *--Where='-';
				goto EMIT;
			case 'c':
				*--Where=(char)va_arg(Args, char);
				ActualWd=1;
				goto EMIT2;
			case 's':
				Where=va_arg(Args, char *);
EMIT:				ActualWd=strlen(Where);
/* pad on left with spaces (for right justify) */
EMIT2:				if((Flags & VPR_LJ) == 0)
				{	for(; GivenWd > ActualWd; GivenWd--)
					{	Fn(Ptr++, ' ');
						Count++; }}
/* emit string/char/converted number from Buf */
				while(*Where)
				{	Fn(Ptr++, *Where++);
					Count++; }
/* pad on right with spaces (for left justify) */
				if(GivenWd < ActualWd) GivenWd=0;
				else GivenWd -= ActualWd;
				for(; GivenWd; GivenWd--)
				{	Fn(Ptr++, ' ');
					Count++; }	/* FALL THROUGH */
			default:	/* FALL THROUGH */
				break; }
		default:
			State=Flags=GivenWd=0;
			break; }}
	return(Count); }
/*****************************************************************************
	name:	putchar
	action:	write Char to stdout (console only, for now)
	returns:Char
*****************************************************************************/
int putchar(int Char)
{	asm("mov 8(%esp),%eax");
	asm("int $0x30"); }
/*****************************************************************************
	name:	printf
*****************************************************************************/
int printfOut(char *Str, char Char)
{	return(putchar(Char)); }

int printf(const char *Fmt, ...)
{	va_list Args;
	int RetVal;

	va_start(Args, Fmt);
	RetVal=myPrintf(printfOut, NULL, Fmt, Args);
	va_end(Args);
	return(RetVal); }
/*////////////////////////////////////////////////////////////////////////////
	conio.h
////////////////////////////////////////////////////////////////////////////*/
#define		LINEAR_SEL	8

#define		ATTRIB		0x7100
#define		FAKE_SPACE	0xFFu
#define		SCN_HT		25
#define		SCN_WD		80

extern char CsrX;
extern char CsrY;
/*****************************************************************************
	name:	scroll
	action:	scrolls display up, down, left, or right as needed
*****************************************************************************/
void scroll(void)
{	unsigned Count;
	unsigned short Blank;

	Blank=' ' | ATTRIB;
/* scroll up */
	if(CsrY >= SCN_HT)
	{	Count=CsrY - SCN_HT + 1;
		farmemmove(LINEAR_SEL, 0xB8000ul,
			LINEAR_SEL, 0xB8000ul + Count * SCN_WD * 2,
			(SCN_HT - Count) * SCN_WD * 2);
		farmemsetw(LINEAR_SEL,
			0xB8000ul + (SCN_HT - Count) * SCN_WD * 2,
			Blank, SCN_WD);
		CsrY=SCN_HT - 1; }
/* scroll down XXX - CsrY is unsigned */
	else if(CsrY < 0)
	{	Count=-CsrY;
		farmemmove(LINEAR_SEL, 0xB8000ul,
			LINEAR_SEL, 0xB8000ul + Count * SCN_WD,
			SCN_WD * (SCN_HT - Count));
		farmemsetw(LINEAR_SEL, 0xB8000ul, Blank, Count * SCN_WD); }
/* scroll right */
//	if(CsrX >= 80)
}//        {
/* XXX - no left/right scroll? */
/*****************************************************************************
	name:	putch
*****************************************************************************/
int putch(int Char)
{	unsigned long Where;
	unsigned short Temp;

	Where=(CsrY * SCN_WD + CsrX) * 2 + 0xB8000ul;
/* backspace (destructive cursor left) */
	if(Char == 0x08)
	{	Temp=ATTRIB | FAKE_SPACE;
		if(CsrX == 0 && CsrY == 0) return(EOF);
		do	/* skip tab, cr, or lf blanks */
		{	Where -= 2;
			if(CsrX) CsrX--;
			else
			{	CsrX=SCN_WD - 1;
				CsrY--; }}
		while(peekw(LINEAR_SEL, Where) == Temp);
		pokew(LINEAR_SEL, Where, Temp); }
/* tab (destructive) */
	else if(Char == 0x09)
	{	Temp=7 - (CsrX & 7);
		goto CON_CR; }
/* carriage return (non-destructive) */
	else if(Char == '\r')	/* 0x0D */
		CsrX=0;
/* CR/LF (destructive) */
	else if(Char == '\n')	/* 0x0A */
	{	Temp=SCN_WD - CsrX - 1;
CON_CR:		putch(' ');	/* recursion */
		for(; Temp; Temp--) putch(FAKE_SPACE);
		return(Char); }
/* line feed (destructive cursor down) */
	else if(Char == '\n')	/* XXX - 0x0A again */
	{	Temp=SCN_WD - 1;
		goto CON_CR; }
/* printable ASCII */
	else if(Char >= ' ')
	{	pokew(LINEAR_SEL, Where, Char | ATTRIB);
		CsrX++;
		if(CsrX >= SCN_WD)
		{	CsrX=0;
			CsrY++;
			scroll(); }}
	Temp=CsrY * SCN_WD + CsrX;
	disable();		/* XXX - save flags, then disable */
	outb(0x3D4, 14);
	outb(0x3D5, Temp >> 8);
	outb(0x3D4, 15);
	outb(0x3D5, Temp);
	enable();		/* XXX - restore flags */
	return(Char); }
/*////////////////////////////////////////////////////////////////////////////
	main
////////////////////////////////////////////////////////////////////////////*/
char *Msg[]={
	"zero divide", "debug exception", "NMI", "INT3",
	"INTO", "BOUND exception", "invalid opcode", "no coprocessor",
	"double fault", "coprocessor segment overrun",
		"bad TSS", "segment not present",
	"stack fault", "GPF", "page fault", "coprocessor error",
	"??", "alignment check", "??", "??",
	"??", "??", "??", "??",
	"??", "??", "??", "??",
	"??", "??", "??", "??",
	"timer tick", "keyboard", "IRQ 2", "IRQ 3",
	"IRQ 4", "IRQ 5", "floppy", "IRQ 7",
	"real-time clock", "IRQ 9", "IRQ 10", "IRQ 11",
	"IRQ 12", "math chip", "primary IDE", "secondary IDE" };
/*****************************************************************************
	name:	unhand
*****************************************************************************/
void unhand(unsigned WhichInt, unsigned Off, unsigned Sel)
{	printf("\nException #%u (%s) at address 0x%X:0x%lX\n"
		"System halted.\n", WhichInt, (WhichInt < 48 ?
		Msg[WhichInt] : "??"), Sel, Off);
	while(1); }
/*****************************************************************************
	name:	unhand2
*****************************************************************************/
void unhand2(unsigned WhichInt, unsigned ErrorCode, unsigned Off, unsigned Sel)
{	register long PageFaultAdr;

	printf("\nException #%u (%s) at address 0x%X:0x%X (error code "
		"0x%X)\n", WhichInt, (WhichInt < 48
		? Msg[WhichInt] : "??"), Sel, Off, ErrorCode);
	if(WhichInt == 14)
	{	asm("mov %%cr2, %0" : "=r"(PageFaultAdr));
		printf("Page fault address: 0x%X\n", PageFaultAdr); }
	printf("System halted.");
	while(1); }
/*****************************************************************************
	name:	taskA

	This code runs in Ring 3.
*****************************************************************************/
void taskA(void)
{	long Pause;

	while(1)
	{	printf("Hello from task A. ");
		for(Pause=0xFFFFF; Pause; Pause--); }}
/*****************************************************************************
	name:	taskB

	This code runs in Ring 3.
*****************************************************************************/
void taskB(void)
{	long Pause;

	while(1)
	{	printf("Greetings from task B. ");
		for(Pause=0xFFFFF; Pause; Pause--);
/* die */
//		asm("int $0x18");
		}}
