from pymemcache.client import base

# Don't forget to run `memcached' before running this next line:
client = base.Client(('localhost', 5701))

# Once the client is instantiated, you can access the cache:
client.set('some_key', 'some value')

# Retrieve previously set data again:
client.get('some_key')
'some value'