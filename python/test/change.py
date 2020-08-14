#!/usr/bin/python3
import json

def get_json() :
    json_file = "/Users/hjshin/script/test.json"
    json_data = open(json_file).read()

    data = json.loads(json_data)

    return data

print(get_json)
