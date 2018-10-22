#!/bin/bash

subject="This is an e-letter"
body="Hello friendo"
from="capf96@gmail.com"
to="capf96@gmail.com 12-11555@usb.ve"

echo "$body" | mutt -s "$subject" -e "my_hdr From:$from" -- $to && echo "I did it!" || echo "Not so fast!"


