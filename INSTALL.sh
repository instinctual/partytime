#!/usr/bin/env bash

INSDIR="/opt/instinctual"
INSTALLDIR="$INSDIR/partytime"

cd "$(dirname "$0")" || exit
CURRENTDIR=`pwd`
cd $CURRENTDIR

# If the script is not running as root, it won't have permissions to install packages.
# So, check if the user has root privileges
if [[ $UID -ne 0 ]]; then
    echo "You must be root to install packages. Try running with sudo or as root."
    exit 1
fi

show_usage() {
    echo "Usage: $0 [--install | --uninstall]"
    echo "  --install       Install Partytime"
    echo "  --uninstall     Un-install Partytime"
}

# No options means we should display usage
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

# Save the option in a variable
ACTION=""

while [[ "$1" != "" ]]; do
    case $1 in
        --install)
            shift
            ACTION="install"
            ;;
        --uninstall)
            shift
            ACTION="uninstall"
            ;;
        *)
            echo "Invalid option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

if [[ $ACTION == "install" ]]; then
  # Check if xmlstarlet is installed
  if ! rpm -q xmlstarlet &>/dev/null; then
      echo
      echo "xmlstarlet is NOT installed."
      read -p "Do you want to install xmlstarlet? This will also install epel-release and requires an Internet Connection. (y/n) " choice

      echo "Testing for Internet connectivity to google.com.  Please wait."
      ping -W2 -c1 google.com > /dev/null
      if [ $? -eq 0 ]
        then
          echo "Internet is good.  Moving On."
          echo
        else
          echo "Installer needs Internet connectivity. Open the firewall and try again."
          exit 0
      fi

      case $choice in
          y|Y)
              check_internet
              # Attempt to install xmlstarlet
              dnf install -y epel-release
              dnf update -y epel-release
              dnf install -y xmlstarlet
              ;;
          n|N)
              echo "Exiting without installing xmlstarlet."
              exit 1
              ;;
          *)
              echo "Invalid choice. Exiting."
              exit 1
              ;;
      esac
  fi

    mkdir -p "$INSTALLDIR"
    install -m 555 partytimewrapper.sh "$INSTALLDIR"
    install -m 555 partytime.sh "$INSTALLDIR"
    install -m 440 partytime.rules /etc/sudoers.d/partytime
    install -m 444 partytime.desktop /etc/xdg/autostart/partytime.desktop

  # Check to see if there is an existing configuration file.
  if [ ! -f "$INSTALLDIR/partytime.conf" ]
    then
      install -m 664 partytime.conf.sample "$INSTALLDIR/partytime.conf"
      echo "**********************************************************************************************"
      echo "You MUST edit partytime.conf with the proper Backburner Manager and Groups info for your site."
      echo "**********************************************************************************************"
  else
    echo "Existing config file found, not going to replace."
  fi

  # Check if the user 'partytime' already exists
  if id "partytime" &>/dev/null; then
      echo "User 'partytime' already exists."
    else
      # Add the user 'partytime' as a system account with no login capabilities and locked account.
      useradd -M -r -s /sbin/nologin -d /tmp partytime --password '!'
      # Verify the user was created
      if id "partytime" &>/dev/null; then
          echo "User 'partytime' was successfully created."
        else
          echo "Failed to create the 'partytime' user."
          exit 2
      fi
  fi

  # Configure partytime.service
  install -m 444 partytime.service /etc/systemd/system/partytime.service
  systemctl daemon-reload
  echo "Starting PartyTime service."
  systemctl enable --now partytime.service
  
  echo
  echo "██████   █████  ██████  ████████ ██    ██ ████████ ██ ███    ███ ███████            "
  echo "██   ██ ██   ██ ██   ██    ██     ██  ██     ██    ██ ████  ████ ██                 "
  echo "██████  ███████ ██████     ██      ████      ██    ██ ██ ████ ██ █████              "
  echo "██      ██   ██ ██   ██    ██       ██       ██    ██ ██  ██  ██ ██                 "
  echo "██      ██   ██ ██   ██    ██       ██       ██    ██ ██      ██ ███████            "
  echo "                                                                                    "
  echo "                                                                                    "
  echo "███████ ██   ██  ██████ ███████ ██      ██      ███████ ███    ██ ████████ ██ ██ ██ "
  echo "██       ██ ██  ██      ██      ██      ██      ██      ████   ██    ██    ██ ██ ██ "
  echo "█████     ███   ██      █████   ██      ██      █████   ██ ██  ██    ██    ██ ██ ██ "
  echo "██       ██ ██  ██      ██      ██      ██      ██      ██  ██ ██    ██             "
  echo "███████ ██   ██  ██████ ███████ ███████ ███████ ███████ ██   ████    ██    ██ ██ ██ "
  echo

elif [[ "$ACTION" == "uninstall" ]]; then

  systemctl disable --now partytime.service
  rm -vf /etc/systemd/system/partytime.service
  rm -vf /etc/sudoers.d/partytime
  rm -vf /etc/xdg/autostart/partytime.desktop
  rm -vrf "$INSTALLDIR"
  userdel -r partytime
  
  # Check if the INSDIR
  if [[ -d $INSDIR ]]; then
      # Check if the INSDIR is empty
      if [[ ! "$(ls -A "$INSDIR")" ]]; then
          echo "Directory "$INSDIR" is empty. Deleting..."
          rmdir -v "$INSDIR"
          if [[ $? -eq 0 ]]; then
              echo "Directory "$INSDIR" successfully deleted."
          else
              echo "Failed to delete $INSDIR."
          fi
      else
          echo "Directory $INSDIR is not empty. Not deleting."
      fi
  else
      echo "Directory $INSDIR does not exist."
  fi
  echo "Partytime has been un-installed."
fi