org 0x6000
use16

.loop:
mov byte [neg_flag],0x0f
mov ah,0x06
int 0x61
;mov ah,0x0B
;int 0x61
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,textstr
int 0x61
mov dx,0
mov bx,0x0fff
mov ah,0x17
int 0x61
mov ax,dx
xor dx,dx
mov cx,3
div cx

cmp dx,0
je .tail
cmp dx,1
je .head
jmp .done
.tail:
inc dword [tail]
jmp .done
.head:
inc dword [head]
.done:
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,text3str
int 0x61
mov ah,0x27
mov edx,[head]
int 0x61
mov ah,0x03
mov dx,text4str
int 0x61
mov ah,0x27
mov edx,[tail]
int 0x61

mov eax,[head]
mov ecx,100
xor edx,edx
mul ecx
mov ecx,[tail]
add ecx,[head]
xor edx,edx
cmp ecx,0
je .skip1
div ecx
.skip1:
mov [headprob],eax
mov eax,[tail]
mov ecx,100
xor edx,edx
mul ecx
mov ecx,[tail]
add ecx,[head]
xor edx,edx
cmp ecx,0
je .skip2
div ecx
.skip2:
mov [tailprob],eax

; mov eax,[headprob]
; mov ecx,100
; xor edx,edx
; mul ecx
; mov ecx,[tailprob]
; xor edx,edx
; cmp ecx,0
; je .skip3
; div ecx
.skip3:
;xor edx,edx
;mov ecx,2
;div ecx
;mov [prob],eax

; mov eax,[headprob]
; add eax,[tailprob]
; mov ecx,2
; xor edx,edx
; div ecx

mov eax,[headprob]
mov ecx,[tailprob]
cmp eax,ecx
jl .tail_big
.head_big:
sub eax,ecx
jmp .done3
.tail_big:
sub ecx,eax
xchg ecx,eax
mov byte [neg_flag],0xf0
.done3:
mov [prob],eax

mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,text5str
int 0x61
mov ah,0x27
mov edx,[headprob]
int 0x61
mov ah,0x03
mov dx,text6str
int 0x61
mov ah,0x27
mov edx,[tailprob]
int 0x61

mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,text2str
int 0x61
cmp byte [neg_flag],0xf0
je .neg
mov dl,'+'
jmp .done2
.neg:
mov dl,'-'
.done2:
mov ah,0x02
int 0x21
mov ah,0x27
mov edx,[prob]
int 0x61

;mov ah,0x0B
;int 0x61
mov ah,0x09
int 0x61
;mov ah,0x17
;int 0x61
;mov ah,0x17
;int 0x61
;mov ah,0x17
;int 0x61
mov ah,0x06
mov dl,0xFF
int 0x21
cmp dl,0x0f
je .loop
ret

textstr:
db "Coin probability test :",0
text2str:
db "        Current probability :",0
text3str:
db "   Head Count :  ",0
text4str:
db "      Tail Count :  ",0
text5str:
db "   Head Probability: ",0
text6str:
db "   Tail Probability: ",0
dw 0
head:
dd 0
tail:
dd 0
headprob:
dd 0
tailprob:
dd 0
prob:
dd 0
neg_flag:
db 0x0f
times 512-($-$$) db 0x90