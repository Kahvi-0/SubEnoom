#Installs

apt-get  -qq  install golang-go gobuster theharvester figlet

# THe harvester reqs
pip3 install ujson
pip3 install aiomultiprocess
pip3 install aiohttp
pip3 install censys
pip3 install aiodns
pip3 install aiosqlite
pip3 install pyppeteer
pip3 install uvloop

#
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/httprobe@latest
go install github.com/glebarez/cero@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/owasp-amass/amass/v4/...@master
go install github.com/hakluke/hakrevdns@latest

