import json

def parse_json(object,key):
    obj_dict = json.loads(object)
    print(obj_dict.get(key,'"key not found"'))

    # Iterating through the json
    #for i in obj_dict.get(key):
    #    print(i)


if __name__ == "__main__":
    object = '{"id":"09", "name": "Nitin", "department":"Finance"}'
    key = 'name'
    parse_json(object,key)