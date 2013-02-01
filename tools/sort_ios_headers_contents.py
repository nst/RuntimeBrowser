#!/usr/bin/python

def write_header_description(filepath, first_lines, ivars, properties, class_methods, instance_methods):

    with open (filepath, 'w') as f:

        for l in first_lines:
            f.write(l)
        for l in ivars:
            f.write(l)
        f.write("}\n\n")
        
        for l in properties:
            f.write(l)
        
        f.write("\n")
        
        for l in class_methods:
            f.write(l)
        
        f.write("\n")
        
        for l in instance_methods:
            f.write(l)
        
        f.write("\n")

        f.write("@end\n")

def sort_header(path_in, path_out):

    ivars = []
    properties = []
    class_methods = []
    instance_methods = []
    
    first_lines = []
    has_seen_interface = False
    
    with open(path_in, 'r') as f:
        for line in f:
            
            if not has_seen_interface:
                first_lines.append(line)
    
            if line.startswith('@interface'):
                has_seen_interface = True
    
            if line.startswith('    '):
                ivars.append(line)
            elif line.startswith('@property'):
                properties.append(line)
            elif line.startswith('+'):
                class_methods.append(line)
            elif line.startswith('-'):
                instance_methods.append(line)
    
    ivars = sorted(ivars, key = lambda s: s.split(' ')[-1])
    properties = sorted(properties, key = lambda s: s.split(' ')[-1])
    class_methods = sorted(class_methods, key = lambda s: ')'.join(s.split(')')[1:]))
    instance_methods = sorted(instance_methods, key = lambda s: ')'.join(s.split(')')[1:]))

    write_header_description(path_out, first_lines, ivars, properties, class_methods, instance_methods)

sort_header("/Users/nst/Desktop/ACAccountCredential.h", "/Users/nst/Desktop/ACAccountCredential_.h")
