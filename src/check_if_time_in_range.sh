#!/bin/bash

# USAGE: bash check_if_time_in_range.sh $sunrise_sunset_time $time_str $margin_mins
#### example:
#   sunrise_sunset_time="06:32 19:57"
#   time_str="11:06"
#   margin_mins=30
#   bash check_if_time_in_range.sh $sunrise_sunset_time $time_str $margin_mins
#    ---> true

#### example for testing:
# sunrise_sunset_time="06:32 19:57"
# for thours in {00..23}; do
#     for tmins in {00..59}; do
#         time_str="${thours}:${tmins}"
#         bash check_if_time_in_range.sh $sunrise_sunset_time $time_str $margin_mins
#     done
# done

start_time=$1
end_time=$2
test_time=$3
margin_mins=$4

function time2mins(){
    mins=$(echo ${1:3:2} | sed 's/^0*//')
    #hours=$(echo ${1:0:2} | sed 's/^0*//')
    hours=$([ "${1:0:1}" == 0 ] && echo "${1:1:1}" || echo "${1:0:2}" | sed 's/^0*//')
    echo "$(($mins + 60*$hours))"
}

start_time_mins=$(time2mins $start_time)
end_time_mins=$(time2mins $end_time)
test_time_mins=$(time2mins $test_time)

# echo "$start_time (=$start_time_mins)"
# echo "$end_time (=$end_time_mins)"
# echo "$test_time (=$test_time_mins)"

if (( $test_time_mins < $start_time_mins + $margin_mins )) || (( $test_time_mins > $end_time_mins - $margin_mins )); then
    echo false
else
    echo true
fi
