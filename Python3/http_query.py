def http_query_header():
    try:
        headers_accept_encoding = ['gzip, deflate']    # 'Accept-Encoding': 'gzip, deflate'
        headers_accept_language = ['zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2']
        headers_accept = ['text/html,application/xhtml+xml,text/html,application/xhtml+xml,application/xml,*/*']    # 'Accept': '*/*'
        headers_connection = ['keep-alive']    # 'Connection': 'keep-alive'
        headers_ua = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36 Edg/93.0.961.38',
            'Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1',
            'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
        ]    # 'User-Agent': 'python-requests/2.24.0'
        header = {
            'User-Agent': headers_ua[random.randrange(0,len(headers_ua))],
            'Accept': headers_accept[random.randrange(0,len(headers_accept))],
            'Accept-Encoding': headers_accept_encoding[random.randrange(0,len(headers_accept_encoding))],
            'Accept-Language': headers_accept_language[random.randrange(0,len(headers_accept_language))],
            'Connection': headers_connection[random.randrange(0,len(headers_connection))],
            'Cache-Control': 'no-cache'
        }
        return header

    except Exception as Error:
        print ('[Error]: Some errors have occurred, please check the parameters .')

def http_query(http_query_url, http_query_data = 'text' ):
    try:
        http_requests = requests.get(http_query_url, headers=http_query_header())
        http_requests.encoding = http_requests.apparent_encoding
        if ( http_requests.status_code == int(200) ):
            if ( http_query_data == 'json' ):
                return http_requests.json()
            else:
                return http_requests.text
        else:
            return str(http_requests.status_code)

    except Exception as Error:
        print ('[Error]: Some errors have occurred, please check the parameters .')
