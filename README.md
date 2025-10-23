# SubEnoom
![image](https://github.com/Kahvi-0/SubEnoom/assets/46513413/5aa80594-aade-4ff9-a603-adda3dc6df2a)


Tool that combines many subdomain tools and methods. Can intake domains, IPs, and subnets. 

By default SubEnoom will try to only show domains that are present in the domain list you provide. Try to give at least the highest most domain if possible. 


### Download

```
git clone https://github.com/Kahvi-0/SubEnoom.git && cd SubEnoom
python3 -m venv subenum
source subenum/bin/activate
```

### Install Locally

```
chmod +x ./subenoom.sh
```

```
./setup.sh
```

### Install with Docker
<code style="color : red">Make sure to create scope.txt first</code>

```
sudo docker build -t subnoom .
```

-----

### Usage

**Run locally**
```
./subenoom.sh -d domains.txt -o outputdirname
```

Example

```
./subenoom.sh -d domains.txt -o DNSEnum 
```


**Run with Docker**

Note: the `/app` dir is where the output files are being stored within the container and mounted to the host at `app` in the running folder

Note: make sure to use --rm so the container does not persist
```
sudo docker run -v $(pwd)/app:/app/app -ti --rm subnoom -c "./subenoom.sh -d scope.txt -o /app/app/out"
```

<code style="color : red">The output files will be in the `app` directory on the host</code>


Options:
```
-f  add a filter that removes results for shared web hosting domains such as amazonaws.com and akamaiedge.net
-r  Do not resolve IPs for provided domains and add to scope
-a do not run amass since it can be very time consuming
-k custom amass key location
-s custom subfinder config file
-m custom amass config location
```

### Scope file format:

```
example.com
example2.com
1.1.1.1
2.2.2.2-32
3.3.3.3/24
```
------

**Cleanup docker: remove image**

List all images
```
sudo docker images -aq
```

Remove single image
```
sudo docker rmi -f [image]
```

Remove all images
```
sudo docker rmi -f $(sudo docker images -aq)
```

------

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
harvester.config
```

# Troubleshooting
-------

Errors with Amass config - this may be related to your host having a version of amass prior to 4.0. Double check what is called by default.
```
Failed to load the configuration file
```





