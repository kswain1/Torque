# Torque
This is the ios app for Hx Innovations that connects imu and emg pairing together.

# Workspace setup 
- install pod files by using pod install
- setup environment files to become a wear notch user

- Set up your ~/.netrc file. If you don’t have it, create it now.

```console 
vi ~/.netrc file
```

```console
 machine wearnotch.com
 login {yourLoginCredentials}
 password {yourPassword}
 ```

## Install Cocoa Pods on Macbook 
sudo gem install cocoapods

## Installation Podfile
In terminal run pod install to connect all of the podfiles.
$ pod install 

## Technical specification For IMU's
What kind of sensors do you use?

Notches use onboad MEMES sensors, including accelerometer, gyroscope and magnetometer

- Gyroscope range

±250, ±500, ±1000, ±2000, ±4000 dps

- Accelerometer range

±2, ±4, ±8, ±16, ±32 g

- Magnetometer range

±4/ ±8/ ±12/ ±16 gauss

- Sampling frequency

5Hz, 10Hz, 20Hz, 40Hz, 50Hz, 100Hz, 125Hz, 200Hz, 333Hz, 500Hz

- EMG range: 
60HZ 

