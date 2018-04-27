#!/bin/sh
rm runtime.log
bash -x install.sh |& tee runtime.log
