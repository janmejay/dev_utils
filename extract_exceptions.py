#!/usr/bin/env python
#
# Extracts exceptions from log files.
#

import sys
import re
from collections import defaultdict

REGEX = re.compile("(^\tat |^Caused by: |^\t... \\d+ more)")
# Usually, all inner lines of a stack trace will be "at" or "Caused by" lines.
# With one exception: the line following a "nested exception is" line does not
# follow that convention. Due to that, this line is handled separately.
CONT = re.compile("; nested exception is: *$")

exceptions = defaultdict(int)

def registerException(exc):
  exceptions[exc] += 1

def processFile(fileName):
  with open(fileName, "r") as fh:
    currentMatch = None
    lastLine = None
    addNextLine = False
    for line in fh.readlines():
      if addNextLine and currentMatch != None:
        addNextLine = False
        currentMatch += line
        continue
      match = REGEX.search(line) != None
      if match and currentMatch != None:
        currentMatch += line
      elif match:
        currentMatch = lastLine + line
      else:
        if currentMatch != None:
          registerException(currentMatch)
        currentMatch = None
      lastLine = line
      addNextLine = CONT.search(line) != None
    # If last line in file was a stack trace
    if currentMatch != None:
      registerException(currentMatch)

for f in sys.argv[1:]:
  processFile(f)

for item in sorted(exceptions.items(), key=lambda e: e[1], reverse=True):
  print item[1], ":", item[0]
