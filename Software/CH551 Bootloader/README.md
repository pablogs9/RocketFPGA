/etc/udev/rules.d/99-ch559.rules
ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="5722", MODE="0666"
sudo udevadm control --reload-rules && sudo udevadm trigger