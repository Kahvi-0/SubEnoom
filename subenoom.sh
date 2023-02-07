#!/bin/bash

# For the moment, this tool will be focues on IPv4

# Error handling 
#set -e
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

echo "Enum Script For Subdomains"
echo ""
echo "Parsing the domains list as the scope"

subwordlist='/usr/share/wordlists/amass/fierce_hostlist.txt'
#subwordlist='/usr/share/wordlists/amass/jhaddix_all.txt'


help_screen() {
	printf "\n HELP SCREEN \n\n"
	printf "./SubEnum.sh -d <domain list file> -o <output dirname> -m <mode>\n"
	printf "\nmode= passive,all \n"
	printf "\n-p 80,443,8080,etc  ports for active tools to target\n"
}

check_mode() {
	regex='^passive|all'
	if [[ $mode =~ $regex ]]; then
		printf ""
	else
		help_screen
		exit 1
	fi
}

progalt() {

    if [[ "$call" == 1 ]]; then
        clear -x
    	stats
    	echo 'Still trying to find subdomains ヾ(･ω･*)ﾉ'
    	call=2
    else
        clear -x
    	stats
    	echo 'Still trying to find subdomains (＾-＾)旦 '
    	call=1
    fi
}

call=1

stats() {
	echo " -----------------------------"
	echo "| Domain list: $domain"
	echo "| Output Directory: $dir"
	echo "| Mode: $mode"
	echo " -----------------------------"
	echo " "
}

while getopts ":d:o:m:h:" option; do
	case "${option}" in
		d) # List of domains and IPs
			domain=$(pwd)/${OPTARG};;
		o) # Output dir
			dir=${OPTARG};;
		m) # Passive or all tests
			mode=${OPTARG}
			check_mode ;;
		h) # Display Help
			help_screen
			exit 1;;
		\?) # Invalid option
			echo "Error: Invalid option"
			exit 1;;
	esac
done


# Check for mandatory args
if [ -z "$domain" ] || [ -z "$dir" ] || [ -z "$mode" ]; then
    help_screen
    exit 1
fi

# Checking the scan mode
if [[ "$mode" == *"all"* ]]; then
	echo "scan will include active methods"
else
	echo "scan will include only passive methods"
fi

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
while true; do
	if [ ! -d "$dir" ]; then
		mkdir $dir
	else
		echo "Directory already exists"
		echo ""
		echo "Choose a new output directory name"
		read dir
		echo "new output directory will be $dir"
		continue
	fi
	break
done

cd $dir
touch subdomains1.txt params1.txt alivesubdomains1.txt

#convert subnets to IP list and create an expanded list of inscope IPs and domains
file=$(cat $domain)
for i in $file; do
	if echo $i | grep -q -E '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' ; then
		echo ""
	else
		host $i | grep -oE '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' >> inscopeips.txt
		echo $i >> InputHosts.txt
		echo $i
	fi
	done

cat $domain | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$' >> expandedsubnets.txt
cat $domain | grep -E '^[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\-' >> expandedsubnets.txt
nmap -sL -iL ./expandedsubnets.txt -n  | grep -oE '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' | sort | uniq >> inscopeips.txt && rm expandedsubnets.txt
cat $domain | grep -E '^[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$' >> inscopeips.txt
cat inscopeips.txt InputHosts.txt | uniq >> ExpandedScope.txt
domain=ExpandedScope.txt

