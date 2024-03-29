# PartyTime

Join in the render party.

Utilize idle workstations to join BackBurner Server render Groups when no one is logged into the machine.

Upon GUI login to machine, PartyTime will remove machine from pre-defined BackBurner Server groups.
Upon logout,shutdown or reboot, the machine is added back to the groups.

## Demostration video:
https://youtu.be/4w36Qi4Bhsg
#
## Important Installation info:
`xmlstarlet` is a required package.  The INSTALL.sh script will automatically prompt to install this via the internet.  If this is not desired, manually install the `xmlstarlet` RPM prior to running PartyTime installer.

You must configure your partytime.conf file and reboot. PartyTime will not work until you have done this.  
# 

## Installation

1. Download latest release.
2. unzip on linux machine.
3.  `cd partytime-`*version number*
4. run `sudo ./INSTALL.sh --install`

## Security
A sudo rule is added as /etc/sudoers.d/partytime that allows **ALL** users to restart the adsk_backburner service.  This is neccessary to kick off the local machine from a render job when someone logs in.  Unfortunately this is the only workaround until Autodesk fixes Backburner Manager.

### **Required Configuration:**

1.  **Modify Configuration file**

	In `/opt/instinctual/partytime/partytime.conf` modify the parameters to match your infrastructure.

2.  **Add a `partytime` user to Backburner Manager**

		In BackBurner Monitor gui:
			1. Press Gear icon
			2. Under Administrator Users click Add
			3. type in `partytime`
			4. Press `enter`
			5. Click `Save` at bottom of app
![Backburner AddUser gif](https://github.com/instinctual/partytime/blob/3a3d93d6c8312fb857224a0cc9ebd336278c1ff0/adduser.gif)
3. **Reboot**
#
You can test functionality via the command line.

`/opt/instinctual/partytime/partytime.sh --add` will add the machine to the group(s) defined.

`/opt/instinctual/partytime/partytime.sh --remove` will remove the machine from the group(s) defined.
## When machine has Teradici/PCoIP active, PartyTime will act in a "remove always" mode, since Burn and other GPU based renders won't work.
#
## Un-Install
1. run `sudo ./INSTALL.sh --uninstall`
