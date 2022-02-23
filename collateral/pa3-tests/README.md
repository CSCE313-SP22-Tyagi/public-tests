# <p align="center">Unit Tester for PA3 BoundedBuffer<p>

tester takes input in the form of a sequence of commands ```push <r>``` and ```pop <r>``` where ```r > 0``` is the number of requests of that type to send to the BoundedBuffer. The first two lines of input should be of the form:
```
# defaults included for convenience
[b <bbcap=5> s <wrdsize=16> n <numthrds=1>]

# threads will be put to sleep for [l, u] seconds where 0 < l < u
[l <min_sleep=0> u <max_sleep=1>] 0
```

If typing the commands directly, end sequece with ```Ctrl+D``` to represent EOF.

To run:
```
$ make

# input-file is optional - can also just use stdin
$ ./tester [< <input-file>]
```
