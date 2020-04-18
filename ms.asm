.include "m8515def.inc" // Подключаем заголовочный файл ATMega8115

.equ 	Frqnc = 8000000						;Частота МП в Гц
.equ 	BaudRate = 19200					;Скорость передачи  по UART
.equ 	Rate = Frqnc/(16*BaudRate)-1		;Определение параметра UBRR
.equ	BTN_PIN	=PINA


.def temp = r16 // Присваиваем символические имена регистрам
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


;-----------|Установка таймера|------------------------------------------------------------------------
SETUP:

	LDI		temp,low(RAMEND) 	;инициализация стека для работы команд RCall и RET а так же прерываний
	OUT		SPL,temp			;
	LDI		temp,high(RAMEND)	;
	OUT		SPH,temp			;

	LDI temp, 0xFF
	OUT TCNT0, temp

	//TCCR0 - регистр предделителя
	//TIMSK - счетный регистр
	LDI	TEMP,0b00000010				;С. 258 TCCR0    //OCIE0 - разрешение прерываний по совпадению 
	OUT TIMSK, TEMP

	LDI	TEMP,0b00000101			;С. 270 TCCR0    //выбор предделителяна 1024 
	OUT TCCR0,TEMP

	LDI	temp,0b11111111
	OUT	DDRB,temp					;Установка режима работы OUT

	LDI led_states, 0b00001111//Устанавливаем начальное состояние
	LDI led_timing, 0 
	LDI is_blink, 0
	LDI is_print_name, 0
	LDI button_counter, 0

;-----------|Установка USART|------------------------------------------------------------------------
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

	LDI		temp,(1<<RXCIE)|(1<<RXEN)|(1<<TXEN)   ;RXCE-hразрешение прерывания по завершению приема  RXEN-разрешение приема 
			                                             ; TXEN- разрешение передачи
	OUT		UCSRB,temp; установка битов в регистр  UCSRB

	LDI		temp,(1<<UCSZ0)|(1<<UCSZ1)|(1<<URSEL)  ;UCSZ0,UCSZ1-определение количества бит данных на 8 бит 
			                                              ;URSEL-выбираем регистр UCSRC, а не UBRR
	OUT		UCSRC,temp; установка битов в регистр  UCSRC
	
	LDI		temp,0b00000000
	OUT		DDRA,temp					;Установка режима работы IN

	SEI		//Разрешаем глобавльное прерывание


;******Главный цикл******************************
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

;==========[[Прием по USART]]========================================================================
USART_RX:	
	CLI     //глобальный запрет прерываний 
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

 	//cbi BTN_PIN, 0 // Очищаем бит
	SEI     //глобальное разрешение прерываний
	RETI

FIRST_BUTTON:
	LDI led_timing, 4//Примерно секунда, меняем и в зависмости от значения, чаще-медленее мигает

	CPI is_blink, 0
	BREQ ENABLE_BLINK

	CPI is_blink, 1
	BREQ DISABLE_BLINK

	RJMP USART_VIX


SECOND_BUTTON:
	RJMP INVERT

THIRD_BUTTON:
	LDI led_timing, 6//Примерно 1.2, меняем и в зависмости от значения, чаще-медленее мигает

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
	SEI //Разрешаем прерывание
	RETI //Завершаем текущее прерывание

;====================================================================================================

;==========[[Отправка по USART]]=====================================================================
USART_TX:
	CLI    //глобальный запрет прерываний 
	OUT		UDR,temp
	SBIS	UCSRA,UDRE     //если бит установлен пропускаем следующую команду UDRE_флаг опустошение регистра передатчика
			                       //1-если буфер пустой 
	RJMP	PC-1
	SEI    //глобальное разрешение прерываний
	RET

//Выводим первое имя
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
	LDI		temp,13						;CR    //возврат каретки 
	RCALL	USART_TX
	LDI		temp,10						;LF    //перевод строки
	RCALL	USART_TX

	inc		is_print_name //Инк счетчик, чтобы не было повторного срабатывания
	RET	

