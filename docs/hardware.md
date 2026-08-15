ARGUS Hardware Setup & Configuration Walkthrough

1. Powering On ARGUS

When power is applie ARGUS application Starts.

The application first checks whether the expected hardware device interfaces are present.

It checks for:

GPS serial device
SIM serial device
I²C interface

These checks are diagnostic warnings; they allow the application to identify missing hardware before normal operation begins.

2. Hardware Initialization

After the initial checks, ARGUS initializes its hardware.

The configuration button is initialized as an input with a pull-up arrangement.

The SIM800L modem is then initialized.

The buzzer is also initialized and produces the startup notification pattern.

This gives a simple physical indication that the ARGUS application has reached its startup stage

3. GPS Starts Early

The GPS reader is started before the configuration period.

This is intentional.

The application allows the GPS to begin acquiring satellites while the user is deciding whether configuration mode is required.

This means the configuration period is not completely wasted from the GPS acquisition perspective.

4. Configuration Mode Entry

This is the most important part of the setup procedure.

After startup, ARGUS provides a 30-second configuration-entry window.

The application indicates:

Hold the button for 5 seconds within 30 seconds to enter config mode.

To enter configuration mode:
Power on ARGUS.
Wait for the startup sequence.
Within the first 30 seconds, press and hold the configuration button.
Continue holding it for approximately 5 seconds.
ARGUS detects the long press.
Configuration mode is activated.

The software specifically measures the duration of the button press rather than triggering configuration mode from a simple momentary press.

5. Configuration Mode

Once the five-second button press is detected, ARGUS enters its configuration mode.

The configuration mode provides a local web-based interface for setting up the system.

The purpose is to configure the vehicle and emergency information without modifying the main application.

The configuration system is part of the ARGUS application itself; it is not a separate hardware controller.

6. ARGUS Configuration Network

The configured hotspot parameters are:

Network name: ARGUS-Config
Password: argus1234
Interface: wlan0
Configuration server port: 8080

These are the values defined by the application.

Once configuration mode is active, the user connects a phone, laptop, or other Wi-Fi device to the ARGUS configuration network.

The configuration page is then used to configure the device.

7. Configuration Page

The configuration page is intended to collect the information ARGUS needs for vehicle identification and emergency notification.

The setup information includes:

User information
Name
Age
Blood group
Vehicle information
Vehicle registration number
Medical information
Medical conditions
Medications
Emergency contacts
Primary emergency contact
Additional emergency contacts

This information is stored as ARGUS configuration data and is available to the application during normal operation.

8. Completing Configuration

After entering the required information, the configuration is saved.

ARGUS then exits the configuration process and returns to normal startup.

The application waits briefly and reloads the configuration so that the newly saved information is available to the running system.

This means you do not need to manually restart the application simply because you changed the configuration.

9. If Configuration Mode Is Not Required

If the button is not held for five seconds during the initial 30-second window, ARGUS automatically continues with normal startup.

So there are two startup paths:

                    POWER ON
                       │
                       ▼
                 Hardware Init
                       │
                       ▼
                 GPS Starts
                       │
                       ▼
             30-second button window
                       │
              ┌────────┴────────┐
              │                 │
       Hold 5 seconds       No long press
              │                 │
              ▼                 ▼
       CONFIGURATION        NORMAL STARTUP

This allows the same device to be configured during installation while still starting normally during everyday use.

10. GPS Acquisition After Setup

Once configuration handling is complete, ARGUS proceeds to GPS acquisition.

The configured maximum GPS startup wait is 120 seconds.

The 30-second configuration period already counts toward this startup GPS window.

Therefore, ARGUS does not unnecessarily restart the GPS waiting period after configuration.

The system can wait for the remaining available GPS acquisition time.

11. Normal Monitoring Begins

Once startup is complete, ARGUS enters its normal monitoring state.

At this point the system continuously combines:

GPS + MPU6050 + application logic + buzzer + communication

The MPU6050 monitoring loop operates at:

50 Hz

according to the application configuration.

This is the normal operational state of the device.

12. Normal Road Monitoring

During normal operation, the MPU6050 continuously observes vehicle movement.

ARGUS looks for different motion patterns.

The configured thresholds include:

Crash thresholds
Turn thresholds
Bump threshold
Pothole threshold

