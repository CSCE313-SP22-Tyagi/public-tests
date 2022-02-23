#include <getopt.h>
#include <stdlib.h>

#include "BoundedBuffer.h"

#define CAP 10
#define SIZE 15
#define NUM 1

int main (int argc, char** argv) {
    int bbcap = CAP;
    int wsize = SIZE;
    int nthrd = NUM;

    // CLI option to change BoundedBuffer capacity, word size, and number of threads
    int opt;
    static struct option long_options[] = {
        {"bbcap", required_argument, nullptr, 'b'},
        {"wsize", required_argument, nullptr, 's'},
        {"nthrd", required_argument, nullptr, 'n'},
        {0, 0, 0, 0}
    };
    while ((opt = getopt_long(argc, argv, "b:s:n:", long_options, nullptr)) != -1) {
        switch (opt) {
            case 'b':
                bbcap = atoi(optarg);
            case 's':
                wsize = atoi(optarg);
            case 'n':
                nthrd = atoi(optarg);
        }
    }


}
