#!/bin/bash

##
# BUT BABIS
# 
# Simple curl script for getting EET bills info from SKM BUT BRNO.
#
# @todo: Date do not work
#
#
# WARNING AND DISCLAIMER:
# This app is offered "as is", and IT DOES NOT MAKE ANY GUARANTEES ON ANY ISSUE.
#
# ID:
# - your BUT ID
#
# PASSWORD:
# - your BUT IS password
#
# DATE_FROM (not working)
# - from which date may be bills gained

##
# Come as no surprise, prints the usage.
#
usage() {
    cat <<EOF
Usage: ${PROGNAME} [options]

Simple curl script for getting EET bills info from SKM BUT BRNO.

Options:
EOF

    cat <<EOF | column -s\& -t
    -h, --help          & shows this help and terminates
    -i, --id            & BUT BRNO id (e.g. 211193)
    -d, --date-from     & from which date may be bills gained (e.g. 20.01.2018, defaults 01.09.2018)
    -p, --password      & your BUT IS password (e.g. uHergD78pyhj)
    -m, --mail          & email of the player (e.g. foo@bar.baz)
    -r, --register      & register to Uctenkovka, in order to register billet you must download script uctenkovka.sh from https://gist.github.com/stuchl4n3k/af0178701122e501d6a3a33a117d7d04 and place it into same folder
EOF
}

##
# Checks if a given argument is a (decimal) number.
#
is_number() {
    case $1 in ''|*[!0-9]*) false;; esac;
}

##
# Validates input variables.
#
validate_input() {
    VALID=1
    if [[ ${BUT_ID} == "" ]]; then
        >&2 printf "error: no ID given\n"
        VALID=0
    fi

    if [[ ${PASSWORD} == "" ]]; then
        >&2 printf "error: no password given\n"
        VALID=0
    fi

    if [[ ${DATE_FROM} == "" ]]; then
        DATE_FROM = "01.09.2018"
    fi

    # date "+%Y-%m-%d" -d ${DATE} > /dev/null  2>&1
    # if [ $? -ne 0 ]; then
    #     >&2 printf "error: invalid date given\n"
    #     VALID=0
    # fi

    # date "+%H:%M" -d ${TIME} > /dev/null  2>&1
    # if [ $? -ne 0 ]; then
    #     >&2 printf "error: invalid time given\n"
    #     VALID=0
    # fi

}

