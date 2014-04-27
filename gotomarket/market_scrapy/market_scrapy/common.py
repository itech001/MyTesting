
import urllib

def download_image(url,file):
  urllib.urlretrieve(url, file)
