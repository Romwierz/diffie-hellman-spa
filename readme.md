## Board Overview

The development board is based on the **AT89S52 MCU** and it also includes:

- XC9536XL CPLD to generate control/debug signals and communicate with PC
- JTAG interface connected to the CPLD
- 74HCT573 latch and 628128 SRAM for address/data handling

AT89S52 does not have native JTAG support, so the JTAG connector works with the CPLD, not the MCU directly.
That is why there are two programming methods available:

- **Monitor-based via CPLD** requires Keil µVision C51 evaluation kit to be used which is only available on Windows OS.
It uses monitor firmware (that is written on MCU's Flash) that makes debugging a lot easier.
- **Direct ISP via SPI** programs MCU directly, but overwrites monitor firmware.

## Workspace Setup

Linux is used as primary development environment and Keil software runs on Windows Virtual Machine.
It is possible thanks to Shared Folders functionality in Oracle Virtual Box.

### VM Setup

After setting up the Windows Virtual Machine and installing [Keil Software](https://www.keil.com/demo/eval/c51.htm) on it, there two main things to do.
The first one is adding the shared folder mentioned above, and the second one is enabling USB Passthrough (and adding a filter to automatically pass the selected device).
Both must be done using Guest Additions or Extension Pack.
