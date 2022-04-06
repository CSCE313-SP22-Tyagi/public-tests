#!/usr/bin/env bash

# function to clean up files and make executables
remake () {
    #echo -e "\nCleaning old files and making executables"
    make -s >/dev/null 2>&1
}


echo -e "To remove colour from tests, set COLOUR to 1 in sh file\n"
COLOUR=0
if [[ COLOUR -eq 0 ]]; then
    ORANGE='\033[0;33m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    ORANGE='\033[0m'
    GREEN='\033[0m'
    RED='\033[0m'
    NC='\033[0m'
fi


remake
#echo -e "\nTest cases for datapoint transfers"

echo -e "\nTesting :: ./server -r 8080 & ./client -a 127.0.0.1 -r 8080 -n 1000 -p 5 -w 100 -h 20 -b 5\n"
N=1000
P=5
./server -r 8080 >/dev/null &
sleep 1
./client -a 127.0.0.1 -r 8080 -n ${N} -p ${P} -w 100 -h 20 -b 5 >out.tst
if [ $(comm -12 out.tst test-files/data1.txt | wc -l) -eq $(cat test-files/data1.txt | wc -l) ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
kill $! 2>/dev/null
wait $! 2>/dev/null

echo -e "\nTesting :: ./server -r 8081 & ./client -a 127.0.0.1 -r 8081 -n 10000 -p 10 -w 100 -h 20 -b 30\n"
N=10000
P=10
./server -r 8081 >/dev/null &
sleep 1
./client -a 127.0.0.1 -r 8081 -n ${N} -p ${P} -w 100 -h 20 -b 30 >out.tst
if [ $(comm -12 out.tst test-files/data2.txt | wc -l) -eq $(cat test-files/data2.txt | wc -l) ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
kill $! 2>/dev/null
wait $! 2>/dev/null


remake
#echo -e "\nTest cases for csv file transfers"

echo -e "\nTesting :: ./server -r 8082 & ./client -a 127.0.0.1 -r 8082 -w 100 -b 30 -f 1.csv; diff -sqwB BIMDC/1.csv received/1.csv\n"
./server -r 8082 >/dev/null &
sleep 1
./client -a 127.0.0.1 -r 8082 -w 100 -b 30 -f 1.csv >/dev/null
if test -f "received/1.csv"; then
    if diff BIMDC/1.csv received/1.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No 1.csv in received/ directory${NC}"
fi
kill $! 2>/dev/null
wait $! 2>/dev/null


remake
#echo -e "\nTest cases for binary file transfers"

echo -e "\nTesting :: ./server -r 8083 & truncate -s 256K BIMDC/test.bin; ./client -a 127.0.0.1 -r 8083 -w 100 -b 50 -f test.bin; diff -sqwB BIMDC/test.bin received/test.bin\n"
truncate -s 256K BIMDC/test.bin
./server -r 8083 >/dev/null &
sleep 1
./client -a 127.0.0.1 -r 8083 -w 100 -b 50 -f test.bin >/dev/null
if test -f "received/test.bin"; then
    if diff BIMDC/test.bin received/test.bin >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No test.bin in received/ directory${NC}"
fi
kill $! 2>/dev/null
wait $! 2>/dev/null

echo -e "\nTesting :: ./server -r 8084 -m 4096 & truncate -s 256K BIMDC/test.bin; ./client -a 127.0.0.1 -r 8084 -w 100 -b 50 -m 4096 -f test.bin; diff -sqwB BIMDC/test.bin received/test.bin\n"
truncate -s 256K BIMDC/test.bin
./server -r 8084 -m 4096 >/dev/null &
sleep 1
./client -a 127.0.0.1 -r 8084 -w 100 -b 50 -m 4096 -f test.bin >/dev/null
if test -f "received/test.bin"; then
    if diff BIMDC/test.bin received/test.bin >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No test.bin in received/ directory${NC}"
fi
kill $! 2>/dev/null
wait $! 2>/dev/null

echo -e "\n"
exit 0
