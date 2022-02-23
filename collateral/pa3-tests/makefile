CXX=g++
CXXFLAGS=-std=c++17 -g -pedantic -Wall -Wextra -Werror -fsanitize=address,undefined -fno-omit-frame-pointer
LDLIBS=


SRCS=tester.cpp
DEPS=BoundedBuffer.cpp
BINS=$(SRCS:%.cpp=%.exe)
OBJS=$(DEPS:%.cpp=%.o)


all: clean $(BINS)

%.o: %.cpp %.h
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.exe: %.cpp $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(patsubst %.exe,%,$@) $^ $(LDLIBS)


.PHONY: clean

clean:
	rm -f tester *.o
