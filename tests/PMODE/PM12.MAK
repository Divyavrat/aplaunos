PROJ	=pm12
CFLAGS	=-c -O2
OBJECTS	=$(PROJ)a.o $(PROJ)c.o
MAKEFILE=$(PROJ).mak
DEL	=deltree /y

$(PROJ).com: $(MAKEFILE) $(OBJECTS) $(PROJ).scr
	ld -o $(PROJ).cof -T$(PROJ).scr $(OBJECTS)
	echo CAUTION: disassembly is not accurate until do_pm >$(PROJ).lst
	objdump --disassemble $(PROJ).cof >>$(PROJ).lst
	nm --line-numbers $(PROJ).cof | sort >$(PROJ).sym
	objcopy --input-format coff-go32 --output-format binary $(PROJ).cof $(PROJ).com

$(PROJ)a.o: $(MAKEFILE) $(PROJ)a.asm
	nasm -f aout -o $(PROJ)a.o $(PROJ)a.asm

$(PROJ)c.o: $(MAKEFILE) $(PROJ)c.c
	gcc $(CFLAGS) $(PROJ)c.c

clean:
	$(DEL) *.o *.com pm12.cof pm12.lst pm12.sym
