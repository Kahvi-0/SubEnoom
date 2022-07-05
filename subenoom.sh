#!/bin/bash

echo "Enum Script For Subdomains and OSINT URLS"

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

rm subdomains1.txt urls1.txt params1.txt && touch subdomains1.txt urls1.txt params1.txt

# Passive enum commands
## subdomain
### Amass
echo "Amass"
amassConfig=~/.config/amass/config.ini
amass enum -passive -df $domain -log amass.log -config $amassConfig >> subdomains1.txt
### assetfinder
#### Can add API keys detailed here:https://github.com/tomnomnom/assetfinder
echo "assetfinder"
cat $domain | assetfinder --subs-only >> subdomains1.txt

## Urls
### gau
echo "gau"
cat $domain | gau --subs --o urls1.txt

### waybackurls
echo "waybackurls"
cat $domain | waybackurls >> urls1.txt

# Active enum 
#brute force
# knock


## Check for subdomain hijack
#go get github.com/haccer/subjack
#~/go/bin/subjack -w $url/recon/final.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o $url/recon/potential_takeover/PT.txt

# Last checks 

##Uniq results
echo "sorting"
uniq urls1.txt > urls.txt && rm urls1.txt
## Pull parameters from results 
cat urls.txt | grep '?*=' | cut -d '=' -f 1 | sort -u > params.txt

## Pull domains from certs
#possibly cut out-of-scope domains (tho could be useful in some cases) 
#if any flag = -c cero will cut out of scope domains.
if [[ "$*" == *"-c"* ]]; then
	echo "cero respecting scope"
	scope=$(cat $domain | tr '\n' '|')
	cat subdomains1.txt | cero -d -c 1000 $ceroports | grep -E "($scope)" > subdomains2.txt
else
	echo "cero will include outofscope domains"
	cat subdomains1.txt | cero -d -c 1000 $ceroports > subdomains2.txt
fi
sort subdomains1.txt subdomains2.txt | uniq > subdomains.txt && rm subdomains1.txt && rm subdomains2.txt

## Check if domains are active
echo "checking which subdomains are alive"
cat ./subdomains.txt | httprobe $httprobeports > alivesubdomains1.txt

#### Add option to proxy traffic through burp

## Screenshot each domain
echo "getting screenshots"
wget -q https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip -O aquatone.zip && mkdir tools && unzip aquatone.zip -d tools/

#defaut ports "80,443,8000,8080,8443"
#cp alivesubdomains.txt http.txt
#cp alivesubdomains.txt https.txt
#sed -i -e 's/^/http:\/\//' http.txt
#sed -i -e 's/^/https:\/\//' https.txt
#cat http.txt https.txt > screenshots1.txt
sort alivesubdomains1.txt | uniq > alivesubdomains.txt
cat urls.txt >> alivesubdomains1.txt
#removing file types that really dont need screenshots
sort alivesubdomains1.txt | uniq | grep -v '.css\|.woff\|.js' > screenshots.txt
cat screenshots.txt | tools/aquatone $aquatoneports -silent -out ./

# Output
wget https://raw.githubusercontent.com/Kahvi-0/Pentest-Projects/master/Website%20Enumeration/Subdomain%20Enum/results.html
firefox ./results.html ./aquatone_report.html
