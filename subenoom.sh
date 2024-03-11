#!/bin/bash

WHITE="\e[97m"
BLUE="\e[34m"
PURPLE="\e[35m"
GREY="\e[37m"
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
ENDCOLOUR="\e[0m"

#Configs:
amassConfig=~/.config/amass/config.ini

help_screen() {
	figlet HELP SCREEN
	printf "./SubEnum.sh -d <domain list file> -o <output dirname>\n"
}

loadscreen() {

    if [[ "$call" == 1 ]]; then
        clear -x
    	stats
    	echo "Still trying to use $currentTool against $i ヾ(･ω･*)ﾉ"
    	echo " "
    	echo " "
    	echo "      )  ("
	echo "     (   ) )"
	echo "      ) ( ("
	echo "    _______)_"
	echo " .-'---------|"
	echo "( C|/\/\/\/\/|"
	echo " '-./\/\/\/\/|"
	echo "   '_________'"
	echo "    '-------'"
    	call=2
    else
        clear -x
    	stats
    	echo "Still trying to use $currentTool against $i (＾-＾)旦 "
    	echo " "
    	echo " "
    	echo "      (   ) ("
	echo "       ) (  )"
	echo "    (         "
	echo "    _)____(__"
	echo " .-'---------|"
	echo "( C|/\/\/\/\/|"
	echo " '-./\/\/\/\/|"
	echo "   '_________'"
	echo "    '-------'"
    	call=1
    fi
}

call=1

# Want to show more info about the current scan being done, look less like hanging
stats() {
	echo " ---------------------------------------------"
	echo "| Output Directory: $(pwd)"
	echo "| Current Tool: $currentTool"
	echo "| Last updated: $(date)" 
	echo " ----------------------------------------------"
	echo " "
}

while getopts ":d:o:h:" option; do
	case "${option}" in
		d) # List of domains and IPs
			domain=$(pwd)/${OPTARG};;
		o) # Output dir
			dir=${OPTARG};;
		h) # Display Help
			help_screen
			exit 1;;
		\?) # Invalid option
			echo "Error: Invalid option"
			exit 1;;
	esac
done

# Check for mandatory args
if [ -z "$domain" ] || [ -z "$dir" ]; then
    help_screen
    exit 1
fi

# Add section for target ports if wanted

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

#finish section for making and moving to dir

#convert subnets to IP list and create an expanded list of inscope IPs and domains

file=$(cat $domain)
for i in $file; do
	#check if line is an IP address
	if echo $i | grep -q -E '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' ; then
		echo ""
	else
		host $i | grep -oE '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' >> inscopeips.txt
		echo $i >> InputHosts.txt
	fi
	done


figlet Sub e Noom
echo -e "${WHITE}[+]${BLUE} SubeNoom v2.0 ${WHITE}[+]${ENDCOLOR}"
echo " "
echo -e "${WHITE}[+]${PURPLE}The following are the domains and IP addresses that will be ran through OSINT tools ${WHITE}[+]${ENDCOLOR}"
echo -e "${WHITE}[+]${RED}The resolved IP address(es) for provided domains were included${WHITE}[+]${ENDCOLOR}"

cat inscopeips.txt
cat $domain

echo "Please confirm these settings are accurate"
echo "Press Any Key"
read

# Sort provided domains and IPs
cat $domain | grep -E '^[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$' >> inscopeips.txt

## Convert subnets to single IP addresses
cat $domain | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$' >> expandedsubnets.txt
cat $domain | grep -E '^[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\-' >> expandedsubnets.txt
nmap -sL -iL ./expandedsubnets.txt -n 2>/dev/null | grep -oE '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' | sort | uniq >> inscopeips.txt && rm expandedsubnets.txt
cat inscopeips.txt InputHosts.txt | uniq >> ExpandedScope.txt
domain=ExpandedScope.txt

# For the rest of the script:
# inscopeips.txt = full list of provided IPs with expanded subnets
# InputHosts.txt = domains provided 
# ExpandedScope = All IPs and Domains provided

#==========================================
#========= ENUMERATION TOOLS ==============
#==========================================

# Reverse Lookup
currentTool=ReverseLookup
file=$(cat inscopeips.txt)
for i in $file; do
	echo $i | dnsx -ptr -resp-only --silent >> ReverseIP.txt
	done

# AMASS
## Only using list of input hosts
file=$(cat InputHosts.txt)
currentTool=Amass
for i in $file; do
	loadscreen
	# Amass active + normal. -nf points the "already known subdomain names" to the provided file as to not ignore domains in the local DB
	echo "Start" > amass.txt
	amass enum  -d $i -active -log amass.log -config $amassConfig -nf InputHosts.txt -p 80,443,8080 >> amass.txt
	# Carve out the useful ASN info
	echo $i >> ASN.txt
	sed -n '/OWASP Amass/,/The enumeration/{//!p}' amass.txt >> ASN.txt
	# Carve out domains 
	sed -n '/Start/,/OWASP/{//!p}' amass.txt >> scan-subdomains.txt
