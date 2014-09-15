;Copyright (c) 2009 Max Reitz
;
;Permission is hereby granted,  free of charge,  to any  person obtaining a
;copy of this software and associated documentation files (the "Software"),
;to deal in the Software without restriction,  including without limitation
;the rights to use,  copy, modify, merge, publish,  distribute, sublicense,
;and/or sell copies  of the  Software,  and to permit  persons to whom  the
;Software is furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING  BUT NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR  PURPOSE AND  NONINFRINGEMENT.  IN NO EVENT SHALL
;THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY,  WHETHER IN AN ACTION OF CONTRACT,  TORT OR OTHERWISE,  ARISING
;FROM,  OUT OF  OR IN CONNECTION  WITH THE  SOFTWARE  OR THE  USE OR  OTHER
;DEALINGS IN THE SOFTWARE.

;Hinweise zum System:
;isynax lÃ¤dt im RealMode zunÃ¤chst einige weitere Sektoren des Betriebssystems nach. Danach wird in den
;Protected Mode geschalten - Paging und das A20-Gate bleiben deaktiviert.

target_port = 0x0B1A ;6667 in Big-Endian
wrong = 0

org 0x7C00

use16

;DF auf den korrekten Wert setzen
cld
;Interrupts aktivieren (kÃ¶nnte zum Laden der Sektoren nÃ¼tzlich sein, obwohl Interrupts eigentlich schon
;aktiviert sein sollten)
sti
;CS auf einen bekannten Wert setzen
jmp   far 0x0000:start

gdt_start:
gdt_dummy:      ;0x0000
dd 0,0
gdt_entry_code: ;0x0008
dw 0xFFFF
dw 0x0000
db 0x00
db 10011010b
db 11001111b
db 0x00
gdt_entry_data: ;0x0010
dw 0xFFFF
dw 0x0000
db 0x00
db 10010010b
db 11001111b
db 0x00
gdt_end:
gdt_desc:
dw 23
dd gdt_start
idt_desc:
dw 2047
dd 0x90000

start:
;Stack einrichten
mov   esp,0xFFFF

;Datensegmente anpassen
xor   ax,ax
mov   ds,ax
mov   es,ax
mov   ss,ax

;dl sollte richtig gesetzt sein
mov   ax,0x020B ;Elf Sektoren lesen
mov   bx,more
mov   cx,0x0002 ;Track: 0; Sektor: 2
xor   dh,dh     ;Head: 0
int   0x13

;GDT laden und in den Protected Mode springen
cli
lgdt  [gdt_desc]
mov   eax,cr0
or    eax,1
mov   cr0,eax
jmp   far 0x08:pmode

use32

pmode:
;Korrekten Datenselektor laden
mov   ax,0x10
mov   ds,ax
mov   es,ax
mov   ss,ax
;Neuen Stack einrichten
mov   esp,0x20000

;IDT erstellen
mov   ebx,0x90000
mov   ecx,256
mov   eax,gen_int_handler
;Generischen Handler eintragen
set_gen_loop:
mov   word [ebx],ax
mov   word [ebx+2],0x0008
mov   byte [ebx+5],10001110b
ror   eax,16
mov   word [ebx+6],ax
ror   eax,16
add   ebx,8
loop  set_gen_loop

;IRQ-Handler eintragen
mov   ebx,0x90100
mov   ecx,16
set_irq_loop:
mov   eax,gen_irq_handler
cmp   ecx,15
jne   gen_handler
;Eine besondere ISR fÃ¼r IRQ1 (Tastatur)
mov   eax,kbd_handler
gen_handler:
mov   word [ebx],ax
mov   word [ebx+2],0x0008
mov   byte [ebx+5],10001110b
ror   eax,16
mov   word [ebx+6],ax
ror   eax,16
add   ebx,8
loop  set_irq_loop

;PICs initialisieren
;ICW1 (Initialization Command Word)
mov   al,0x11
out   0x20,al
out   0xA0,al
;ICW2
mov   al,32
out   0x21,al
add   al,8
out   0xA1,al
;ICW3
mov   al,0x04
out   0x21,al
mov   al,2
out   0xA1,al
;ICW4
mov   al,0x01
out   0x21,al
out   0xA1,al
;Alle IRQs aktivieren
dec   al
out   0x21,al
out   0xA1,al

;Tastatus initialisieren
;Standardmodus aktivieren
mov   dx,0x64
push  edx
mov   al,0x60
mov   cl,0x41
call  send_keyboard_command
;Typematicrate einstellen (klappt nur nicht wirklich)
mov   dx,0x60
mov   al,0xF3
xor   cl,cl
call  send_keyboard_command
;Tastatur Ã¼ber den Commandport aktivieren
pop   edx
mov   al,0xAE
mov   ecx,-1
call  send_keyboard_command
;Tastatur Ã¼ber den Statusport aktivieren
mov   dx,0x60
mov   al,0xF4
call  send_keyboard_command
;Scancodeset 2 einstellen
mov   al,0xF0
xor   cl,cl
call  send_keyboard_command
;Alle eventuell noch vorhandenen Scancodes auslesen
flush_kbd_buffer:
in    al,0x64
test  al,1
jz    kbd_buffer_flushed
in    al,0x60
jmp   flush_kbd_buffer
kbd_buffer_flushed:

;IDT laden und Interrupts aktivieren
lidt  [idt_desc]
sti

call  update_input

;Bildschirminhalt leeren
mov   edi,0xB8000
mov   ecx,960
mov   eax,0x07000700
rep   stosd

;Nach Netzwerkkarten suchen
xor   eax,eax
pci_bus_scan:
xor   ebx,ebx
pci_slot_scan:
xor   ecx,ecx
pci_function_scan:
push  eax
cdq
call  pci_config_read_long
;Gibt es Ã¼berhaupt ein GerÃ¤t?
cmp   ax,0xFFFF
je    pci_do_next_function
;Ist dieses GerÃ¤t eine rtl8139-Netzwerkkarte?
cmp   ax,0x10EC
jne   pci_do_next_function
shr   eax,16
cmp   ax,0x8139
jne   pci_do_next_function
pop   eax
;Da haben wir eine, also mit der Initialisierung fortfahren
jmp   rtl8139found
pci_do_next_function:
inc   ecx
cmp   ecx,8
pop   eax
jb    pci_function_scan
inc   ebx
cmp   ebx,32
jb    pci_slot_scan
inc   eax
cmp   eax,2
jb    pci_bus_scan

;Schade, nix gefunden
mov   esi,noncard
call  print
mov   esi,found
call  print
cli
hlt

;Befehl zur Tastatur schicken
;al: Befehl
;cl: Daten (wenn keine Daten gesendet werden sollen, ist ecx -1)
;dl: Befehlsport
send_keyboard_command:
pushad
push  eax
;Warten, bis Befehle gesendet werden dÃ¼rfen
wait_kbd:
in    al,0x64
test  al,2
jnz   wait_kbd
pop   eax
;Befehl senden
out   dx,al
;Soll ein Parameter hinterher?
cmp   ecx,-1
je    send_no_command_anymore
;Ja, also auch den senden (per Port 0x60)
mov   dx,0x60
mov   al,cl
mov   ecx,-1
call  send_keyboard_command
send_no_command_anymore:
popad
ret

