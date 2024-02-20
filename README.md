## bind-load-zone.sh

This script can be used to increment, sign and reload a domain in BIND 9.  It can take a signed or unsigned domain as an argument, and will handle it appropriately.<br>
Written and tested on Debian 9-12.  <br><br>
The script does the following:<br>
  1) Increments the serial of the domain's zone file<br>
  2) Checks if the domain is signed by looking in $BINDZONECONF<br>
  3) Re-signs the domain (if it was previously signed)<br>
  4) Reloads BIND for the domain (rndc reload [DOMAIN])<br>