The current application defines:

Crash: X/Y/Z acceleration changes
Turn: horizontal motion changes
Bump: vertical acceleration disturbance
Pothole: larger vertical acceleration disturbance
13. Pothole Detection Flow

When a pothole-like event is detected, ARGUS:

Reads the current GPS position.
Determines whether it is a current GPS position or last-known position.
Records the pothole event.
Activates the pothole buzzer pattern.
Sends the event toward the backend telemetry process.

The application explicitly logs the event together with the GPS state.

The important point for your testing is that the pothole event is a road event, not a crash.

14. Bump Detection Flow

A bump is treated separately from a pothole.

When the bump threshold is exceeded:

ARGUS identifies the event.
The GPS position can be obtained.
The bump event is logged.
The bump buzzer pattern is activated.

The current application does not treat an ordinary bump as a confirmed emergency.

15. Turn Detection Flow

The system also monitors horizontal motion changes for turning behavior.

When the configured turn thresholds are reached:

ARGUS identifies the turn.
The event is logged.
The turn buzzer pattern is activated.

A turn is therefore handled as a normal driving event rather than an emergency event.

16. Crash Detection

Crash detection has a different workflow.

ARGUS continuously compares acceleration measurements against its crash thresholds.

with the Y axis treated as the vertical/gravity axis.

A detected crash pattern does not immediately send an emergency message.

Instead, ARGUS starts the confirmation process.

17. 15-Second Crash Confirmation

The crash confirmation period is:

15 seconds

This is specifically configured as:

CANCEL_WINDOW_S = 15.

The purpose is to prevent a single unexpected acceleration event from immediately generating an emergency response.

The sequence is:

Possible crash
      │
      ▼
15-second confirmation window
      │
      ├── Cancelled → return to monitoring
      │
      └── Not cancelled
                │
                ▼
          Confirmed crash
18. Confirmed Crash Response

Once the crash is confirmed, ARGUS switches the event into its emergency workflow.

The important priority is:

CRASH
  ↓
EMERGENCY SMS
  ↓
BACKEND NOTIFICATION

The application was specifically structured so that the emergency SMS is handled before the backend crash POST.

This prevents a slow network request from delaying the primary emergency-contact notification.

19. Normal Operation vs Emergency Operation

The system effectively has two operational priorities.

Normal operation
GPS
 ↓
MPU6050
 ↓
Road-event detection
 ↓
Buzzer / telemetry
 ↓
Continue monitoring
Emergency operation
Crash detected
 ↓
15-second confirmation
 ↓
Crash confirmed
 ↓
Emergency SMS
 ↓
Backend notification

The crash path takes priority over routine road-event processing.

20. Returning to Normal Operation

After configuration mode, ARGUS returns to normal monitoring.

Similarly, ordinary events such as potholes, bumps and turns do not terminate the application.

The intended behavior is continuous operation:

Monitor
  ↓
Detect event
  ↓
Handle event
  ↓
Return to monitoring
  ↓
Detect next event
  ↓
...

This makes ARGUS suitable for continuous vehicle operation rather than one-shot event detection.


Simplified Demonstration Flow

                    POWER ON
                       │
                       ▼
                ARGUS INITIALIZES
                       │
                       ▼
                 GPS STARTS
                       │
                       ▼
             30-SECOND SETUP WINDOW
                       │
            ┌──────────┴──────────┐
            │                     │
       HOLD 5 SECONDS         NO BUTTON
            │                     │
            ▼                     │
     CONFIGURATION MODE            │
            │                     │
     Configure user,               │
     vehicle & contacts            │
            │                     │
            └──────────┬──────────┘
                       ▼
                 GPS ACQUISITION
                       │
                       ▼
                NORMAL MONITORING
                       │
          ┌────────────┼─────────────┐
          │            │             │
       Pothole       Bump          Turn
          │            │             │
       Buzzer       Buzzer        Buzzer
          │
       Telemetry
          │
          ▼
      BACKEND
          
          Meanwhile...
          
       Crash detected
             │
             ▼
      15-sec confirmation
             │
       ┌─────┴─────┐
       │           │
    Cancel       Confirm
       │           │
       ▼           ▼
    Normal       SMS
   monitoring     │
                  ▼
               Backend
                  │
                  ▼
           Normal monitoring