rtl8139found:
;Ah, toll, eine rtl8139-Netzwerkkarte wurde gefunden, das kÃ¶nnen wir dem Benutzer auch gleich
;mal sagen
mov   esi,rtl8139
call  print
mov   esi,found
call  print
;Wir beginnen bei der Suche nach dem Beginn des I/O-Bereichs beim Offset 0x10 im PCI-Header
mov   edx,0x10
jmp   rtl8139_bar_loop


rtl8139 db "rtl8139",0
found db " found",10,0
noncard db "No card",0

times 510-($-$$) db 0

dw 0xAA55

;Bootsektor zu Ende, hier beginnen die weiteren Sektoren

more:

;Liest ein dword von einem PCI-Header
;eax = Bus
;ebx = Slot
;ecx = Function
;edx = Offset
pci_config_read_long:
pushad
and   eax,0xFF
shl   eax,16
or    eax,0x80000000
and   ebx,0x1F
shl   ebx,11
or    eax,ebx
and   ecx,0x07
shl   ecx,8
or    eax,ecx
and   edx,0xFC
or    eax,edx
mov   edx,0xCF8
out   dx,eax
add   edx,4
in    eax,dx
mov   [esp+28],eax
popad
ret

;Schreibt ein dword in einen PCI-Header
;eax = Bus
;ebx = Slot
;ecx = Function
;edx = Offset
;esi = Wert
pci_config_write_long:
pushad
and   eax,0xFF
shl   eax,16
or    eax,0x80000000
and   ebx,0x1F
shl   ebx,11
or    eax,ebx
and   ecx,0x07
shl   ecx,8
or    eax,ecx
and   edx,0xFC
or    eax,edx
mov   edx,0xCF8
out   dx,eax
add   edx,4
mov   eax,esi
out   dx,eax
popad
ret

rtl8139_io_space db "I/O not",0
mac db "MAC: ",0
router db "Router ",0
rtl8139iobase dd 0
rtl8139mac db 0,0,0,0,0,0
rtl8139receive = 0x40000
rtl8139recbufpos dd 0
rtl8139transmit_base = 0x44000 ;0x44000, 0x44800, 0x45000, 0x45800
rtl8139cur_transmit dd 0
rtl8139target = 0x46000
router_mac db 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
my_seq dd 0x422A6613
server_seq dd 0
con_status db 0 ;geschlossen

;Wunderbar, wir haben also eine rtl8139. Da suchen wir jetzt gleich mal nach dem Beginn des I/O-Raums
rtl8139_bar_loop:
push  eax
call  pci_config_read_long
;Ist das ein I/O-Raum?
test  eax,1
jnz   rtl8139_bar_found
pop   eax
add   edx,4
cmp   edx,0x28 ;Nix gefunden...? Doof.
jae   rtl8139_io_not_found
jmp   rtl8139_bar_loop

rtl8139_io_not_found:
mov   esi,rtl8139_io_space
call  print
mov   esi,found
call  print
;Meh, keine Lust mehr
cli
hlt

rtl8139_bar_found:
;So, das ist also der Beginn des I/O-Raums
and   eax,0xFFF8
mov   [rtl8139iobase],eax
pop   eax
;IRQ-Nummer auslesen
mov   edx,0x3C
call  pci_config_read_long
and   eax,0xFF

;Die ISR fÃ¼r diesen IRQ eintragen
mov   ebx,0x90100
shl   eax,3
add   ebx,eax
mov   eax,rtl8139_handler
mov   word [ebx],ax
mov   word [ebx+2],0x0008
mov   byte [ebx+5],10001110b
shr   eax,16
mov   word [ebx+6],ax

;Karte initialisieren
mov   edx,[rtl8139iobase]
xor   ecx,ecx
mov   esi,mac
call  print
xor   eax,eax
;Erstmal die MAC-Adresse auslesen (Register +0x00 bis +0x05)
rtl8139_read_mac:
in    al,dx
inc   edx
mov   [rtl8139mac+ecx],al
call  print_hex
cmp   cx,5
jae   rtl8139_no_colon
mov   esi,colon
call  print
inc   cx
jmp   rtl8139_read_mac
rtl8139_no_colon:

mov   esi,br
call  print

add   edx,0x31 ;Zum COMMAND-Register gehen
mov   al,0x10
out   dx,al    ;Resetten

;Warten, bis der Reset beendet wurde
rtl8139_wait_for_reset_done:
in    al,dx
test  al,0x10
jnz   rtl8139_wait_for_reset_done

mov   al,0x0C
out   dx,al ;Empfangen und Senden aktivieren

;Ein bisschen warten (PIT-Treiber wÃ¤re sinnvoll, ja)
mov   ecx,0xFFFFF
rtl8139_wait_a_bit:
loop  rtl8139_wait_a_bit

add   edx,0x09 ;Zum TRANSMISSION-CONFIG-Register gehen
in    eax,dx
and   eax,0x7FC00000
or    eax,0x00000700 ;2kB-DMA
out   dx,eax

add   edx,0x04 ;Zum RECEIVE-CONFIG-Register gehen
mov   eax,0x0000070D ;Unlimitierter DMA, Broadcast+Multicast+Singlecast (kein Promiscuous)
out   dx,eax

sub   edx,0x14 ;Zum RECEIVE-BUFFER-Register gehen
mov   eax,rtl8139receive
out   dx,eax

add   edx,0x0E ;Zum INTERRUPT-STATUS-Register gehen
xor   ax,ax
out   dx,ax
sub   edx,0x02 ;Zum INTERRUPT-MASK-Register gehen
dec   ax ;0xFFFF
out   dx,ax ;Alles aktivieren

;Wieder ein bisschen warten...
mov   ecx,0xFFFFF
rtl8139_wait_a_bit2:
loop  rtl8139_wait_a_bit2

mov   [has_new_string],0

mov   esi,q_server_ip
call  print
wait_for_server_ip:
cmp   [has_new_string],0
je    wait_for_server_ip
mov   ebx,[has_new_string]
mov   [has_new_string],0
mov   esi,ebx
call  strlen
dec   eax ;Zeilenumbruch entfernen
mov   ecx,eax
mov   edi,0x89000
rep   movsb
xor   al,al
stosb
mov   ebx,0x89000
call  ipstring_to_value
mov   [server_ip],eax

mov   esi,q_my_ip
call  print
wait_for_my_ip:
cmp   [has_new_string],0
je    wait_for_my_ip
mov   ebx,[has_new_string]
mov   [has_new_string],0
mov   esi,ebx
call  strlen
dec   eax ;Zeilenumbruch entfernen
mov   ecx,eax
mov   edi,0x89020
rep   movsb
xor   al,al
stosb
mov   ebx,0x89020
call  ipstring_to_value
mov   [my_ip],eax

mov   esi,q_router_ip
call  print
wait_for_router_ip:
cmp   [has_new_string],0
je    wait_for_router_ip
mov   ebx,[has_new_string]
mov   [has_new_string],0
mov   esi,ebx
call  strlen
dec   eax ;Zeilenumbruch entfernen
mov   ecx,eax
mov   edi,0x89020
rep   movsb
xor   al,al
stosb
mov   ebx,0x89020
call  ipstring_to_value
mov   [router_ip],eax

