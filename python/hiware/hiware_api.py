#!/usr/bin/env python3

import requests
import json
from collections import OrderedDict
from base64 import b64encode
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from flask import Flask

app = Flask(__name__)

def login():

    key = requests.get('https://10.39.11.172:11200/hiware/api/v1/auth/randomKey', verify=False)

    json_key = key.json()
    issueKey = json_key['content']['issueKey']
    randomKey = json_key['content']['randomKey']

    ID = 'wcloud'
    PW = 'ahfkd123'

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

def logout(authKey):

    log_out = requests.post('https://10.39.11.172:11200/hiware/api/v1/auth/logout', verify=False, headers={'API-Token': authKey})
    print('logout :', log_out)

@app.route('/eq_delete/<hostname>')
def eq_delete(hostname):

    authKey = login()
    eq_number_search = requests.get('https://10.39.11.172:11200/hiware/v1/ext/eqmts?eqmtNm='+hostname, verify=False, headers={'API-Token': authKey})
    eq_number_search_json = eq_number_search.json()
    eq_number = eq_number_search_json['content'][0]['eqmtNo']

    eq_delete = requests.delete('https://10.39.11.172:11200/hiware/v1/ext/eqmts/'+eq_number+'?delPstpEqmtYn=N', verify=False, headers={'API-Token': authKey})
    result = str(eq_delete)

    logout(authKey)

    return 'hiware list delete : ' + result

@app.route('/eq_check/<hostname>')
def eq_check(hostname):

    authKey = login()
    eq_number_search = requests.get('https://10.39.11.172:11200/hiware/v1/ext/eqmts?eqmtNm='+hostname, verify=False, headers={'API-Token': authKey})
    eq_number_search_json = eq_number_search.json()
    eq_number = eq_number_search_json['content'][0]['eqmtNo']
    eq_ip = eq_number_search_json['content'][0]['eqmtIp']
    eq_hostname = eq_number_search_json['content'][0]['eqmtNm']

    logout(authKey)

    return 'hostname : ' + eq_hostname + '\nip : ' + eq_ip + '\neq number : ' + eq_number + "\n"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port='9090')

