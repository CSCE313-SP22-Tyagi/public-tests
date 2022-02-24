#include <stdlib.h>
#include <unistd.h>

#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

#include "BoundedBuffer.h"

#define CAP 5
#define SIZE 16
#define NUM 1
#define MIN_SLEEP 0
#define MAX_SLEEP 1

using namespace std;

// fill char buffer with random values
void make_word (char* buf, int size) {
    for (int i = 0; i < size; i++) {
        buf[i] = (rand() % 256) - 128;
    }
}

// mutex for synchronization of vector
mutex mtx;

// add element to vector
void add_word (vector<char*>* words, char* wrd) {
    mtx.lock();
    words->push_back(wrd);
    mtx.unlock();
}

// remove element from vector
void remove_word (vector<char*>* words, char* wrd, int size) {
    mtx.lock();
    for (vector<char*>::iterator iter = words->begin(); iter != words->end(); ++iter) {
        char* cur = *iter;
        bool equal = true;
        for (int i = 0; i < size; i++) {
            if (wrd[i] != cur[i]) {
                equal = false;
                break;
            }
        }
        if (equal) {
            words->erase(iter);
            delete[] cur;
            break;
        }
    }
    mtx.unlock();
}

// thread to push count char buffers to BoundedBuffer
void push_thread_function (int count, int min, int max, int size, vector<char*>* words, BoundedBuffer* bb) {
    for (int i = 0; i < count; i++) {
        char* wrd = new char[size];
        make_word(wrd, size);
        add_word(words, wrd);

        sleep((rand() % ((max+1)-min)) + min);

        bb->push(wrd, size);
    }
}

// thread to pop count char buffers from BoundedBuffer
void pop_thread_function (int count, int min, int max, int size, BoundedBuffer* bb, vector<char*>* words) {
    for (int i = 0; i < count; i++) {
        sleep((rand() % ((max+1)-min)) + min);

        char* wrd = new char[size];
        int read = bb->pop(wrd, size);

        if (read == size) {
            remove_word(words, wrd, size);
        }

        delete[] wrd;
    }
}

int main () {
    int bbcap = CAP;
    int wsize = SIZE;
    int nthrd = NUM;
    int lower = MIN_SLEEP;
    int upper = MAX_SLEEP;

    // change BoundedBuffer capacity, word size, number of threads, and sleep range
    char opt;
    int val;
    while (cin >> opt) {
        if (opt == '0') {
            break;
        }
        cin >> val;
        switch (opt) {
            case 'b':
                bbcap = val;
                break;
            case 's':
                wsize = val;
                break;
            case 'n':
                nthrd = val;
                break;
            case 'l':
                lower = val;
                break;
            case 'u':
                upper = val;
                break;
            default:
                cerr << "Invalid option - " << opt << endl;
                break;
        }
    }
    // validate values
    if (bbcap < 1) {
        bbcap = CAP;
    }
    if (wsize < 1) {
        wsize = SIZE;
    }
    if (nthrd < 1) {
        nthrd = NUM;
    }
    if (lower <= 0 || lower >= upper) {
        lower = MIN_SLEEP;
    }
    if (upper <= lower) {
        upper = lower+1;
    }
    cerr << "bbcap: " << bbcap << ", wsize: " << wsize << ", nthrd: " << nthrd << ", lower: " << lower << ", upper: " << upper << endl;

    // initialize overhead
    srand(time(nullptr));

    BoundedBuffer bb(bbcap);

    thread** push_thrds = new thread*[nthrd];
    thread** pop_thrds = new thread*[nthrd];
    for (int i = 0; i < nthrd; i++) {
        push_thrds[i] = nullptr;
        pop_thrds[i] = nullptr;
    }

    vector<char*> words;
    int count = 0;

    // process commands to test
    string type;
    int reqs = 0;
    int idx_push = 0;
    int idx_pop = 0;
    while (cin >> type >> reqs) {
        if (reqs <= 0) {
            cerr << "Invalid number of requests; not processing command" << endl;
            continue;
        }

        if (type == "push") {
            if (idx_push < nthrd) {
                push_thrds[idx_push++] = new thread(push_thread_function, reqs, lower, upper, wsize, &words, &bb);
                count += reqs;
                if (count > bbcap) {
                    cerr << "Push thread should block" << endl;
                }
            }
            else {
                cerr << "Out of push threads to create" << endl;
            }
        }
        else if (type == "pop") {
            if (idx_pop < nthrd) {
                pop_thrds[idx_pop++] = new thread(pop_thread_function, reqs, lower, upper, wsize, &bb, &words);
                count -= reqs;
                if (count < 0) {
                    cerr << "Pop thread should block" << endl;
                }
            }
            else {
                cerr << "Out of pop threads to create" << endl;
            }
        }
        else {
            cerr << "Invalid command :: " << type << endl;
        }
    }

    // verify input consumed
    if (!cin.eof()) {
        cerr << "Invalid input" << endl;

        // clean-up head allocated memory
        for (auto wrd : words) {
            delete[] wrd;
        }
        delete[] push_thrds;
        delete[] pop_thrds;

        return 1;
    }

    // joining all threads
    for (int i = 0; i < nthrd; i++) {
        if (push_thrds[i] != nullptr) {
            push_thrds[i]->join();
        }
        delete push_thrds[i];
        
        if (pop_thrds[i] != nullptr) {
            pop_thrds[i]->join();
        }
        delete pop_thrds[i];
    }

    // determining exit status
    cerr << count << " " << words.size() << " " << bb.size() << endl;
    int status = 0;
    if ((size_t) count != words.size() || (size_t) count != bb.size()) {
        status = 1;
    }

    // clean-up head allocated memory
    for (auto wrd : words) {
        delete[] wrd;
    }
    delete[] push_thrds;
    delete[] pop_thrds;

    return status;
}
