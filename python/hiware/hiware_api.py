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

    hostname_ljust = 'hostname'.ljust(10)
    ip_ljust = 'ip'.ljust(10)
    eq_number_ljust = 'eq number'.ljust(10)

    return hostname_ljust + ' : ' + eq_hostname + "\n" + ip_ljust + ' : ' + eq_ip + '\n' + eq_number_ljust + ' : ' + eq_number + "\n"

@app.route('/eq_add/<hostname>/<ipaddr>/<os>/<env>')
def eq_add(hostname, ipaddr, os, env):

    authKey = login()

    eq_add_result_file = open('result.txt', 'w')

    if os == 'UBUNTU':
        os = '000103'
    elif os == 'CENTOS':
        os = '000010'
    else:
        print('OS를 확인부탁드립니다.')

    if env == 'DEV':
        env = '510'
    elif env == 'QA':
        env = '512'
    elif env == 'STG/PERF':
        env = '513'
    elif env == 'PROD':
        env = '514'
    elif env == 'V-DEV':
        env = '499'
    elif env == 'V-QA':
        env = '501'
    elif env == 'V-STG-A':
        env = '504'
    elif env == 'V-STG-B/PERF':
        env = '506'
    elif env == 'V-PROD-A':
        env = '507'
    elif env == 'V-PROD-B':
        env = '508'
    elif env == 'V-PROD-C':
        env = '509'
    elif env == 'Server':
        env = '496'
    else:
        print('env를 확인부탁드립니다.')

    eq_add_json = OrderedDict()
    eq_add_json = {
        "eqmtNm" : hostname,
        "eqmtGrpNo" : env,
        "eqmtClassCode" : "01",
        "eqmtPtnCode" : "02",
        "osVerCode" : os,
        "eqmtSecurFuncCdArray" : [
            "1"
        ],
        "sysSvrNo" : "2",
        "eqmtIpList" : [
            {
                "ipAddrLayerCode" : "01",
                "eqmtIp" : ipaddr,
                "dlgEqmtIpYn" : "Y"
            }
        ],
        "eqmtConnPtnCode" : "1",
        "samAcctInfoYn" : "Y",
        "samAcctInfo" : {
            "basicEqmtSvcNo" : "1",
            "eqmtSvcNoList" :[
                "1"
            ]
        }
    }
    eq_add_api = requests.post('https://10.39.11.172:11200/hiware/v1/ext/eqmts', verify=False, headers={'API-Token': authKey}, json=eq_add_json)
    eq_add_api_str = str(eq_add_api)
    result_file_source = hostname + ' / input reuslt : ' + eq_add_api_str + '\n'
    eq_add_result_file.write(result_file_source)
    eq_add_result_file.close()

    return hostname + ' input result : ' + eq_add_api_str

if __name__ == '__main__':
    app.run(host='0.0.0.0', port='9090')
