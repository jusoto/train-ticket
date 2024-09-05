#!/bin/bash

# This script is meant to execute n times a HTTP request

# If one command fails all the script fails
set -o errexit

# Global variables
times=$1
IFS=',' read -r -a test_cases <<<"$2"
hostname=$3
mkdir -p output
output_filename="/lclhome/jsoto128/$4"
echo "test_cases: $test_cases"

# Format to store HTTP response times
format="%{http_code},%{time_namelookup},%{time_connect},%{time_appconnect},%{time_pretransfer},%{time_redirect},%{time_starttransfer},%{time_total}"
file_header="http_code,time_namelookup,time_connect,time_appconnect,time_pretransfer,time_redirect,time_starttransfer,time_total"

#keep track of test cases that have finished
test1_finished=true
test2_finished=true
test3_finished=true
test4_finished=true
test5_finished=true

# Expected usage
# Example: test_cases.sh 100 1,2,3,4,5 localhost output_filename
main() {

  if [[ (-z "$times") || (-z "$test_cases") ]]; then
    echo "ERROR:
  One or more parameters are missing.

  Usage: test_cases.sh 100 1,2,3,4,5 localhost output_filename

Aborting.
    "
    exit 1
  fi

  before_all

  for element in "${test_cases[@]}"; do
    case $element in
    1)
      run_test_case_1
      test1_finished=true
      ;;
    2)
      run_test_case_2
      test2_finished=true
      ;;
    3)
      run_test_case_3
      test3_finished=true
      ;;
    4)
      run_test_case_4
      test4_finished=true
      ;;
    5)
      run_test_case_5
      test5_finished=true
      ;;
    esac
  done

  after_all
}

