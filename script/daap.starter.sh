#!/bin/bash
# daap generator
# domain access authentication protocol
# this is the process daemon that creates daaps for the daapchain

monitorid=$(uuidgen)
daapid=$(uuidgen)
scale=1.00314159
init=705.633583069446
it=652
num=0
./clean.sh
while true;do
shekid=$(uuidgen)
num=$((($RANDOM+1)%114))
#num=$((num+1))
host=$(sed "${num}q;d" nasdaq.sites.daap|cut -f2|xargs)

if [ -z $chainid ]; then
chainid=$shekid
fi

echo "${num} COLLECTING HANDSHAKE DATA FROM [$host] FOR DAAP [$daapid]"
echo -n|openssl s_client -connect $host:443 -showcerts  > info.txt 2>/dev/null 
echo -n|openssl s_client -connect $host:443 | openssl x509 -pubkey -out out.log 2>/dev/null
masterkey=$(grep "Master-Key" info.txt|cut -f2 -d:|xargs)
cipherid=$(grep "Cipher" info.txt|tail -1|cut -f2 -d:|xargs)
sessionid=$(grep "Session-ID" info.txt|cut -f2 -d:|xargs)
protocolid=$(grep "Protocol" info.txt|cut -f2 -d:|xargs)
grep 'subject=' info.txt|sed 's/_/_/g'|xargs > cainfosubject 
grep 'issuer=' info.txt|sed 's/_/_/g'|xargs > cainfoissuer
cat out.log | cut -f2 -d- > public.key

if [ -z ${sessionid} ];then
echo "TLS error, continue"
continue
fi

if [ ! -f cainfosubject ]  || [ ! -f cainfoissuer ] || [ ! -f public.key ];then
echo "CA or Public Key error"
continue
fi

dt=`date +%s`
num=${#dt}
datetime=${dt}
filename=${datetime}.daap.${daapid}.monitor.${monitorid}.shek.${shekid}.shek

jo DAAP-ID=${daapid} Host-ID=${host} Monitor-ID=${monitorid} Session-ID=${sessionid} Chain-ID=${chainid} Protocol-ID=${protocolid} Cipher-ID=${cipherid} SHEK-ID=${shekid} SHEK-MK=${masterkey} SHEK-PK=@out.log CA-Info-Depth-Subject=@cainfosubject CA-Info-Depth-Issuer=@cainfoissuer SHEK-DT=${datetime} > ../shek/${filename}
cat ../shek/${filename}
it=$((it+1))
echo "current step " $it
echo "current scale " $init

if [ $it -eq ${init/.*} ];then 
echo "Saving DAAP!"
zip -m ../daap/${datetime}.daap.${daapid}.monitor.${monitorid}.zip ../shek/* 
daapid=$(uuidgen)
mkdir -p ../shek
it=0;init=$(echo "scale=12;$init*$scale"|bc)
chainid=
#tidyup
./clean.sh
fi

#set chain id for next shek.
chainid=$shekid
done
exit 0
