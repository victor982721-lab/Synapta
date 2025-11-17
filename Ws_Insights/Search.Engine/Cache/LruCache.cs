using System.Collections.Generic;

namespace Ws_Insights.Search.Cache
{
    /// <summary>
    /// A simple least-recently-used cache.  Items are evicted when the cache exceeds a maximum
    /// number of entries.  This implementation uses a dictionary and linked list.  It is not
    /// thread-safe and is intended only as a placeholder for a more efficient LRU implementation.
    /// </summary>
    public class LruCache<TKey, TValue>
    {
        private readonly int _capacity;
        private readonly Dictionary<TKey, LinkedListNode<(TKey Key, TValue Value)>> _map;
        private readonly LinkedList<(TKey Key, TValue Value)> _list;

        public LruCache(int capacity)
        {
            _capacity = capacity;
            _map = new Dictionary<TKey, LinkedListNode<(TKey, TValue)>>();
            _list = new LinkedList<(TKey, TValue)>();
        }

        public bool TryGet(TKey key, out TValue value)
        {
            if (_map.TryGetValue(key, out var node))
            {
                value = node.Value.Value;
                _list.Remove(node);
                _list.AddFirst(node);
                return true;
            }
            value = default!;
            return false;
        }

        public void Put(TKey key, TValue value)
        {
            if (_map.TryGetValue(key, out var node))
            {
                _list.Remove(node);
            }
            else if (_map.Count >= _capacity)
            {
                var last = _list.Last;
                if (last != null)
                {
                    _map.Remove(last.Value.Key);
                    _list.RemoveLast();
                }
            }
            var newNode = new LinkedListNode<(TKey, TValue)>((key, value));
            _list.AddFirst(newNode);
            _map[key] = newNode;
        }
    }
}