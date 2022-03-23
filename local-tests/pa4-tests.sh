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
            echo "Failed to clean up FIFO files"
            find . -type p -exec echo {} +
            find . -type p -exec rm {} +
        fi
    elif [ "$1" = "q" ]; then
        if [ "$(find /dev/mqueue/ -user $USER)" ]; then
            echo "Failed to clean up MQ files"
            find /dev/mqueue/ -user $USER -exec rm {} +
        fi
    elif [ "$1" = "s" ]; then
        if [ "$(find /dev/shm/ -user $USER)" ]; then
            echo "Failed to clean up SHM files"
            find /dev/shm/ -user $USER -exec rm {} +
        fi
    else
        echo "broken"
        exit 1
    fi
}

# mounting /dev/mqueue/ if it is in virtual filesystem
echo -e "\nChecking for /dev/mqueue/ directory"
if [ ! -d "/dev/mqueue/" ]; then
    echo "Need root privilege to mount /dev/mqueue"
    sudo mkdir /dev/mqueue/
    sudo mount -t mqueue none /dev/mqueue/
else
    echo "Found it"
fi


echo -e "\nTo remove colour from tests, set COLOUR to 1 in sh file\n"
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


for i in f q s; do

    remake
    #echo -e "\nTest case for single datapoint transfers"

    echo -e "\nTesting :: ./client -i $i -p 14 -t 0.096 -e 1\n"
    VAL=$(awk -F, '$1 == "0.096" { print $2 }' BIMDC/14.csv)
    strace -e trace=mq_open,openat -o trace.tst ./client -i $i -p 14 -t 0.096 -e 1 >temp 2>/dev/null
    if grep -qF -- ${VAL} temp; then
        if [ "$i" = "f" ]; then
            if [ $(grep 'openat(AT_FDCWD, "fifo_control' trace.tst | wc -l) -eq $((2)) ]; then
                echo -e "  ${GREEN}Passed${NC}"
            else
                echo -e "  ${ORANGE}Incorrect channel type${NC}"
            fi
        elif [ "$i" = "q" ]; then
            if [ $(grep 'mq_open(' trace.tst | wc -l) -eq $((2)) ]; then
                echo -e "  ${GREEN}Passed${NC}"
            else
                echo -e "  ${ORANGE}Incorrect channel type${NC}"
            fi
        elif [ "$i" = "s" ]; then
            if [ $(grep 'openat(AT_FDCWD, "/dev/shm/' trace.tst | wc -l) -eq $((10)) ]; then
                echo -e "  ${GREEN}Passed${NC}"
            else
                echo -e "  ${ORANGE}Incorrent channel type${NC}"
            fi
        fi
    else
        echo -e "  ${RED}Failed${NC}"
    fi
    rm temp
    checkclean "$i"


    remake
    #echo -e "\nTest case for multiple datapoint transfers"

    echo -e "\nTesting :: ./client -i $i -p 9; diff -sqwB <(head -n 1000 BIMDC/9.csv) received/x1.csv\n"
    strace -e trace=mq_open,openat -o trace.tst ./client -i $i -p 9 >/dev/null 2>&1
    if test -f "received/x1.csv"; then
        if diff -wB <(head -n 1000 BIMDC/9.csv) received/x1.csv >/dev/null; then
            if [ "$i" = "f" ]; then
                if [ $(grep 'openat(AT_FDCWD, "fifo_control' trace.tst | wc -l) -eq $((2)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type${NC}"
                fi
            elif [ "$i" = "q" ]; then
                if [ $(grep 'mq_open(' trace.tst | wc -l) -eq $((2)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type${NC}"
                fi
            elif [ "$i" = "s" ]; then
                if [ $(grep 'openat(AT_FDCWD, "/dev/shm/' trace.tst | wc -l) -eq $((10)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrent channel type${NC}"
                fi
            fi
        else
            echo -e "  ${RED}Failed${NC}"
        fi
    else
        echo -e "  ${ORANGE}No x1.csv in received/ directory${NC}"
    fi
    checkclean "$i"


    remake
    # echo -e "\nTest case for binary file transfers (with varying buffer capacity)"

    echo -e "\nTesting :: truncate -s 256K BIMDC/test.bin; ./client -i $i -f test.bin -m 512; diff BIMDC/test.bin received/test.bin\n"
    truncate -s 256K BIMDC/test.bin
    strace -e trace=mq_open,openat -o trace.tst ./client -i $i -f test.bin -m 512 >/dev/null 2>&1
    if test -f "received/test.bin"; then
        if diff BIMDC/test.bin received/test.bin >/dev/null; then
            if [ "$i" = "f" ]; then
                if [ $(grep 'openat(AT_FDCWD, "fifo_control' trace.tst | wc -l) -eq $((2)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type${NC}"
                fi
            elif [ "$i" = "q" ]; then
                if [ $(grep 'mq_open(' trace.tst | wc -l) -eq $((2)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type${NC}"
                fi
            elif [ "$i" = "s" ]; then
                if [ $(grep 'openat(AT_FDCWD, "/dev/shm/' trace.tst | wc -l) -eq $((10)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrent channel type${NC}"
                fi
            fi
        else
            echo -e "  ${RED}Failed${NC}"
        fi
    else
        echo -e "  ${ORANGE}No test.bin in received/ directory${NC}"
    fi
    checkclean "$i"


    remake
    # echo -e "\nTest cases for new channel"

    echo -e "\nTesting :: ./client -i $i -c 3 -p 9; for i in {1..3}; do diff -sqwB <(head -n 1000 BIMDC/9.csv) received/x\$i.csv; done\n"
    NUMC=3
    strace -e trace=mq_open,openat -o trace.tst ./client -i $i -c ${NUMC} -p 9 >/dev/null 2>&1
    for n in $(eval echo "{1..${NUMC}}"); do
        if test -f "received/x$n.csv"; then
            if diff -wB <(head -n 1000 BIMDC/9.csv) received/x$n.csv >/dev/null; then
                if [ "$i" = "f" ]; then
                    if [ $(grep 'openat(AT_FDCWD, "fifo_data' trace.tst | wc -l) -eq $((2*NUMC)) ]; then
                        echo -e "  ${GREEN}Passed x$n.csv${NC}"
                    else
                        echo -e "  ${ORANGE}Incorrect channel type or not enough new channels opened${NC}"
                        break
                    fi
                elif [ "$i" = "q" ]; then
                    if [ $(grep 'mq_open(' trace.tst | wc -l) -eq $((2*(NUMC+1))) ]; then
                        echo -e "  ${GREEN}Passed x$n.csv${NC}"
                    else
                        echo -e "  ${ORANGE}Incorrect channel type or not enough new channels opened${NC}"
                        break
                    fi
                elif [ "$i" = "s" ]; then
                    if [ $(grep 'openat(AT_FDCWD, "/dev/shm/' trace.tst | wc -l) -eq $((6*NUMC+10)) ]; then
                        echo -e "  ${GREEN}Passed x$n.csv${NC}"
                    else
                        echo -e "  ${ORANGE}Incorrect channel type or not enough new channels opened${NC}"
                        break
                    fi
                fi
            else
                echo -e "  ${RED}Failed x$n.csv${NC}"
                break
            fi
        else
            echo -e "  ${ORANGE}No x$n.csv in received/ directory${NC}"
        fi
    done
    checkclean "$i"

    echo -e "\nTesting :: ./client -i $i -c 10 -f 10.csv -m 1024; diff BIMDC/10.csv received/10.csv\n"
    NUMC=10
    strace -e trace=mq_open,openat -o trace.tst ./client -i $i -c ${NUMC} -f 10.csv -m 1024 >/dev/null 2>&1
    if test -f "received/10.csv"; then
        if diff BIMDC/10.csv received/10.csv >/dev/null; then
            if [ "$i" = "f" ]; then
                if [ $(grep 'openat(AT_FDCWD, "fifo_data' trace.tst | wc -l) -eq $((2*NUMC)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type or not enough new channels opened${NC}"
                fi
            elif [ "$i" = "q" ]; then
                if [ $(grep 'mq_open(' trace.tst | wc -l) -eq $((2*(NUMC+1))) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type or not enough new channels opened${NC}"
                fi
            elif [ "$i" = "s" ]; then
                if [ $(grep 'openat(AT_FDCWD, "/dev/shm/' trace.tst | wc -l) -eq $((6*NUMC+10)) ]; then
                    echo -e "  ${GREEN}Passed${NC}"
                else
                    echo -e "  ${ORANGE}Incorrect channel type or not enough new channels opened${NC}"
                fi
            fi
        else
            echo -e "  ${RED}Failed${NC}"
        fi
    else
        echo -e "  ${ORANGE}No 10.csv in received/ directory${NC}"
    fi
    checkclean "$i"

done

make -s clean
echo -e "\n"
exit 0
