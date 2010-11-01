int pins[] = {0};

void setup() {
  Serial.begin(9600); 
}
 
void loop() {
  Serial.write((byte)255);
  Serial.write((byte)255);
  
  // sample and print the sensor values 
  int length = sizeof(pins) / sizeof(int); 
  for (int i = 0; i < length; i++) {
    int pin = pins[i];
    int analogValue = analogRead(pin);
    sendInt(analogValue);  
  }
  
  // wait 100ms to sample again
  delay(500);
}

void sendInt(int i){
  Serial.write(i & 0xFF);
  Serial.write((i >> 8) & 0xFF);
}
