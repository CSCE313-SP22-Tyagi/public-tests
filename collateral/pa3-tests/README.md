# <p align="center">Unit Tester for PA3 BoundedBuffer<p>

tester takes input in the form of a sequence of commands ```push``` and ```pop```. The first line of input should be of the form ```[b <bbcap=5> s <wrdsize=16> n <numthrds=1>] 0``` - defaults shown here for convience. If typing the commands directly, end sequece with ```Ctrl+D``` to represent EOF.

To run:
```bash
$ make

# input-file is optional - can also just use stdin
$ ./tester [< <input-file>]
```
