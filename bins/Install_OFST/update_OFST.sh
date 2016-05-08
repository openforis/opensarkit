#!/bin/bash

# The MIT License (MIT)
# Copyright (c) 2016 Andreas Vollrath

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

cd ${OPENSARKIT}
SECONDS=0
echo -ne " Updating OFST to the latest version ..." &&
git pull >> ${OSK_HOME}/LOG/log_update
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

SECONDS=0
echo -ne " Updating SNAP to the latest version ..." &&
snap --nosplash --nogui --modules --update-all  >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


