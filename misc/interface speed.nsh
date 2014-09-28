############
#
# Shows network speed of a given interface on a server
# Steven Alexson, Oct 17, 2008
#
###
#
# Requirements:
#     * NSH installed on source
#
###
#
# Parameters:
#     * Target server hostname
#
###
#
# This script retrieves the configuration information forn network adapters
# on a target host.
#
############
 
###
# Set Path
###

PATH=$PATH:/tech/bladelogic/sbin:/tech/bladelogic/bin

 
###
# Output usage information
###

print_usage() {
        echo ""
        echo "Usage: NetworkSpeed.nsh <HOSTNAME>"
        echo ""
        exit 1
}
 
###
# Output error message
###

print_error() {
        echo ""
        echo "ERROR: $1"
        echo ""
        echo "Script terminating!"
        echo ""
}

 
###
# Some variables used in the script
###

SERVER=$1
 
if [ ! "$SERVER" ]
then
        print_usage
fi
 
IFNAME=`nnet -c -H $SERVER | awk -F, '{print $2}' | tr -d '"'`

alias ipawk="awk -F, '{print \$5}'"

for i in `nnet -c -H $SERVER | ipawk | tr -d '"' | tr -d "^M"`; do (
        ###
        # Determine Interface Speed
        ###
 
        IPADDR=$i

        INAME=`blquery $SERVER -x $IPADDR -e 'net_interface_name ("IP = $ARGV[0]")' | tr -d "^M"`
 
        if [ "$INAME" = "-1" ]
        then
                die ("ERROR: Could not determine interface name!")
        fi
 
        MAC_ADDR=`blquery $SERVER -x "$INAME" -e 'net_mac_address ("NAME = $ARGV[0]")' | tr -d "^M"`
        BC_ADDR=`blquery $SERVER -x "$INAME" -e 'net_broadcast_address ("NAME = $ARGV[0]")' | tr -d "^M"`
        SUBNET=`blquery $SERVER -x "$INAME" -e 'net_subnet_mask ("NAME = $ARGV[0]")' | tr -d "^M"`
 
        echo "[$INAME]"
        echo "IP_ADDRESS = $IPADDR"
        echo "INTERFACE_NAME = $INAME"
        echo "MAC_ADDRESS = $MAC_ADDR"
        echo "BROADCAST_ADDRESS = $BC_ADDR"
        echo "SUBNET_MASK = $SUBNET"

        blquery $SERVER -x $INAME -e '
                set_variable ("FLAGS", net_flags ("NAME = $ARGV[0]"));
                printf ("INTERFACE_FLAGS = %s\n", $FLAGS);
 
                if ($FLAGS <= 0, printf ("INTERFACE_SPEED = NA"),
                        printf ("INTERFACE_SPEED = %s/sec (%s)",
                                if ($FLAGS & 1, "10 Mb", if ($FLAGS & 2, "100 Mb", if ($FLAGS & 4, "1 Gb", "NA"))),
                                if ($FLAGS & 32, "Half Duplex", if ($FLAGS & 64, "Full Duplex", "Auto")))
                );
                '
        );
        echo ''
done

 
unalias ipawk