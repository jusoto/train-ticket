#!/bin/bash

#Global variables
times=$1
test_cases=$2
host=$3
filename=$4
log_filename=$5
remote_username=$6
remote_host=$7

if [[ (-z "$times") || (-z "$test_cases") || (-z "$host") || (-z "$filename") || (-z "$log_filename") ]]; then
    echo "
  ERROR:

  One or more parameters are missing.

  Usage: run_test_remote_monitoring.sh 100 1,2,3,4,5 localhost output_filename log_filename remote_username remote_host

  Aborting...
    "
    exit 1
fi

# Define the log file
LOG_FILE=~/$log_filename

# Define the absolute path to test_cases.sh
TEST_CASES_SCRIPT="/lclhome/jsoto128/Documents/Projects/FIU/github.com/train-ticket/caseStudy/test_cases.sh"

# Function to collect system metrics and append them to the log file
collect_metrics() {
    # Get timestamp
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    # Get CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Get memory usage
    MEM_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')

    # Get I/O usage
    IO_USAGE=$(iostat -d | grep vda | awk '{print $2,$3}')

    # Load Average
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }')

    # Process Count
    process_count=$(ps -ef | wc -l)

    # Network Usage
    network_usage=$(ifconfig | grep -A 1 "inet " | awk '/RX packets/ { printf "Rx:%s Tx:%s", $2, $6 }')

    # Disk I/O Latency
    disk_io_latency=$(iostat -d | grep vda | awk '{print "Read:"$2" Write:"$3}')

    # Network Latency
    network_latency=$(ping -c 5 google.com | grep rtt | awk '{print "Min:"$4 " Avg:"$5 " Max:"$6}')

    # Docker Stats
    docker_stats=$(docker stats --no-stream)

    # Write to log file
    echo "$TIMESTAMP CPU Usage: $CPU_USAGE% | Memory Usage: $MEM_USAGE% | I/O Usage (read write): $IO_USAGE | Docker Stats: $docker_stats | Load Average: $load_avg | Process Count: $process_count | Network Usage: $network_usage | Disk I/O Latency: $disk_io_latency | Network Latency: $network_latency" >>"$LOG_FILE"
}

# Function to run test_cases.sh on the remote client
run_remote_tests() {

    # Print in console the process id
    echo "PROCESS ID: $MONITOR_PID"

    # SSH command to execute test_cases.sh on the remote client
    ssh $remote_username@$remote_host $TEST_CASES_SCRIPT $times "$test_cases" $host $filename
}

# Function to stop the script gracefully
stop_script() {
    # Stop the background process
    kill -SIGINT $MONITOR_PID
    echo "Monitoring stopped. Exiting..."
    exit 0
}

# Trap the SIGINT signal (Ctrl+C) to stop the script gracefully
trap stop_script SIGINT

# Main loop to continuously collect metrics and log them
while true; do
    collect_metrics
    sleep 1 # Adjust this if you want to change the frequency
done &
MONITOR_PID=$!

# Run tests on the remote client
run_remote_tests

# Once the remote tests are completed, stop monitoring metrics
kill $MONITOR_PID
echo "Remote tests completed. Stopping monitoring... PID: $MONITOR_PID - stopped at $(date)"
