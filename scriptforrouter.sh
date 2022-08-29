/system identity
set name=hotspot.wi.fi
/interface ethernet
set [ find default-name=ether1 ] loop-protect=on name=V100
# интерфейс сети доступа  для «своих» [hotspot.wi.fi].
set [ find default-name=ether2 ] loop-protect=on name=V200
# интерфейс сети аплинка [bgp.your.area].
set [ find default-name=ether3 ] loop-protect=on name=V300

/interface bridge

add name=bridge-local

add name=bridge-public
 

/interface bridge port
add bridge=bridge-local interface=V200
 

/ip address
add address=172.30.0.10/24 comment="Uplink network" interface=V300 network=172.30.0.0
add address=172.16.0.1/24 comment="Management network" interface=V100 network=172.16.0.0
add address=172.20.0.1/24 comment="Hotspot network local" interface=bridge-local network=172.20.0.0
add address=172.21.0.1/24 comment="Hotspot network public" interface=bridge-public network=172.21.0.0
 

/ip pool
add name=hotspot.wi.fi ranges=172.20.0.2-172.20.0.99
add name=public.wi.fi ranges=172.21.0.2-172.21.0.99
 

/ip dhcp-server
add add-arp=yes address-pool=hotspot.wi.fi disabled=no interface=bridge-local name=hotspot.wi.fi
add add-arp=yes address-pool=public.wi.fi disabled=no interface=bridge-public name=public.wi.fi
 
/ip dhcp-server network
add address=172.20.0.0/24 comment=hotspot.wi.fi dns-server=172.20.0.1 domain=hotspot.wi.fi gateway=172.20.0.1 ntp-server=172.31.0.8,172.31.0.9
add address=172.21.0.0/24 comment=public.wi.fi dns-server=172.21.0.1 domain=public.wi.fi gateway=172.21.0.1 ntp-server=172.31.0.8,172.31.0.9
 

/ip dns
set allow-remote-requests=yes servers=172.31.0.3,172.31.0.4

/ip dns static
add address=172.20.0.1 name=hotspot.wi.fi ttl=5m
add address=172.21.0.1 name=public.wi.fi ttl=5m
add address=172.30.0.251 name=a.bgp.your.area ttl=5m
add address=172.30.0.252 name=b.bgp.your.area ttl=5m
add address=172.30.0.254 name=v.bgp.your.area ttl=5m

/ip hotspot profile
set [ find default=yes ] dns-name=hotspot.wi.fi hotspot-address=172.20.0.1 http-cookie-lifetime=1w name=hotspot.wi.fi
 

/ip hotspot
add address-pool=hotspot.wi.fi disabled=no interface=bridge-local name=hotspot.wi.fi
 
/ip hotspot user profile
set [ find default=yes ] address-pool=hotspot.wi.fi keepalive-timeout=1w mac-cookie-timeout=1d name=local shared-users=100
 
/ip hotspot user
add name=user1 password=password1
add name=user2 password=password2
 

/ip firewall address-list
.
add address=172.30.0.251 list="Main GW"  comment=a.bgp.your.area