before_all() {
  # Services
  AUTH_SERVICE="auth"
  USER_SERVICE="userservice"
  GATEWAY_SERVICE="gatewayservice"
  TRAIN_SERVICE="trainservice"
  ORDER_SERVICE="orderservice"
  TICKET_OFFICE_SERVICE="ticketofficeservice"
  NOTIFICATION_SERVICE="notifyservice"

  # Gateway port
  GATEWAY_SERVICE_PORT=18888

  # Get token
  local url="$hostname:12349/api/v1/auth"
  local response=$(curl -X POST -s $url \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Authorization: Basic ZnJvbnQtZW5kOmZyb250LWVuZA==' \
    -H 'Accept: application/json' \
    -d 'grant_type=password&scope=webclient&username=passenger&password=password')
  token=$(echo $response | jq -r '.access_token')

  # Get a valid tripId by creating a trip through the API
  local url="$hostname:$GATEWAY_SERVICE_PORT/api/v1/$ORDER_SERVICE/order"
  local response=$(curl -X POST \
    -s $url \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer ' $token \
    -H 'Accept: application/json' \
    -d '{ "contactsName": "John Doe",
          "trainNumber: "G1235",
          "coachNumber: "1",
          "seatClass": "economy",
          "seatNumber": "1A",
          "from: "Miami, FL",
          "to": "Orlando, FL",
          "price": 100 }')
  tripId_tc4=${response:7:36}
}

after_all() {

  if ($test1_finished && $test2_finished && $test3_finished && $test4_finished && $test5_finished); then
    echo "All test cases were executed."
  else
    echo "Some test cases were not executed."
  fi

  if [ "$test1_finished" != true ]; then
    echo "Test case 1 was not executed."
  fi
  if [ "$test2_finished" != true ]; then
    echo "Test case 2 was not executed."
  fi
  if [ "$test3_finished" != true ]; then
    echo "Test case 3 was not executed."
  fi
  if [ "$test4_finished" != true ]; then
    echo "Test case 4 was not executed."
  fi
  if [ "$test5_finished" != true ]; then
    echo "Test case 5 was not executed."
  fi

}

run_test_case_1() {
  test1_finished=false
  echo "Test case 1 started."
  local output_filename_1=$output_filename"_1.csv"
  rm -f $output_filename_1
  echo "1. Create train type use case"
  echo $file_header |& tee -a $output_filename_1
  local url="$hostname:$GATEWAY_SERVICE_PORT/api/v1/$TRAIN_SERVICE/trains"
  for ((i = 1; i <= $times; i++)); do
    local response=$(curl -X POST \
      -w $format \
      --silent $url \
      --output /dev/null \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ' $token \
      -H 'Accept: application/json' \
      -d '{ "name": "bullet train", "economyClass": 1000, "comfortClass": 10, "averageSpeed": 300 }')
    echo $response |& tee -a $output_filename_1
    local status=${response:0:3}
    if [[ "$status" -ge "200" && "$status" -lt "300" ]]; then
      echo "PASS"
    else
      echo "FAILS"
    fi
  done
  echo "Test case 1 finished."
}

run_test_case_2() {
  test2_finished=false
  echo "Test case 2 started."
  local output_filename_2=$output_filename"_2.csv"
  rm -f $output_filename_2
  echo "2. Update ticket office use case"
  echo $file_header |& tee -a $output_filename_2
  #local url="$hostname/api/v1/cost"
  local url="$hostname:$GATEWAY_SERVICE_PORT/api/v1/$TICKET_OFFICE_SERVICE/updateOffice"
  for ((i = 1; i <= $times; i++)); do
    local response=$(curl -X POST \
      -w $format \
      -s $url \
      --output /dev/null \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ' $token \
      -H 'Accept: application/json' \
      -d ' {"province": "florida", "city":"miami", "region": "region1",
            "oldOfficeName":  "test1",
            "newOffice": {
              "name": "test1",
              "address": "address1",
              "workTime": "0800-18:00",
              "windowNum": 3
              }
            }')
    echo $response |& tee -a $output_filename_2
    local status=${response:0:3}
    if [[ "$status" -ge "200" && "$status" -lt "300" ]]; then
      echo "PASS"
    else
      echo "FAILS"
    fi
  done
  echo "Test case 2 finished."
}

run_test_case_3() {
  test3_finished=false
  echo "Test case 3 started."
  local output_filename_3=$output_filename"_3.csv"
  rm -f $output_filename_3
  echo "3. Receive notification use case"
  echo $file_header |& tee -a $output_filename_3
  local url="$hostname:$GATEWAY_SERVICE_PORT/api/v1/directions/$NOTIFICATION_SERVICE/notification/order_create_success"
  for ((i = 1; i <= $times; i++)); do
    local response=$(curl -X POST \
      -w $format \
      -s $url \
      --output /dev/null \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ' $token \
      -H 'Accept: application/json' \
      -d '{ "orderId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }')
    echo $response |& tee -a $output_filename_3
    local status=${response:0:3}
    if [[ "$status" -ge "200" && "$status" -lt "300" ]]; then
      echo "PASS"
    else
      echo "FAILS"
    fi
  done
  echo "Test case 3 finished."
}

run_test_case_4() {
  test4_finished=false
  echo "Test case 4 started."
  local output_filename_4=$output_filename"_4.csv"
  rm -f $output_filename_4
  echo "4. Update train trip use case"
  echo $file_header |& tee -a $output_filename_4
  local tripId=$tripId_tc4

  # Update tripId_tc4 information with new destination address
  if [[ -z "$tripId" ]]; then
    echo "tripId is empty. In order to execute this test case a tripId is required."
  else
    local url="$hostname:$GATEWAY_SERVICE_PORT/api/v1/$ORDER_SERVICE/order/admin"
    for ((i = 1; i <= $times; i++)); do
      local response=$(curl -X PUT \
        -w $format \
        -s $url \
        --output /dev/null \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer ' $token \
        -H 'Accept: application/json' \
        --data-binary '{ "orderId": "'"$tripId"'",
            "province": "florida", "city":"miami", "region": "region2",
            "oldOfficeName":  "test1",
            "newOffice": {
              "name": "test1",
              "address": "address1",
              "workTime": "0800-18:00",
              "windowNum": 3
              }
            }')
      echo $response |& tee -a $output_filename_4
      local status=${response:0:3}
      if [[ "$status" -ge "200" && "$status" -lt "300" ]]; then
        echo "PASS"
      else
        echo "FAILS"
      fi
    done
  fi
  echo "Test case 4 finished."
}

run_test_case_5() {
  test5_finished=false
  echo "Test case 5 started."
  local output_filename_5=$output_filename"_5.csv"
  rm -f $output_filename_5
  echo "5. Request order information use case"
  echo $file_header |& tee -a $output_filename_5
  local tripId=$tripId_tc4

  # Actual test case
  if [[ -z "$tripId" ]]; then
    echo "tripId is empty. In order to execute this test case a tripID is required."
  else
    local url="$hostname:$GATEWAY_SERVICE_PORT/api/v1/$ORDER_SERVICE/order/$tripId"
    for ((i = 1; i <= $times; i++)); do
      local response=$(curl -X GET \
        -w $format \
        -s $url \
        --output /dev/null \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer ' $token \
        -H 'Accept: application/json')
      echo $response |& tee -a $output_filename_5
      local status=${response:0:3}
      if [[ "$status" -ge "200" && "$status" -lt "300" ]]; then
        echo "PASS"
      else
        echo "FAILS"
      fi
    done
  fi
  echo "Test case 5 finished."
}

main "$@"
