package com.exam.util;

import java.sql.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.logging.*;

public class DBConnectionPool {
    private static final Logger logger = Logger.getLogger(DBConnectionPool.class.getName());
    
    private static String dbUrl;
    private static String user;
    private static String pass;
    
    private static final int MAX_POOL_SIZE = 10;
    private static final BlockingQueue<Connection> connectionPool = new LinkedBlockingQueue<>(MAX_POOL_SIZE);
    private static final Set<Connection> activeConnections = ConcurrentHashMap.newKeySet();
    
    static {
        initializePool();
    }
    
    private static void initializePool() {
        try {
            // Load the PostgreSQL Driver
            Class.forName("org.postgresql.Driver");
            
            // Read environment variables
            String envUrl = System.getenv("DB_URL");
            String envUser = System.getenv("DB_USER");
            String envPass = System.getenv("DB_PASSWORD");
            
            // Use env variables when hosted, fallback to local for development
            dbUrl = (envUrl != null) ? envUrl : "jdbc:postgresql://localhost:5432/Project";
            user = (envUser != null) ? envUser : "postgres";
            pass = (envPass != null) ? envPass : "fake_local_password";
            
            logger.info("[DBConnectionPool] Initialized with URL: " + dbUrl);
            
        } catch (ClassNotFoundException e) {
            logger.log(Level.SEVERE, "[DBConnectionPool] Failed to load PostgreSQL driver", e);
        }
    }
    
    public static Connection getConnection() throws SQLException {
        try {
            // Try to get an existing connection from the pool
            Connection conn = connectionPool.poll();
            
            if (conn != null) {
                // Validate that the connection is still alive
                if (conn.isValid(2)) {
                    activeConnections.add(conn);
                    logger.fine("[DBConnectionPool] Reusing connection from pool. Active: " + activeConnections.size());
                    return conn;
                } else {
                    // Connection is stale, close it and create a new one
                    try {
                        conn.close();
                    } catch (SQLException e) {
                        logger.warning("[DBConnectionPool] Failed to close stale connection");
                    }
                }
            }
            
            // Create a new connection if pool is empty or connection was stale
            if (activeConnections.size() < MAX_POOL_SIZE) {
                Connection newConn = DriverManager.getConnection(dbUrl, user, pass);
                activeConnections.add(newConn);
                logger.fine("[DBConnectionPool] Created new connection. Active: " + activeConnections.size());
                return newConn;
            } else {
                // Wait for a connection to become available
                logger.warning("[DBConnectionPool] Pool exhausted, waiting for available connection");
                conn = connectionPool.take();
                if (conn.isValid(2)) {
                    activeConnections.add(conn);
                    return conn;
                } else {
                    try {
                        conn.close();
                    } catch (SQLException e) {
                        logger.warning("[DBConnectionPool] Failed to close stale connection");
                    }
                    return getConnection(); // Retry
                }
            }
            
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new SQLException("Interrupted while waiting for database connection", e);
        }
    }
    
    public static void releaseConnection(Connection conn) {
        if (conn != null) {
            try {
                activeConnections.remove(conn);
                if (conn.isValid(2) && connectionPool.size() < MAX_POOL_SIZE) {
                    connectionPool.offer(conn);
                    logger.fine("[DBConnectionPool] Returned connection to pool. Pool size: " + connectionPool.size());
                } else {
                    conn.close();
                    logger.fine("[DBConnectionPool] Closed connection. Pool size: " + connectionPool.size());
                }
            } catch (SQLException e) {
                logger.warning("[DBConnectionPool] Error releasing connection: " + e.getMessage());
                try {
                    conn.close();
                } catch (SQLException ex) {
                    logger.warning("[DBConnectionPool] Failed to close connection during error: " + ex.getMessage());
                }
            }
        }
    }
    
    public static void closeAllConnections() {
        logger.info("[DBConnectionPool] Closing all connections");
        
        // Close all active connections
        for (Connection conn : activeConnections) {
            try {
                conn.close();
            } catch (SQLException e) {
                logger.warning("[DBConnectionPool] Failed to close active connection: " + e.getMessage());
            }
        }
        activeConnections.clear();
        
        // Close all pooled connections
        Connection conn;
        while ((conn = connectionPool.poll()) != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                logger.warning("[DBConnectionPool] Failed to close pooled connection: " + e.getMessage());
            }
        }
        
        logger.info("[DBConnectionPool] All connections closed");
    }
    
    public static int getActiveConnectionCount() {
        return activeConnections.size();
    }
    
    public static int getPoolSize() {
        return connectionPool.size();
    }
}