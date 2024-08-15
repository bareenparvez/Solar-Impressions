#include <Wire.h>
#include "RTClib.h"

RTC_DS1307 rtc;

const int ldrPin = A0; // Pin connected to the LDR
int ldrValue;

void setup() {
  Serial.begin(115200);
  delay(10);

  // Initialize RTC
  if (!rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
  }
  if (!rtc.isrunning()) {
    Serial.println("RTC is NOT running!");
    // Following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

  pinMode(ldrPin, INPUT);
}

void loop() {
  // Read and map LDR value
  int rawLdrValue = analogRead(ldrPin);
  ldrValue = map(rawLdrValue, 200, 800, 0, 1023); // Adjust sensitivity range

  // Ensure values are within bounds
  ldrValue = constrain(ldrValue, 0, 1023);

  // Read RTC value
  DateTime now = rtc.now();
  String dateTime = String(now.year()) + "/" + String(now.month()) + "/" + String(now.day()) + " " +
                    String(now.hour()) + ":" + String(now.minute()) + ":" + String(now.second());

  // Send data to serial in JSON format
  String data = "{\"ldr\":" + String(ldrValue) + ", \"datetime\":\"" + dateTime + "\"}";
  Serial.println(data);

  delay(1000); // Adjust the delay as needed
}
