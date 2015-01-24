import time
import RPi.GPIO as GPIO


# Use BCM GPIO references
# instead of physical pin numbers
GPIO.setmode(GPIO.BOARD)

# GPIO pins (from http://www.scraptopower.co.uk/Raspberry-Pi/how-to-connect-stepper-motors-a-raspberry-pi)
# [11,12,13,15] or [GPIO17, GPIO18, GPIO27,GPIO22]
step_pins = [11,12,13,15]

# Set pins as output
for pin in step_pins:
    print "Setup pin {0}".format(pin)
    GPIO.setup(pin,GPIO.OUT)
    GPIO.output(pin,False)

step_counter = 0
wait_time = 0.005

step_count1 = 4
seq1 = []
seq1 = range(0,step_count1)

seq1[0] = [1,0,0,0]
seq1[1] = [0,1,0,0]
seq1[2] = [0,0,1,0]
seq1[3] = [0,0,0,1]

step_count2 = 8
seq2 = []
seq2 = range(0, step_count2)
seq2[0] = [1,0,0,0]
seq2[1] = [1,1,0,0]
seq2[2] = [0,1,0,0]
seq2[3] = [0,1,1,0]
seq2[4] = [0,0,1,0]
seq2[5] = [0,0,1,1]
seq2[6] = [0,0,0,1]
seq2[7] = [1,0,0,1]

seq = seq2
step_count = step_count2

while 1==1:
    for pin in range(0, 4):
        xpin = step_pins[pin]
        if seq[step_counter][pin] != 0:
            print " Step {0} Enable {1}".format(step_counter, xpin)
            GPIO.output(xpin, 1)
        else:
            GPIO.output(xpin, 0)

    step_counter += 1
    if step_counter == step_count:
        step_counter = 0
    time.sleep(wait_time)
