#!/usr/bin/env python3

import requests
import getpass
import json
from collections import OrderedDict
from base64 import b64encode
from Crypto.Cipher import AES

def login():

    key = requests.get('https://10.39.11.172:11200/hiware/api/v1/auth/randomKey', verify=False)

    json_key = key.json()
    issueKey = json_key['content']['issueKey']
    randomKey = json_key['content']['randomKey']

    ID = input('ID : ')
    PW = getpass.getpass('PW : ')

    data = PW.encode()
    key = randomKey.encode()

    ivBytes = bytes([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    cipher = AES.new(key, AES.MODE_CBC, ivBytes)
    ct_bytes = cipher.encrypt(pad(data, AES.block_size))
    encpwd = b64encode(ct_bytes).decode('utf-8')

    login_json = OrderedDict()
    login_json = {
        "userId" : ID,
        "password" : encpwd,
        "issueKey" : issueKey,
        "authProviderId" : "hiware",
        "authProviderType" : "ID/PASSWORD",
        "ipAddress" : "10.39.11.172"
    }

    headers = {'Content-Type': 'application/json; charset=utf-8'}
    login_result = requests.post("https://10.39.11.172:11200/hiware/api/v1/auth/login", verify=False, headers=headers, json=login_json)
    login_result_json = login_result.json()
    auth_key = login_result_json['content']['authKey']

    return auth_key

def main_run():

    authKey = login()
    print(authKey)

if __name__ == '__main__':
    main_run()

