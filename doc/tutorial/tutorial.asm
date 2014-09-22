org 0x6000
use16
welcome_screen:
call mouselib_setup
mov cx, 0
mov dx, 0
call mouselib_move
welcome:
call os_hide_cursor
call os_clear_screen
;call mouselib_hide
.loop:
	mov ax,.osstring
	mov bx,.welcome_str1
	mov cx,[color]
	call os_draw_background
	mov bl,0x30
	mov dx,0x0202
	mov si,76
	mov di,5
	call os_draw_block
	mov dx,0x0305
	call os_move_cursor
	mov si,.welcome_str_t1
	call os_print_string
	mov bl,0x30
	mov dx,0x1502
	mov si,76
	mov di,0x18
	call os_draw_block
	mov dx,0x1605
	call os_move_cursor
	mov si,.welcome_str_t2
	call os_print_string
	mov bl,0x97
	mov dx,0x0602
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0704
	call os_move_cursor
	mov si,.welcome_str_t3
	call os_print_string
	mov bl,0x8D
	mov dx,0x060C
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x070E
	call os_move_cursor
	mov si,.welcome_str_t4
	call os_print_string
	mov bl,0x29
	mov dx,0x0616
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0717
	call os_move_cursor
	mov si,.welcome_str_t5
	call os_print_string
	mov bl,0xAC
	mov dx,0x0620
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0722
	call os_move_cursor
	mov si,.welcome_str_t6
	call os_print_string
	mov bl,0xE4
	mov dx,0x062A
	mov si,11
	mov di,9
	call os_draw_block
	mov dx,0x072B
	call os_move_cursor
	mov si,.welcome_str_t7
	call os_print_string
	mov bl,0x6F
	mov dx,0x0635
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0736
	call os_move_cursor
	mov si,.welcome_str_t8
	call os_print_string
	
	mov bl,0x7F
	mov dx,0x0A02
	mov si,20
	mov di,0x0D
	call os_draw_block
	mov dx,0x0B06
	call os_move_cursor
	mov si,.welcome_str_e1
	call os_print_string
	mov bl,0xF7
	mov dx,0x0A16
	mov si,20
	mov di,0x0D
	call os_draw_block
	mov dx,0x0B18
	call os_move_cursor
	mov si,.welcome_str_e2
	call os_print_string
	mov bl,0x70
	mov dx,0x0A2A
	mov si,20
	mov di,0x0D
	call os_draw_block
	mov dx,0x0B2C
	call os_move_cursor
	mov si,.welcome_str_e3
	call os_print_string
	
	mov bl,0x12
	mov dx,0x1032
	mov si,20
	mov di,0x15
	call os_draw_block
	mov dx,0x1235
	call os_move_cursor
	mov si,.continue_str
	call os_print_string
	
	.recheck:
	call mouselib_locate
	;call mouselib_freemove
	call mouselib_show
	call mouselib_input_wait
	jc .key_pressed
	call mouselib_anyclick
	jc .button
	call mouselib_hide
	jmp .recheck
.key_pressed:
	;call os_check_for_key
	call mouselib_hide
	mov ah,0x00
	int 0x16
	cmp al, 27
	je .exit
	cmp al, 13
	je .exit
	cmp al,'c'
	je .common_link
	cmp al,'f'
	je .folder
	cmp al,'a'
	je .app
	cmp al,'e'
	je .editing
	cmp al,'u'
	je .customize
	cmp al,'s'
	je .shutdown
	cmp al,'m'
	je .example_link
	cmp al,'p'
	je .examplefolder
	cmp al,'l'
	je .exampleapp
	jmp .loop
.button:
call mouselib_hide
call mouselib_locate
;call mouselib_freemove
cmp dx,6
jl .exit
cmp dx,20
jg .exit
cmp dx,9
jl .common
cmp dx,0x0D
jl .example
.exit:
	call mouselib_hide
	call os_clear_screen
	call os_show_cursor
	call mouselib_remove_driver
	ret
