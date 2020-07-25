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

    printf "interestingparams \n\n " >> $output_directory/output/gf_results.txt 
gf interestingparams $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt

    printf "debug_logic \n\n " >> $output_directory/output/gf_results.txt 
gf debug_logic $output_directory/gfonly/final_full_live_urls.txt| awk -F ':' '{$1=$2="\b"; print $0}' >> $output_directory/output/gf_results.txt 
 printf "\n\n\n" >> $output_directory/output/gf_results.txt
 


 cd -
}

get_hidden_params(){
  mkdir -p $output_directory/ffuf_hidden_params
  echo "Scanning for hidden params............."
  ffuf -w $output_directory/200.txt -s -u FUZZ -t 100 -se -r -sf  -od $output_directory/ffuf_hidden_params/ -r
  cd $output_directory/
  extract_hidden_param.py -i "ffuf_hidden_params/*" -u $output_directory/200.txt  -p $output_directory/output/hidden_params.txt
  cat $output_directory/output/hidden_params.txt >> $output_directory/output/params.txt

  cd $output_directory/ffuf_hidden_params
  grep  -Eo "var [a-zA-Z0-9_]+" * |awk '{print $2}' | awk '!seen[$0]++' > $output_directory/output/vars.txt
  cat $output_directory/output/vars.txt >> $output_directory/output/params.txt

  rm_dup_file $output_directory/output/params.txt
}

build_urls(){
mkdir -p $output_directory/build_urls
echo "Building ssrf urls"

# path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/ssrf.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/ssrf.txt
path_plus_param.py -f  ~/Wordlist/parameter/ssrf.txt -f $output_directory/output/vars.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/ssrf.txt

# echo "Building lfi urls"
# path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/LFI.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/LFI.txt



# path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/Open_redirect.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/Open_redirect.txt


echo "Building xss urls"

path_plus_param.py -f  $output_directory/output/params.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/xss.txt
# path_plus_param.py -f  $output_directory/output/params.txt ~/Wordlist/parameter/columns.txt -p $output_directory/temp_processing/unique_domainpaths.txt > $output_directory/build_urls/xss.txt




# # for sqli, needing to append ' at the end of query value, so it is different from other test input
#qsreplace -a %23 > $output_directory/build_urls/sqli.txt
}

remove_files(){
  rm $output_directory/build_urls/xss.txt
  rm  $output_directory/build_urls/ssrf.txt
  
}

mkdir -p $output_directory/
mkdir -p $output_directory/output

echo "Input file from gau      $file  "

cat $file | sed -E -e '/(\.jpg|\.png|\.gif|\.woff|\.css|\.ico|\.js|\.swf|\.zip|\.JPG|\.mp3|\.mov|\.svg|\.jpeg|\.map|\.pdf|\.txt)/d'| sed '/^[[:space:]]*$/d' > $output_directory/filtered_url.txt
echo "Remove urls with boring extensions"



echo "Remove urls with boring extensions     $output_directory/filtered_url.txt "


cat $output_directory/filtered_url.txt | wordlistgen > $output_directory/output/wordlistgen.txt

echo "Using wordlistgen     $output_directory/output/wordlistgen.txt "



cat $output_directory/filtered_url.txt | urinteresting >  $output_directory/output/maybeinteresting_urls.txt

echo "find urls which may contain interesting things such as admin,proxy  $output_directory/output/maybeinteresting_urls.txt"

cat $output_directory/filtered_url.txt | unfurl keys | awk '!seen[$0]++'   > $output_directory/output/params.txt
echo  "Extract parameters of query string               $output_directory/output/params.txt "

awk '/?/ && /=/' $output_directory/filtered_url.txt > $output_directory/with_querystring_urls.txt
echo  "Only keeps urls with query string   $output_directory/with_querystring_urls.txt" 

mkdir -p $output_directory/temp_processing/


# cat $output_directory/with_querystring_urls.txt | unfurl -u format " %p?%q"   >  $output_directory/temp_processing/pathandquery.txt
echo "Deduplicate live urls, only remain unique path and query sting   $output_directory/unique_urls.txt"

# deduplicate_urls.py $output_directory/temp_processing/pathandquery.txt   $output_directory/with_querystring_urls.txt $output_directory/unique_urls.txt
cat $output_directory/with_querystring_urls.txt | urldedupe > $output_directory/unique_urls.txt

count=$(wc -l $output_directory/unique_urls.txt| awk '{print $1}')

echo "Check status on $count urls .................."


