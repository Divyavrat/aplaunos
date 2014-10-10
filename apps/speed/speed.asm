mov ax,0x0020
mov di,int20h
call set_ivt

;__get_speed__:
   ;first do a cpuid command, with eax=1
   mov  eax,1
   cpuid
   ;test edx,byte 0x10      ; test bit #4. Do we have TSC ?
   test dl,byte 0x10
   jz   detect_end         ; no ?, go to detect_end
   ;wait until the timer interrupt has been called.
   mov  ebx, ~[irq0_count]
 
;__wait_irq0__:
 
   cmp  ebx, ~[irq0_count]
   jz   wait_irq0
   rdtsc                   ; read time stamp counter
   mov  ~[tscLoDword], eax
   mov  ~[tscHiDword], edx
   add  ebx, 2             ; Set time delay value ticks.
   ; remember: so far ebx = ~[irq0]-1, so the next tick is
   ; two steps ahead of the current ebx ;)
 
;__wait_for_elapsed_ticks__:
 
   cmp  ebx, ~[irq0_count] ; Have we hit the delay?
   jnz  wait_for_elapsed_ticks
   rdtsc
   sub eax, ~[tscLoDword]  ; Calculate TSC
   sbb edx, ~[tscHiDword]
   ; f(total_ticks_per_Second) =  (1 / total_ticks_per_Second) * 1,000,000
   ; This adjusts for MHz.
   ; so for this: f(100) = (1/100) * 1,000,000 = 10000
   mov ebx, 10000
   div ebx
   ; ax contains measured speed in MHz
   ;mov ~[mhz], ax
   call printwordh
   ret

tscHiDword:dw 0
tscLoDword:dw 0