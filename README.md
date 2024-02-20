## bind-load-zone.sh

Written and tested on Debian 9-12, this script can be used for a signed or unsigned domain, which is provided as an argument.<br>
It does the following:<br>

  1) Increments the serial of the domain's zone file<br>
  2) Checks if the domain is signed by looking in $BINDZONECONF<br>
  3) Re-signs the domain (if it was already signed)<br>
  4) Reloads BIND for the domain (rndc reload [DOMAIN])<br>