# count=$(expr $count + 1)
# if [ "$count" -lt 99999 ]
# then 
#     halive $output_directory/unique_urls.txt -t 100 --output $output_directory/halive.txt
#     egrep '302|301|200' $output_directory/halive.txt | awk 'BEGIN { FS = "," } ; { print $1 }' > $output_directory/final_full_live_urls.txt
# else 
#   echo "using fff..............  $count urls   "
#     cat $output_directory/unique_urls.txt |  fff -s 301 -s 302 -s 200 > $output_directory/fff.txt  
#     awk '{print $1}' $output_directory/fff.txt > $output_directory/final_full_live_urls.txt
# fi
# echo " Obtain currentlly live urls           $output_directory/final_full_live_urls.txt  "


  echo "using fff..............  $count urls   "
    cat $output_directory/unique_urls.txt |  fff -s 301 -s 302 -s 200 -s 500 > $output_directory/fff.txt  
    cat $output_directory/fff.txt | egrep '200|500'|   awk '{print $2}' > $output_directory/200.txt
    cat $output_directory/fff.txt |  egrep '302|301'|  awk '{print $2}' > $output_directory/301-302.txt
    cat $output_directory/fff.txt |  egrep '302|301|200|500'|  awk '{print $2}' > $output_directory/final_full_live_urls.txt
    cat $output_directory/final_full_live_urls.txt | urldedupe -s  > $output_directory/dedupe_similar_urls.txt








#final_full_live_urls.txt
# https://www.takeaway.com/be-en/melita-beveren?gclid=CPnRucma5d8CFXyIxQIdLpgFgQ&gclsrc=ds
# https://www.takeaway.com/pizzahutgent?utm_campaign=foodorder&utm_medium=organic&utm_sour
# ce=google
# https://www.takeaway.com/_Incapsula_Resource?SWKMTFSR=1&e=0.7240281121983518
# https://www.takeaway.com/be/sushi-beveren?k1111=k1111

get_hidden_params

# whatweb -i $output_directory/final_full_live_urls.txt | tee $output_directory/ip.txt

run_gf
#bug with gf 

cat  $output_directory/200.txt | unfurl -u format "%s://%d%p" > $output_directory/temp_processing/unique_domainpaths.txt
#https://www.takeaway.com/bg-nl/acties-en-kortingen-in-sofiya
``
build_urls


#xss


echo "Using kxss...........    $output_directory/200.txt      $output_directory/output/xss1.txt      "
cat $output_directory/200.txt | timeout 3h kxss >  $output_directory/output/xss1.txt
echo "kxss finished at $(date +'%Y-%m-%d-%H-%M') for $output_directory/200.txt"

echo "Using kxss...........   $output_directory/build_urls/xss.txt     $output_directory/output/xss2.txt      "
cat $output_directory/build_urls/xss.txt | timeout 3h  kxss >  $output_directory/output/xss2.txt
echo "kxss finished at $(date +'%Y-%m-%d-%H-%M') for $output_directory/build_urls/xss.txt"


# echo "Using xss.py ...........       $output_directory/output/xsspy.txt      "
#  timeout 6h xss.py -v 4 -u $output_directory/200.txt -O $output_directory/output/xsspy.txt
# echo "xss.py finished at $(date +'%Y-%m-%d-%H-%M') for $output_directory/output/xsspy.txt"

# echo "Using xss.py ...........       $output_directory/output/xsspy2.txt      "
#  timeout 6h xss.py -v 4 -u $output_directory/build_urls/xss.txt -O $output_directory/output/xsspy2.txt
# echo "xss.py finished at $(date +'%Y-%m-%d-%H-%M') for $output_directory/output/xsspy2.txt"

echo "Using puppeteer-xss.py  ...........       $output_directory/output/xsspy.txt      "
 timeout 6h puppeteer-xss.py  -t 5 -v 4 -u $output_directory/200.txt -O $output_directory/output/xsspy.txt
echo "puppeteer-xss.py  finished at $(date +'%Y-%m-%d-%H-%M') for $output_directory/200.txt"

echo "Using puppeteer-xss.py  ...........       $output_directory/output/xsspy2.txt      "
 timeout 8h puppeteer-xss.py -t 5 -v 4 -u $output_directory/build_urls/xss.txt -O $output_directory/output/xsspy2.txt
echo "puppeteer-xss.py  finished at $(date +'%Y-%m-%d-%H-%M') for $output_directory/build_urls/xss.txt"

 grep -i vulnerable $output_directory/output/xsspy.txt > $output_directory/output/xss_vulnerable.txt
 grep -i vulnerable $output_directory/output/xsspy2.txt >> $output_directory/output/xss_vulnerable.txt




#lfi
 echo "Scanning for lfi ...   $output_directory/output/lfi1.txt "
  timeout 8h lfi.py -v 4 -u $output_directory/200.txt   -O $output_directory/output/lfi1.txt
 grep -i vulnerable $output_directory/output/lfi1.txt > $output_directory/output/lfi_vulnerable.txt

echo "lfi.py finished at $(date +'%Y-%m-%d-%H-%M')"
 echo "Finished scanning of  lfi ...   $output_directory/output/lfi_vulnerable.txt "




