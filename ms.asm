.include "m8515def.inc" // ���������� ������������ ���� ATMega8115
.def temp = r16 // ����������� ������������� ����� ���������
.def led_states = r17
.def led_counter = r18
.def led_timing = r19

.cseg
.org 0
	rjmp SETUP	
.org $007 
	rjmp TIM0_OVF ; Timer1 Overflow Handler

;****** �������������******************************
SETUP:
	ldi temp, HIGH(RAMEND)
	out sph, temp
	ldi temp, LOW(RAMEND)
	out spl, temp
	
	ldi temp, 0xFF
	out TCNT0, temp

	//TCCR0 - ������� ������������
	//TIMSK - ������� �������
	ldi	TEMP,0b00000010				;�. 258 TCCR0    //OCIE0 - ���������� ���������� �� ���������� 
	out TIMSK, TEMP

	ldi	TEMP,0b00000101			;�. 270 TCCR0    //����� �������������� 1024 
	out TCCR0,TEMP

	LDI	temp,0b11111111
	OUT	DDRB,temp					;��������� ������ ������ OUT

	ldi led_states, 0b00001111//������������� ��������� ���������
	ldi led_timing, 20 //�������� �������, ������ � � ���������� �� ��������, ����-�������� ������

	sei //��������� ����������

;******������� ����(������)******************************
MAIN:
	rjmp MAIN

TIM0_OVF:
	cli
	inc led_counter
	rcall BLINK

FIRST_BUTTON:
	ldi led_timing, 20
	rjmp BLINK

SECOND_BUTTON:
	rjmp INVERT

THIRD_BUTTON:
	ldi led_timing, 25
	rjmp BLINK

//FOURTH_BUTTON:


//FIFTH_BUTTON:

BLINK:
	cp led_counter, led_timing//���������� �������, � ��������, ���� ������ ��� �������, �� =>
	brlo END //������� �� �����, ������ �� ������
	
	//TODO ����� ��������, � ������������ stack
	cpi	led_states, 0b11110000//����������, ���� ����� � �������� ���������, � �������� ������ ������, �� =>
	breq put_over //������������ ������ ������� � ������, ����� ����������

	cpi led_states, 0b11100001
	breq put_over

	cpi led_states, 0b11000011
	breq put_over

	cpi led_states, 0b10000111
	breq put_over

	lsl led_states //���������� �������� ��������� ����������� 00001111 => 00011110
	rjmp vix

PUT_OVER:
	lsl led_states
	inc led_states
	rjmp vix

INVERT:
	ldi temp, 255 // 255=11111111
	eor	led_states, temp //EOR ���������� ������� ��������� �����������
	rjmp vix

VIX:
	ldi led_counter,0 //�������� �������
	rjmp PORT_OUT // �������� ����� PORT_OUT

PORT_OUT:
	out PORTB, led_states  //������� �� ���� ������� ��������� �����������
	rjmp END //��������� ������� ����������

END:
	sei //��������� ����������
	reti //��������� ������� ����������
