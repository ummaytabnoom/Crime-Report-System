package utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Central Oracle connection utility for the Crime Report System.
 *
 * Configuration can be supplied through environment variables or JVM system
 * properties. Existing XE defaults are kept for backward compatibility.
 *
 * Environment / system property names:
 *   CRIME_DB_URL / crime.db.url
 *   CRIME_DB_USER / crime.db.user
 *   CRIME_DB_PASSWORD / crime.db.password
 */
public final class DBConnection {
    private static final String DEFAULT_URL = "jdbc:oracle:thin:@localhost:1521:XE";
    private static final String DEFAULT_USER = "system";
    private static final String DEFAULT_PASSWORD = "a12345";

    private DBConnection() {
        // Utility class.
    }

    static {
        try {
            Class.forName("oracle.jdbc.OracleDriver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError("Oracle JDBC driver not found: " + e.getMessage());
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
                value("crime.db.url", "CRIME_DB_URL", DEFAULT_URL),
                value("crime.db.user", "CRIME_DB_USER", DEFAULT_USER),
                value("crime.db.password", "CRIME_DB_PASSWORD", DEFAULT_PASSWORD)
        );
    }

    private static String value(String property, String environment, String fallback) {
        String configured = System.getProperty(property);
        if (configured == null || configured.isBlank()) {
            configured = System.getenv(environment);
        }
        return configured == null || configured.isBlank() ? fallback : configured;
    }
}
