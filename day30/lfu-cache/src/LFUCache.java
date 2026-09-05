import java.util.*;

class LFUCache {
    // 1. 存储 key 到 value 的映射
    Map<Integer, Integer> keyToVal;
    // 2. 存储 key 到 频率的映射
    Map<Integer, Integer> keyToFreq;
    // 3. 存储 每个频率 对应的 key 列表 (LinkedHashSet 保证了同频率下按时间顺序排序)
    Map<Integer, LinkedHashSet<Integer>> freqToKeys;

    int capacity;
    int minFreq; // 记录当前最小的频率，用于淘汰

    public LFUCache(int capacity) {
        this.capacity = capacity;
        this.minFreq = 0;
        this.keyToVal = new HashMap<>();
        this.keyToFreq = new HashMap<>();
        this.freqToKeys = new HashMap<>();
    }

    public int get(int key) {
        if (!keyToVal.containsKey(key)) return -1;

        // 增加该 key 的频率
        updateFreq(key);
        return keyToVal.get(key);
    }

    public void put(int key, int value) {
        if (capacity <= 0) return;

        if (keyToVal.containsKey(key)) {
            keyToVal.put(key, value);
            updateFreq(key);
            return;
        }

        if (keyToVal.size() >= capacity) {
            // 淘汰频率最低且最旧的 key
            evict();
        }

        // 插入新 key
        keyToVal.put(key, value);
        keyToFreq.put(key, 1);
        freqToKeys.computeIfAbsent(1, k -> new LinkedHashSet<>()).add(key);
        minFreq = 1; // 新插入的频率肯定是 1
    }

    // 核心函数：更新 key 的频率
    private void updateFreq(int key) {
        int freq = keyToFreq.get(key);
        keyToFreq.put(key, freq + 1);

        // 从旧频率列表中移除
        freqToKeys.get(freq).remove(key);

        // 如果旧频率是最小频率，且移除后该频率列表空了，则更新最小频率
        if (freq == minFreq && freqToKeys.get(freq).isEmpty()) {
            minFreq++;
        }

        // 加入新频率列表
        freqToKeys.computeIfAbsent(freq + 1, k -> new LinkedHashSet<>()).add(key);
    }

    // 淘汰操作
    private void evict() {
        // 找到最小频率列表里的第一个元素（最旧的）
        LinkedHashSet<Integer> keys = freqToKeys.get(minFreq);
        int oldestKey = keys.iterator().next();

        // 同步删除
        keys.remove(oldestKey);
        keyToVal.remove(oldestKey);
        keyToFreq.remove(oldestKey);
    }
}