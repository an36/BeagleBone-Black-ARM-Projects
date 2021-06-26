/*
	ECE372 | Project 2: Part1 (Testing I2C signals)
	
	The program below Initializes I2C1 one, and sends a signal 
	to the slave address 0x60 using Polling.  The program Polls the
	Bus Busy bit and if the bus if free then the program sends a 
	Byte to the motor controller.  The SDA and SCL signals can
	be detected using an oscilloscope.
	
	Uses: R0-R2 and I2C1.
	
	Author: Abdullah Almarzouq		|     March 2020
*/



.text
.global _start
_start:
		@Changing from mode 0 to mode 2
		LDR R0,=0x44E10000			@Base address of control Module
		MOV R1,#0x0000003A			@Value to connect I2C_SCL to pin 17
		STR R1,[R0,#0x95C]			@Write to conf_spi0_cs0
		MOV R1,#0x0000003A			@Value to connect I2C_SDA to pin 18
		STR R1,[R0,#0x958]			@Write to conf_spi0_d1
		
		@turn on I2C1 clock
		LDR R2,=0x44E00048			@Address of CM_PER_I2C1_CLKCTRL
		MOV R1,#0x2					@Value to turn on clock
		STR R1,[R2]					@Write to I2C control module to trun on clock
		
		LDR R0,=0x4802A000			@Base address of I2C1
		
		@Modifying I2C_CON register yo disable I2C
		MOV R1,#0x0000				@Value to disable I2C_EN bit
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		
		@Scalling frequency and changing to Fast/Standard mode
		MOV R1,#0x3					@Value to change from 48MHz to 12MHz
		STR R1,[R0,#0xB0]			@Write to I2C_PSC register
		
		MOV R1,#0x8					@Value to change SCLL to 400Kbps
		STR R1,[R0,#0xB4]			@Write to I2C_SCLL register
		MOV R1,#0xA					@Value to change SCLH to 400Kbps
		STR R1,[R0,#0xB8]			@Write to I2C_SCLH register
		
		@Configure slave address
		MOV R1,#0x60				@Slave address
		STR R1,[R0,#0xAC]			@Write to I2C_SA register
		
		@Modifying I2C_CON configure register to obtain start condition, set transmitter mode and such
		MOV R1,#0x8600				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		
		B POLL1						@Jump to branch POLL

SEND:@Branch to send a byte through I2C
		MOV R1,#1					@Sending 1 byte only
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0xAA				@The byte to be sent
		STRB R1,[R0,#0x9C]			@Write to I2C_DATA
		B POLL1

POLL1:
		LDR R1,[R0,#0x24]			@Read value in I2C_IRQSTATUS_RAW
		TST R1,#0x1000				@Check is Bus Busy bit is set to 1 (busy)
		BEQ SEND					@If bit is equal to 0 then go to SEND
		B POLL1

		