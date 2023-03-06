import bs4
import re

URIEL_GETPAGE  = 0x10
URIEL_NAVBACK  = 0x11
URIEL_NAVFWD   = 0x12
URIEL_STR_SIZE = 144
URIEL_THUMB    = 0x13
URIEL_WEBM     = 0x14

class Uriel:
    download_buffer = ''
    user_agent = ''
    history = []
    nav_index = -1
    class rel:
        scheme = ''
        netloc = ''
        path = ''

def uriel(data):
    if data == URIEL_GETPAGE:
        UrielGetPage()
    if data == URIEL_NAVBACK:
        UrielNavBack()
    if data == URIEL_NAVFWD:
        UrielNavFwd()
    if data == URIEL_THUMB:
        UrielThumb()
    if data == URIEL_WEBM:
        UrielWebM()

def UrielGetPage():
    global Uriel
    os.lseek(HGBD,0,os.SEEK_SET)
    HGBD_PARAM_BUF = os.read(HGBD,BLK_SIZE)
    os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
    HGBD_URL_BUF = os.read(HGBD,BLK_SIZE*4)
    if Uriel.user_agent == '':
        Uriel.user_agent = HGBD_PARAM_BUF[:HGBD_PARAM_BUF.find('\x00')]
    url_comp = urlparse.urlparse(HGBD_URL_BUF[:HGBD_URL_BUF.find('\x00')])
    scheme = ''
    netloc = ''
    path = ''
    if url_comp.scheme == '':
        scheme = Uriel.rel.scheme
    else:
        scheme = url_comp.scheme
        Uriel.rel.scheme = url_comp.scheme
    if url_comp.netloc == '':
        netloc = Uriel.rel.netloc
    else:
        netloc = url_comp.netloc
        Uriel.rel.netloc = url_comp.netloc

    if url_comp.path != '':
        if url_comp.path.find('/') != -1:
            if url_comp.scheme == '' or url_comp.netloc == '':
                if url_comp.path[:1] != '/':
                    path = Uriel.rel.path + url_comp.path
                    Uriel.rel.path += url_comp.path[:url_comp.path.rfind('/')+1]
                else:
                    path = url_comp.path
                    Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
            else:
                path = url_comp.path
                Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
        else:
            path = Uriel.rel.path + url_comp.path

    post_scheme = netloc + "/" + urllib.quote(path)
    post_scheme = post_scheme.replace('//','/')
    if url_comp.query != '':
        post_scheme += '?'+url_comp.query
    url = scheme + "://" + post_scheme
    pagereq = subprocess.Popen('wget -O - -U "' + Uriel.user_agent + '" "' + url + '"', shell=True, stdin=subprocess.PIPE, stderr=subprocess.PIPE, stdout=subprocess.PIPE).communicate()
    pagedata = pagereq[0]
    pagehdrs = pagereq[1].split('\n')
    filedata = UrielPreProcess(pagedata, url)
    filesize = len(filedata)
    if filesize>0:
        if filedata.find('$AN,"",A="BINARY"$') != -1:
            Uriel.download_buffer = pagedata
            if url[-2:].upper()==".Z":
                tmp_z_file = "/tmp/" + str(uuid.uuid4()).split('-')[0].upper() + ".Z"
                while os.path.exists(tmp_z_file):
                    tmp_z_file = "/tmp/" + str(uuid.uuid4()).split('-')[0].upper() + ".Z"
                open(tmp_z_file,"wb").write(pagedata)
                try:
                    os.system('tosz "' + tmp_z_file + '"')
                    pagedata = open(tmp_z_file.split('.Z')[0],"rb").read()
                    os.remove(tmp_z_file.split('.Z')[0])
                    Uriel.download_buffer = pagedata
                except:
                    Uriel.download_buffer = ''
            ZeroParamBuf()
            os.lseek(HGBD,0,os.SEEK_SET)
            os.write(HGBD,str(len(Uriel.download_buffer)))
            os.lseek(HGBD,128,os.SEEK_SET)
            os.write(HGBD,"download://"+'\x00')
            os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
            os.write(HGBD,Uriel.download_buffer)
            logger.info("[Uriel] copy to download buffer " + url)
        else:
            for p_hdr in pagehdrs:
                if p_hdr.lower().find('location: ') != -1:
                    if p_hdr.lower().find('[following]') != -1:
                        url_comp = urlparse.urlparse(p_hdr[p_hdr.lower().find('location: ')+10:p_hdr.lower().find('[following]')].strip())
                        scheme = ''
                        netloc = ''
                        path = ''
                        if url_comp.scheme == '':
                            scheme = Uriel.rel.scheme
                        else:
                            scheme = url_comp.scheme
                            Uriel.rel.scheme = url_comp.scheme
                        if url_comp.netloc == '':
                            netloc = Uriel.rel.netloc
                        else:
                            netloc = url_comp.netloc
                            Uriel.rel.netloc = url_comp.netloc
                        if url_comp.path != '':
                            if url_comp.path.find('/') != -1:
                                if url_comp.scheme == '' or url_comp.netloc == '':
                                    if url_comp.path[:1] != '/':
                                        path = Uriel.rel.path + url_comp.path
                                        Uriel.rel.path += url_comp.path[:url_comp.path.rfind('/')+1]
                                    else:
                                        path = url_comp.path
                                        Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
                                else:
                                    path = url_comp.path
                                    Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
                            else:
                                path = Uriel.rel.path + url_comp.path
                        post_scheme = netloc + "/" + urllib.quote(path)
                        post_scheme = post_scheme.replace('//','/')
                        if url_comp.query != '':
                            post_scheme += '?'+url_comp.query
                        url = scheme + "://" + post_scheme
            Uriel.nav_index += 1
            Uriel.history = Uriel.history[0:Uriel.nav_index]
            Uriel.history.append({'url':url, 'filedata':filedata})
            ZeroParamBuf()
            os.lseek(HGBD,0,os.SEEK_SET)
            os.write(HGBD,str(filesize))
            os.lseek(HGBD,128,os.SEEK_SET)
            os.write(HGBD,str(url)[:URIEL_STR_SIZE])
            os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
            os.write(HGBD,filedata)
            logger.info("[Uriel] navigate to " + url)
    else:
        filesize = -1
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        logger.error("[Uriel] error reading url " + url)
    conn.send(chr(URIEL_GETPAGE))

