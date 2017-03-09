#!/usr/bin/env python

# Copyright 2016 Mosen/Tim Sutton
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# # # #
# Slightly modified by Max Schlapfer for use at ETH Zurich 
# to optimize the output for machine reading and further use
# with the RecipeCreator script.				2017-03-09
# # # #


import os
import sys
import json
import unicodedata
import urllib2
from urllib import urlencode

CCM_URL = 'https://prod-rel-ffc-ccm.oobesaas.adobe.com/adobe-ffc-external/core/v4/products/all'
BASE_URL = 'https://prod-rel-ffc.oobesaas.adobe.com/adobe-ffc-external/aamee/v2/products/all'

def add_product(products, product):
    if product['id'] not in products:
        products[product['id']] = []

    products[product['id']].append(product)


def feed_url(channels, platforms):
    """Build the GET query parameters for the product feed."""
    params = [
        ('payload', 'true'),
        ('productType', 'Desktop'),
        ('_type', 'json')
    ]
    for ch in channels:
        params.append(('channel', ch))

    for pl in platforms:
        params.append(('platform', pl))

    return CCM_URL + '?' + urlencode(params)

def fetch(channels, platforms):
    """Fetch the feed contents."""
    url = feed_url(channels, platforms)
    print('Fetching from feed URL: {}'.format(url))

    req = urllib2.Request(url, headers={
        'User-Agent': 'Creative Cloud',
        'x-adobe-app-id': 'AUSST_4_0',
    })
    data = json.loads(urllib2.urlopen(req).read())

    return data

def dump(channels, platforms):
    """Save feed contents to feed.json file"""
    url = feed_url(channels, platforms)
    print('Fetching from feed URL: {}'.format(url))

    req = urllib2.Request(url, headers={
        'User-Agent': 'Creative Cloud',
        'x-adobe-app-id': 'AUSST_4_0',
    })
    data = urllib2.urlopen(req).read()
    with open(os.path.join(os.path.dirname(__file__), 'feed.json'), 'w+') as feed_fd:
        feed_fd.write(data)
    print('Wrote output to feed.json')


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == 'dump':
        dump(['ccm', 'sti'], ['osx10', 'osx10-64'])
    else:
        data = fetch(['ccm', 'sti'], ['osx10', 'osx10-64'])
        products = {}
        for channel in data['channel']:
            for product in channel['products']['product']:
                add_product(products, product)

        for sapcode, productVersions in products.iteritems():

            for product in productVersions:
                base_version = product['platforms']['platform'][0]['languageSet'][0].get('baseVersion')
                if not base_version:
                    base_version = "N/A"

                name = unicodedata.normalize("NFKD", product['displayName'])
                print("{0},Adobe,{1},{2},{3}".format(
                    sapcode,
                    name,
                    base_version,
                    product['version']
                ))
            print("---")
