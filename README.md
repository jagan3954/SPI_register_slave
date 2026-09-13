# Architecture and FSM Diagram

  stateDiagram-v2
      [*] --> Idle
      Idle --> Busy: start accepted
      Busy --> Finish: word complete
      Finish --> Idle: done pulse
      Busy --> Idle: reset / CS abort

  The SPI Master contains a configurable clock-divider generator, transaction control FSM, transmit shift register, receive shift register, bit counter, and chip-select timing control. The divider derives SCLK from the system clock
  according to the programmed rate. The datapath shifts MOSI data out and samples MISO data in on the mode-appropriate clock edges, supporting SPI modes 0 through 3 and 8- or 16-bit transfers.

  The SPI Slave uses synchronized SCLK, CS, and MOSI inputs, edge detection, a transaction shift register, and a register-map decode block. Completed 16-bit command words are decoded as R/W, address, and data fields; read data is
  returned full-duplex during the corresponding transaction.

  # Timing, Corner Cases, & Limitations

  The slave crosses asynchronous SPI signals into the system-clock domain using double-flop synchronizers. SCLK, CS, and MOSI are each sampled through two sequential synchronization stages before edge detection and transaction
  processing. This substantially reduces metastability risk while keeping the slave logic synchronous to the system clock.

  Because SCLK is detected in the system-clock domain, the system clock must be greater than 2.5× the maximum SCLK frequency. This margin provides sufficient sampling opportunities for synchronized SCLK transitions and reliable edge
  detection. Operation outside this ratio can cause missed edges or unreliable serial data capture.

  Handled corner cases include:

  - Start requests received while the master is busy are rejected; the active transaction remains undisturbed.
  - Reset asserted during an active transfer returns the master and slave transaction logic to a known idle state.
  - CS deasserted before completion aborts the in-progress slave transaction; partial words do not update writable registers.
  - Invalid register addresses are ignored for writes and return a defined benign value for reads.
  - Read-only registers, including Device ID and Status, are protected from write attempts.
  - Chip-select framing prevents data from one transaction carrying into the next.

  # Simulation Verification Log

  xsim> run all
  ============================================================
   SPI Master / SPI Slave Self-Checking Verification
  ============================================================

  [TEST] Reset and idle-state initialization
    INFO: Master reset complete
    INFO: Slave registers initialized
    PASS: Idle state and default register values verified

  [TEST] SPI Mode 0 - Control register write/read
    WRITE: addr=0x01 data=0xA5
    READ : addr=0x01 expected=0xA5 received=0xA5
    PASS: Mode 0 write/read match

  [TEST] SPI Mode 1 - Data register write/read
    WRITE: addr=0x03 data=0x3C
    READ : addr=0x03 expected=0x3C received=0x3C
    PASS: Mode 1 write/read match

  [TEST] SPI Mode 2 - Control register write/read
    WRITE: addr=0x01 data=0x5A
    READ : addr=0x01 expected=0x5A received=0x5A
    PASS: Mode 2 write/read match

  [TEST] SPI Mode 3 - Data register write/read
    WRITE: addr=0x03 data=0xC3
    READ : addr=0x03 expected=0xC3 received=0xC3
    PASS: Mode 3 write/read match

  [TEST] Device ID validation
    READ : addr=0x00 expected=0xA5 received=0xA5
    PASS: Device ID matches expected value

  [TEST] Read-only register protection
    WRITE: addr=0x00 data=0x00
    READ : addr=0x00 expected=0xA5 received=0xA5
    PASS: Device ID write ignored

  [TEST] Reset during transaction
    INFO: Reset asserted during active SPI transfer
    PASS: Transaction aborted and interfaces returned to idle

  [TEST] Early CS deassertion
    INFO: CS released before 16-bit command completion
    PASS: Partial transaction ignored; register contents unchanged

  [TEST] Invalid address handling
    READ : addr=0x7F expected=0x00 received=0x00
    PASS: Invalid address returned defined default value

  ============================================================
   TEST SUMMARY
  ============================================================
   Tests Run    : 10
   Tests Passed : 10
   Tests Failed : 0
   Result       : PASS
  ============================================================

  # Synthesis Report

  ------------------------------------------------------------
  Post-Synthesis Utilization Report
  Target Device: xc7z020clg400-1
  Family       : Zynq-7000
  ------------------------------------------------------------

  Site Type                 Used     Available     Utilization
  ------------------------------------------------------------
  Slice LUTs                  184        53,200         0.35%
  Slice Registers             142       106,400         0.13%
  BUFG                          1            32         3.13%
  Bonded IOB                    8           200         4.00%
  Block RAM Tile                0           140         0.00%
  DSP Slices                    0           220         0.00%
  ------------------------------------------------------------

  Design Summary:
    - Configurable SPI Master and register-mapped SPI Slave
    - No block RAM or DSP resources required
    - LUT and register utilization remain well under 1%
    - One global buffer used for the system clock
  ------------------------------------------------------------
