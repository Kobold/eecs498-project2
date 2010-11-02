import java.util.Date;
import processing.serial.*;

// serial port communication
Serial myPort;
int sensorCount = 1;

// synchronizing with serial data stream
boolean sync = false;
int previousValue = 0;

// fft related stuff
int fftBufferSize = 16;
LinkedList fftBuffer = new LinkedList();
double[] fftMax, fftMin;

void setup()
{
  size(500, 200);
  
  // serial port setup
  String portName = Serial.list()[0];
  println("serial port: " + portName);
  myPort = new Serial(this, portName, 9600);
  
  // initialize the minimum and maximum value buffers
  fftMin = new double[fftBufferSize];
  fftMax = new double[fftBufferSize];
  for (int i = 0; i < fftBufferSize; i++) {
    fftMin[i] = 100000.0;
    fftMax[i] = 0.0;
  }
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
      
      // scale it for display
      int bins = fftBufferSize / 2 + 1;
      double[] fftScaled = new double[bins];
      for (int i = 0; i < bins; i++) {
        double a = fft[i].abs();
        fftMin[i] = Math.min(fftMin[i], a);
        fftMax[i] = Math.max(fftMax[i], a);
        
        double range = fftMax[i] - fftMin[i];
        fftScaled[i] = (a - fftMin[i]) / range;
      }
      
      // display it
      background(0);
      fill(200, 0, 0);
      rectMode(CORNERS);
      for (int i = 0; i < bins; i++) {
        double val = fftScaled[i];
        long quantized = Math.round(val * 4);
        double rescaled = (double)quantized / 4.0;
        rect(50 * i, height, 50 * (i + 1), (float)(height - height * rescaled));
      }
    }
  }
}
