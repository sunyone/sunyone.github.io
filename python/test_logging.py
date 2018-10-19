#!/usr/bin/env python
#coding=utf-8
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import os
import logging.config


class Logger():
    def __init__(self):
        # 定义三种日志输出格式 开始
        self.standard_format = '[%(asctime)s][%(threadName)s:%(thread)d][task_id:%(name)s][%(filename)s:%(lineno)d]' \
                  '[%(levelname)s][%(message)s]' #其中name为getlogger指定的名字
        self.simple_format = '[%(levelname)s][%(asctime)s][%(filename)s:%(lineno)d]%(message)s'
        self.id_simple_format = '[%(levelname)s][%(asctime)s] %(message)s'
        # 定义日志输出格式 结束

        self.logfile_dir = os.path.dirname(os.path.abspath(__file__)) + '/log' # log文件的目录
        self.logfile_name = 'all2.log'  # log文件名

        # 如果不存在定义的日志目录就创建一个
        if not os.path.isdir(self.logfile_dir):
            os.mkdir(self.logfile_dir)
        # log文件的全路径
        self.logfile_path = os.path.join(self.logfile_dir, self.logfile_name)
        print(self.logfile_path)

        # log配置字典
        self.logging_dic = {
            'version': 1,
            'disable_existing_loggers': False,
            'formatters': {
                'standard': {'format': self.standard_format},
                'simple': {'format': self.simple_format},
                },
            'filters': {},
            'handlers': {
                #打印到终端的日志
                'console': {
                    'level': 'DEBUG',
                    'class': 'logging.StreamHandler',  # 打印到屏幕
                    'formatter': 'simple'
                    },

                #打印到文件的日志,收集info及以上的日志
                'default': {
                    'level': 'DEBUG',
                    'class': 'logging.handlers.RotatingFileHandler', # 保存到文件
                    'formatter': 'standard',
                    'filename': self.logfile_path,  # 日志文件
                    'maxBytes': 1024*5,  # 日志大小 5K
                    'backupCount': 5,
                    'encoding': 'utf-8',  # 日志文件的编码
                    },
                },
            'loggers': {
                #logging.getLogger(__name__)拿到的logger配置
                '': {
                    'handlers': ['default', 'console'],  # 这里把上面定义的两个handler都加上，即log数据既写入文件又打印到屏幕
                    'level': 'DEBUG',
                    'propagate': True,  # 向上（更高level的logger）传递
                    },
                },
            }

    def msg(self, msg, file_num):
        self.file_num = file_num
        logging.config.dictConfig(self.logging_dic)  # 导入上面定义的logging配置
        logger = logging.getLogger(__name__)  # 生成一个log实例
        logger.info('[' + str(self.file_num) + ']' + msg)  # 记录该文件的运行状态

if __name__ == '__main__':
    logger = Logger()
    logger.msg('sssss', sys._getframe().f_lineno)

