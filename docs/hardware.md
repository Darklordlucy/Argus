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

6. Configuration Mode

Once the five-second button press is detected, ARGUS enters its configuration mode.

The configuration mode provides a local web-based interface for setting up the system.

The purpose is to configure the vehicle and emergency information without modifying the main application.

The configuration system is part of the ARGUS application itself; it is not a separate hardware controller.

7. ARGUS Configuration Network

The configured hotspot parameters are:

Network name: ARGUS-Config
Password: argus1234
Interface: wlan0
Configuration server port: 8080

These are the values defined by the application.

Once configuration mode is active, the user connects a phone, laptop, or other Wi-Fi device to the ARGUS configuration network.

The configuration page is then used to configure the device.

8. Configuration Page

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

9. Completing Configuration

After entering the required information, the configuration is saved.

ARGUS then exits the configuration process and returns to normal startup.

The application waits briefly and reloads the configuration so that the newly saved information is available to the running system.

This means you do not need to manually restart the application simply because you changed the configuration.