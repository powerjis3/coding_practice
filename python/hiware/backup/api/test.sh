#!/bin/bash

#result="$(curl -k -H "Content-Type: application/json" "https://10.39.11.172:11200/hiware/api/v1/auth/randomKey")"
result="$(http --verify no  GET https://hiware.wonders.work:11200/hiware/api/v1/auth/randomKey)"
echo "result: '$result'"
randomkey=$(echo "$result" | sed -n 's|.*"randomKey":"\([^"]*\)".*|\1|p')
issuekey=$(echo "$result" | sed -n 's|.*"issueKey":"\([^"]*\)".*|\1|p')

echo ${#randomkey}
echo "RandomKey:$randomkey"
echo "issueKey:$issuekey"

enckey="$(echo -n $randomkey | od -A n -t x1 | sed 's/ *//g')"
echo "encKey:$enckey"
encpwd="$(echo -n "shwlsod12" | openssl enc -aes-128-cbc -base64 -K $enckey -iv 0)"
echo "encPwd:$encpwd"

result2="$(curl -k -d "{\"userId\":\"hjshin\", \"password\":\"$encpwd\", \"issueKey\":\"$issuekey\", \"authProviderType\": \"ID/PASSWORD\", \"authProviderId\" : \"hiware\"}" -H "Content-Type: application/json" -X POST "https://hiware.wonders.work:11200/hiware/api/v1/auth/login")"

echo "result : '$result2'"