##
# Main function. Does the actual HTTP request via curl.
#
main() {
#    login_form_content=$(curl -d https://www.vutbr.cz/login)
#    echo $login_form_content>>curl.txt
   login_form_content=$(wget -q -O - --save-cookies cookies.txt \
     --keep-session-cookies \
      --delete-after \
      https://www.vutbr.cz/login
     )
   #echo $login_form_content>>wget.txt
   sent_time=$(echo ${login_form_content} | perl -nle 'm/\074input type\075\042hidden\042 name\075\042sentTime\042 value\075\042([0-9]{10,})\042\076/; print $1')
   #echo $sent_time
   sv_Bfdkey_5D=$(echo ${login_form_content} | perl -nle 'm/\074input type\075\042hidden\042 name\075\042sv\133fdkey\135\042 value\075\042([A-Za-z0-9]{10,})\042\076/; print $1')
   #echo $sv_Bfdkey_5D

    POST=`printf "special_p4_form=1&login_form=1&sentTime=%s&sv%%5Bfdkey%%5D=%s&LDAPlogin=%s&LDAPpasswd=%s&login=" ${sent_time} ${sv_Bfdkey_5D} ${BUT_ID} ${PASSWORD}`

    login=$(wget -q -O -\
        --load-cookies cookies.txt \
        --keep-session-cookies \
        --save-cookies cookies.txt \
        --post-data $POST \
        --delete-after \
        https://www.vutbr.cz/login/in)

    SKM_web_main=$(wget -q -O -\
        --load-cookies cookies.txt \
        --keep-session-cookies \
        --save-cookies cookies.txt \
        --delete-after \
        https://www.vutbr.cz/external/kamb_redirect.php)

    #echo ${SKM_web_main} >>SKM.txt
    #account_adress=$(echo ${SKM_web_main} | perl -nle 'm/\074a href\075\042([a-zA-Z0-9\057]{1,})\042\076 \074img alt\075\042Detail\042 title\075\042[^\042]*\042 src\075\042\057app05\057IsKAM\057Content\057images\057eye\056png\042\076 \074\057a\076/; print $1')
    account_adress=$(echo ${SKM_web_main} | perl -nle 'm/\074a href\075\042\057app05\057IsKAM\057Konta\057PrevodyUhrady\057([a-zA-Z0-9\057]{1,})\042\076/; print $1')
    #echo $account_adress
    while [ "$account_adress" != "" ]
    do
        echo "Account: "$account_adress
        #datum_POST=`printf "datumOd=%s" $DATE_FROM`
        datum_POST=`printf "datumOd=01.09.2018"`
        #'datumOd='$DATE_FROM
        echo "POSTING DATE "$datum_POST
        SKM_web_list=$(wget -q -O -\
            --method='POST' \
            --header='Content-Type: application/x-www-form-urlencoded' \
            --user-agent='Mozzila/5.0' \
            --load-cookies cookies.txt \
            --keep-session-cookies \
            --save-cookies cookies.txt \
            --body-data='datumOd=01.09.2018' \
            --delete-after \
            https://www.skm.vutbr.cz/app05/IsKAM/Konta/PrevodyUhrady/$account_adress)

        #echo ${SKM_web_list} >>SKM_list.txt
        
        bill_adress=$(echo ${SKM_web_list} | perl -nle 'm/\074a title\075\042EET &#250;čtenka\042 href\075\042\057app05\057IsKAM\057EETUctenka\057DejUctenku\057([a-zA-Z0-9\057]{1,})\042 Class\075\042btn btn-sm btn-sm-table\042\076EET &#250;čtenka\074\057a\076/; print $1')
        #echo $bill_adress

        while [ "$bill_adress" != "" ]
        do
            SKM_EET_bill=$(wget -q -O -\
                --load-cookies cookies.txt \
                --keep-session-cookies \
                --save-cookies cookies.txt \
                --delete-after \
                https://www.skm.vutbr.cz/app05/IsKAM/EETUctenka/DejUctenku/$bill_adress)
            #echo ${SKM_EET_bill} >>SKM_bill.txt

            FIK_code=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042FIK\042\076FIK\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042[^\042]*\042\076(.{39})\074\057label\076/; print $1')
            #FIK_code=$(echo ${SKM_EET_bill} | perl -nle 'm/\s*\074\057th\076\s*\074td\076\s*\074label for\075\042\042\076([0-9A-Z]{1,})\074\057label\076/; print $1')
            #echo $FIK_code

            DATE_y=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042DatumTrzby\042\076Datum a čas přijet&#237;\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042\042\076([0-9]{1,2})\056 ([0-9]{1,2})\056 ([0-9]{4})[^\074]+\074\057label\076/; print $3')
            DATE_m=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042DatumTrzby\042\076Datum a čas přijet&#237;\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042\042\076([0-9]{1,2})\056 ([0-9]{1,2})\056 ([0-9]{4})[^\074]+\074\057label\076/; print $2')
            DATE_d=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042DatumTrzby\042\076Datum a čas přijet&#237;\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042\042\076([0-9]{1,2})\056 ([0-9]{1,2})\056 ([0-9]{4})[^\074]+\074\057label\076/; print $1')
            if [ "${#DATE_m}" = "1" ]
            then
                DATE_m="0"$DATE_m
            fi
            if [ "${#DATE_d}" = "1" ]
            then
                DATE_d="0"$DATE_d
            fi
            DATE=$DATE_y"-"$DATE_m"-"$DATE_d
            #echo $DATE

            TIME=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042DatumTrzby\042\076Datum a čas přijet&#237;\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042\042\076[0-9]{1,2}\056 [0-9]{1,2}\056 [0-9]{4} ([0-9]{1,2}\072[0-9]{2})[^\074]+\074\057label\076/; print $1')
            if [ "${#TIME}" = "4" ]
            then
                TIME="0"$TIME
            fi
            #echo $TIME

            DIC=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042DIC\042\076DIČ\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042[^\074]*\042\076(CZ[0-9]{1,})\074\057label\076/; print $1')
            #echo $DIC

            AMOUNT=$(echo ${SKM_EET_bill} | perl -nle 'm/\074label for\075\042CelkovaCastka\042\076Celkov&#225; č&#225;stka tržby\074\057label\076\072\s*\074\057th\076\s*\074td\076\s*\074label for\075\042[^\074]*\042\076([0-9]{1,})\074\057label\076/; print $1')".00"
            if [ "${AMOUNT}" = "0.00" ]
            then
                AMOUNT="0.01"
            fi
            #echo $AMOUNT

            FIK_3=$(echo $FIK_code | perl -nle 'm/([0-9A-Z]{1,}\055[0-9A-Z]{1,}\055[0-9A-Z]{1,})\055[0-9A-Z]{1,}\055[0-9A-Z]{1,}\055[0-9A-Z]{1,}/; print $1')
            #echo $FIK_3
            if [ ${REGISTER} = true ]
            then
                echo "REGISTRUJI: "$DIC" "$DATE" "$TIME" "$AMOUNT"CZK"
                ./uctenkovka.sh -e $MAIL -a $AMOUNT -f $FIK_3 -v $DIC -d $DATE -t $TIME
            else
                echo "NEREGISTRUJI: "$DIC" "$DATE" "$TIME" "$AMOUNT"CZK"
            fi
            remove=$(echo ${SKM_web_list} | perl -nle 'm/(\074a title\075\042EET &#250;čtenka\042 href\075\042\057app05\057IsKAM\057EETUctenka\057DejUctenku\057[a-zA-Z0-9\057]{1,}\042 Class\075\042btn btn-sm btn-sm-table\042\076EET &#250;čtenka\074\057a\076)/; print $1')
            in=""
            SKM_web_list=$(echo ${SKM_web_list} | perl -nle 'm/\074a title\075\042EET &#250;čtenka\042 href\075\042\057app05\057IsKAM\057EETUctenka\057DejUctenku\057([a-zA-Z0-9\057]{1,})\042 Class\075\042btn btn-sm btn-sm-table\042\076EET &#250;čtenka\074\057a\076(.*)/; print $2')
            #echo $SKM_web_list
            bill_adress=$(echo ${SKM_web_list} | perl -nle 'm/\074a title\075\042EET &#250;čtenka\042 href\075\042\057app05\057IsKAM\057EETUctenka\057DejUctenku\057([a-zA-Z0-9\057]{1,})\042 Class\075\042btn btn-sm btn-sm-table\042\076EET &#250;čtenka\074\057a\076/; print $1')
        done
        SKM_web_main=$(echo ${SKM_web_main} | perl -nle 'm/\074a href\075\042\057app05\057IsKAM\057Konta\057PrevodyUhrady\057([a-zA-Z0-9\057]{1,})\042\076(.*)/; print $2')
        account_adress=$(echo ${SKM_web_main} | perl -nle 'm/\074a href\075\042\057app05\057IsKAM\057Konta\057PrevodyUhrady\057([a-zA-Z0-9\057]{1,})\042\076/; print $1')
    done
}

VERSION="1.0.3"
PROGNAME=${0##*/}
SHORTOPTS="h,r,i:,d:,p:,m:"
LONGOPTS="help,register,id:,date-from:,password:,mail:"

API_URL="https://www.vutbr.cz/login/in"
BUT_ID=0;
PASSWORD="";
REGISTER=false

echo -e "--- VUT BABIŠ ${VERSION} by jzakw\n"

ARGS=$(getopt -s bash --options ${SHORTOPTS} --longoptions ${LONGOPTS} --name ${PROGNAME} -- "$@")
if [ $? -ne 0 ]; then
    usage
    exit 1
elif [ $# -eq 0 ]; then
    >&2 printf "${PROGNAME}: no arguments supplied\n"
    usage
    exit 1
fi

eval set -- "${ARGS}"
unset ARGS

while true; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--register)
            REGISTER=true
            ;;
		-i|--id)
			shift
			BUT_ID=$1
			;;
		-d|--date-from)
			shift
			DATE_FROM=$1
			;;
		-p|--password)
			shift
			PASSWORD=$1
			;;
        -m|--mail)
			shift
			MAIL=$1
			;;
		--)
			shift
			break
			;;
		*)
            usage
            exit 1
			;;
    esac
    shift
done

validate_input
main
