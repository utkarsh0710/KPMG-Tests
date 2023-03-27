import requests
import argparse
import sys

def get_vm_metadata(key):
    METADATA_URL = 'http://metadata.google.internal/computeMetadata/v1/'
    METADATA_HEADERS = {'Metadata-Flavor': 'Google'}
    meta_vals = ['attributes', 'cpu-platform', 'description', 'disks', 'guest-attributes', 'hostname', 'id', 'image', 'legacy-endpoint-access', 'licenses', 'machine-type', 'maintenance-event', 'name', 'network-interfaces', 'preempted', 'scheduling', 'service-accounts', 'tags', 'zone']
    if key in meta_vals:
        if key in ['attributes', 'disks', 'guest-attributes', 'legacy-endpoint-access', 'licenses', 'network-interfaces', 'scheduling', 'service-accounts']:
            url = METADATA_URL + f'instance/{key}/'
        else:    
            url = METADATA_URL + f'instance/{key}'
        res = requests.get(url, headers=METADATA_HEADERS,)
        print(res.text)
    else:
        sys.exit(f'"key" should be one of {meta_vals}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", help="vm instance metadata key", required=True)
    args = parser.parse_args()
    get_vm_metadata(args.key)