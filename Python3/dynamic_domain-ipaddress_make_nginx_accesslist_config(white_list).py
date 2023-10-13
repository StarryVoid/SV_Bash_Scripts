#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#
# Dynamic IPAddress Make Nginx Access Config (White List)
#
# Author: StarryVoid <stars@starryvoid.com>
# Intro:  https://blog.starryvoid.com/archives/585.html
# Build:  2021/03/23 Version 1.1.1.1
#
# Operating Environment "Python3.6+ dnspython"
# Install Command "pip3 install dnspython"
# About "dnspython" https://github.com/rthalley/dnspython https://dnspython.readthedocs.io/en/latest/
# About "ngx_http_access_module" http://nginx.org/en/docs/http/ngx_http_access_module.html

import sys,dns.resolver,subprocess

### Config Start ###

# Default Input File ./dns_read_list.txt
# One line of the configuration file is like "www.google.com#8.8.8.8#A#216.58.197.196#Annotation"
# You can use commands like this to generate sample files " echo -e 'domain1#dnsserver1#A#ipaddress_old1#Annotation1\ndomain2#dnsserver2#A#ipaddress_old2#Annotation2' "
Input_file_path = "./dns_read_list.txt"

# Default Output File ./nginx_access_whitelist.conf
# One line of the output file is like "Allow 216.58.197.196/32;"
# There is an extra rule at the end of the configuration file "deny all;"
# And automatically reload the Nginx service "systemctl reload nginx.service"
Output_file_path = "./nginx_access_whitelist.conf"
Auto_Reload_Command = "systemctl reload nginx.service"

# (bool)Read Your Linux System File '/etc/resolv.conf' , Default is '0' , DNSPython default is '1' .
# If the '/etc/resolv.conf' file of your Linux server is damaged, Please configure to ‘0’ to disable this option to prevent errors
# The errors result during the test is like this "dns.resolver.NoResolverConfiguration: Resolver configuration could not be read or specified no nameservers."
DNS_Read_System_Config = "0"

# (str/None)Your Network Drive Bind Address , Default is "None" , Change to "str('127.0.0.1')"
DNS_Query_Source_Address = None

# (list)Extended DNS server for additional queries , Default is "['8.8.8.8','1.1.1.1','114.114.114.114']"
# When there is a DNS query error, you can select other public servers to query 
DNS_Query_Server_Expand = ['8.8.8.8','1.1.1.1','114.114.114.114']

### Config End ###

### Script start ###

def DNS_Query(domain_name,dns_server,domain_type,source_address):
    try:
        DNS_Resolver = dns.resolver.Resolver(configure=bool(DNS_Read_System_Config))
        DNS_Resolver.port = int("53")
        DNS_Resolver.timeout = float("1.0")
        DNS_Resolver.lifetime = float("5.0")
        DNS_Resolver.nameservers = list(str(dns_server).split('#'))+list(DNS_Query_Server_Expand)
        DNS_Response = sorted(answer.split(" ")[4].strip(".").lower() for answer in DNS_Resolver.resolve(str(domain_name),rdtype=str(domain_type),source=source_address).response.answer[-1].to_text().split("\n"))
        return DNS_Response[0]
        """
        Other data processing methods 
        
        DNS_Answer_List=list()
        DNS_Answer_List_Rdata = DNS_Resolver.resolve(str(domain_name),str(domain_type))
        for rdata in DNS_Answer_List_Rdata:
            DNS_Answer_List.append(str(rdata))                              #IP
            #DNS_Answer_List.append(str(rdata.target).strip(".").lower())    #CNAME
        return tuple(DNS_Answer_List)
        """
        """
        DNS_Answer_List=tuple()
        DNS_Answer_List_RRset = DNS_Resolver.resolve(str(domain_name),str(domain_type))
        for rrset in DNS_Answer_List_RRset.response.answer:
            for i in rrset.items:
                print(i.to_text())
                DNS_Answer_List.append(str(i.to_text()).strip(".").lower())
        return tuple(DNS_Answer_List)
        """
    except Exception as Error:
        print (domain_name,domain_type,'Error: unable to start def \"DNS_Query\"')

def main():
    try:
        Input_tmp_data = []
        Output_tmp_data = []
        Difference_Status = int(0)
        #
        with open(str(Input_file_path), "r") as r_file:
            r_file_lines = r_file.readlines()
        #
        for r_line in r_file_lines:
            #r_line="www.google.com#8.8.8.8#A#216.58.197.196#Annotation"
            DNS_query_info = str(r_line).split('#')
            DNS_query_info[-1] = DNS_query_info[-1].replace('\n', '').replace('\r', '')
            #print("Inf1",DNS_query_info)
            Old_DNS_Answer=DNS_query_info[3].strip()
            New_DNS_Answer=DNS_Query(DNS_query_info[0].strip(),DNS_query_info[1].strip(),DNS_query_info[2].strip(),DNS_Query_Source_Address)
            if str(New_DNS_Answer) == "None" :
                New_DNS_Answer=Old_DNS_Answer
            #print("Inf2",DNS_query_info)
            #print("Old",Old_DNS_Answer)
            #print("New",New_DNS_Answer)
            if str(New_DNS_Answer.strip()) != str(Old_DNS_Answer.strip()) :
                Difference_Status+=1
                DNS_query_info[3] = str(New_DNS_Answer)
                #print("Inf3",DNS_query_info)
            Input_tmp_data.append(str("#".join(DNS_query_info)))
            Output_tmp_data.append("allow " + str(New_DNS_Answer) + "/32;")
            #print(New_DNS_Answer,Old_DNS_Answer,"Num =",Difference_Status)
        Input_tmp_data.append('\n')
        Output_tmp_data.append('deny all;\n')
        #
        if bool(Difference_Status) :
            #print("O1",Input_tmp_data)
            #print("O2",Output_tmp_data)
            with open(str(Input_file_path), "w+") as w_file_output:
                w_file_output.write("\n".join(Input_tmp_data))
            with open(str(Output_file_path), "w+") as w_file_input:
                w_file_input.write("\n".join(Output_tmp_data))
            subprocess.Popen(str(Auto_Reload_Command),shell=True).returncode
    #
    except Exception as Error:
        print ('[Error]: Some errors have occurred, please check the configuration file.')

### Script end ###

if __name__ == "__main__":
    main()
