#!/usr/bin/env python
#coding=utf-8
import sys
reload(sys)
sys.setdefaultencoding('utf-8')


import requests
import re

class SparkTools(object):
    def __init__(self, rm_urls, app_name):
        self.__rm_urls = rm_urls
        self.__app_name = app_name

    def getHref(self):
        header = {"Accept": "application/json"}

        for rm_url in self.__rm_urls:
            apiurl = rm_url + '/ws/v1/cluster/info'

            try:
                r = requests.get(url=apiurl, headers=header, verify=False)
                r.raise_for_status()
            except requests.RequestException as e:
                #print(e)
                pass
            else:
                uri = rm_url
                return uri

    def getAppId(self):
        uri = self.getHref()
        if uri:
            apiurl = uri + '/ws/v1/cluster/apps/?state=RUNNING&user=yuemeqoe'
            header = {"Accept": "application/json"}

            try:
                r = requests.get(url=apiurl, headers=header, verify=False)
                r.raise_for_status()
            except requests.RequestException as e:
                #print(e)
                return False
            else:
                result = r.json()
                a=result["apps"]["app"]
                app_id = [i["id"] for i in result["apps"]["app"] if i["name"] in self.__app_name]
                return app_id[0]
        else:
            print "uri is None!"
            exit()

    def getSparkStreamInfo(self):
        app_id = self.getAppId()
        sparkStr = "http://172.16.64.101:8088"

        re_data = re.compile(r'Avg:\s+(\S+)?\s+events\/sec')
        #re_delay = re.compile(r'Avg:\s+(\d+)\s+seconds?\s+(\d+)\s+ms')
        re_delay = re.compile(ur'Avg:\s+(?:(\d+)\s+hours?\s+)?(?:(\d+)\s+minutes?\s+)?(?:(\d+)\s+seconds?\s+)?(\d+)\s+ms')
        #<div>Avg: 1 second 820 ms</div>
        #<div>Avg: 14 seconds 181 ms</div>
        #<div>Avg: 16 seconds 3 ms</div>
        #<div>Avg: 2 minutes 1 second 820 ms</div>
        #<div>Avg: 1 hour 2 minutes 1 second 820 ms</div>

        apiurl = sparkStr + '/proxy/' + app_id + '/streaming'
        header = {"Accept": "application/json"}

        try:
            r = requests.get(url=apiurl, headers=header, verify=False)
            r.raise_for_status()
        except requests.RequestException as e:
            #print(e)
            return False
        else:
            result = r.text
            #result = result + '\n<div>Avg: 820 ms</div>'
            #print result

        datas = []
        my_data=re.search(re_data, result)
        if my_data:
            input_rate = my_data.group(1)
            #print "%s: input_rate=%s events/sec" %(app_id, input_rate)
        else:
            print "input_rate=0"
        datas.append(input_rate)


        data_delay=re.findall(re_delay, result)
        if len(data_delay) == 3:
            #print data_delay
            for i in data_delay:
                delay_h, delay_m, delay_sec, delay_ms = i
                if delay_h   == '': delay_h   = 0
                if delay_m   == '': delay_m   = 0
                if delay_sec == '': delay_sec = 0
                if delay_ms  == '': delay_ms  = 0
                delay = (int(delay_h)*3600 + int(delay_m)*60 + int(delay_sec))*1000 + int(delay_ms)
                #print "%s: delay=%s ms" %(app_id, delay)
                datas.append(delay)
            input_rate, scheduling_delay, processing_time, total_delay = datas
        else:
            print "%s: delay is None" %app_id
        return {"input_rate":input_rate, "scheduling_delay":scheduling_delay, "processing_time":processing_time, "total_delay":total_delay}

        #try:
        #    bsObj = BeautifulSoup(result, 'html.parser')
        #    print bsObj.prettify()
        #    #href  = bsObj.findAll("a",{"href":re.compile("^http:.*")},text=app_id)[0].attrs["href"]
        #
        #except Exception ,e :
        #    print "解析标签出错",str(e)


if __name__ == '__main__':
    rm_urls = ["http://172.16.64.100:8088", "http://172.16.64.101:8088"]    #ResourceManager服务主、备地址
    #应用名称列表
    app_names = ("yme_cleaner_all", "yme_cleaner_bj", "kafkatoHDFS", "Recorddata_onlyTokafka", "Singleuser_onlytokafka", "OfflineCountAreaKpiHour", "OfflineCountAreaKpiDay", "OfflineCountAreaKpiMonth")

    for app_name in app_names:
        a=SparkTools(rm_urls, app_name)
        b=a.getSparkStreamInfo()
        print "%s: %s" %(app_name, b)