mov   esi,nickname
call  print
wait_for_nickname:
cmp   [has_new_string],0
je    wait_for_nickname
mov   ebx,[has_new_string]
mov   [has_new_string],0
mov   esi,ebx
mov   edi,name
call  strlen
dec   eax
mov   ecx,eax
rep   movsb
mov   esi,irc_nick
mov   edi,0x88000
movsd
movsb
mov   esi,ebx
call  strlen
mov   ecx,eax
push  ecx
rep   movsb
mov   esi,irc_user
movsd
movsb
mov   esi,ebx
pop   ecx
dec   ecx
push  ecx
rep   movsb
mov   al,' '
stosb
mov   esi,ebx
pop   ecx
push  ecx
rep   movsb
mov   al,' '
stosb
mov   esi,0x89000
push  ebx
mov   ebx,esi
call  strlen
pop   ebx
mov   ecx,eax
rep   movsb
mov   al,' '
stosb
mov   al,':'
stosb
mov   esi,ebx
pop   ecx
rep   movsb
mov   al,10
stosb
xor   al,al
stosb

;Jetzt die MAC-Adresse des Routers herausfinden
;Dazu erstellen wir einen ARP-Request
;Zuerst den Ethernetheader
;Ziel: Der Router (in router_mac sollte noch FF:FF:FF:FF:FF:FF stehen, also Broadcast)
mov   esi,router_mac
mov   edi,arp_eth_destMAC
mov   ecx,6
push  ecx
rep   movsb
;Quelle: Ich
mov   esi,rtl8139mac
pop   ecx
rep   movsb
;Jetzt das ARP-Paket
mov   [arp_packet_hwaddr_type],0x0100 ;MAC
mov   [arp_packet_hwaddr_size],6 ;6 Bytes
mov   [arp_packet_protaddr_type],0x0008 ;IPv4
mov   [arp_packet_protaddr_size],4 ;4 Bytes
mov   [arp_packet_operation],0x0100 ;ARP-Request
;Meine MAC-Adresse eintragen
mov   esi,rtl8139mac
mov   edi,arp_packet_srcMAC
mov   ecx,6
rep   movsb
;Meine IP-Adresse eintragen
mov   eax,[my_ip]
mov   [arp_packet_srcIP],eax
;MAC-Adresse des Routers eintragen (hier darf man reinschreiben, was man will)
mov   esi,router_mac
mov   edi,arp_packet_destMAC
mov   ecx,6
rep   movsb
;IP-Adresse des Routers eintragen
mov   eax,[router_ip]
mov   [arp_packet_destIP],eax
;Ab damit!
mov   esi,arp_packet
mov   ecx,arp_packet_end-arp_packet
call  rtl8139_do_packet
;Jetzt auf eine Antwort warten
wait_for_arp_reply:
cmp   [is_new_arp_packet],0
je    wait_for_arp_reply
;Die MAC-Adresse des Routers auslesen
mov   esi,arp_packet_srcMAC
mov   edi,router_mac
mov   ecx,6
rep   movsb

;Jetzt diese auch noch schÃ¶n ausgeben, der Benutzer will ja mÃ¶glichst viel wissen, was er
;eh schon weiÃŸ
mov   esi,router
call  print
mov   esi,mac
call  print

;Den Mist ausgeben
xor   ecx,ecx
xor   eax,eax
read_router_mac:
mov   al,[router_mac+ecx]
call  print_hex
cmp   cx,5
je    no_colon
mov   esi,colon
call  print
no_colon:
inc   cx
cmp   cx,6
jb    read_router_mac

mov   esi,br
call  print

;Wir greifen uns einfach mal frech vor
mov   [con_status],1 ;SYN gesendet

;Jetzt wird erst das SYN-Paket gesendet
xor   ecx,ecx
mov   edx,TCP_SYN
call  send_tcp_packet

;Warten wir auf das SYN-ACK
wait_for_syn_ack:
cmp   [con_status],1
je    wait_for_syn_ack

;Jetzt einloggen
mov   esi,0x88000
call  print

;Die NICK- und USER-Befehle senden
mov   ebx,0x88000
call  strlen
mov   ecx,eax
mov   edx,TCP_PSH+TCP_ACK
call  send_tcp_packet

;Warten wir auf einen Tastendruck - der Benutzer weiÃŸ meist am Besten, wann wir soweit sind
mov   [key],0
while_wait:
cmp   [key],0
je    while_wait

wait_for_action:
hlt
cmp   [has_new_string],0
je    wait_for_action
mov   ebx,[has_new_string]
push  ebx
mov   [has_new_string],0
mov   edi,0x88000
push  edi
mov   ecx,512
xor   eax,eax
rep   stosd
pop   edi
mov   esi,ebx
lodsb
cmp   al,'/'
je    is_command
mov   esi,privmsg
movsd
movsd
mov   esi,cur_chan
mov   ebx,esi
call  strlen
mov   ecx,eax
rep   movsb
mov   al,' '
stosb
mov   al,':'
stosb
pop   esi
push  esi
mov   ebx,esi
call  strlen
mov   ecx,eax
rep   movsb
mov   ebx,0x88000
mov   esi,open
call  print
mov   esi,name
call  print
mov   esi,close
call  print
pop   esi
call  print
jmp   send_it
is_command:
add   esp,4
copy_string:
lodsb
or    al,al
jz    copy_cmd_done
stosb
jmp   copy_string
copy_cmd_done:
mov   ebx,0x88000
call  check_send_irc_command
send_it:
call  strlen
mov   ecx,eax
mov   edx,TCP_PSH+TCP_ACK
call  send_tcp_packet
jmp   wait_for_action

cur_chan: times 128 db 0
open db "<",0
close db "> ",0
name: times 64 db 0
privmsg db "PRIVMSG "
irc_nick db "NICK "
irc_user db "USER "
nickname db "Nickname?",10,0
q_my_ip db "IP dieses Computers?",10,0
q_router_ip db "IP des Routers?",10,0
q_server_ip db "IP des IRC-Servers? (z. B. 217.26.49.12)",10,0
server_ip dd 0
my_ip dd 0
router_ip dd 0

irc_join db "join "
irc_part db "part",10

check_send_irc_command:
pushad
mov   esi,ebx
mov   edi,irc_join
mov   ecx,5
repe  cmpsb
je    has_join
mov   esi,ebx
mov   edi,irc_part
mov   ecx,5
repe  cmpsb
je    has_part
popad
ret

has_join:
mov   edi,cur_chan
push  edi
mov   ecx,32
xor   eax,eax
rep   stosd
pop   edi
join_skip_space:
lodsb
cmp   al,' '
je    join_skip_space
dec   esi
mov   ebx,esi
call  strlen
mov   ecx,eax
dec   ecx ;Zeilenumbruch entfernen
rep   movsb
popad
ret

has_part:
mov   edi,esi
dec   edi
mov   al,' '
stosb
mov   esi,cur_chan
mov   ebx,esi
call  strlen
mov   ecx,eax
rep   movsb
mov   al,10
stosb
xor   al,al
stosb
popad
ret

;Wandelt eine IP-Adresse in Stringform in ihren Wert um
;ebx: Pointer zum String
ip_value dd 0
ipstring_to_value:
pushad
mov   esi,ebx
mov   ebx,10
mov   [ip_value],0
xor   ecx,ecx
parse_it_all:
cdq
field:
xor   eax,eax
lodsb
cmp   ecx,3
jb    not_last_field
or    al,al
jz    field_done
jmp   check_the_number
not_last_field:
cmp   al,'.'
je    field_done
check_the_number:
cmp   al,'0'
jb    no_valid_ip
cmp   al,'9'
ja    no_valid_ip
push  eax
mov   eax,edx
cdq
mul   ebx
mov   edx,eax
pop   eax
sub   al,'0'
add   edx,eax
jmp   field
field_done:
test  edx,0xFFFFFF00
jnz   no_valid_ip
shl   ecx,3 ;Mit 8 multiplizieren
shl   edx,cl
shr   ecx,3
or    [ip_value],edx
inc   ecx
cmp   ecx,4
jb    parse_it_all
popad
mov   eax,[ip_value]
ret
no_valid_ip:
popad
xor   eax,eax
ret

