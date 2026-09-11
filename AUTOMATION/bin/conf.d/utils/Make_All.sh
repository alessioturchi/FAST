#!/bin/bash
#Compile all souces in current directory

for i in $(find . -name "source_*" |sort); do
  echo "************"
  echo "** ${i}"
  echo "************"
  cd $(basename "${i}")
  make
  EXIT=$?
  echo "************"
  if [ $EXIT -eq 0 ]; then
    echo "** ${i} Compiled successfully"
  else
    echo "!!! ERROR COMPILING ${i}"
    exit 1
  fi
  cd ..
  echo "************"
done
