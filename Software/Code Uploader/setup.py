from setuptools import setup

setup(
    install_requires = [
        'pyserial'
    ],
    scripts = [
        'fpga_upload.py'
    ]
)