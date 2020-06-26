#!/bin/bash

ffuf_Wordlist=/root/Wordlist/endpoint/10w_common.txt
rootPath=/var/www/jsrecon/rscan


usage() { echo -e "Usage: $0 -d domain [-e]\n  Select -e to specify excluded domains\n " 1>&2; exit 1; }

while getopts ":d:e:r:" o; do
    case "${o}" in
        d)
            domain=${OPTARG}
            ;;

            #### working on subdomain exclusion
        e)
            excluded=${OPTARG}
            ;;

        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))


waybackrecon() {
echo "Scraping wayback for data..."
printf $domain  | gau -subs -providers  wayback | awk '!seen[$0]++'> $rootPath/$domain/wayback-data/wayback.txt
printf $domain  | gau -subs -providers  commoncrawl | awk '!seen[$0]++' > $rootPath/$domain/wayback-data/commoncrawl.txt
touch $rootPath/$domain/wayback-data/temp.txt
cat $rootPath/$domain/wayback-data/commoncrawl.txt >> $rootPath/$domain/wayback-data/temp.txt
cat $rootPath/$domain/wayback-data/wayback.txt >> $rootPath/$domain/wayback-data/temp.txt
cat $rootPath/$domain/wayback-data/temp.txt | awk '!seen[$0]++'>  $rootPath/$domain/wayback-data/gau.txt

rm $rootPath/$domain/wayback-data/temp.txt $rootPath/$domain/wayback-data/commoncrawl.txt $rootPath/$domain/wayback-data/wayback.txt

cat $rootPath/$domain/wayback-data/gau.txt  | sort -u | grep -P "\w+\.js(\?|$)" | sort -u > $rootPath/$domain/wayback-data/jsurls.txt
[ -s $rootPath/$domain/wayback-data/jsurls.txt ] && echo "JS Urls saved to /$domain/wayback-data/jsurls.txt"

cat $rootPath/$domain/wayback-data/gau.txt  |  unfurl -u paths >  $rootPath/$domain/wayback-data/paths.txt

rscan.sh -f $rootPath/$domain/wayback-data/gau.txt -o $rootPath/$domain/wayback-data/

}


waybackdowloader_oldjsfile(){
  cd $rootPath/$domain/wayback-data/
  while read p ; do 
      wayback_machine_downloader $p  --only "/\.js$/i" > /dev/null
  done < $rootPath/$domain/responsiveDomains.txt
  cd $rootPath/$domain/wayback-data/websites/
  for fl_nm in $(find . -type f );
  do cp $fl_nm  $rootPath/$domain/wayback-data/jsfile/$(echo $fl_nm | cut -c 3- |sed -e 's/[^A-Za-z0-9._-]/_/g'); 
done 

  rm -rf $rootPath/$domain/wayback-data/websites/
}


find_firebase(){

  touch  $rootPath/$domain/useful/firebase_js_location.txt

  cd $rootPath/$domain/wayback-data/jsfile/
    for fl_nm in $(find . -type f );
  do grep "firebaseio" $fl_nm > /dev/null &&  readlink -f $fl_nm >> $rootPath/$domain/useful/firebase_js_location.txt;
done 

if [ -s "$rootPath/$domain/useful/firebase_js_location.txt" ]
  then python3  ~/recon_tools/Scripts/python/location2link.py $rootPath/$domain/useful/firebase_js_location.txt $rootPath/$domain/useful/firebase_js_link.html
  else
  rm $rootPath/$domain/useful/firebase_js_location.txt
    return 
  fi

cd -- 

    echo "  http://jsrecon.ragnarokv.site/links/${domain}/useful/firebase_js_link.html " | mutt -s "Found potential firebaseio url from  ${domain}"  inthebybyby@gmail.com   

}

checkjsfile(){
  cd $rootPath/$domain/wayback-data/jsfile
  echo "Downloading js files using aria2c.............."
  aria2c -i $rootPath/$domain/wayback-data/jsurls.txt > /dev/null
  # wget2 -i $rootPath/$domain/wayback-data/jsurls.txt -P $rootPath/$domain/wayback-data/jsfile
  fdupes . -r -f -1 -S -d -N 
  ls | while read file; do mv $file $(echo $file | sed -e 's/[^A-Za-z0-9._-]/_/g'); done
  DumpsterDiver.py -p . -o  $rootPath/$domain/useful/entropy.json > /dev/null
  python3 ~/recon_tools/Scripts/python/entropy_json.py $rootPath/$domain/useful/entropy.json $rootPath/$domain/useful/new.json

  rm $rootPath/$domain/wayback-data/jsfile/errors.log




  printf "\n\n\n\n Things from gf \n\n\n" >> $rootPath/$domain/useful/pattern.txt
  gf http-auth  >> $rootPath/$domain/useful/pattern.txt
  gf fw  >> $rootPath/$domain/useful/pattern.txt
  gf firebase  >> $rootPath/$domain/useful/pattern.txt
  gf s3-buckets  >> $rootPath/$domain/useful/pattern.txt
  gf servers  >> $rootPath/$domain/useful/pattern.txt
  gf sec  >> $rootPath/$domain/useful/pattern.txt
  gf aws-keys  >> $rootPath/$domain/useful/pattern.txt
  


}


using_blc(){
  touch $rootPath/$domain/useful/blc.txt
  echo "Using blc "

  while read p ; do 
    timeout 5m blc  $p -rfoi --exclude youtube.com  --flter--level 3 >> $rootPath/$domain/useful/blc.txt
  done < $rootPath/$domain/responsive_urls.txt

  chmod +r $rootPath/$domain/useful/blc.txt


}

