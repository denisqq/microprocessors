.include "m8515def.inc" // ���������� ������������ ���� ATMega8115

.equ 	Frqnc = 8000000						;������� �� � ��
.equ 	BaudRate = 19200					;�������� ��������  �� UART
.equ 	Rate = Frqnc/(16*BaudRate)-1		;����������� ��������� UBRR
.equ	BTN_PIN	=PINA


.def temp = r16 // ����������� ������������� ����� ���������
.def led_states = r17
.def led_counter = r18
.def led_timing = r19
.def is_blink = r20
.def current_button = r21
.def is_print_name = r22
.def button_counter = r24

.cseg

.org 0
	rjmp SETUP	
.org $007 
	rjmp TIM0_OVF ; Timer1 Overflow Handler

.ORG URXCaddr			
	RJMP	USART_RX


;-----------|��������� �������|------------------------------------------------------------------------
SETUP:

	LDI		temp,low(RAMEND) 	;������������� ����� ��� ������ ������ RCall � RET � ��� �� ����������
	OUT		SPL,temp			;
	LDI		temp,high(RAMEND)	;
	OUT		SPH,temp			;

	LDI temp, 0xFF
	OUT TCNT0, temp

	//TCCR0 - ������� ������������
	//TIMSK - ������� �������
	LDI	TEMP,0b00000010				;�. 258 TCCR0    //OCIE0 - ���������� ���������� �� ���������� 
	OUT TIMSK, TEMP

	LDI	TEMP,0b00000101			;�. 270 TCCR0    //����� �������������� 1024 
	OUT TCCR0,TEMP

	LDI	temp,0b11111111
	OUT	DDRB,temp					;��������� ������ ������ OUT

	LDI led_states, 0b00001111//������������� ��������� ���������
	LDI led_timing, 0 
	LDI is_blink, 0
	LDI is_print_name, 0
	LDI button_counter, 0

;-----------|��������� USART|------------------------------------------------------------------------
USART_SETUP:
	LDI		temp,HIGH(Rate)
	OUT		UBRRH,temp
	LDI		temp,LOW(Rate)
	OUT		UBRRL,temp

	IN		temp,EMCUCR
	ANDI	temp,0b01111111				;SM0<<0
	OUT		EMCUCR,temp

	IN		temp,MCUCR
	SBR		temp,(1<<SE)
	ANDI	temp,0b11101111				;SM1<<0
	OUT		MCUCR,temp

	IN		temp,MCUCSR
	SBR		temp,0b11011111				;SM2<<0
	OUT		MCUCSR,temp

	LDI		temp,(1<<RXCIE)|(1<<RXEN)|(1<<TXEN)   ;RXCE-h���������� ���������� �� ���������� ������  RXEN-���������� ������ 
			                                             ; TXEN- ���������� ��������
	OUT		UCSRB,temp; ��������� ����� � �������  UCSRB

	LDI		temp,(1<<UCSZ0)|(1<<UCSZ1)|(1<<URSEL)  ;UCSZ0,UCSZ1-����������� ���������� ��� ������ �� 8 ��� 
			                                              ;URSEL-�������� ������� UCSRC, � �� UBRR
	OUT		UCSRC,temp; ��������� ����� � �������  UCSRC
	
	LDI		temp,0b00000000
	OUT		DDRA,temp					;��������� ������ ������ IN

	SEI		//��������� ����������� ����������


;******������� ����******************************
MAIN:
	RCALL BUTTON_TIMER
	RJMP MAIN

BUTTON_TIMER:
	CPI button_counter, 6
	BRGE BUTTON_HANDLER
	RET

BUTTON_HANDLER:

	SBIS	BTN_PIN,0x01
	RCALL	FIRST_BUTTON

	SBIS	BTN_PIN,0x02
	RCALL	SECOND_BUTTON

	SBIS	BTN_PIN,0x03
	RCALL	THIRD_BUTTON

	SBIS	BTN_PIN,0x04
	RCALL	FOURTH_BUTTON

	SBIS	BTN_PIN,0x05
	RCALL	FIFTH_BUTTON
	LDI button_counter, 0
	RET

;==========[[����� �� USART]]========================================================================
USART_RX:	
	CLI     //���������� ������ ���������� 
	IN	temp,UDR

	CPI temp, 0x31
	BREQ FIRST_BUTTON

	CPI temp, 0x32
	BREQ SECOND_BUTTON

	CPI temp, 0x33
	BREQ THIRD_BUTTON

	CPI temp, 0x34
	BREQ FOURTH_BUTTON

	CPI temp, 0x35
	BREQ FIFTH_BUTTON

 	//cbi BTN_PIN, 0 // ������� ���
	SEI     //���������� ���������� ����������
	RETI

FIRST_BUTTON:
	LDI led_timing, 4//�������� �������, ������ � � ���������� �� ��������, ����-�������� ������

	CPI is_blink, 0
	BREQ ENABLE_BLINK

	CPI is_blink, 1
	BREQ DISABLE_BLINK

	RJMP USART_VIX


SECOND_BUTTON:
	RJMP INVERT

THIRD_BUTTON:
	LDI led_timing, 6//�������� 1.2, ������ � � ���������� �� ��������, ����-�������� ������

	CPI is_blink, 0
	BREQ ENABLE_BLINK

	CPI is_blink, 1
	BREQ DISABLE_BLINK

	RJMP USART_VIX


