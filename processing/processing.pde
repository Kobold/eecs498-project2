import java.util.Date;
import processing.serial.*;

// serial port communication
int sensorCount = 1;
Serial inPort;
Serial outPort;

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
  
  // input serial port setup
  String portName = Serial.list()[2];
  println("in serial port: " + portName);
  inPort = new Serial(this, portName, 9600);
  
  // output serial port setup
  portName = Serial.list()[0];
  println("out serial port: " + portName);
  outPort = new Serial(this, portName, 9600);
  
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
    int temp = inPort.read();
    sync = (temp == 255) && (previousValue == 255);
    previousValue = temp;
    println("synching port");
  }
  
  if (sync && (inPort.available() >= 2 + 2 * sensorCount)) {
    // parse the serial values
    ArrayList readings = new ArrayList();
    for (int i = 0; i < sensorCount; i++) {
      int low = inPort.read();
      int high= inPort.read();
      int reading = (high << 8) + low;
      readings.add(new Integer(reading));
    } 
    inPort.read();
    inPort.read();
    
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
      outPort.write(255);
      
      background(0);
      fill(200, 0, 0);
      rectMode(CORNERS);
      for (int i = 0; i < bins; i++) {
        double val = fftScaled[i];
        byte quantized = (byte)Math.round(val * 4);
        double rescaled = (double)quantized / 4.0;
        rect(50 * i, height, 50 * (i + 1), (float)(height - height * rescaled));
        
        outPort.write(quantized);
      }
    }
  }
}
