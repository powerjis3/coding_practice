#!/usr/bin/env python3

import requests
import getpass
import json
from collections import OrderedDict
from base64 import b64encode
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

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

def eq_add(authKey):

    eq_add_result_file = open('result.txt', 'w')

    file_list = open('list.txt', 'r')
    lines = file_list.readlines()
    for i in lines:
        a = i.split()
        hostname = a[0]
        ipaddr = a[1]
        os = a[2]

        if os == 'UBUNTU':
            os = '000103'
        elif os == 'CENTOS':
            os = '000010'
        else:
            print('OS를 확인부탁드립니다.')

        eq_add_json = OrderedDict()
        eq_add_json = {
            "eqmtNm" : hostname,
            "eqmtGrpNo" : "496",
            "eqmtClassCode" : "01",
            "eqmtPtnCode" : "01",
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
        print(hostname, '/ input result :', eq_add_api)
        eq_add_api_str = str(eq_add_api)
        result_file_source = hostname + ' / input reuslt : ' + eq_add_api_str + '\n'
        eq_add_result_file.write(result_file_source)

    eq_add_result_file.close()

def logout(authKey):

    log_out = requests.post('https://10.39.11.172:11200/hiware/api/v1/auth/logout', verify=False, headers={'API-Token': authKey})
    print('logout :', log_out)

def main_run():

    authKey = login()
    eq_add(authKey)
    logout(authKey)

if __name__ == '__main__':
    main_run()

