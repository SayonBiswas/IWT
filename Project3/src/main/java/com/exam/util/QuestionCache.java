package com.exam.util;

import java.util.*;
import java.util.concurrent.*;

public class QuestionCache {
    private static final int CACHE_SIZE = 100;
    private static final long CACHE_EXPIRY_MINUTES = 10;
    
    private static final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private static final ScheduledExecutorService cleanupExecutor = Executors.newSingleThreadScheduledExecutor();
    
    static {
        // Schedule periodic cache cleanup
        cleanupExecutor.scheduleAtFixedRate(QuestionCache::cleanupExpiredEntries, 
            CACHE_EXPIRY_MINUTES, CACHE_EXPIRY_MINUTES, TimeUnit.MINUTES);
    }
    
    private static class CacheEntry {
        final List<Map<String, Object>> questions;
        final long timestamp;
        
        CacheEntry(List<Map<String, Object>> questions) {
            this.questions = new ArrayList<>(questions); // Create a copy for thread safety
            this.timestamp = System.currentTimeMillis();
        }
        
        boolean isExpired() {
            return (System.currentTimeMillis() - timestamp) > (CACHE_EXPIRY_MINUTES * 60 * 1000);
        }
    }
    
    public static List<Map<String, Object>> get(String topic, int tid) {
        String key = topic + ":" + tid;
        CacheEntry entry = cache.get(key);
        
        if (entry != null && !entry.isExpired()) {
            return new ArrayList<>(entry.questions); // Return a copy to prevent modification
        }
        
        return null; // Cache miss or expired
    }
    
    public static void put(String topic, int tid, List<Map<String, Object>> questions) {
        String key = topic + ":" + tid;
        
        // Limit cache size
        if (cache.size() >= CACHE_SIZE) {
            cleanupExpiredEntries();
            if (cache.size() >= CACHE_SIZE) {
                // Remove oldest entry if still too large
                cache.remove(cache.keySet().iterator().next());
            }
        }
        
        cache.put(key, new CacheEntry(questions));
    }
    
    private static void cleanupExpiredEntries() {
        Iterator<Map.Entry<String, CacheEntry>> iterator = cache.entrySet().iterator();
        while (iterator.hasNext()) {
            Map.Entry<String, CacheEntry> entry = iterator.next();
            if (entry.getValue().isExpired()) {
                iterator.remove();
            }
        }
    }
    
    public static void clear() {
        cache.clear();
    }
    
    public static int size() {
        return cache.size();
    }
}