import processing.serial.*;
import wekaizing.*;

// serial port communication
Serial myPort;
int sensorCount = 3;

// synchronizing with serial data stream
boolean sync = false;
int previousValue = 0;

// data classification
ArrayList currentValues;
boolean trained = false;
WekaData data;
WekaClassifier classifier;

void setup()
{
  // serial port setup
  String portName = Serial.list()[0];
  println("serial port: " + portName);
  myPort = new Serial(this, portName, 9600);
  
  data = new WekaData();
  data.AddAttribute("1");
  data.AddAttribute("2");
  data.AddAttribute("3");
  Object[] classes = {0,1};
  data.AddAttribute("class", classes);
  classifier = new WekaClassifier(WekaClassifier.KSTAR);
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
    myPort.read();
    myPort.read();
    
    // store the readings globally
    currentValues = readings;
    
    // display the classification of the current position
    if (trained) {
      ArrayList values = (ArrayList)currentValues.clone();
      values.add(0);
      Object[] pData = values.toArray();
      int pred = classifier.Classify(pData);
      
      println("prediction = " + pred);
    } else {
      println("");
    }
  }
}

void learnValues(int pClass) {
  ArrayList values = (ArrayList)currentValues.clone();
  values.add(pClass);
  Object[] pData = values.toArray();
  
  data.InsertData(pData);
  classifier.Build(data);
  trained = true;
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    learnValues(1);
    println("learning confident");
  } else if (key == 'n' || key == 'N') {
    learnValues(0);
    println("learning not confident");
  }
}

