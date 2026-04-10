import org.apache.camel.BindToRegistry;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.jdbc.JdbcComponent;
import org.apache.commons.dbcp.BasicDataSource;

public class DatabaseToRedisRoute extends RouteBuilder {

    @BindToRegistry("myDataSource")
    public BasicDataSource createDataSource() {
        BasicDataSource dataSource = new BasicDataSource();
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setUrl("jdbc:postgresql://-svc:5432/<<dbname>>");
        dataSource.setUsername("usermicros");
        dataSource.setPassword("pswmicros");
        return dataSource;
    }

    @Override
    public void configure() throws Exception {
        from("timer:tick?period=2000")
            .setBody(simple("SELECT * FROM config"))
            .to("jdbc:myDataSource")
            .to("log:info");
    }
}
