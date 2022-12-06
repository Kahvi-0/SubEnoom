### SubEnoom

Script that combines many OSINT tools. Can intake domains, IPs, and subnets. 

By default SubEnoom will try to only show domains that are present in the domain list you provide. Try to give at least the highest most domain if possible. 

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
git clone https://github.com/Kahvi-0/SubEnoom.git && cd SubEnoom && chmod +x ./subenoom.sh
```

```
./subenoom.sh -d ./domains.txt -o outputdirname  -m (all|passive) <other arguments>
```

Other arguments

```
-c  tool cero will only return results with same domain(s) that are submitted to the tool

-p 80,443,8080,etc  ports for active tools to target
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

- Aquatone against web servers on IPs and not just domains
- List web servers that may just be IP based
- Seperate inscope and out of scope
