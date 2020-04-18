.include "m8515def.inc" // Подключаем заголовочный файл ATMega8115
.def temp = r16 // Присваиваем символические имена регистрам
.def led_states = r17
.def led_counter = r18
.def led_timing = r19

.cseg
.org 0
	rjmp SETUP	
.org $007 
	rjmp TIM0_OVF ; Timer1 Overflow Handler

;****** Инициализация******************************
SETUP:
	ldi temp, HIGH(RAMEND)
	out sph, temp
	ldi temp, LOW(RAMEND)
	out spl, temp
	
	ldi temp, 0xFF
	out TCNT0, temp

	//TCCR0 - регистр предделителя
	//TIMSK - счетный регистр
	ldi	TEMP,0b00000010				;С. 258 TCCR0    //OCIE0 - разрешение прерываний по совпадению 
	out TIMSK, TEMP

	ldi	TEMP,0b00000101			;С. 270 TCCR0    //выбор предделителяна 1024 
	out TCCR0,TEMP

	LDI	temp,0b11111111
	OUT	DDRB,temp					;Установка режима работы OUT

	ldi led_states, 0b00001111//Устанавливаем начальное состояние
	ldi led_timing, 20 //Примерно секунда, меняем и в зависмости от значения, чаще-медленее мигает

	sei //Разрешаем прерывания

;******Главный цикл(пустой)******************************
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
	cp led_counter, led_timing//Сравниваем счетчик, с таймером, если меньше чем тайминг, то =>
	brlo END //Выходим из цикла, ничего не делаем
	
	//TODO Можно поменять, и использовать stack
	cpi	led_states, 0b11110000//сравниваем, если диоды в конечном состоянии, и сдвигать больше некуда, то =>
	breq put_over //Перекидываем первую единицу в начало, далее аналогично

	cpi led_states, 0b11100001
	breq put_over

	cpi led_states, 0b11000011
	breq put_over

	cpi led_states, 0b10000111
	breq put_over

	lsl led_states //Логическое смещение состояния светодиодов 00001111 => 00011110
	rjmp vix

PUT_OVER:
	lsl led_states
	inc led_states
	rjmp vix

INVERT:
	ldi temp, 255 // 255=11111111
	eor	led_states, temp //EOR перевернет текущее состояние светодиодов
	rjmp vix

VIX:
	ldi led_counter,0 //Обнуляем счетчик
	rjmp PORT_OUT // вызываем метку PORT_OUT

PORT_OUT:
	out PORTB, led_states  //Выводим на порт текущее состояние светодиодов
	rjmp END //Завершаем текущее прерывание

END:
	sei //Разрешаем прерывание
	reti //Завершаем текущее прерывание
