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


