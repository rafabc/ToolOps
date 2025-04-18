package datasourceAutowired;
/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// You can use the sample postgres database available at https://github.com/apache/camel-k/tree/release-1.8.x/examples/databases/postgres-deploy
//
// kamel run JDBCSelect.java --dev -p quarkus.datasource.camel.db-kind=postgresql
//                                 -p quarkus.datasource.camel.jdbc.url=jdbc:postgresql://postgres:5432/test
//                                 -p quarkus.datasource.camel.username=postgresadmin
//                                 -p quarkus.datasource.camel.password=admin123

// Alternatively, you can bundle your credentials as a secret properties file:
//
// kubectl create secret generic my-datasource --from-file=datasource.properties
//
// kamel run JDBCSelect.java --dev --config secret:my-datasource

// camel-k: dependency=camel:jdbc
// camel-k: dependency=mvn:io.quarkus:quarkus-jdbc-postgresql

import org.apache.camel.builder.RouteBuilder;

public class REDISGetKey extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        from("direct:start")
            .setHeader("CamelRedis.Key", "mykey")
            .setHeader("CamelRedis.Value", "valx")
            .to("reactive-streams:redis-publisher"); // Endpoint para enviar mensajes a Redis
    }
}

/*
import io.quarkus.runtime.annotations.RegisterForReflection;
import org.apache.camel.builder.RouteBuilder;

@RegisterForReflection // Necesario para permitir la introspección de clases por Camel
public class RedisRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        from("direct:start")
            .setHeader("CamelRedis.Key", constant("mykey"))
            .setHeader("CamelRedis.Value", body())
            .to("reactive-streams:redis-publisher"); // Endpoint para enviar mensajes a Redis
    }
}*/