def UrielNavBack():
    global Uriel
    if Uriel.nav_index > 0:
        Uriel.nav_index -= 1
    url_comp = urlparse.urlparse(Uriel.history[Uriel.nav_index]['url'])
    filedata = Uriel.history[Uriel.nav_index]['filedata']
    scheme = ''
    netloc = ''
    path = ''
    if url_comp.scheme == '':
        scheme = Uriel.rel.scheme
    else:
        scheme = url_comp.scheme
    if url_comp.netloc == '':
        netloc = Uriel.rel.netloc
    else:
        netloc = url_comp.netloc

    if url_comp.path != '':
        if url_comp.path.find('/') != -1:
            if url_comp.scheme == '' or url_comp.netloc == '':
                if url_comp.path[:1] != '/':
                    path = Uriel.rel.path + url_comp.path
                    Uriel.rel.path += url_comp.path[:url_comp.path.rfind('/')+1]
                else:
                    path = url_comp.path
                    Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
            else:
                path = url_comp.path
                Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
        else:
            path = Uriel.rel.path + url_comp.path

    post_scheme = netloc + "/" + urllib.quote(path)
    post_scheme = post_scheme.replace('//','/')
    if url_comp.query != '':
        post_scheme += '?'+url_comp.query
    url = scheme + "://" + post_scheme
    filesize = len(filedata)
    if filesize>0:
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        os.lseek(HGBD,128,os.SEEK_SET)
        os.write(HGBD,str(url)[:URIEL_STR_SIZE])
        os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
        os.write(HGBD,filedata)
        logger.info("[Uriel] history navigate back to " + url)
    else:
        filesize = -1
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        logger.error("[Uriel] error reading history for url " + url)
    conn.send(chr(URIEL_NAVBACK))

