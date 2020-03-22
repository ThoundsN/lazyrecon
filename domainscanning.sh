#!/bin/bash


########################################
# ///                                        \\\
#  		You can edit your configuration here
#
#
########################################


massdnsWordlist=/root/Wordlist/subdomain/726w_subdomain.txt
ffuf_Wordlist=/root/Wordlist/endpoint/10w_common.txt





chromiumPath=/snap/bin/chromium
rootPath=/root/OneDrive/output/lazyrecon

########################################
# Happy Hunting
########################################






red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SECONDS=0


usage() { echo -e "Usage: $0 -d domain [-e]\n  Select -e to specify excluded domains\n " 1>&2; exit 1; }

while getopts ":d:f:r:" o; do
    case "${o}" in
        d)
            domain=${OPTARG}
            ;;

        f)
            file=${OPTARG}
            ;;

        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))


wayback(){

  waybackrecon
  waybackdowloader_oldjsfile
  checkjsfile

  cp -r $rootPath/$domain/$foldername/html/ /var/www/jsrecon/links/$domain/


  memento_mass -f $rootPath/$domain/$foldername/allsubdomains_final.txt  -o $rootPath/$domain/$foldername/wayback-data/robots_archieve.txt

  cp -r  $rootPath/$domain/$foldername/wayback-data/ /var/www/jsrecon/links/$domain/wayback-data/
  rm -rf $rootPath/$domain/$foldername/wayback-data/jsfile/

}

discovery(){

  if [ ! -d "/var/www/jsrecon/links/$domain/wayback-data/jsfile/" ]; then
  wayback
fi




  portscanning
  eyewitnesser


}


waybackdowloader_oldjsfile(){
  cd $rootPath/$domain/$foldername/wayback-data/
  while read p ; do 
      wayback_machine_downloader $p  --only "/\.js$/i"
  done < $rootPath/$domain/$foldername/allsubdomains_final.txt
  cd $rootPath/$domain/$foldername/wayback-data/websites/
  for fl_nm in $(find . -type f );
  do cp $fl_nm  $rootPath/$domain/$foldername/wayback-data/jsfile/$(echo $fl_nm | cut -c 3- |sed -e 's/[^A-Za-z0-9._-]/_/g'); 
done 

  rm -rf $rootPath/$domain/$foldername/wayback-data/websites/
}


find_firebase(){

  touch  $rootPath/$domain/$foldername/html/firebase_js_location.txt

  cd $rootPath/$domain/$foldername/wayback-data/jsfile/
    for fl_nm in $(find . -type f );
  do grep "firebaseio" $fl_nm > /dev/null &&  readlink -f $fl_nm >> $rootPath/$domain/$foldername/html/firebase_js_location.txt;
done 

if [ -s "$rootPath/$domain/$foldername/html/firebase_js_location.txt" ]
  then python3  ~/recon_tools/Scripts/python/location2link.py $rootPath/$domain/$foldername/html/firebase_js_location.txt $rootPath/$domain/$foldername/html/firebase_js_link.html
  else
  rm $rootPath/$domain/$foldername/html/firebase_js_location.txt
    return 
  fi

rm $rootPath/$domain/$foldername/html/firebase_js_location.txt
cd -- 

    echo "  http://jsrecon.ragnarokv.site/links/${domain}/html/firebase_js_link.html " | mutt -s "Found potential firebaseio url from  ${domain}"  inthebybyby@gmail.com   

}

checkjsfile(){
  wget2 -i $rootPath/$domain/$foldername/wayback-data/jsurls.txt -P $rootPath/$domain/$foldername/wayback-data/jsfile
  cd $rootPath/$domain/$foldername/wayback-data/jsfile
  fdupes . -r -f -1 -S -d -N 
  ls | while read file; do mv $file $(echo $file | sed -e 's/[^A-Za-z0-9._-]/_/g'); done
  DumpsterDiver.py -p . -o  $rootPath/$domain/$foldername/html/entropy.json
  python3 ~/recon_tools/Scripts/python/entropy_json.py $rootPath/$domain/$foldername/html/entropy.json $rootPath/$domain/$foldername/html/new.json

  echo "Fininshed high entropy scanning  in jsfile http://jsrecon.ragnarokv.site/links/${domain}/html/new.json " | mutt -s "Entropy string ${domain} "  inthebybyby@gmail.com

  find_firebase

  rm $rootPath/$domain/$foldername/wayback-data/jsfile/errors.log
  grep -oE ".{0,75}(application\/xml|encodeuricomponent|wsdl).{0,60}"  * > $rootPath/$domain/$foldername/html/pattern.txt


  python3  ~/recon_tools/LinkFinder/linkfinder.py -i './*'   -o $rootPath/$domain/$foldername/html/${domain}_js.html

  python3 /root/recon_tools/Scripts/python/extract_link.py $rootPath/$domain/$foldername/html/${domain}_js.html $rootPath/$domain/$foldername/html/${domain}_other.html $rootPath/$domain/$foldername/html/${domain}_api.html

  cd -


}

