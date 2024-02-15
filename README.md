### SubEnoom

Version 3.0



Script that combines many OSINT tools. Can intake domains, IPs, and subnets. 

By default SubEnoom will try to only show domains that are present in the domain list you provide. Try to give at least the highest most domain if possible. 


##### Download

```
git clone https://github.com/Kahvi-0/SubEnoom.git && cd SubEnoom && chmod +x ./subenoom.sh
```

##### Install

```
./setup.sh
```

Add API keys to the following configs on your host for max results.

Amass:
```
~/.config/amass/config.ini
```
theHarvester:
```
/etc/theHarvester/api-keys.yaml
```
Assetfinder


##### Syntax

```
./subenoom.sh -d domains.txt -o outputdirname
```

Example

```
./subenoom.sh -d domains.txt -o DNSEnum 
```


#### Domain file format:

```
example.com
example2.com
1.1.1.1
2.2.2.2-32
3.3.3.3/24
```

#### To Do

- List web servers that may just be IP based
- Seperate inscope and out of scope
- List of info about scan such as ports checked
- better list of live / inscope websites