FOURTH_BUTTON:
	CPI is_print_name, 0
	BREQ PRINT_FIRST_NAME

	CPI is_print_name, 1
	BREQ PRINT_SECOND_NAME

	RJMP USART_VIX

FIFTH_BUTTON:
	ldi	 led_timing, 7
	RJMP PRINT_LED_STATE 


ENABLE_BLINK:
	LDI is_blink, 1
	RJMP USART_VIX

DISABLE_BLINK:
	LDI is_blink, 0
	RJMP USART_VIX

USART_VIX:
	SEI //��������� ����������
	RETI //��������� ������� ����������

;====================================================================================================

;==========[[�������� �� USART]]=====================================================================
USART_TX:
	CLI    //���������� ������ ���������� 
	OUT		UDR,temp
	SBIS	UCSRA,UDRE     //���� ��� ���������� ���������� ��������� ������� UDRE_���� ����������� �������� �����������
			                       //1-���� ����� ������ 
	RJMP	PC-1
	SEI    //���������� ���������� ����������
	RET

//������� ������ ���
PRINT_FIRST_NAME:
	LDI		temp,68						;D
	RCALL	USART_TX
	LDI		temp,101					;e
	RCALL	USART_TX
    LDI		temp,110					;n
	RCALL	USART_TX
	LDI		temp,105					;i
	RCALL	USART_TX
	LDI		temp,115					;s
	RCALL	USART_TX
	LDI		temp,13						;CR    //������� ������� 
	RCALL	USART_TX
	LDI		temp,10						;LF    //������� ������
	RCALL	USART_TX

	inc		is_print_name //��� �������, ����� �� ���� ���������� ������������
	RET	

//������� ������ ���
PRINT_SECOND_NAME:
	LDI		temp,69						;E
	RCALL	USART_TX
	LDI		temp,103					;g
	RCALL	USART_TX
    LDI		temp,111					;o
	RCALL	USART_TX
	LDI		temp,114					;r
	RCALL	USART_TX
	LDI		temp,13						;CR    //������� ������� 
	RCALL	USART_TX
	LDI		temp,10						;LF    //������� ������
	RCALL	USART_TX
	inc		is_print_name //��� �������, ����� �� ���� ���������� ������������
	RET	

PRINT_LED_STATE:

	SBRC 	led_states, 0 //���������, ���� ������� ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 0 //���������, ���� ������� ��� ����������, �� ������� 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 1 //���������, ���� ������ ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 1 //���������, ���� ������ ��� ����������, �� ������� 1
	RCALL	PRINT_ONE
	
	SBRC	led_states, 2 //���������, ���� ������ ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 2 //���������, ���� ������ ��� ����������, �� ������� 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 3 //���������, ���� ������ ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 3//���������, ���� ������ ��� ����������, �� ������� 1
	RCALL	PRINT_ONE
	
	SBRC	led_states, 4 //���������, ���� ��������� ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 4//���������, ���� ��������� ��� ����������, �� ������� 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 5 //���������, ���� ����� ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 5//���������, ���� ����� ��� ����������, �� ������� 1
	RCALL	PRINT_ONE
	
	SBRC	led_states, 6 //���������, ���� ������ ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 6//���������, ���� ������ ��� ����������, �� ������� 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 7 //���������, ���� ������� ��� �� ����������, �� ������� 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 7 //���������, ���� ������� ��� ����������, �� ������� 1
	RCALL	PRINT_ONE
	
	LDI		temp, 0

	RCALL	USART_TX
	LDI		temp,13						;CR    //������� ������� 
	RCALL	USART_TX
	LDI		temp,10						;LF    //������� ������
	RCALL	USART_TX
	RET

PRINT_ONE:
	LDI 	temp, 0x31
	RCALL	USART_TX
	RET
PRINT_ZERO:
	LDI temp,0x30
	RCALL	USART_TX
	RET
;====================================================================================================

;==========[[������]]========================================================================

TIM0_OVF:
	CLI
	//IN		current_button,BTN_PIN   //����������� ������
	INC button_counter
	INC led_counter

	CPI is_blink, 0
	BREQ END
	

	RCALL BLINK

BLINK:
	CP led_counter, led_timing//���������� �������, � ��������, ���� ������ ��� �������, �� =>
	BRLO END //������� �� �����, ������ �� ������
	
	//TODO ����� ��������, � ������������ stack
	CPI	led_states, 0b11110000//����������, ���� ����� � �������� ���������, � �������� ������ ������, �� =>
	BREQ put_over //������������ ������ ������� � ������, ����� ����������

	CPI led_states, 0b11100001
	BREQ put_over

	CPI led_states, 0b11000011
	BREQ put_over

	CPI led_states, 0b10000111
	BREQ put_over

	LSL led_states //���������� �������� ��������� ����������� 00001111 => 00011110
	RJMP vix

PUT_OVER:
	LSL led_states //�������� � ����
	INC led_states //��������������
	RJMP vix

INVERT:
	LDI temp, 255 // 255=11111111
	EOR	led_states, temp //EOR ���������� ������� ��������� �����������
	RJMP VIX

VIX:
	LDI led_counter,0 //�������� �������
	RJMP PORT_OUT // �������� ����� PORT_OUT

PORT_OUT:
	OUT PORTB, led_states  //������� �� ���� ������� ��������� �����������
	RJMP END //��������� ������� ����������

END:
	SEI //��������� ����������
	RETI //��������� ������� ����������

;====================================================================================================
