#!/usr/bin/env bash

# function to clean up files and make executables
remake () {
    #echo -e "\nCleaning old files and making executables"
    make -s >/dev/null 2>&1
    make -C test-files/ -s >/dev/null 2>&1
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
#echo -e "\nTest cases for BoundedBuffer"

echo -e "\nTesting :: ./test-files/tester < test-files/test_single_msg.txt\n"
if timeout 20 ./test-files/tester < test-files/test_single_msg.txt >/dev/null 2>&1; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

echo -e "\nTesting :: ./test-files/tester < test-files/test_push_synch.txt\n"
if timeout 20 ./test-files/tester < test-files/test_push_synch.txt >/dev/null 2>&1; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

echo -e "\nTesting :: ./test-files/tester < test-files/test_pop_synch.txt\n"
if timeout 40 ./test-files/tester < test-files/test_pop_synch.txt >/dev/null 2>&1; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

echo -e "\nTesting :: ./test-files/tester < test-files/test_both_synch.txt\n"
if timeout 60 ./test-files/tester < test-files/test_both_synch.txt >/dev/null 2>&1; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi


remake
#echo -e "\nTest cases for datapoint transfers"

echo -e "\nTesting :: ./client -n 1000 -p 5 -w 100 -h 20 -b 5\n"
N=1000
P=5
if [ $(./client -n ${N} -p ${P} -w 100 -h 20 -b 5 | grep -oFw ${N} | wc -l) -eq ${P} ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
checkclean "f"

echo -e "\nTesting :: ./client -n 10000 -p 10 -w 100 -h 20 -b 30\n"
N=10000
P=10
if [ $(./client -n ${N} -p ${P} -w 100 -h 20 -b 30 | grep -oFw ${N} | wc -l) -eq ${P} ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
checkclean "f"


remake
#echo -e "\nTest cases for csv file transfers"

echo -e "\nTesting :: ./client -w 100 -b 30 -f 1.csv; diff -sqwB BIMDC/1.csv received/1.csv\n"
./client -w 100 -b 30 -f 1.csv >/dev/null 2>&1
if test -f "received/1.csv"; then
    if diff BIMDC/1.csv received/1.csv >/dev/null; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed${NC}"
    fi
else
    echo -e "  ${ORANGE}No 1.csv in received/ directory${NC}"
fi
checkclean "f"


remake
#echo -e "\nTest cases for binary file transfers"

echo -e "\nTesting :: truncate -s 256K BIMDC/test.bin; ./client -w 100 -b 50 -f test.bin; diff -sqwB BIMDC/test.bin received/test.bin\n"
truncate -s 256K BIMDC/test.bin
./client -w 100 -b 50 -f test.bin >/dev/null 2>&1
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

echo -e "\nTesting :: truncate -s 256K BIMDC/test.bin; ./client -w 100 -b 50 -m 8192 -f test.bin; diff -sqwB BIMDC/test.bin received/test.bin\n"
truncate -s 256K BIMDC/test.bin
./client -w 100 -b 50 -m 8192 -f test.bin >/dev/null 2>&1
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

echo -e "\n"
exit 0
