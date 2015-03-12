#!/usr/bin/env python

# $ cd headers
# $ python sort_ios_headers.py

import os
import shutil

def ios_path_in_header(header_path):
    count = 0
    for line in open(header_path):
        count += 1
        if count == 2:
            # line expected to be like "   Image: /System/Library/Frameworks/Accounts.framework/Accounts"
            comps = line.split(" ")
            if len(comps) == 5:
                return comps[4][:-1]
                break
    return None

def dst_dir_for_ios_path(ios_path):
    ios_path_comps_full = ios_path.split(os.path.sep)
    
    if len(ios_path_comps_full) < 2:
        return None
    
    is_framework = ios_path_comps_full[-2].endswith('.framework')
    
    if is_framework:
        ios_path_comps = ios_path_comps_full[3:-1]
    else:
        ios_path_comps = ["lib", ios_path_comps_full[-1]]

    return os.path.sep.join(ios_path_comps)

for root, dirs, files in os.walk('.'):

    headers = (f for f in files if f.endswith(".h"))

    for f in headers:
        filename = os.path.splitext(f)[0]
        
        path = os.path.join(root, f)
        
        ios_path = ios_path_in_header(path)
        
        dst_dir = dst_dir_for_ios_path(ios_path)
        if not dst_dir:
            print "-- can't find dst_dir for", ios_path
            continue
        
        if not os.path.exists(dst_dir):
            os.makedirs(dst_dir)
                
        dst = os.path.join(dst_dir, f)

        print dst

        shutil.move(path, dst)
