.include "m8515def.inc" // ���������� ������������ ���� ATMega8115
//.include "ComPort.asm"

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


;******������� ����(������)******************************
MAIN:
	RJMP MAIN


;==========[[����� �� USART]]========================================================================
USART_RX:	
	CLI     //���������� ������ ���������� 
	IN		temp,UDR

	CPI temp, 0x31
	BREQ FIRST_BUTTON

	CPI temp, 0x32
	BREQ SECOND_BUTTON

	CPI temp, 0x33
	BREQ THIRD_BUTTON

 	cbi BTN_PIN, 0 // ������� ���
	SEI     //���������� ���������� ����������
	RETI

FIRST_BUTTON:
	LDI led_timing, 4//�������� �������, ������ � � ���������� �� ��������, ����-�������� ������

	CPI is_blink, 0
	BREQ ENABLE_BLINK

	CPI is_blink, 1
	BREQ DISABLE_BLINK

	rjmp USART_VIX


SECOND_BUTTON:
	RJMP INVERT

THIRD_BUTTON:
	LDI led_timing, 6//�������� 1.2, ������ � � ���������� �� ��������, ����-�������� ������

	CPI is_blink, 0
	BREQ ENABLE_BLINK

	CPI is_blink, 1
	BREQ DISABLE_BLINK

	rjmp USART_VIX


//FOURTH_BUTTON:


//FIFTH_BUTTON:


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

;==========[[������]]========================================================================

TIM0_OVF:
	CLI
	CPI is_blink, 0
	BREQ END

	INC led_counter

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
