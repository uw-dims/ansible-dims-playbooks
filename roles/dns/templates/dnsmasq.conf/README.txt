DO NOT use a default 'dnsmasq.conf.j2' file here.

There is no generic configuration for a split-horizon DNS server, only specific
configurations that handle proxy/recursion for specific domain clients. Use
"skip: true" in the task that uses "with_first_found" logic to avoid
breaking DNS on a host that should be properly configured for split-horizon
DNS service.
