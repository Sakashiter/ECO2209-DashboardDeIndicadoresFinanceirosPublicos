package cache

import (
	"sync"
	"time"
)

type entry struct {
	value     any
	expiresAt time.Time
}

type Store struct {
	mu     sync.RWMutex
	values map[string]entry
}

func New() *Store {
	return &Store{
		values: make(map[string]entry),
	}
}

func Get[T any](store *Store, key string) (T, bool) {
	var zero T

	store.mu.RLock()
	item, ok := store.values[key]
	store.mu.RUnlock()

	if !ok || time.Now().After(item.expiresAt) {
		if ok {
			store.mu.Lock()
			delete(store.values, key)
			store.mu.Unlock()
		}

		return zero, false
	}

	value, ok := item.value.(T)

	if !ok {
		return zero, false
	}

	return value, true
}

func Set(store *Store, key string, value any, ttl time.Duration) {
	store.mu.Lock()

	store.values[key] = entry{
		value:     value,
		expiresAt: time.Now().Add(ttl),
	}

	store.mu.Unlock()
}
