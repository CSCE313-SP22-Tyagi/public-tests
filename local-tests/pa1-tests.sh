#!/usr/bin/env bash

# function to clean up files and make executables
remake () {
    #echo -e "\nCleaning old files and making executables"
    make -s clean
    make -s >/dev/null 2>&1
}

# function to check for IPC files
checkclean () {
    if [ "$1" = "f" ]; then
        if [ "$(find . -type p)" ]; then
            #echo "Failed to close FIFORequestChannel - removing for next test"
            find . -type p -exec rm {} +
        fi
    else
        echo "something broke"
        exit 1
    fi
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
echo -e "\nVerify the server runs as child\n"
timeout 5 strace -e trace=execve -f -o trace.tst ./client -p 1 -t 0.004 -e 1 >/dev/null 2>&1
if ! grep -q 'execve("./server"' trace.tst; then
    echo "  Server does not run as child - can't test with script"
    exit 1
fi


remake
#echo -e "\nTest cases for single datapoint transfers"

echo -e "\nTesting :: ./client -p 12 -t 0.016 -e 1\n"
VAL=$(awk -F, '$1 == "0.016" { print $2 }' BIMDC/12.csv)
if ./client -p 12 -t 0.016 -e 1 | grep -qe ${VAL}; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
checkclean "f"

echo -e "\nTesting :: ./client -p 5 -t 59.996 -e 2\n"
VAL=$(awk -F, '$1 == "59.996" { print $3 }' BIMDC/5.csv)
if ./client -p 5 -t 59.996 -e 2 | grep -qe ${VAL}; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
checkclean "f"


remake
#echo -e "\nTest cases for multiple datapoint transfers"

echo -e "\nTesting :: ./client -p 9; diff -sqwB <(head -n 1000 BIMDC/9.csv) received/x1.csv\n"
./client -p 9 >/dev/null 2>&1
if test -f "received/x1.csv"; then
    if diff -wB <(head -n 1000 BIMDC/9.csv) received/x1.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No x1.csv in received/ directory${NC}"
fi
checkclean "f"

echo -e "\nTesting :: ./client -p 5; diff -sqwB <(head -n 1000 BIMDC/5.csv) received/x1.csv\n"
./client -p 5 >/dev/null 2>&1
if test -f "received/x1.csv"; then
    if diff -wB <(head -n 1000 BIMDC/5.csv) received/x1.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No x1.csv in received/ directory${NC}"
fi
checkclean "f"


remake
# echo -e "\nTest cases for CSV file transfers (with default buffer capacity)"

echo -e "\nTesting :: ./client -f 8.csv; diff BIMDC/8.csv received/8.csv\n"
./client -f 8.csv >/dev/null 2>&1
if test -f "received/8.csv"; then
    if diff BIMDC/8.csv received/8.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No 8.csv in received/ directory${NC}"
fi
checkclean "f"

echo -e "\nTesting :: ./client -f 2.csv; diff BIMDC/2.csv received/2.csv\n"
./client -f 2.csv >/dev/null 2>&1
if test -f "received/2.csv"; then
    if diff BIMDC/2.csv received/2.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No 2.csv in received/ directory${NC}"
fi
checkclean "f"


remake
# echo -e "\nTest cases for CSV file transfers (with varying buffer capacity)"

echo -e "\nTesting :: ./client -f 11.csv -m 512; diff BIMDC/11.csv received/11.csv\n"
./client -f 11.csv -m 512 >/dev/null 2>&1
if test -f "received/11.csv"; then
    if diff BIMDC/11.csv received/11.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No 11.csv in received/ directory${NC}"
fi
checkclean "f"


remake
# echo -e "\nTest cases for binary file transfers (with default buffer capacity)"

echo -e "\nTesting :: truncate -s 256K BIMDC/test.bin; ./client -f test.bin; diff BIMDC/test.bin received/test.bin\n"
truncate -s 256K BIMDC/test.bin
./client -f test.bin >/dev/null 2>&1
if test -f "received/test.bin"; then
    if diff BIMDC/test.bin received/test.bin >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No test.bin in received/ directory${NC}"
fi
checkclean "f"


remake
# echo -e "\nTest cases for binary file transfers (with varying buffer capacity)"

echo -e "\nTesting :: truncate -s 256K BIMDC/test.bin; ./client -f test.bin -m 512; diff BIMDC/test.bin received/test.bin\n"
truncate -s 256K BIMDC/test.bin
./client -f test.bin -m 512 >/dev/null 2>&1
if test -f "received/test.bin"; then
    if diff BIMDC/test.bin received/test.bin >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No test.bin in received/ directory${NC}"
fi
checkclean "f"


remake
# echo -e "\nTest cases for new channel"

echo -e "\nTesting :: ./client -c -p 12 -t 0.016 -e 1\n"
VAL=$(awk -F, '$1 == "0.016" { print $2 }' BIMDC/12.csv)
if strace -e trace=openat -o trace.tst ./client -c -p 12 -t 0.016 -e 1 2>/dev/null | grep -qe ${VAL}; then
    if grep -q 'openat(AT_FDCWD, "fifo_data' trace.tst; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${ORANGE}No new channel opened${NC}"
    fi
else
    echo -e "  ${RED}Failed${NC}"
fi
checkclean "f"

echo -e "\nTesting :: ./client -c -f 10.csv -m 1024; diff BIMDC/10.csv received/10.csv\n"
strace -e trace=openat -o trace.tst ./client -c -f 10.csv -m 1024 >/dev/null 2>&1
if test -f "received/10.csv"; then
    if diff BIMDC/10.csv received/10.csv >/dev/null; then
        if grep -q 'openat(AT_FDCWD, "fifo_data' trace.tst; then
            echo -e "  ${GREEN}Passed${NC}"
        else
            echo -e "  ${ORANGE}No new channel opened${NC}"
        fi
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No 10.csv in received/ directory${NC}"
fi
checkclean "f"

make -s clean
echo -e "\n"
exit 0
