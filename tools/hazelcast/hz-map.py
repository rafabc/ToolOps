import hazelcast



# Connect to Hazelcast cluster.
#client = hazelcast.HazelcastClient(  cluster_name="dev", cluster_members=[ "192.168.1.39:5701", "192.168.1.39:5702" ])
client = hazelcast.HazelcastClient()
# Get or create the "distributed-map" on the cluster.
distributed_map = client.get_map("dni-map")

# Put "key", "value" pair into the "distributed-map" and wait for
# the request to complete.
distributed_map.set("RBC", "274944546X").result()
distributed_map.set("LXF", "725545446V").result()

# Try to get the value associated with the given key from the cluster
# and attach a callback to be executed once the response for the
# get request is received. Note that, the set request above was
# blocking since it calls ".result()" on the returned Future, whereas
# the get request below is non-blocking.
get_future = distributed_map.get("RBC")
get_future.add_done_callback(lambda future: print(future.result()))

# Do other operations. The operations below won't wait for
# the get request above to complete.

print("Map size:", distributed_map.size().result())

# Shutdown the client.
client.shutdown()