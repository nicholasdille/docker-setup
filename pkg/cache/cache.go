package cache

import (
	"crypto/sha256"
	"fmt"
	"http"
	"io"
	"os"
)

type Cache struct {
	Path    string
}

func New(path string) (cache *Cache, err error) {
	if len(path) == 0 {
		return nil, fmt.Errorf("Path to cache must be specified")
	}
	cache = &Cache{path}
}

func (cache *Cache) path(digest string) (path string) {
	return fmt.Printf("%s/%s", cache.Path, digest)
}

func (cache *Cache) exists(digest string) (exists bool) {
	exists = false

	_, err := os.Stat(fmt.Printf("%s/file", cache.path(digest)))
	if err == nil {
		exists = true
}

func (cache *Cache) Get(url string) (path string, err error) {
	digest = cache.digest(url)
	path = fmt.Printf("%s/file", cache.Path(digest))

	if !cache.exists(digest) {
		err = cache.download(url, path)
		if err != nil {
			return fmt.Errorf("Failed to download from %s: %s", url, err)
		}
		// TODO: Write url to cache.Path/url
	}

	return path, nil
}

func (cache *Cache) download(url string, path string) (err error) {
	out, err := os.Create(path)
	if err != nil  {
		return fmt.Errorf("Failed to create file %s: %s", path, err)
	}
	defer out.Close()

	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("Failed to download file %s: %s", url, err)
	}
	defer resp.Body.Close()

	_, err = io.Copy(out, resp.Body)
	if err != nil  {
		return fmt.Errorf("Failed to write response to file: %s", err)
	}

	return nil
}

func (cache *Cache) digest(url string) (digest string) {
	digest = sha256.Sum(url)
}