is_new_arp_packet db 0

;FÃ¼r ARP-Pakete
arp_packet:
;Ethernetheader
arp_eth_destMAC db 0,0,0,0,0,0
arp_eth_srcMAC db 0,0,0,0,0,0
arp_eth_packet_type dw 0x0608
;ARP-Paket
arp_packet_hwaddr_type dw 0
arp_packet_protaddr_type dw 0
arp_packet_hwaddr_size db 0
arp_packet_protaddr_size db 0
arp_packet_operation dw 0
arp_packet_srcMAC db 0,0,0,0,0,0
arp_packet_srcIP dd 0
arp_packet_destMAC db 0,0,0,0,0,0
arp_packet_destIP dd 0
arp_packet_end:

;FÃ¼r TCP-Pakete, die abgeschickt werden sollen
tcp_packet:
;Ethernetheader
tcp_eth_packet:
tcp_eth_destMAC db 0,0,0,0,0,0
tcp_eth_srcMAC db 0,0,0,0,0,0
tcp_eth_packet_type dw 0x0008
;IP-Header
tcp_ip_packet:
tcp_ip_header db 0x45 ;IPv4, keine Optionen
tcp_ip_priority db 0 ;Bah, wer braucht den sowas
tcp_ip_packetsize dw 0
tcp_ip_id dw 0 ;Braucht doch auch kein Schwein
tcp_ip_fragment dw 0x0040 ;Don't fragment
tcp_ip_ttl db 128 ;So machen es doch alle
tcp_ip_protocol db 0x06 ;TCP
tcp_ip_checksum dw 0
tcp_ip_srcIP dd 0
tcp_ip_destIP dd 0
;TCP-Header
tcp_tcp_packet:
tcp_tcp_srcport dw 0x0004 ;1024 in Big-Endian
tcp_tcp_destport dw target_port
tcp_tcp_seq dd 0
tcp_tcp_ack dd 0
tcp_tcp_hdrlen db 0x50 ;5 in Big-Endian
tcp_tcp_flags db 0
tcp_tcp_window dw 0x1405 ;1300 in Big-Endian
tcp_tcp_checksum dw 0
tcp_tcp_urgent dw 0 ;Bah. Als ob wir es eilig hÃ¤tten.
tcp_packet_end:
;Hier kommen dann die Daten hin (also theoretisch, die sind dann nicht wirklich hier,
;sondern in einem Speicherbereich, in dem sie keinen Schaden anrichten kÃ¶nnen)

;Die TCP-Flags
TCP_FIN = 0x01
TCP_SYN = 0x02
TCP_RST = 0x04
TCP_PSH = 0x08
TCP_ACK = 0x10
TCP_URG = 0x20


;Ein TCP-Paket senden
;ebx: Daten
;ecx: LÃ¤nge der Daten
;edx: Flags
send_tcp_packet:
pushad
push  ecx
;Erstmal mit 0 initialisieren
mov   edi,0x50000
mov   ecx,512
xor   eax,eax
rep   stosd
;Die MAC-Adresse des Routers eintragen
mov   esi,router_mac
mov   edi,tcp_eth_destMAC
mov   ecx,6
push  ecx
rep   movsb
;Meine MAC-Adresse eintragen
mov   esi,rtl8139mac
pop   ecx
rep   movsb
;LÃ¤nge von IP-Header + TCP-Header,...
mov   ax,tcp_packet_end-tcp_ip_packet
pop   ecx
push  ecx
;...DatenlÃ¤nge dazuaddieren,...
add   ax,cx
;...in Big-Endian umwandeln und...
xchg  al,ah
;...als LÃ¤nge des gesamten IP-Pakets eintragen.
mov   [tcp_ip_packetsize],ax
;Meine IP
mov   eax,[my_ip]
mov   [tcp_ip_srcIP],eax
;Die IP des Ziels (ist konstant)
mov   eax,[server_ip]
mov   [tcp_ip_destIP],eax
;Checksummenfeld mit 0 initialisieren
mov   [tcp_ip_checksum],0
push  ebx
;Checksumme fÃ¼r den IP-Header berechnen,...
mov   ebx,tcp_ip_packet
mov   ecx,tcp_tcp_packet-tcp_ip_packet
call  calculate_network_checksum
;...in Big-Endian umwandeln und...
xchg  al,ah
;...eintragen.
mov   [tcp_ip_checksum],ax
pop   ebx
;Die Flags in den TCP-Header eintragen
mov   [tcp_tcp_flags],dl
;Meine Sequenznummer erstmal in Big-Endian umwandeln und...
mov   eax,[my_seq]
mov   ecx,eax
xchg  al,ah
shr   ecx,16
xchg  cl,ch
shl   eax,16
mov   ax,cx
;...diesen Wert dann eintragen.
mov   [tcp_tcp_seq],eax
;So, das Gleiche mit der Sequenznummer des Servers...
mov   eax,[server_seq]
mov   ecx,eax
xchg  al,ah
shr   ecx,16
xchg  cl,ch
shl   eax,16
mov   ax,cx
;Uuuund eintragen.
mov   [tcp_tcp_ack],eax
;Wenn es ein SYN-Paket ist, mÃ¼ssen wir die Sequenznummer um eins erhÃ¶hen
test  dl,TCP_SYN
jz    no_syn
inc   [my_seq]
no_syn:
;Ebenso bei FIN-Paketen
test  dl,TCP_FIN
jz    no_fin
inc   [my_seq]
no_fin:
pop   ecx
push  ecx
add   [my_seq],ecx
;Checksumme mit 0 initialisieren
mov   [tcp_tcp_checksum],0

;Checksumme berechnen
mov   edi,0x50000
;Pseudoheader bilden
mov   eax,[my_ip]
stosd
mov   eax,[server_ip]
stosd
xor   al,al
stosb
mov   al,0x06
stosb
pop   eax
push  eax
add   eax,tcp_packet_end-tcp_tcp_packet
xchg  al,ah
stosw
;TCP-Header dranhÃ¤ngen
mov   esi,tcp_tcp_packet
mov   ecx,tcp_packet_end-tcp_tcp_packet
rep   movsb
mov   esi,ebx
;Daten dranhÃ¤ngen
pop   ecx
push  ecx
or    ecx,ecx
jz    no_tcp_data_check
rep   movsb
no_tcp_data_check:
;Jetzt die Checksumme berechnen
mov   ecx,edi
push  ebx
mov   ebx,0x50000
sub   ecx,ebx
call  calculate_network_checksum
;Und auch eintragen
pop   ebx
xchg  al,ah
mov   [tcp_tcp_checksum],ax

;Paket abschicken
mov   edi,0x50000
mov   esi,tcp_packet
mov   ecx,tcp_packet_end-tcp_packet
rep   movsb
pop   ecx
or    ecx,ecx
jz    no_tcp_data
push  ecx
mov   esi,ebx
rep   movsb
pop   ecx
no_tcp_data:
mov   esi,0x50000
add   ecx,tcp_packet_end-tcp_packet
call  rtl8139_do_packet
popad
ret