#Note that this is the top results from this sites demo and may not be all associated domains
file=$(cat inscopeips.txt)
for i in $file; do
	curl -i -s -k -X $'GET' -H $'Host: ipinfo.io' -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0' "https://ipinfo.io/$i?dataset=reverse-api" | grep -oP '(?<=noopener">).*(?=<\/a>)' >> ReverseIP.txt
	done
	
# Expand input domain file and move over to using expanded list for rest of script

#==========================================
#=========PASSIVE ENUMERATION TOOLS========
#==========================================
### Amass
progalt && echo ""
echo "Amass"
amassConfig=~/.config/amass/config.ini
amass enum -passive -df $domain -log amass.log -config $amassConfig >> amass.txt
cat amass.txt >> subdomains1.txt

### assetfinder
progalt && echo ""
echo "assetfinder"
cat $domain | assetfinder --subs-only >> assetfinder.txt
cat assetfinder.txt >> subdomains1.txt

### gau
progalt && echo ""
#fetches known URLs from AlienVault's Open Threat Exchange, the Wayback Machine, Common Crawl, and URLScan for any given domain
echo "gau"
cat InputHosts.txt | gau --subs --blacklist png,jpg,jpeg,gif,css,svg,woff,woff2,map,pdf,js,webp,ttf,eot,webp,jfif --fc 404,400,405,500 >> gau.txt
cat gau.txt | grep -oP '(?<=^https:\/\/).*?(?=\/|\?|$)' | sort | uniq >> subdomains1.txt
cat gau.txt | grep -oP '(?<=^http:\/\/).*?(?=\/|\?|$)' | sort | uniq >> subdomains1.txt
cat gau.txt >> urls1.txt

### waybackurls
progalt && echo ""
#Pulls urls from wayback
echo "waybackurls"
cat InputHosts.txt | waybackurls >> waybackurls.txt
cat waybackurls.txt | grep -oP '(?<=^https:\/\/).*?(?=\/|\?|$)' | sort | uniq >> subdomains1.txt
cat waybackurls.txt | grep -oP '(?<=^http:\/\/).*?(?=\/|\?|$)' | sort | uniq >> subdomains1.txt
cat waybackurls.txt >> urls1.txt

### theHarvester
progalt && echo ""
echo "theHarvester"
filename=$(cat $domain)
for i in $filename; do 
	theHarvester -d $i -b all >> theHarvester.txt
	cat theHarvester.txt | sed -n '/Hosts found/,$p' | awk -F ":" '{print$1}' | tail -n +3 | sort | uniq >> subdomains1.txt
	cat theHarvester.txt | sed -n '/Hosts found/,$p' | tail -n +3 | sort | uniq >> hostinfo.txt
	cat theHarvester.txt | sed -n '/Emails found/,/\[\*\]/p' | tail -n +3 | head -n -2 | sort | uniq >> emails1.txt
	cat theHarvester.txt | sed -n '/Interesting Urls found/,/\[\*\]/p' | tail -n +3 | head -n -2 | sort | uniq >> urls1.txt
done

#=========================================
#=========ACTIVE ENUMERATION TOOLS========
#=========================================
if [[ "$*" == *"all"* ]]; then
	echo "Active Enum"
	#Permutation and wordlist generation
	#https://sidxparab.gitbook.io/subdomain-enumeration-guide/active-enumeration/permutation-alterations
	
	#brute force
	progalt && echo ""
	echo "This may take a while..."
	filename=$(cat InputHosts.txt)
	for i in $filename; do
		echo "Gobusting subdomains for $i"
		gobuster dns -q -d $i -w $subwordlist -o gobust.txt
		cat gobust.txt | awk -F ' ' '{print $2}' | sort | uniq >> subdomains1.txt && rm gobust.txt
	done

	## Check for subdomain hijack
	#go get github.com/haccer/subjack
	#~/go/bin/subjack -w $url/recon/final.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o $url/recon/potential_takeover/PT.txt
	# ================================================
fi


## Pull domains from certs

cat subdomains1.txt inscopeips.txt | sort | uniq | cero -d -c 1000 $ceroports  | grep -E "($scope)" > subdomains2.txt
sort subdomains1.txt subdomains2.txt | uniq > subdomains.txt && rm subdomains1.txt && rm subdomains2.txt

# Scope parsing
progalt && echo ""

## Check if domains are active

progalt && echo ""
if [[ "$mode" == *"all"* ]]; then
	echo "checking which subdomains are alive"
	cat ./subdomains.txt inscopeips.txt | httprobe $httprobeports > upcheck1.txt
	sort upcheck1.txt | grep -Eo "http://.*"  | cut -c 8- > http.txt
	sort upcheck1.txt | grep -Eo "https://.*"  | cut -c 9- > https.txt
	cat http.txt https.txt | sort | uniq > alivesubdomains1.txt
	sort upcheck1.txt  | uniq > toscreenshot.txt
else
	cp subdomains.txt alivesubdomains1.txt
fi

## Screenshot each domain

# Final sorting

cat urls1.txt | sort | uniq >> urls.txt
cat emails1.txt | sort | uniq >> emails.txt

#Resolve domain to IP and check if resolved IP is in scope
progalt && echo ""

#Resolve domains to IPs and highlighting ones that are inscope based on provided IPs
echo "Resolving IPs for found domains"

filename=$(cat alivesubdomains1.txt)
for i in $filename; do
	host $i >> resolve1.txt ||true
	cat resolve1.txt | uniq > resolve2.txt 
	cat resolve2.txt | grep -v mail | grep -v '3(NXDOMAIN)' >> resolve.txt ||true
	progalt && echo ""
	echo "Resolving hostnames"
	done

while read i;  do
	if echo $i | grep -q -E '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$' ; then
		ip=$(echo $i | grep address | awk -F ' ' '{print$NF}')
		newline=$(echo "$i " $(whois $ip | grep Organization))
		sed -i "s/.*$i.*/$newline/"  resolve.txt
	else
		progalt && echo ""
		echo "Determining owners of IPs. This may take a while..."
	fi
done <resolve.txt

#filename=$(cat resolve.txt)
#for i in $filename; do
while read i;  do
	if echo $i | grep -F -f inscopeips.txt; then
	    echo "<p><font style="color:purple"> $i </font> </p>" >> alivesubdomains.html ;
	    echo $i >> inscopeDomains1.txt ;
	else
 	    echo "<p> $i </p>" >> alivesubdomains.html ;
	fi
done <resolve.txt

cat resolve.txt | uniq > ResolveFinal.txt

cat inscopeDomains1.txt | awk -F ' ' '{print$1}' > inscopeDomains2.txt
cat inscopeDomains2.txt | sort | uniq > inscopeDomains.txt

#removing file types that really dont need screenshots
progalt && echo ""
if [[ "$mode" == *"all"* ]]; then
	echo "getting screenshots of subdomains"
	wget -q https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip -O aquatone.zip && mkdir tools && unzip -qq aquatone.zip -d tools/
	sort toscreenshot.txt | uniq | grep -v '.css\|.woff\|.js' > screenshots.txt
	cat screenshots.txt | tools/aquatone $aquatoneports -silent -out ./
else
	echo ""
fi

rm alivesubdomains1.txt InputHosts.txt resolve1.txt resolve2.txt urls1.txt

# Output
wget -q https://raw.githubusercontent.com/Kahvi-0/SubEnoom/main/results.html

if [[ "$mode" == *"all"* ]]; then
	firefox ./results.html ./aquatone_report.html > /dev/null &

else
	firefox ./results.html > /dev/null &
fi

progalt && echo ""
echo "Expecting more results?"
echo " "
echo "Add API keys to the following tools"
echo "- Assetfinder: https://github.com/tomnomnom/assetfinder"
echo "- theHarvester"
echo "- Amass"
