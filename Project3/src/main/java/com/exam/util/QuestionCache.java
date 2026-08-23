package com.exam.util;

import java.util.*;
import java.util.concurrent.*;

public class QuestionCache {
    private static final int  CACHE_SIZE           = 100;
    private static final long CACHE_EXPIRY_MINUTES = 10;

    private static final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private static final ScheduledExecutorService cleanupExecutor =
            Executors.newSingleThreadScheduledExecutor();

    static {
        cleanupExecutor.scheduleAtFixedRate(
                QuestionCache::cleanupExpiredEntries,
                CACHE_EXPIRY_MINUTES, CACHE_EXPIRY_MINUTES, TimeUnit.MINUTES);
    }

    private static class CacheEntry {
        final List<Map<String, Object>> questions;
        final long timestamp;

        CacheEntry(List<Map<String, Object>> questions) {
            this.questions = new ArrayList<>(questions);
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
            System.out.println("[QuestionCache] Cache HIT for key: " + key + ", returning " + entry.questions.size() + " questions");
            return new ArrayList<>(entry.questions);
        }
        System.out.println("[QuestionCache] Cache MISS for key: " + key);
        return null;
    }

    public static void put(String topic, int tid, List<Map<String, Object>> questions) {
        String key = topic + ":" + tid;
        if (cache.size() >= CACHE_SIZE) {
            cleanupExpiredEntries();
            if (cache.size() >= CACHE_SIZE) {
                cache.remove(cache.keySet().iterator().next());
            }
        }
        cache.put(key, new CacheEntry(questions));
        System.out.println("[QuestionCache] Cached " + questions.size() + " questions for key: " + key);
    }

    // FIX: New method — called by AIUtils before regenerating questions for
    // a topic that already exists. Without this, exam.jsp would keep serving
    // the old cached questions even after AIUtils inserted fresh ones.
    public static void invalidate(String topic, int tid) {
        String key = topic + ":" + tid;
        cache.remove(key);
        System.out.println("[QuestionCache] Invalidated cache for key: " + key);
    }

    private static void cleanupExpiredEntries() {
        Iterator<Map.Entry<String, CacheEntry>> it = cache.entrySet().iterator();
        while (it.hasNext()) {
            if (it.next().getValue().isExpired()) it.remove();
        }
    }

    public static void clear() {
        cache.clear();
    }

    public static int size() {
        return cache.size();
    }
}