# Implementation of RED in P4

## Environment Setup

To build the virtual machine:
- Install [Vagrant](https://vagrantup.com) and [VirtualBox](https://virtualbox.org)
- Clone the repository
- Before proceeding, ensure that your system has at least 12 Gbytes of free disk space, otherwise the installation can fail in unpredictable ways.
- `cd vm-ubuntu-20.04`
- `vagrant up` - The time for this step to complete depends upon your computer and Internet access speeds, but for example with a 2015 MacBook pro and 50 Mbps download speed, it took a little less than 20 minutes.  It requires a reliable Internet connection throughout the entire process.
- When the machine reboots, you should have a graphical desktop machine with the required software pre-installed.  There are two user accounts on the VM, `vagrant` (password `vagrant`) and `p4` (password `p4`).  The account `p4` is the one you are expected to use.

*Note*: Before running the `vagrant up` command, make sure you have enabled virtualization in your environment; otherwise you may get a "VT-x is disabled in the BIOS for both all CPU modes" error. Check [this](https://stackoverflow.com/questions/33304393/vt-x-is-disabled-in-the-bios-for-both-all-cpu-modes-verr-vmx-msr-all-vmx-disabl) for enabling it in virtualbox and/or BIOS for different system configurations.

You will need the script to execute to completion before you can see the `p4` login on your virtual machine's GUI. In some cases, the `vagrant up` command brings up only the default `vagrant` login with the password `vagrant`. Dependencies may or may not have been installed for you to proceed with running P4 programs. Please refer the [existing issues](https://github.com/p4lang/tutorials/issues) to help fix your problem or create a new one if your specific problem isn't addressed there.

To install dependencies by hand, please reference the [vm-ubuntu-20.04](./vm-ubuntu-20.04) installation scripts.
They contain the dependencies, versions, and installation procedure.
You should be able to run them directly on an Ubuntu 16.04 machine:
- `sudo ./root-bootstrap.sh`
- `sudo ./user-bootstrap.sh`

## Run the program
- Under folder `\src\red`, type command `make` to enter Mininet CLI, then you can run your tests based on the topology under the same folder.

## Viusalization of the running log
* Current visialization is using python, you can run command:
   - `python visualize_log.py`
   This will show you the running log of switch s1, specificly. And will display the instant queue length along with the average queue length in the same picture. The drop probability and the drop situation are shown in other two plots.


