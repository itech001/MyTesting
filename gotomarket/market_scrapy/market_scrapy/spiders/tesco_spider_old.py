
from scrapy.selector import Selector
from scrapy.spider import Spider
from scrapy.http import Request
from market_scrapy.items import MarketScrapyItem

class TescoSpider(Spider):
     name = 'tesco_old'
     allowed_domains = ['cn.tesco.com']
     start_urls = [ 
         'http://www.cn.tesco.com/StoresInformation.html?pid=124',
         'http://www.cn.tesco.com/StoresInformation.html?pid=100', 
     ]

     def parse(self, response):
         sel = Selector(response)

         item = MarketScrapyItem()
         #item['name'] = 'test'
         item['name'] = sel.re('id=\"mdname\"(.*?)</span')
         item['bus'] = sel.re('id=\"inforBody\".*')
         return item 

