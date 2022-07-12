#!/bin/bash

echo "Enum Script For Subdomains"
echo ""
echo "Parsing the domains list as the scope"

help_screen () {
	printf "\n HELP SCREEN \n\n"
	printf "./SubEnum.sh <domain list file> <output dirname> <type>\n"
	printf "\ntype= passive,all \n"
	printf "\n-p 80,443,8080,etc  ports for active tools to target\n"
	printf "\n-c makes sure that cero only returns inscope domains\n"
}

if [[ $1 = "-h" ]]; then
	help_screen
	exit 1
fi

if [ $# -lt 3 ]; then
	help_screen
	exit 1
fi

regex='^passive|all'
if [[ $3 =~ $regex ]]; then
	printf ""
else
	help_screen
	exit 1
fi

if [[ "$*" == *"all"* ]]; then
	echo "scan will include active methods"

else
	echo "scan will include only passive methods"
fi

#Arguments
domain=../$1
dir=$2

# Target ports
if [[ "$*" == *"-p"* ]]; then
      ports=$(echo $* | grep -oP '(\d.*\,.*\d)')
      aquatoneports="-ports $ports"
      ceroports="-p $ports"
      echo http:$ports > httpports.txt
      echo https:$ports > httpsports.txt
      sed -i -e 's/,/ http\:/g' httpports.txt
      sed -i -e 's/,/ https\:/g' httpsports.txt
      cat httpports.txt httpsports.txt | tr '\n' ' ' > httprobeports.txt && rm httpports.txt httpsports.txt
      httprobeports="-p $(cat ./httprobeports.txt)"
else
      aquatoneports=""
      ceroports=""
      httprobeports=""
fi

# Setup files / dirs
if [ ! -d "$dir" ]; then
	mkdir $dir
else
	echo "Directory already exists"
	exit 1
fi

cd $dir

touch subdomains1.txt params1.txt alivesubdomains1.txt

# Write used settings

# Passive enum
## subdomain
### Amass
echo "Amass"
amassConfig=~/.config/amass/config.ini
amass enum -passive -df $domain -log amass.log -config $amassConfig >> subdomains1.txt
### assetfinder
#### Can add API keys detailed here:https://github.com/tomnomnom/assetfinder
echo "assetfinder"
cat $domain | assetfinder --subs-only >> subdomains1.txt


### gau
#fetches known URLs from AlienVault's Open Threat Exchange, the Wayback Machine, Common Crawl, and URLScan for any given domain
echo "gau"
cat $domain | gau --subs | grep -oP '(?<=:\/\/).*?(?=\/|\?|$)' | sort | uniq >> subdomains1.txt

### waybackurls
#Pulls urls from wayback
echo "waybackurls"
cat $domain | waybackurls | grep -oP '(?<=:\/\/).*?(?=\/|\?|$)' | sort | uniq >> subdomains1.txt

# Add new passive methods above me


# Active enum 
if [[ "$*" == *"all"* ]]; then
	echo "Active Enum"
	#Permutation and wordlist generation
	#https://sidxparab.gitbook.io/subdomain-enumeration-guide/active-enumeration/permutation-alterations
	
	#brute force
	# knock

	## Check for subdomain hijack
	#go get github.com/haccer/subjack
	#~/go/bin/subjack -w $url/recon/final.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o $url/recon/potential_takeover/PT.txt


	# Add new active methods above me
fi


## Pull domains from certs

#if any flag = -c cero will cut out of scope domains.
if [[ "$*" == *"-c"* ]]; then
	echo "cero respecting scope"
	scope=$(cat $domain | tr '\n' '|')
	cat subdomains1.txt | sort | uniq | cero -d -c 1000 $ceroports | grep -E "($scope)" > subdomains2.txt
else
	echo "cero will include outofscope domains"
	cat subdomains1.txt | sort | uniq | cero -d -c 1000 $ceroports > subdomains2.txt
fi

sort subdomains1.txt subdomains2.txt | uniq > subdomains3.txt && rm subdomains1.txt && rm subdomains2.txt

# Scope parsing
if [[ "$*" == *"oos"* ]]; then
	echo ""
	mv subdomains3.txt subdomains.txt && rm subdomains3.txt
else
	echo "Removing top level domains not defined in domains file"
	grep -F -f $domain subdomains3.txt > subdomains.txt && rm subdomains3.txt
fi


## Check if domains are active
if [[ "$*" == *"all"* ]]; then
	echo "checking which subdomains are alive"
	cat ./subdomains.txt | httprobe $httprobeports > alivesubdomains1.txt
	sort alivesubdomains1.txt | uniq > alivesubdomains.html

else
	echo "<p><font style="color:red">Passive mode used</font></p>" > alivesubdomains.html
	cp subdomains.txt alivesubdomains1.txt
fi


#### Add option to proxy traffic through burp
## Screenshot each domain

# Final sorting
# Ideas to check for IPs and what is inscope

#Resolve domain to IP and check if resolved IP is in scope


filename=$(cat alivesubdomains1.txt)
#convert subnets to IP lists
cat $domain | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$' > expandedsubnets.txt
cat $domain | grep -E '^[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\-' >> expandedsubnets.txt
nmap -sL -iL ./expandedsubnets.txt -n  | awk '/Nmap scan report/{print $NF}' > inscopeips.txt && rm expandedsubnets.txt
cat $domain | grep -E '^[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$' >> inscopeips.txt
for i in $filename; do
	ip=$(host $i)
	if echo $ip | grep -F -f inscopeips.txt; then
	    echo "<p><font style="color:green"> $ip </font> </p>" >> alivesubdomainsX.html ;
	else
 	    echo "$ip" >> alivesubdomainsX.html ;
	fi
	done

cat alivesubdomainsX.html | grep -v 'not found: 3(NXDOMAIN)' > alivesubdomains.html

#removing file types that really dont need screenshots
if [[ "$*" == *"all"* ]]; then
	echo "getting screenshots of subdomains"
	wget -q https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip -O aquatone.zip && mkdir tools && unzip -qq aquatone.zip -d tools/
	sort alivesubdomains1.txt | uniq | grep -v '.css\|.woff\|.js' > screenshots.txt
	cat screenshots.txt | tools/aquatone $aquatoneports -silent -out ./
else
	echo ""
fi

# rm alivesubdomains1.txt

# Output
wget -q https://raw.githubusercontent.com/Kahvi-0/SubEnoom/main/results.html

if [[ "$*" == *"all"* ]]; then
	firefox ./results.html ./aquatone_report.html

else
	firefox ./results.html
fi
