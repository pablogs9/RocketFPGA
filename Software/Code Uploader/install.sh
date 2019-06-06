#! /bin/bash
if [ "$EUID" -ne 0 ]
  then 
    cp fpga_upload.py ~/bin/fpga_upload
    chmod 555 ~/bin/fpga_upload
  else 
    cp fpga_upload.py /usr/bin/fpga_upload
    chmod 555 /usr/bin/fpga_upload
fi
