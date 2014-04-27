
from scrapy.selector import Selector
from scrapy.spider import Spider
from scrapy.http import Request

from selenium import webdriver
import time
from market_scrapy.items import MarketScrapyItem

class TescoSpider(Spider):
    name = 'tesco'
    allowed_domains = ['cn.tesco.com']
    start_urls = [ 
        'http://www.cn.tesco.com/StoresInformation.html?pid=124',
        'http://www.cn.tesco.com/StoresInformation.html?pid=100', 
    ]

    def __init__(self):
        Spider.__init__(self)
        self.verificationErrors = []
        self.driver = webdriver.Firefox() 
    
    def __del__(self):
        self.driver.quit()
        print self.verificationErrors
        Spider.__del__(self)

    def parse(self, response):
         self.driver.get(response.url)

         if self.driver: time.sleep(3)   

         item = MarketScrapyItem()
         #item['name'] = 'test'
         item['name'] = self.driver.find_element_by_id('mdname').text.encode('utf-8')
         item['bus'] = self.driver.find_element_by_id('inforBody').text.encode('utf-8')
         return item 

