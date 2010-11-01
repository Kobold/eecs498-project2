import processing.serial.*;

// serial port communication
Serial myPort;
int sensorCount = 1;

// synchronizing with serial data stream
boolean sync = false;
int previousValue = 0;

void setup()
{
  // serial port setup
  String portName = Serial.list()[0];
  println("serial port: " + portName);
  myPort = new Serial(this, portName, 9600);
}

void draw()
{
  if (!sync) {
    int temp = myPort.read();
    sync = (temp == 255) && (previousValue == 255);
    previousValue = temp;
  }
  
  if (sync && (myPort.available() >= 8)) {
    // parse the serial values
    ArrayList readings = new ArrayList();
    for (int i = 0; i < sensorCount; i++) {
      int low = myPort.read();
      int high= myPort.read();
      int reading = (high << 8) + low;
      print(reading + " ");
      readings.add(reading);
    } 
    println("");
    myPort.read();
    myPort.read();
  }
}
