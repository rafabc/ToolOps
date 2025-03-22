import hazelcast

client = hazelcast.HazelcastClient(
    cluster_name="dev",
    cluster_members=[
        "192.168.1.39:5701",
        "192.168.1.39:5702",
    ],
    lifecycle_listeners=[
        lambda state: print("Lifecycle event >>>", state),
    ]
)

print("Connected to cluster")
client.shutdown()