/*
	ECE372 | Project 2: Part2 (Stepper Motor)
	
	The program below Initializes I2C1 one, and sends a signal 
	to the motor controller board (PCA9685 chip) using polling method.
	The program Polls the Bus Busy bit and if the bus if free then the 
	program sends the Bytes to the motor controller.  The program
	initializes the PCA9685 chip and modifies the PWMs (LEDn_ON)
	to control the stepper so that the motor steps through a 
	full revolution.
	
	Added features: Button push. When the button is pushed an IRQ interrupt
	happens which lets the motor step 200 steps to perform a full revolution.
	
	Uses: R0-R8, I2C1, GPIO1_29 (button) and adafruit motor controller board.
	
	Author: Abdullah Almarzouq		|     March 2020
*/



.text
.global _start
.global INT_DIRECTOR
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
		MOV R1,#0x00000000			@Slave address to perform a software reser on the PCA9685 chip.
		STR R1,[R0,#0xAC]			@Write to I2C_SA register
		
		@Modifying I2C_CON configure register to obtain start condition, set transmitter mode and such
		MOV R1,#0x8600				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		
		BL POLL1						@Jump to branch POLL
		
init:@This branch initialize the PCA9685 chip
		MOV R1,#1					@Sending 1 byte only
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x06				@Software reset byte
		STRB R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@Poll BB bit
		
		MOV R1,#0x0000				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		
		@Configure slave address
		MOV R1,#0xE0				@Slave address to write to ALLCALL registers
		STR R1,[R0,#0xAC]			@Write to I2C_SA register
		
		MOV R1,#0x8600				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		
		BL POLL1					@Poll BB pit
		
		@Put PCA9685 in sleep by writing a byte to Mode1 register
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x00				@Bytes to access Mode1 register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x11				@put PCA9685 to sleep
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@Poll BB pit
		
		@Change the PCA9685 Prescale register to modify the frequency
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0xFE				@Bytes to access Pre_Scale register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x05				@change to 1Khz
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@Poll BB pit
		
		@Restart PCA9685
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x00				@Bytes to access Mode1 register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x01				@modify sleep bit (set to 0)
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB pit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x00				@Bytes to access Mode1 register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x81				@modify Restart bit (set to 1)
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		@Set Totem Pole Structure and Non-inverted bits in Mode2 register
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x01				@Bytes to access Mode2 register and set totem pole structure and non-inverted bits
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x04				@set totem pole structure and non-inverted bits
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		@Set PWM2 & PWM7 High
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x0F				@Bytes to access LED2_ON_H registe
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x23				@Bytes to access LED7_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		@Zero ALL_LED_OFF_H
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0xFD				@Bytes to access ALL_LED_OFF_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to zero
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		

@@@@@@@@@@@@@@@@@@@@@@@@ Initialize button interrupt (GPIO1_29) process @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		@Enable clock for GPIO1 module
		MOV R3,#0x02				@Value to enable clock for a GPIO1 module
		LDR R1,=0x44E000AC			@Address of CM_PER_GPIO1_CLKCTRL register
		STR R3,[R1]					@Write 0x02 to register
		
		@Detect falling edge on GPIO1_29 and enable to assert POINTRPEND1
		LDR R1,=0x4804C000			@Base Address of GPIO1
		MOV R2,#0x20000000			@Load value for Bit 29
		LDR R3,[R1,#0x14C]			@Read GPIO1_FALLINGDETECT register
		ORR R3,R3,R2				@Modify (set bit 29)
		STR R3,[R1,#0x14C]			@Write back
		STR R2,[R1,#0x34]			@Enable GPIO1_29 request on POINTRPEND1
		
		@Initialize INTC
		LDR R1,=0x48200000			@Base Address of INTC register
		MOV R2,#0x2					@Value to reset INTC
		STR R2,[R1,#0x10]			@Write to INTC Config register
		
		MOV R2,#0x04				@Value to unmask INTC INT 98, GPIOINT1A
		STR R2,[R1,#0xE8]			@Write to INTC_MIR_CLEAR3 register
		
		@Clear off the button request if the button was pressed before the program was running, or from a previous run
		LDR R1,=0x4804C000			@Base address of GPIO1
		MOV R2,#0x20000000			@Value turns off GPIO1_29 Interrupt request and INTC interrupt request
		STR R2,[R1,#0x2C]			@Write to GPIO1_IRQSTATUS_0
		
		@Turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
		LDR R3,=0x48200048			@Address of INTC_CONTROL register
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R3]					@Write to INTC_CONTROL register
		
		@Enable IRQ processor in CPSR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c,R3				@Write back to CPSR
		
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		
		@Dead loop to wait for intrrupt
LOOP:	NOP
		B LOOP
		
INT_DIRECTOR:
		LDR R3,=0X4804C02C			@Load GPIO1_IRQSTATUS_0 register address
		LDR R1,[R3]					@Read STATUS register
		TST R1,#0x20000000			@Cheack if bit 29 =1
		BNE BUTTON_SVC				@If bit 29 =1, then button is pushed, else
		
		BL PASS_ON						@Jump back to dead loop
		
PASS_ON: 

		@Enable IRQ processor in CPSR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c,R3				@Write back to CPSR
		
		LDR R3,=0x48200048			@Go back. INTC_CONTROL register address
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R3]					@Write to INTC_CONTROL register
		
		BL LOOP
		
BUTTON_SVC:
		LDR R8,=0xFFFF				@Counter for Delay2 branch loop to fix the debounced button debounce
	Delay2: @this delay loop fixes the problem when the button is acting as if it was being pushed twice
		SUBS R8,R8,#0x01
		BNE Delay2
		
		LDR R3,=0X4804C02C			@Load GPIO1_IRQSTATUS_0 register address
		MOV R1,#0x20000000			@Value turns off GPIO1_29 Interrupt request and INTC interrupt request
		STR R1,[R3]					@Write to GPIO1_IRQSTATUS_0
		
		@Turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
		LDR R3,=0x48200048			@Address of INTC_CONTROL register
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R3]					@Write to INTC_CONTROL register
		
		@Enable IRQ processor in CPSR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c,R3				@Write back to CPSR
		
		LDR R6,=count				@Load the address of the counter value from literal pool
		
		MOV R4,#200					@Counter for the stepping loop (200 steps)
		
		BL STEP1
			
STEP1:@This branch is a loop for the steps which the motor will take
		BL POLL1					@POLL BB bit
		
		@first step (PMW4:H, PWM3:L, PWM5:H and PWM6:L)
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x17				@Bytes to access LED4_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x13				@Bytes to access LED3_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1B				@Bytes to access LED5_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1F				@Bytes to access LED6_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		LDR R7,[R6]					@Delay loop counter
		BL SDelay					@Jump to step delay loop
		
		SUBS R4,R4,#1				@Decrement Step counter
		BEQ	 PASS_ON				@If counter zero then STOP	

STEP2:@Branch to step the next step
		BL POLL1					@POLL BB bit
		
		@second step (PMW4:H, PWM3:L, PWM5:L and PWM6:H)
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x17				@Bytes to access LED4_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x13				@Bytes to access LED3_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1B				@Bytes to access LED5_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA		
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1F				@Bytes to access LED6_ON_H register 
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		LDR R7,[R6]					@Delay loop counter
		BL SDelay					@Jump to step delay loop

		SUBS R4,R4,#1				@Decrement Step counter
		BEQ	 PASS_ON				@If counter zero then STOP

STEP3:@Branch to step the next step		
		BL POLL1					@POLL BB bit
		
		@Third step (PMW4:L, PWM3:H, PWM5:L and PWM6:H)
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x17				@Bytes to access LED4_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x13				@Bytes to access LED3_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1B				@Bytes to access LED5_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1F				@Bytes to access LED6_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		LDR R7,[R6]					@Delay loop counter
		BL SDelay					@Jump to step delay loop
		
		SUBS R4,R4,#1				@Decrement Step counter
		BEQ	 PASS_ON				@If counter zero then STOP	

STEP4:@Branch to step the next step
		BL POLL1					@POLL BB bit
		
		@Fourth step (PMW4:L, PWM3:H, PWM5:H and PWM6:L)
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x17				@Bytes to access LED4_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x13				@Bytes to access LED3_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1B				@Bytes to access LED5_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x10				@set to high
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		MOV R5,#5000				@Delay loop counter
		BL CDelay					@Jump to commands delay loop
		
		BL POLL1					@POLL BB bit
		
		MOV R1,#2					@Sending 2 bytes
		STR R1,[R0,#0x98]			@Write to I2C_CNT register
		MOV R1,#0x8603				@Value to write to I2C_CON to obtain the right settings
		STR R1,[R0,#0xA4]			@Write to I2C_CON register
		MOV R1,#0x1F				@Bytes to access LED6_ON_H register
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		MOV R1,#0x00				@set to Low
		STR R1,[R0,#0x9C]			@Write to I2C_DATA
		
		LDR R7,[R6]				@Delay loop counter
		BL SDelay					@Jump to step delay loop
		
		SUBS R4,R4,#1				@Decrement STEP loop counter
		BNE STEP1					@If counter not zero then go back to branch STEP
		BEQ PASS_ON					@Else, go to STOP
		
		
POLL1:@Branch to Poll the bus busy bit
		LDR R1,[R0,#0x24]			@Read value in I2C_IRQSTATUS_RAW
		TST R1,#0x1000				@Check is Bus Busy bit is set to 1 (busy)
		BNE POLL1					@If bit is equal to 1 then keep polling
		MOV PC,LR					@Else, return


CDelay:@Delay loop to be used between each command sent to PCA9685
		SUBS R5,R5,#1				@Decrement counter
		BNE CDelay					@If counter value is not zero then keep decrementing
		MOV PC,LR					@Else, return
		
SDelay:@Delay loop to be used between each step
		SUBS R7,R7,#1				@Decrement counter
		BNE SDelay					@If counter value is not zero then keep decrementing
		MOV PC,LR					@Else, return
		

		NOP

.data
count: .WORD 0x00061A80