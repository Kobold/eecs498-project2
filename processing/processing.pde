import java.util.Date;
import processing.serial.*;

// serial port communication
Serial myPort;
int sensorCount = 1;

// synchronizing with serial data stream
boolean sync = false;
int previousValue = 0;

long lastSampleTime;
int fftBufferSize = 16;
LinkedList fftBuffer = new LinkedList();

void setup()
{
  size(500, 200);
  
  // serial port setup
  String portName = Serial.list()[0];
  println("serial port: " + portName);
  myPort = new Serial(this, portName, 9600);
  
  lastSampleTime = new Date().getTime();
}

void draw()
{
  if (!sync) {
    int temp = myPort.read();
    sync = (temp == 255) && (previousValue == 255);
    previousValue = temp;
  }
  
  if (sync && (myPort.available() >= 2 + 2 * sensorCount)) {
    // parse the serial values
    ArrayList readings = new ArrayList();
    for (int i = 0; i < sensorCount; i++) {
      int low = myPort.read();
      int high= myPort.read();
      int reading = (high << 8) + low;
      readings.add(new Integer(reading));
      
      long newSampleTime = new Date().getTime();
      println("T = " + (newSampleTime - lastSampleTime));
      lastSampleTime = newSampleTime;
    } 
    myPort.read();
    myPort.read();
    
    // add the reading to the fft buffer
    fftBuffer.addLast(readings.get(0));
    if (fftBuffer.size() > fftBufferSize) {
      fftBuffer.removeFirst();
    }
    
    // perform the FFT once the buffer is filled
    if (fftBuffer.size() == fftBufferSize) {
      // copy the buffer into a complex array
      Complex[] signal = new Complex[fftBufferSize];
      for (int i = 0; i < fftBufferSize; i++) {
        signal[i] = new Complex(((Integer)fftBuffer.get(i)).intValue(), 0);
      }
      
      // perform the FFT
      Complex[] fft = FFT.fft(signal);
      
      int bins = fftBufferSize / 2 + 1;
      background(0);
      fill(255);
      rectMode(CORNERS);
      print("[");
      for (int i = 0; i < bins; i++) {
        double a = Math.log(fft[i].abs());
        rect(10 * i, height, 10 * (i + 1), (float)(height - height * (a / 8.5)));
      }
      println("]");
    }
  }
}