hostalive(){
echo "Probing for live hosts..."
cat $rootPath/$domain/raw_subdomains.txt  | httprobe -c 50 -t 3000 > $rootPath/$domain/responsive_urls.txt

cat $rootPath/$domain/responsive_urls.txt |unfurl -unique domain > $rootPath/$domain/responsiveDomains.txt

run_subscraper

count=$(wc -l $rootPath/$domain/responsiveDomains.txt | awk '{print $1}')

if [[ $count = 0 ]]; then
  exit 1
fi

echo  "${yellow}Total of ${count} live subdomains were found${reset}"
}

find_subs(){
      echo "${green}Recon started on $domain ${reset}"
  echo "Listing subdomains using assertfinder..."

  findomain -r -t $domain -u $rootPath/$domain/raw_subdomains.txt  

  assetfinder --subs-only $domain >> $rootPath/$domain/raw_subdomains.txt

   if [[ $wildcard_boolean !=  1 ]]; then
   #statements
       /root/recon_tools/massdns/scripts/subbrute.py $massdnsWordlist $domain | massdns -r /root/Wordlist/resolver.txt -t A -q -o S > $rootPath/$domain/useless/mass.txt



fi

awk '!seen[$3]++' $rootPath/$domain/useless/mass.txt > /tmp/masstmp
mv /tmp/masstmp $rootPath/$domain/useless/mass.txt

awk '{print $1}' $rootPath/$domain/useless/mass.txt | sed 's/\.$//' > $rootPath/$domain/massdns_subdomains.txt

rm_dup_file $rootPath/$domain/massdns_subdomains.txt

cat $rootPath/$domain/massdns_subdomains.txt >> $rootPath/$domain/raw_subdomains.txt
}


run_subscraper(){
     touch $rootPath/$domain/useless/subscraper.txt
     cat $rootPath/$domain/responsiveDomains.txt| parallel subscraper.py -u {} -o $rootPath/$domain/useless/subscraper.txt
     cat $rootPath/$domain/useless/subscraper.txt |  awk '!seen[$0]++' > $rootPath/$domain/useless/unique_subscraper.txt
     cat $rootPath/$domain/useless/unique_subscraper.txt |  httprobe -c 50 -t 3000 > $rootPath/$domain/responsive_unique_subscraper_urls.txt
     cat $rootPath/$domain/responsive_urls.txt >> $rootPath/$domain/responsive_unique_subscraper_urls.txt
     cat $rootPath/$domain/responsive_unique_subscraper_urls.txt |  awk '!seen[$0]++' > $rootPath/$domain/responsive_urls.txt 
}

nsrecords_subjack(){

                echo "${green}Started dns records check...${reset}"
                echo "Looking into CNAME Records..."


                touch $rootPath/$domain/useful/pos.txt


                cat $rootPath/$domain/useless/mass.txt | egrep 'CNAME|wp' > $rootPath/$domain/useful/cnames.txt
                # cat $rootPath/$domain/useless/dnsgen_mass.txt | grep 'CNAME|wp' >> $rootPath/$domain/cnames.txt


                cat $rootPath/$domain/cnames.txt | sort -u | while read line; do
                hostrec=$(echo "$line" | awk '{print $1}')
                if [[ $(host $hostrec | grep NXDOMAIN) != "" ]]
                then
                echo "${red}Check the following domain for NS takeover:  $line ${reset}"
                echo "$line" >> $rootPath/$domain/useful/pos.txt
                else
                echo -ne "working on it...\r"
                fi
                done
                sleep 1

                subjack -c ~/go/src/github.com/haccer/subjack/fingerprints.json  -w $rootPath/$domain/allsubdomains_final.txt  -t 10 -timeout 15 -o $rootPath/$domain/useful/subjack.txt -ssl -a -m

                chmod +r $rootPath/$domain/useful/subjack.txt


        }


ffuf_403(){
  cd $rootPath/$domain/
  mkdir $rootPath/$domain/ffuf_403
  ffuf_403_process.py -i "ffuf/processed/*" "ffuf_paths/processed/*" -o $rootPath/$domain/ffuf_403
  cp $rootPath/$domain/ffuf_403/ffuf_403.html $rootPath/$domain/ffuf_403/originalurl.html $rootPath/$domain/ffuf_403/rewriteurls.html $rootPath/$domain/useful

}

run_ffuf(){
  ffuf_mass -f $rootPath/$domain/responsive_urls.txt  -q -o $rootPath/$domain/ffuf/ -w /root/Wordlist/endpoint/10w_common.txt
  ffuf_mass -f $rootPath/$domain/responsive_urls.txt  -o $rootPath/$domain/ffuf_paths/ -w $rootPath/$domain/wayback-data/paths.txt
  cp $rootPath/$domain/ffuf/ffuf_output.html $rootPath/$domain/useful/ffuf_output.html
  cp $rootPath/$domain/ffuf_paths/ffuf_output.html $rootPath/$domain/useful/ffuf_paths_output.html   
}


if [  -d "/var/www/jsrecon/rscan/$domain" ]; then
# Control will enter here if $DIRECTORY  exist.
    exit 0
fi

export rootPath
export domain

mkdir -p $rootPath/$domain
mkdir -p $rootPath/$domain/useful
mkdir -p $rootPath/$domain/wayback-data/
mkdir -p $rootPath/$domain/useless
mkdir -p $rootPath/$domain/ffuf/
mkdir -p $rootPath/$domain/ffuf_paths/



  find_subs
  hostalive
  run_subscraper
  run_cloud_enum
  using_blc
   nsrecords_subjack $domain

waybackrecon
waybackdowloader_oldjsfile
checkjsfile
find_firebase
run_ffuf
ffuf_403

echo $domain >> /root/Wordlist/domains_monitoring.txt