def UrielNavFwd():
    global Uriel
    if Uriel.nav_index < len(Uriel.history)-1:
        Uriel.nav_index += 1
    url_comp = urlparse.urlparse(Uriel.history[Uriel.nav_index]['url'])
    filedata = Uriel.history[Uriel.nav_index]['filedata']
    scheme = ''
    netloc = ''
    path = ''
    if url_comp.scheme == '':
        scheme = Uriel.rel.scheme
    else:
        scheme = url_comp.scheme
    if url_comp.netloc == '':
        netloc = Uriel.rel.netloc
    else:
        netloc = url_comp.netloc

    if url_comp.path != '':
        if url_comp.path.find('/') != -1:
            if url_comp.scheme == '' or url_comp.netloc == '':
                if url_comp.path[:1] != '/':
                    path = Uriel.rel.path + url_comp.path
                    Uriel.rel.path += url_comp.path[:url_comp.path.rfind('/')+1]
                else:
                    path = url_comp.path
                    Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
            else:
                path = url_comp.path
                Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
        else:
            path = Uriel.rel.path + url_comp.path

    post_scheme = netloc + "/" + urllib.quote(path)
    post_scheme = post_scheme.replace('//','/')
    if url_comp.query != '':
        post_scheme += '?'+url_comp.query
    url = scheme + "://" + post_scheme
    filesize = len(filedata)
    if filesize>0:
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        os.lseek(HGBD,128,os.SEEK_SET)
        os.write(HGBD,str(url)[:URIEL_STR_SIZE])
        os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
        os.write(HGBD,filedata)
        logger.info("[Uriel] history navigate fwd to " + url)
    else:
        filesize = -1
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        logger.error("[Uriel] error reading history for url " + url)
    conn.send(chr(URIEL_NAVFWD))

def UrielThumb():
    global Uriel
    os.lseek(HGBD,0,os.SEEK_SET)
    HGBD_PARAM_BUF = os.read(HGBD,BLK_SIZE)
    os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
    HGBD_URL_BUF = os.read(HGBD,BLK_SIZE*4)
    if Uriel.user_agent == '':
        Uriel.user_agent = HGBD_PARAM_BUF[:HGBD_PARAM_BUF.find('\x00')]
    url_comp = urlparse.urlparse(HGBD_URL_BUF[:HGBD_URL_BUF.find('\x00')])
    scheme = ''
    netloc = ''
    path = ''
    if url_comp.scheme == '':
        scheme = Uriel.rel.scheme
    else:
        scheme = url_comp.scheme
    if url_comp.netloc == '':
        netloc = Uriel.rel.netloc
    else:
        netloc = url_comp.netloc

    if url_comp.path != '':
        if url_comp.path.find('/') != -1:
            if url_comp.scheme == '' or url_comp.netloc == '':
                if url_comp.path[:1] != '/':
                    path = Uriel.rel.path + url_comp.path
                    Uriel.rel.path += url_comp.path[:url_comp.path.rfind('/')+1]
                else:
                    path = url_comp.path
                    Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
            else:
                path = url_comp.path
                Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
        else:
            path = Uriel.rel.path + url_comp.path

    post_scheme = netloc + "/" + urllib.quote(path)
    post_scheme = post_scheme.replace('//','/')
    if url_comp.query != '':
        post_scheme += '?'+url_comp.query
    url = scheme + "://" + post_scheme
    tmp_thumb = '/tmp/' + str(uuid.uuid4()) + '.bmp'
    while os.path.exists(tmp_thumb):
        tmp_thumb = '/tmp/' + str(uuid.uuid4()) + '.bmp'
    pagedata = subprocess.Popen('wget -q -O - -U "' + Uriel.user_agent + '" "' + url + '" 2>/dev/null | gm convert -resize 100x100 - -colors 16 "' + tmp_thumb + '"', shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE).communicate()[0]
    filedata = open(tmp_thumb,"rb").read()
    try:
        os.remove(tmp_thumb)
    except:
        pass
    filesize = len(filedata)
    if filesize>0:
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
        os.write(HGBD,filedata)
        logger.info("[Uriel] get image thumbnail " + url)
    else:
        filesize = -1
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        logger.error("[Uriel] error reading url " + url)
    conn.send(chr(URIEL_THUMB))

