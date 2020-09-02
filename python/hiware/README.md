hiware eq add

1. write list.txt (hostname     IP      OS      ENV)

    ex) engine49.listingsearch.nd.wemakeprice.org       172.21.7.163    UBUNTU  PROD

    OS - UBUNTU , CENTOS
    ENV - DEV , QA , STG/PERF , PROD , V-DEV , V-QA , V-STG-A , V-STG-B/PERF , V-PROD-A , V-PROD-B , V-PROD-C

2. start hiware.py



#########################################################


hiware eq delete

1. curl http://wcloud01.sys.common.wemakeprice.org:9090/hiware_delete/{hostname}
