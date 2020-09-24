hiware eq add

    OS - UBUNTU , CENTOS
    ENV - Server

1. write list.txt (hostname IP  OS  ENV)

    ex) engine49.listingsearch.nd.wemakeprice.org       172.21.7.163    UBUNTU  PROD


2. start eq_add.py

or

1. curl http://wcloud01.sys.common.wemakeprice.org:9090/eq_add/{hostname}/{ipaddr}/{os}/{env}


#########################################################


hiware eq check

1. curl http://wcloud01.sys.common.wemakeprice.org:9090/eq_check/{hostname}


#########################################################


hiware eq delete

1. curl http://wcloud01.sys.common.wemakeprice.org:9090/eq_delete/{hostname}


#########################################################
