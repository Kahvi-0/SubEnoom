# SubEnoom
Version 3.1

![image](https://github.com/Kahvi-0/SubEnoom/assets/46513413/5aa80594-aade-4ff9-a603-adda3dc6df2a)


Script that combines many OSINT tools. Can intake domains, IPs, and subnets. 

By default SubEnoom will try to only show domains that are present in the domain list you provide. Try to give at least the highest most domain if possible. 


### Download

```
git clone https://github.com/Kahvi-0/SubEnoom.git && cd SubEnoom
```

### Install Locally

```
chmod +x ./subenoom.sh
```

```
./setup.sh
```

### Install with Docker

Make sure to create scope.txt first

```
docker build -t subnoom .
```

Note: the `/tmp` dir is where the output files are being stored within the container and mounted to the host at `/app`
```
docker run -v $(pwd)/app:/tmp -ti --rm subnoom -c "./subenoom.sh -d scope.txt -o /tmp/out1.txt"
```

The output files will be in the `app` directory on the host

### Configuration 

### Add API keys to the following configs on your host for max results.

Amass:
Script calls amass.config to be used which calls this file to be used for API keys
```
amass.keys
```

Subfinder:
Script calls this file to be used for api keys
```
subfinder.config
```

theHarvester: 
This file is moved to correct location when docker image is built. If using local install put contents into `~/.theHarvester/api-keys.yaml`
```
theharvester.config
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




