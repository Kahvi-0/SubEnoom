# SubEnoom
Version 3.1

![image](https://github.com/Kahvi-0/SubEnoom/assets/46513413/5aa80594-aade-4ff9-a603-adda3dc6df2a)


Script that combines many OSINT tools. Can intake domains, IPs, and subnets. 

By default SubEnoom will try to only show domains that are present in the domain list you provide. Try to give at least the highest most domain if possible. 


### Download

```
git clone https://github.com/Kahvi-0/SubEnoom.git && cd SubEnoom && chmod +x ./subenoom.sh
```

### Install Locally

```
./setup.sh
```

### Install with Docker

```
```

```
```

### Configuration 

### Add API keys to the following configs on your host for max results.

Amass:
```
amass.config
```
theHarvester:
```
/etc/theHarvester/api-keys.yaml
```

If using docker, update harvester.config this will be copied to the apikey location when the image is built

Subfinder:
```
subfinder.config
```


### Syntax

```
./subenoom.sh -d domains.txt -o outputdirname
```

Example

```
./subenoom.sh -d domains.txt -o DNSEnum 
```

Options:
```
-f  add a filter that removes results for shared web hosting domains such as amazonaws.com and akamaiedge.net
-r  Do not resolve IPs for provided domains and add to scope 
```

### Domain file format:

```
example.com
example2.com
1.1.1.1
2.2.2.2-32
3.3.3.3/24
```