def UrielWebM():
    global Uriel
    os.lseek(HGBD,0,os.SEEK_SET)
    HGBD_PARAM_BUF = os.read(HGBD,BLK_SIZE)
    os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
    HGBD_URL_BUF = os.read(HGBD,BLK_SIZE*4)
    if Uriel.user_agent == '':
        Uriel.user_agent = HGBD_PARAM_BUF[:HGBD_PARAM_BUF.find('\x00')]
    url_comp = urlparse.urlparse(HGBD_URL_BUF[:HGBD_URL_BUF.find('\x00')])
    scheme = ''
    netloc = ''
    path = ''
    if url_comp.scheme == '':
        scheme = Uriel.rel.scheme
    else:
        scheme = url_comp.scheme
    if url_comp.netloc == '':
        netloc = Uriel.rel.netloc
    else:
        netloc = url_comp.netloc

    if url_comp.path != '':
        if url_comp.path.find('/') != -1:
            if url_comp.scheme == '' or url_comp.netloc == '':
                if url_comp.path[:1] != '/':
                    path = Uriel.rel.path + url_comp.path
                    Uriel.rel.path += url_comp.path[:url_comp.path.rfind('/')+1]
                else:
                    path = url_comp.path
                    Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
            else:
                path = url_comp.path
                Uriel.rel.path = url_comp.path[:url_comp.path.rfind('/')+1]
        else:
            path = Uriel.rel.path + url_comp.path

    post_scheme = netloc + "/" + urllib.quote(path)
    post_scheme = post_scheme.replace('//','/')
    if url_comp.query != '':
        post_scheme += '?'+url_comp.query
    url = scheme + "://" + post_scheme

    tmp_webm_path = '/tmp/' + str(uuid.uuid4()) + '/'
    while os.path.exists(tmp_webm_path):
        tmp_webm_path = '/tmp/' + str(uuid.uuid4()) + '/'
    os.mkdir(tmp_webm_path)
    os.system('cd "' + tmp_webm_path + '"; wget -q -O - -U "' + Uriel.user_agent + '" "' + url + '" 2>/dev/null | ffmpeg -i - %04d.jpg -hide_banner')
    for t in glob.glob(tmp_webm_path + '*.jpg'):
        os.system('gm convert -resize 100x100 "' + t + '" -colors 16 "' + t.replace('jpg','bmp') + '"')
        os.remove(t)
    webm_frames = 0
    for webm_frame in sorted(glob.glob(tmp_webm_path+'*.bmp')):
        webm_frames += 1
        os.system('cd "' + tmp_webm_path + '"; cat ' + webm_frame + ' >> output.bin')
    
    filedata = open(tmp_webm_path+'output.bin',"rb").read()
    try:
        os.remove(tmp_webm_path+'output.bin')
    except:
        pass
    if len(tmp_webm_path)>0:
        os.system('rm -rf "' + tmp_webm_path + '"')
    filesize = len(filedata)
    if filesize>0:
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        os.lseek(HGBD,128,os.SEEK_SET)
        os.write(HGBD,str(webm_frames))
        os.lseek(HGBD,BLK_SIZE,os.SEEK_SET)
        os.write(HGBD,filedata)
        logger.info("[Uriel] get WebM " + url)
    else:
        filesize = -1
        ZeroParamBuf()
        os.lseek(HGBD,0,os.SEEK_SET)
        os.write(HGBD,str(filesize))
        logger.error("[Uriel] error reading url " + url)
    conn.send(chr(URIEL_WEBM))

