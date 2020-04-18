;�������� �� UART (Com ����)
ComInit:											;������������� Com ����� 

		Ldi		temp2,$00								;
;		Ldi		r16,$0C								;19200 ���� =12D(0�h) ��� ������ �� ���������� ���������� 4 ��� STK500 (��������� OSCEL ��, ����� ����� 4 ���)
		Ldi		temp,$0B								;19200 ���� =11D(0Bh) ��� ������ �� �����. ��������� ������� 3.686 ��� STK500 (��������� OSCEL ��, �� ����� �����)
		out 	UBRRH, temp2							;� UBRRH
		out 	UBRRL, temp							;� UBRRL

 		ldi 	temp, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)			;Enable receiver and transmitter � ���������� �� �����
		out 	UCSRB,temp									;UCSRB
 
    	ldi 	temp, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)  		;|(1<<UPM0)|(1<<UPM1);Set frame format: 8data, 1stop bit
		out 	UCSRC,temp									;UCSRC
		sei
		Ret											;������� �� ������������

ComStop: 	
		ldi 	temp, (1<<RXEN)|(1<<TXEN)			;No Enable receiver and transmitter
		out 	UCSRB,temp							;UCSRB
		Ret											;������� �� ������������

;�������� ����� �� ���
TxCh:		sbis	UCSRA,UDRE		;�������� ����� (UDRE=1)����������� ������ COM ����� 
			rjmp	TxCh			;��� ���������� ����� � �������� UDRE=0, ��������� ��������
			out		UDR,R20			;������ � �����, ��������� ���� ������
			ret						;����� TxCh,	�������
									
;����� ����� �� ���
RxCh:		Sbic 	PINA,0x04	;���� A.4 ������ ��� ������ (= 0), �� ������������ ���� ������ ����
			RJmp	Res1		;A.4 ������ ��� ������ (= 1), ����� �� ������� ������ LOOP: ������ � ������ � ������� ����� ������ ������ (�.0-�.4)������ RET
			sbis	UCSRA,Rxc		;���� ���� ������ ����� �� COM �����? 
			rjmp	RxCh			;��� ������ �����, ��������� ��������
			In		R21,UDR			;��, ����. ������ �������� ���� ������ � R21
			ret						;�������
