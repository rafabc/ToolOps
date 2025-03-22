

import requests
session = requests.Session()
print(session.cookies.get_dict())

response = session.get('http://google.com')
print(session.cookies.get_dict())