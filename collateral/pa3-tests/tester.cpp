#include <stdlib.h>

#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

#include "BoundedBuffer.h"

#define CAP 5
#define SIZE 16
#define NUM 1

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

// thread to push char buffer to BoundedBuffer
void push_thread_function (char* wrd, int size, BoundedBuffer* bb) {
    bb->push(wrd, size);
}

// thread to pop char buffer from BoundedBuffer
void pop_thread_function (int size, BoundedBuffer* bb, vector<char*>* words) {
    char* wrd = new char[size];
    int read = bb->pop(wrd, size);
    if (read != size) {
        delete[] wrd;
        return;
    }

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

    delete[] wrd;
}

int main () {
    int bbcap = CAP;
    int wsize = SIZE;
    int nthrd = NUM;

    // change BoundedBuffer capacity, word size, and number of threads
    char opt;
    int val;
    while (cin >> opt) {
        if (opt == 0) {
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
        }
    }
    cerr << bbcap << " " << wsize << " " << nthrd << endl;

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
    int idx_push = 0;
    int idx_pop = 0;
    while (cin >> type) {
        if (type == "push") {
            if (idx_push < nthrd) {
                char* wrd = new char[wsize];
                make_word(wrd, wsize);
                add_word(&words, wrd);
                push_thrds[idx_push++] = new thread(push_thread_function, wrd, wsize, &bb);
                count++;
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
                pop_thrds[idx_pop++] = new thread(pop_thread_function, wsize, &bb, &words);
                count--;
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
