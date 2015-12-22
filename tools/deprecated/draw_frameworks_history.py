#!/usr/bin/env python

# $ python draw_frameworks_history.py && open ios_framweorks.png

from PIL import Image, ImageDraw, ImageFont
import os

def build_data(path):
    d = {} # {'symbol':[('6.0', 'private'), ('6.1', 'public')]}

    for root, dirs, files in os.walk(path):
        sym_files = (f for f in files if len(f.split('_')) == 3 and f.endswith(".txt"))
        for filename in sym_files:
            path = os.path.join(root, filename)
    
            f_ = open(path)
            lines = f_.readlines()
            f_.close()
            
            file_type = filename.split('_')[2].split('.')[0]
            
            if file_type == 'pub':
                status = 'public'
            elif file_type == 'pri':
                status = 'private'
            elif file_type == 'lib':
                status = 'lib'
            else:
                raise Exception

            version = '.'.join(filename.split('_')[0:2])
            
            lines = [l.strip('\n') for l in lines]
            
            for name in lines:
                if not name in d:
                    d[name] = [(version, status)]
                else:
                    d[name].append((version, status))

    return d
 
def sorted_versions(d):
    versions = set()
    for version_status in d.values():
        for v, s in version_status:
            versions.add(v)
            
    sorted_versions = list(versions)
    sorted_versions.sort()

    return sorted_versions

def draw_data(d):
    TOP_MARGIN_HEIGHT = 12
    RIGHT_MARGIN_WIDTH = 220
    LINE_HEIGHT = 12
    BOX_WIDTH = 32
    FONT = ImageFont.truetype("/System/Library/Fonts/Monaco.dfont", 9)

    versions = sorted_versions(d)
    
    img = Image.new("RGB", (len(versions) * BOX_WIDTH + RIGHT_MARGIN_WIDTH, len(d) * LINE_HEIGHT + TOP_MARGIN_HEIGHT), 'lightgray')
    draw = ImageDraw.Draw(img)
    draw.fontmode="1" # antialiasing
    
    for (i, k) in enumerate(sorted(d.iterkeys())):
        draw.text((len(versions) * BOX_WIDTH + 3, TOP_MARGIN_HEIGHT + i * LINE_HEIGHT), k, fill="black", font=FONT)

        l = d[k]
        for (version, status) in l:
            color = 'red' if status == 'private' else 'green' if status == 'public' else 'blue'
            x1 = versions.index(version) * BOX_WIDTH + 1
            x2 = x1 + BOX_WIDTH - 2
            y1 = TOP_MARGIN_HEIGHT + i * LINE_HEIGHT
            y2 = TOP_MARGIN_HEIGHT + (i+1) * LINE_HEIGHT - 2
            draw.rectangle((x1, y1, x2, y2), fill=color)

    major = None
    for (i, v) in enumerate(versions):
        current_major = v.split('.')[0]
        if current_major != major:
            draw.line((i * BOX_WIDTH, 0, i * BOX_WIDTH, len(d) * LINE_HEIGHT + TOP_MARGIN_HEIGHT), fill="black")
            major = current_major  
        draw.text((i * BOX_WIDTH + 7, 0), v, fill="black", font=FONT)
    draw.line((len(versions) * BOX_WIDTH, 0, len(versions) * BOX_WIDTH, len(d) * LINE_HEIGHT + TOP_MARGIN_HEIGHT), fill="black")
    draw.line((0, TOP_MARGIN_HEIGHT, len(versions) * BOX_WIDTH, TOP_MARGIN_HEIGHT), fill="black")

    img.save("ios_frameworks.png", "PNG")

d = build_data('data')
draw_data(d)
