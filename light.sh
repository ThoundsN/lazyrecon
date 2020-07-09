#!/bin/bash

ffuf_Wordlist=/root/Wordlist/endpoint/10w_common.txt
rootPath=/var/www/jsrecon/rscan
massdnsWordlist=/root/Wordlist/subdomain/726w_subdomain.txt



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





cat $rootPath/$domain/wayback-data/gau.txt  | sort -u | grep -P "\w+\.js(\?|$)" | sort -u > $rootPath/$domain/wayback-data/jsurls_temp.txt
cat $rootPath/$domain/wayback-data/jsurls_temp.txt  | urldedupe > $rootPath/$domain/wayback-data/jsurls.txt
[ -s $rootPath/$domain/wayback-data/jsurls.txt ] && echo "JS Urls saved to $rootPath/$domain/wayback-data/jsurls.txt"
rm $rootPath/$domain/wayback-data/jsurls_temp.txt


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

  # rm -rf $rootPath/$domain/wayback-data/websites/
}


find_firebase(){
echo "Searching for firebase...."
  touch  $rootPath/$domain/useful/firebase_js_location.txt

  cd $rootPath/$domain/wayback-data/jsfile/
    for fl_nm in $(find . -type f );
  do grep "firebaseio" $fl_nm > /dev/null &&  readlink -f $fl_nm >> $rootPath/$domain/useful/firebase_js_location.txt;
done 

if [ -s "$rootPath/$domain/useful/firebase_js_location.txt" ]
  then python3  ~/recon_tools/Scripts/python/location2link.py $rootPath/$domain/useful/firebase_js_location.txt $rootPath/$domain/useful/firebase_js_link.html
  fi

cd -- 


}

checkjsfile(){
  mkdir -p $rootPath/$domain/wayback-data/jsfile
  cd $rootPath/$domain/wayback-data/jsfile
  echo "Downloading js files using aria2c.............."
  aria2c -i $rootPath/$domain/wayback-data/jsurls.txt 
  # wget2 -i $rootPath/$domain/wayback-data/jsurls.txt -P $rootPath/$domain/wayback-data/jsfile
  fdupes . -r -f -1 -S -d -N 
  ls | while read file; do mv $file $(echo $file | sed -e 's/[^A-Za-z0-9._-]/_/g'); done
  gf urls > $rootPath/$domain/useful/endpoints_injs.txt
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
cat $rootPath/$domain/allsubdomains_final.txt  | httprobe -c 50 -t 3000 > $rootPath/$domain/responsive_urls.txt

cat $rootPath/$domain/responsive_urls.txt |unfurl -unique domain > $rootPath/$domain/responsiveDomains.txt


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


cat $rootPath/$domain/massdns_subdomains.txt >> $rootPath/$domain/raw_subdomains.txt

rm_dup_file $rootPath/$domain/raw_subdomains.txt

grep $domain  $rootPath/$domain/raw_subdomains.txt | sed 's/*\.//' >> $rootPath/$domain/allsubdomains_final.txt
}


run_subscraper(){
     touch $rootPath/$domain/useless/subscraper.txt
     timeout 2h  sh -c "cat $rootPath/$domain/responsiveDomains.txt|  parallel subscraper.py -u {} -o $rootPath/$domain/useless/subscraper.txt > /dev/null"
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

run_cloud_enum(){
brand=$(echo $domain |cut -d '.' -f 1 )
cloud_enum.py -k $domain -k $brand  -t 20 -l $rootPath/$domain/useful/cloud_enum.txt

}



export rootPath
export domain
export -f run_subscraper

mkdir -p $rootPath/$domain
mkdir -p $rootPath/$domain/useful
mkdir -p $rootPath/$domain/wayback-data/
mkdir -p $rootPath/$domain/useless
mkdir -p $rootPath/$domain/ffuf/
mkdir -p $rootPath/$domain/ffuf_paths/
mkdir -p $rootPath/$domain/wayback-data/jsfile


touch $rootPath/$domain/useless/mass.txt
touch $rootPath/$domain/cnames.txt
touch $rootPath/$domain/pos.txt
touch $rootPath/$domain/raw_subdomains.txt
touch $rootPath/$domain/useless/massdns_temp.txt
touch $rootPath/$domain/useless/cleantemp.txt
touch $rootPath/$domain/allsubdomains_final.txt





  find_subs
  hostalive
  run_subscraper
  run_cloud_enum
  # using_blc

   nsrecords_subjack $domain
  # cat $rootPath/$domain/$foldername/responsive_urls.txt | smuggler.py -l $rootPath/$domain/useful/smuggler.txt


waybackrecon
waybackdowloader_oldjsfile
checkjsfile
find_firebase
run_ffuf
ffuf_403

gitround-runer.py -i $rootPath/$domain/allsubdomains_final.txt -n 10 -o $rootPath/$domain/useful/gitrounds.txt


for filename in $rootPath/$domain/wayback-data/ouput/*; do
  if [ -s "$filename" ]
  then 
    cp $filename  $rootPath/$domain/useful
fi
done

todate=$(date +'%Y-%m-%d-%H-%M')

echo "light Scan of $domain completed at $todate ."



echo $domain >> /root/Wordlist/domains_monitoring.txt


