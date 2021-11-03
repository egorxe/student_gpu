DIRNAME=$(shell basename $(CURDIR))
PROGNAME=$(DIRNAME)
HEADERS=$(wildcard *.hh *.h)
CXXFLAGS += -g -I../include


$(PROGNAME): *.cc $(HEADERS)
	c++ $(CXXFLAGS) *.cc -o $(PROGNAME)
