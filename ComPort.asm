;Ia?aaa?a ii UART (Com ii?o)
ComInit:											;eieoeaeecaoey Com ii?oa 

		Ldi		r17,$00								;
;		Ldi		r16,$0C								;19200 eaia =12D(0Nh) i?e ?aaioa io eaa?oaaiai aaia?aoi?a 4 IAo STK500 (ia?aiu?ea OSCEL EA, io?ai eaa?o 4 IAo)
		Ldi		r16,$0B								;19200 eaia =11D(0Bh) i?e ?aaioa io aiaoi. oaeoiaiai neaiaea 3.686 IAo STK500 (ia?aiu?ea OSCEL IA, ia io?ai eaa?o)
		out 	UBRRH, r17							;a UBRRH
		out 	UBRRL, r16							;a UBRRL

 		ldi 	r16, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)			;Enable receiver and transmitter e i?a?uaaiey ii i?e?io
		out 	UCSRB,r16							;UCSRB
 
    	ldi 	r16, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0);|(1<<UPM0)|(1<<UPM1);Set frame format: 8data, 1stop bit
		out 	UCSRC,r16							;UCSRC
		sei
		Ret											;aica?ao ec iiai?ia?aiiu

ComStop: 	
		ldi 	r16, (1<<RXEN)|(1<<TXEN)			;No Enable receiver and transmitter
		out 	UCSRB,r16							;UCSRB
		Ret											;aica?ao ec iiai?ia?aiiu

;Ia?aaa?a aaeoa ii NII
TxCh:		sbis	UCSRA,UDRE		;i?eaaiea oeaaa (UDRE=1)iionoioaiey aooa?a COM ii?oa 
			rjmp	TxCh			;iao aioiaiinoe ii?oa e ia?aaa?a UDRE=0, iiaoi?eou i?eaaiea
			out		UDR,R20			;ionoie e aioia, caa?o?aai aaeo aaiiuo
			ret						;eiiao TxCh,	aica?ao
									
;I?eai aaeoa ii NII
RxCh:			Sbic 	PINA,0x04	;Anee A.4 eiiiea aua ia?aoa (= 0), oi ia?ai?uaioou iaio eiiaao aiec
				RJmp	Res1		;A.4 eiiiea o?a io?aoa (= 1), auoia ia aa?oiaa eieuoi LOOP: ioeoaa e i?eoee e i?eaaou eaeo? ieaoau eiiieo (A.0-A.4)aianoi RET
			sbis	UCSRA,Rxc		;anou oeaa i?eaia aaeoa ii COM ii?oo? 
			rjmp	RxCh			;iao i?eaia aaeoa, iiaoi?eou i?eaaiea
			In		R21,UDR			;aa, anou. ?eoaou i?eiyoue aaeo aaiiuo a R21
			ret						;aica?ao
