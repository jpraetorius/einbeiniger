#!/bin/bash
thin -a 127.0.0.1 -R config.ru -e production -d -l /var/log/thin/thin.log -P /var/run/thin.pid -u app -g app start