def UrielPreProcess(htm1, l_url):
    title_text = ''
    hb_header = '$WW,1$$BLACK$$MA+LIS,"[Close]",LM="U_CloseBrowser;"$ $MA+LIS,"[Back]",LM="U_HistNav(0);"$ $MA+LIS,"[Fwd]",LM="U_HistNav(1);"$ $MA+LIS,"[Go]",LM="U_Browser(GetStr(\\"\nURL> \\"));"$ ' + title_text + '\n\n'  

    doc_detect = False
    if htm1.upper().find('<HTML') != -1:
        doc_detect = True
    if htm1.upper().find('<!DOCTYPE HTML') != -1:
        doc_detect = True
    if doc_detect == False:
        return '$AN,"",A="BINARY"$'

    htm1 = htm1[htm1.upper().find('<HTML'):]
    htm1 = htm1.replace('$', '$$')  

    htm1 = htm1.replace('<blockquote>','    ')
    htm1 = htm1.replace('<BLOCKQUOTE>','    ')  

    htm1 = htm1.replace('<br>','\n')
    htm1 = htm1.replace('<br/>','\n')
    htm1 = htm1.replace('<br />','\n')
    htm1 = htm1.replace('<BR>','\n')
    htm1 = htm1.replace('<BR/>','\n')
    htm1 = htm1.replace('<BR />','\n')  

    htm1 = htm1.replace('<li>',' * ')
    htm1 = htm1.replace('<LI>',' * ')   

    htm1 = htm1.replace('</img>','')
    htm1 = htm1.replace('</IMG>','')    

    title_text = ''
    a_pos = htm1.upper().find('<TITLE>')
    if a_pos != -1:
        title_text = htm1[a_pos:htm1.find('</', a_pos)].split('>')[1]   

    soup1 = bs4.BeautifulSoup(htm1, 'lxml') 

    unwrap_tags = [ 'html', 'body', 'p', 'b', 'pre', 'span', 'table', 'header' ]
    for tag in unwrap_tags:
        for match in soup1.findAll(tag):
            match.unwrap()  

    for f in soup1.findAll('a'):
        for tag in f.findAll(True):
             if str(tag).find('<None>') == -1:
                 if tag.name.upper() != 'IMG':
                     tag.decompose()

    remove_tags = [ 'style', 'svg', 'embed', 'head', 'noscript', 'object', 'param', 'script', 'option' ]
    for tag in remove_tags:
        [s.extract() for s in soup1(tag)]   

    html = str(soup1)   

    html = html.replace('<h1>','$PURPLE$')
    html = html.replace('<H1>','$PURPLE$')
    html = html.replace('</h1>','$BLACK$')
    html = html.replace('</H1>','$BLACK$')  

    html = html.replace('<u>','$UL,1$')
    html = html.replace('<U>','$UL,1$')
    html = html.replace('</u>','$UL,0$')
    html = html.replace('</U>','$UL,0$')    

    html = html.replace('<b>','$IV,1$')
    html = html.replace('<B>','$IV,1$')
    html = html.replace('</b>','$IV,0$')
    html = html.replace('</B>','$IV,0$')

    a_pos = html.upper().find('<IMG ')
    while a_pos != -1:
        img_text = html[a_pos:].split('>')[0]
        img_text.replace("'",'"')
        img_src = ''
        img_pos = img_text.upper().find('SRC')
        if img_pos > 0:
            img_src = img_text[img_text.upper().find('SRC'):].split('"')[1]
        img_el = '[URIEL_IMG]' + img_src + '[/URIEL_IMG]'
        # Experimental WebM tags
        if html.lower().find(img_src.lower()[:img_src.lower().rfind('.')-1]+'.webm') != -1:
            img_el = '[URIEL_WEBM]' + img_src[:img_src.rfind('.')-1] + '.webm' + '[/URIEL_WEBM]'
        html = html[:a_pos] + img_el + html[1+html.upper().find('>', a_pos):]
        a_pos = html.upper().find('<IMG ')

    a_pos = html.upper().find('<BUTTON ')
    while a_pos != -1:
        button_text = html[a_pos:].split('>')[1]
        button_text = button_text[:button_text.upper().find('</BUTTON')]
        button_text = button_text.replace('"','\\"')
        button_doctext = '$BT,"' + button_text + '"$'
        html = html[:a_pos] + button_doctext + html[9+html.upper().find('</BUTTON>', a_pos):]
        a_pos = html.upper().find('<BUTTON ')   

    a_ctr = 0
    a_pos = html.upper().find('<A ')
    while a_pos != -1:
        link_pre = ''
        link_text = html[a_pos:].split('>')[1]
        link_text = link_text[:link_text.upper().find('</A')]
        while link_text.find('[URIEL_IMG]') != -1:
            link_pre += link_text[link_text.find('[URIEL_IMG]'):12+link_text.find('[/URIEL_IMG]')] + ' '
            link_text = link_text[:link_text.find('[URIEL_IMG]')] + link_text[12+link_text.find('[/URIEL_IMG]'):]
        link_text = link_text.replace('"','\\"')
        link_href = ''
        link_pos = html[a_pos:html.upper().find('</A>', a_pos)].upper().find('HREF')
        if link_pos > 0:
            link_href = html[a_pos:html.upper().find('</A>', a_pos)][link_pos:].replace('\'','"').split('"')[1]
        doldoc_link = '$AN,"",A="A' + str(a_ctr) + '"$$MA+LIS,"' + link_text + '",LM="U_Navigate(\\"A' + str(a_ctr) + '\\",\\"' + link_href + '\\");"$'
        html = html[:a_pos] + link_pre + doldoc_link + html[4+html.upper().find('</A>', a_pos):]
        a_ctr += 1
        a_pos = html.upper().find('<A ')    

    a_pos = html.upper().find('<CENTER>')
    while a_pos != -1:
        center_text = html[a_pos:].split('>')[1]
        center_text = center_text[:center_text.upper().find('</CENTER')]
        center_text = center_text.replace('"','\\"')
        if center_text.upper().find('[URIEL_IMG]') != -1:
            center_doctext = center_text
        else:
            center_doctext = '$TX+CX,"' + center_text + '"$'
        html = html[:a_pos] + center_doctext + html[9+html.upper().find('</CENTER>', a_pos):]
        a_pos = html.upper().find('<CENTER>')   

    html = html.replace('</div>','\n')
    html = html.replace('</DIV>','\n')  

    html = html.replace('</td>', ' ')
    html = html.replace('</TD>', ' ')   

    html = html.replace('</tr>', '\n')
    html = html.replace('</TR>', '\n')  

    a_pos = html.upper().find('<INPUT ')
    while a_pos != -1:
        input_text = html[a_pos:].split('>')[0]
        input_text = input_text.replace("'", '"')
        input_doctext = '[$UL,1$          $UL,0$]'  

        t_text = ''
        if input_text.upper().find('VALUE='):
            t_t = input_text[input_text.upper().find('VALUE='):].split('"')
            if len(t_t) > 2:
                t_text = t_t[1]
            
        bt_text = t_text if t_text != '' else 'Button'
        st_text = t_text if t_text != '' else 'Submit'  

        if input_text.find('button') != -1:
            input_doctext = '$BT,"' + bt_text + '"$'
        if input_text.find('checkbox') != -1:
            input_doctext = '$CB$'
        if input_text.find('hidden') != -1:
            input_doctext = ''
        if input_text.find('submit') != -1:
            input_doctext = '$BT,"' + st_text + '"$'            

        html = html[:a_pos] + input_doctext + html[1+html.upper().find('>', a_pos):]
        a_pos = html.upper().find('<INPUT ')    

    a_pos = html.upper().find('<')
    while a_pos != -1:
        html = html[:a_pos] + html[1+html.upper().find('>', a_pos):]
        a_pos = html.upper().find('<')  

    html = html.replace('&lt;','<')
    html = html.replace('&gt;','>')
    html = html.replace('&amp;','&')
    html = html.replace('&apos;','\'')
    html = html.replace('&quot;','"')   

    img_a_ctr = 0
    while html.find('[URIEL_IMG]') != -1:
        img_url = html[11+html.find('[URIEL_IMG]'):html.find('[/URIEL_IMG]')]
        img_ma = '$AN,"",A="IMG' + str(img_a_ctr) + '"$$MA+LIS,"[IMG]",LM="U_InsertThumb(\\"IMG' + str(img_a_ctr) + '\\",\\"$IMIS$\\",\\"$IMIE$\\",\\"' + img_url + '\\");"$$AN,"",A="IMIS' + str(img_a_ctr) + '"$'
        html = html[:html.find('[URIEL_IMG]')] + img_ma + html[12+html.find('[/URIEL_IMG]'):]        
        img_a_ctr += 1

    # WebM links
    webm_a_ctr = 0
    while html.find('[URIEL_WEBM]') != -1:
        webm_url = html[12+html.find('[URIEL_WEBM]'):html.find('[/URIEL_WEBM]')]
        webm_ma = '[WebM]",LM="U_PlayWebM(\\"WEBM' + str(webm_a_ctr) + '\\",\\"' + webm_url + '\\");"$$AN,"",A="WEBM' + str(webm_a_ctr) + '"$$MA+LIS,"'
        html = html[:html.find('[URIEL_WEBM]')] + webm_ma + html[13+html.find('[/URIEL_WEBM]'):]
        webm_a_ctr += 1

    hb_header = '$WW,1$$BLACK$$MA+LIS,"[Close]",LM="U_CloseBrowser;"$ $MA+LIS,"[Back]",LM="U_HistNav(0);"$ $MA+LIS,"[Fwd]",LM="U_HistNav(1);"$ $MA+LIS,"[Go]",LM="U_Browser(GetStr(\\"URL> \\"));"$ ' + title_text + '\n\n'    

    ind_id = ''
    o_html = ''
    o_lj_ct = 0
    o_lj_indent = False

    for line in html.split('\n'):
        if not o_lj_indent:
            if line[0:13] == '$AN,"",A="IMG':
                # Left Justified image detected.
                ind_id = line.split('IMG')[1].split('"')[0]
                line = line.replace('$IMIS$','IMIS' + ind_id)
                line = line.replace('$IMIE$','IMIE' + ind_id)
                o_lj_indent = True            

        if o_lj_indent:
            o_lj_ct += 1
            if o_lj_ct > 11:
                line = '$AN,"",A="IMIE' + ind_id + '"$' + line
                ind_id = ''
                o_lj_ct = 0
                o_lj_indent = False

        line = line.replace('$IMIS$','')
        line = line.replace('$IMIE$','')
        o_html += line + '\n' 

    # Unicode fixes
    o_html = o_html.replace('\xE2\x80\xA2','\xF9')
    o_html = o_html.replace('\xC2\xA0',' ')
    
    # Custom styles
    # (eventually, I will add minimal CSS support)

    if l_url.lower().find('4chan.org') != -1:
        c_html = ''
        for line in o_html.split('\n'):
            if line.strip()[:1] == '>' and line.strip()[:2] != '>>':
                c_html += '$GREEN$' + line + '$BLACK$\n'
            else:
                c_html += line + '\n'
        return hb_header + c_html
    
    return hb_header + o_html 