#open_redirect
cat $output_directory/301-302.txt | grep --color -iE "(callback=|checkout=|checkout_url=|continue=|data=|dest=|destination=|dir=|domain=|feed=|file=|file_name=|file_url=|folder=|folder_url=|forward=|from_url=|go=|goto=|host=|html=|image_url=|img_url=|load_file=|load_url=|login_url=|logout=|navigation=|next=|next_page=|Open=|out=|page=|page_url=|path=|port=|redir=|redirect=|redirect_to=|redirect_uri=|redirect_url=|reference=|return=|return_path=|return_to=|returnTo=|return_url=|rt=|rurl=|show=|site=|target=|to=|uri=|url=|val=|validate=|view=|RedirectUrl=|Return=|ReturnUrl=|ClientSideUrl=|failureUrl=|ru=|relayState=|fallbackurl=|clickurl=|dest_url=|urlReturn=|referer=|appUrlScheme=|cgi-bin/redirect.cgi=|window=|re|r|url|new)" > $output_directory/build_urls/Open_redirect_input.txt
 redirect_replaceparam.py -f $output_directory/build_urls/Open_redirect_input.txt > $output_directory/build_urls/Open_redirect_ffuf.txt
echo "ffuing $output_directory/build_urls/Open_redirect_ffuf.txt"
ffuf -w  $output_directory/build_urls/Open_redirect_ffuf.txt -H "X-Real-IP: 127.0.0.1" -u FUZZ -t 100  -r  -s


# echo "Using  openredirect.py .....  $output_directory/output/openredirectpy.txt"
# timeout 4h openredirect.py -u $output_directory/build_urls/Open_redirect_input.txt -O $output_directory/output/openredirectpy.txt
#  grep -i vulnerable $output_directory/output/openredirectpy.txt > $output_directory/output/redirect_vulnerable.txt





#sqlid
echo "Scanning sqli  $output_directory/output/sqli1.txt  "
cat $output_directory/200.txt |  timeout 6h qsfuzz -c ~/Wordlist/qsfuzz/sqli.yaml -w 100 | tee $output_directory/output/sqli1.txt

#crlf 
echo "Scanning crlf  $output_directory/output/crlf.txt  "

cat $output_directory/200.txt |  timeout 3h qsfuzz -c ~/Wordlist/qsfuzz/crlf.yaml -w 100 | tee $output_directory/output/crlf.txt

echo "Scanning crlf  using crlf.py  $output_directory/output/crlfpy.txt  "
timeout 4h crlf.py -u $output_directory/200.txt -v 4 -t 80 -O $output_directory/output/crlfpy.txt
 grep -i vulnerable $output_directory/output/crlfpy.txt > $output_directory/output/crlf_vulnerable.txt

echo "crlf.py finished at $(date +'%Y-%m-%d-%H-%M')"

 #cors 
 echo "Scanning cors  using cors.py  $output_directory/output/corspy.txt  "
timeout 4h cors.py -u $output_directory/200.txt -v 4 -t 80  -O $output_directory/output/corspy.txt
 grep -i vulnerable $output_directory/output/corspy.txt > $output_directory/output/cors_vulnerable.txt

echo "cors.py finished at $(date +'%Y-%m-%d-%H-%M')"



#ssrf 
echo "Building urls for ssrf   $output_directory/build_urls/ssrf_ffuf1.txt  "
ssrf_replaceparam.py -f $output_directory/200.txt > $output_directory/build_urls/ssrf_ffuf1.txt
ssrf_replaceparam.py -f $output_directory/build_urls/ssrf.txt -a > $output_directory/build_urls/ssrf_ffuf2.txt

echo "Ffufing generaterd ssrf urls   "

ffuf -w $output_directory/build_urls/ssrf_ffuf1.txt -u FUZZ -t 100 -r  -s -H "X-Real-IP: 127.0.0.1"
timeout 3h ffuf -w $output_directory/build_urls/ssrf_ffuf2.txt -u FUZZ -t 100 -r -s -H "X-Real-IP: 127.0.0.1"
psql -d ssrf  -c "SELECT * FROM ssrf_records where  created_on > current_date - interval '7 days'" --csv > $output_directory/output/ssrf.csv


 #request smuggling  
 echo "Scanning request smuggling  using smuggler_gwen001.py  $output_directory/output/smuggler.txt  "
# timeout 10h smuggler_gwen001.py -u $output_directory/dedupe_similar_urls.txt -v 4 -t 150  -O $output_directory/output/smuggler.txt
timeout 10h smuggler_modified.py -u $output_directory/dedupe_similar_urls.txt -v 4 -t 150  -O $output_directory/output/smuggler.txt
echo "smuggler_gwen001.py finished at $(date +'%Y-%m-%d-%H-%M')"

 grep -i vulnerable $output_directory/output/smuggler.txt > $output_directory/output/smuggler_vulnerable.txt


remove_files