;NetzwerkprÃ¼fsumme bilden
;ebx: Buffer
;ecx: GrÃ¶ÃŸe
calculate_network_checksum:
xor   eax,eax
pushad
or    ebx,ebx
jz    calculate_network_checksum_ret
cmp   ecx,2
jb    calculate_network_checksum_ret
mov   esi,ebx
cdq
calc_on:
xor   eax,eax
lodsb
shl   eax,8
lodsb
add   edx,eax
loop  is_not_odd
xor   eax,eax
lodsb
shl   eax,8
add   edx,eax
jmp   make_it_16
is_not_odd:
loop  calc_on
make_it_16:
test  edx,0xFFFF0000
jz    has_sum
mov   eax,edx
shr   eax,16
and   edx,0x0000FFFF
add   edx,eax
jmp   make_it_16
has_sum:
not   edx
and   edx,0xFFFF
mov   [esp+28],edx
calculate_network_checksum_ret:
popad
ret


;Paket Ã¼ber die rtl8139-Netzwerkkarte abschicken
;esi: Daten
;ecx: LÃ¤nge
rtl8139_do_packet:
pushad
;Auf maximal 1514 Bytes zusammenstutzen
cmp   ecx,1514
jbe   rtl8139_packet_size_not_too_big
mov   ecx,1514
rtl8139_packet_size_not_too_big:
;Den aktuellen Sendepuffer auslesen und erhÃ¶hen
mov   edi,[rtl8139cur_transmit]
inc   edi
cmp   edi,4
jae   rtl8139_transmitbuf_wrap_around
mov   [rtl8139cur_transmit],edi
rtl8139_set_transmitbuf:
dec   edi
mov   edx,edi
;Pufferposition ermitteln
shl   edi,11 ;Mal 2048
add   edi,rtl8139transmit_base
push  ecx
push  edi
;Puffer leeren
mov   ecx,512
xor   eax,eax
rep   stosd
;Daten kopieren
pop   edi
pop   ecx
push  ecx
push  edi
rep   movsb
;Transfer beginnen
shl   edx,2 ;Mal 4
add   edx,[rtl8139iobase]
add   edx,0x20 ;TRANSMIT-ADDRESS
pop   eax
;Adresse des Puffers eintragen
out   dx,eax
sub   edx,0x10 ;TRANSMIT-STATUS
pop   eax
;Pakete mÃ¼ssen mindestens 60 Byte haben
cmp   eax,60
jae   rtl8139_packet_size_ok
mov   eax,60
rtl8139_packet_size_ok:
;Transfer mit dem Eintragen der PaketgrÃ¶ÃŸe starten
out   dx,eax
popad
ret
rtl8139_transmitbuf_wrap_around:
mov   [rtl8139cur_transmit],0
jmp   rtl8139_set_transmitbuf


colon db ":",0
br db 10,0

;Der IRQ-Handler fÃ¼r die rtl8139
rtl8139_handler:
pushad
mov   edx,[rtl8139iobase]
add   edx,0x3E
xor   eax,eax
;Grund fÃ¼r diesen IRQ auslesen
in    ax,dx
;Paket empfangen?
test  ax,1
jnz   rtl8139_packet_received
rtl8139_handler_ret:
;Der Karte mitteilen, dass alle GrÃ¼nde fÃ¼r den IRQ abgearbeitet wurden
out   dx,ax
;IRQs aktivieren
mov   al,0x20
out   0x20,al
out   0xA0,al
popad
;Und zurÃ¼ckkehren
iret
;Da ist doch tatsÃ¤chlich was reingekommen
rtl8139_packet_received:
pushad
mov   edx,[rtl8139iobase]
add   edx,0x37 ;COMMAND
rtl8139_new_packet_test:
in    al,dx
;Gibt es noch neue Pakete?
test  al,0x01 ;Is buffer empty
jnz   rtl8139_no_new_packet
;Jup, also nehmen wir uns das erste vor
mov   esi,rtl8139receive
add   esi,[rtl8139recbufpos]
;Status auslesen
lodsw
push  ax
;GrÃ¶ÃŸe herausfinden
lodsw
xor   ecx,ecx
mov   cx,ax
pop   ax
push  ecx
;Wurde das Paket gut empfangen?
test  ax,1
jz    rtl8139_no_good_packet
;Stimmt die GrÃ¶ÃŸe auch?
cmp   ecx,14 ;GrÃ¶ÃŸe des Ethernetheaders
jb    rtl8139_no_good_packet
cmp   ecx,1518 ;Maximale GrÃ¶ÃŸe
jae   rtl8139_no_good_packet
;Alles OK, also kopieren wir es in einen Puffer und lassen es dann Ã¼berprÃ¼fen
mov   edi,rtl8139target
push  ecx
mov   ecx,512
xor   eax,eax
;Puffer leeren
rep   stosd
pop   ecx
mov   eax,[rtl8139recbufpos]
add   eax,ecx
;Wurde das Paket durchgebrochen (wir haben ja schlieÃŸlich einen Ringpuffer)?
cmp   eax,8192
ja    rtl8139_broken_packet
;Nein, also kopieren wir es in einem Schritt
mov   edi,rtl8139target
mov   esi,rtl8139receive
add   esi,[rtl8139recbufpos]
add   esi,4
rep   movsb
jmp   rtl8139_check
rtl8139_broken_packet:
;Ja, also kopieren wir zunÃ¤chst den ersten Teil...
mov   edx,8192
sub   edx,[rtl8139recbufpos]
mov   esi,rtl8139receive
add   esi,[rtl8139recbufpos]
add   esi,4
push  ecx
mov   ecx,edx
mov   edi,rtl8139target
rep   movsb
;Und dann den Rest
pop   ecx
mov   esi,rtl8139receive
sub   ecx,edx
rep   movsb
rtl8139_check:
;Dann lassen wir die Daten Ã¼berprÃ¼fen
mov   ebx,rtl8139target
call  check_network_data
rtl8139_no_good_packet:
;Das Paket Ã¼berspringen
mov   eax,[rtl8139recbufpos]
pop   ecx
add   eax,ecx
add   eax,7
and   eax,0x00001FFC
;Position des nÃ¤chsten Pakets
mov   [rtl8139recbufpos],eax
sub   eax,0x10 ;Das muss sein, kA, warum genau
inc   edx ;CURRENT-READ-ADDRESS
;Diese Position eintragen
out   dx,ax
dec   edx ;COMMAND
jmp   rtl8139_new_packet_test
rtl8139_no_new_packet:
;Alle Pakete abgearbeitet, also zurÃ¼ckkehren
popad
jmp   rtl8139_handler_ret


;ebx: Ethernetpaket
check_network_data:
pushad
cmp   word [ebx+12],0x0608 ;ARP
je    check_arp
cmp   word [ebx+12],0x0008 ;IP
je    check_ip
popad
ret

;ebx: Ethernetpaket
check_arp:
mov   esi,ebx
mov   edi,arp_packet
mov   ecx,arp_packet_end-arp_packet
rep   movsb
cmp   word [arp_packet_operation],0x0100 ;Request
je    do_arp_reply ;Antwort senden
cmp   word [arp_packet_operation],0x0200 ;Reply
je    has_arp_reply ;Antwort auswerten
popad
ret