//Выводим второе имя
PRINT_SECOND_NAME:
	LDI		temp,69						;E
	RCALL	USART_TX
	LDI		temp,103					;g
	RCALL	USART_TX
    LDI		temp,111					;o
	RCALL	USART_TX
	LDI		temp,114					;r
	RCALL	USART_TX
	LDI		temp,13						;CR    //возврат каретки 
	RCALL	USART_TX
	LDI		temp,10						;LF    //перевод строки
	RCALL	USART_TX
	inc		is_print_name //Инк счетчик, чтобы не было повторного срабатывания
	RET	

PRINT_LED_STATE:

	SBRC 	led_states, 0 //Проверяем, если нулевой бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 0 //Проверяем, если нулевой бит установлен, то выводим 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 1 //Проверяем, если первый бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 1 //Проверяем, если первый бит установлен, то выводим 1
	RCALL	PRINT_ONE
	
	SBRC	led_states, 2 //Проверяем, если второй бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 2 //Проверяем, если второй бит установлен, то выводим 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 3 //Проверяем, если третий бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 3//Проверяем, если третий бит установлен, то выводим 1
	RCALL	PRINT_ONE
	
	SBRC	led_states, 4 //Проверяем, если четвертый бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 4//Проверяем, если четвертый бит установлен, то выводим 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 5 //Проверяем, если пятый бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 5//Проверяем, если пятый бит установлен, то выводим 1
	RCALL	PRINT_ONE
	
	SBRC	led_states, 6 //Проверяем, если шестой бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 6//Проверяем, если шестой бит установлен, то выводим 1
	RCALL	PRINT_ONE

	SBRC 	led_states, 7 //Проверяем, если седьмой бит не установлен, то выводим 0
	RCALL	PRINT_ZERO
	
	SBRS	led_states, 7 //Проверяем, если седьмой бит установлен, то выводим 1
	RCALL	PRINT_ONE
	
	LDI		temp, 0

	RCALL	USART_TX
	LDI		temp,13						;CR    //возврат каретки 
	RCALL	USART_TX
	LDI		temp,10						;LF    //перевод строки
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

;==========[[Таймер]]========================================================================

TIM0_OVF:
	CLI
	//IN		current_button,BTN_PIN   //подключение кнопок
	INC button_counter
	INC led_counter

	CPI is_blink, 0
	BREQ END
	

	RCALL BLINK

BLINK:
	CP led_counter, led_timing//Сравниваем счетчик, с таймером, если меньше чем тайминг, то =>
	BRLO END //Выходим из цикла, ничего не делаем
	
	//TODO Можно поменять, и использовать stack
	CPI	led_states, 0b11110000//сравниваем, если диоды в конечном состоянии, и сдвигать больше некуда, то =>
	BREQ put_over //Перекидываем первую единицу в начало, далее аналогично

	CPI led_states, 0b11100001
	BREQ put_over

	CPI led_states, 0b11000011
	BREQ put_over

	CPI led_states, 0b10000111
	BREQ put_over

	LSL led_states //Логическое смещение состояния светодиодов 00001111 => 00011110
	RJMP vix

PUT_OVER:
	LSL led_states //Смещение в лево
	INC led_states //Инкреминтируем
	RJMP vix

INVERT:
	LDI temp, 255 // 255=11111111
	EOR	led_states, temp //EOR перевернет текущее состояние светодиодов
	RJMP VIX

VIX:
	LDI led_counter,0 //Обнуляем счетчик
	RJMP PORT_OUT // вызываем метку PORT_OUT

PORT_OUT:
	OUT PORTB, led_states  //Выводим на порт текущее состояние светодиодов
	RJMP END //Завершаем текущее прерывание

END:
	SEI //Разрешаем прерывание
	RETI //Завершаем текущее прерывание

;====================================================================================================
