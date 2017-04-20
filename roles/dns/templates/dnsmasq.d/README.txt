This directory holds files to be inserted into the /etc/dnsmasq.d
directory. These are additional configuration settings that could
have been included in /etc/dnsmasq.conf, but instead have been
modularized and placed into this directory to facilitate management
of one or more alternative zones for things like "split-horizon"
(a.k.a., "split-brain") DNS.  (For more on how "split-horizon"
DNS works, see https://staff.washington.edu/dittrich/home/network.html#dns)

Each of the files placed into the /etc/dnsmasq.d directory hold
configuration settings, which can handle things like DNS domain
to IP CIDR block mappings, server associations, and CNAME
mappings. An associated file whose name starts with "/etc/hosts."
can then hold IP to DNS name mappings that complete the
zone definition. These should be inserted in pairs as
shown here.


          /etc/default/dnsmasq
                      |
                      |
                      v
/etc/dnsmasq.conf --> /etc/dnsmasq.d
                      ├── consul --> /.consul/NN.NN.NN.NN#PP
                      ├── dims   --> /etc/hosts.dims
                      └── local  --> /etc/hosts.local