do_arp_reply:
;Einfach ein paar Werte in dem Paket vertauschen (Ziel und Quelle eben), auÃŸerdem die
;eigene MAC-Adresse eintragen
mov   esi,arp_eth_srcMAC
mov   edi,arp_eth_destMAC
mov   ecx,6
push  ecx
rep   movsb
mov   esi,rtl8139mac
mov   edi,arp_eth_srcMAC
pop   ecx
push  ecx
rep   movsb
mov   [arp_packet_operation],0x0200
mov   esi,arp_packet_srcMAC
mov   edi,arp_packet_destMAC
mov   ecx,10 ;MAC + IP
rep   movsb
mov   esi,rtl8139mac
mov   edi,arp_packet_srcMAC
pop   ecx
rep   movsb
mov   eax,[my_ip]
mov   [arp_packet_srcIP],eax
mov   esi,arp_packet
mov   ecx,arp_packet_end-arp_packet
call  rtl8139_do_packet
popad
ret

has_arp_reply:
mov   [is_new_arp_packet],1
popad
ret

check_ip:
cmp   byte [ebx+14+9],0x06 ;TCP
je    check_tcp
popad
ret

thats_reset db "Connection reset.",10,0
has_data db 0
dlen dd 0

;So, eigentlich mÃ¼sste man einen Checksummencheck machen. Das sparen wir uns.
check_tcp:
add   ebx,14 ;Ethernetteil Ã¼berspringen
;Ist das IP-Paket Ã¼berhaupt fÃ¼r uns?
mov   eax,[server_ip]
cmp   dword [ebx+12],eax
jne   invalid_tcp
mov   eax,[my_ip]
cmp   dword [ebx+16],eax
jne   invalid_tcp
xor   ecx,ecx
;GrÃ¶ÃŸe des IP-Pakets
mov   cx,[ebx+2]
xchg  cl,ch ;In Little-Endian umwandeln
;LÃ¤nge des IP-Headers in DWords
mov   al,[ebx]
and   eax,0xF
shl   eax,2 ;In Byte umrechnen
sub   ecx,eax ;GrÃ¶ÃŸe des TCP-Pakets
add   ebx,eax ;IP-Header Ã¼berspringen
;Ist das TCP-Paket Ã¼berhaupt fÃ¼r uns?
cmp   word [ebx],target_port ;Source: 6667
jne   invalid_tcp
cmp   word [ebx+2],0x0004 ;Destination: 1024
jne   invalid_tcp
mov   eax,[ebx+4] ;Sequenznummer des Servers
push  eax
mov   dl,[ebx+13] ;Flags
mov   al,byte [ebx+12] ;LÃ¤nge des Headers in DWords
and   eax,0xF0 ;die oberen vier Bits
shr   eax,2 ;mit vier multiplizieren und gleichzeitig vier Bits nach rechts schieben
sub   ecx,eax ;Nur die reine DatenlÃ¤nge
add   ebx,eax ;TCP-Header Ã¼berspringen
;Bei SYN-Paketen muss die Sequenznummer um eins erhÃ¶ht werden
test  dl,TCP_SYN
jz    rec_no_syn
inc   [server_seq]
rec_no_syn:
;Bei FIN-Paketen ebenso
test  dl,TCP_FIN
jz    rec_no_fin
inc   [server_seq]
rec_no_fin:
;AuÃŸerdem um die LÃ¤nge der Daten erhÃ¶hen
add   [server_seq],ecx
mov   [dlen],ecx
mov   [has_data],0
or    ecx,ecx
jz    no_data_rec
mov   [has_data],1
no_data_rec:

pop   ecx ;Sequenznummer des Servers

;Ã„hm, bei RST ist das ein bissel doof
test  dl,TCP_RST
jz    no_rst
mov   esi,thats_reset
call  print
;Gleich schlieÃŸen
mov   [con_status],0
jmp   invalid_tcp
no_rst:

cmp   [con_status],1 ;SYN gesendet
jne   check_status_2
mov   al,dl
and   al,TCP_SYN+TCP_ACK
cmp   al,TCP_SYN+TCP_ACK ;SYN-ACK-Paket
jne   connect_failed
mov   [con_status],2 ;Verbindung aufgebaut
;Sequenznummer in Little-Endian umwandeln und eintragen
mov   eax,ecx
xchg  al,ah
shr   ecx,16
xchg  cl,ch
shl   eax,16
mov   ax,cx
inc   eax ;SYN -> inkrementieren
mov   [server_seq],eax
;ACK'en
xor   ecx,ecx
mov   edx,TCP_ACK
call  send_tcp_packet

jmp   invalid_tcp
connect_failed:
mov   [con_status],0
jmp   invalid_tcp

check_status_2:
cmp   [con_status],2 ;Verbindung steht
jne   check_status_3
check_it:
mov   al,TCP_ACK
not   al
;Wenn es irgendwas auÃŸer ACK gibt, muss geACKt werden
test  dl,al
jnz   ack_it
;Bei Daten ebenso
cmp   [has_data],1
jne   invalid_tcp
ack_it:
xor   ecx,ecx
mov   edx,TCP_ACK
call  send_tcp_packet

;Daten Ã¼berprÃ¼fen, wenn welche da sind
cmp   [has_data],1
jne   no_data
call  has_irc_data
no_data:
jmp   invalid_tcp

check_status_3:
cmp   [con_status],3 ;FIN gesendet
jne   check_status_4
test  dl,TCP_FIN
jz    check_it ;Na, dann sind es eben nochmal Daten
has_fin:
;FIN ACKen
xor   ecx,ecx
mov   edx,TCP_ACK
call  send_tcp_packet
do_reset:
;Und resetten
mov   al,0xFE
out   0x64,al

check_status_4:

invalid_tcp:
popad
ret

has_irc_data:
mov   esi,ebx
mov   edi,0x70000
mov   ecx,[dlen]
has_irc_data_rep:
lodsb
cmp   al,13
je    found_one_stuff
cmp   al,10
je    found_one_stuff
test  al,0x80
jz    store_irc_char
mov   dl,al
and   dl,0xF8
cmp   dl,0xF0
je    utf8_four_chars
and   dl,0xF0
cmp   dl,0xE0
je    utf8_three_chars
and   dl,0xE0
cmp   dl,0xC0
je    utf8_two_chars
mov   al,'?'
store_irc_char:
stosb
loop  has_irc_data_rep
ret

