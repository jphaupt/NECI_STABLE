#!/usr/bin/env python

''' extract_guga.py [options] file 

Extract specific guga test suite data and output it in a format which can be used by testcode2.'''

import optparse
import sys

# specific output analysis for my guga "unit test" testsuite, which also compares the matrix elements with 
# Sandeeps Block code! 

# Test data to be searched for.
# Each element in this list is a list with information about a single test
# value. The first element gives the name, the second a string that should be
# searched for in the file, and the third gives the position of the data value
# in the line where the data is stored. The fourth element, a logical,
# specifies whether the quantity should be repeated multiple times in the
# output file, if multiple simulations are being performed (i.e., replicas
# or excited states).

# i have to additionally test for succesfull NECI and CSFOH runs: 
test_data = [
    ['ref_energy','<D0|H|D0>', -1, False],
    ['final_energy','Final energy estimate', -1, True],
    ['neci_success','NECI Run successful:',-1,False],
    ['csfoh_success','CSFOH Run succesful:',-1,False]
]

# i am not yet sure about the simulation labels:

# The following are strings to be searched for which specify which simulation
# or estimate is about to be printed. For example, when using replica tricks
# or calculating excited states. The second index specifies where in the line
# the simulation/state label is specified.
simulation_labels = [
    ['Final energy estimate for state', 5],
    ['Stochastic error measures for RDM', -1],
    ['FINAL ESTIMATES FOR RDM', -1]
]

def extract_data(filename):
    '''Extract test data from the input file.'''

    names = []
    values = []
    sim_label_string = ''

    f = open(filename)

    for line in f:
        # Search for a string specifying which simulation/state the data will be for.
        for sim_string in simulation_labels:
            if sim_string[0] in line:
                words = line.split()
                sim_label = words[sim_string[-1]].rstrip(":")
                sim_label_string = "_" + sim_label
        # Search for the data itself.
        for data in test_data:
            if data[1] in line:
                words = line.split()
                if data[3]:
                    # Use a header name with a simulation/state label.
                    names.append(data[0]+sim_label_string)
                else:
                    # Use a header name without a simulation/state label.
                    names.append(data[0])
                values.append(words[data[2]])

    f.close()

    return names, values

def write_data(names, values, padding):
    '''Write test data in a clean format.'''

    # Print data names.
    for (name, value) in zip(names, values):
        format = '%%-%is' % (max(len(value), len(name))+padding)
        sys.stdout.write(format % name)

    sys.stdout.write('\n')

    # Print the data values themselves.
    for (name, value) in zip(names, values):
        format = '%%-%is' % (max(len(value), len(name))+padding)
        sys.stdout.write(format % value)

    sys.stdout.write('\n')

def parse_options(args):
    '''Read and return filename and any options present.'''

    parser = optparse.OptionParser(usage = __doc__)
    (options, filename) = parser.parse_args(args)

    if len(filename) != 1:
        parser.print_help()
        sys.exit(1)

    return filename[0]

if __name__ == '__main__':
    filename = parse_options(sys.argv[1:])

    names, values = extract_data(filename)
    write_data(names, values, padding=2)