waybackrecon () {
echo "Scraping wayback for data..."
cat $rootPath/$domain/$foldername/allsubdomains_final.txt  | gau > $rootPath/$domain/$foldername/wayback-data/waybackurls.txt
cat $rootPath/$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | unfurl --unique keypairs > $rootPath/$domain/$foldername/wayback-data/paramlist.txt
[ -s $rootPath/$domain/$foldername/wayback-data/paramlist.txt ] && echo "Wordlist saved to /$domain/$foldername/wayback-data/paramlist.txt"






cat $rootPath/$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.js(\?|$)" | sort -u > $rootPath/$domain/$foldername/wayback-data/jsurls.txt
[ -s $rootPath/$domain/$foldername/wayback-data/jsurls.txt ] && echo "JS Urls saved to /$domain/$foldername/wayback-data/jsurls.txt"

cat $rootPath/$domain/$foldername/wayback-data/waybackurls.txt  |  unfurl --unique format "%s://%d%p" >  $rootPath/$domain/$foldername/wayback-data/paths.txt


cat $rootPath/$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.php(\?|$) "| sort -u > $rootPath/$domain/$foldername/wayback-data/phpurls.txt
[ -s $rootPath/$domain/$foldername/wayback-data/phpurls.txt ] && echo "PHP Urls saved to /$domain/$foldername/wayback-data/phpurls.txt"

cat $rootPath/$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.aspx(\?|$) "| sort -u  > $rootPath/$domain/$foldername/wayback-data/aspxurls.txt
[ -s $rootPath/$domain/$foldername/wayback-data/aspxurls.txt ] && echo "ASP Urls saved to /$domain/$foldername/wayback-data/aspxurls.txt"

cat $rootPath/$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.jsp(\?|$) "| sort -u  > $rootPath/$domain/$foldername/wayback-data/jspurls.txt
[ -s $rootPath/$domain/$foldername/wayback-data/jspurls.txt ] && echo "JSP Urls saved to /$domain/$foldername/wayback-data/jspurls.txt"

cat $rootPath/$domain/$foldername/wayback-data/paths.txt | sed -E -e '/(\.jpg|\.png|\.gif|\.woff|\.css|\.ico|\.js)$/d' | perl -p -e 's/(.*)/<br><a href="\1" target="_blank">\1<\/a><br>/'  >  $rootPath/$domain/$foldername/html/paths.html
  
grep 'admin\|proxy' $rootPath/$domain/$foldername/html/paths.html > $rootPath/$domain/$foldername/html/adminpath.html
}


hostalive(){
echo "Probing for live hosts..."
cat $file  | httprobe -c 50 -t 3000 > $rootPath/$domain/$foldername/responsive_urls.txt

cat $rootPath/$domain/$foldername/responsive_urls.txt |unfurl -unique domain > $rootPath/$domain/$foldername/responsiveDomains.txt


echo  "${yellow}Total of ${count} live subdomains were found${reset}"
}



recon(){

  hostalive

 
  cat $rootPath/$domain/$foldername/responsive_urls.txt  |unfurl -unique domain > $rootPath/$domain/$foldername/responsiveDomains_final.txt

  python3 /root/recon_tools/Scripts/python/urls_processing.py  $rootPath/$domain/$foldername/responsive_urls.txt  $rootPath/$domain/$foldername/ffuf_input.txt

  nsrecords $domain


}


eyewitnesser(){
  echo "Starting Eyewitness scan..."
  timeout 3h EyeWitness.py --web  --no-prompt  -f $rootPath/$domain/$foldername/responsive_urls.txt --timeout 30  -d $rootPath/$domain/$foldername/eyewitness
  cd $rootPath/$domain/$foldername/eyewitness/screens
  # fdupes . -r -f -1 -S -d
  cd -
	mv $rootPath/$domain/$foldername/eyewitness /var/www/jsrecon/links/$domain/

}





