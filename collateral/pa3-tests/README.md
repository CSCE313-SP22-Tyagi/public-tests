# <p align="center">Unit Tester for PA3 BoundedBuffer<p>

tester takes input in the form of a sequence of commands ```push``` and ```pop```. If typing the commands directly, end sequece with ```Ctrl+D``` to represent EOF.

To run:
```bash
$ make

# input-file is optional - can also just use stdin
$ ./tester -b <bbcap> -s <wrdsize> -n <numthrds> [< <input-file>]
```
