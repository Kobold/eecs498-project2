// the number of frequency bins the arduino is transmitting
int frequencyCount = 9;

// shift register pins
int data = 2;
int clock = 3;
int latch = 4;

// serial communication
boolean synced = false;

/*
* setup() – this function runs once when you turn your Arduino on
* We set the three control pins to outputs
*/
void setup()
{
  Serial.begin(9600);
  
  pinMode(data, OUTPUT);
  pinMode(clock, OUTPUT);  
  pinMode(latch, OUTPUT);  
}

byte generateOutputBits(int input)
{
  byte out = 0;
  for (int i = 0; i < input; i++) {
    out = (out << 1) | 1;
  }
  return out;
}

void outputBits(byte output)
{
  byte mask = 0x8;
  for (int i = 0; i < 4; i++) {
    if (output & mask) {
      digitalWrite(data, HIGH);
    } else {
      digitalWrite(data, LOW);
    }
    
    digitalWrite(clock, HIGH);
    delayMicroseconds(10);
    digitalWrite(clock, LOW);
    
    mask = mask >> 1;
  }
}

void loop()
{
  // sync to the serial input stream
  if (!synced) {
    int input = Serial.read();
    synced = (input == 255);
  }

  // test if there's enough input to update the display
  if (synced && (Serial.available() > frequencyCount)) {
    // read in the amplitudes to display
    int amplitudes[frequencyCount];
    for (int i = 0; i < frequencyCount; i++) {
      amplitudes[i] = Serial.read();
    }
    int stopgap = Serial.read();
    synced = (stopgap == 255); // read off the sync 255
    
    // output the values to the shift register
    digitalWrite(latch, LOW);
    for (int i = frequencyCount - 1; i >= 0; i--) {
      byte output = generateOutputBits(amplitudes[i]);
      outputBits(output);
    }
    digitalWrite(latch, HIGH);
  }
  
  /*byte disp = (generateOutput(2) << 6) |
              (generateOutput(1) << 4) |
              (generateOutput(1) << 2) |
              generateOutput(0);
              
                    // 87 65 43 21
  updateLEDs(disp); // 11 00 00 00*/
}

/*
* updateLEDs() - sends the LED states set in ledStates to the 74HC595
* sequence
*/
void updateLEDs(int value){
  digitalWrite(latch, LOW);     //Pulls the chips latch low
  shiftOut(data, clock, MSBFIRST, value); //Shifts out the 8 bits to the shift register
  digitalWrite(latch, HIGH);   //Pulls the latch high displaying the data
}
/*
* updateLEDsLong() - sends the LED states set in ledStates to the 74HC595
* sequence. Same as updateLEDs except the shifting out is done in software
* so you can see what is happening.
*/
void updateLEDsLong(int value){
  digitalWrite(latch, LOW);    //Pulls the chips latch low
  for(int i = 0; i < 8; i++){  //Will repeat 8 times (once for each bit)
    int bit = value & B10000000; //We use a "bitmask" to select only the eighth
                               //bit in our number (the one we are addressing this time through
    value = value << 1;          //we move our number up one bit value so next time bit 7 will be
                               //bit 8 and we will do our math on it
    if(bit == 128){
      digitalWrite(data, HIGH);  //if bit 8 is set then set our data pin high
    } else {
      digitalWrite(data, LOW);
    }            //if bit 8 is unset then set the data pin low
    
    digitalWrite(clock, HIGH);                //the next three lines pulse the clock pin
    delay(1);
    digitalWrite(clock, LOW);
  }
  
  digitalWrite(latch, HIGH);  //pulls the latch high shifting our data into being displayed
}

