# BeagleBone Black ARM Assembly Language Projects
This repo contains Abdullah's BeagleBone Black ARM Assembly Language Projects.  


The first project is a UART Speech Synthesizer driver program, written in ARM Assembly Language.  The project contains two parts (tlkr.s & counter.s):

Part 1 (tlkr.s): This program invokes the Speech Synthesizer, when a button is pressed, which will let the Speech Synthesizer speak/say a phrase in Darth Vader voice.

Part 2 (counter.s):  This program invokes the Speech Synthesizer to let it announce the amount of time (in HEX) between the initial button press and the secondary button press. 


The second project is a I2C Stepper Motor driver program, written in ARM Assembly Language.  This project contains two parts (polling.s & stepper.s):

Part 1 (polling.s): This program simply polls the BeagleBone Black I2C bus (I2C1) to test and determine whether the I2C bus is behaving properly.

Part 2 (stepper.s): This program actuates the Stepper Motor, when a button is pressed, which will let the Stepper Motor perform a full revolution.