utf8_two_chars:
mov   edx,eax
and   edx,0x1F
shl   edx,6
lodsb
and   al,0x3F
or    dl,al
cmp   edx,0x00A1 ;Umgedrehtes Ausrufezeichen
jne   utf8_2c_c1
mov   al,0xAD
jmp   utf8_2c_f
utf8_2c_c1:
cmp   edx,0x00A7 ;Â§
jne   utf8_2c_c2
mov   al,0x15
jmp   utf8_2c_f
utf8_2c_c2:
cmp   edx,0x00B0 ;Â°
jne   utf8_2c_c3
mov   al,0xF8
jmp   utf8_2c_f
utf8_2c_c3:
cmp   edx,0x00B2 ;Â²
jne   utf8_2c_c4
mov   al,0xFD
jmp   utf8_2c_f
utf8_2c_c4:
cmp   edx,0x00B5 ;Âµ
jne   utf8_2c_c5
mov   al,0xE6
jmp   utf8_2c_f
utf8_2c_c5:
cmp   edx,0x00BF ;Umgedrehtes Fragezeichen
jne   utf8_2c_c6
mov   al,0xA8
jmp   utf8_2c_f
utf8_2c_c6:
cmp   edx,0x00C4 ;Ã„
jne   utf8_2c_c7
mov   al,0x8E
jmp   utf8_2c_f
utf8_2c_c7:
cmp   edx,0x00D6 ;Ã–
jne   utf8_2c_c8
mov   al,0x99
jmp   utf8_2c_f
utf8_2c_c8:
cmp   edx,0x00DC ;Ãœ
jne   utf8_2c_c9
mov   al,0x9A
jmp   utf8_2c_f
utf8_2c_c9:
cmp   edx,0x00DF ;ÃŸ
jne   utf8_2c_c10
mov   al,0xE1
jmp   utf8_2c_f
utf8_2c_c10:
cmp   edx,0x00E4 ;Ã¤
jne   utf8_2c_c11
mov   al,0x84
jmp   utf8_2c_f
utf8_2c_c11:
cmp   edx,0x00F6 ;Ã¶
jne   utf8_2c_c12
mov   al,0x94
jmp   utf8_2c_f
utf8_2c_c12:
cmp   edx,0x00FC ;Ã¼
jne   utf8_2c_c13
mov   al,0x81
jmp   utf8_2c_f
utf8_2c_c13:
cmp   edx,0x00FD ;Ã½
jne   utf8_2c_c14
mov   al,'y'
jmp   utf8_2c_f
utf8_2c_c14:
mov   al,'?'
utf8_2c_f:
jmp   store_irc_char

utf8_three_chars:
mov   edx,eax
and   edx,0x0F
shl   edx,6
lodsb
and   al,0x3F
or    dl,al
shl   edx,6
lodsb
and   al,0x3F
or    dl,al
cmp   edx,0x20AC ;EUR
jne   utf8_3c_c1
mov   al,0xEE ;Ã„hnlich dem Zeichen
jmp   utf8_3c_f
utf8_3c_c1:
cmp   edx,0x1E9E ;GroÃŸes Eszett
jne   utf8_3c_c2
mov   al,'S'
stosb ;Zwei bitte
jmp   utf8_3c_f
utf8_3c_c2:
mov   al,'?'
utf8_3c_f:
jmp   store_irc_char

utf8_four_chars:
mov   al,'?'
add   esi,3 ;Drei weitere Zeichen
jmp   store_irc_char

reason_notice db "NOTICE ",0
reason_privmsg db "PRIVMSG ",0
reason_part db "PART ",0
reason_kick db "KICK ",0
reason_quit db "QUIT ",0
reason_join db "JOIN ",0

found_one_stuff:
mov   byte [edi],0
mov   ebx,esi
cmp   al,13
jne   dont_inc
inc   ebx
dec   ecx
dont_inc:
mov   esi,0x70000
cmp   byte [esi],':'
je    dont_print_messages
call  print
push  ecx
push  esi
mov   esi,br
call  print
pop   esi
jmp   dont_push_ecx
dont_print_messages:
push  ecx
dont_push_ecx:
push  esi
mov   edi,irc_ping
mov   ecx,6
repe  cmpsb
jne   no_pong
mov   esi,irc_pong
mov   edi,0x60000
mov   ecx,6
rep   movsb
pop   esi
push  esi
add   esi,6
pushad
mov   ebx,esi
call  strlen
mov   ecx,eax
rep   movsb
mov   al,10
stosb
mov   byte [edi],0
mov   esi,0x60000
call  print
mov   ebx,0x60000
sub   edi,ebx
mov   ecx,edi
mov   edx,TCP_PSH+TCP_ACK
call  send_tcp_packet
popad
no_pong:
pop   esi
push  esi
mov   edi,irc_error
mov   ecx,7
repe  cmpsb
jne   no_error
xor   ecx,ecx
mov   edx,TCP_FIN+TCP_ACK
call  send_tcp_packet
mov   [con_status],3
no_error:
pop   esi
push  esi
lodsb
cmp   al,':'
jne   no_message
push  esi
look_for_name:
lodsb
cmp   al,'!'
je    has_a_name
cmp   al,' '
je    has_a_space
jmp   look_for_name
has_a_name:
mov   ebx,esi
dec   esi
mov   byte [esi],0
look_for_reason:
lodsb
cmp   al,' '
je    has_a_reason
jmp   look_for_reason
has_a_reason:
push  esi
mov   edi,reason_notice
mov   ecx,7
repe  cmpsb
je    print_the_name
pop   esi
push  esi
mov   edi,reason_privmsg
mov   ecx,8
repe  cmpsb
je    print_the_name
pop   esi
push  esi
mov   edi,reason_join
mov   ecx,5
repe  cmpsb
jne   no_join
mov   esi,reason_join
call  print
jmp   print_just_the_name
no_join:
pop   esi
push  esi
mov   edi,reason_kick
mov   ecx,5
repe  cmpsb
jne   no_kick
mov   esi,reason_kick
call  print
jmp   print_just_the_name
no_kick:
pop   esi
push  esi
mov   edi,reason_part
mov   ecx,5
repe  cmpsb
jne   no_part
mov   esi,reason_part
call  print
jmp   print_just_the_name
no_part:
pop   esi
push  esi
mov   edi,reason_quit
mov   ecx,5
repe  cmpsb
jne   no_quit
mov   esi,reason_quit
call  print
no_quit:
jmp   print_just_the_name
print_the_name:
pop   esi
mov   esi,open
call  print
pop   esi
call  print
mov   esi,close
call  print
mov   esi,ebx
jmp   look_for_message
print_just_the_name:
pop   esi
pop   esi
call  print
mov   esi,colon
call  print
mov   esi,ebx
look_for_message:
lodsb
cmp   al,':'
je    has_a_message
or    al,al
jz    has_no_message
jmp   look_for_message
has_a_message:
call  print
has_no_message:
mov   esi,br
call  print
jmp   no_message
has_a_space:
mov   esi,stars
call  print
pop   esi
jmp   look_for_message
no_message:
pop   esi
pop   ecx
mov   esi,ebx
dec   ecx
jz    has_nothing
mov   edi,0x70000
jmp   has_irc_data_rep
has_nothing:
ret

stars db "*** ",0

irc_ping db "PING :",0
irc_pong db "PONG :",0
irc_error db "ERROR :",0

scancode db 0
key db 0

key_table_nothing:
;    0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29
dd   0, 27,'1','2','3','4','5','6','7','8','9','0','ÃŸ',"'",  8,  9,'q','w','e','r','t','z','u','i','o','p','Ã¼','+', 10,  0
;   30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56  57  58  59
dd 'a','s','d','f','g','h','j','k','l','Ã¶','Ã¤','^',  1,'#','y','x','c','v','b','n','m',',','.','-',  1,'*',  0,' ',  2,  0
;   60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84  85  86
dd   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,'*','7','8','9','-','4','5','6','+','1','2','3','0',  0,  0,  0,'<'

key_table_shift:
;    0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29
dd   0, 27,'!','"','Â§','$','%','&','/','(',')','=','?',"'",  8,  9,'Q','W','E','R','T','Z','U','I','O','P','Ãœ','*', 10,  0
;   30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56  57  58  59
dd 'A','S','D','F','G','H','J','K','L',':','"','@',  1,"'",'Y','X','C','V','B','N','M',';',':','_',  1,'*',  0,' ',  2,  0
;   60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84  85  86
dd   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,'*','7','8','9','-','4','5','6','+','1','2','3','0',  0,  0,  0,'>'

