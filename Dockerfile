FROM kalilinux/kali-rolling
WORKDIR /app
COPY . .
RUN apt-get update -qq -y && apt-get upgrade -qq -y 
RUN apt purge theharvester
RUN apt-get -f install -qq  curl wget gnupg git gobuster golang theharvester host -y
RUN bash ./setup.sh
RUN chmod +x ./subenoom.sh
RUN mkdir wordlists
RUN curl https://github.com/owasp-amass/amass/blob/master/examples/wordlists/deepmagic.com_top500prefixes.txt -o wordlists/deepmagic.com_top500prefixes.txt
RUN curl https://github.com/owasp-amass/amass/blob/master/examples/wordlists/deepmagic.com_top50kprefixes.txt -o wordlists/deepmagic.com_top50kprefixes.txt
RUN curl https://github.com/owasp-amass/amass/blob/master/examples/wordlists/subdomains-top1mil-5000.txt -o wordlists/subdomains-top1mil-5000.txt
ENTRYPOINT ["/bin/bash"]
CMD ["./subenoom.sh", "$@", "$@"]