.common:
cmp cx,0x35
jge .shutdown
cmp cx,0x2A
jge .customize
cmp cx,0x20
jge .editing
cmp cx,0x16
jge .app
cmp cx,0x0C
jge .folder
.common_link:
mov ax,.welcome_str_t3m1
mov bx,.welcome_str_t3m2
mov cx,.welcome_str_t3m3
mov dx,0
call os_dialog_box
jmp welcome
.folder:
mov ax,.welcome_str_t4m1
mov bx,.welcome_str_t4m2
mov cx,.welcome_str_t4m3
mov dx,0
call os_dialog_box
jmp welcome
.app:
mov ax,.welcome_str_t5m1
mov bx,.welcome_str_t5m2
mov cx,.welcome_str_t5m3
mov dx,0
call os_dialog_box
jmp welcome
.editing:
mov ax,.welcome_str_t6m1
mov bx,.welcome_str_t6m2
mov cx,.welcome_str_t6m3
mov dx,0
call os_dialog_box
jmp welcome
.customize:
mov ax,.welcome_str_t7m1
mov bx,.welcome_str_t7m2
mov cx,.welcome_str_t7m3
mov dx,0
call os_dialog_box
jmp welcome
.shutdown:
mov ax,.welcome_str_t8m1
mov bx,.welcome_str_t8m2
mov cx,.welcome_str_t8m3
mov dx,0
call os_dialog_box
jmp welcome
.example:
cmp cx,0x2A
jge .exampleapp
cmp cx,0x16
jge .examplefolder
.example_link:
mov ax,.welcome_str_e1m1
mov bx,.welcome_str_e1m2
mov cx,.welcome_str_e1m3
mov dx,0
call os_dialog_box
jmp welcome
.examplefolder:
mov ax,.welcome_str_e2m1
mov bx,.welcome_str_e2m2
mov cx,.welcome_str_e2m3
mov dx,0
call os_dialog_box
jmp welcome
.exampleapp:
mov ax,.welcome_str_e3m1
mov bx,.welcome_str_e3m2
mov cx,.welcome_str_e3m3
mov dx,0
call os_dialog_box
jmp welcome

.osstring:
db ' Aplaun OS Tutorial ',0
.welcome_str1:
db 'Welcome User to a new newbee World. Check out the commands first.',0
.welcome_str_t1:
db ' For all commands ask for "help". Or click on these to read.',0
.welcome_str_t2:
db ' Reminder: Try the commands without the quotes.',0
.welcome_str_t3:
db 'Common',0
.welcome_str_t3m1:
db 't is time d is date (check clock too).',0
.welcome_str_t3m2:
db 'calc to open calculator. (try "2+6-3")',0
.welcome_str_t3m3:
db 'cls to clear screen',0
.welcome_str_t4:
db 'Folder',0
.welcome_str_t4m1:
db 'nm to name a file/folder (example.txt)',0
.welcome_str_t4m2:
db 'q to list all files and folders.',0
.welcome_str_t4m3:
db 'q also loads the file if found equal.',0
.welcome_str_t5:
db 'App/Prog',0
.welcome_str_t5m1:
db 'to start it just type the name',0
.welcome_str_t5m2:
db 'to give arguments press space and type',0
.welcome_str_t5m3:
db 'Add commonly used programs to path list.',0
.welcome_str_t6:
db 'Editing',0
.welcome_str_t6m1:
db 'edit to change text documents',0
.welcome_str_t6m2:
db 'code to alter machine codes',0
.welcome_str_t6m3:
db 'read to open simple txt books',0
.welcome_str_t7:
db 'cUstomize',0
.welcome_str_t7m1:
db 'color , color2 to change colors',0
.welcome_str_t7m2:
db 'prompt and scrollmode for more customs',0
.welcome_str_t7m3:
db 'Apps can even change your font and cursor',0
.welcome_str_t8:
db 'Shutdown',0
.welcome_str_t8m1:
db 'e to exit / fhlt to halt',0
.welcome_str_t8m2:
db 'restart to restart',0
.welcome_str_t8m3:
db 'reboot to reboot',0

.welcome_str_e1:
db 'exaMple-file',0
.welcome_str_e1m1:
db 'nm test.txt',0
.welcome_str_e1m2:
db 'q',0
.welcome_str_e1m3:
db 'edit',0
.welcome_str_e2:
db 'examPle-folder',0
.welcome_str_e2m1:
db 'nm folder',0
.welcome_str_e2m2:
db 'q',0
.welcome_str_e2m3:
db 'dir',0
.welcome_str_e3:
db 'exampLe-app',0
.welcome_str_e3m1:
db 'hangman',0
.welcome_str_e3m2:
db 'life',0
.welcome_str_e3m3:
db 'viewer',0

.continue_str:
db 'Continue ->>',0

os_print_string:
pusha
mov ah,0x01
int 0x2b
popa
ret

os_move_cursor:
pusha
mov ah,0x03
int 0x2b
popa
ret

os_show_cursor:
pusha
mov ah,0x05
int 0x2b
popa
ret

os_hide_cursor:
pusha
mov ah,0x06
int 0x2b
popa
ret

os_clear_screen:
pusha
mov ah,0x06
int 0x61
popa
ret

os_dialog_box:
pusha
mov dx,ax
mov ah,0x20
int 0x2b
popa
ret

os_draw_background:
pusha
mov dx,ax
mov ah,0x25
int 0x2b
popa
ret

os_draw_block:
pusha
mov ah,0x26
int 0x2b
popa
ret

message_flag:
db 0x0f
color:
dw 0x3534

include 'mouse.lib'
times (512*8)-($-$$) db 0