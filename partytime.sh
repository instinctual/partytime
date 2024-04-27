#!/usr/bin/env bash

cd "$(dirname "$0")"
source partytime.conf
CURRENTHOST=$(hostname -s)

show_usage() {
    echo "Usage: $0 [--add | --remove]"
    echo "  --add       Add host to Backburner Group"
    echo "  --remove    Remove host from Backburner Group"
}

 TMPFILE=$(mktemp)

# No options means we should display usage
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

# Save the option in a variable
ACTION=""

while [[ "$1" != "" ]]; do
    case $1 in
        --add)
            shift
            ACTION="add"
            ;;
        --remove)
            shift
            ACTION="remove"
            ;;
        *)
            echo "Invalid option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# We have to do these pings, as Wiretap needs a kick sometimes to connect to the Manager
while true; do
    # Ping the host with a single packet
    /opt/Autodesk/wiretap/tools/current/wiretap_ping -t 100 -h $BBMANAGER:Backburner
    # Check if the last command was successful
    if [ $? -eq 0 ]; then
        echo "Ping successful!"
        break
    else
        echo "Ping failed. Retrying in 10 seconds..."
        sleep 10
    fi
done

# Get full XML for BBM Group
bbmgetallxml(){
    BBGROUPINFO=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info)
}

# Isolate the server list
bbmgetserverlistxml(){
    BBGROUPSERVERS=$(echo "$BBGROUPINFO" | xmlstarlet sel -t -v "/info/servers")
}

# Add the current host to the server XML list
bbmaddserverxml(){
    if echo "$BBGROUPINFO" | xmlstarlet sel -t -v "count(/info/servers/node())" | grep -q '^0$'; then
        # If <servers> is empty, add ${CURRENTHOST} without a comma
        BBGROUPINFO=$(echo "$BBGROUPINFO" | xmlstarlet ed --update "/info/servers" -x "concat(.,'${CURRENTHOST}')")
        else
        # If <servers> is not empty, add a comma before ${CURRENTHOST}
        BBGROUPINFO=$(echo $BBGROUPINFO | xmlstarlet ed --update "/info/servers" -x "concat(.,',${CURRENTHOST}')")
    fi
}

# Remove the current hostname from the server list
bbmremovehostxml(){
    BBGROUPSERVERS=$(echo $BBGROUPSERVERS | sed "s/\b$CURRENTHOST\b//; s/,,/,/; s/^,//; s/,$//")
}

# Update modified server list into the source XML
bbmupdateserverlistxml(){
    BBGROUPINFO=$(echo "$BBGROUPINFO" | xmlstarlet ed --update "/info/servers" --value "$BBGROUPSERVERS")
}

#Sumbit the modified XML list to Backburner Manager
bbmsubmitxml(){
    echo "$BBGROUPINFO" > $TMPFILE
    /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info -f $TMPFILE
    sleep 2
    rm $TMPFILE
}

# Check if PCOIP is active.  If so, then override ACTION and set to 'remove' since Burn expects to have a local window manager running and errors out if not.  
# So we do NOT add a host that is running PCOIP.
PCOIPSERVICE="pcoip"
PCOIPSTATUS=$(systemctl is-active "$PCOIPSERVICE")

if [ "$PCOIPSTATUS" == "active" ]; then
    ACTION=remove
fi

#Loop thru specified groups and add or remove the host.
for BBGROUP in "${BBGROUPS[@]}"; do
    bbmgetallxml
    if [[ $ACTION == "add" ]]; then
        # Check if the CURRENTHOST exists in that list
        bbmgetserverlistxml
        if ! echo $BBGROUPSERVERS | grep -q "\<${CURRENTHOST}\>"; then
            # If not, add the current host to the server XML list
            bbmaddserverxml
        fi
    elif [[ $ACTION == "remove" ]]; then
        bbmgetserverlistxml
        bbmremovehostxml
        bbmupdateserverlistxml  
    fi
    bbmsubmitxml
done

#Restart BB service to kick machine off from current render job
if [[ $ACTION == "remove" ]]; then
    sudo /usr/bin/systemctl stop adsk_backburner
    sleep 15
    sudo /usr/bin/systemctl start adsk_backburner
fi