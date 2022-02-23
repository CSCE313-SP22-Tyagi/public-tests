#!/usr/bin/env bash

# function to clean up files and make executables
remake () {
    #echo -e "\nCleaning old files and making executables"
    make -s clean
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


#echo -e "\nStart testing"
remake
echo -e "\nTesting :: echo \"Hello world | Life is Good > Great $\"\n"
cat ./test-files/test_echo_double.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_echo_double.txt)
if ./shell < ./test-files/cmd.txt 2>/dev/null | grep -qF -- "${RES}"; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

remake
echo -e "\nTesting :: ls\n"
cat ./test-files/test_ls.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_ls.txt)
if ./shell < ./test-files/cmd.txt 2>/dev/null | grep -qF -- "${RES}"; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

remake
echo -e "\nTesting :: ls -l /usr/bin\n"
cat ./test-files/test_ls_l_usr_bin.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_ls_l_usr_bin.txt)
if ./shell < ./test-files/cmd.txt 2>/dev/null | grep -qF -- "${RES}"; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

remake
echo -e "\nTesting :: ls -l -a\n"
cat ./test-files/test_ls_l_a.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_ls_l_a.txt)
if ./shell < ./test-files/cmd.txt 2>/dev/null | grep -qF -- "${RES}"; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

remake
echo -e "\nTesting :: ps aux\n"
cat ./test-files/test_ps_aux.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_ps_aux.txt)
if ./shell < ./test-files/cmd.txt 2>/dev/null | grep -qF -- "${RES}"; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

remake
echo -e "\nTesting :: ps aux > a; grep /usr < a; grep /usr < a > b\n"
cat ./test-files/test_input_output_redirection.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_input_output_redirection.txt)
rm -f a b
./shell < ./test-files/cmd.txt >temp 2>/dev/null
if grep -qF -- "${RES}" temp; then
    if [ -f a ] && [ -f b ] && grep -qF -- "${RES}" b; then
        echo -e "  ${GREEN}Passed${NC}"
    else
        echo -e "  ${RED}Failed file creation${NC}"
    fi
else
    echo -e "  ${RED}Failed final output${NC}"
fi
rm temp

remake
echo -e "\nTesting :: ls -l | grep \"shell.cpp\"\n"
cat ./test-files/test_single_pipe.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_single_pipe.txt)
NOTRES=$(ls -l | grep "Tokenizer.cpp")
strace -e trace=execve -f -o out.trace ./shell < ./test-files/cmd.txt >temp 2>/dev/null
LS=$(which ls)
GREP=$(which grep)
if grep -q "execve(\"${LS}\"" out.trace && grep -q "execve(\"${GREP}\"" out.trace && grep -qFw -- "${RES}" temp && ! grep -qFw -- "${NOTRES}" temp; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
rm temp

remake
echo -e "\nTesting :: ps aux | awk ""'""/usr/{print \$1}""'"" | sort -r\n"
cat ./test-files/test_multiple_pipes_A.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_multiple_pipes_A.txt)
ARR=($RES)
echo "${RES}" >cnt.txt
CNT=$(grep -oF -- "${ARR[0]}" cnt.txt | wc -l)
strace -e trace=execve -f -o out.trace ./shell < ./test-files/cmd.txt >temp 2>/dev/null
PS=$(which ps)
AWK=$(which awk)
SORT=$(which sort)
if grep -q "execve(\"${PS}\"" out.trace && grep -q "execve(\"${AWK}\"" out.trace && grep -q "execve(\"${SORT}\"" out.trace && grep -qFw -- "${RES}" temp && [ $(grep -oFw -- "${ARR[0]}" temp | wc -l) -le $((${CNT}+3)) ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
rm cnt.txt temp

remake
echo -e "\nTesting :: Multiple Pipes & Redirection\n"
cat ./test-files/test_multiple_pipes_redirection.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
RES=$(. ./test-files/test_multiple_pipes_redirection.txt)
echo "${RES}" >cnt.txt
CNT=$(grep -oF -- "${RES}" cnt.txt | wc -l)
rm -f cnt.txt test.txt output.txt
if [ $(./shell < ./test-files/cmd.txt 2>/dev/null | grep -oFw -- "${RES}" | wc -l) -eq ${CNT} ] && [ -f test.txt ] && [ -f output.txt ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi

remake
echo -e "\nTesting :: cd ../../\n"
cat ./test-files/test_cd_A.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
DIR=$(. ./test-files/test_cd_A.txt)
./shell < ./test-files/cmd.txt >temp 2>/dev/null
if [ $(grep -oF -- "${DIR}" temp | wc -l) -ge 3 ] && [ $(grep -oF -- "${DIR}/" temp | wc -l) -le 1 ]; then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
rm temp

remake
echo -e "\nTesting :: cd -\n"
cat ./test-files/test_cd_B.txt ./test-files/test_exit.txt > ./test-files/cmd.txt
TEMPDIR=$(cd /home && pwd)
DIR=$(. ./test-files/test_cd_B.txt | head -n 1)
./shell < ./test-files/cmd.txt >temp 2>/dev/null
if [ $(grep -oF -- "${DIR}" temp | wc -l) -ge 3 ] && ( [ $(grep -oF -- "${TEMPDIR}" temp | wc -l) -le 1 ] || ( grep -qF -- "${TEMPDIR}/" <<< "$DIR" && [ $(grep -oF -- "${TEMPDIR}" temp | wc -l) -gt $(grep -oF -- "${DIR}" temp | wc -l) ] ) ); then
    echo -e "  ${GREEN}Passed${NC}"
else
    echo -e "  ${RED}Failed${NC}"
fi
rm temp

exit 0