add address=172.30.0.252 list="Main GW"  comment=b.bgp.your.area
add address=172.30.0.254 list="Main GW"  comment=v.bgp.your.area
add address=172.30.0.251 list="Services" comment=a.bgp.your.area
add address=172.30.0.252 list="Services" comment=b.bgp.your.area
add address=172.30.0.254 list="Services" comment=v.bgp.your.area
add address=172.31.0.3 list="Services" comment=a.dns.your.area
add address=172.31.0.4 list="Services" comment=b.dns.your.area
add address=172.31.0.8 list="Services" comment=a.ntp.your.area
add address=172.31.0.9 list="Services" comment=b.ntp.your.area
add address=172.16.0.251  list="Allowed"  comment=a.man.bgp.your.area
add address=172.16.0.252  list="Allowed"  comment=b.man.bgp.your.area
add address=172.16.0.254  list="Allowed"  comment=v.man.bgp.your.area
add address=172.16.0.101  list="Allowed"  comment=spot1.hotspot.wi.fi
add address=172.16.0.102  list="Allowed"  comment=spot2.hotspot.wi.fi
add address=172.16.0.103  list="Allowed"  comment=spot3.hotspot.wi.fi
add address=172.16.0.104  list="Allowed"  comment=spot4.hotspot.wi.fi
add address=172.16.0.105  list="Allowed"  comment=spot5.hotspot.wi.fi
 
 
/ip firewall filter
add action=drop chain=forward comment="Hide uplink devices" dst-address=172.30.0.0/24 dst-address-list="!Main GW" log=yes log-prefix=DROP_Inner-Lan src-address=0.0.0.0/0
add action=drop chain=forward comment="Hide Allowed devices" dst-address-list=Allowed log=yes log-prefix=DROP_Allowed src-address=0.0.0.0/0 src-address-list=!Services
add action=drop chain=input comment="Hide hotspot devices" dst-address=172.20.0.0/24 dst-address-list=!Allowed log=yes log-prefix=DROP_public src-address=172.21.0.0/24 src-address-list=!Allowed
add action=drop chain=forward comment="Hide hotspot devices" dst-address=172.20.0.0/24 dst-address-list=!Allowed log=yes log-prefix=DROP_public src-address=172.21.0.0/24 src-address-list=!Allowed
add action=drop chain=input comment="Hide hotspot devices" dst-address=172.21.0.0/24 dst-address-list=!Allowed log=yes log-prefix=DROP_public src-address=172.20.0.0/24 src-address-list=!Allowed

add action=drop chain=forward comment="Hide hotspot devices" dst-address=172.21.0.0/24 dst-address-list=!Allowed log=yes log-prefix=DROP_public src-address=172.20.0.0/24 src-address-list=!Allowed
 

/ip firewall nat

add action=masquerade chain=srcnat comment="Main NAT local" out-interface=V300 src-address=172.20.0.0/25

add action=masquerade chain=srcnat comment="Main NAT guest" out-interface=V300 src-address=172.21.0.0/25

add action=masquerade chain=srcnat comment="Allow all from V100 to Services" dst-address-list=Services out-interface=V300 src-address=172.16.0.0/24
 
 

/ip route
add check-gateway=ping distance=1 gateway=172.30.0.254
 

/ip service
set api disabled=yes
set www disabled=yes
set telnet disabled=yes
set api-ssl disabled=yes	
set ftp address=172.16.0.0/24
set ssh address=172.16.0.0/24
set winbox address=172.16.0.0/24
 

/tool mac-server
set [find default=yes] disabled=yes
/tool mac-server mac-winbox
add interface=V100
set [find default=yes] disabled=yes
 
 