done

# crt.sh
currentTool=crt.sh
file=$(cat InputHosts.txt)
for i in $file; do
	loadscreen
	curl https://crt.sh/?q=$i 2>/dev/null | grep "<TD>" | grep -v -e "style=" | sed 's/<TD>//g; s/<\/TD>//g; s/<BR>/\n/g' | tr -d ' ' | sort -u >> scan-subdomains.txt
done

# Assetfinder
## Only using list of input hosts
file=$(cat InputHosts.txt)
currentTool=Assetfinder
for i in $file; do
	loadscreen
	echo $i | assetfinder --subs-only >> scan-subdomains.txt
done

# Gau
currentTool=Gau
file=$(cat InputHosts.txt)
for i in $file; do
	loadscreen
	echo $i | gau --subs --blacklist png,jpg,jpeg,gif,css,svg,woff,woff2,map,pdf,js,webp,ttf,eot,webp,jfif --fc 404,400,405,500 >> scan-urls.txt	
done
	
cat gau.txt | grep -oP '(?<=^https:\/\/).*?(?=\/|\?|$)' | sort -u >> scan-subdomains.txt
cat gau.txt | grep -oP '(?<=^http:\/\/).*?(?=\/|\?|$)' | sort -u >> scan-subdomains.txt

# Waybackurls
currentTool=Waybackurls
file=$(cat InputHosts.txt)
for i in $file; do
	loadscreen
	echo $i | waybackurls >> waybackurls.txt
done

cat waybackurls.txt | grep -oP '(?<=^https:\/\/).*?(?=\/|\?|$)' | sort -u >> scan-subdomains.txt
cat waybackurls.txt | grep -oP '(?<=^http:\/\/).*?(?=\/|\?|$)' | sort -u >> scan-subdomains.txt

# theHarvester
currentTool=theHarvester
filename=$(cat InputHosts.txt)
for i in $filename; do 
	loadscreen
	theHarvester -d $i -b all > theHarvester.txt
	cat theHarvester.txt >> theHarvester.log
	cat theHarvester.txt | sed -n '/\[\*\] Hosts found/,$p' | awk -F ":" '{print$1}' | tail -n +3 | sort -u >> scan-subdomains.txt
	cat theHarvester.txt | sed -n '/\[\*\] Hosts found/,$p' | tail -n +3 | sort -u >> hostinfo.txt
	cat theHarvester.txt | sed -n '/\[\*\] Emails found/,/\[\*\]/p' | tail -n +3 | head -n -2 | sort -u >> scan-emails.txt
	cat theHarvester.txt | sed -n '/\[\*\] Interesting Urls found/,/\[\*\]/p' | tail -n +3 | head -n -2 | sort -u >> scan-urls.txt
done

#Subfinder
currentTool=Subfinder
subfinder -up
filename=$(cat InputHosts.txt)
for i in $filename; do 
	loadscreen
	subfinder -d $i -silent -all | sort -u >> scan-subdomains.txt
done

# Brute Force with gobuster
currentTool=gobuster
wget https://raw.githubusercontent.com/Kahvi-0/SubEnoom/main/sublist.txt
filename=$(cat InputHosts.txt)
for i in $filename; do
	loadscreen
	echo "Gobusting subdomains for $i"
	gobuster dns -q -d $i -w sublist.txt -o gobust.txt
	cat gobust.txt | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | awk -F ' ' '{print $2}' | sort | uniq >> scan-subdomains.txt && rm gobust.txt
done


#==========================================
#========= FINAL SORTING ==================
#==========================================
currentTool=Sorting
loadscreen
sort -u scan-subdomains.txt| grep -v "No names were discovered" > subdomains.txt && rm subdomains1.txt && rm scan-subdomains2.txt
cat scan-urls.txt | sort -u >> urls.txt
cat scan-emails.txt | sort -u >> emails.txt


#===================================================================
#========= Checking SCOPE AND ALIVE HOSTS SORTING ==================
#===================================================================
currentTool=httprobe
httprobeports=""
i="found domains and inscope IPs"
loadscreen 
echo "Checking which subdomains are alive"
cat subdomains.txt inscopeips.txt | sort | uniq > alivesubdomains1.txt


#=========================================================
#========= RESOLVING IPs AND IF IN SCOPE =========
#=========================================================

currentTool=HOST
filename=$(cat alivesubdomains1.txt)
for i in $filename; do
	loadscreen
	if echo $i| grep -E 'amazonaws.com|office.com|microsoft.com|cloudflare.com|herokudns.com|cloudfront.net|akamai.net|akamaiedge.net' ; then
		:
	else
		host $i >> resolve1.txt ||true
	fi