portscanning(){
  touch $rootPath/$domain/$foldername/domain_ip_tmp.txt
  while read line; do
     ip=$(dig +short $line @8.8.8.8| grep -m 1 -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
     if [[ -z $ip ]]; then
       continue
     fi
     echo "$line     $ip" >>$rootPath/$domain/$foldername/domain_ip_tmp.txt
  done <  $file

  cat $rootPath/$domain/$foldername/domain_ip_tmp.txt | awk '!seen[$2]++' > $rootPath/$domain/$foldername/domain_ip.txt

  rm $rootPath/$domain/$foldername/domain_ip_tmp.txt


  awk '{print $2}' $rootPath/$domain/$foldername/domain_ip.txt | awk '!seen[$0]++' > $rootPath/$domain/$foldername/only_ip.txt

 timeout 3h ipport_mass -f  $rootPath/$domain/$foldername/only_ip.txt -o $rootPath/$domain/$foldername/portscanning

cp $rootPath/$domain/$foldername/portscanning/ip_services.txt /var/www/jsrecon/links/$domain/
}

massdns_second_check(){
  cat $rootPath/$domain/$foldername/raw_subdomains.txt | massdns -r /root/Wordlist/resolver.txt -t A -q -o S -w  $rootPath/$domain/$foldername/useless/massdns_temp.txt

}



nsrecords(){

                echo "${green}Started dns records check...${reset}"
                echo "Looking into CNAME Records..."





                cat $rootPath/$domain/$foldername/useless/massdns_temp.txt | grep CNAME >> $rootPath/$domain/$foldername/cnames.txt
                cat $rootPath/$domain/$foldername/useless/dnsgen_mass.txt | grep CNAME >> $rootPath/$domain/$foldername/cnames.txt


                cat $rootPath/$domain/$foldername/cnames.txt | sort -u | while read line; do
                hostrec=$(echo "$line" | awk '{print $1}')
                if [[ $(host $hostrec | grep NXDOMAIN) != "" ]]
                then
                echo "${red}Check the following domain for NS takeover:  $line ${reset}"
                echo "$line" >> $rootPath/$domain/$foldername/pos.txt
                else
                echo -ne "working on it...\r"
                fi
                done
                sleep 1

        }



logo(){
  #can't have a bash script without a cool logo :D
  echo "${red}
 _     ____  ____ ___  _ ____  _____ ____  ____  _
/ \   /  _ \/_   \\\  \///  __\/  __//   _\/  _ \/ \  /|
| |   | / \| /   / \  / |  \/||  \  |  /  | / \|| |\ ||
| |_/\| |-||/   /_ / /  |    /|  /_ |  \__| \_/|| | \||
\____/\_/ \|\____//_/   \_/\_\\\____\\\____/\____/\_/  \\|
${reset}                                                      "
}


main(){
  logo


  mkdir -p $rootPath/$domain
  mkdir -p $rootPath/$domain/$foldername
  mkdir -p $rootPath/$domain/$foldername/wayback-data/
  mkdir -p $rootPath/$domain/$foldername/eyewitness
  mkdir -p $rootPath/$domain/$foldername/useless
  mkdir -p $rootPath/$domain/$foldername/html
  mkdir -p /var/www/jsrecon/links/$domain
  mkdir -p /var/www/jsrecon/links/$domain/urls

  mkdir -p $rootPath/$domain/$foldername/wayback-data/jsfile

  touch $rootPath/$domain/$foldername/useless/mass.txt
  touch $rootPath/$domain/$foldername/cnames.txt
  touch $rootPath/$domain/$foldername/pos.txt
  touch $rootPath/$domain/$foldername/raw_subdomains.txt
  touch $rootPath/$domain/$foldername/useless/massdns_temp.txt
  touch $rootPath/$domain/$foldername/domaintemp.txt
  touch $rootPath/$domain/$foldername/useless/cleantemp.txt
  touch $rootPath/$domain/$foldername/allsubdomains_final.txt

  recon

  echo "Starting discovery..."
  discovery

  mkdir -p $rootPath/$domain/$foldername/ffuf/

  ffuf_mass -f $rootPath/$domain/$foldername/ffuf_input.txt -o $rootPath/$domain/$foldername/ffuf/
  cp $rootPath/$domain/$foldername/ffuf/ffuf_output.html /var/www/jsrecon/links/$domain/ffuf_output.html
  echo "Fininshed ffuf scanning  http://jsrecon.ragnarokv.site/links/${domain}/ffuf_output.html " | mutt -s "FFUF_full ${domain} "  inthebybyby@gmail.com


  # -a $rootPath/$domain/$foldername/ffuf/ffuf_output.html




  echo "${green}Scan for $domain finished successfully${reset}"
  duration=$SECONDS
  echo "Scan completed in : $(($duration / 60)) minutes and $(($duration % 60)) seconds."
  stty sane
  tput sgr0
}

todate=$(date +'%Y-%m-%d-%H-%M')
path=$(pwd)
foldername=recon-$todate

export rootPath
export domain
export foldername


main $domain
