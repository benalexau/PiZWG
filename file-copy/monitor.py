#!/bin/python3

import re
import time
from telnetlib import Telnet

# Hostname where the ser2net control port is available
HOST="localhost"

# Port where the ser2net control port is available
PORT=4444

# Timeout for telnet connection and read operations
TIMEOUT_SECS=5

# Sleep period between successive "showport" commands
COMMAND_SLEEP=1

# Line number of ser2net "showport" response with connection info
SHOWPORT_RESPONSE_CONNECTION_INFO_LINE=5

def find_connected_to(tn):
    tn.write(b"showport\n")
    bytes = tn.read_until(b"-> ", TIMEOUT_SECS)
    string = bytes.decode("utf-8")
    if not "connected to" in string:
        return "unconnected"
    lines = re.split("\n", string)
    return lines[SHOWPORT_RESPONSE_CONNECTION_INFO_LINE].strip()

# Monitor runs until an exception occurs, or a remote device becomes connected
# to the serial port and then that remote connection ceases for any reason.
def monitor():
    with Telnet(HOST, PORT, TIMEOUT_SECS) as tn:
        # Wait for connection prompt (timeout will cause fatal exception)
        tn.read_until(b"-> ", TIMEOUT_SECS)

        # Wait for initial connection from initial_connection
        initial_connection = find_connected_to(tn)
        while initial_connection == "unconnected":
            time.sleep(COMMAND_SLEEP)
            initial_connection = find_connected_to(tn)
        print("Initial connection: ", initial_connection)

        # Connection received; wait for it to disconnect
        subsequent_connection = find_connected_to(tn)
        while initial_connection == subsequent_connection:
            time.sleep(COMMAND_SLEEP)
            subsequent_connection = find_connected_to(tn)
        print("Subsequent connection: ", subsequent_connection)
 
        tn.write(b"exit\n")
        tn.close()

# Invoke monitor function
while True:
    try:
        monitor()
        break
    except Exception as e:
        print("Error: " + str(e))
        break
