#!/bin/bash

# installed httpie

key=$(http --verify no  GET https://10.39.11.172:11200/hiware/api/v1/auth/randomKey)

randomkey=$(echo "$key" | sed -n 's|.*"randomKey":"\([^"]*\)".*|\1|p')
issuekey=$(echo "$key" | sed -n 's|.*"issueKey":"\([^"]*\)".*|\1|p')

echo "randomkey : $randomkey"
echo "issuekey : $issuekey"
echo "  "

enckey="$(echo -n $randomkey | od -A n -t x1 | sed 's/ *//g')"
echo "encKey:$enckey"
encpwd="$(echo -n "shwlsod12" | openssl enc -aes-128-cbc -base64 -K $enckey -iv 0)"
echo "encPwd:$encpwd"

cat <<EOF > key.json
{
    "userid" : "hjshin",
    "password" : "$encpwd",
    "issueKey" : "$enckey",
    "authProviderid" : "hiware",
    "authProviderType" : "ID/PASSWORD"
}
EOF

#cat key.json | http --verify no https://10.39.11.172:11200/hiware/api/v1/auth/login

#rm -rf key.json