up_state db 0
string_pos dd 0x1000
has_new_string dd 0

kbd_handler:
pushad
in    al,0x64
test  al,1
jz    no_key
mov   [key],1
in    al,0x60
mov   [scancode],al
cmp   al,1
jne   no_key
;Escape
mov   [key],0 ;Das will doch keiner wissen
cmp   [con_status],2
jne   reset_now
xor   ecx,ecx
mov   edx,TCP_FIN+TCP_ACK
call  send_tcp_packet
mov   [con_status],3
jmp   kbd_done
no_key:
cmp   al,0x55
je    kbd_done
cmp   al,0xEE
je    kbd_done
cmp   al,0xFA
je    kbd_done
cmp   al,0xFD
je    kbd_done
cmp   al,0xFE ;FIXME
je    kbd_done
cmp   al,0xE0 ;FIXME
je    kbd_done
cmp   al,0xE1 ;FIXME
je    kbd_done
and   eax,0x7F
cmp   [up_state],1
je    use_upper_table
mov   ebx,key_table_nothing
jmp   use_table
use_upper_table:
mov   ebx,key_table_shift
use_table:
shl   eax,2
mov   edx,[ebx+eax]
or    edx,edx
jz    kbd_done
cmp   edx,1
je    is_shift
cmp   edx,2
je    is_caps
test  [scancode],0x80
jnz   kbd_done
cmp   edx,8 ;Backspace
je    backspace
mov   edi,[string_pos]
mov   al,dl
stosb
inc   [string_pos]
cmp   edx,10
jne   kbd_done
xor   al,al
stosb
and   edi,0xF000
mov   [has_new_string],edi
cmp   edi,0x2000
jne   make_it_high_now
mov   [string_pos],0x1000
mov   edi,0x1000
mov   ecx,1024
xor   eax,eax
rep   stosd
jmp   kbd_done
make_it_high_now:
mov   [string_pos],0x2000
mov   edi,0x2000
mov   ecx,1024
xor   eax,eax
rep   stosd
kbd_done:
call  update_input
mov   al,0x20
out   0x20,al
popad
iret
is_shift:
xor   [up_state],1
jmp   kbd_done
is_caps:
test  [scancode],0x80
jz    kbd_done
xor   [up_state],1
jmp   kbd_done
backspace:
test  [string_pos],0xFFF
jz    kbd_done
dec   [string_pos]
mov   edi,[string_pos]
xor   al,al
stosb
jmp   kbd_done

reset_now:
xor   ecx,ecx
mov   edx,TCP_RST
call  send_tcp_packet
mov   al,0xFE
out   0x64,al
cli
hlt

gen_irq_handler:
push  eax
mov   al,0x20
out   0x20,al
out   0xA0,al
pop   eax
iret

gen_int_handler:
iret


numbuf db 0,0,0,0,0,0,0,0,0,0,0
;eax: Zahl
print_number:
pushad
mov   ecx,eax
mov   edi,numbuf+10
xor   al,al
mov   [edi],al
mov   ebx,10
print_number_get:
dec   edi
mov   eax,ecx
cdq
div   ebx
mov   ecx,eax
mov   eax,edx
add   al,'0'
mov   [edi],al
or    ecx,ecx
jnz   print_number_get
mov   esi,edi
call  print
popad
ret

hexbuf db 0,0,0,0,0,0,0,0,0
;eax: Zahl
print_hex:
pushad
mov   ecx,eax
mov   edi,hexbuf+8
xor   al,al
mov   [edi],al
print_hex_get:
dec   edi
mov   eax,ecx
and   eax,0xF
shr   ecx,4
cmp   al,10
jae   do_hex_add
add   al,'0'
print_hex_store:
mov   [edi],al
or    ecx,ecx
jnz   print_hex_get
mov   esi,edi
call  print
popad
ret
do_hex_add:
add   al,'A'-10
jmp   print_hex_store

if wrong = 0
cur_x dd 0
cur_y dd 0
else
cur_x dd 79
cur_y dd 23
end if
;esi: String
print:
pushad
call  print_calc
print_loop:
lodsb
or    al,al
jz    print_quit
cmp   al,10
je    print_do_lf
stosb
mov   al,7
stosb
if wrong = 1
sub   edi,4
mov   eax,[cur_x]
dec   [cur_x]
cmp   eax,0
je    print_do_lf
else
inc   [cur_x]
cmp   [cur_x],80
jae   print_do_lf
end if
jmp   print_loop
print_do_lf:
if wrong = 0
inc   [cur_y]
mov   [cur_x],0
cmp   [cur_y],24
jae   print_do_pagemove
else
mov   eax,[cur_y]
dec   [cur_y]
mov   [cur_x],79
cmp   eax,0
je    print_do_pagemove
end if
call  print_calc
jmp   print_loop
print_do_pagemove:
if wrong = 0
mov   [cur_y],23
mov   edi,0xB8E60
else
mov   [cur_y],0
mov   edi,0xB809E
end if
pushad
if wrong = 0
mov   esi,0xB80A0
mov   edi,0xB8000
mov   ecx,960
rep   movsd
mov   edi,0xB8E60
mov   ecx,40
mov   eax,0x07000700
rep   stosd
else
mov   ecx,23
mov   esi,0xB8DC0
mov   edi,0xB8E60
move_page_bw:
push  ecx
mov   ecx,40
rep   movsd
sub   esi,0x140
sub   edi,0x140
pop   ecx
loop  move_page_bw
mov   edi,0xB8000
mov   ecx,40
mov   eax,0x07000700
rep   stosd
end if
popad
jmp   print_loop
print_calc:
mov   eax,[cur_y]
mov   ebx,160
cdq
mul   ebx
mov   edx,[cur_x]
shl   edx,1
add   eax,edx
mov   edi,0xB8000
add   edi,eax
ret
print_quit:
popad
ret

update_input:
pushad
mov   edi,0xB8F00
mov   eax,0x17201720
mov   ecx,40
rep   stosd
mov   ebx,[string_pos]
and   ebx,0xF000
call  strlen
cmp   eax,79
jb    no_movement_needed
sub   eax,79
add   ebx,eax
no_movement_needed:
mov   esi,ebx
if wrong = 0
mov   edi,0xB8F00
else
mov   edi,0xB8F9E
end if
print_the_input:
lodsb
or    al,al
jz    input_printed
cmp   al,10
je    print_the_input
stosb
if wrong = 1
sub   edi,2
end if
mov   al,0x17
stosb
if wrong = 1
sub   edi,2
end if
jmp   print_the_input
input_printed:
sub   edi,0xB8F00
shr   edi,1
add   edi,24*80
mov   al,15
mov   edx,0x3D4
out   dx,al
inc   edx
mov   eax,edi
out   dx,al
dec   edx
push  eax
mov   al,14
out   dx,al
pop   eax
inc   dx
shr   eax,8
out   dx,al
popad
ret

strlen:
push  ecx
push  esi
mov   esi,ebx
xor   ecx,ecx
strlen_wait:
inc   ecx
lodsb
or    al,al
jnz   strlen_wait
dec   ecx
mov   eax,ecx
pop   esi
pop   ecx
ret

times (512*12)-($-$$) db 0