done

cat resolve1.txt | sort -u > resolve2.txt 
cat resolve2.txt | grep -vE 'amazonaws.com|office.com|microsoft.com|cloudflare.com|herokudns.com|cloudfront.net|akamai.net|akamaiedge.net' | grep -v mail | grep -v '3(NXDOMAIN)' >> resolve.txt ||true
currentTool=whois
while read i;  do
	loadscreen
	if echo $i | grep -q -E '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$' ; then
		ip=$(echo $i | grep address | awk -F ' ' '{print$NF}')
		echo "$i :" $(whois $ip | sed -n 's/Organization://p' | sed  -e 's/://g') >> resolve3.txt
	else
		:
	fi
done <resolve.txt

while read i;  do
	loadscreen
	if echo $i | grep -F -f inscopeips.txt; then
	    sed -i "1s/^/<p><font style='color:purple'> $i <\/font> <\/p>\n /" alivesubdomains1.html ;
	    echo $i >> inscopeDomains1.txt ;
	else
 	    echo "<p> $i </p>" >> alivesubdomains1.html ;
	fi
done <resolve.txt

# maybe sort by purple for all inscope at top

cat inscopeDomains1.txt | awk -F ' ' '{print$1}' | sort -u > cero.txt



#cero here so it can use a list of domains found to be inscope based on provided IP
# cero
currentTool=cero
ceroports=""
i="found domains and inscope IPs"
loadscreen
cat cero.txt inscopeips.txt | sort -u | cero -d -c 1000 $ceroports > cero-out1.txt
cat cero-out1.txt | sort -u > cero-out.txt
#------
# going over inscope check again after cero

currentTool=HOST-cero
filename=$(cat cero-out.txt)
for i in $filename; do
	loadscreen
	if echo $i| grep -E 'amazonaws.com|office.com|microsoft.com|cloudflare.com|herokudns.com|cloudfront.net|akamai.net|akamaiedge.net' ; then
		:
	else
		host $i >> cero1.txt ||true
	fi
done
cat cero1.txt | sort -u > cero2.txt 
cat cero2.txt | grep -vE 'amazonaws.com|office.com|microsoft.com|cloudflare.com|herokudns.com|cloudfront.net|akamai.net|akamaiedge.net|awsglobalaccelerator.com' | grep -v mail | grep -v '3(NXDOMAIN)' >> ceroresolve.txt ||true
currentTool=whois-cero
while read i;  do
	loadscreen
	if echo $i | grep -q -E '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$' ; then
		ip=$(echo $i | grep address | awk -F ' ' '{print$NF}')
		echo "$i :" $(whois $ip | sed -n 's/Organization://p' | sed  -e 's/://g') >> resolve3.txt
	else
		:
	fi
done <ceroresolve.txt

while read i;  do
	loadscreen
	if echo $i | grep -F -f inscopeips.txt; then
	    sed -i "1s/^/<p><font style='color:purple'> $i <\/font> <\/p>\n /" alivesubdomains1.html ;
	    echo $i >> inscopeDomains1.txt ;
	else
 	    echo "<p> $i </p>" >> alivesubdomains1.html ;
	fi
done <ceroresolve.txt


#------
cat alivesubdomains1.html | uniq > alivesubdomains.html
cat resolve3.txt | grep "has address"| sed 's/has address/:/g' | sort -u >> ResolveFinal.txt
cat resolve.txt | grep "is an alias for"|  sort -u > Alias.txt
cat inscopeDomains1.txt | grep "has address"| sed 's/has address/:/g' | sort -u > inscopeDomains.txt

#==========================================
#========= FILE CLEANUP ===================
#==========================================
currentTool=Filecleanup
loadscreen
rm alivesubdomains1.txt InputHosts.txt resolve.txt resolve1.txt resolve2.txt scan-urls.txt scan-emails.txt

#==========================================
#========= Output =========================
#==========================================

wget -q https://raw.githubusercontent.com/Kahvi-0/SubEnoom/main/results.html
firefox ./results.html > /dev/null &

echo " "
figlet output
echo "Full list of alive inscope domains found with resolved IPs $dir/inscopeDomains.txt"
echo " "
echo "Full list of domains found with resolved IPs $dir/ResolveFinal.txt"
echo " "
echo "Full list of domains found $dir/subdomains.txt. This can be reran with the tool to possibly find more domains"
echo " "
echo "All files can be found in the output directory $dir"
echo " "
echo "Expecting more results?"
echo " "
echo "Add API keys to the following tools"
echo "- Assetfinder: https://github.com/tomnomnom/assetfinder"
echo "- theHarvester"
echo "- Amass"