/caps-man channel
add band=2ghz-b/g/n frequency=2412 name=CH1
add band=2ghz-b/g/n frequency=2417 name=CH2
add band=2ghz-b/g/n frequency=2422 name=CH3
add band=2ghz-b/g/n frequency=2427 name=CH4
add band=2ghz-b/g/n frequency=2432 name=CH5
add band=2ghz-b/g/n frequency=2437 name=CH6
add band=2ghz-b/g/n frequency=2442 name=CH7
add band=2ghz-b/g/n frequency=2447 name=CH8
add band=2ghz-b/g/n frequency=2452 name=CH9
add band=2ghz-b/g/n frequency=2457 name=CH10
add band=2ghz-b/g/n frequency=2462 name=CH11
add band=2ghz-b/g/n frequency=2467 name=CH12
add band=2ghz-b/g/n frequency=2472 name=CH13
add band=5ghz-a/n/ac frequency=5180 name=CH36
add band=5ghz-a/n/ac frequency=5200 name=CH40
add band=5ghz-a/n/ac frequency=5220 name=CH44
add band=5ghz-a/n/ac frequency=5240 name=CH48
add band=5ghz-a/n/ac frequency=5260 name=CH52
add band=5ghz-a/n/ac frequency=5280 name=CH56
add band=5ghz-a/n/ac frequency=5300 name=CH60
add band=5ghz-a/n/ac frequency=5320 name=CH64
add band=5ghz-a/n/ac frequency=5500 name=CH100
add band=5ghz-a/n/ac frequency=5520 name=CH104
add band=5ghz-a/n/ac frequency=5540 name=CH108
add band=5ghz-a/n/ac frequency=5560 name=CH112
add band=5ghz-a/n/ac frequency=5580 name=CH116
add band=5ghz-a/n/ac frequency=5600 name=CH120
add band=5ghz-a/n/ac frequency=5620 name=CH124
add band=5ghz-a/n/ac frequency=5640 name=CH128
add band=5ghz-a/n/ac frequency=5660 name=CH132
add band=5ghz-a/n/ac frequency=5680 name=CH136
add band=5ghz-a/n/ac frequency=5700 name=CH140
add band=5ghz-a/n/ac frequency=5745 name=CH149
add band=5ghz-a/n/ac frequency=5765 name=CH153
add band=5ghz-a/n/ac frequency=5785 name=CH157
add band=5ghz-a/n/ac frequency=5805 name=CH161
add band=5ghz-a/n/ac frequency=5825 name=CH165
 
/caps-man datapath
add bridge=bridge-local local-forwarding=yes name=datapath1
add bridge=bridge-local local-forwarding=yes name=datapath2
add bridge=bridge-public local-forwarding=no name=datapath3 vlan-id=1
add authentication-types=wpa2-psk encryption=aes-ccm,tkip name=public passphrase=PublicNetwork@wi.fi
 
/caps-man configuration
add channel=CH10 country=russia datapath=datapath1 mode=ap name=2G-config rx-chains=0,1,2 ssid=hs2.wi.fi tx-chains=0,1,2
add channel=CH36 country=russia datapath=datapath2 mode=ap name=5G-config rx-chains=0,1,2 ssid=hs5.wi.fi tx-chains=0,1,2
add channel=CH10 country=russia datapath=datapath3 mode=ap name=2G-config-pub rx-chains=0,1,2 security=public ssid=public.wi.fi tx-chains=0,1,2
 

/caps-man manager
set enabled=yes package-path=/firmware/caps upgrade-policy=require-same-version
 

/caps-man provisioning

add action=create-dynamic-enabled hw-supported-modes=b,gn identity-regexp="spot([0-9]+).hotspot.wi.fi" master-configuration=2G-config name-format=prefix-identity slave-configurations=2G-config-pub
add action=create-dynamic-enabled hw-supported-modes=an,ac identity-regexp="spot([0-9]+).hotspot.wi.fi" master-configuration=5G-config name-format=prefix-identity
/system ntp client

set enabled=yes primary-ntp=172.31.0.8 secondary-ntp=172.31.0.9

/system logging action
add disk-file-count=10 disk-file-name=log/auth disk-lines-per-file=4096 name=auth target=disk
add disk-file-count=10 disk-file-name=log/info disk-lines-per-file=4096 name=info target=disk
add disk-file-count=10 disk-file-name=log/error disk-lines-per-file=4096 name=error target=disk
add disk-file-count=10 disk-file-name=log/syslog disk-lines-per-file=4096 name=syslog target=disk
add disk-file-count=10 disk-file-name=log/warning disk-lines-per-file=4096 name=warning target=disk
add disk-file-count=10 disk-file-name=log/firewall disk-lines-per-file=4096 name=firewall target=disk
 
/system logging
set 0 action=info topics=info,!firewall,!account,!system
set 1 action=error
set 2 action=warning
add action=firewall topics=firewall
add action=auth topics=account
add action=syslog topics=system,!account
