;Передача по UART (Com порт)
ComInit:											;инициализация Com порта 

		Ldi		temp2,$00								;
;		Ldi		r16,$0C								;19200 кбод =12D(0Сh) при работе от кварцевого генератора 4 МГц STK500 (перемычка OSCEL КГ, нужен кварц 4 МГц)
		Ldi		temp,$0B								;19200 кбод =11D(0Bh) при работе от внешн. тактового сигнала 3.686 МГц STK500 (перемычка OSCEL ПГ, не нужен кварц)
		out 	UBRRH, temp2							;в UBRRH
		out 	UBRRL, temp							;в UBRRL

 		ldi 	temp, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)			;Enable receiver and transmitter и прерывания по приёму
		out 	UCSRB,temp									;UCSRB
 
    	ldi 	temp, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)  		;|(1<<UPM0)|(1<<UPM1);Set frame format: 8data, 1stop bit
		out 	UCSRC,temp									;UCSRC
		sei
		Ret											;возврат из подпрограммы

ComStop: 	
		ldi 	temp, (1<<RXEN)|(1<<TXEN)			;No Enable receiver and transmitter
		out 	UCSRB,temp							;UCSRB
		Ret											;возврат из подпрограммы

;Передача байта по СОМ
TxCh:		sbis	UCSRA,UDRE		;ожидание флага (UDRE=1)опустошения буфера COM порта 
			rjmp	TxCh			;нет готовности порта к передаче UDRE=0, повторить ожидание
			out		UDR,R20			;пустой и готов, загружаем байт данных
			ret						;конец TxCh,	возврат
									
;Прием байта по СОМ
RxCh:		Sbic 	PINA,0x04	;Если A.4 кнопка еще нажата (= 0), то перепрыгнуть одну комаду вниз
			RJmp	Res1		;A.4 кнопка уже отжата (= 1), выход на верхнее кольцо LOOP: откуда и пришли и ожидать какую нибудь кнопку (А.0-А.4)вместо RET
			sbis	UCSRA,Rxc		;есть флаг приема байта по COM порту? 
			rjmp	RxCh			;нет приема байта, повторить ожидание
			In		R21,UDR			;да, есть. Читать принятый байт данных в R21
			ret						;возврат
